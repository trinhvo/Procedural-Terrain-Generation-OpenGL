#version 410 core

// define the number of CPs in the output patch
layout (vertices = 4) out;

uniform mat4 MV;
uniform mat4 MVP;

uniform sampler2D heightMap;

uniform vec2 zoomOffset;
uniform float zoom;

// attributes of the input CPs
in vec3 vpoint_TC[];
in vec2 uv_TC[];

// attributes of the output CPs
out vec3 vpoint_TE[];
out vec2 uv_TE[];

const float CLOSEST_TESS_DISTANCE = 0.2f;
const float FURTHEST_TESS_DISTANCE = 2.5f;
const float MIN_TESSELATION = 1.0f;
const float MAX_TESSELATION = 1.0f;

float GetTessLevel(float Distance0, float Distance1)
{
    float avgDistance = (Distance0 + Distance1) / 2.0;

    //Clamp average between closest and furthest tesselation distance
    avgDistance = clamp(CLOSEST_TESS_DISTANCE, FURTHEST_TESS_DISTANCE, avgDistance);

    //More tesselation the closer we are from the point
    return mix(MAX_TESSELATION,
               MIN_TESSELATION,
               (avgDistance - CLOSEST_TESS_DISTANCE) / (FURTHEST_TESS_DISTANCE - CLOSEST_TESS_DISTANCE));
}

bool offscreen(vec3 v){
    vec4 vProj = MVP * vec4(v, 1.0f);
    vProj /= vProj.w;

    //Rough estimate
    return  any(bvec2(vProj.z < -1.1, vProj.z > 1.1)) ||
            any(lessThan(vProj.xy, vec2(-2))) ||
            any(greaterThan(vProj.xy, vec2(2)));
}

bool underHeight(vec2 v){
    return 1.3 * pow(texture(heightMap, (v+zoomOffset) * zoom).r, 3) > 0.1f;
}

void main()
{
    // Set the control points of the output patch
    uv_TE[gl_InvocationID] = uv_TC[gl_InvocationID];
    vpoint_TE[gl_InvocationID] = vpoint_TC[gl_InvocationID];

    // Calculate the distance from the camera to the three control points
    vec4 v0 = MV * vec4(vpoint_TC[0], 1.0);
    vec4 v1 = MV * vec4(vpoint_TC[1], 1.0);
    vec4 v2 = MV * vec4(vpoint_TC[2], 1.0);
    vec4 v3 = MV * vec4(vpoint_TC[3], 1.0);

    if(all(bvec4(offscreen(vpoint_TC[0]), offscreen(vpoint_TC[1]), offscreen(vpoint_TC[2]), offscreen(vpoint_TC[3])))
       || all(bvec4(underHeight(uv_TE[0]), underHeight(uv_TE[1]), underHeight(uv_TE[2]), underHeight(uv_TE[3])))){
        // No tesselation means patch is dropped -> save computation time !
        gl_TessLevelOuter[0] = gl_TessLevelOuter[1] = gl_TessLevelOuter[2] = gl_TessLevelOuter[3] = 0;
        gl_TessLevelInner[0] = gl_TessLevelInner[1] = 0;
    } else {
       gl_TessLevelOuter[0] = 1;
       gl_TessLevelOuter[1] = 1;
       gl_TessLevelOuter[2] = 1;
       gl_TessLevelOuter[3] = 1;
       gl_TessLevelInner[0] = 1;
       gl_TessLevelInner[1] = 1;
    }
}
