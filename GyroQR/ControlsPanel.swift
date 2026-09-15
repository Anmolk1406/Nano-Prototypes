import SwiftUI

struct ControlsPanel: View {
    @ObservedObject var motion: MotionEngine
    @ObservedObject var t: Tuning
    @ObservedObject var haptics = Haptics.shared
    @ObservedObject var skin: SkinTuning
    @Binding var scene: AppScene
    @Binding var expanded: Bool

    var body: some View {
        VStack(spacing: 0) {
            handle
            if expanded {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        sceneSection
                        Divider().overlay(.white.opacity(0.12))
                        if scene == .skinSelect {
                            motionSection
                            Divider().overlay(.white.opacity(0.12))
                            gestureSection
                            Divider().overlay(.white.opacity(0.12))
                            arcSection
                            Divider().overlay(.white.opacity(0.12))
                            hapticsSection
                        }
                        if scene == .qrCard {
                            sourceSection
                        Divider().overlay(.white.opacity(0.12))
                        tiltSection
                        Divider().overlay(.white.opacity(0.12))
                        lightSection
                        Divider().overlay(.white.opacity(0.12))
                        stageSection
                        }
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
            Picker("", selection: $scene) {
                ForEach(AppScene.allCases) { s in Text(s.rawValue).tag(s) }
            }
            .pickerStyle(.segmented)
            if scene == .skinSelect {
                Text("Swipe the card up to cycle skins, drag it down to confirm.")
                    .font(.system(size: 11)).foregroundStyle(.white.opacity(0.55))
            }
        }
    }

    private var motionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            header("Entry & hints")
            Toggle("Deal-in on appear", isOn: $skin.entryEnabled).font(rowFont)
            slider("Response", $skin.entryResponse, 0.2...0.7, unit: "s", format: "%.2f",
                   enabled: skin.entryEnabled)
            slider("Stagger", $skin.entryStagger, 0...0.12, unit: "s", format: "%.3f",
                   enabled: skin.entryEnabled)
            Toggle("Idle gesture hints", isOn: $skin.hintsEnabled).font(rowFont)
            slider("Cycle hint", $skin.hintCycleAmount, 0...0.4, enabled: skin.hintsEnabled)
            slider("Pull hint", $skin.hintPullAmount, 0...0.4, enabled: skin.hintsEnabled)
            slider("Repeat every", $skin.hintRepeat, 2...12, unit: "s", format: "%.0f",
                   enabled: skin.hintsEnabled)
        }
    }

    /// Sensitivity. Travel scales how far the finger has to go, not how far the
    /// card moves — so a longer drag reads as weight, not as a bigger animation.
    private var gestureSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            header("Gesture")
            slider("Drag travel", $skin.dragTravel, 0.5...2.0, format: "%.2f")
            Text(String(format: "Throw %.0fpt \u{00B7} pull %.0fpt \u{00B7} commits at %.0f%%",
                        SkinSelectSpec.cycleThreshold * skin.dragTravel,
                        SkinSelectSpec.confirmThreshold * skin.dragTravel,
                        SkinSelectSpec.commitFraction * 100))
                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))
            slider("Throw detents", $skin.cycleDetents, 0...12, format: "%.0f",
                   enabled: haptics.isEnabled)
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
            header("Stage")
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
