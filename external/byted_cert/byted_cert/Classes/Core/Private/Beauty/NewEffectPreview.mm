//
//  NewEffectView.m
//  smash_demo
//

#import "NewEffectPreview.h"
#include "opengl_offscreen_render.h"
//#import <ReactiveCocoa/ReactiveCocoa.h>
//#import "ConstDefine.h"
#include <vector>

static const char *VERTEXT_SHADER = R"(
attribute vec4 a_Position;
attribute vec2 a_TextureCoordinates;
varying vec2 v_TextureCoordinates;

void main()
{
    v_TextureCoordinates = a_TextureCoordinates;
    gl_Position = a_Position;
}
)";

static const char *FRAGMENT_SHADER = R"(
precision highp float;
varying highp vec2 v_TextureCoordinates;

uniform sampler2D inputImageTexture;

void main()
{
    vec2 tex;
    tex.x = v_TextureCoordinates.x;
    tex.y = 1.0 - v_TextureCoordinates.y;
    vec4 src = texture2D(inputImageTexture, tex);
    gl_FragColor = src.bgra;
}
)";

static const char *BEAUTY_FRAGMENT_SHADER = R"(
precision mediump float;
//当前要采集像素的点
varying mediump vec2 v_TextureCoordinates;
//纹理
uniform sampler2D inputImageTexture;
//输出的宽与高
//uniform vec2 singleStepOffset;
uniform float intensity;
vec2 blurCoordinates[20];

void modifyColor(vec4 color){
    color.r=max(min(color.r, 1.0), 0.0);
    color.g=max(min(color.g, 1.0), 0.0);
    color.b=max(min(color.b, 1.0), 0.0);
    color.a=max(min(color.a, 1.0), 0.0);
}

void main(){
    //1、 模糊 ： 平滑处理 降噪    //singleStepOffset：步长
    int width = 480;
    int height = 640;
    vec2 singleStepOffset =vec2(1.0/float(width), 1.0/float(height));

    vec2 textureCoordinate;
    textureCoordinate.x = v_TextureCoordinates.x;
    textureCoordinate.y = 1.0 - v_TextureCoordinates.y;

    blurCoordinates[0] = textureCoordinate.xy + singleStepOffset *vec2(0.0, -10.0);
    blurCoordinates[1] = textureCoordinate.xy + singleStepOffset *vec2(0.0, 10.0);
    blurCoordinates[2] = textureCoordinate.xy + singleStepOffset *vec2(-10.0, 0.0);
    blurCoordinates[3] = textureCoordinate.xy + singleStepOffset *vec2(10.0, 0.0);
    blurCoordinates[4] = textureCoordinate.xy + singleStepOffset *vec2(5.0, -8.0);
    blurCoordinates[5] = textureCoordinate.xy + singleStepOffset *vec2(5.0, 8.0);
    blurCoordinates[6] = textureCoordinate.xy + singleStepOffset *vec2(-5.0, 8.0);
    blurCoordinates[7] = textureCoordinate.xy + singleStepOffset *vec2(-5.0, -8.0);
    blurCoordinates[8] = textureCoordinate.xy + singleStepOffset *vec2(8.0, -5.0);
    blurCoordinates[9] = textureCoordinate.xy + singleStepOffset *vec2(8.0, 5.0);
    blurCoordinates[10] = textureCoordinate.xy + singleStepOffset *vec2(-8.0, 5.0);
    blurCoordinates[11] = textureCoordinate.xy + singleStepOffset *vec2(-8.0, -5.0);
    blurCoordinates[12] = textureCoordinate.xy + singleStepOffset *vec2(0.0, -6.0);
    blurCoordinates[13] = textureCoordinate.xy + singleStepOffset *vec2(0.0, 6.0);
    blurCoordinates[14] = textureCoordinate.xy + singleStepOffset *vec2(6.0, 0.0);
    blurCoordinates[15] = textureCoordinate.xy + singleStepOffset *vec2(-6.0, 0.0);
    blurCoordinates[16] = textureCoordinate.xy + singleStepOffset *vec2(-4.0, -4.0);
    blurCoordinates[17] = textureCoordinate.xy + singleStepOffset *vec2(-4.0, 4.0);
    blurCoordinates[18] = textureCoordinate.xy + singleStepOffset *vec2(4.0, -4.0);
    blurCoordinates[19] = textureCoordinate.xy + singleStepOffset *vec2(4.0, 4.0);
    //计算平均值     //本身的点的像素值
    vec4 currentColor = texture2D(inputImageTexture, textureCoordinate);
    vec3 rgb = currentColor.rgb;
    // 计算偏移坐标的颜色值总和
    for (int i =0; i <20; i++) {
        //采集20个点 的像素值 相加 得到总和
        rgb += texture2D(inputImageTexture, blurCoordinates[i].xy).rgb; }
    // rgb：21个点的像素和     //平均值 模糊效果     // rgba
    vec4 blur =vec4(rgb *1.0 /21.0, currentColor.a);
    //gl_FragColor = blur;        //高反差
    //强光处理:color = 2 * color1 * color2;
    //  24.0 强光程度        // clamp:获得三个参数中大小处在中间的那个值
    vec4 highPassColor = currentColor - blur;
    highPassColor.r = clamp(2.0 * highPassColor.r * highPassColor.r *24.0, 0.0, 1.0);
    highPassColor.g = clamp(2.0 * highPassColor.g * highPassColor.g *24.0, 0.0, 1.0);
    highPassColor.b = clamp(2.0 * highPassColor.b * highPassColor.b *24.0, 0.0, 1.0);
    // 过滤疤痕
    vec4 highPassBlur =vec4(highPassColor.rgb, 1.0);
    //3、融合 -> 磨皮            //蓝色通道值
    float b = min(currentColor.b, blur.b);
    float value = clamp((b -0.2) *5.0, 0.0, 1.0);
    // RGB的最大值
    float maxChannelColor = max(max(highPassBlur.r, highPassBlur.g), highPassBlur.b);
    // 磨皮程度

//    float intensity = 0.4;
    float currentIntensity = (1.0 - maxChannelColor / (maxChannelColor +0.2)) * value * intensity;
    //gl_FragColor = highPassBlur;
    // 一个滤镜        //opengl 内置函数 线性融合        //混合 x*(1−a)+y⋅a        // 第三个值越大，在这里融合的图像 越模糊
    vec3 r = mix(currentColor.rgb, blur.rgb, currentIntensity);

    // 美白
//    float level = 0.4;
    vec4 deltaColor = vec4(r, 1.0) + vec4(intensity * 0.25, intensity * 0.25, intensity * 0.15, 0.0);
    modifyColor(deltaColor);

    gl_FragColor =deltaColor.bgra;

}

)";


@interface NewEffectPreview ()


@end


@implementation NewEffectPreview
{
    EAGLContext *_context;
    OpenglOffscreenRender *_render;
    std::vector<float> _vertPoints, _textPoints;
    bool _openglInit;

    //    MattingViewModel* _mattingViewModel;
    //    CGPoint _previousPt;
    //    BOOL _firstTouch;
    //    OpenglOffscreenRender* _mattingRender;
    //    bool _mattingOpenglInit;
    //    BOOL _notShowBackgroundImage;
    int _beautyIntensity;
    GLKTextureInfo *_brushTex;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupGL];
    }
    return self;
}

- (void)setupGL {
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (_context == nil) {
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }

    self.context = _context;

    if ([EAGLContext currentContext] != _context) {
        [EAGLContext setCurrentContext:_context];
    }

    float vertices[] = {-1.f, -1.f, 1.f, -1.f, -1.f, 1.f, 1.f, 1.f};
    float texVertices[] = {0.f, 0.f, 1.f, 0.0f, 0.f, 1.0f, 1.f, 1.0f};
    _vertPoints.clear();
    _vertPoints.resize(sizeof(vertices) / sizeof(float));
    memcpy(_vertPoints.data(), vertices, _vertPoints.size() * sizeof(float));
    _textPoints.clear();
    _textPoints.resize(sizeof(texVertices) / sizeof(float));
    memcpy(_textPoints.data(), texVertices, _textPoints.size() * sizeof(float));

    _render = new OpenglOffscreenRender();
    _render->setIsOffScreenRender(false);
    _openglInit = _render->init(VERTEXT_SHADER, BEAUTY_FRAGMENT_SHADER);
}

- (void)setBeautuyIntensity:(int)beautyIntensity {
    _beautyIntensity = beautyIntensity;
}

- (void)tearDownGL {
    [EAGLContext setCurrentContext:_context];
    //release gl resource
    delete _render;
    GLuint name = _brushTex.name;
    glDeleteTextures(1, &name);

    if ([EAGLContext currentContext] == _context) {
        [EAGLContext setCurrentContext:nil];
    }
    _context = nil;
}

- (void)dealloc {
    [self tearDownGL];
}

- (void)update:(CVPixelBufferRef)pixelBuffer {
    if (_openglInit) {
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        unsigned char *pixelBufferPtr = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        int pixelBufferHeight = CVPixelBufferGetHeight(pixelBuffer);
        int pixelBufferWidth = CVPixelBufferGetWidth(pixelBuffer);
        CGFloat cr = (CGFloat)pixelBufferWidth / (CGFloat)pixelBufferHeight;
        unsigned long stride = CVPixelBufferGetBytesPerRow(pixelBuffer);

        unsigned long outStride = pixelBufferWidth * 4;
        unsigned char *outPixelBufferPtr = new unsigned char[outStride * pixelBufferHeight];
        for (int i = 0; i < pixelBufferHeight; i++) {
            memcpy(outPixelBufferPtr + i * outStride, pixelBufferPtr, outStride);
            pixelBufferPtr += stride;
        }

        if (pixelBufferPtr != nullptr && pixelBufferHeight > 0 && pixelBufferWidth > 0) {
            _render->setTexture(0, "inputImageTexture", 0, pixelBufferWidth, pixelBufferHeight, outPixelBufferPtr);
        }

        delete[] outPixelBufferPtr;
        _render->setAttitude(0, "a_Position", 2, _vertPoints.data());
        _render->setAttitude(1, "a_TextureCoordinates", 2, _textPoints.data());
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    }
    [self setNeedsDisplay];
}

- (void)render {
    if (_openglInit) {
        CGSize viewPortSize = self.bounds.size;
        [self bindDrawable];

        float tmp = 0;
        tmp = _beautyIntensity / 100.0;
        _render->setUniform(0, "intensity", DT_FLOAT, &tmp);
        CGFloat scale = self.contentScaleFactor;
        _render->render(viewPortSize.width * scale, viewPortSize.height * scale, 4);
    }
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    [self render];
}

@end
