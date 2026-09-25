import XCTest

/// Real touch injection.
///
/// `simctl` cannot synthesise taps, and the native Simulator integration on this
/// machine is gated behind a `sudo xcode-select` that hasn't been run. A UI test
/// bundle drives genuine taps and typing through the same path a finger does,
/// which is the only way to prove a control is actually usable — a hit test says
/// which view owns a point, not which gesture recognizer wins the touch.
final class InteractionTests: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    private func launch(_ args: String...) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = args
        app.launch()
        return app
    }

    /// The regression that started this: a tap-to-dismiss gesture on an
    /// *ancestor* of the field claimed the touch, so the field never took focus.
    /// `typeText` fails loudly when the element has no keyboard focus, which is
    /// exactly the signal wanted here.
    func testEmailFieldTakesTypingAfterATap() {
        let app = launch("-onbStep", "Email")
        let field = app.textFields["emailField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "email field never appeared")

        field.tap()
        field.typeText("kiaan")

        XCTAssertEqual(field.value as? String, "kiaan",
                       "tapping the field did not give it keyboard focus")
    }

    /// Tapping the label / padding should focus the field too — the text line is
    /// only ~22pt of the 56pt row, so most of the control is the tap layer.
    func testTappingTheRowPaddingFocusesTheField() {
        let app = launch("-onbStep", "Email")
        let field = app.textFields["emailField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))

        // Near the top of the row, over the "Email ID" label rather than the
        // text line.
        let row = field.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: -1.1))
        row.tap()
        field.typeText("x")

        XCTAssertEqual(field.value as? String, "x",
                       "the row's tap layer did not focus the field")
    }

    /// Touch has to be dead while the cycle transition runs.
    ///
    /// `handleDrag` assigns `advance` and `reveal` directly — deliberately, so
    /// they track the hand — which means a gesture accepted mid-transition
    /// snaps both out of their running curves and the card and background
    /// jump. The gesture is masked off rather than guarded inside the handlers,
    /// because a gesture allowed to *begin* and then ignored is still live when
    /// the transition ends and arrives with a large accumulated translation.
    ///
    /// Observable proxy: a downward drag past the confirm threshold normally
    /// selects the card and enables Continue. Thrown mid-transition it must do
    /// nothing. `-cycleDuration` stretches the window so the second gesture
    /// reliably lands inside it.
    func testGestureIsLockedOutDuringTheCycleTransition() {
        let app = launch("-onbStep", "Skin", "-cycleDuration", "2.5")
        let cta = app.buttons["skinContinue"]
        XCTAssertTrue(cta.waitForExistence(timeout: 5), "skin step never appeared")
        XCTAssertFalse(cta.isEnabled, "Continue should start disabled")

        let stage = app.windows.firstMatch
        func drag(from: CGVector, to: CGVector) {
            stage.coordinate(withNormalizedOffset: from)
                .press(forDuration: 0.05,
                       thenDragTo: stage.coordinate(withNormalizedOffset: to))
        }

        // Commit a cycle — an upward throw well past the threshold.
        drag(from: CGVector(dx: 0.5, dy: 0.55), to: CGVector(dx: 0.5, dy: 0.18))

        // Straight into a confirm pull, while the transition is still running.
        drag(from: CGVector(dx: 0.5, dy: 0.35), to: CGVector(dx: 0.5, dy: 0.95))

        XCTAssertFalse(cta.isEnabled,
                       "a drag accepted mid-transition selected the card")

        // And the lock has to lift again afterwards, or the screen is bricked.
        Thread.sleep(forTimeInterval: 3.0)
        drag(from: CGVector(dx: 0.5, dy: 0.35), to: CGVector(dx: 0.5, dy: 0.95))
        XCTAssertTrue(cta.waitForExistence(timeout: 2) && cta.isEnabled,
                      "the gesture never came back after the transition")
    }

    /// A diagonal swipe has to commit to exactly one of the two gestures.
    ///
    /// On the sideways axis both used to run at once: `advance` carried the
    /// front card out on x while `pull` — derived from `drag.height` rather
    /// than from state — dropped that same card on y and mounted the copy in
    /// front of the sheet, so one diagonal swipe put two cards on screen
    /// moving on two axes.
    ///
    /// The pair is what makes this meaningful. Both drags are the same
    /// diagonal shape and the same length; only which axis dominates differs,
    /// and they have to come out opposite. A lock that simply always picked
    /// "confirm" would pass the first half and fail the second.
    func testADiagonalSwipeCommitsToOneGestureOnly() {
        let app = launch("-onbStep", "Skin", "-cycleAxis", "Side",
                         "-entryDelay", "0", "-skinProbe")
        let cta = app.buttons["skinContinue"]
        XCTAssertTrue(cta.waitForExistence(timeout: 5), "skin step never appeared")
        XCTAssertFalse(cta.isEnabled, "Continue should start disabled")

        let stage = app.windows.firstMatch
        func drag(from: CGVector, to: CGVector) {
            stage.coordinate(withNormalizedOffset: from)
                .press(forDuration: 0.05,
                       thenDragTo: stage.coordinate(withNormalizedOffset: to))
        }

        // Mostly sideways, well past the cycle threshold, but 20% of the
        // screen downward as well — enough to have crossed the confirm
        // threshold on its own.
        drag(from: CGVector(dx: 0.15, dy: 0.42), to: CGVector(dx: 0.92, dy: 0.62))
        XCTAssertFalse(cta.isEnabled,
                       "a sideways-dominant diagonal also confirmed the card")

        // And the pull must have contributed nothing *during* the throw, which
        // is the part the Continue button cannot see: the copy in front of the
        // sheet mounts on `pull > 0`, so a non-zero pull there is the second
        // card. The app latches it, because XCUITest cannot query mid-drag.
        XCTAssertEqual(app.staticTexts["skinProbe"].label, "clean",
                       "the confirm pull ran alongside the throw — two cards")

        // The same diagonal the other way round: mostly downward, with as much
        // sideways travel. This one must confirm.
        Thread.sleep(forTimeInterval: 1.2)
        drag(from: CGVector(dx: 0.30, dy: 0.30), to: CGVector(dx: 0.50, dy: 0.97))
        XCTAssertTrue(cta.waitForExistence(timeout: 2) && cta.isEnabled,
                      "a downward-dominant diagonal did not confirm the card")
    }

    /// Send OTP must arm on any non-empty string — no @ or domain required.
    func testSendOTPArmsOnAnyText() {
        let app = launch("-onbStep", "Email")
        let field = app.textFields["emailField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))

        let cta = app.buttons["Send OTP"]
        XCTAssertTrue(cta.waitForExistence(timeout: 5))
        XCTAssertFalse(cta.isEnabled, "Send OTP should start disabled")

        field.tap()
        field.typeText("kiaan")
        XCTAssertTrue(cta.isEnabled, "Send OTP should arm on any non-empty text")
    }
}
