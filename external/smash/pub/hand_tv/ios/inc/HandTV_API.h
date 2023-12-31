#ifndef _SMASH_HANDTVAPI_H_
#define _SMASH_HANDTVAPI_H_
#include "tt_common.h"
#include "internal_smash.h"
#if defined __cplusplus
extern "C" {
#endif

// prefix: HS -> HandTVSDK

// clang-format off
typedef void *HandTVHandle;

#define HANDTV_DEFAULT_MAX_HAND_NUM 20
#define HANDTV_DEFAULT_MAX_PERSON_NUM 10
#define HANDTV_KEY_POINT_NUM 22
#define HANDTV_PERSON_KEY_POINT_NUM 18
#define HANDTV_KEY_POINT_NUM_EXTENSION 2

#define HANDTV_UnknownSide 0
#define HANDTV_LeftHand 2
#define HANDTV_RightHand 4
#define HANDTV_DoubleHand 8


// 手部检测的返回结构体
// 结构体有默认值 调用方需要根据返回值是否是默认值 判断是否有相应的检测结果
typedef struct HandTVInfo {
    int id;                         ///< 手的id
    int person_id;                  ///< 人的id (合法的id是>=0，否则是-1)
    int hand_side;                  ///< 左手/右手/双手标识
    AIRect rect;                    ///< 手部矩形框 默认: 0
    int action;                     ///< 手部动作, 默认: 99
    float rot_angle;                ///< 手部旋转角度, 默认: 0
    float score;                    ///< 手部检测置信度 默认: 0
    float action_score;             ///< 手势分类置信度 默认: 0
    float rot_angle_bothhand;       ///< 双手夹角 默认: 0
    TTKeyPoint key_points[HANDTV_KEY_POINT_NUM];   /// 手部关键点 默认: 0
    TTKeyPoint key_points_extension[HANDTV_KEY_POINT_NUM_EXTENSION];  // 手部扩展点 默认: 0
    unsigned char *segment;         ///< 手掌分割mask 取值范围 0～255 默认: nullptr
    int segment_width;              ///< 手掌分割宽 默认: 0
    int segment_height;             ///< 手掌分割高 默认: 0
} HandTVInfo, *ptr_HandTVInfo;


// Gesture define
#define HANDTV_GESTURE_HEART_A 0
#define HANDTV_GESTURE_HEART_B 1
#define HANDTV_GESTURE_HEART_C 2
#define HANDTV_GESTURE_HEART_D 3
#define HANDTV_GESTURE_OK 4
#define HANDTV_GESTURE_HAND_OPEN 5
#define HANDTV_GESTURE_THUMB_UP 6
#define HANDTV_GESTURE_THUMB_DOWN 7
#define HANDTV_GESTURE_ROCK 8
#define HANDTV_GESTURE_NAMASTE 9
#define HANDTV_GESTURE_PLAM_UP 10
#define HANDTV_GESTURE_FIST 11
#define HANDTV_GESTURE_INDEX_FINGER_UP 12
#define HANDTV_GESTURE_DOUBLE_FINGER_UP 13
#define HANDTV_GESTURE_VICTORY 14
#define HANDTV_GESTURE_BIG_V 15
#define HANDTV_GESTURE_PHONECALL 16
#define HANDTV_GESTURE_BEG 17
#define HANDTV_GESTURE_THANKS 18
#define HANDTV_GESTURE_UNKNOWN 19


/// @brief 检测结果
typedef struct HandTVResult {
    HandTVInfo p_hands[HANDTV_DEFAULT_MAX_HAND_NUM];       // 检测到的手部信息
    int hand_count;                               // 检测到的手部数目，p_hands 数组中，只有前hand_count个结果是有效的，后面的是无效；
} HandTVResult, *ptr_HandTVResult;

typedef enum {
    HANDTV_REFRESH_FRAME_INTERVAL = 1,           // 设置检测刷新帧数，暂不支持
    HANDTV_MAX_HAND_NUM = 2,                     // 设置最多的手的个数，默认为2，目前最多设置为20；
    HANDTV_DETECT_MIN_SIDE = 3,                  // 设置检测的最短边长度, 默认192
    HANDTV_CLS_SMOOTH_FACTOR = 4,                // 设置分类平滑参数，默认0.7， 数值越大分类越稳定
    HANDTV_USE_ACTION_SMOOTH = 5,                // 设置是否使用类别平滑，默认1，使用类别平滑；不使用平滑，设置为0
    HANDTV_ALGO_LOW_POWER_MODE = 6,              // 降级模式，默认走高级的版本。如果
    HANDTV_ALGO_AUTO_MODE = 7,                   // 降级模式，默认走高级的版本。如果
    // 如果设置为 HAND_TV_ALGO_AUTO_MODE 模式，则可以以下参数来设置算法降级的阈值
    HANDTV_ALGO_TIME_ELAPSED_THRESHOLD = 8,      // 算法耗时阈值，默认为 20ms
    HANDTV_ALGO_MAX_TEST_FRAME = 9,              // 设置运行时测试算法的执行的次数, 默认是 150 次
    HANDTV_IS_USE_DOUBLE_GESTURE = 10,           // 设置是否使用双手手势， 默认为true
    HANDTV_ENLARGE_FACTOR_REG = 11,              // 设置回归模型的输入初始框的放大比列, 默认1.6
    HANDTV_NARUTO_GESTURE = 12,                  // 设置支持火影忍者手势，暂不支持
    HANDTV_HAND_THRESH = 13,                     // 设置手势跟踪阈值，暂不支持
    //
    HANDTV_ENABLE_ASYNC = 14,                    // 设置手检测和人体骨骼点是否异步，仅支持都同步或都异步，并且只能设置一次
    HANDTV_NOUSE = 15,                           // 无效功能，暂不支持
    HANDTV_DETECT_MAX_SIZE = 16,                 // 设置detect_max_size的大小，建议最大值为704，最小值352（是32的倍数）
    HANDTV_ENABLE_DTW_ACT = 17,                  // 设置动态手势，暂不支持
    HANDTV_DETECT_INTERVAL = 18,                 // 设置检测刷新帧数，默认为3 (>=1 && <= 30)
    HANDTV_SKELETON_INTERVAL = 19,               // 设置骨骼点刷新帧数，默认为1 (>=1 && <= 30)
    HANDTV_ENABLE_KP = 20,                       // 设置是否开启手关键点检测，默认为-1，不开启；开启则设为1
    HANDTV_ALLOWED_FILTER_SKELETON_FRAMES = 21,  // 设置allowed_filter_skeleton_frames
    HANDTV_ENABLE_FILTER_HAND_RECT = 22,         // 设置enable_filter_hand_rect
    HANDTV_ALLOWED_FILTER_HAND_RECT_FRAMES = 23, // 设置allowed_filter_hand_rect_frames
    //
    HANDTV_ENABLE_TSM_ACT = 24,                  // 设置TSM动态手势，暂不支持
    //
    HANDTV_ENABLE_PERSON_RECOGNITION = 25,       // 设置enable_person_recognition，暂不支持
} handtv_param_type;

typedef enum {
    HANDTV_MODEL_DETECT = 0x0001,             // 检测手，必须加载
    HANDTV_MODEL_BOX_REG = 0x0002,            // 检测手框，必须加载
    HANDTV_MODEL_GESTURE_CLS = 0x0004,        // 手势分类，必须加载
    HANDTV_MODEL_KEY_POINT = 0x0008,          // 手关键点，可选
    HANDTV_MODEL_SEGMENT = 0x0010,            // 可见性点，暂不支持
    HANDTV_MODEL_SK = 0x0020,                 // 人体模型, 必须加载
    HANDTV_MODEL_DTW_ACTION = 0x0040,         // 动态手势模型, 暂不支持
    HANDTV_MODEL_TSM_ACTION = 0x0080,         // 动态手势模型, 暂不支持
    HANDTV_MODEL_PERSON_RECOGNITION = 0x0100, // reid模型, 暂不支持
} handtv_model_type;// TODO: 其实这里以需要加载的能力为划分更好

// @param [out] handle Created hand handle
// @param [unsigned int] 目前无效
AILAB_EXPORT
int HandTV_CreateHandler(
    HandTVHandle *handle, unsigned int config, const int max_target_num);

// NOTE: 目前只支持 HANDTV_DETECT_MIN_SIDE

AILAB_EXPORT
int HandTV_SetParam(HandTVHandle handle, handtv_param_type type, float value);
// usage:
// HTVS_SetParam(HANDTV_DETECT_MIN_SIDE, 192);

// 初始化模型：HANDTV_MODEL_DETECT 和 HANDTV_MODEL_BOX_REG 和 HANDTV_MODEL_GESTURE_CLS 为必须初始化；
// HANDTV_MODEL_KEY_POINT 选择初始化；
AILAB_EXPORT
int HandTV_SetModel(HandTVHandle handle,
                  handtv_model_type type,
                  const char *model_path);

AILAB_EXPORT
int HandTV_SetModelFromBuf(HandTVHandle handle,
                         handtv_model_type type,
                         const char *model_buf,
                         unsigned int len);

/*
 *@brief: 手部检测，结果存放在p_hand_result 中
 *@param: handle 检测句柄
 *@param: image 图片指针
 *@param: pixel_format 图片像素格式
 *@param: image_width 图片宽度
 *@param: image_height 图片高度
 *@param: image_stride 图片每行的字节数目
 *@param: orientation 图片旋转方向
 *@param: detection_config 请求检测的模块，为 hand_model_type
 *的按位与操作，目前只有HandTV_MODEL_KEY_POINT
 *是可选的；
 *@param: p_hand_result 检测结果返回，需要分配好内存；
 *@param: smooth 是否进行keypoints平滑
 *@ */
AILAB_EXPORT
int HandTV_DoPredict(HandTVHandle handle,
                   const unsigned char *image,
                   PixelFormatType pixel_format,
                   int image_width,
                   int image_height,
                   int image_stride,
                   ScreenOrient orientation,
                   unsigned long long detection_config,
                   HandTVResult *p_hand_result,
                   int delayframecount);

/*
 @brief: 释放资源
 @param: handle 检测句柄
 */
AILAB_EXPORT
int HandTV_ReleaseHandle(HandTVHandle handle);

// 内存申请
AILAB_EXPORT
HandTVResult* MallocHandTVResult(HandTVHandle handle, int seg_width, int seg_height);

// 内存释放
AILAB_EXPORT
int ReleaseHandTVResult(HandTVResult *p_hand_result);

#if defined __cplusplus
};
#endif

// clang-format on

#endif  // SMASH_HANDTV_API

