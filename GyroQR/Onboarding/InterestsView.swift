import SwiftUI

/// Step 6 — `Interest Page` (1113:27168).
///
/// Ten categories, two across, each the `Chips` component (1113:19319) with
/// its own render. Selected is the component's other variant: white with a
/// 1pt #D6E9FF border, a pastel sheen in the corner and the label in a
/// purple-to-sky gradient.
struct InterestsView: View {
    @ObservedObject var tune: OnboardingTuning
    var onBack: () -> Void = {}
    var onContinue: (Set<String>) -> Void
    var onSkip: () -> Void

    private struct Category: Identifiable {
        let id: String       // slug, and the selection key
        let title: String
    }

    /// The design's order, read left to right, then down.
    private let categories: [Category] = [
        .init(id: "art",     title: "Art"),
        .init(id: "gadgets", title: "Gadgets"),
        .init(id: "stem",    title: "STEM"),
        .init(id: "science", title: "Science"),
        .init(id: "beauty",  title: "Beauty"),
        .init(id: "gaming",  title: "Gaming"),
        .init(id: "fashion", title: "Fashion"),
        .init(id: "pets",    title: "Pets"),
        .init(id: "anime",   title: "Anime"),
        .init(id: "toys",    title: "Toys"),
    ]

    private let minimum = 3

    @State private var picked: Set<String> = []

    /// `-interestsAll` opens with everything selected, so the selected
    /// variant can be looked at directly.
    private var preselectAll: Bool {
        ProcessInfo.processInfo.arguments.contains("-interestsAll")
    }

    private var ready: Bool { picked.count >= minimum }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white
            KidGridBackdrop()

            KidTitle(lines: [
                KidTitleLine(text: "What are your", frame: CGRect(x: 69.5, y: 112.32, width: 236, height: 48), angle: 40.9238),
                // This line's purple stop is further out — 118% — so less
                // of it reaches the box.
                KidTitleLine(text: "interests?", frame: CGRect(x: 104.5, y: 143.5, width: 166, height: 48), angle: 51.6897,
                             endColor: Color(hex: 0x571AB8)),
            ], bars: [
                CGRect(x: 103.797, y: 141.442, width: 162.468, height: 24.712),
                CGRect(x: 77.017, y: 133.314, width: 193.184, height: 16.006),
            ])

            Text(prompt)
                .font(OnboardingSpec.F.b16)
                .tracking(-0.15)
                .foregroundStyle(OnboardingSpec.C.tertiary)
                .contentTransition(.numericText())
                .frame(width: 278, height: 22)
                .offset(x: 48.5, y: 200.835)

            grid.offset(x: 16, y: 246.835)

            KidHeaderBar(active: 2, onBack: onBack)

            actionBar.offset(y: 682)
        }
        .frame(width: OnboardingSpec.size.width, height: OnboardingSpec.size.height,
               alignment: .topLeading)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: picked)
        .onAppear {
            Haptics.shared.prepare()
            if preselectAll { picked = Set(categories.map(\.id)) }
        }
    }

    private var prompt: String {
        if picked.isEmpty { return "Pick at least \(minimum) interests" }
        let short = minimum - picked.count
        return short > 0 ? "\(short) more to go" : "Nice — that’s enough to start"
    }

    /// `Frame 2147229647`: the Continue row, `Skip for now` under it and the
    /// home strip, on white with 24pt top corners.
    private var actionBar: some View {
        VStack(spacing: 2) {
            VStack(spacing: 0) {
                ParentPrimaryButton(title: "Continue", enabled: ready) { onContinue(picked) }
                    .padding(12)
                Button {
                    Haptics.shared.selectionTick()
                    onSkip()
                } label: {
                    Text("Skip for now")
                        .font(OnboardingSpec.F.a14)
                        .foregroundStyle(OnboardingSpec.C.grey500)
                        .padding(.horizontal, 8)
                        .frame(height: 28)
                }
                .buttonStyle(.plain)
            }
            Color.clear.frame(height: 24)
        }
        .frame(width: 375)
        .background(.white, in: UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24,
                                                       style: .continuous))
    }

    private var grid: some View {
        VStack(spacing: 13) {
            ForEach(0..<(categories.count / 2), id: \.self) { row in
                HStack(spacing: 13) {
                    tile(categories[row * 2])
                    tile(categories[row * 2 + 1])
                }
                .frame(height: 74.8)
            }
        }
        .frame(width: 343)
    }

    /// One `Chips`: 165 × 75, 20pt corners, H18 Bold label at (16, 16), the
    /// render's 60pt box at (103, 27) running off the foot and clipped.
    private func tile(_ item: Category) -> some View {
        let on = picked.contains(item.id)
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        return Button {
            toggle(item.id)
        } label: {
            ZStack(alignment: .topLeading) {
                Color(hex: 0xF9F9FB)
                // Selected: white, with the sheen over it.
                ZStack(alignment: .topLeading) {
                    Color.white
                    Image("int3d_selected_bg")
                        .resizable()
                        .frame(width: 214, height: 120)
                        .offset(x: -49, y: -29)
                }
                // The sheen is bigger than the chip; it must not size it.
                .frame(width: 165, height: 75, alignment: .topLeading)
                .clipped()
                .opacity(on ? 1 : 0)

                label(item.title, on: on).offset(x: 16, y: 16)

                Image("int3d_\(item.id)")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipped()
                    .offset(x: 103, y: 27)
            }
            .frame(width: 165, height: 75)
            .clipShape(shape)
            .overlay(shape.strokeBorder(Color(hex: 0xD6E9FF), lineWidth: 1).opacity(on ? 1 : 0))
        }
        .buttonStyle(PressDip(scale: 0.97, haptic: false))
    }

    /// H18 Bold: #343D54, or the selected variant's #A73BF3 → #6CC3FC.
    private func label(_ title: String, on: Bool) -> some View {
        let text = Text(title)
            .font(NoonFont.f(.bold, 18))
            .tracking(-0.15)
            .frame(height: 24)
            .fixedSize()
        return ZStack {
            text.foregroundStyle(Color(hex: 0x343D54)).opacity(on ? 0 : 1)
            text.foregroundStyle(LinearGradient(colors: [Color(hex: 0xA73BF3), Color(hex: 0x6CC3FC)],
                                                startPoint: .top, endPoint: .bottom))
                .opacity(on ? 1 : 0)
        }
    }

    private func toggle(_ id: String) {
        if picked.contains(id) {
            picked.remove(id)
            Haptics.shared.selectionTick()
        } else {
            picked.insert(id)
            // The tick that takes you over the line is worth more than the ones
            // before it — it's the moment Continue arms.
            if picked.count == minimum { Haptics.shared.success() } else { Haptics.shared.keyTick() }
        }
    }
}
