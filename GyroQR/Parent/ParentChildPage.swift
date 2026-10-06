import SwiftUI
import Lottie

/// Frame 1 (1015:44811): the child's details — names, birthday, gender,
/// *Continue*. Frame 2 plays over this page on *Continue*: "Kiaan is 10 Years
/// Old", `parent_celebration.json`, which is the whole of that overlay — its
/// dimmed plate, rays, hand and type — and fades itself in and out, so the
/// email page comes up as soon as it ends.
struct ParentChildPage: View {
    @EnvironmentObject private var model: ParentModel
    @FocusState private var focus: Field?
    @State private var celebrating = false

    private enum Field { case first, last }

    var body: some View {
        ParentStage {
            ParentHeaderBackground()
            ParentTitleHeader(title: "Child Details",
                              subtitle: "We’ll use these details to create their nano profile") {
                BotArt()
            }
            form
                .offset(y: 258)
            ParentActionBar {
                ParentPrimaryButton(title: "Continue", enabled: ready) { next() }
            }
            // Under the celebration, not over it.
            ParentOverlayBar(page: .child)
            if celebrating {
                LottieView(animation: .named("parent_celebration"))
                    .playing(loopMode: .playOnce)
                    .resizable()
                    .frame(width: 375, height: 812)
                    // Nothing under it takes a touch while it plays.
                    .contentShape(Rectangle())
                    .onTapGesture {}
            }
        }
        .onTapGesture { focus = nil }
        .onAppear {
            // `-parentAutoContinue` presses Continue a second in, for
            // capturing the celebration and the hand-off without a tap.
            if ProcessInfo.processInfo.arguments.contains("-parentAutoContinue") {
                // With the keyboard up first, the way it is after typing a name.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { focus = .first }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { next() }
            }
        }
        // A field taking focus — tapped into, or Next from the first name.
        .onChange(of: focus) { _, now in if now != nil { Haptics.shared.lightTap() } }
        .onChange(of: model.birthday) { Haptics.shared.lightTap() }
    }

    private var ready: Bool {
        !model.firstName.trimmingCharacters(in: .whitespaces).isEmpty
            && !model.lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func next() {
        guard !celebrating else { return }
        focus = nil
        model.setOverlay(true)
        celebrating = true
        // Not on its last frame: by then it has faded itself out and the bare
        // page would sit there a beat. The email page starts fading in as the
        // celebration starts fading out, so the two overlap.
        DispatchQueue.main.asyncAfter(deadline: .now() + ParentChildPage.celebrationHandOff) {
            guard model.stack.last == .child else { return }
            model.push(.email)
        }
    }

    /// Frame 76 of the celebration's 90, at 60fps: where its type, stars and
    /// rays begin to go.
    static let celebrationHandOff: Double = 76.0 / 60

    // MARK: form — 1015:44837, 16 in, 20 down, sections 32 apart

    private var form: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                ParentSectionTitle(text: "Child’s name")
                HStack(spacing: 8) {
                    nameBox("First name*", text: $model.firstName, field: .first)
                    nameBox("Last name*", text: $model.lastName, field: .last)
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    ParentSectionTitle(text: "Birthday")
                    Text("We'll make sure to make it special for them.")
                        .parentType(ParentSpec.T.b13r)
                        .foregroundStyle(ParentSpec.C.textTertiary)
                        .padding(.horizontal, 4)
                }
                birthdayField
            }
            VStack(alignment: .leading, spacing: 8) {
                ParentSectionTitle(text: "Gender")
                HStack(spacing: 8) {
                    genderCard(.boy, "Boy", avatar: "parent_avatar_boy")
                    genderCard(.girl, "Girl", avatar: "parent_avatar_girl")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .frame(width: 375, alignment: .topLeading)
    }

    private func nameBox(_ label: String, text: Binding<String>, field: Field) -> some View {
        ParentFieldBox(label: label, focused: focus == field) {
            TextField("", text: text)
                .font(NoonFont.f(.semibold, 14))
                .tracking(-0.14)
                .foregroundStyle(ParentSpec.C.ink)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .focused($focus, equals: field)
                .submitLabel(field == .first ? .next : .done)
                .onSubmit { focus = field == .first ? .last : nil }
                .frame(height: 18)
                .padding(.vertical, 2)
        }
    }

    /// `M-Input-alt`: the date, and a calendar glyph. The system date picker
    /// sits invisibly over the whole field, so a tap anywhere opens it.
    private var birthdayField: some View {
        HStack(spacing: 8) {
            Text(model.birthday.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year()))
                .parentType(ParentSpec.T.b14s)
                .foregroundStyle(ParentSpec.C.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Image("parent_calendar").resizable().frame(width: 20, height: 20)
        }
        .padding(.horizontal, 12)
        .frame(height: 56)
        .background(ParentSpec.C.field, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            DatePicker("", selection: $model.birthday, in: ...Date.now, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
                .colorMultiply(.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .opacity(0.011)
                // The picker opening is the field taking focus.
                .simultaneousGesture(TapGesture().onEnded { Haptics.shared.lightTap() })
        }
    }

    /// A `Search result` card: the hexagon avatar, the label, a radio.
    private func genderCard(_ g: ParentModel.Gender, _ label: String, avatar: String) -> some View {
        let on = model.gender == g
        return Button {
            Haptics.shared.lightTap()
            withAnimation(ParentSpec.spring) { model.gender = g }
        } label: {
            HStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(avatar)
                        .resizable()
                        .frame(width: 35.797, height: 38.8)
                        .frame(width: 34.997, height: 38)
                    Text(label)
                        .parentType(ParentSpec.T.label2)
                        .foregroundStyle(ParentSpec.C.label)
                }
                Spacer(minLength: 0)
                ParentTickRadio(on: on)
            }
            // The design's 12 × 8 inside its 1pt border.
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .background(on ? ParentSpec.C.selectedFill : ParentSpec.C.cardSubtle,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(on ? ParentSpec.C.selectedStroke : ParentSpec.C.borderSubtle, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        // The haptic is the action's, so it lands on the tick.
        .buttonStyle(PressDip(scale: 0.99, haptic: false))
    }
}

/// The bot, over the soft purple glow the design keeps behind it.
private struct BotArt: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            // `image 1583515812`, flipped, cropped to its top 70%, blurred 50:
            // a haze, not a shape — the bot's shadow of colour on the header.
            Image("parent_bot_glow")
                .resizable()
                .frame(width: 113.51, height: 156.21)
                .frame(width: 113.442, height: 108.895, alignment: .top)
                .clipped()
                .scaleEffect(x: -1, y: 1)
                .blur(radius: 50)
                .offset(x: (235 - 113.442) / 2, y: 125 - 26.11 - 108.895)
            ParentLottie(name: "parent_bot", size: ParentArt.bot.size, origin: ParentArt.bot.origin)
        }
        .frame(width: 235, height: 125, alignment: .topLeading)
    }
}

/// Where each header Lottie's canvas sits in the 235 × 125 art box, found by
/// matching its last frame against the Figma render of its page: the Lottie's
/// own pixels, isolated by a screenshot with and one without it
/// (`-parentNoArt`), slid over the render until the header matches best.
enum ParentArt {
    static let bot = (size: CGSize(width: 455, height: 195), origin: CGPoint(x: -111, y: -36))
    static let email = (size: CGSize(width: 240, height: 140), origin: CGPoint(x: -2.5, y: -14))
    static let shield = (size: CGSize(width: 240, height: 140), origin: CGPoint(x: -1.5, y: -9))
    static let pin = (size: CGSize(width: 240, height: 140), origin: CGPoint(x: -2.5, y: -10))
}
