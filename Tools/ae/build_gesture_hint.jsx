// Builds GESTURE_DOWN and GESTURE_UP — the skin picker's hand hints, Figma
// `gesture animate - down` (1060:19705) and `- up` (1060:19706) — into the
// open After Effects project, in their own folder. Nothing else is touched,
// and the project is not saved.
//
//   osascript -e 'tell application "Adobe After Effects 2026" to DoScriptFile
//                 "/…/Tools/ae/build_gesture_hint.jsx"'
//
// The parts come from `Tools/build_gesture_hint_layers.py`
// (Tools/ae/gesture_hint/). Each comp is 2x — 240 × 580, the design's
// 118 × 180.6 frame at (1, 40)pt with room round it for the hand's travel —
// at 60fps, and runs once in 2.0s. Figma's frame is the gesture's *end*:
// the finger at the end of its trail. Here the finger starts at the other
// end of the track and draws the trail as it goes.
//
// THE TIMING IS SHARED WITH THE APP. `GestureHintTiming` in
// GyroQR/SkinGestureHint.swift holds the same numbers, and the picker moves
// the card on them, so the card goes as the finger drags and settles as it
// lets go. Change one, change the other.
//
//   0.00 → 0.25  the hand arrives: fades in, settles from 112%
//   0.25 → 0.35  press: the hand dips to 92%, the dot lights
//   0.35 → 1.05  drag, ease-in-out cubic — the card nudge's own curve
//   1.05 → 1.20  release: the hand springs back, the dot goes out
//   1.10 → 1.50  the hand, trail and chevrons fade
//   1.50 → 2.00  nothing, so a replay starts clean
//
// Lottie-safe by construction: image layers and transforms only, and no
// parenting — every layer works its position out from the same finger
// expression. `export_gesture_hint.jsx` samples it all to keyframes.
//
// Re-running replaces the previous build (the folder is removed first).

(function () {
    var ROOT = "/Users/anmkumar/Nano/GyroQR/Tools/ae/";
    var DIR = ROOT + "gesture_hint/";
    var LOG = new File(DIR + "build_log.txt");
    var lines = [];
    LOG.lineFeed = "Unix";
    function log(s) {
        lines.push(s);
        if (LOG.open("w")) { LOG.write(lines.join(String.fromCharCode(10))); LOG.close(); }
    }
    var failed = false;
    function step(name, fn) {
        if (failed) { log("skip " + name); return; }
        try { fn(); log("ok   " + name); }
        catch (e) { failed = true; log("FAIL " + name + ": " + e.toString() + " (line " + e.line + ")"); }
    }

    var FPS = 60, DUR = 2.0, W = 240, H = 580;
    var layout;
    step("read layout", function () {
        var f = new File(DIR + "layout.json");
        f.open("r"); var txt = f.read(); f.close();
        layout = eval("(" + txt + ")");
    });
    if (failed) return;

    app.beginUndoGroup("Build gesture hints");
    var proj = app.project, folder, foot = {};

    step("clear previous build", function () {
        for (var i = proj.numItems; i >= 1; i--) {
            var it = proj.item(i);
            if (it instanceof FolderItem && it.name === "GyroQR - Gesture hint") it.remove();
        }
    });
    step("folder + footage", function () {
        folder = proj.items.addFolder("GyroQR - Gesture hint");
        var names = ["trail", "dot", "chev", "hand"];
        for (var i = 0; i < names.length; i++) {
            var f = proj.importFile(new ImportOptions(new File(DIR + names[i] + ".png")));
            f.parentFolder = folder;
            f.mainSource.alphaMode = AlphaMode.STRAIGHT;
            foot[names[i]] = f;
        }
    });

    function tr(L) { return L.property("ADBE Transform Group"); }

    // Design points → comp pixels. The frame sits at (1, 40)pt.
    function px(x) { return (1 + x) * 2; }
    function py(y) { return (40 + y) * 2; }

    // The finger, shared by every layer. `Y0`/`Y1` are its start and end in
    // comp pixels.
    function head(Y0, Y1) {
        return [
            "var T = {arrive: 0.25, press: 0.35, drag: 1.05, lift: 1.20, fade0: 1.10, fade1: 1.50};",
            "function cl(v) { return Math.max(0, Math.min(1, v)); }",
            "function rp(a, b) { return cl((time - a) / (b - a)); }",
            "function io(t) { return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2; }",
            "function eo(t) { return 1 - Math.pow(1 - t, 3); }",
            "var Y0 = " + Y0 + ", Y1 = " + Y1 + ";",
            "var k = io(rp(T.press, T.drag));",
            "var fy = Y0 + (Y1 - Y0) * k;",
            "var dir = Y1 > Y0 ? 1 : -1;",
            "var fade = 1 - rp(T.fade0, T.fade1);",
            ""
        ].join(String.fromCharCode(10));
    }

    // One comp. `up` mirrors the frame top to bottom: H = 180.6129.
    function build(name, up) {
        var FH = 180.6129;
        function my(y) { return up ? FH - y : y; }
        var comp = proj.items.addComp(name, W, H, 1, DUR, FPS);
        comp.parentFolder = folder;
        comp.bgColor = [0.08, 0.08, 0.08];

        // The design's dark ground, for judging — a guide, not exported.
        var G = comp.layers.addSolid([0.078, 0.078, 0.078], "GROUND_GUIDE", W, H, 1, DUR);
        G.guideLayer = true;

        var FX = px(29.928 + 9);                   // the finger's x, the dot's centre
        var Y0 = py(my(12)), Y1 = py(my(101.613)); // dot centre, start and end
        var hd = head(Y0, Y1);

        // TRAIL — anchored at the end the finger starts from, growing behind
        // it to 12pt past the finger (the dot's centre is 12 from the design
        // rect's rounded end).
        var tw = layout.trail[0], th = layout.trail[1];
        var T = comp.layers.add(foot.trail);
        T.name = "TRAIL";
        // Anchored at the image's top, the rect's flat end; `up` turns it
        // 180° about that, so it grows upward from the frame's foot.
        tr(T).property("ADBE Anchor Point").setValue([tw / 2, 0]);
        tr(T).property("ADBE Position").setValue([FX, py(my(0))]);
        tr(T).property("ADBE Rotate Z").setValue(up ? 180 : 0);
        tr(T).property("ADBE Scale").expression = hd +
            "var len = Math.abs(fy - " + py(my(0)) + ") + 24;" +
            "[100, 100 * len / " + th + "]";
        tr(T).property("ADBE Opacity").expression = hd + "100 * rp(0.25, 0.35) * fade";

        // CHEVRONS — ride the trail 34.8pt behind the finger, and only show
        // once there is trail enough to hold them.
        var C = comp.layers.add(foot.chev);
        C.name = "CHEVRONS";
        tr(C).property("ADBE Anchor Point").setValue([layout.chev[0] / 2, layout.chev[1] / 2]);
        tr(C).property("ADBE Rotate Z").setValue(up ? 180 : 0);
        tr(C).property("ADBE Position").expression = hd + "[" + FX + ", fy - dir * 69.6]";
        tr(C).property("ADBE Opacity").expression = hd + "100 * cl((k - 0.35) / 0.3) * fade";

        // DOT — under the fingertip; lights on the press, out on the lift.
        var D = comp.layers.add(foot.dot);
        D.name = "DOT";
        tr(D).property("ADBE Anchor Point").setValue([layout.dot[0] / 2, layout.dot[1] / 2]);
        tr(D).property("ADBE Rotate Z").setValue(up ? 180 : 0);
        tr(D).property("ADBE Position").expression = hd + "[" + FX + ", fy]";
        tr(D).property("ADBE Scale").expression = hd + "var s = 60 + 40 * eo(rp(0.25, 0.35)); [s, s]";
        tr(D).property("ADBE Opacity").expression = hd + "100 * rp(0.25, 0.35) * (1 - rp(1.05, 1.20))";

        // HAND — its anchor is the fingertip, so the press and the release
        // scale about the point touching the glass. After the lift it drifts
        // on a little way, as a hand leaving the screen does.
        var Hd = comp.layers.add(foot.hand);
        Hd.name = "HAND";
        tr(Hd).property("ADBE Anchor Point").setValue(layout.handTip);
        tr(Hd).property("ADBE Rotate Z").setValue(-30);
        tr(Hd).property("ADBE Position").expression = hd +
            "var drift = 14 * eo(rp(1.05, 1.50));" +
            "[" + FX + " + drift * 0.5, fy + dir * drift]";
        tr(Hd).property("ADBE Scale").expression = hd +
            "var s = 1.12 - 0.12 * eo(rp(0, 0.25));" +
            "s -= 0.08 * eo(rp(0.25, 0.35));" +
            "s += 0.08 * eo(rp(1.05, 1.20));" +
            "s = s * " + layout.handScale + "; [s, s]";
        tr(Hd).property("ADBE Opacity").expression = hd + "100 * eo(rp(0, 0.25)) * fade";
        return comp;
    }

    step("GESTURE_DOWN", function () { build("GESTURE_DOWN", false); });
    step("GESTURE_UP", function () { build("GESTURE_UP", true).openInViewer(); });
    app.endUndoGroup();
    log(failed ? "done with errors" : "done");
})();
