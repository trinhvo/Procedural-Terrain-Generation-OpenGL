#version 330

in vec2 uv;

out vec4 color;

uniform sampler2D tex;
uniform float tex_width;
uniform float tex_height;
uniform int second_pass;

const float[3] G = float[3](0.327162,	0.345675,	0.327162);

void main() {

    int K = 1;

    vec3 tot_image = vec3(0.0);
    float tot_weight = 0;
    for(int k = -K; k <= K; k++){
        float weight = G[k + K];
        tot_image +=
                weight
                *                 // Ternary condition to convolve either vertically or horizontally
                texture(tex, uv + ((second_pass == 0) ? vec2(k/tex_width, 0) : vec2(0, k/tex_height))).rgb;
        tot_weight += weight;
    }

    color = vec4(tot_image / tot_weight, 1.0);

}

