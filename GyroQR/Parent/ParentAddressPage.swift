import SwiftUI
import Lottie

/// Frames 9 and 10: pick a saved address, then Let's Go.
///
/// 9 (1015:45592) lists three saved addresses; any number can be ticked, the
/// first one to start with, and at least one before *Continue*. *Continue*
/// plays frame 10 (1015:45661) over the page — `Lets Go.lottie`, which is
/// the whole of that overlay, its purple and all — and hands on to the
/// invite.
struct ParentAddressPage: View {
    @EnvironmentObject private var model: ParentModel
    @State private var going = false

    private static let burj = ["Burj Khalifa, 1 Sheikh Mohammed bin Rashid Blvd,", "Downtown Dubai"]
    private let addresses: [(name: String, line: [String])] = [
        ("Work", burj), ("Ayush’s Dubai Place", burj), ("Ayush’s Dubai Place", burj),
    ]

    var body: some View {
        ParentStage {
            ParentHeaderBackground()
            ParentTitleHeader(title: "Add Address",
                              subtitle: "Select a saved address. \(model.firstName) can add more later") {
                ParentLottie(name: "parent_pin", size: ParentArt.pin.size, origin: ParentArt.pin.origin)
            }
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(addresses.indices, id: \.self) { i in card(i) }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 20 + 100)
            }
            .frame(width: 375, height: 812 - 258)
            .offset(y: 258)

            ParentRowActions(onBack: { model.back() }, primary: "Continue",
                             enabled: !model.addresses.isEmpty) { letsGo() }
                .onAppear {
                    // `-parentTickDemo` ticks the other two addresses and
                    // unticks the first, for recording the checkbox.
                    guard ProcessInfo.processInfo.arguments.contains("-parentTickDemo") else { return }
                    for (t, i) in [(1.2, 1), (1.9, 2), (2.8, 0)] {
                        DispatchQueue.main.asyncAfter(deadline: .now() + t) {
                            withAnimation(ParentSpec.spring) {
                                if model.addresses.contains(i) { model.addresses.remove(i) } else { model.addresses.insert(i) }
                            }
                        }
                    }
                }

            // Under Let's Go, not over it.
            ParentOverlayBar(page: .address)

            if going {
                LottieView { try await DotLottieFile.named("parent_letsgo") }
                    .playing(loopMode: .playOnce)
                    // On to the invite the moment it ends: it animates right up
                    // to its last frame, so there is nothing to wait for.
                    .animationDidFinish { _ in
                        model.push(.invite)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { going = false }
                    }
                    .resizable()
                    .frame(width: 375, height: 812)
                    .transition(.opacity)
            }
        }
    }

    private func letsGo() {
        model.setOverlay(true)
        withAnimation(.easeOut(duration: 0.15)) { going = true }
    }

    // MARK: `Address cards` — the ticked one lilac-topped, the rest grey

    private func card(_ i: Int) -> some View {
        let on = model.addresses.contains(i)
        let a = addresses[i]
        return Button {
            Haptics.shared.lightTap()
            withAnimation(ParentSpec.spring) {
                if on { model.addresses.remove(i) } else { model.addresses.insert(i) }
            }
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(on ? "parent_addr_work" : "parent_addr_home")
                        .resizable().frame(width: 20, height: 20)
                        .frame(width: 29, height: 29)
                        .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(on ? Color(hex: 0xF6DBFF).opacity(0.1) : ParentSpec.C.borderSubtle, lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.02), radius: 7.4, y: 12.9)
                    Text(a.name)
                        .font(NoonFont.f(.medium, 14)).tracking(-0.14)
                        .foregroundStyle(ParentSpec.C.ink)
                        .lineLimit(1)
                        .frame(height: 18)
                    Text("24 m")
                        .font(NoonFont.f(.bold, 10))
                        .foregroundStyle(on ? Color(red: 2 / 255, green: 6 / 255, blue: 12 / 255).opacity(0.6)
                                            : ParentSpec.C.textSecondary)
                        .frame(height: 12)
                        .padding(.top, 3).padding(.bottom, 4)
                        .frame(width: 37)
                        .background(.white, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    Spacer(minLength: 0)
                    ParentCheckbox(on: on)
                        .padding(.horizontal, 8)
                }
                .padding(.leading, 8).padding(.trailing, 4)
                .frame(height: 45)
                .background(on ? Color(hex: 0xFCF0FF) : .clear)

                VStack(alignment: .leading, spacing: 8) {
                    // Two 17pt lines, broken where the design breaks them.
                    ParentLines(lines: a.line, style: .init(weight: .regular, size: 13, line: 17, tracking: -0.05),
                                alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    // Zero-height in the design: the dashes hang over the
                    // gap between the two rows rather than taking a point.
                    Color.clear.frame(height: 0)
                        .overlay(alignment: .top) {
                            Line()
                                .stroke(ParentSpec.C.borderSubtle, style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [2, 2]))
                                .frame(height: 1)
                                .offset(y: -1)
                        }
                    HStack(spacing: 4) {
                        Text("Ahmed Ali,")
                        Text("+971-50 789 3456")
                        Image("parent_verified").resizable().frame(width: 14, height: 14)
                    }
                    .font(NoonFont.f(.regular, 12)).tracking(-0.05)
                    .foregroundStyle(ParentSpec.C.textPrimary)
                    .frame(height: 17)
                }
                .padding(12)
                .background(.white)
            }
            .background(on ? Color(hex: 0xF0F0F5) : Color(hex: 0xF9F9FB))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(on ? Color(hex: 0xF6DBFF) : ParentSpec.C.borderPrimary, lineWidth: 1)
            }
            // The ticked card's 2pt #FCF5FE ring, outside its border.
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: 0xFCF5FE))
                    .padding(-2)
                    .opacity(on ? 1 : 0)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PressDip(scale: 0.99, haptic: false))
    }

    private struct Line: Shape {
        func path(in r: CGRect) -> Path {
            Path { p in p.move(to: CGPoint(x: 0.5, y: 0.5)); p.addLine(to: CGPoint(x: r.width - 0.5, y: 0.5)) }
        }
    }
}

/// Frame 11: the invite QR screen the app already has.
struct ParentInvitePage: View {
    @EnvironmentObject private var model: ParentModel
    @ObservedObject var motion: MotionEngine
    @ObservedObject var tuning: Tuning

    var body: some View {
        ShareScreen(motion: motion, t: tuning, onClose: { model.restart() })
            .onAppear {
                tuning.cardStyle = .invite
                motion.start()
            }
            .onDisappear { motion.stop() }
    }
}
