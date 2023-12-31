#ifndef SMASH_FINGERTIPSDK_API
#define SMASH_FINGERTIPSDK_API
#include "tt_common.h"
// prefix: FT -> FingertipSDK

// clang-format off
typedef void *FingertipSDKHandle;  // 句柄

#define AI_FT_MAX_HAND_NUM 2
#define FT_HAND_KEY_POINT_NUM 22
#define FT_HAND_KEY_POINT_NUM_EXTENSION 2

extern const char *FT_HandTypes[30];

// 手部检测的返回结构体
typedef struct FingertipInfo {
  int id;                         ///< 手的id
  AIRect rect;                    ///< 手部矩形框
  unsigned int action;            ///< 手部动作, 如果没有检测，则置为 99
  float rot_angle;                ///< 手部旋转角度, 仅手张开是比较准确, 如果没有检测，则置为0
  float score;                    ///< 手部检测置信度
  float rot_angle_bothhand;       ///< 双手夹角
  struct TTKeyPoint key_points[FT_HAND_KEY_POINT_NUM];   ///< 手部关键点, 如果没有检测到，则置为0
  struct TTKeyPoint key_points_extension[FT_HAND_KEY_POINT_NUM_EXTENSION];  ///< 手部扩展点，如果没有检测到，则置为0
  unsigned int seq_action;        ///< 0 如果没有序列动作设置为0， 其他为有效值
  float *segment;         ///< 手掌分割mask
  int segment_width;              ///< 手掌分割框
  int segment_height;             ///< 手掌分割高
  bool photograph;
} FingertipInfo, *ptr_FingertipInfo;

/// @brief 检测结果
typedef struct FingertipResult {
  FingertipInfo p_hands[AI_FT_MAX_HAND_NUM];  // 检测到的手部信息
  int hand_count;                     // 检测到的手部数目，p_Fingertips 数组中，只有前hand_count个结果是有效的，后面的是无效；
} FingertipResult, *ptr_FingertipResult;

typedef enum {
  FT_HAND_REFRESH_FRAME_INTERVAL = 1,      // 设置检测刷新帧数, 暂不支持
  FT_HAND_MAX_HAND_NUM = 2,                // 设置最多的手的个数，默认为1，目前最多设置为2；
  FT_HAND_DETECT_MIN_SIDE = 3,             // 设置检测的最短边长度, 默认192
  FT_HAND_CLS_SMOOTH_FACTOR = 4,           // 设置分类平滑参数，默认0.7， 数值越大分类越稳定
  FT_HAND_USE_ACTION_SMOOTH = 5,           // 设置是否使用类别平滑，默认1，使用类别平滑；不使用平滑，设置为0
  FT_HAND_ALGO_LOW_POWER_MODE = 6,         // 降级模式，默认走高级的版本。如果
  FT_HAND_ALGO_AUTO_MODE = 7,              // 降级模式，默认走高级的版本。如果
  // 如果设置为 FT_HAND_ALGO_AUTO_MODE 模式，则可以以下参数来设置算法降级的阈值
  FT_HAND_ALGO_TIME_ELAPSED_THRESHOLD = 8, // 算法耗时阈值，默认为 20ms
  FT_HAND_ALGO_MAX_TEST_FRAME = 9,         // 设置运行时测试算法的执行的次数, 默认是 150 次
  FT_HAND_IS_USE_DOUBLE_GESTURE = 10,      // 设置是否使用双手手势， 默认为true
  FT_HAND_LOC_SCORE_THRES = 11, // set locating score threshold
  FT_HAND_CLS_SCORE_THRES = 12, // set classification score threshold
  FT_HAND_FINE_LOC_SCORE_THRES = 13, // set fine locating score threshold
  FT_HAND_RESET_SCORE_THRES = 14 // reset to default score thresholds
} fingertip_param_type;

typedef enum {
  FT_HAND_MODEL_DETECT = 0x0001,       // 检测手，必须加载
  FT_HAND_MODEL_BOX_REG = 0x0002,      // 检测手框，必须加载
  FT_HAND_MODEL_GESTURE_CLS = 0x0004,  // 手势分类，可选
  FT_HAND_MODEL_KEY_POINT = 0x0008,    // 手关键点，可选
  FT_HAND_MODEL_KEY_POINT_FINTUNE = 0x0006,    // 手关键点，可选
  FT_HAND_MODEL_GESTURE_CLS_EZ = 0x0012,    // 可见性点，可选
} fingertip_model_type;

// @param [out] handle Created hand handle
// @param [unsigned int] 目前无效

AILAB_EXPORT
int FT_CreateHandler(FingertipSDKHandle *handle, unsigned int config);

// NOTE: 目前只支持 FT_HAND_DETECT_MIN_SIDE
// int FT_SetParam(HandSDKHandle handle, hand_param_type type, float value, int
// );
int FT_SetParam(FingertipSDKHandle handle, fingertip_param_type type, float value);
// usage:
// FT_SetParam(HAND_DETECT_MIN_SIDE, 192);

// 初始化模型：HAND_MODEL_DETECT 和 HAND_MODEL_BOX_REG 为必须初始化；
// HAND_MODEL_GESTURE_CLS 和 HAND_MODEL_KEY_POINT 选择初始化；
int FT_SetModel(FingertipSDKHandle handle,
                fingertip_model_type type,
                const char *model_path);

int FT_SetModelFromBuf(FingertipSDKHandle handle,
                       fingertip_model_type type,
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
 *的按位与操作，目前只有HAND_MODEL_GESTURE_CLS 和 HAND_MODEL_KEY_POINT
 *是可选的；
 *@param: p_hand_result 检测结果返回，需要分配好内存；
 *@param: smooth 是否进行keypoints平滑
 *@ */
AILAB_EXPORT
int FT_DoPredict(FingertipSDKHandle handle,
                 const unsigned char *image,
                 PixelFormatType pixel_format,
                 int image_width,
                 int image_height,
                 int image_stride,
                 ScreenOrient orientation,
                 unsigned long long detection_config,
                 FingertipResult *p_Fingertip_result,
                 bool usetracking);

/*
@brief: 释放资源
@param: handle 检测句柄
*/
AILAB_EXPORT
int FT_ReleaseHandle(FingertipSDKHandle handle);
// clang-format on

AILAB_EXPORT
int FT_Reset(FingertipSDKHandle handle);
#endif  // SMASH_HANDSDK_API
