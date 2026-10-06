(function () {
    var ROOT = "/Users/anmkumar/Nano/GyroQR/Tools/ae/confirm_rays/";
    var comp = null;
    for (var i = 1; i <= app.project.numItems; i++) {
        var it = app.project.item(i);
        if (it instanceof CompItem && it.name === "CONFIRM_RAYS") comp = it;
    }
    if (!comp) return;
    var g = comp.layer("WASH_GUIDE"); var was = g.enabled; g.enabled = false;
    var ts = [0, 1, 2, 3];
    for (var k = 0; k < ts.length; k++) {
        try { comp.saveFrameToPng(ts[k], new File(ROOT + "check_" + k + ".png")); } catch (e) {}
    }
    g.enabled = was;
})();
