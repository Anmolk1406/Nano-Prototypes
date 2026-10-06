import SwiftUI

/// Frames 3 and 4: the child's email, then the sheet that confirms it.
///
/// Frame 3 (1015:45271) is drawn with the keyboard up — the field focused,
/// the Back / Continue row riding on the keyboard — so the page opens that
/// way, and the row drops to the foot of the page if the keyboard goes.
/// Frame 4 (1015:45373) is `M-BottomSheet` over it.
struct ParentEmailPage: View {
    @EnvironmentObject private var model: ParentModel
    @FocusState private var focused: Bool
    @State private var autoFocusing = false
    /// `-parentSheet` opens with the confirm sheet up, for screenshots.
    @State private var confirming = ProcessInfo.processInfo.arguments.contains("-parentSheet")

    var body: some View {
        ParentStage {
            ParentHeaderBackground()
            ParentTitleHeader(title: "Email ID", subtitle: "We'll send the login code here") {
                ParentLottie(name: "parent_email", size: ParentArt.email.size, origin: ParentArt.email.origin)
            }
            body258
                .offset(y: 258)
            actions
            // Under the sheet's scrim, not over it.
            ParentOverlayBar(page: .email)
            ConfirmEmailSheet(email: model.email, name: model.firstName, shown: confirming,
                              // The sheet and the page fade out together while
                              // the intro brings its own elements up.
                              onConfirm: { model.push(.intro) },
                              onEdit: {
                                  withAnimation(ParentSpec.spring) { confirming = false }
                                  // The bar comes back on top once the scrim
                                  // has faded, not while it is still over it.
                                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                      if !confirming { model.setOverlay(false) }
                                  }
                                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { focused = true }
                              })
        }
        .onAppear {
            if confirming { model.setOverlay(true) }
            // Once the page has faded in, as the design has it: focused.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                guard !confirming else { return }
                autoFocusing = true; focused = true
            }
        }
        // Soft on a tap into the field; not when the page focuses it itself.
        .onChange(of: focused) { _, now in
            if now && !autoFocusing { Haptics.shared.lightTap() }
            autoFocusing = false
        }
    }

    private var valid: Bool {
        let e = model.email.trimmingCharacters(in: .whitespaces)
        return e.contains("@") && e.split(separator: "@").last?.contains(".") == true
    }

    // MARK: 1015:45305 — 16 in, 20 down, 15 between

    private var body258: some View {
        VStack(alignment: .leading, spacing: 15) {
            emailField
            HStack(spacing: 12) {
                Image("parent_info").resizable().frame(width: 24, height: 24)
                ParentLines(lines: ["If your child email already exists on noon, they",
                                    "will be added to your family after verification"],
                            style: ParentSpec.T.b13r, colour: ParentSpec.C.textSecondary, alignment: .leading)
                    .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
            }
            .padding(12)
            .background(Color(hex: 0xE3FCF2), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color(hex: 0xCBF6E5), lineWidth: 1)
            }
            HStack(spacing: 6) {
                Text("Don't have an email?")
                    .parentType(ParentSpec.T.b14r)
                    .foregroundStyle(ParentSpec.C.textTertiary)
                Text("Create a username")
                    .parentType(ParentSpec.T.b14s)
                    .foregroundStyle(ParentSpec.C.textPrimary)
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .frame(width: 375, alignment: .topLeading)
    }

    /// `M-Input-alt` with a label row — "Email" and a red asterisk.
    private var emailField: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 2) {
                Text("Email").foregroundStyle(ParentSpec.C.textSecondary)
                Text("*").foregroundStyle(Color(hex: 0xD92626))
            }
            .font(NoonFont.f(.medium, 12))
            .tracking(-0.1)
            .frame(height: 18)
            TextField("", text: $model.email)
                .font(NoonFont.f(.medium, 14))
                .tracking(-0.1)
                .foregroundStyle(ParentSpec.C.textPrimary)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.continue)
                .onSubmit { if valid { confirm() } }
                .focused($focused)
                .frame(height: 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .frame(height: 56)
        .background(focused ? ParentSpec.C.surface : ParentSpec.C.field,
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(ParentSpec.C.borderSubtle, lineWidth: 1)
        }
        .animation(ParentSpec.spring, value: focused)
        .parentFocusRing(focused)
        // The whole box takes the tap, not just the line of text in it.
        .contentShape(Rectangle())
        .onTapGesture { focused = true }
    }

    private var actions: some View {
        ParentRowActions(onBack: { model.back() }, primary: "Continue", enabled: valid) { confirm() }
    }

    private func confirm() {
        focused = false
        model.setOverlay(true)
        withAnimation(ParentSpec.spring) { confirming = true }
    }
}

/// `M-SecondaryNeutralButton`: white, a hairline border, dark type.
struct ParentSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .parentType(ParentSpec.T.a16)
                .foregroundStyle(ParentSpec.C.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
        }
        // The primary's dome in white: the same press, light and haptic.
        .buttonStyle(DomeButtonStyle(variant: .light))
    }
}

/// Frame 4's `M-BottomSheet` (1015:45419): an 80% scrim, the grabber, and a
/// white card 12 in from each side holding the envelope, the message, the
/// address in a pill and two actions — bottom-anchored above the 33pt home
/// strip, so its top lands at y 302.
private struct ConfirmEmailSheet: View {
    let email: String
    let name: String
    let shown: Bool
    let onConfirm: () -> Void
    let onEdit: () -> Void

    /// The grabber's live pull, down only — the sheet follows it.
    @State private var dragDown: CGFloat = 0
    /// 0…1 — the grabber pulled up: the sheet stretches, its sections
    /// easing apart.
    /// `-sheetStretch 1` holds it stretched, for a screenshot: the gesture
    /// cannot be driven in the Simulator.
    @State private var stretch: CGFloat = {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: "-sheetStretch"), i + 1 < a.count, let v = Double(a[i + 1]) else { return 0 }
        return CGFloat(max(0, min(1, v)))
    }()

    /// The design system's `M-BottomSheet` (`field-design-system`,
    /// `BottomSheet.tsx`), its numbers verbatim.
    private enum DS {
        /// `motion.spring.springLight` — entry, exit and the drag's return.
        static let springLight = Animation.interpolatingSpring(stiffness: 300, damping: 28)
        /// `motion.spring.springBouncy` — the stretch letting go.
        static let springBouncy = Animation.interpolatingSpring(stiffness: 280, damping: 18)
        /// Pull-down past which letting go dismisses.
        static let closeDrag: CGFloat = 60
        /// Pull-up that reaches full stretch.
        static let expandTravel: CGFloat = 80
        /// The gap each section boundary opens by at full stretch.
        static let expandGap: CGFloat = 16
        /// The scrim fades out over this much pull-down.
        static let scrimFade: CGFloat = 200
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.8)
                // Fades with the pull, so dragging the sheet down reads as
                // starting to let it go.
                .opacity(shown ? 1 - min(1, dragDown / DS.scrimFade) : 0)
                .onTapGesture(perform: onEdit)
            VStack(spacing: 0) {
                grabber
                card.padding(.horizontal, 12)
                Color.clear.frame(height: 33)
            }
            .offset(y: (shown ? 0 : 520) + dragDown)
        }
        .frame(width: 375, height: 812)
        .animation(DS.springLight, value: shown)
        .allowsHitTesting(shown)
        // Invisible is not absent: keep it out of the accessibility tree too.
        .accessibilityHidden(!shown)
        .onChange(of: shown) { _, now in
            // A drag that dismissed the sheet goes back to rest with it, on
            // the same spring, so it cannot snap for a frame.
            if !now { withAnimation(DS.springLight) { dragDown = 0; stretch = 0 } }
        }
    }

    /// The grabber, and the handle for both gestures: down drags the sheet
    /// and past 60pt lets it go; up stretches it, and it springs back.
    private var grabber: some View {
        Capsule().fill(.white.opacity(0.64)).frame(width: 36, height: 4)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        let dy = v.translation.height
                        if dy >= 0 {
                            dragDown = dy
                            stretch = 0
                        } else {
                            dragDown = 0
                            stretch = min(1, -dy / DS.expandTravel)
                        }
                    }
                    .onEnded { v in
                        if v.translation.height > DS.closeDrag {
                            onEdit()
                            return
                        }
                        // The stretch is a peek, not a state: always back.
                        withAnimation(DS.springLight) { dragDown = 0 }
                        withAnimation(DS.springBouncy) { stretch = 0 }
                    }
            )
            .accessibilityLabel("Sheet grabber")
    }

    private var gap: CGFloat { stretch * DS.expandGap }

    private var card: some View {
        VStack(spacing: 0) {
            // The header's envelope Lottie again, in the same 235 × 125 art
            // box. The sheet used a flat 3× export matted onto white, and its
            // edge showed as a box against the card. Mounted only while the
            // sheet is up, so it plays as the sheet rises rather than
            // finishing unseen while the sheet waits off-screen.
            ZStack {
                if shown {
                    ParentLottie(name: "parent_email", size: ParentArt.email.size, origin: ParentArt.email.origin)
                        .transition(.opacity)
                }
            }
            .frame(width: 235, height: 125)
            .padding(.top, 24).padding(.bottom, 12 + gap)
            VStack(spacing: 4) {
                Text("Confirm \(name)'s email")
                    .font(NoonFont.f(.bold, 20)).tracking(-0.25)
                    .foregroundStyle(ParentSpec.C.textPrimary)
                    .frame(height: 28)
                ParentLines(lines: ["Make sure you have entered the right email ",
                                    "so \(name) can verify this account later."],
                            style: ParentSpec.T.b14r, colour: ParentSpec.C.textTertiary)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .padding(.bottom, gap)
            Text(email)
                .parentType(ParentSpec.T.b14s)
                .foregroundStyle(ParentSpec.C.textPrimary)
                .padding(.horizontal, 24)
                .frame(height: 48)
                .background(.white, in: Capsule())
                .overlay { Capsule().strokeBorder(ParentSpec.C.borderSubtle, lineWidth: 1) }
                .padding(.horizontal, 12).padding(.vertical, 20)
                .padding(.bottom, gap)
            VStack(spacing: 12) {
                ParentPrimaryButton(title: "Yes, use this email", action: onConfirm)
                ParentSecondaryButton(title: "Edit email", action: onEdit)
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 8, y: -2)
    }
}
