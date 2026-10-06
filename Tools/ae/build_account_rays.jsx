// Builds ACCT_RAYS — the account header's speed-line entrance — into the open
// After Effects project, in its own folder. Nothing else in the project is
// touched, and the project is not saved.
//
//   osascript -e 'tell application "Adobe After Effects 2026" to DoScriptFile
//                 "/…/Tools/ae/build_account_rays.jsx"'
//
// The planes come from `Tools/build_account_layers.py` (Tools/ae/account_rays/).
// The comp is 3× — 1125 × 1287, the header's 375 × 429 — at 60fps for 1.5s.
//
// Lottie-safe by construction: image layers and shape layers only, transform
// keyframes, strokes and trim paths. No effects, no merge paths, no blend
// modes, and the one expression (FrameForge's spring on the final scale) is
// baked to keyframes before export. `export_lottie.jsx` then writes the JSON.
//
//   BASE          the backdrop with no starburst in it — the header's purple
//   RAYS_FLOW_n   five soft-edged copies of the starburst, each flying out
//                 from the vanishing point and fading, staggered, so the rays
//                 read as a stream pouring out of the centre
//   RAYS          the starburst itself, easing in from 90% and settling on a
//                 spring to exactly where the design has it
//   SPEED_LINES   thin streaks shot outward along the rays with trim paths
//
// Re-running replaces the previous build (the folder is removed first).

(function () {
    var ROOT = "/Users/anmkumar/Nano/GyroQR/Tools/ae/";
    var LOG = new File(ROOT + "account_rays/build_log.txt");
    var lines = [];
    LOG.lineFeed = "Unix";
    function log(s) {
        lines.push(s);
        if (LOG.open("w")) { LOG.write(lines.join(String.fromCharCode(10))); LOG.close(); }
    }
    // Never let an exception out: in After Effects an uncaught error opens a
    // modal alert, which blocks the AppleEvent until someone clicks it and
    // takes every other scripting channel down with it. A failed step is
    // logged and every later step skipped.
    var failed = false;
    function step(name, fn) {
        if (failed) { log("skip " + name); return; }
        try { fn(); log("ok   " + name); }
        catch (e) { failed = true; log("FAIL " + name + ": " + e.toString() + " (line " + e.line + ")"); }
    }

    var S = 3, FPS = 60, DUR = 1.5;
    var layout;
    step("read layout", function () {
        var f = new File(ROOT + "account_rays/layout.json");
        f.open("r"); var txt = f.read(); f.close();
        layout = eval("(" + txt + ")");
    });
    if (failed) return;
    var VP = [layout.vp[0] * S, layout.vp[1] * S];

    app.beginUndoGroup("Build ACCT_RAYS");
    var proj = app.project, folder, comp, foot = {};

    step("clear previous build", function () {
        for (var i = proj.numItems; i >= 1; i--) {
            var it = proj.item(i);
            if (it instanceof FolderItem && it.name === "GyroQR - Account rays") it.remove();
        }
    });
    step("folder + footage", function () {
        folder = proj.items.addFolder("GyroQR - Account rays");
        var names = ["base", "rays", "soft"];
        for (var i = 0; i < names.length; i++) {
            var spec = layout[names[i]];
            var io = new ImportOptions(new File(ROOT + "account_rays/" + spec.file));
            var f = proj.importFile(io);
            f.parentFolder = folder;
            f.mainSource.alphaMode = AlphaMode.STRAIGHT;
            foot[names[i]] = f;
        }
    });
    step("comp", function () {
        comp = proj.items.addComp("ACCT_RAYS", layout.size[0] * S, layout.size[1] * S,
                                  1, DUR, FPS);
        comp.parentFolder = folder;
        comp.bgColor = [0.30, 0.09, 0.69];
    });

    function tr(layer) { return layer.property("ADBE Transform Group"); }
    function key(prop, t, v) { prop.setValueAtTime(t, v); return prop.nearestKeyIndex(t); }
    function ease(prop, k, inInf, outInf) {
        var dims = prop.value instanceof Array ? prop.value.length : 1;
        if (prop.propertyValueType === PropertyValueType.TwoD_SPATIAL ||
            prop.propertyValueType === PropertyValueType.ThreeD_SPATIAL) dims = 1;
        var a = [], b = [];
        for (var d = 0; d < dims; d++) {
            a.push(new KeyframeEase(0, inInf)); b.push(new KeyframeEase(0, outInf));
        }
        prop.setTemporalEaseAtKey(k, a, b);
    }
    // Accelerate away from key k: its outgoing handle is long and flat, the
    // next key arrives at full speed.
    function launch(prop, k1, k2) {
        prop.setInterpolationTypeAtKey(k1, KeyframeInterpolationType.BEZIER,
                                       KeyframeInterpolationType.BEZIER);
        ease(prop, k1, 33, 72);
        prop.setInterpolationTypeAtKey(k2, KeyframeInterpolationType.LINEAR,
                                       KeyframeInterpolationType.LINEAR);
    }
    function place(layer, spec, originIsCentre) {
        var k = S / spec.scale;       // footage px → comp px
        var ax = (layout.vp[0] - spec.x) * spec.scale;
        var ay = (layout.vp[1] - spec.y) * spec.scale;
        tr(layer).property("ADBE Anchor Point").setValue([ax, ay]);
        tr(layer).property("ADBE Position").setValue(VP);
        return 100 * k;
    }

    // Layers are added top-down, each new one landing on top, so the stack is
    // built from the bottom.
    step("BASE", function () {
        var L = comp.layers.add(foot.base);
        L.name = "BASE";
        place(L, layout.base);
    });

    var FLOWS = [
        // start (s), how long it flies (s), peak opacity
        [0.00, 0.62, 90], [0.12, 0.62, 85], [0.24, 0.62, 80],
        [0.36, 0.64, 72], [0.50, 0.66, 60]
    ];
    step("RAYS_FLOW", function () {
        for (var i = 0; i < FLOWS.length; i++) {
            var t0 = FLOWS[i][0], d = FLOWS[i][1], peak = FLOWS[i][2];
            var L = comp.layers.add(foot.soft);
            L.name = "RAYS_FLOW_" + (i + 1);
            var base = place(L, layout.soft);
            var sc = tr(L).property("ADBE Scale");
            var k1 = key(sc, t0, [base * 0.22, base * 0.22]);
            var k2 = key(sc, t0 + d, [base * 1.75, base * 1.75]);
            launch(sc, k1, k2);
            var op = tr(L).property("ADBE Opacity");
            key(op, t0, 0);
            var kp = key(op, t0 + d * 0.28, peak);
            key(op, t0 + d, 0);
            ease(op, kp, 40, 40);
            L.inPoint = t0; L.outPoint = t0 + d;
        }
    });

    step("RAYS", function () {
        var L = comp.layers.add(foot.rays);
        L.name = "RAYS";
        var base = place(L, layout.rays);
        var sc = tr(L).property("ADBE Scale");
        // 90% is the smallest this plane can be and still cover the header —
        // its top edge is 210pt above the vanishing point and the header's
        // is 187, so anything smaller would show the plane's edge.
        var k1 = key(sc, 0.52, [base * 0.90, base * 0.90]);
        var k2 = key(sc, 0.98, [base, base]);
        ease(sc, k1, 33, 20);
        ease(sc, k2, 70, 33);
        var op = tr(L).property("ADBE Opacity");
        var o1 = key(op, 0.52, 0);
        var o2 = key(op, 0.86, 100);
        ease(op, o1, 33, 10);
        ease(op, o2, 60, 33);
    });

    // Streaks: straight radial paths, each with its own trim that runs a
    // dash from the centre out past the corner. A seeded generator, so a
    // rebuild gives the same streaks.
    var seed = 20260925;
    function rnd() { seed = (seed * 1103515245 + 12345) % 2147483648; return seed / 2147483648; }
    step("SPEED_LINES", function () {
        var L = comp.layers.addShape();
        L.name = "SPEED_LINES";
        tr(L).property("ADBE Anchor Point").setValue([0, 0]);
        tr(L).property("ADBE Position").setValue([0, 0]);
        var root = L.property("ADBE Root Vectors Group");
        var N = 26;
        for (var i = 0; i < N; i++) {
            // Evenly spread with jitter, so no quadrant is empty.
            var ang = (i / N) * Math.PI * 2 + (rnd() - 0.5) * 0.18;
            var r0 = 70 * S, r1 = 360 * S;
            var p0 = [VP[0] + Math.cos(ang) * r0, VP[1] + Math.sin(ang) * r0];
            var p1 = [VP[0] + Math.cos(ang) * r1, VP[1] + Math.sin(ang) * r1];
            // Adding a property to a group invalidates every reference already
            // held into it, so all three are added first and then fetched fresh.
            root.addProperty("ADBE Vector Group");
            var g = root.property(root.numProperties);
            g.name = "streak_" + (i < 9 ? "0" : "") + (i + 1);
            g.property("ADBE Vectors Group").addProperty("ADBE Vector Shape - Group");
            g = root.property(root.numProperties);
            g.property("ADBE Vectors Group").addProperty("ADBE Vector Graphic - Stroke");
            g = root.property(root.numProperties);
            g.property("ADBE Vectors Group").addProperty("ADBE Vector Filter - Trim");
            g = root.property(root.numProperties);
            var c = g.property("ADBE Vectors Group");
            var path = c.property(1), st = c.property(2), tm = c.property(3);
            var sh = new Shape();
            sh.vertices = [p0, p1]; sh.inTangents = [[0, 0], [0, 0]];
            sh.outTangents = [[0, 0], [0, 0]]; sh.closed = false;
            path.property("ADBE Vector Shape").setValue(sh);

            var lav = rnd() < 0.35;
            st.property("ADBE Vector Stroke Color").setValue(lav ? [0.86, 0.80, 1, 1] : [1, 1, 1, 1]);
            st.property("ADBE Vector Stroke Width").setValue((1.1 + rnd() * 1.9) * S);
            st.property("ADBE Vector Stroke Line Cap").setValue(2);

            var t0 = 0.04 + rnd() * 0.78;
            var d = 0.30 + rnd() * 0.22;
            var len = 14 + rnd() * 16;           // % of the path the dash spans
            var e = tm.property("ADBE Vector Trim End");
            var s = tm.property("ADBE Vector Trim Start");
            var e1 = key(e, t0, 0), e2 = key(e, t0 + d, 100);
            var s1 = key(s, t0 + d * (len / 100), 0), s2 = key(s, t0 + d * (1 + len / 100), 100);
            launch(e, e1, e2);
            launch(s, s1, s2);

            var op = st.property("ADBE Vector Stroke Opacity");
            var peak = 55 + rnd() * 35;
            key(op, t0, 0);
            var kp = key(op, t0 + d * 0.3, peak);
            key(op, t0 + d * (1 + len / 100), 0);
            ease(op, kp, 40, 40);
        }
        L.outPoint = 1.2;
    });

    step("open", function () { comp.openInViewer(); comp.time = 0.5; });
    app.endUndoGroup();

    var out = new File(ROOT + "account_rays/build_done.json");
    if (out.open("w")) {
        out.write(failed ? '{"ok":false}' : '{"ok":true,"comp":' + comp.id + ',"layers":' + comp.numLayers + '}');
        out.close();
    }
})();
