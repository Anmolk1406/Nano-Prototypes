#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

/// The mouth's y profile at a given x — the pocket's top edge with its notch.
///
/// A shader sees one pixel at a time and cannot walk a `Path`, so the profile
/// is rebuilt from the four joints between the path's cubics, passed in from
/// `PocketShape.notchShoulders`. The real shoulders are bezier; a smoothstep
/// between the joints is within a point of them and has no crease.
static float mouthY(float x, float edgeY, float x0, float x1, float x2, float x3,
                    float depth, float rim, float w) {
    // Outside the notch the top edge is not flat: the shape crowns from `rim`
    // at the far left and right up to the crest at the shoulders, so this has
    // to ramp rather than return a constant the way the old straight-edged
    // shape allowed.
    if (x <= x0) return edgeY + rim * (1.0 - saturate(x / max(x0, 0.001)));
    if (x >= x3) return edgeY + rim * saturate((x - x3) / max(w - x3, 0.001));
    if (x >= x1 && x <= x2) return edgeY + depth;      // the notch floor
    float t = (x < x1) ? (x - x0) / max(x1 - x0, 0.001)
                       : (x3 - x) / max(x3 - x2, 0.001);
    t = saturate(t);
    return edgeY + depth * (t * t * (3.0 - 2.0 * t));
}

/// Bows the card into the pocket's mouth.
///
/// A card crossing the edge is otherwise cut by a line, which is the one thing
/// that gives away that the sheet is a flat shape drawn over it rather than
/// something with a lip. This samples from lower down as it enters, so the band
/// of card just inside the mouth compresses — what a thick rounded edge does to
/// whatever passes under it.
///
/// **One-sided, and zero at the edge itself.** The first version was a
/// symmetric falloff centred on the contour, which distorted the card on both
/// sides — including the part still outside the pocket, where there is no lip
/// to do it. Simply dropping the outside half is not enough either: the weight
/// peaks *at* the contour, so cutting it there leaves a full-`amount` jump
/// across one pixel, which tears the card along the mouth. A half-sine is zero
/// at the edge, peaks `reach / 2` inside and returns to zero at `reach`, so the
/// whole effect lives inside the shape with no seam at either end of it.
///
/// `pos` is in the distorted view's own coordinate space, so every x and y here
/// is the sheet's geometry expressed in the card layer's frame.
///
/// Returns the position to sample, not a colour: this is a `distortionEffect`.
[[ stitchable ]] float2 mouthBend(float2 pos, float edgeY, float reach, float amount,
                                 float x0, float x1, float x2, float x3, float depth,
                                 float rim, float w) {
    float edge = mouthY(pos.x, edgeY, x0, x1, x2, x3, depth, rim, w);
    float d = pos.y - edge;
    if (d <= 0.0 || d >= reach) return pos;        // outside the shape, untouched
    float t = d / max(reach, 0.001);
    return float2(pos.x, pos.y + amount * sin(t * M_PI_F));
}
