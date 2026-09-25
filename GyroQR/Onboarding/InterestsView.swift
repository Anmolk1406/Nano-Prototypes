import SwiftUI

/// Step 6 — `Interest Page` (845:50568), with the categories from
/// `Category assets` (848:53680).
///
/// Ten categories, two across. Selected swaps the grey plate for brand-blue-50
/// with an action-bold border, recolours the label and drops a check badge in
/// the corner — the two states the design draws (845:50619 vs 845:50623).
///
/// The design's own frame still shows the eight it was drawn with (Art, Gaming,
/// Sports, Fashion, Lego, Pets, Science, Anime) at 92pt tall. Ten of those plus
/// the header and the CTA come to 886pt on an 812pt screen, so the tile is 72pt
/// here and the label is allowed two lines — the new names are phrases, not
/// single words. Everything else is the design's.
struct InterestsView: View {
    @ObservedObject var tune: OnboardingTuning
    var onContinue: (Set<String>) -> Void
    var onSkip: () -> Void

    private struct Category: Identifiable {
        let id: String       // slug, and the selection key
        let title: String
    }

    /// Sheet order, read left-to-right then down.
    private let categories: [Category] = [
        .init(id: "gaming",   title: "Gaming"),
        .init(id: "tech",     title: "Tech & Gadgets"),
        .init(id: "reading",  title: "Reading & Stories"),
        .init(id: "arts",     title: "Arts & Crafts"),
        .init(id: "building", title: "Building & STEM"),
        .init(id: "beauty",   title: "Beauty & Self care"),
        .init(id: "sneakers", title: "Sneakers & Style"),
        .init(id: "room",     title: "Room Makeover"),
        .init(id: "sports",   title: "Sports & Outdoor"),
        .init(id: "plush",    title: "Plush & Collectibles"),
    ]

    private let minimum = 3
    private let tileHeight: CGFloat = 72
    private let gutter: CGFloat = 10

    @State private var picked: Set<String> = []
    @State private var appeared = false

    /// `-interestsAll` opens with everything selected. The tile is 72pt tall
    /// and both the check badge and the render live on its right edge, so the
    /// selected state is the one worth being able to look at directly.
    private var preselectAll: Bool {
        ProcessInfo.processInfo.arguments.contains("-interestsAll")
    }

    private var ready: Bool { picked.count >= minimum }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                LinearGradient(colors: [OnboardingSpec.C.brandBlue100, .white],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 188)
                Color.white
            }

            VStack(spacing: 0) {
                StepDots(active: 2).padding(.top, 76)

                VStack(spacing: 8) {
                    Text("What are your\ninterests?")
                        .font(OnboardingSpec.F.h32)
                        .tracking(-0.25)
                        .lineSpacing(2)
                        .foregroundStyle(OnboardingSpec.C.primary)
                    Text(prompt)
                        .font(OnboardingSpec.F.b16)
                        .tracking(-0.15)
                        .foregroundStyle(ready ? OnboardingSpec.C.successBold
                                               : OnboardingSpec.C.tertiary)
                        .contentTransition(.numericText())
                }
                .multilineTextAlignment(.center)
                .frame(width: 217)
                .padding(.top, 20)

                grid.padding(.top, 28)

                Spacer(minLength: 0)

                CTABar {
                    NeutralCTA(title: "Continue", enabled: ready) { onContinue(picked) }
                    Button {
                        Haptics.shared.selectionTick()
                        onSkip()
                    } label: {
                        Text("Skip for now")
                            .font(OnboardingSpec.F.a14)
                            .foregroundStyle(OnboardingSpec.C.tertiary)
                            .frame(height: 36)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: OnboardingSpec.size.height)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 18)
        }
        .frame(width: OnboardingSpec.size.width, height: OnboardingSpec.size.height,
               alignment: .top)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: picked)
        .onAppear {
            Haptics.shared.prepare()
            withAnimation(.spring(response: 0.46, dampingFraction: 0.84)) { appeared = true }
            if preselectAll { picked = Set(categories.map(\.id)) }
        }
    }

    private var prompt: String {
        if picked.isEmpty { return "Pick at least \(minimum) interests" }
        let short = minimum - picked.count
        return short > 0 ? "\(short) more to go" : "Nice — that’s enough to start"
    }

    private var grid: some View {
        VStack(spacing: gutter) {
            ForEach(0..<(categories.count / 2), id: \.self) { row in
                HStack(spacing: gutter) {
                    tile(categories[row * 2])
                    tile(categories[row * 2 + 1])
                }
            }
        }
        .frame(width: 343)
    }

    private func tile(_ item: Category) -> some View {
        let on = picked.contains(item.id)
        return Button {
            toggle(item.id)
        } label: {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(on ? OnboardingSpec.C.brandBlue50 : OnboardingSpec.C.grey100)

                Text(item.title)
                    .font(NoonFont.f(.bold, 16))
                    .tracking(-0.15)
                    .lineSpacing(-1)
                    .lineLimit(2)
                    .minimumScaleFactor(0.84)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(on ? OnboardingSpec.C.actionBold : OnboardingSpec.C.grey800)
                    .frame(width: 96, alignment: .topLeading)
                    .padding(.leading, 14)
                    .padding(.top, 13)

                // Bottom-right, as in the design. The three numbers here, the
                // badge's two below, and `CategoryArt.maxHeight` are one
                // decision: art bottom-anchored at 2 with a 44pt ceiling
                // starts at y 26, and a 20pt badge inset 6 ends at y 26. They
                // meet and never overlap. At the design's 22pt badge and 50pt
                // art the brush, the perfume bottle and the bear all had a
                // check stamped through them.
                art(item)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 9)
                    .padding(.bottom, 2)
                    .scaleEffect(on ? 1.06 : 1, anchor: .bottomTrailing)

                Image("ic_check_solid")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 8)
                    .padding(.top, 6)
                    .opacity(on ? 1 : 0)
                    .scaleEffect(on ? 1 : 0.5)
            }
            .frame(height: tileHeight)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(on ? OnboardingSpec.C.actionBold : .clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func art(_ item: Category) -> some View {
        let name = "cat_\(item.id)_\(tune.categoryArt.suffix)"
        let box = CategoryArt.box(for: name)
        return Image(name)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: box.width, height: box.height)
            .shadow(color: .black.opacity(0.10), radius: 5, y: 3)
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

/// Sizing for the category renders.
///
/// These twenty trim to aspects between 0.75 and 2.5 — a tall perfume bottle
/// and a wide pair of sunglasses are the extremes. Dropping them all into one
/// fixed box makes the wide ones look like slivers and the tall ones tower, so
/// each is sized to the same *area* instead, which is what actually reads as
/// equal weight. The aspect comes from the asset itself, so re-exporting a
/// render needs no change here.
enum CategoryArt {
    /// Area of a 42pt square. The ceiling is what the tile can actually give
    /// without running into the selected-state check badge — see `tile`.
    private static let area: CGFloat = 42 * 42
    private static let maxWidth: CGFloat = 60
    private static let maxHeight: CGFloat = 44

    private static var cache = [String: CGSize]()

    static func box(for name: String) -> CGSize {
        if let hit = cache[name] { return hit }
        let natural = UIImage(named: name)?.size ?? CGSize(width: 1, height: 1)
        let aspect = max(0.2, natural.width / max(natural.height, 1))

        var h = (area / aspect).squareRoot()
        var w = aspect * h
        if w > maxWidth  { w = maxWidth;  h = w / aspect }
        if h > maxHeight { h = maxHeight; w = aspect * h }

        let box = CGSize(width: w.rounded(), height: h.rounded())
        cache[name] = box
        return box
    }
}
