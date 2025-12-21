#ifdef GL_ES
precision highp float;
#endif

uniform sampler2D   u_doubleBuffer0;
uniform sampler2D   u_tex0;          // <-- seed image
uniform vec2        u_resolution;
uniform vec2        u_mouse;
uniform float       u_time;
uniform int         u_frame;

#include "../deps/lygia/generative/random.glsl"

void main() {
    vec3 color = vec3(0.0);
    vec2 st = gl_FragCoord.xy/u_resolution;

#ifdef DOUBLE_BUFFER_0

    if (u_frame <= 1) {
        color = texture2D(u_tex0, st).rgb;
    } else {
        color = texture2D(u_doubleBuffer0, st).rgb;
        vec3  pixel = vec3(vec2(2.0)/u_resolution.xy,0.);
        float r = texture2D(u_doubleBuffer0, st + (-pixel.zy)).r;
        float g = texture2D(u_doubleBuffer0, st + (-pixel.xz)).g;
        float b = texture2D(u_doubleBuffer0, st + (pixel.xz)).b;
        color = vec3(r, g, b);
    }

#else
    color = texture2D(u_doubleBuffer0, st).rgb;
#endif

    gl_FragColor = vec4(color, 1.0);
}

