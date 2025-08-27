//
// Example blue light filter shader.
//

#version 300 es

precision mediump float;
in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;
uniform float time;
uniform vec2 resolution;

#define SIZE 3.0;

float N21(vec2 p) {
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 7.3345);
    return fract(p.x * p.y);
}

void main() {

    float t = mod(time + 1.0, 7200.0); // initial offset, move to the top
    // correct for aspect ratio to make squares square

    vec2 aspect = vec2(1.6, 1.0); // times 2 on x to make rectangles;
    vec2 scale = vec2(2.0, 1.0);
    vec2 size = vec2(5.0, 5.0);
    size = size * aspect * scale;

    vec2 uv = v_texcoord * size;
    uv.y = 1.0 - uv.y;

    uv.y += t * 0.25;
    vec2 st = fract(uv) - 0.5;
    vec2 id = floor(uv);

    float n = N21(id);
    t += n * 5.2385;
    float w = v_texcoord.y * 10.0;
    float x = (n - 0.5) * 0.8;
    x += (0.4 - abs(x)) * sin(3.0 * w) * pow(sin(w), 6.0) * 0.45;
    float y = -sin(t + sin(t + sin(t) * 0.5)) * 0.45;
    vec2 displacement = vec2(x, y);

    // displacement.y += abs(st.x);
    displacement.y -= (st.x - displacement.x) * (st.x - displacement.x);

    vec2 dropPos = (st - displacement) / scale;
    float drop = smoothstep(0.05, 0.03, length(dropPos));

    vec2 trailPos = (st - vec2(displacement.x, 0)) / scale;
    trailPos.y = (fract(trailPos.y * 8.0) - 0.5) / 8.0;
    float trail = smoothstep(0.03, 0.01, length(trailPos));
    float fogTrail = smoothstep(-0.05, 0.05, dropPos.y);
    fogTrail *= smoothstep(0.5, displacement.y, st.y);
    trail *= fogTrail;
    fogTrail *= smoothstep(0.05, 0.04, abs(dropPos.x));

    // pixColor.rgb += fogTrail * 0.5;
    // pixColor.rgb += drop;
    // pixColor.rgb += trail;
    vec2 offset = vec2(drop + trail);

    vec4 pixColor = texture(tex, v_texcoord + offset * 0.01);

    // if (st.x > 0.48 || st.y > 0.49) pixColor = vec4(0.0);

    fragColor = pixColor;
}
