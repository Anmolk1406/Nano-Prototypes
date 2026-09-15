import SwiftUI

/// The share screen from Figma `779:22071`, laid out at its native 375 × 812
/// and scaled to fit the device. Everything except the card is static chrome;
/// the card is the live gyro piece.
struct ShareScreen: View {
    @ObservedObject var motion: MotionEngine
    @ObservedObject var t: Tuning
    var onClose: () -> Void = {}

    var body: some View {
        GeometryReader { geo in
            let scale = max(geo.size.width / ScreenSpec.size.width,
                            geo.size.height / ScreenSpec.size.height)
            content
                .frame(width: ScreenSpec.size.width, height: ScreenSpec.size.height)
                .scaleEffect(scale, anchor: .center)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .ignoresSafeArea()
    }

    private var content: some View {
        ZStack(alignment: .topLeading) {
            Image("screen_backdrop")
                .resizable()
                .frame(width: ScreenSpec.size.width, height: ScreenSpec.size.height)

            closeButton
                .frame(width: ScreenSpec.closeButton.width, height: ScreenSpec.closeButton.height)
                .offset(x: ScreenSpec.closeButton.minX, y: ScreenSpec.closeButton.minY)

            // The card carries the caption and the avatar as its own layers, so
            // both move with it.
            GyroCardView(out: motion.out, t: t,
                         caption: (ScreenSpec.captionLine1, ScreenSpec.captionLine2))
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            motion.beginDrag()
                            motion.setDrag(CGPoint(x:  v.translation.width  / 140,
                                                   y: -v.translation.height / 140))
                        }
                        .onEnded { _ in motion.releaseDrag() }
                )
                .offset(x: ScreenSpec.card.minX, y: ScreenSpec.card.minY)

            bottomSheet
                .frame(width: ScreenSpec.sheet.width, height: ScreenSpec.sheet.height)
                .offset(x: ScreenSpec.sheet.minX, y: ScreenSpec.sheet.minY)
        }
        .frame(width: ScreenSpec.size.width, height: ScreenSpec.size.height, alignment: .topLeading)
    }

    // MARK: chrome

    // 779:22685 — M-IconButton, H40, Default emphasis.
    private var closeButton: some View {
        Button(action: onClose) {
            ZStack {
                Circle().fill(.white)
                Circle().strokeBorder(ScreenSpec.Palette.borderSubtle, lineWidth: 1)
                Image("ic_close")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(ScreenSpec.Palette.textPrimary)
            }
        }
        .buttonStyle(.plain)
    }

    // 779:22703 — Header Container.
    //
    // The container itself has NO fill in the design: the screen background
    // shows through behind the OR row and the invite field. Only the invite
    // field, the action bar and the home bar are white.
    private var bottomSheet: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                orDivider
                linkBox
            }
            .padding(20)

            // M-RowActionBar + Home bar — the only filled parts, and the only
            // ones that cast the container's upward shadow.
            VStack(spacing: 0) {
                shareButton
                    .padding(12)
                ZStack {
                    Color.white
                    Capsule()
                        .fill(ScreenSpec.Palette.homeBar)
                        .frame(width: 124, height: 5)
                }
                .frame(height: 24)
            }
            .background(.white)
            .shadow(color: Color(white: 0.878).opacity(0.5), radius: 11, y: -5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle().fill(ScreenSpec.Palette.separator).frame(height: 1)
            Text("OR")
                .figmaText(ScreenSpec.TypeScale.b12)
                .foregroundStyle(ScreenSpec.Palette.textMuted)
            Rectangle().fill(ScreenSpec.Palette.separator).frame(height: 1)
        }
    }

    // 779:22709 — Box
    private var linkBox: some View {
        HStack {
            Text(ScreenSpec.inviteLink)
                .figmaText(ScreenSpec.TypeScale.b14)
                .foregroundStyle(ScreenSpec.Palette.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 12)
            Image("ic_copy")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundStyle(ScreenSpec.Palette.textPrimary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(.white)
        .clipShape(Capsule())
        .overlay { Capsule().strokeBorder(ScreenSpec.Palette.borderAction, lineWidth: 1) }
    }

    // M-NeutralButton, H52
    private var shareButton: some View {
        Button {} label: {
            HStack(spacing: 8) {
                Image("ic_share")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                Text("Share invite")
                    .figmaText(ScreenSpec.TypeScale.a16)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(ScreenSpec.Palette.inverted)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
