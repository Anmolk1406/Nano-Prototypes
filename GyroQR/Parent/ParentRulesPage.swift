import SwiftUI

/// Frames 6, 7 and 8: Set Rules.
///
/// 6 (1015:45974) is auto-approve chosen. 7 (1015:45823) is manual chosen —
/// its card opens to "Select one": above an order limit, with the limit's
/// field, or for every order — and is 940 tall, so the options scroll under
/// the header. 8 (1015:45899) is the limit field being typed into, the number
/// pad up and the Back / Continue row riding it.
struct ParentRulesPage: View {
    @EnvironmentObject private var model: ParentModel
    @FocusState private var editing: Bool
    @State private var pressedCard: ParentModel.Approval?

    var body: some View {
        ParentStage {
            ParentHeaderBackground()
            ParentTitleHeader(title: "Set Rules", subtitle: "Set up approval rules for shopping") {
                ParentLottie(name: "parent_shield", size: ParentArt.shield.size, origin: ParentArt.shield.origin)
            }
            options
            ParentRowActions(onBack: { model.back() }, primary: "Continue") {
                editing = false
                model.push(.address)
            }
        }
    }

    // MARK: 1015:45852 — 16 in, 20 down; the cards 16 apart

    private var options: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    card(.auto)
                    card(.manual)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                // Room to scroll the last option clear of the action bar.
                .padding(.bottom, 20 + 100)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: editing) { _, now in
                guard now else { return }
                Haptics.shared.lightTap()
                // Frame 8: the options scrolled up under the header so the
                // field sits clear of the number pad.
                withAnimation(ParentSpec.spring) { proxy.scrollTo("select", anchor: .top) }
            }
        }
        .frame(width: 375, height: 812 - 258)
        .offset(y: 258)
    }

    private func card(_ kind: ParentModel.Approval) -> some View {
        let on = model.approval == kind
        return VStack(alignment: .leading, spacing: 24) {
            Button {
                guard model.approval != kind else { return }
                Haptics.shared.lightTap()
                editing = false
                withAnimation(ParentSpec.spring) { model.approval = kind }
            } label: {
                head(kind, on: on)
            }
            .buttonStyle(PressReport(pressed: Binding(
                get: { pressedCard == kind },
                set: { pressedCard = $0 ? kind : nil })))

            if kind == .manual && on {
                DashedDivider()
                select.id("select")
            }
        }
        // 12 of padding inside a 1pt border: CSS sizes the border inside the
        // box, so the content starts 13 in.
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(on ? AnyShapeStyle(LinearGradient(colors: [.white, Color(hex: kind == .manual ? 0xFBF0FF : 0xFDF5FF)],
                                                       startPoint: .top, endPoint: .bottom))
                         : AnyShapeStyle(Color.white))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(on ? Color(hex: 0xF6DBFF) : ParentSpec.C.borderSubtle, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        // The whole card dips under a press on its header.
        .scaleEffect(pressedCard == kind ? 0.99 : 1)
        .animation(.interpolatingSpring(stiffness: 320, damping: 28), value: pressedCard)
    }

    /// The art and the radio on one row, the title and its line under them.
    private func head(_ kind: ParentModel.Approval, on: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                art(kind)
                Spacer(minLength: 0)
                ParentDotRadio(on: on)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(kind == .auto ? "Auto-approve orders" : "Manually approve orders")
                    .parentType(ParentSpec.T.b16s)
                    .foregroundStyle(ParentSpec.C.textPrimary)
                Text(kind == .auto ? "\(model.firstName) can place orders using available wallet balance"
                                   : "Approve all orders or those over a specific amount.")
                    .parentType(ParentSpec.T.b13r)
                    .foregroundStyle(ParentSpec.C.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    /// 56 × 56, the render overscanned the way the design crops it.
    private func art(_ kind: ParentModel.Approval) -> some View {
        let (name, w, h, x, y): (String, CGFloat, CGFloat, CGFloat, CGFloat) = kind == .auto
            ? ("parent_rule_auto", 1.1666, 1.1667, -0.0833, -0.0542)
            : ("parent_rule_manual", 1.1604, 1.1604, -0.0774, -0.079)
        return Image(name)
            .resizable()
            .frame(width: 56 * w, height: 56 * h)
            .offset(x: 56 * x + 56 * (w - 1) / 2, y: 56 * y + 56 * (h - 1) / 2)
            .frame(width: 56, height: 56)
            .clipped()
    }

    /// `More Actions`: "Select one", then the two manual rules in a white
    /// panel — above a limit (with its field) and for every order.
    private var select: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select one")
                .parentType(ParentSpec.T.b14r)
                .foregroundStyle(ParentSpec.C.textSecondary)
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    rule(.aboveLimit, "Above an order limit")
                    if model.manualRule == .aboveLimit { limitField }
                }
                DashedDivider()
                rule(.everyOrder, "For every order")
                    .padding(.vertical, 8)
            }
            .padding(16)
            .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func rule(_ r: ParentModel.ManualRule, _ title: String) -> some View {
        Button {
            Haptics.shared.lightTap()
            if r != .aboveLimit { editing = false }
            withAnimation(ParentSpec.spring) { model.manualRule = r }
        } label: {
            HStack(spacing: 8) {
                Text(title)
                    .parentType(ParentSpec.T.b14s)
                    .foregroundStyle(ParentSpec.C.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ParentDotRadio(on: model.manualRule == r)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressDip(scale: 0.99, haptic: false))
    }

    /// The limit: the dirham mark and the amount, on the number pad.
    private var limitField: some View {
        HStack(spacing: 4) {
            Text(MoneyStyle.dirham)
                .font(NoonFont.f(.semibold, 14))
                .foregroundStyle(ParentSpec.C.textPrimary)
            TextField("", text: $model.limit)
                .font(NoonFont.f(.semibold, 14))
                .tracking(-0.1)
                .foregroundStyle(ParentSpec.C.textPrimary)
                .keyboardType(.numberPad)
                .focused($editing)
                .onChange(of: model.limit) { _, v in
                    let digits = String(v.filter(\.isNumber).prefix(6))
                    if digits != v { model.limit = digits }
                }
        }
        .frame(height: 20)
        .padding(.horizontal, 12)
        .frame(height: 56)
        .background(editing ? ParentSpec.C.surface : Color(hex: 0xF9F9FB),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(ParentSpec.C.borderPrimary, lineWidth: 1)
        }
        .animation(ParentSpec.spring, value: editing)
        .parentFocusRing(editing, corner: 16)
        .contentShape(Rectangle())
        .onTapGesture { editing = true }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

/// `M-Divider`, dashed: #EDDBFF, 4 on 4 off.
struct DashedDivider: View {
    var body: some View {
        Line()
            .stroke(Color(hex: 0xEDDBFF), style: StrokeStyle(lineWidth: 1, lineCap: .square, dash: [4, 4]))
            .frame(height: 1)
    }
    private struct Line: Shape {
        func path(in r: CGRect) -> Path {
            Path { p in p.move(to: CGPoint(x: 0.5, y: 0.5)); p.addLine(to: CGPoint(x: r.width - 0.5, y: 0.5)) }
        }
    }
}
