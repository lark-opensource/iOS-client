//
//  LivenessTaskController.h
//  Pods
//
//  Created by zhengyanxin on 2020/12/22.
//

#ifndef LivenessTaskController_h
#define LivenessTaskController_h
#import "FaceLiveViewController.h"
#import <smash/tt_common.h>

typedef NS_ENUM(NSUInteger, BDCTActionLivenessParamType) {
    BDCT_ACTION_LIVENESS_RESET = 0,                   //重置活体检测的状态，int
    BDCT_ACTION_LIVENESS_TIME_PER_ACTION = 1,         //每个动作的允许时间，float
    BDCT_ACTION_LIVENESS_ACTION_LIST = 2,             //需要完成的动作序列，int, 00001111  0 = "眨眼", 1 = "张嘴", 2 = "点头", 3 =                                                                                        "摇头"，当数值小于255时只能下发动作类型，有序下发见下面的用法解释。
    BDCT_ACTION_LIVENESS_RE_ID_TIME_LIMIT = 5,        //重新定位人脸的允许时间，推荐0.3-0.5, float
    BDCT_ACTION_LIVENESS_RANDOM_ORDER = 7,            //随机顺序模式，推荐1，int
    BDCT_ACTION_LIVENESS_DETECT_ACTION_NUMBER = 9,    //需要检测的动作数量, int
    BDCT_ACTION_LIVENESS_TIME_BTW_ACTION = 11,        //动作切换的时间间隔, 推荐1.0-2.0,  float
    BDCT_ACTION_LIVENESS_STILL_LIVENESS_THRESH = 13,  //如果配置静默活体的话，支持设置阈值, float
    BDCT_ACTION_LIVENESS_FACE_SIMILARITY_THRESH = 14, //如果配置了人脸识别的话，支持设置阈值，float
    BDCT_ACTION_LIVENESS_MASK_RADIUS_RATIO = 15,      //活体圆圈半径相对于整个屏幕宽度的占比，适配任意尺寸的图像输入，默认是0.375，float
    BDCT_ACTION_LIVENESS_OFFSET_TO_CENTER_RATIO = 16, //圆圈中心位置到顶部距离/整个屏幕高度，适配任意尺寸的图像输入，默认是0.37，float
    BDCT_ACTION_LIVENESS_TIME_FOR_WAIT_FACE = 17,     //允许的最大等待人脸时间
    BDCT_ACTION_LIVENESS_FACE_OCCUPY_RATIO = 18,      //用于控制人脸占比的参数，影响检测距离
    BDCT_ACTION_LIVENESS_DEBUG_MODE = 20,             //调试模式
    BDCT_ACTION_LIVENESS_CONTINUOUS_MODE = 21,        //连续且严格的动作检测，默认false，int
    BDCT_ACTION_LIVENESS_MAX_LOSE_NUMBER = 22,        //人脸最大丢失次数，安全场景下全程人脸不允许丢失。默认为正无穷。
    BDCT_ACTION_LIVENESS_WRONG_ACTION_MODE = 23,      //是否需要做错误动作检测，默认关闭，int，可以参考文档:                                                                                         bytedance.feishu.cn/docs/doccnfJuxSVpqRv3VqBzTsYUgHd
    BDCT_ACTION_LIVENESS_WRONG_ACTION_INVALID_TIME = 24,
    BDCT_ACTION_LIVENESS_ROTATE_FLAG = 25,
    BDCT_ACTION_LIVENESS_SAFE_MORE = 26,
    BDCT_ACTION_LIVENESS_MASK_MODE = 27,
    BDCT_ACTION_LIVENESS_CAPTURE_MODE = 28,
    BDCT_ACTION_LIVENESS_QUALITY_THRESH = 29,
    BDCT_ACTION_LIVENESS_QUALITY_CACHE = 30,
    BDCT_ACTION_LIVENESS_STABLE_THRESH = 31,
    BDCT_ACTION_LIVENESS_FACE_ANGLE = 38
    //当第N个（N >= 2）新动作提示开始后，在Invalid_time内，不会触发错误动作检测，但是对应指令的动作仍然会被检测。
    //时间设置过短，容易上个动作还没结束，这里就检测到错误动作了；时间设置过长，会降低黑产随机视频攻击的门槛。
    //float型，默认1.0，推荐0.1 - 2.0。

};
@protocol LivenessTCProtocol <NSObject>

@required

- (instancetype)initWithVC:(FaceLiveViewController *)vc;

- (int)setInitParams:(NSDictionary *)params;
- (int)setParamsGeneral:(int)type value:(float)value;

- (CGImageRef)doFaceLive:(CVPixelBufferRef)pixels orient:(ScreenOrient)orient;
- (void)setMaskRadiusRatio:(float)maskRadiusRadio offsetToCenterRatio:(float)offsetToCenterRatio;

- (void)reStart:(int)type;
- (void)viewDismiss;
- (void)trackCancel;

- (int)getAlgoErrorCode;
- (NSString *)getLivenessErrorTitle:(int)code;

@optional

- (NSString *)getLivenessErrorMsg:(int)code;

// 视频活体专属：录制视频
- (void)recordSrcVideo:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;

@end


@interface LivenessTC : NSObject <LivenessTCProtocol>

@end

#endif /* LivenessTaskController_h */
