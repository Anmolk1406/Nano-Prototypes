// Writes a comp as Lottie JSON (bodymovin 5.7 schema) — ACCT_RAYS to
// Tools/ae/account_rays/acct_rays.json unless a wrapper says otherwise. `Tools/pack_account_rays.py` then
// zips it with its images into GyroQR/Account/acct_rays.lottie.
//
// A narrow exporter on purpose: it knows image layers, shape layers holding
// groups of path / rectangle + stroke / fill / gradient fill + trim, and the
// five layer transforms — what build_account_rays.jsx makes plus the vector
// Base that replaced its image plane, and all of it Lottie-native.
//
// Gradient colours are the one thing ExtendScript cannot read — the property
// exists but has no readable value. So a gradient fill is exported with its
// geometry and a *sampling request*: the layer is rendered on its own to
// grad_<n>.png, and pack_account_rays.py reads the colours back off that
// render along the gradient's own start-to-end line and fits stops to them. Anything else in
// the comp is reported as unsupported rather than silently dropped. For
// hand-edited versions that go further, the LottieFiles panel exports the
// same comp.
//
// Every animated property is *sampled on every frame* with valueAtTime, which
// bakes keyframe eases and expressions alike — Lottie evaluates neither AE's
// temporal ease nor expressions — and then the samples a straight line
// between their neighbours already predicts are dropped.

(function () {
    // Which comp, and where it goes: ACCT_RAYS by default, or whatever a
    // wrapper puts in `$.global.LOTTIE_EXPORT` ({ comp, root, json }) before
    // `$.evalFile`-ing this — see export_confirm_rays.jsx.
    var cfg = $.global.LOTTIE_EXPORT || {};
    $.global.LOTTIE_EXPORT = undefined;
    var ROOT = cfg.root || "/Users/anmkumar/Nano/GyroQR/Tools/ae/account_rays/";
    var COMP = cfg.comp || "ACCT_RAYS";
    var JSON_NAME = cfg.json || "acct_rays.json";
    var report = [];
    var comp = null;
    for (var i = 1; i <= app.project.numItems; i++) {
        var it = app.project.item(i);
        if (it instanceof CompItem && it.name === COMP) comp = it;
    }
    function done(obj, name) {
        var f = new File(ROOT + name);
        f.encoding = "UTF-8"; f.lineFeed = "Unix";
        if (f.open("w")) { f.write(obj); f.close(); }
    }
    if (!comp) { done('{"ok":false,"why":"no ' + COMP + ' comp"}', "export_report.json"); return; }

    var fps = comp.frameRate;
    var nFrames = Math.round(comp.duration * fps);
    function r4(v) { return Math.round(v * 10000) / 10000; }
    function arr(v) { return v instanceof Array ? v : [v]; }

    function animated(p) {
        return p.numKeys > 0 || (p.expressionEnabled && p.expression !== "");
    }
    // Greedy line simplification over the per-frame samples.
    function simplify(samples, tol) {
        var keep = [0], last = 0;
        for (var j = 2; j < samples.length; j++) {
            var ok = true;
            for (var k = last + 1; k < j && ok; k++) {
                var u = (k - last) / (j - last);
                for (var d = 0; d < samples[k].length; d++) {
                    var lin = samples[last][d] + (samples[j][d] - samples[last][d]) * u;
                    if (Math.abs(lin - samples[k][d]) > tol) { ok = false; break; }
                }
            }
            if (!ok) { keep.push(j - 1); last = j - 1; }
        }
        keep.push(samples.length - 1);
        return keep;
    }
    // prop → Lottie animatable. `map` turns an AE value into the Lottie one.
    function anim(p, map, tol, spatial, f0, f1) {
        if (!animated(p)) return { a: 0, k: map(p.value) };
        var a = f0 === undefined ? 0 : f0, b = f1 === undefined ? nFrames : f1;
        var samples = [];
        for (var f = a; f <= b; f++) samples.push(arr(map(p.valueAtTime(f / fps, false))));
        var keep = simplify(samples, tol);
        var keys = [];
        for (var q = 0; q < keep.length; q++) {
            var idx = keep[q], s = samples[idx], kk = { t: a + idx, s: s };
            if (q < keep.length - 1) {
                if (spatial) {
                    kk.i = { x: 1, y: 1 }; kk.o = { x: 0, y: 0 };
                    kk.to = [0, 0, 0]; kk.ti = [0, 0, 0];
                } else {
                    var ix = [], iy = [], ox = [], oy = [];
                    for (var d = 0; d < s.length; d++) { ix.push(1); iy.push(1); ox.push(0); oy.push(0); }
                    kk.i = { x: ix, y: iy }; kk.o = { x: ox, y: oy };
                }
            }
            keys.push(kk);
        }
        return { a: 1, k: keys };
    }
    function v2(v) { return [r4(v[0]), r4(v[1]), 0]; }
    function v2n(v) { return [r4(v[0]), r4(v[1])]; }

    var gradients = [], currentLayer = null;
    // A point in a shape group's space → comp pixels, through the group's and
    // the layer's transforms. Static transforms, no rotation — enough for a
    // full-bleed gradient, and checked: anything else is reported.
    function groupToComp(L, g, pt) {
        var gt = g.property("ADBE Vector Transform Group");
        var gp = gt.property("ADBE Vector Position").value, ga = gt.property("ADBE Vector Anchor").value;
        var gs = gt.property("ADBE Vector Scale").value;
        var t = L.property("ADBE Transform Group");
        var lp = t.property("ADBE Position").value, la = t.property("ADBE Anchor Point").value;
        var ls = t.property("ADBE Scale").value;
        if (gt.property("ADBE Vector Rotation").value !== 0 || t.property("ADBE Rotate Z").value !== 0)
            report.push("rotated gradient on " + L.name + ": sampling line may be off");
        var x = (pt[0] - ga[0]) * gs[0] / 100 + gp[0], y = (pt[1] - ga[1]) * gs[1] / 100 + gp[1];
        return [r4((x - la[0]) * ls[0] / 100 + lp[0]), r4((y - la[1]) * ls[1] / 100 + lp[1])];
    }
    function sc(v) { return [r4(v[0]), r4(v[1]), 100]; }
    function n1(v) { return r4(arr(v)[0]); }

    function transform(layer) {
        var t = layer.property("ADBE Transform Group");
        var f0 = Math.max(0, Math.floor(layer.inPoint * fps));
        var f1 = Math.min(nFrames, Math.ceil(layer.outPoint * fps));
        return {
            o: anim(t.property("ADBE Opacity"), n1, 0.05, false, f0, f1),
            r: anim(t.property("ADBE Rotate Z"), n1, 0.01, false, f0, f1),
            p: anim(t.property("ADBE Position"), v2, 0.05, true, f0, f1),
            a: anim(t.property("ADBE Anchor Point"), v2, 0.05, true, f0, f1),
            s: anim(t.property("ADBE Scale"), sc, 0.01, false, f0, f1)
        };
    }

    var assets = [], assetIds = {};
    function assetFor(src) {
        if (assetIds[src.id]) return assetIds[src.id];
        var id = "img_" + assets.length;
        assets.push({ id: id, w: src.width, h: src.height, u: "/images/",
                      p: decodeURI(src.mainSource.file.name), e: 0 });
        assetIds[src.id] = id;
        return id;
    }

    function shapeGroup(g, f0, f1) {
        var c = g.property("ADBE Vectors Group"), it = [];
        for (var i = 1; i <= c.numProperties; i++) {
            var p = c.property(i), mn = p.matchName;
            if (mn === "ADBE Vector Shape - Group") {
                var sh = p.property("ADBE Vector Shape").value, v = [], ii = [], oo = [];
                for (var k = 0; k < sh.vertices.length; k++) {
                    v.push([r4(sh.vertices[k][0]), r4(sh.vertices[k][1])]);
                    ii.push([r4(sh.inTangents[k][0]), r4(sh.inTangents[k][1])]);
                    oo.push([r4(sh.outTangents[k][0]), r4(sh.outTangents[k][1])]);
                }
                if (animated(p.property("ADBE Vector Shape"))) report.push("animated path in " + g.name + " exported static");
                it.push({ ty: "sh", nm: p.name, ks: { a: 0, k: { i: ii, o: oo, v: v, c: sh.closed } } });
            } else if (mn === "ADBE Vector Graphic - Stroke" &&
                       !animated(p.property("ADBE Vector Stroke Width")) &&
                       p.property("ADBE Vector Stroke Width").value === 0) {
                // A zero-width stroke draws nothing; leaving it out keeps
                // its dash settings from reaching a player that half-supports them.
            } else if (mn === "ADBE Vector Graphic - Stroke") {
                var col = p.property("ADBE Vector Stroke Color").value;
                it.push({ ty: "st", nm: p.name,
                          c: { a: 0, k: [r4(col[0]), r4(col[1]), r4(col[2]), 1] },
                          o: anim(p.property("ADBE Vector Stroke Opacity"), n1, 0.1, false, f0, f1),
                          w: anim(p.property("ADBE Vector Stroke Width"), n1, 0.02, false, f0, f1),
                          lc: p.property("ADBE Vector Stroke Line Cap").value,
                          lj: p.property("ADBE Vector Stroke Line Join").value,
                          ml: 4, bm: 0 });
            } else if (mn === "ADBE Vector Shape - Rect") {
                it.push({ ty: "rc", nm: p.name, d: p.property("ADBE Vector Shape Direction").value,
                          s: anim(p.property("ADBE Vector Rect Size"), v2n, 0.05, false, f0, f1),
                          p: anim(p.property("ADBE Vector Rect Position"), v2n, 0.05, true, f0, f1),
                          r: anim(p.property("ADBE Vector Rect Roundness"), n1, 0.05, false, f0, f1) });
            } else if (mn === "ADBE Vector Graphic - Fill") {
                var fc = p.property("ADBE Vector Fill Color").value;
                it.push({ ty: "fl", nm: p.name, c: { a: 0, k: [r4(fc[0]), r4(fc[1]), r4(fc[2]), 1] },
                          o: anim(p.property("ADBE Vector Fill Opacity"), n1, 0.1, false, f0, f1), r: 1, bm: 0 });
            } else if (mn === "ADBE Vector Graphic - G-Fill") {
                var sp = p.property("ADBE Vector Grad Start Pt").value, ep = p.property("ADBE Vector Grad End Pt").value;
                var gt = p.property("ADBE Vector Grad Type").value;
                var sample = "grad_" + gradients.length + ".png";
                gradients.push({ layer: currentLayer, idx: currentLayer.index, file: sample,
                                 start: groupToComp(currentLayer, g, sp), end: groupToComp(currentLayer, g, ep) });
                it.push({ ty: "gf", nm: p.name, t: gt, r: 1, bm: 0,
                          o: anim(p.property("ADBE Vector Fill Opacity"), n1, 0.1, false, f0, f1),
                          s: { a: 0, k: [r4(sp[0]), r4(sp[1])] }, e: { a: 0, k: [r4(ep[0]), r4(ep[1])] },
                          g: { p: 2, k: { a: 0, k: [0, 0, 0, 0, 1, 1, 1, 1] } },
                          _sample: { file: sample } });
                if (gt !== 1) report.push("radial gradient in " + g.name + ": sampled along its radius only");
            } else if (mn === "ADBE Vector Filter - Trim") {
                it.push({ ty: "tm", nm: p.name,
                          s: anim(p.property("ADBE Vector Trim Start"), n1, 0.05, false, f0, f1),
                          e: anim(p.property("ADBE Vector Trim End"), n1, 0.05, false, f0, f1),
                          o: anim(p.property("ADBE Vector Trim Offset"), n1, 0.05, false, f0, f1),
                          m: 1 });
            } else {
                report.push("unsupported " + mn + " in " + g.name);
            }
        }
        var gt2 = g.property("ADBE Vector Transform Group");
        it.push({ ty: "tr",
                  p: anim(gt2.property("ADBE Vector Position"), v2n, 0.05, true, f0, f1),
                  a: anim(gt2.property("ADBE Vector Anchor"), v2n, 0.05, true, f0, f1),
                  s: anim(gt2.property("ADBE Vector Scale"), v2n, 0.01, false, f0, f1),
                  r: anim(gt2.property("ADBE Vector Rotation"), n1, 0.01, false, f0, f1),
                  o: anim(gt2.property("ADBE Vector Group Opacity"), n1, 0.05, false, f0, f1),
                  sk: { a: 0, k: 0 }, sa: { a: 0, k: 0 } });
        return { ty: "gr", nm: g.name, np: it.length - 1, it: it };
    }

    var layers = [];
    for (var li = 1; li <= comp.numLayers; li++) {
        var L = comp.layer(li);
        // Guides are for judging the comp in AE — never part of the animation.
        if (!L.enabled || L.guideLayer) continue;
        if (L.property("ADBE Effect Parade") && L.property("ADBE Effect Parade").numProperties > 0)
            report.push("effects on " + L.name + " not exported");
        if (L.blendingMode !== BlendingMode.NORMAL) report.push("blend mode on " + L.name + " not exported");
        var f0 = Math.max(0, Math.floor(L.inPoint * fps)), f1 = Math.min(nFrames, Math.ceil(L.outPoint * fps));
        var o = { ddd: 0, ind: li, nm: L.name, sr: 1, ks: transform(L), ao: 0,
                  ip: f0, op: f1, st: 0, bm: 0 };
        if (L instanceof ShapeLayer) {
            currentLayer = L;
            o.ty = 4; o.shapes = [];
            var root = L.property("ADBE Root Vectors Group");
            for (var g = 1; g <= root.numProperties; g++) {
                if (root.property(g).matchName === "ADBE Vector Group") o.shapes.push(shapeGroup(root.property(g), f0, f1));
                else report.push("unsupported top-level " + root.property(g).matchName + " on " + L.name);
            }
        } else if (L.source instanceof FootageItem && L.source.mainSource instanceof FileSource) {
            o.ty = 2; o.refId = assetFor(L.source);
        } else {
            report.push("skipped layer " + L.name);
            continue;
        }
        layers.push(o);
    }

    // Render each gradient layer alone, at a frame where it is on screen,
    // so its colours can be read back. Every layer's enabled state is put
    // back afterwards.
    for (var gi = 0; gi < gradients.length; gi++) {
        var G = gradients[gi], was = [];
        for (var q = 1; q <= comp.numLayers; q++) { was.push(comp.layer(q).enabled); comp.layer(q).enabled = (q === G.idx); }
        try { comp.saveFrameToPng(Math.max(G.layer.inPoint, 0), new File(ROOT + G.file)); }
        catch (e) { report.push("could not render " + G.file + ": " + e.toString()); }
        for (var q2 = 1; q2 <= comp.numLayers; q2++) comp.layer(q2).enabled = was[q2 - 1];
        G.layer = G.layer.name;
    }

    var lottie = { v: "5.7.0", fr: fps, ip: 0, op: nFrames, w: comp.width, h: comp.height,
                   nm: comp.name, ddd: 0, assets: assets, layers: layers, markers: [] };
    done(JSONish(lottie), JSON_NAME);
    done('{"ok":true,"layers":' + layers.length + ',"frames":' + nFrames +
         ',"notes":' + JSONish(report) + ',"gradients":' + JSONish(gradients) + '}', "export_report.json");

    // ExtendScript has no JSON object; a small serialiser for plain data.
    function JSONish(v) {
        if (v === null) return "null";
        if (v instanceof Array) {
            var a = [];
            for (var i = 0; i < v.length; i++) a.push(JSONish(v[i]));
            return "[" + a.join(",") + "]";
        }
        if (typeof v === "object") {
            var parts = [];
            for (var k in v) if (v.hasOwnProperty(k)) parts.push('"' + k + '":' + JSONish(v[k]));
            return "{" + parts.join(",") + "}";
        }
        if (typeof v === "string") return '"' + v.replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"';
        if (typeof v === "boolean") return v ? "true" : "false";
        return isFinite(v) ? String(v) : "0";
    }
})();
