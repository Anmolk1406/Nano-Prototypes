import SwiftUI

/// `M-Toast` (845:49129), the success/failure banner on the OTP step.
///
/// The design only draws the success variant; the error one reuses the same
/// anatomy on `surface/error-bold`, which is how the component's own
/// documentation describes its Error type.
struct Toast: Equatable, Identifiable {
    enum Kind { case success, failure }
    let id = UUID()
    let kind: Kind
    let message: String

    static func == (a: Toast, b: Toast) -> Bool { a.id == b.id }

    var surface: Color {
        switch kind {
        case .success: OnboardingSpec.C.successBold
        case .failure: OnboardingSpec.C.errorBold
        }
    }

    var glyph: String {
        switch kind {
        case .success: "ic_verified"
        case .failure: "ic_info_circle"
        }
    }
}

struct ToastView: View {
    let toast: Toast

    var body: some View {
        HStack(spacing: 8) {
            Image(toast.glyph)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundStyle(.white)
            Text(toast.message)
                .font(OnboardingSpec.F.b14s)
                .tracking(-0.1)
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(12)
        .background(toast.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(.white.opacity(0.08), lineWidth: 1))
        .shadow(color: Color(hex: 0x0B0C0E).opacity(0.10), radius: 7, y: 6)
    }
}

/// Drops a toast in from above and clears it after `dwell`.
///
/// Keyed on the toast's identity rather than on a Bool, so firing the same
/// message twice in a row still re-animates instead of sitting there looking
/// like nothing happened.
struct ToastHost: ViewModifier {
    @Binding var toast: Toast?
    var dwell: Double = 2.2

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let toast {
                ToastView(toast: toast)
                    .padding(.top, 53)     // Figma places the instance at y = 53
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task(id: toast.id) {
                        try? await Task.sleep(for: .seconds(dwell))
                        withAnimation(.easeInOut(duration: 0.25)) { self.toast = nil }
                    }
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: toast)
    }
}

extension View {
    func toastHost(_ toast: Binding<Toast?>) -> some View {
        modifier(ToastHost(toast: toast))
    }
}
