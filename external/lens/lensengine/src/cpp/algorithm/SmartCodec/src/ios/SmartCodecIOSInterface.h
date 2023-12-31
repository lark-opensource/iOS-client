//
//  SmartCodecIOSInferface.h
//  lensDemo
//

#import <UIKit/UIKit.h>
using namespace std;
typedef uint frame_id;

//typedef enum
//{
//    R540P,
//    R720P,
//    R1080P
//} VideoResolution;

typedef struct {
    int width;
    int height;
    int fps;
    int originalbitrate;
    const char* modelpath;
    const char* jsonSettings;
    bool yuvFmt;
} LensSmartCodecIOSModelParam; // 模型配置参数

typedef struct
{
    int frametype;
    int framesize;
    float ptstime;
}IOSHWCodecFeature; // 码流特征

typedef struct {
    float bitRate;
    float quality;
    bool useI; //指导编码器是否插入I帧
    float averageComplexity; //平均复杂度/平均调节幅度，需要上报
    float maxComplexity; //最大幅度，需要上报
    float minComplexity; //最小幅度，需要上报
}IOSHWCodecParm;    // 预测的编码参数（average bitrate）


@interface SmartCodecIOSInterface : NSObject
-(instancetype)Initwithparm: (LensSmartCodecIOSModelParam)parm withError:(int &)errorCode; //模型初始化接口
-(IOSHWCodecParm)InitCodecParm; //初始化编码参数接口
-(void)GetVideoFeature: (frame_id)idx buffers:(CVPixelBufferRef) framebuffer;//视频特征提取接口
-(void)GetCodecFeature: (frame_id)idx feature:(IOSHWCodecFeature) parm;//码流特征获取接口
-(void) ComputeCodecParam: (frame_id) idx;
-(IOSHWCodecParm) GetFinalParam;
-(void)Release;
@end
