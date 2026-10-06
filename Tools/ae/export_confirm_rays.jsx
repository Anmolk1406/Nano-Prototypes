// Exports CONFIRM_RAYS (build_confirm_rays.jsx) as Lottie JSON to
// Tools/ae/confirm_rays/confirm_rays.json, through the shared exporter. Every
// frame of the expressions is sampled to keyframes there. Then
// `python3 Tools/pack_confirm_rays.py` makes GyroQR/skin_confirm_rays.lottie.
$.global.LOTTIE_EXPORT = {
    comp: "CONFIRM_RAYS",
    root: "/Users/anmkumar/Nano/GyroQR/Tools/ae/confirm_rays/",
    json: "confirm_rays.json"
};
$.evalFile(new File("/Users/anmkumar/Nano/GyroQR/Tools/ae/export_lottie.jsx"));
