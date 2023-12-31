//
//  SSFR.shader.h
//  Pods
//
//  Created by lixiaoqi on 2020/4/22.
//
#if 0

#ifndef SSFR_es31_h
#define SSFR_es31_h
static const char* get_depth_vs_es31 = R"(#version 310 es
precision highp float;
in vec4 aVertex;
out vec4 viewPos;

uniform mat4 projMatrix;
uniform mat4 viewMatrix;
uniform float s_h;
uniform float p_t; 
uniform float p_n; 
uniform float r; 
uniform float p_f;

void main() {
    vec4 pos;
    pos.x = aVertex.x / 2.0;
    pos.y = aVertex.z / 2.0 - 1.0;
    pos.z = aVertex.y / 2.0;
    pos.w = 1.0;
    viewPos = viewMatrix * pos;
    float dist = length(viewPos.xyz);
    gl_Position = projMatrix * viewPos;
    gl_PointSize = r*p_n*s_h / (-viewPos.z * p_t);
}

)";

// color order is BGRA
static const char* get_depth_fs_es31 = R"(#version 310 es
precision highp float;
in vec4 viewPos;
out vec4 FragColor;

uniform mat4 projMatrix;
uniform mat4 viewMatrix;
uniform int s_h;
uniform float p_t;
uniform float p_n;
uniform float r;
uniform float p_f;


float linearize(float d, float p_f, float p_n) {
    float f = p_f, n = p_n;
    return 2.0 * f * n / (d * (f - n) - (f + n));
}

// [[early_fragment_tests]]
void main()
{

    float x = 2.0 * gl_PointCoord.x - 1.0;
    float y = 2.0 * gl_PointCoord.y - 1.0;
    float pho = x * x + y * y;
    float z = sqrt(1.0 - pho);
    if (pho > 1.0) {
        FragColor = vec4(0.0, 0.0, 0.0, 1.0);
        gl_FragDepth = 1.0f;
        return;
    }
    vec4 nviewPos = vec4(viewPos.xyz + vec3(x, y, z) * r, 1.0);
    vec4 nclipPos = projMatrix * nviewPos;
    float nz_ndc = nclipPos.z / nclipPos.w;
    gl_FragDepth = 0.5 * (1.0 * nz_ndc + 1.0 + 0.0); //gl_DepthRange
    FragColor.r = -nviewPos.z;
    FragColor.g = 1.0;
    return;
}

)";

// same as getDepth
static const char* get_thick_vs_es31 = R"(#version 310 es
precision highp float;
in vec4 aVertex;
out vec4 viewPos;

uniform mat4 projMatrix;
uniform mat4 viewMatrix;
uniform float s_h;
uniform float p_t; 
uniform float p_n; 
uniform float r; 
uniform float p_f;

void main()
{
    vec4 pos;
    pos.x = aVertex.x / 2.0;
    pos.y = aVertex.z / 2.0 - 1.0;
    pos.z = aVertex.y / 2.0;
    pos.w = 1.0;
    viewPos = viewMatrix * pos;
    float dist = length(viewPos.xyz);
    gl_Position = projMatrix * viewPos;
    gl_PointSize = r*p_n*s_h / (-viewPos.z * p_t);
    return;
}
)";

// color order is BGRA
static const char* get_thick_fs_es31 = R"(#version 310 es
precision highp float;
in vec4 viewPos;
out vec4 FragColor;

uniform mat4 projMatrix;
uniform mat4 viewMatrix;
uniform int s_h;
uniform float p_t;
uniform float p_n;
uniform float r;
uniform float p_f;

// [[early_fragment_tests]]
void main()
{
    float x = 2.0 * gl_PointCoord.x - 1.0;
    float y = 2.0 * gl_PointCoord.y - 1.0;
    float pho = x * x + y * y;
    float z = sqrt(1.0 - pho);
    if (pho > 1.0) {
        FragColor = vec4(0.0);
        return;
    }
    vec3 lightDir = vec3(0, 0, 1.0);
    FragColor.r = 2.0 * r*dot(vec3(x, y, z), lightDir);
    //out.FragColor.r = out.FragColor.r * 0.5;
    return;
}
)";

static const char* smooth_depth_vs_es31 = R"(#version 310 es
precision highp float;
in vec4 aVertex;
out vec2 vTex;
out vec2 blurCoordinates0;
out vec2 blurCoordinates1;
out vec2 blurCoordinates2;
out vec2 blurCoordinates3;
out vec2 blurCoordinates4;
out vec2 blurCoordinates5;
out vec2 blurCoordinates6;
out vec2 blurCoordinates7;
out vec2 blurCoordinates8;
out vec2 blurCoordinates9;
out vec2 blurCoordinates10;

uniform float texelWidthOffset;
uniform float texelHeightOffset;

void main()	
{	
    vTex = ((aVertex.xy * 0.5) + 0.5);	
    gl_Position = aVertex;	
    gl_Position.z = 0.0;	
    gl_Position.w = 1.0;	
    vec2 singleStepOffset;	
    singleStepOffset.x = texelWidthOffset;	
    singleStepOffset.y = texelHeightOffset;	
    blurCoordinates0 = vTex;	
    blurCoordinates1 = singleStepOffset * 1.0;	
    blurCoordinates2 = vTex + singleStepOffset * 1.0;
    blurCoordinates3 = vTex - singleStepOffset * 2.0;
    blurCoordinates4 = vTex + singleStepOffset * 2.0;
    blurCoordinates5 = vTex - singleStepOffset * 3.0;
    blurCoordinates6 = vTex + singleStepOffset * 3.0;
    blurCoordinates7 = vTex - singleStepOffset * 4.0;
    blurCoordinates8 = vTex + singleStepOffset * 4.0;
    blurCoordinates9 = vTex - singleStepOffset * 5.0;
    blurCoordinates10 = vTex + singleStepOffset * 5.0;
}	

)";

// color order is BGRA
static const char* smooth_depth_fs_es31 = R"(#version 310 es
precision highp float;

in vec2 vTex;
in vec2 blurCoordinates0;
in vec2 blurCoordinates1;
in vec2 blurCoordinates2;
in vec2 blurCoordinates3;
in vec2 blurCoordinates4;
in vec2 blurCoordinates5;
in vec2 blurCoordinates6;
in vec2 blurCoordinates7;
in vec2 blurCoordinates8;
in vec2 blurCoordinates9;
in vec2 blurCoordinates10;
out vec4 FragColor;

uniform float p_n;
uniform float p_f;
uniform float d_w;
uniform float d_h;
uniform int kernel_r;
uniform float blur_r;
uniform float blur_z;
uniform int blur_option;
uniform float texelWidthOffset;
uniform float texelHeightOffset;
uniform sampler2D zTex;

void main()
{
    // x: sum of weighted intensity. y: sum of weights
    vec2 sum = vec2(0.0, 0.0);	
    // r channel: sum of weighted intensity.  g channel : sum of weights
    vec2 value;	
    // the intensity of the non-offset pixel
    vec2 value0;	
    // is the pixel out of the fluid region?
    float flag = 1.0;	
    value = texture(zTex, blurCoordinates0).xy;	
    value0 = value;	
    // filter out the pixels whose initial intensity is 0
    if (value.y == 0.0 && blur_option % 2 == 0) {	
        FragColor.r = 0.0;	
        FragColor.g = 0.0;	
        return;	
    }	
    if (value.y < 0.01 || value.x / value.y < 0.5) {	
        flag = -1.0;	
    }	
    if (value.y > 0.01 || blur_option % 2 == 0) {	
        sum.x += value.x * 1.0;	
        sum.y += abs(value.y) * 1.0 * flag;	
    }	
    value = texture(zTex, blurCoordinates1).xy;	
    if (value.y > 0.01 || blur_option % 2 == 0) {	
        sum.x += value.x * 0.972604;	
        sum.y += abs(value.y) * 0.972604 * flag;	
    }	
    value = texture(zTex, blurCoordinates2).xy;	
    if (value.y > 0.01 || blur_option % 2 == 0) {	
        sum.x += value.x * 0.972604;	
        sum.y += abs(value.y) * 0.972604 * flag;	
    }	
    value = texture(zTex, blurCoordinates3).xy;	
    if (value.y > 0.01 || blur_option % 2 == 0) {	
        sum.x += value.x * 0.894839;	
        sum.y += abs(value.y) * 0.894839 * flag;	
    }
     value = texture(zTex, blurCoordinates4).xy;	
    if (value.y > 0.01 || blur_option % 2 == 0) {	
        sum.x += value.x * 0.894839;	
        sum.y += abs(value.y) * 0.894839 * flag;	
    }	
    value = texture(zTex, blurCoordinates5).xy;	
    if (value.y > 0.01 || blur_option % 2 == 0) {	
        sum.x += value.x * 0.778801;	
        sum.y += abs(value.y) * 0.778801 * flag;	
    }	
    value = texture(zTex, blurCoordinates6).xy;	
    if (value.y > 0.01 || blur_option % 2 == 0) {	
        sum.x += value.x * 0.778801;	
        sum.y += abs(value.y) * 0.778801 * flag;	
    }	
    value = texture(zTex, blurCoordinates7).xy;	
    if (value.y > 0.01 || blur_option % 2 == 0) {	
        sum.x += value.x * 0.64118;	
        sum.y += abs(value.y) * 0.64118 * flag;	
    }	
    value = texture(zTex, blurCoordinates8).xy;	
    if (value.y > 0.01 || blur_option % 2 == 0) {	
        sum.x += value.x * 0.64118;	
        sum.y += abs(value.y) * 0.64118 * flag;	
    }	
    value = texture(zTex, blurCoordinates9).xy;	
    if (value.y > 0.01 || blur_option % 2 == 0) {	
        sum.x += value.x * 0.249352;	
        sum.y += abs(value.y) * 0.249352 * flag;	
    }	
    value = texture(zTex, blurCoordinates10).xy;	
    if (value.y > 0.01 || blur_option % 2 == 0) {	
        sum.x += value.x * 0.249352;	
        sum.y += abs(value.y) * 0.249352 * flag;	
    }	

    // in the last step, we save the normalized result in the r channel
    if (blur_option == 4) {
        if (sum.y < 0.01) {	
            FragColor.r = 0.0;	
            FragColor.g = 0.0;	
        }	
        else {	
            FragColor.r = max(sum.x / sum.y, 0.0);	
            FragColor.g = 0.0;	
        }	
    }	
    else {	
        if (sum.y < 0.01 && blur_option % 2 == 0) {	
            FragColor.r = 0.0;	
            FragColor.g = 0.0;	
        }	
        else {	
            FragColor.r = sum.x;	
            FragColor.g = sum.y;	
        }	
    }
    return;
}

)";

static const char* restore_normal_vs_es31 = R"(#version 310 es
precision highp float;
in vec4 aVertex;
out vec2 vTex;
out vec2 blurCoordinates0;

void main()
{
    vTex = ((aVertex.xy * 0.5) + 0.5);
    gl_Position = aVertex;
    gl_Position.z = 0.0;
    gl_Position.w = 1.0;
    return;
}
)";

// color order is BGRA
static const char* restore_normal_fs_es31 = R"(#version 310 es
precision highp float;

in vec2 vTex;
out vec4 FragColor;

uniform float p_n;
uniform float p_f;
uniform float p_t;
uniform float p_r;
uniform float s_w;
uniform float s_h;
uniform int keep_edge;

uniform sampler2D zTex;
void main()
{
    float f_x, f_y, c_x, c_y, c_x2, c_y2;
    /* global */
    f_x = p_n / p_r;
    f_y = p_n / p_t;
    c_x = 2.0 / (s_w * f_x);
    c_y = 2.0 / (s_h * f_y);
    c_x2 = c_x * c_x;
    c_y2 = c_y * c_y;
    float x = vTex.x, y = vTex.y;
    float dx = 1.0 / s_w, dy = 1.0 / s_h;
    float z = texture(zTex, vec2(x, y)).r;
    float z2 = z * z;
    float dzdx = texture(zTex, vec2(x + dx, y)).r - z;
    float dzdy = texture(zTex, vec2(x, y + dy)).r - z;
    float dzdx2 = z - texture(zTex, vec2(x - dx, y)).r;
    float dzdy2 = z - texture(zTex, vec2(x, y - dy)).r;

    /* Skip silhouette */
    if (keep_edge == 1) {
        if (abs(dzdx2) < abs(dzdx)) dzdx = dzdx2;
        if (abs(dzdy2) < abs(dzdy)) dzdy = dzdy2;
    }
    vec3 n = vec3(-c_y * dzdx, -c_x * dzdy, c_x*c_y*z);
    /* revert n.z to positive for debugging */
    n.z = -n.z;
    float d = length(n);
    FragColor = vec4(n / d, d);
//FragColor = vec4(1.0);
    return;
}
)";

static const char* shading_vs_es31 = R"(#version 310 es
precision highp float;
in vec4 aVertex;
out vec2 vTex;
out vec2 blurCoordinates0;

void main()
{
    vTex = ((aVertex.xy * 0.5) + 0.5);
    gl_Position = aVertex;
    gl_Position.z = 0.0;
    gl_Position.w = 1.0;
    return;
}
)";

// color order is BGRA
static const char* shading_metal_fs_es31 = R"(#version 310 es
precision highp float;

in vec2 vTex;
out vec4 FragColor;

uniform sampler2D zTex;
uniform sampler2D normalDTex;
uniform sampler2D thickTex;
uniform sampler2D cameraTex;

uniform mat4 iview;
uniform float    p_n;
uniform float    p_f;
uniform float    p_t;
uniform float    p_r;
uniform int      shading_option;
uniform float    r0;



)";

static const char* display_vs_es31 = R"(#version 310 es
precision highp float;
in vec4 aVertex;
out vec2 vTex;

void main()
{
    vTex = aVertex.xy * 0.5 + 0.5;
    gl_Position = aVertex;
    gl_Position.z = 0.0;
    gl_Position.w = 1.0;
}
)";

// color order is BGRA
static const char* display_fs_es31 = R"(#version 310 es
precision highp float;

in vec2 vTex;
out vec4 FragColor;
uniform sampler2D inputTexture;

void main()
{
    vec4 colorSample = texture(inputTexture, vTex);
    float ap = colorSample.r;
    ap = ap/5.0;
//    ap = (ap - 0.95) * 20.0;
//    colorSample = vec4(ap, ap, ap, 1.0);
    FragColor = vec4(colorSample.rgb, 1.0);
//FragColor = vec4(1.0, 1.0, 0.0, 1.0); 
}
)";

#endif /* SSFR_shader_h */

#endif
