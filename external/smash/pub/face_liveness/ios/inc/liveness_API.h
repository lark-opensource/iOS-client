//
// Created by 王旭 on 2018/8/24.
//

#ifndef MODULES_LIVENESS_API_H
#define MODULES_LIVENESS_API_H

#include "tt_common.h"

#if defined __cplusplus
extern "C" {
#endif

typedef void *LivenessHandle;

//需要传入活体检测的结构体参数
//typedef enum {
//    kClockwiseRotate_0 = 0,
//    kClockwiseRotate_90 = 1,
//    kClockwiseRotate_180 = 2,
//    kClockwiseRotate_270 = 3,
//} ScreenOrient;
//
//typedef enum {
//    kPixelFormat_RGBA8888 = 0,
//    kPixelFormat_BGRA8888 = 1,
//    kPixelFormat_BGR888 = 2,
//    kPixelFormat_RGB888 = 3,
//} PixelFormatType;
typedef struct AILAB_EXPORT LivenessInput {
        unsigned char *image;    //从摄像头中读取的图像，当前推荐使用640*480输入的图像
        PixelFormatType pixel_format;    //图像格式，枚举类型
        int image_width;   //图像宽度
        int image_height;   //图像高度
        int image_stride;   //图像的step
        int radius;   //检测活体mask的半径，推荐为图像宽度*(0.4 - 0.45)
        ScreenOrient orientation;   //图像方向
} LivenessInput;


//用于获取活体检测过程中的最佳照片
typedef struct AILAB_EXPORT LivenessBestFrame{
        unsigned char *image;   //用于存储最佳图像，可以是包含背景的图像或者是人脸图像
        int image_width;     //获取最佳照片的宽度
        int image_height;    //获取最佳照片的宽度
}LivenessBestFrame;



//用于保存活体检测返回值的结构体参数
//category: {0 = "眨眼", 1 = "张嘴", 2 = "点头", 3 = "摇头"}
//timeleft: 用于提示剩余时间
//status: {0 = "检测失败", 1 = "检测成功", 2 = "请勿遮挡并直面镜头",
//        3 = "请靠近点", 4 = "请不要过快", 5 = "请保持端正", 6 = "",
//        7 = "请确认只有一张人脸", 8 = "请保持睁眼", 9 = "请离远点", 10 ="请保持人脸在框内"};
//is_valided_face_catched: {0:尚未检测到第一张有效人脸或者已经检测完成，当前状态只显示status额外提示信息；
//                          1:已检测到第一张有效人脸并且尚未完成检测，当前状态应显示status/timeleft/category提示信息}
//detect_result_code:{ 0 = "检测尚未完成", 1 = "检测成功", 2 = "超时未检测到第一张有效人脸",
//                     3 = "单个动作超时", 4 = "人脸丢失超过最大允许次数", 5 = "人脸REID超时",
//                     6 = "做错动作，可能是视频攻击", 7 = "静默活体检测失败", 8 = "过程中人脸不一致"
// }
typedef struct AILAB_EXPORT LivenessOutput {
        int category;    // 做的动作类型
        int timeleft;    // 当前动作的剩余时间
        int status;      // 状态信息
        int is_valided_face_catched;  // 是否获取到第一张有效人脸
        int detect_result_code;   //用于判断活体检测的结果，提取具体的错误信息等
        void* extra_info; // 额外的数据，目前用于debug
} LivenessOutput;


//用于客户端定义需要下发的检测动作
typedef enum {
    BLINK = 0,  //眨眼
    OPENMOUTH = 1,  //张嘴
    NOD = 2,   //点头
    SHAKE = 3,  //摇头
} ActionCmd;


//用于设置活体检测各种模式的配置参数
enum LivenessParamType {
    RESET = 0,    //重置活体检测的状态，int
    TIME_PER_ACTION = 1,    //每个动作的允许时间，int
    ACTION_LIST = 2,     //需要完成的动作序列，int array
    MAX_LOSE_NUMBER = 3,    //允许人脸丢失的最大次数，int
    EXCLUSIVE_MODE = 4,    //是否开启动作互斥模式，相当于另一种强安全模式，可抵御随机视频攻击，int
    RE_ID_TIME_LIMIT = 5,   //重新定位人脸的允许时间，推荐0.3-0.5, float
    STRONG_SAFE_MODE = 6,    //强安全模式，开启后用户体验会下降，但安全性能会提升，int
    RANDOM_ORDER = 7,    //随机顺序模式，推荐1，int
    USE_STILL_VERIFY = 8,  //是否开启静默活体统计检测，可抵御头套、面具等高级攻击，int
    DETECT_ACTION_NUMBER = 9,  //需要检测的动作数量, int
    MASK_RADIUS = 10,   //图像中心的mask半径，int
    TIME_BTW_ACTION = 11,  //动作切换的时间间隔, 推荐1.0-2.0,  float
    OFFSET_TO_CENTER = 12,  //中轴线偏移，推荐0-150, 正数表示向上偏移, int
};


//创建handler
AILAB_EXPORT
int Liveness_CreateHandle(LivenessHandle *handle);

//设置活体检测状态机的参数，对应可配置参数类型见LivenessParamType
AILAB_EXPORT
int Liveness_SetParam(LivenessHandle handle, LivenessParamType type, void* value, int actionListLength = -1);

//设置活体检测系统需要加载的模型文件，model_path为模型路径
AILAB_EXPORT
int Liveness_SetModel(LivenessHandle handle, const char *model_path);

// 保留接口
AILAB_EXPORT
int Liveness_SetModelFromBuf(LivenessHandle handle,
                             const char *model_buf,
                             int model_buf_len);

//输入一张图，活体检测的状态机进行预测
AILAB_EXPORT
int LivenessPredict(LivenessHandle handle, LivenessInput *args, LivenessOutput *ret);

//获取检测过程的最佳照片，用于后续人证比对
AILAB_EXPORT
int Liveness_BestFrame(LivenessHandle handle,
                        LivenessBestFrame *bestFrameEnv,      //包含背景的最佳图像，现优化输出文件的尺寸，Env图像的尺寸为360*480*4
                        LivenessBestFrame *bestFrameFace);    //仅包含人脸的最佳图像，现优化输出文件的尺寸，Face图像的尺寸为250*250*4

//释放资源
AILAB_EXPORT
void Liveness_Release(LivenessHandle handle);


#if defined __cplusplus
}
#endif

#endif //MODULES_LIVENESS_API_H
