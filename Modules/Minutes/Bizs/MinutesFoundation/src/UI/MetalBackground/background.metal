//
//  background.metal
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/4/6.
//

#include <metal_stdlib>
using namespace metal;

typedef struct
{
    vector_float4 position;
    vector_float2 textureCoordinate;
} LYVertex;

typedef enum VertexInputIndex
{
    VertexInputIndexVertices     = 0,
} VertexInputIndex;

typedef enum FragmentInputIndex
{
    FragmentInputIndexTexture     = 0,
    FragmentInputIndexUniforms     = 1,
} FragmentInputIndex;

typedef struct
{
    vector_float2 u_resolution;
    float u_time;
    float u_slot1;
    float u_slot2;
    float noiseFactor;
    float noiseDisplacement;
    vector_float2 uv_offset;
    float sampleScale;
    float flowSpeed;
    float u_saturation;
} UniformParameters;

float snoise(float2 v, float noiseFactor);
float3 mod289(float3 x);
float2 mod289(float2 x);
float3 permute(float3 x);
float blendColorDodge(float base,float blend);
float3 blendColorDodge(float3 base, float3 blend);
float3 blendColorDodge(float3 base, float3 blend, float opacity);
float3 brightnessContrast(float3 value, float brightness,float contrast);
float3 czm_saturation(float3 rgb, float adjustment);
float gradientNoise(float2 uv);

typedef struct
{
    float4 clipSpacePosition [[position]]; // position的修饰符表示这个是顶点

    float2 textureCoordinate; // 纹理坐标，会做插值处理

} RasterizerData;

vertex RasterizerData // 返回给片元着色器的结构体
vertexShader(uint vertexID [[ vertex_id ]], // vertex_id是顶点shader每次处理的index，用于定位当前的顶点
             constant LYVertex *vertexArray [[ buffer(VertexInputIndexVertices) ]]) { // buffer表明是缓存数据，0是索引
    RasterizerData out;
    out.clipSpacePosition = vertexArray[vertexID].position;
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    return out;
}

fragment float4
samplingShader(RasterizerData input [[stage_in]], // stage_in表示这个数据来自光栅化。（光栅化是顶点处理之后的步骤，业务层无法修改）
               texture2d<half> colorTexture [[ texture(FragmentInputIndexTexture) ]],
               constant UniformParameters &uniformParams [[buffer(FragmentInputIndexUniforms)]]) // texture表明是纹理数据，0是索引
{

    float2 position = float2(input.clipSpacePosition.x/2, input.clipSpacePosition.y/2);
    float2 st = position/uniformParams.u_resolution.xy;
    float s = snoise(float2(st.x*1.,st.y*1.3+uniformParams.u_time*uniformParams.flowSpeed), uniformParams.noiseFactor);

    // multiply the uv coord for 1 + the noise
    st*= float2( 1. + s * (uniformParams.noiseDisplacement*uniformParams.u_slot1) );
    // apply page offset
    st.x += ( uniformParams.u_slot2 * 0.5 + 0.5 );

    st += uniformParams.uv_offset;

    constexpr sampler textureSampler (mag_filter::linear,
    min_filter::linear); // sampler是采样器

    float3 color = float3(colorTexture.sample(textureSampler,float2(st.x*108./234.,st.y)/uniformParams.sampleScale).xyz);
    color.rgb = blendColorDodge(
        color.rgb,
        mix( float3( 0., 0., 0. ),
             float3( .14, 0., 0.),
             0.
        )
    );

    color = czm_saturation(color,uniformParams.u_slot1*uniformParams.u_saturation);
//    brightness Effect
    color = brightnessContrast(color,-1.+uniformParams.u_slot1,1.);
//
    color += color *(10.5/255.0) * gradientNoise(input.clipSpacePosition.xy) - (10.5/255.0);

    return float4(color ,1.0);
}

float3 mod289(float3 x){
    return x-floor(x*(1./289.))*289.;
}

float2 mod289(float2 x){
    return x-floor(x*(1./289.))*289.;
}

float3 permute(float3 x){
    return mod289(((x*34.)+1.)*x);
}

float snoise(float2 v, float noiseFactor)
{
    const float4 C=float4(.211324865405187,// (3.0-sqrt(3.0))/6.0
    .366025403784439,// 0.5*(sqrt(3.0)-1.0)
    -.577350269189626,// -1.0 + 2.0 * C.x
    .024390243902439);// 1.0 / 41.0
    // First corner
    float2 i=floor(v+dot(v,C.yy));
    float2 x0=v-i+dot(i,C.xx);

    // Other corners
    float2 i1;
    //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
    //i1.y = 1.0 - i1.x;
    i1=(x0.x>x0.y)?float2(1.,0.):float2(0.,1.);
    // x0 = x0 - 0.0 + 0.0 * C.xx ;
    // x1 = x0 - i1 + 1.0 * C.xx ;
    // x2 = x0 - 1.0 + 2.0 * C.xx ;
    float4 x12=x0.xyxy+C.xxzz;
    x12.xy-=i1;

    // Permutations
    i=mod289(i);// Avoid truncation effects in permutation
    float3 p=permute(permute(i.y+float3(0.,i1.y,1.))
    +i.x+float3(0.,i1.x,1.));

    float3 m=max(.5-float3(dot(x0,x0),dot(x12.xy,x12.xy),dot(x12.zw,x12.zw)),0.);
    m=m*m;
    m=m*m;

    // Gradients: 41 points uniformly over a line, mapped onto a diamond.
    // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

    float3 x=2.*fract(p*C.www)-1.;
    float3 h=abs(x)-.5;
    float3 ox=floor(x+.5);
    float3 a0=x-ox;

    // Normalise gradients implicitly by scaling m
    // Approximation of: m *= inversesqrt( a0*a0 + h*h );
    m*=1.79284291400159-0.85373472095314*(a0*a0+h*h);

    // Compute final noise value at P
    float3 g;
    g.x=a0.x*x0.x+h.x*x0.y;
    g.yz=a0.yz*x12.xz+h.yz*x12.yw;
    return noiseFactor*dot(m,g);
}

float blendColorDodge(float base,float blend){
    return(blend==1.)?blend:min(base/(1.-blend),1.);
}

float3 blendColorDodge(float3 base, float3 blend) {
    return float3(blendColorDodge(base.r,blend.r),blendColorDodge(base.g,blend.g),blendColorDodge(base.b,blend.b));
}

float3 blendColorDodge(float3 base, float3 blend, float opacity) {
    return (blendColorDodge(base, blend) * opacity + base * (1. - opacity));
}

float3 brightnessContrast(float3 value, float brightness,float contrast)
{
    value = ( value - 0.5 ) * contrast + 0.5 + brightness;

    return value;
}

float3 czm_saturation(float3 rgb, float adjustment)
{
    const float3 W = float3(.2125, .7154, .0721);
    float3 intensity = float3(dot(rgb, W));
    return mix(intensity, rgb, adjustment);
}

float gradientNoise(float2 uv)
{
    const float3 magic = float3(.06711056, .00583715, 52.9829189);
    return fract(magic.z * fract(dot(uv, magic.xy)));
}
