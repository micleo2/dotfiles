#ifdef GL_ES
precision highp float;
#endif

uniform sampler2D   u_doubleBuffer0;
uniform sampler2D   u_tex0;          
uniform vec2        u_resolution;
uniform float       u_time;
uniform int         u_frame;

#include "random.glsl"

void main() {
    vec2 st = gl_FragCoord.xy / u_resolution;
    vec3 color;

#ifdef DOUBLE_BUFFER_0

    if (u_frame <= 1) {
        color = texture2D(u_tex0, st).rgb;
    } else {
        vec3 prev = texture2D(u_doubleBuffer0, st).rgb;

        // Scale coordinates down for low-frequency regions
        // vec2 region = st * 0.00005; // bigger regions smear together
        float region = st.x * 0.00005; // bigger regions smear together

        // Random chance per region
        float chance = random(region + u_time * 0.1);
        if (chance > 0.9) { 
            // Randomized downward offset and horizontal jitter
            float smearSpeed = (5.5 + random(region + u_time*1.7)) * 3.0 / u_resolution.y;
            float jitter = (random(region + u_time*2.3) - 0.5) * 12.0 / u_resolution.x; // wider jitter

            vec2 offset = vec2(0, smearSpeed);
            vec3 smear = texture2D(u_doubleBuffer0, clamp(st + offset, vec2(0.0), vec2(1.0))).rgb;

            float blendAmount = 0.1;
            color = mix(prev, smear, blendAmount);
        } else {
            color = prev;
        }
    }

#else
    color = texture2D(u_doubleBuffer0, st).rgb;
#endif

    gl_FragColor = vec4(color, 1.0);
}

