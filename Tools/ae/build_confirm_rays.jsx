// Builds CONFIRM_RAYS — the skin-confirm header's rays, looping — into the open
// After Effects project, in its own folder. Nothing else in the project is
// touched, and the project is not saved.
//
//   osascript -e 'tell application "Adobe After Effects 2026" to DoScriptFile
//                 "/…/Tools/ae/build_confirm_rays.jsx"'
//
// The planes come from `Tools/build_confirm_rays_layers.py`
// (Tools/ae/confirm_rays/): the four rays of Figma 1036:18725, each with its
// progressive blur baked in. The comp is 2x — 750 × 518, the header's
// 375 × 259 — at 60fps, and loops every 4s.
//
// What is in here and what is not: the Lottie is the rays alone, white, on a
// transparent ground. The wash they sit on — the grey the app leans toward
// the chosen card — and the white fades across the header's foot stay in the
// app, so the colour can follow the card. WASH_GUIDE shows that wash for
// judging the motion; it is a guide layer and is not exported.
//
// The motion: every ray is a funnel narrowing to one point below the title,
// so each turns about that point — the rays sway like light from a source
// just out of frame. They also stretch up from it and breathe in opacity, and
// RAY_SWEEP, a second copy of the tall ray, swings wider across them so the
// light is clearly moving. Every curve is a sine of the 4s loop or one of its
// harmonics, so frame 240 is frame 0 again.
//
// Lottie-safe by construction: image layers, transforms only. The motion is
// written as expressions for editing here; `export_confirm_rays.jsx` samples
// them to keyframes on every frame, since Lottie plays neither expressions
// nor AE's eases.
//
// Re-running replaces the previous build (the folder is removed first).

(function () {
    var ROOT = "/Users/anmkumar/Nano/GyroQR/Tools/ae/";
    var LOG = new File(ROOT + "confirm_rays/build_log.txt");
    var lines = [];
    LOG.lineFeed = "Unix";
    function log(s) {
        lines.push(s);
        if (LOG.open("w")) { LOG.write(lines.join(String.fromCharCode(10))); LOG.close(); }
    }
    // Never let an exception out: an uncaught error opens a modal alert, which
    // blocks the AppleEvent until someone clicks it.
    var failed = false;
    function step(name, fn) {
        if (failed) { log("skip " + name); return; }
        try { fn(); log("ok   " + name); }
        catch (e) { failed = true; log("FAIL " + name + ": " + e.toString() + " (line " + e.line + ")"); }
    }

    var FPS = 60, DUR = 4;
    var layout;
    step("read layout", function () {
        var f = new File(ROOT + "confirm_rays/layout.json");
        f.open("r"); var txt = f.read(); f.close();
        layout = eval("(" + txt + ")");
    });
    if (failed) return;
    var PIVOT = layout.pivot;

    app.beginUndoGroup("Build CONFIRM_RAYS");
    var proj = app.project, folder, comp, foot = {};

    step("clear previous build", function () {
        for (var i = proj.numItems; i >= 1; i--) {
            var it = proj.item(i);
            if (it instanceof FolderItem && it.name === "GyroQR - Confirm rays") it.remove();
        }
    });
    step("folder + footage", function () {
        folder = proj.items.addFolder("GyroQR - Confirm rays");
        for (var i = 0; i < layout.rays.length; i++) {
            var r = layout.rays[i];
            var f = proj.importFile(new ImportOptions(new File(ROOT + "confirm_rays/" + r.file)));
            f.parentFolder = folder;
            f.mainSource.alphaMode = AlphaMode.STRAIGHT;
            foot[r.name] = f;
        }
    });
    step("comp", function () {
        comp = proj.items.addComp("CONFIRM_RAYS", layout.comp[0], layout.comp[1], 1, DUR, FPS);
        comp.parentFolder = folder;
        comp.bgColor = [1, 1, 1];
    });

    function tr(layer) { return layer.property("ADBE Transform Group"); }

    // The app's wash, for judging the rays against: #C3CAD3 from 8.9% of the
    // wash rectangle down to white. A guide layer — not rendered, not exported.
    step("WASH_GUIDE", function () {
        var L = comp.layers.addSolid([1, 1, 1], "WASH_GUIDE", comp.width, comp.height, 1, DUR);
        var ramp = L.property("ADBE Effect Parade").addProperty("ADBE Ramp");
        // The wash rectangle runs from y −20.3 to 287 in header points.
        ramp.property(1).setValue([comp.width / 2, (-20.3 + 307.256 * 0.08884) * 2]);
        ramp.property(2).setValue([0xC3 / 255, 0xCA / 255, 0xD3 / 255, 1]);
        ramp.property(3).setValue([comp.width / 2, 287 * 2]);
        ramp.property(4).setValue([1, 1, 1, 1]);
        L.guideLayer = true;
    });

    // Each plane is placed so its anchor is the rays' shared pivot, in its
    // own pixels, and that anchor sits on the pivot in the comp.
    function ray(name, footName) {
        var spec;
        for (var i = 0; i < layout.rays.length; i++) if (layout.rays[i].name === footName) spec = layout.rays[i];
        var L = comp.layers.add(foot[footName]);
        L.name = name;
        tr(L).property("ADBE Anchor Point").setValue([PIVOT[0] - spec.x, PIVOT[1] - spec.y]);
        tr(L).property("ADBE Position").setValue(PIVOT);
        return L;
    }
    // `w` is the loop's angular frequency; harmonics of it keep the seam.
    var W = "var w = 2 * Math.PI / 4;\n";
    function motion(L, rot, scl, opa) {
        tr(L).property("ADBE Rotate Z").expression = W + rot;
        tr(L).property("ADBE Scale").expression = W + scl;
        tr(L).property("ADBE Opacity").expression = W + opa;
    }

    // Bottom of the stack first, as in the design.
    step("RAY_A", function () {       // the wide outer funnel
        motion(ray("RAY_A", "RAY_A"),
               "3.2 * Math.sin(w * time + 0.4)",
               "var k = Math.sin(w * time + 1.1); [100 + 3 * k, 100 + 7 * k]",
               "78 + 22 * Math.sin(w * time + 2.0)");
    });
    step("RAY_B", function () {       // the tall narrow one
        motion(ray("RAY_B", "RAY_B"),
               "-4.2 * Math.sin(w * time + 1.3)",
               "var k = Math.sin(2 * w * time + 0.6); [100 + 2 * k, 100 + 9 * k]",
               "80 + 20 * Math.sin(w * time + 3.4)");
    });
    step("RAY_C", function () {       // the thick band
        motion(ray("RAY_C", "RAY_C"),
               "2.6 * Math.sin(w * time + 2.4)",
               "var k = Math.sin(w * time + 0.2); [100 + 4 * k, 100 + 6 * k]",
               "72 + 28 * Math.sin(w * time + 0.9)");
    });
    step("RAY_D", function () {       // the centre shaft
        motion(ray("RAY_D", "RAY_D"),
               "1.8 * Math.sin(2 * w * time + 1.8)",
               "var k = Math.sin(w * time + 4.1); [100 + 6 * k, 100 + 14 * k]",
               "70 + 30 * Math.sin(2 * w * time + 0.3)");
    });
    // A second tall ray swinging wide across the others — the light moving,
    // which is what makes the loop read at a glance.
    step("RAY_SWEEP", function () {
        motion(ray("RAY_SWEEP", "RAY_B"),
               "13 * Math.sin(w * time)",
               "var k = Math.cos(w * time); [96 + 4 * k, 104 + 6 * k]",
               "36 + 20 * Math.cos(2 * w * time)");
    });

    step("open", function () { comp.openInViewer(); });
    app.endUndoGroup();
    log(failed ? "done with errors" : "done");
})();
