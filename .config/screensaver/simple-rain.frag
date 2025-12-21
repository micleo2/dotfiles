#version 130
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
	vec2 u = st;
  vec2 n = texture2D(u_tex0, u * .1).rg;  // Displacement
  vec3 color;
    
  // color = textureLod(u_tex0, u, 2.5);
  color = texture2D(u_tex0, st).rgb;
  
  // Loop through the different inverse sizes of drops
  for (float r = 4. ; r > 0. ; r--) {
    vec2 x = u_resolution.xy * r * .015,  // Number of potential drops (in a grid)
         p = 6.28 * u * x + (n - .5) * 2.,
         s = sin(p);
    
    // Current drop properties. Coordinates are rounded to ensure a
    // consistent value among the fragment of a given drop.
    vec4 d = texture2D(u_tex0, round(u * x - 0.25) / x);
    
    // Drop shape and fading
    float t = (s.x+s.y) * max(0., 1. - fract(u_time * (d.b + .1) + d.g) * 2.);;
    
    // d.r -> only x% of drops are kept on, with x depending on the size of drops
    if (d.r < (5.-r)*.08 && t > .5) {
        // Drop normal
        vec3 v = normalize(-vec3(cos(p), mix(.2, 2., t-.5)));
        // fragColor = vec4(v * 0.5 + 0.5, 1.0);  // show normals
        
        // Poor man's refraction (no visual need to do more)
        color = texture2D(u_tex0, u - v.xy * .3).rgb;
    }
  }
  gl_FragColor = vec4(color, 1.0);
}

