import SwiftUI

struct ControlsPanel: View {
    @ObservedObject var motion: MotionEngine
    @ObservedObject var t: Tuning
    @ObservedObject var haptics = Haptics.shared
    @ObservedObject var skin: SkinTuning
    @ObservedObject var onb: OnboardingTuning
    @ObservedObject var topUp: TopUpTuning
    @ObservedObject var button: ButtonLabTuning
    @ObservedObject var shine: ShineLabTuning
    @Binding var scene: AppScene
    @Binding var step: OnboardingStep
    @Binding var expanded: Bool
    /// The account page's one control: play its entrance again.
    @Binding var accountReplay: Int
    /// The parent flow's one control: start it again.
    @Binding var parentReplay: Int

    var body: some View {
        VStack(spacing: 0) {
            handle
            if expanded {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        // Each group is built in its own `body` (see
                        // `Deferred`), not inline here. Inline, every scene's
                        // sections were laid out in this one closure's stack
                        // frame — in a debug build each branch gets its own
                        // slots even though only one runs — and once the
                        // Button lab's controls were added it outgrew the main
                        // thread's stack and crashed the app mid-use.
                        Deferred { sceneSection }
                        divider
                        Deferred { sceneControls }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
                }
                .frame(maxHeight: 330)
            }
        }
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22,
                                          style: .continuous))
        .ignoresSafeArea(edges: .bottom)
    }

    private var divider: some View { Divider().overlay(.white.opacity(0.12)) }

    @ViewBuilder private var sceneControls: some View {
        switch scene {
        case .onboarding: Deferred { onboardingControls }
        case .skinSelect: Deferred { skinControls }
        case .topUp:      Deferred { topUpControls }
        case .button:     Deferred { buttonControls }
        case .account:    Deferred { accountControls }
        case .qrCard:     Deferred { qrControls }
        case .parent:     Deferred { parentControls }
        case .shineLab:   Deferred { shineLabControls }
        // Its picker and Replay are on the screen itself.
        case .lottieLab:  EmptyView()
        }
    }

    private var onboardingControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Deferred { stepSection }
            divider
            VStack(alignment: .leading, spacing: 8) {
                header("Buttons")
                PressScaleRow()
            }
            divider
            Deferred { avatarSection }
            divider
            Deferred { skinControls }
        }
    }

    private var skinControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Deferred { motionSection }
            divider
            Deferred { gestureSection }
            divider
            Deferred { arcSection }
            divider
            Deferred { hapticsSection }
        }
    }

    private var topUpControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Deferred { topUpSection }
            divider
            Deferred { hapticsSection }
        }
    }

    private var buttonControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Deferred { buttonSection }
            divider
            ButtonHapticsSection(h: button.haptics)
        }
    }

    private var accountControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Deferred { accountSection }
            divider
            Deferred { hapticsSection }
        }
    }

    private var parentControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            header("Parent onboarding")
            Text("Adding a kid, ten frames on six pages. Pages push on a spring "
                 + "(320 / 28) under the progress bar, which stays put and fills. The celebration, "
                 + "the email sheet and Let's Go are overlays on their page; the wallet intro "
                 + "brings its own elements in.")
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))
            header("Buttons")
            PressScaleRow()
            Button("Restart") { parentReplay += 1 }
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .buttonStyle(.bordered)
                .tint(.white.opacity(0.9))
        }
    }

    private var shineLabControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Deferred { sourceSection }
            divider
            VStack(alignment: .leading, spacing: 8) {
                header("Shines")
                Text("Experimental. Each shine rides the rim's outer or inner bevel, alternating along "
                     + "each side, and runs along it with the tilt \u{2014} top and bottom on x, the sides on y \u{2014} "
                     + "stopping short of the corner and never glowing in over the panel. "
                     + "The corner shine stays put and glints toward its corner.")
                    .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))
                slider("Travel", $shine.travel, 0...400, unit: "px", format: "%.0f")
                slider("Rest glow", $shine.restGlow, 0...1)
                slider("Stretch", $shine.stretch, 0...0.5)
                Toggle("Orbit (opposite edges run opposite ways)", isOn: $shine.orbit).font(rowFont)
                Toggle("Additive", isOn: $shine.additive).font(rowFont)
                Toggle("White halo round the card", isOn: $shine.halo).font(rowFont)
                Toggle("Show bevel tracks", isOn: $shine.showEdges).font(rowFont)
                Button("Reset") { shine.reset() }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .buttonStyle(.bordered)
                    .tint(.white.opacity(0.9))
            }
            divider
            // The card's own motion and light are the QR card's, shared with
            // it — tilt, parallax, sheen, iridescence, shadow.
            Deferred { tiltSection }
            divider
            Deferred { lightSection }
            // The holo card has no border for the shared rim light to draw
            // on, so it has a rim light of its own over the rim band.
            slider("Rim strength", $shine.rimStrength, 0...1, enabled: t.rimEnabled)
        }
    }

    private var qrControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Deferred { sourceSection }
            divider
            Deferred { tiltSection }
            divider
            Deferred { lightSection }
            divider
            Deferred { stageSection }
        }
    }

    private var handle: some View {
        Button { withAnimation(.snappy) { expanded.toggle() } } label: {
            VStack(spacing: 6) {
                Capsule().fill(.white.opacity(0.35)).frame(width: 38, height: 4)
                if !expanded {
                    Text("Controls").font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: sections

    private var sceneSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            header("Scene")
            // A dropdown rather than a segmented control: at eight scenes the
            // segments were too narrow to show their names.
            Menu {
                Picker("", selection: $scene) {
                    ForEach(AppScene.allCases) { s in Text(s.rawValue).tag(s) }
                }
            } label: {
                HStack {
                    Text(scene.rawValue)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .opacity(0.6)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .contentShape(Rectangle())
            }
            .accessibilityLabel("Scene")
            if scene == .skinSelect || scene == .onboarding {
                Text("Swipe the card up to cycle skins, drag it down to confirm.")
                    .font(.system(size: 11)).foregroundStyle(.white.opacity(0.55))
            }
            if scene == .topUp {
                Text("Tap Request top up on the wallet, enter an amount, and "
                     + "send it. Replay runs the whole round trip hands-free.")
                    .font(.system(size: 11)).foregroundStyle(.white.opacity(0.55))
            }
            if scene == .button {
                Text("Press and hold the button. Pressed \(button.presses)\u{00D7}.")
                    .font(.system(size: 11)).foregroundStyle(.white.opacity(0.55))
            }
            if scene == .account {
                Text("Only the header animates. Replay plays its load-in again.")
                    .font(.system(size: 11)).foregroundStyle(.white.opacity(0.55))
            }
        }
    }

    /// Jump straight to any step. Reviewing step 6 shouldn't mean typing an
    /// OTP four times first.
    private var stepSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            header("Onboarding step")
            Picker("", selection: $step) {
                ForEach(OnboardingStep.allCases) { s in Text(s.rawValue).tag(s) }
            }
            .pickerStyle(.segmented)
            // The flow ends on the kid's home, which has no way back to the
            // start — this is the test UI's.
            Button("Restart the flow") {
                withAnimation(.easeInOut(duration: 0.3)) { step = .splash }
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .buttonStyle(.bordered)
            .tint(.white.opacity(0.9))
            Toggle("Reject the OTP", isOn: $onb.otpAlwaysFails).font(rowFont)
            Text("Any 4 digits pass. Flip that to reach the rejection state \u{2014} "
                 + "its toast and error haptic have no other way in.")
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))

        }
    }

    /// Cycling the avatar is a dissolve between two circles, so the treatment
    /// lives in what happens to the pair mid-swap.
    private var avatarSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            header("Avatar cycle")
            Picker("", selection: $onb.avatarStyle) {
                ForEach(OnboardingTuning.AvatarStyle.allCases) { s in Text(s.rawValue).tag(s) }
            }
            .pickerStyle(.segmented)
            slider("Blur", $onb.avatarBlur, 0...40, unit: "pt", format: "%.0f",
                   enabled: onb.avatarStyle == .crossBlur || onb.avatarStyle == .zoom)
            slider("Response", $onb.avatarResponse, 0.15...0.8, unit: "s", format: "%.2f")
            Toggle("Blur follows the drag", isOn: $onb.dragBlur).font(rowFont)
            slider("Drag blur", $onb.dragBlurAmount, 0.02...0.3, format: "%.2f",
                   enabled: onb.dragBlur)
            Text("Cross blurs both sides on one curve; Zoom adds a scale punch; "
                 + "Glass sweeps a frosted scrim over the swap.")
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))

            header("Shake to shuffle").padding(.top, 8)
            slider("Threshold", $onb.shakeThreshold, 0.3...2.5, unit: "g", format: "%.2f")
            slider("Jolts", $onb.shakePeaks, 1...3, format: "%.0f")
            Text(String(format: "Last jolt: %.2fg. ", onb.shakeLastPeak)
                 + "Lower threshold is more sensitive; iOS's own shake needs about 2g. "
                 + "Jolts is how many hits within 0.6s make a shake.")
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))

            header("Avatar row").padding(.top, 8)
            slider("Edge blur", $onb.rowBlur, 0...24, unit: "pt", format: "%.0f")
            slider("Edge fade", $onb.rowFade, 0...0.9, format: "%.2f")
            slider("Edge shrink", $onb.rowShrink, 0...0.5, format: "%.2f")
            Text("Applied by position, not by a transition: an item at the row's "
                 + "edge carries all three and loses them as it scrolls in.")
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))
        }
    }

    private var motionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            header("Entry & hints")
            Toggle("Deal-in on appear", isOn: $skin.entryEnabled).font(rowFont)
            slider("Delay", $skin.entryDelay, 0...1.5, unit: "s", format: "%.2f",
                   enabled: skin.entryEnabled)
            slider("Response", $skin.entryResponse, 0.2...0.7, unit: "s", format: "%.2f",
                   enabled: skin.entryEnabled)
            slider("Stagger", $skin.entryStagger, 0...0.20, unit: "s", format: "%.3f",
                   enabled: skin.entryEnabled)
            Toggle("Idle gesture hints", isOn: $skin.hintsEnabled).font(rowFont)
            slider("Cycle hint", $skin.hintCycleAmount, 0...0.4, enabled: skin.hintsEnabled)
            slider("Pull hint", $skin.hintPullAmount, 0...0.4, enabled: skin.hintsEnabled)
            slider("Repeat every", $skin.hintRepeat, 2...12, unit: "s", format: "%.0f",
                   enabled: skin.hintsEnabled)
            slider("Hand size", $skin.hintHandScale, 0.8...1.8, unit: "\u{00D7}", format: "%.2f",
                   enabled: skin.hintsEnabled)
        }
    }

    /// Sensitivity. Travel scales how far the finger has to go, not how far the
    /// card moves — so a longer drag reads as weight, not as a bigger animation.
    private var gestureSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            header("Gesture")
            header("Cycle gesture").padding(.top, 8)
            Picker("", selection: $skin.cycleAxis) {
                ForEach(SkinTuning.CycleAxis.allCases) { a in Text(a.rawValue).tag(a) }
            }
            .pickerStyle(.segmented)
            Text("Sideways throws the card off either edge with a rise and a "
                 + "tilt; the confirm pull stays downward in both.")
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))
            slider("Throw travel", $skin.throwTravel, 0.4...2.0, format: "%.2f")
            slider("Pull travel", $skin.pullTravel, 0.4...2.0, format: "%.2f")
            Text(String(format: "Throw %.0fpt \u{00B7} pull %.0fpt \u{00B7} commits at %.0f%%",
                        SkinSelectSpec.cycleThreshold * skin.throwTravel,
                        SkinSelectSpec.confirmThreshold * skin.pullTravel,
                        SkinSelectSpec.commitFraction * 100))
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))
            slider("Throw detents", $skin.cycleDetents, 0...12, format: "%.0f",
                   enabled: haptics.isEnabled)

            header("Cycle transition").padding(.top, 4)
            slider("Duration", $skin.cycleDuration, 0.2...3.0, unit: "s", format: "%.2f")
            slider("Drag preview", $skin.cyclePreview, 0...0.5, format: "%.2f")
            Text("Fixed duration, so a flick and a slow drag look the same. "
                 + "Preview is how much of it the drag scrubs before release \u{2014} "
                 + "at 0 nothing but the card moves until you let go.")
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))

            header("Pocket glow").padding(.top, 4)
            Toggle("Lit mouth on the pull", isOn: $skin.glowEnabled).font(rowFont)
            slider("Cycle", $skin.glowPeriod, 0.8...6, unit: "s", format: "%.1f",
                   enabled: skin.glowEnabled)
            slider("Thickness", $skin.glowThickness, 0.3...2.2, format: "%.2f",
                   enabled: skin.glowEnabled)
            Text("Colours are read off the card being confirmed; a card with no "
                 + "hue of its own glows in tints of the one it has. Lit only "
                 + "while the card is touching the mouth, at full strength.")
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))

            header("Mouth").padding(.top, 8)
            Toggle("Pinch the card into the edge", isOn: $skin.bendEnabled).font(rowFont)
            slider("Amount", $skin.bendAmount, 0...16, unit: "pt", format: "%.0f",
                   enabled: skin.bendEnabled)
            slider("Reach", $skin.bendReach, 8...80, unit: "pt", format: "%.0f",
                   enabled: skin.bendEnabled)
            Text("A Metal distortion, so it needs the Metal toolchain to build. "
                 + "Off leaves the card cut by a straight line at the mouth.")
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))

            header("Confirm screen").padding(.top, 8)
            slider("Card tint", $skin.confirmTint, 0...1, format: "%.2f")
            Text("How far the wash and the rays across the top lean toward the "
                 + "chosen card's colour. 0 is the design's grey and white.")
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))
        }
    }

    /// The incoming skin is revealed through the top arc of a circle centred
    /// below the screen. Depth sets how curved that arc reads.
    private var arcSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            header("Background transition")
            Picker("", selection: $skin.bgStyle) {
                ForEach(SkinTuning.BGStyle.allCases) { b in Text(b.rawValue).tag(b) }
            }
            .pickerStyle(.segmented)
            slider("Arc depth", $skin.arcDepth, 80...1200, unit: "pt", format: "%.0f",
                   enabled: skin.bgStyle == .arc)
            Picker("", selection: $skin.arcEdge) {
                ForEach(SkinTuning.ArcEdge.allCases) { e in Text(e.rawValue).tag(e) }
            }
            .pickerStyle(.segmented)
            .disabled(skin.bgStyle != .arc)
            slider("Edge width", $skin.arcEdgeWidth, 2...70, unit: "pt", format: "%.0f",
                   enabled: skin.bgStyle == .arc && skin.arcEdge != .none)
            slider("Edge intensity", $skin.arcEdgeIntensity, 0...1,
                   enabled: skin.bgStyle == .arc && skin.arcEdge != .none)
            Text("Crossfade is the default. Arc reveals the next skin through the top of a circle centred below the screen.")
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))
        }
    }

    /// The pull-to-confirm rumble is a train of impacts, so its feel is three
    /// numbers: how often they fire, and how hard at each end of the pull.
    private var hapticsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            header("Haptics")
            Toggle("Enabled", isOn: $haptics.isEnabled).font(rowFont)
            slider("Pulse gap", $haptics.pulseGap, 0.02...0.30, unit: "s", format: "%.3f",
                   enabled: haptics.isEnabled)
            slider("Start strength", $haptics.minStrength, 0...1, enabled: haptics.isEnabled)
            slider("End strength", $haptics.maxStrength, 0...1, enabled: haptics.isEnabled)
            slider("Ramp curve", $haptics.rampCurve, 0.4...3, format: "%.2f",
                   enabled: haptics.isEnabled)
            Text("Gap is constant; strength ramps start \u{2192} end over the pull. "
                 + "Curve > 1 holds it light for longer, then bites late.")
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))
        }
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            header("Input")
            Picker("", selection: $motion.source) {
                ForEach(MotionEngine.Source.allCases) { s in
                    Text(s.rawValue).tag(s)
                }
            }
            .pickerStyle(.segmented)

            if motion.source == .motion && !motion.motionAvailable {
                Text("Device motion is unavailable here — use Drag or Demo.")
                    .font(.system(size: 11)).foregroundStyle(.orange)
            }
            slider("Range", $motion.rangeDegrees, 8...80, unit: "°")
            slider("Smoothing", $motion.smoothing, 0.02...1)
            Toggle("Auto-recentre when still", isOn: $motion.autoRecenter).font(rowFont)
            slider("Idle delay", $motion.idleDelay, 0.3...5, unit: "s", format: "%.1f",
                   enabled: motion.autoRecenter)
            if motion.source == .demo { slider("Demo speed", $motion.demoSpeed, 0.1...2) }
            HStack(spacing: 10) {
                Button("Recenter") { motion.recenter() }
                Toggle("Invert X", isOn: $t.invertX).fixedSize()
                Toggle("Invert Y", isOn: $t.invertY).fixedSize()
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .buttonStyle(.bordered)
            .toggleStyle(.button)
            .tint(.white.opacity(0.9))
        }
    }

    private var tiltSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            header("Tilt & depth")
            Toggle("3D tilt", isOn: $t.tiltEnabled).font(rowFont)
            slider("Amount", $t.tiltDegrees, 0...40, unit: "\u{00B0}", enabled: t.tiltEnabled)
            slider("Perspective", $t.perspective, 0...1.5, enabled: t.tiltEnabled)
            Toggle("In-plane roll", isOn: $t.rollEnabled).font(rowFont)
            slider("Roll", $t.roll, 0...8, unit: "\u{00B0}", enabled: t.rollEnabled)
            Toggle("Elevation parallax", isOn: $t.parallaxEnabled).font(rowFont)
            slider("Elevation \u{00D7}", $t.elevationScale, 0...3, enabled: t.parallaxEnabled)
            Toggle("Scale with depth", isOn: $t.depthScale).font(rowFont)
            slider("Contact shadow", $t.contactShadow, 0...2)
            Toggle("Blur from roll", isOn: $t.gyroBlur).font(rowFont)
            slider("Mascot blur", $t.blurScale, 0...1)
            Toggle("Element wobble", isOn: $t.wobbleEnabled).font(rowFont)
            slider("Wobble", $t.wobble, 0...20, unit: "\u{00B0}", enabled: t.wobbleEnabled)
        }
    }

    private var lightSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            header("Light")
            Toggle("Specular sheen", isOn: $t.sheenEnabled).font(rowFont)
            slider("Sheen", $t.sheen, 0...1, enabled: t.sheenEnabled)
            Toggle("Iridescence", isOn: $t.holoEnabled).font(rowFont)
            slider("Holo", $t.holo, 0...0.8, enabled: t.holoEnabled)
            Toggle("Rim light", isOn: $t.rimEnabled).font(rowFont)
            Toggle("Dynamic shadow", isOn: $t.shadowEnabled).font(rowFont)
            slider("Card shadow", $t.shadowShift, 0...45, unit: "pt", enabled: t.shadowEnabled)
        }
    }

    private var stageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            header("Card")
            Picker("", selection: $t.cardStyle) {
                ForEach(Tuning.CardStyle.allCases) { c in Text(c.rawValue).tag(c) }
            }
            .pickerStyle(.segmented)
            Text("Invite is Figma 779:22071 \u{2014} the card on a photo backdrop. "
                 + "Profile is 940:62757 \u{2014} the profile QR on a starburst. "
                 + "Same motion, same knobs; only the planes differ.")
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))

            header("Stage").padding(.top, 4)
            slider("Card scale", $t.cardScale, 0.7...1.15, format: "%.2f")
            Picker("", selection: $t.backdrop) {
                ForEach(Tuning.Backdrop.allCases) { b in Text(b.rawValue).tag(b) }
            }
            .pickerStyle(.segmented)
            Toggle("Show layer bounds", isOn: $t.showBounds).font(rowFont)
            Button("Reset all") { t.reset() }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .buttonStyle(.bordered)
                .tint(.white.opacity(0.9))
        }
    }

    // MARK: top up

    /// The animation's colours are read off the wallet's card skin, so picking
    /// that card is the one control it cannot do without. A plain strip of the
    /// 22 renders in the picker's own browse order, and under it the two or
    /// three colours `SkinPalette` actually pulled out of the chosen one — the
    /// bloom is heavily blurred and additive, so seeing the inputs is the only
    /// way to tell a dull card from a badly sampled one.
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            header("Header load-in")
            Text("The avatar pops from 62% on a spring with the friction "
                 + "dropped to 18 — a damping ratio of 0.5, so it overshoots. "
                 + "The stickers follow from 30%, and the three props travel "
                 + "in from their nearest edge on the page's own 320/28.")
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))
            Button("Replay") { accountReplay += 1 }
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .buttonStyle(.bordered)
                .tint(.white.opacity(0.9))
        }
    }

    private var topUpSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            header("Wallet card skin")
            Text("Drives three things at once: the card on the wallet page, "
                 + "the page's background, and the colours the bloom is built "
                 + "from. 17 is the design's own; 12 gives the strongest bloom.")
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(0..<SkinSelectSpec.skinCount, id: \.self) { slot in
                        let asset = SkinSelectSpec.asset(at: slot)
                        Button { topUp.skin = asset } label: {
                            Image(String(format: "skin_%02d", asset))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 58)
                                .clipShape(RoundedRectangle(cornerRadius: 6,
                                                            style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .strokeBorder(.white,
                                                      lineWidth: topUp.skin == asset ? 2 : 0)
                                }
                                .opacity(topUp.skin == asset ? 1 : 0.55)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 3)
            }
            .scrollIndicators(.hidden)
            .frame(height: 52)

            HStack(spacing: 6) {
                Text(String(format: "skin_%02d", topUp.skin))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.55))
                ForEach(Array(topUp.bloomColors.enumerated()), id: \.offset) { _, c in
                    Capsule().fill(c).frame(width: 26, height: 10)
                }
                Spacer(minLength: 0)
                Button("Replay") { topUp.replay += 1 }
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .buttonStyle(.bordered)
                    .tint(.white.opacity(0.9))
            }

            header("Sequence").padding(.top, 4)
            slider("Page retreat", $topUp.fade, 0.15...1.0, unit: "s", format: "%.2f")
            slider("Bloom rise", $topUp.rise, 0.2...1.6, unit: "s", format: "%.2f")
            slider("Dwell", $topUp.dwell, 0.4...5, unit: "s", format: "%.2f")
            slider("Sweep out", $topUp.sweep, 0.25...1.6, unit: "s", format: "%.2f")
            Text("Rise and sweep are the same driver on two curves \u{2014} growth "
                 + "front-loaded so the bloom is already huge when it leaves, "
                 + "lift and fade held back so it is still bright at the top.")
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))

            header("Sweep").padding(.top, 4)
            slider("Grow to", $topUp.sweepScale, 1.2...4.5, unit: "\u{00D7}", format: "%.2f")
            slider("Clearance", $topUp.sweepClear, 0.4...1.6, unit: "\u{00D7}", format: "%.2f")
            slider("Count up", $topUp.count, 0.2...2, unit: "s", format: "%.2f")
            slider("Count blur", $topUp.countBlur, 0...40, unit: "pt", format: "%.0f")
            slider("Hold landed", $topUp.settle, 0.1...2, unit: "s", format: "%.2f")
            Text("The hold runs from whichever finishes last, the sweep or the "
                 + "count \u{2014} so the wallet never arrives on a number that "
                 + "is still climbing.")
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))
            Text("Clearance 1.0 is exactly the lift that puts the last visible "
                 + "part of the bloom above the top edge, worked out from the "
                 + "cluster's own size, scale and blur. Below 1 it fades out "
                 + "on screen instead of leaving.")
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))

            header("Bloom").padding(.top, 4)
            slider("Blur", $topUp.bloomBlur, 16...110, unit: "pt", format: "%.0f")
            slider("Height", $topUp.bloomHeight, 240...680, unit: "pt", format: "%.0f")
            slider("Drift", $topUp.drift, 0...3, format: "%.2f")

            header("Page").padding(.top, 4)
            slider("Blur", $topUp.pageBlur, 0...44, unit: "pt", format: "%.0f")
            slider("Veil", $topUp.veil, 0.7...1, format: "%.3f")
            Text("The veil stops short of black on purpose: the page is light, "
                 + "and its white keys and chips showing through are what the "
                 + "bloom rises out of.")
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))
            Button("Reset motion") { topUp.reset() }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .buttonStyle(.bordered)
                .tint(.white.opacity(0.9))
        }
    }

    // MARK: button

    private var buttonSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            header("Press style")
            Picker("", selection: $button.style) {
                ForEach(ButtonLabTuning.PressStyle.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            Text(button.style == .round
                 ? "A 1:1 replica of the reference's dome. Raised and lit from "
                   + "above; pressed, lit from below under a lip, with a strong "
                   + "rim on top and a dark one along the bottom."
                 : button.style == .slab
                 ? "Two variants. 1: the design at rest, pressed state built here. "
                   + "2: both states from Figma's 2nd variant. Both share the press "
                   + "scale, bounce, response, depth and light-change duration."
                 : "The first brief: grows under the finger, fill and rim swap ends.")
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))
            if button.style == .slab {
                PressScaleRow()
            } else {
                slider("Scale", $button.pressScale, 1.0...1.12, unit: "\u{00D7}", format: "%.3f")
            }
            if button.style != .lift {
                slider("Shine", $button.shine, 0...1)
                slider("Shine width", $button.shineWidth, 0.3...2, unit: "\u{00D7}")
                if button.style == .slab { DropShadowRow(); PressShadeRows() }
                Text("The rim of light along the top edge while pressed. 1 and 1\u{00D7} "
                     + "are the calibrated look.")
                    .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))
            }
            if button.style != .slab {
                slider("Response", $button.springResponse, 0.08...0.6, unit: "s")
                slider("Damping", $button.springDamping, 0.3...1.0)
                slider("Lift shadow", $button.liftShadow, 0...0.4)
            }

            header("Colour flip").padding(.top, 4)
            Toggle(button.style == .lift ? "Swap fill and stroke" : "Change the light",
                   isOn: $button.flipEnabled).font(rowFont)
            slider("Duration", Binding(get: { button.flipDuration * 1000 },
                                       set: { button.flipDuration = $0 / 1000 }),
                   0...300, unit: "ms", format: "%.0f", enabled: button.flipEnabled)
            Text("Both ways at this duration. 80ms is the brief, and about what "
                 + "the reference takes \u{2014} 4 to 5 frames at 60fps.")
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))
            Button("Reset") { button.resetMotion() }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .buttonStyle(.bordered)
                .tint(.white.opacity(0.9))
        }
    }

    // MARK: bits

    private var rowFont: Font { .system(size: 13, weight: .medium, design: .rounded) }

    private func header(_ s: String) -> some View {
        Text(s.uppercased())
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.45))
            .kerning(0.8)
            .padding(.top, 4)
    }

    private func slider(_ label: String, _ value: Binding<Double>,
                        _ range: ClosedRange<Double>, unit: String = "",
                        format: String = "%.2f", enabled: Bool = true) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 12, design: .rounded))
                .frame(width: 92, alignment: .leading)
            Slider(value: value, in: range)
            Text(String(format: format, value.wrappedValue) + unit)
                .font(.system(size: 11, design: .monospaced))
                .frame(width: 52, alignment: .trailing)
        }
        .foregroundStyle(.white.opacity(enabled ? 0.85 : 0.3))
        .disabled(!enabled)
    }
}

/// The press haptic's controls. Its own view so it can observe the haptics
/// object directly — it lives inside the tuning object, and SwiftUI only
/// watches the object a view is handed.
private struct ButtonHapticsSection: View {
    @ObservedObject var h: PressHaptics

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PRESS HAPTIC")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.45)).kerning(0.8).padding(.top, 4)
            Toggle("On press-down", isOn: $h.enabled)
                .font(.system(size: 13, weight: .medium, design: .rounded))
            Picker("", selection: $h.source) {
                ForEach(PressHaptics.Source.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            if h.source == .impact {
                Picker("", selection: $h.style) {
                    ForEach(PressHaptics.Style.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            row("Intensity", $h.intensity)
            if h.source == .core {
                row("Sharpness", $h.sharpness)
                Text("Low sharpness is a dull thud, high a crisp click.")
                    .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))
            }
            Toggle("Also on release", isOn: $h.onRelease)
                .font(.system(size: 13, weight: .medium, design: .rounded))
            if h.onRelease { row("Release", $h.releaseIntensity) }
            Button("Feel it") { h.pressDown() }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .buttonStyle(.bordered)
                .tint(.white.opacity(0.9))
        }
        .disabled(false)
    }

    private func row(_ label: String, _ v: Binding<Double>) -> some View {
        HStack(spacing: 10) {
            Text(label).font(.system(size: 12, design: .rounded))
                .frame(width: 92, alignment: .leading)
            Slider(value: v, in: 0...1)
            Text(String(format: "%.2f", v.wrappedValue))
                .font(.system(size: 11, design: .monospaced))
                .frame(width: 52, alignment: .trailing)
        }
        .foregroundStyle(.white.opacity(0.85))
    }
}

/// The primary button's drop shadow — the shared value, so this moves every
/// such button in the app, not just the lab's.
/// The press-down's shadows on every primary and white button — the shared
/// values: the shade across the top of the sunk face, the well round the
/// button, and how far it drops.
private struct PressShadeRows: View {
    @ObservedObject var shadow = DomeShadow.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            row("Top shade", $shadow.topShade, 0...1, "%.2f")
            row("White shade", $shadow.whiteTopShade, 0...1, "%.2f")
            row("Well", $shadow.well, 0...1, "%.2f")
            row("Press depth", $shadow.pressDepth, 0...3, "%.1fpt")
            Toggle("Stroke changes on press", isOn: $shadow.strokeChange)
                .font(.system(size: 12, design: .rounded))
            Text("While held. Top shade is the shadow across the top of the face — "
                 + "dark button, then white; "
                 + "Well is the dark ring round the button, 0 to hide it. "
                 + "Stroke off keeps the outline's rest colours while held.")
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))
        }
        .foregroundStyle(.white.opacity(0.85))
    }

    private func row(_ title: String, _ value: Binding<Double>,
                     _ range: ClosedRange<Double>, _ format: String) -> some View {
        HStack(spacing: 10) {
            Text(title).font(.system(size: 12, design: .rounded))
                .frame(width: 92, alignment: .leading)
            Slider(value: value, in: range)
            Text(String(format: format, value.wrappedValue))
                .font(.system(size: 11, design: .monospaced))
                .frame(width: 52, alignment: .trailing)
        }
    }
}

private struct DropShadowRow: View {
    @ObservedObject var shadow = DomeShadow.shared

    var body: some View {
        HStack(spacing: 10) {
            Text("Drop shadow").font(.system(size: 12, design: .rounded))
                .frame(width: 92, alignment: .leading)
            Slider(value: $shadow.strength, in: 0...1)
            Text(String(format: "%.2f", shadow.strength))
                .font(.system(size: 11, design: .monospaced))
                .frame(width: 52, alignment: .trailing)
        }
        .foregroundStyle(.white.opacity(0.85))
    }
}

/// How far every primary and white button shrinks under the finger, and how
/// much it bounces — the shared values.
struct PressScaleRow: View {
    @ObservedObject var shared = DomeShadow.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            row("Press scale", $shared.pressScale, 0.85...1.0, "%.3f\u{00D7}")
            row("Bounce", $shared.pressBounce, 0...0.85, "%.2f")
            row("Response", $shared.pressResponse, 0.12...0.6, "%.2fs")
            Text("Every primary and white button, while held. Scale 1 is no change; "
                 + "bounce 0 settles without overshoot, higher dips past the held "
                 + "size and pops past full size on release.")
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))
        }
        .foregroundStyle(.white.opacity(0.85))
    }

    private func row(_ title: String, _ value: Binding<Double>,
                     _ range: ClosedRange<Double>, _ format: String) -> some View {
        HStack(spacing: 10) {
            Text(title).font(.system(size: 12, design: .rounded))
                .frame(width: 92, alignment: .leading)
            Slider(value: value, in: range)
            Text(String(format: format, value.wrappedValue))
                .font(.system(size: 11, design: .monospaced))
                .frame(width: 52, alignment: .trailing)
        }
    }
}

/// Builds its content in its own `body`, which SwiftUI calls in a separate
/// update — so a large section's views are laid out in that call's stack
/// frame instead of in the frame of whatever contains it.
private struct Deferred<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View { content() }
}
