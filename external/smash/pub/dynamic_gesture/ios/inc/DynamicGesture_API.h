#ifndef SMASH_DYANMICGESTURE_API
#define SMASH_DYANMICGESTURE_API
#include "tt_common.h"
#include "internal_smash.h"

// clang-format off
typedef void *DynamicGestureHandle;

extern char *DynamicGestureTypes[19];

#define DYNAMIC_GESTURE_SWIPING_LEFT 0
#define DYNAMIC_GESTURE_SWIPING_RIGHT 1
#define DYNAMIC_GESTURE_SWIPING_DOWN 2
#define DYNAMIC_GESTURE_SWIPING_UP 3
#define DYNAMIC_GESTURE_SLIDING_TWO_FINGERS_LEFT 4
#define DYNAMIC_GESTURE_SLIDING_TWO_FINGERS_RIGHT 5
#define DYNAMIC_GESTURE_SLIDING_TWO_FINGERS_DOWN 6
#define DYNAMIC_GESTURE_SLIDING_TWO_FINGERS_UP 7
#define DYNAMIC_GESTURE_ZOOMING_IN_WITH_FULL_HAND 8
#define DYNAMIC_GESTURE_ZOOMING_OUT_WITH_FULL_HAND 9
#define DYNAMIC_GESTURE_ZOOMING_IN_WITH_TWO_FINGERS 10
#define DYNAMIC_GESTURE_ZOOMING_OUT_WITH_TWO_FINGERS 11
#define DYNAMIC_GESTURE_THUMB_UP 12
#define DYNAMIC_GESTURE_THUMB_DOWN 13
#define DYNAMIC_GESTURE_SHAKING_HAND 14
#define DYNAMIC_GESTURE_STOP_SIGN 15
#define DYNAMIC_GESTURE_DRUMMING_FINGERS 16
#define DYNAMIC_GESTURE_NO_GESTURE 17
#define DYNAMIC_GESTURE_DOING_OTHER_THINGS 18

typedef struct GestureResult {
    int action;
    float action_score;
} GestureResult;

typedef enum {
    DYNGEST_REFRESH_FRAME_INTERVAL = 1, // 设置检测刷新帧数, 暂不支持
    DYNGEST_NUM_REQ_FRAMES = 2,         // 设置多帧处理动态手势输出结果
} dynamic_gesture_param_type;

typedef enum {
    DYNAMIC_GESTURE_MODEL_GESTURE_CLS = 0x0001, // 动态手势分类模型
} dynamic_gesture_model_type;

// @param [out] handle Created hand handle
// @param [unsigned int] 目前无效
AILAB_EXPORT
int DYNGEST_CreateHandler(DynamicGestureHandle *handle, unsigned int config);

// @param: handle 检测句柄
AILAB_EXPORT
int DYNGEST_SetParam(DynamicGestureHandle handle,
                     dynamic_gesture_param_type type,
                     float value);

// 初始化模型：DYNAMIC_GESTURE_MODEL_GESTURE_CLS 必须初始化
// @param: handle 检测句柄
AILAB_EXPORT
int DYNGEST_SetModel(DynamicGestureHandle handle,
                     dynamic_gesture_model_type type,
                     const char *model_path);

// 初始化模型：DYNAMIC_GESTURE_MODEL_GESTURE_CLS 必须初始化
AILAB_EXPORT
int DYNGEST_SetModelFromBuf(DynamicGestureHandle handle,
                            dynamic_gesture_model_type type,
                            const char *model_buf,
                            unsigned int len);

/* 
 *@brief: 动态手势检测，结果存放在 action和action_score中
 *@param: handle 检测句柄
 *@param: image 图片指针
 *@param: pixel_format 图片像素格式
 *@param: image_width 图片宽度
 *@param: image_height 图片高度
 *@param: image_stride 图片每行的字节数目
 *@param: action 动态手势类别
 *@param: action_score 动态手势类别分数
 *@ */
AILAB_EXPORT
int DYNGEST_DoPredict(DynamicGestureHandle handle,
                      const unsigned char *image,
                      PixelFormatType pixel_format,
                      int image_width,
                      int image_height,
                      int image_stride,
                      ScreenOrient orientation,
                      GestureResult* ptr_result);

/*
 @brief: 释放资源
 @param: handle 检测句柄
 */
AILAB_EXPORT
int DYNGEST_ReleaseHandle(DynamicGestureHandle handle);
// clang-format on

#endif  // SMASH_DYANMICGESTURE_API
