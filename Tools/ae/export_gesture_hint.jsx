// Exports GESTURE_DOWN and GESTURE_UP (build_gesture_hint.jsx) as Lottie JSON
// to Tools/ae/gesture_hint/, through the shared exporter, and renders check
// frames of each. Then `python3 Tools/pack_gesture_hint.py` makes
// GyroQR/hint_hand_pull_down.lottie and GyroQR/hint_hand_swipe_up.lottie.
(function () {
    var DIR = "/Users/anmkumar/Nano/GyroQR/Tools/ae/gesture_hint/";
    var comps = [["GESTURE_DOWN", "gesture_down.json", "report_down.json"],
                 ["GESTURE_UP", "gesture_up.json", "report_up.json"]];
    for (var i = 0; i < comps.length; i++) {
        $.global.LOTTIE_EXPORT = { comp: comps[i][0], root: DIR, json: comps[i][1] };
        $.evalFile(new File("/Users/anmkumar/Nano/GyroQR/Tools/ae/export_lottie.jsx"));
        var r = new File(DIR + "export_report.json");
        if (r.exists) r.copy(DIR + comps[i][2]);
    }
    // Check frames: arrive, mid-drag, end of drag, fading.
    var ts = [0.3, 0.7, 1.05, 1.3];
    for (var c = 1; c <= app.project.numItems; c++) {
        var it = app.project.item(c);
        if (!(it instanceof CompItem) || (it.name !== "GESTURE_DOWN" && it.name !== "GESTURE_UP")) continue;
        var g = it.layer("GROUND_GUIDE"); g.enabled = false;
        for (var k = 0; k < ts.length; k++) {
            try { it.saveFrameToPng(ts[k], new File(DIR + "check_" + it.name.toLowerCase() + "_" + k + ".png")); } catch (e) {}
        }
        g.enabled = true;
    }
})();
