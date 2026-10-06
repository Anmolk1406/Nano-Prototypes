import XCTest

/// The parent flow, walked end to end with real taps: every page reached, every
/// overlay passed through, Back from a later page, and typing into the
/// fields — the page's tap-to-dismiss must not steal the field's touch.
final class ParentFlowTests: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    private func launch(_ args: String...) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-scene", "Parent"] + args
        app.launch()
        return app
    }

    /// The topmost hittable button with this label — the outgoing page
    /// keeps its buttons in the tree until the crossfade finishes.
    private func tap(_ app: XCUIApplication, _ label: String, timeout: TimeInterval = 6,
                     file: StaticString = #filePath, line: UInt = #line) {
        let q = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", label))
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let b = (0..<q.count).map({ q.element(boundBy: $0) }).last(where: { $0.isHittable }) {
                b.tap(); return
            }
            usleep(150_000)
        }
        XCTFail("no hittable \"\(label)\" button", file: file, line: line)
    }

    func testTheWholeFlow() {
        let app = launch()
        XCTAssertTrue(app.staticTexts["Child’s name"].waitForExistence(timeout: 8), "child page never showed")

        // The first-name field takes a tap and typing.
        let first = app.textFields.element(boundBy: 0)
        first.tap()
        first.typeText("x")
        XCTAssertEqual(first.value as? String, "Kiaanx", "the name field did not take focus")
        first.typeText(XCUIKeyboardKey.delete.rawValue)

        tap(app, "Continue")
        XCTAssertTrue(app.staticTexts["We'll send the login code here"].waitForExistence(timeout: 8),
                      "email page never came up")

        tap(app, "Continue")
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Yes, use this email")).firstMatch.waitForExistence(timeout: 5), "confirm sheet never rose")
        tap(app, "Yes, use this email")

        XCTAssertTrue(app.staticTexts["Set up approval rules for shopping"].waitForExistence(timeout: 10),
                      "the intro never moved on to Set Rules")

        tap(app, "Manually approve orders")
        XCTAssertTrue(app.staticTexts["Select one"].waitForExistence(timeout: 4), "manual's options never opened")

        // Back from a later page returns to it, and forward again works.
        tap(app, "Continue")
        XCTAssertTrue(app.staticTexts["Select a saved address. Kiaan can add more later"].waitForExistence(timeout: 6))
        tap(app, "Back")
        XCTAssertTrue(app.staticTexts["Select one"].waitForExistence(timeout: 4), "Back did not return to Set Rules")
        tap(app, "Continue")
        XCTAssertTrue(app.staticTexts["Select a saved address. Kiaan can add more later"].waitForExistence(timeout: 6))

        tap(app, "Continue")
        XCTAssertTrue(app.staticTexts["Share invite"].waitForExistence(timeout: 10) || app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Share invite")).firstMatch.exists, "Let's Go never handed on to the invite")
    }
}
