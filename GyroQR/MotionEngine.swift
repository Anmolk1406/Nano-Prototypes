import SwiftUI
import CoreMotion
import QuartzCore

/// The high-rate half of the motion state, deliberately kept in its own
/// observable object.
///
/// `tilt` changes every display frame. Anything that observes it rebuilds at
/// 120 Hz — and a `Slider` or `Picker` that is rebuilt that often never gets to
/// finish a gesture. Keeping it apart from `MotionEngine`'s settings means the
/// controls only rebuild when a setting actually changes.
@MainActor
final class MotionOutput: ObservableObject {
    @Published fileprivate(set) var tilt = CGPoint.zero   // smoothed
    @Published fileprivate(set) var raw  = CGPoint.zero   // pre-smoothing
}

/// Normalised tilt driver. Produces a smoothed tilt in roughly -1...1 on both
/// axes from whichever source is selected, so every visual effect downstream
/// reads from one place and behaves the same on device and in the Simulator.
@MainActor
final class MotionEngine: ObservableObject {

    enum Source: String, CaseIterable, Identifiable {
        case motion = "Gyro"
        case drag   = "Drag"
        case demo   = "Demo"
        var id: String { rawValue }
    }

    /// Per-frame output. Observe this only where you need the live value.
    let out = MotionOutput()

    // Settings — low frequency, safe for the controls to observe.
    @Published private(set) var motionAvailable = false
    @Published var source: Source = .motion
    /// 0 = frozen, 1 = no smoothing. Applied per-frame, frame-rate independent.
    @Published var smoothing: Double = 0.14
    /// Degrees of physical tilt that map to a full ±1 deflection.
    @Published var rangeDegrees: Double = 30
    @Published var demoSpeed: Double = 0.55
    /// Hold the phone still and the card eases back to flat, treating however
    /// you are holding it as the new level. Gyro only — drag already springs
    /// back on release, and demo is meant to keep moving.
    @Published var autoRecenter = true
    @Published var idleDelay: Double = 1.5

    private let manager = CMMotionManager()
    private var reference: CMAttitude?
    private var proxy: LinkProxy?
    private var link: CADisplayLink?
    private var drag = CGPoint.zero
    private var phase: Double = 0

    // Idle re-centring. `bias` is the pose currently treated as level; while the
    // phone is still it creeps toward the live reading, which walks the output
    // back to zero.
    private var bias = CGPoint.zero
    private var lastSample = CGPoint.zero
    private var idleFor: Double = 0
    /// Units/second of change below which the phone counts as held still.
    private let stillSpeed: Double = 0.35
    /// Time for the bias to close half the remaining gap once idle.
    private let recenterHalfLife: Double = 0.45

    // MARK: lifecycle

    func start() {
        motionAvailable = manager.isDeviceMotionAvailable
        // No gyro means the Simulator. Demo mode shows the effect straight away
        // instead of presenting a card that looks static and broken.
        if !motionAvailable, source == .motion { source = .demo }

        if motionAvailable, !manager.isDeviceMotionActive {
            manager.deviceMotionUpdateInterval = 1.0 / 120.0
            manager.startDeviceMotionUpdates(using: .xArbitraryZVertical)
        }
        guard link == nil else { return }
        let p = LinkProxy { [weak self] dt in self?.step(dt) }
        let l = CADisplayLink(target: p, selector: #selector(LinkProxy.tick(_:)))
        l.add(to: .main, forMode: .common)
        proxy = p
        link = l
    }

    func stop() {
        link?.invalidate(); link = nil; proxy = nil
        if manager.isDeviceMotionActive { manager.stopDeviceMotionUpdates() }
    }

    /// Treat however the phone is currently held as "flat".
    func recenter() {
        reference = manager.deviceMotion?.attitude.copy() as? CMAttitude
        bias = .zero
        lastSample = .zero
        idleFor = 0
        phase = 0
    }

    /// True while the idle timer has elapsed and the card is easing back.
    @Published private(set) var isRecentring = false

    // MARK: drag source

    func beginDrag() {
        // Guarded so a drag does not republish `source` on every frame.
        guard source != .drag else { return }
        source = .drag
    }
    func setDrag(_ p: CGPoint) {
        drag = CGPoint(x: max(-1, min(1, p.x)), y: max(-1, min(1, p.y)))
    }
    func releaseDrag() { drag = .zero }

    // MARK: per-frame

    private func step(_ dt: Double) {
        var next: CGPoint
        switch source {
        case .motion:
            if let dm = manager.deviceMotion,
               let attitude = dm.attitude.copy() as? CMAttitude {
                if reference == nil { reference = attitude.copy() as? CMAttitude }
                if let ref = reference { attitude.multiply(byInverseOf: ref) }
                let r = attitude.roll  * 180 / .pi
                let p = attitude.pitch * 180 / .pi
                let sample = CGPoint(x: clamp(r / rangeDegrees), y: clamp(p / rangeDegrees))

                let speed = hypot(sample.x - lastSample.x, sample.y - lastSample.y) / max(dt, 1e-4)
                lastSample = sample
                idleFor = speed < stillSpeed ? idleFor + dt : 0

                if autoRecenter, idleFor >= idleDelay {
                    let k = 1 - pow(0.5, dt / recenterHalfLife)
                    bias.x += (sample.x - bias.x) * k
                    bias.y += (sample.y - bias.y) * k
                    if !isRecentring { isRecentring = true }
                } else if isRecentring {
                    isRecentring = false
                }
                next = CGPoint(x: clamp(sample.x - bias.x), y: clamp(sample.y - bias.y))
            } else {
                next = .zero
            }
        case .drag:
            if isRecentring { isRecentring = false }
            next = drag
        case .demo:
            if isRecentring { isRecentring = false }
            phase += dt * demoSpeed
            // Two incommensurate frequencies so the loop never looks like a loop.
            next = CGPoint(x: sin(phase), y: cos(phase * 0.73) * 0.8)
        }
        out.raw = next

        // Exponential smoothing normalised to a 60 Hz step.
        let a = 1 - pow(1 - max(0.001, min(1, smoothing)), dt * 60)
        out.tilt = CGPoint(x: out.tilt.x + (next.x - out.tilt.x) * a,
                           y: out.tilt.y + (next.y - out.tilt.y) * a)
    }

    private func clamp(_ v: Double) -> Double { max(-1, min(1, v)) }

    /// CADisplayLink needs an ObjC target; keep the engine itself a plain class.
    private final class LinkProxy: NSObject {
        private let body: (Double) -> Void
        private var last: CFTimeInterval = 0
        init(_ body: @escaping (Double) -> Void) { self.body = body }
        @objc func tick(_ link: CADisplayLink) {
            let dt = last == 0 ? 1.0 / 60.0 : min(0.1, link.timestamp - last)
            last = link.timestamp
            MainActor.assumeIsolated { body(dt) }
        }
    }
}
