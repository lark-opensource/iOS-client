#ifndef SMASH_HANDSDK_API
#define SMASH_HANDSDK_API
#include "tt_common.h"
#if defined __cplusplus
extern "C" {
#endif


// prefix: HS -> HandSDK

// clang-format off
typedef void *HandSDKHandle;

#define AI_MAX_HAND_NUM 2
#define HAND_KEY_POINT_NUM 22
#define HAND_KEY_POINT_3D_NUM 21
#define HAND_KEY_POINT_NUM_EXTENSION 2

extern const char *HandTypes_tob[48];
extern const char *HandTypes[47];

// 手部检测的返回结构体
//结构体有默认值 调用方需要根据返回值是否是默认值 判断是否有相应的检测结果
typedef struct HandInfo {
  int id;                         ///< 手的id
  AIRect rect;                    ///< 手部矩形框 默认: 0
  unsigned int action;            ///< 手部动作, 默认: 99
  float rot_angle;                ///< 手部旋转角度, 默认: 0
  float score;                    ///< 手部检测置信度 默认: 0
  float rot_angle_bothhand;       ///< 双手夹角 默认: 0
  struct TTKeyPoint key_points[HAND_KEY_POINT_NUM];   /// 手部关键点 默认: 0
  struct TTKeyPoint key_points_extension[HAND_KEY_POINT_NUM_EXTENSION];  // 手部扩展点 默认: 0
  unsigned int seq_action;        ///< 无序列动作为0，击拳为1，鼓掌为2，击掌为4  默认: 0
  unsigned char *segment;         ///< 手掌分割mask 取值范围 0～255 默认: nullptr
  int segment_width;              ///< 手掌分割宽 默认: 0
  int segment_height;             ///< 手掌分割高 默认: 0
} HandInfo, *ptr_HandInfo;

typedef struct HandInfoExtra {
  int id;
  struct TTKeyPoint3D kpt3d[HAND_KEY_POINT_3D_NUM]; //手部3d点
  float left_prob;  // 手部为左手的概率，默认0
  float scale;      // 当前手的scale 默认: 1.0
} HandInfoExtra, *ptr_HandInfoExtra;

typedef struct HandInfoForRing {
  int id;
  int render_mode;      // 0:不渲染钻戒，1:只渲染指环，2:渲染整个钻戒
  float trans[12];      // 钻戒的3D旋转与平移
} HandInfoForRing, *ptr_HandInfoForRing;

// Gesture define
#define HAND_GESTURE_HEART_A 0
#define HAND_GESTURE_HEART_B 1
#define HAND_GESTURE_HEART_C 2
#define HAND_GESTURE_HEART_D 3
#define HAND_GESTURE_OK 4
#define HAND_GESTURE_HAND_OPEN 5
#define HAND_GESTURE_THUMB_UP 6
#define HAND_GESTURE_THUMB_DOWN 7
#define HAND_GESTURE_ROCK 8
#define HAND_GESTURE_NAMASTE 9
#define HAND_GESTURE_PLAM_UP 10
#define HAND_GESTURE_FIST 11
#define HAND_GESTURE_INDEX_FINGER_UP 12
#define HAND_GESTURE_DOUBLE_FINGER_UP 13
#define HAND_GESTURE_VICTORY 14
#define HAND_GESTURE_BIG_V 15
#define HAND_GESTURE_PHONECALL 16
#define HAND_GESTURE_BEG 17
#define HAND_GESTURE_THANKS 18
#define HAND_GESTURE_UNKNOWN 19
#define HAND_GESTURE_CABBAGE 20
#define HAND_GESTURE_THREE 21
#define HAND_GESTURE_FOUR 22
#define HAND_GESTURE_PISTOL 23
#define HAND_GESTURE_ROCK2 24
#define HAND_GESTURE_SWEAR 25
#define HAND_GESTURE_HOLDFACE 26
#define HAND_GESTURE_SALUTE 27
#define HAND_GESTURE_SPREAD 28
#define HAND_GESTURE_PRAY 29
#define HAND_GESTURE_QIGONG 30
#define HAND_GESTURE_SLIDE 31
#define HAND_GESTURE_PALM_DOWN 32
#define HAND_GESTURE_PISTOL2 33
#define HAND_GESTURE_NARUTO1 34
#define HAND_GESTURE_NARUTO2 35
#define HAND_GESTURE_NARUTO3 36
#define HAND_GESTURE_NARUTO4 37
#define HAND_GESTURE_NARUTO5 38
#define HAND_GESTURE_NARUTO7 39
#define HAND_GESTURE_NARUTO8 40
#define HAND_GESTURE_NARUTO9 41
#define HAND_GESTURE_NARUTO10 42
#define HAND_GESTURE_NARUTO11 43
#define HAND_GESTURE_NARUTO12 44
#define HAND_GESTURE_SPIDERMAN 45
#define HAND_GESTURE_AVENGERS 46
#define HAND_GESTURE_RAISE 47

// ring position define
#define HAND_RING_POSITION_THUMB_FINGER 1
#define HAND_RING_POSITION_INDEX_FINGER 2
#define HAND_RING_POSITION_MIDDLE_FINGER 3
#define HAND_RING_POSITION_RING_FINGER 4
#define HAND_RING_POSITION_LITTLE_FINGER 5
#define HAND_RING_POSITION_PALM_CENTER 6

// 基于序列的动作
#define HAND_SEQ_ACTION_PUNCHING 1
#define HAND_SEQ_ACTION_CLAPPING 2
#define HAND_SEQ_ACTION_HIGHFIVE 4

/// @brief 检测结果
typedef struct HandResult {
  HandInfo p_hands[AI_MAX_HAND_NUM];  // 检测到的手部信息
  int hand_count;                     // 检测到的手部数目，p_hands 数组中，只有前hand_count个结果是有效的，后面的是无效；
} HandResult, *ptr_HandResult;

/// @brief 更丰富的手部结果
typedef struct HandResultExtra {
  HandInfoExtra p_hands[AI_MAX_HAND_NUM];  // 检测到的手部信息
  int hand_count;    // 检测到的手部数目，p_hands 数组中，只有前hand_count个结果是有效的，后面的是无效；
} HandResultExtra, *ptr_HandResultExtra;

/// @brief 戒指挂载信息
typedef struct HandResultForRing {
  HandInfoForRing p_rings[AI_MAX_HAND_NUM]; // 戒指挂载信息
  unsigned char* mask;  // 戒指的渲染mask，最长边为640
  int mask_height;      // mask的高度
  int mask_width;       // mask的宽度
  int hand_count;       // 检测到的手部数目，p_hands 数组中，只有前hand_count个结果是有效的，后面的是无效；
} HandResultForRing, *ptr_HandResultForRing;

typedef enum {
  HAND_REFRESH_FRAME_INTERVAL = 1,      // 设置检测刷新帧数, 暂不支持
  HAND_MAX_HAND_NUM = 2,                // 设置最多的手的个数，默认为1，目前最多设置为2；
  HAND_DETECT_MIN_SIDE = 3,             // 设置检测的最短边长度, 默认192
  HAND_CLS_SMOOTH_FACTOR = 4,           // 设置分类平滑参数，默认0.7， 数值越大分类越稳定
  HAND_USE_ACTION_SMOOTH = 5,           // 设置是否使用类别平滑，默认1，使用类别平滑；不使用平滑，设置为0
  HAND_ALGO_LOW_POWER_MODE = 6,         // 降级模式，默认走高级的版本。如果
  HAND_ALGO_AUTO_MODE = 7,              // 降级模式，默认走高级的版本。如果
  // 如果设置为 HAND_ALGO_AUTO_MODE 模式，则可以以下参数来设置算法降级的阈值
  HAND_ALGO_TIME_ELAPSED_THRESHOLD = 8, // 算法耗时阈值，默认为 20ms
  HAND_ALGO_MAX_TEST_FRAME = 9,         // 设置运行时测试算法的执行的次数, 默认是 150 次
  HAND_IS_USE_DOUBLE_GESTURE = 10,      // 设置是否使用双手手势， 默认为true
  HNAD_ENLARGE_FACTOR_REG = 11,         // 设置回归模型的输入初始框的放大比列
  HAND_NARUTO_GESTURE = 12,             // 设置支持火影忍者手势，默认为false，如果开启，则支持包括火影在内的45类手势识别
  HAND_USE_SMOOTH = 13,  // 控制是否停止平滑
  HAND_DETECT_FREQUENCE = 14, // 设置在未跟踪到手势时的检测频率默认是1,可设置的范围为[1， 10]
  HAND_KEY_POINT_3D_SMOOTH_FACTOR = 15, // 设置3D关键点的平滑系数，可设置范围为[0, 1]，默认为0.5，值越大越平滑
  HAND_KEY_POINT_SMOOTH_FACTOR = 16,    // 设置2D关键点的平滑系数，可设置范围为[0, 1]，默认为1.0，值越大越平滑
  HAND_RING_POSITION = 17,              // 设置钻戒贴纸挂载位置
  HAND_RING_MOTION_POSTPROC = 18,       // 设置是否开启戒指运动估计后处理
} hand_param_type;

typedef enum {
  HAND_MODEL_DETECT = 0x0001,       // 检测手，必须加载
  HAND_MODEL_BOX_REG = 0x0002,      // 检测手框，必须加载
  HAND_MODEL_GESTURE_CLS = 0x0004,  // 手势分类，可选
  HAND_MODEL_KEY_POINT = 0x0008,    // 手关键点，可选
  HAND_MODEL_SEGMENT = 0x0010,    // 可见性点，可选
  HAND_MODEL_KEY_POINT_3D = 0x0020, // 3D关键点，可选
  HAND_MODEL_LEFTRIGHT = 0x0040,    // 左右手分类，可选
  HAND_MODEL_RING = 0x0080,  // 手势融合模型，可选
} hand_model_type;

// @param [out] handle Created hand handle
// @param [unsigned int] 目前无效

AILAB_EXPORT
int HS_CreateHandler(HandSDKHandle *handle, unsigned int config);

// NOTE: 目前只支持 HAND_DETECT_MIN_SIDE
// int HS_SetParam(HandSDKHandle handle, hand_param_type type, float value, int
// );
AILAB_EXPORT
int HS_SetParam(HandSDKHandle handle, hand_param_type type, float value);
// usage:
// HS_SetParam(HAND_DETECT_MIN_SIDE, 192);

// 初始化模型：HAND_MODEL_DETECT 和 HAND_MODEL_BOX_REG 为必须初始化；
// HAND_MODEL_GESTURE_CLS 和 HAND_MODEL_KEY_POINT 选择初始化；
AILAB_EXPORT
int HS_SetModel(HandSDKHandle handle,
                hand_model_type type,
                const char *model_path);

AILAB_EXPORT
int HS_SetModelFromBuf(HandSDKHandle handle,
                       hand_model_type type,
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
int HS_DoPredict(HandSDKHandle handle,
                 const unsigned char *image,
                 PixelFormatType pixel_format,
                 int image_width,
                 int image_height,
                 int image_stride,
                 ScreenOrient orientation,
                 unsigned long long detection_config,
                 HandResult *p_hand_result,
                 int delayframecount);

/*
@brief: 获取额外的手部信息
@param: handle 检测句柄
*/
AILAB_EXPORT
int HS_GetHandResultExtra(HandSDKHandle handle,
                          HandResultExtra *p_hand_result_extra);

/*
@brief: 设置算法需要处理的区域. [重要*]该接口只能在调用CreateHandler之后，调用其他接口之前调用.
@param: handle 检测句柄
@param: left: [0, 1)
@param: top:  [0, 1)
@param: width: (0, 1]
@param: height: (0, 1]
*/
AILAB_EXPORT
int HS_SetROI(HandSDKHandle handle,
              float left, float top, float width, float height);

/*
@brief: 获取钻戒挂载的手部信息
@param: handle 检测句柄
*/
AILAB_EXPORT
int HS_GetHandResultForRing(HandSDKHandle handle,
                         HandResultForRing *p_hand_result_for_ring);

/*
@brief: 释放资源
@param: handle 检测句柄
*/
AILAB_EXPORT
int HS_ReleaseHandle(HandSDKHandle handle);

/*
@brief: 戒指挂载结果内存申请
@param: handle 检测句柄
@param: height 输入图片的高度
@param: width  输入图片的宽度
*/
AILAB_EXPORT HandResultForRing* HS_MallocResultForRingMemory(void* handle, int height, int width);

/*
@brief: 内存释放
@param: handle 检测句柄
@param: res 戒指挂载结果
*/
AILAB_EXPORT int HS_FreeResultForRingMemory(void* handle, HandResultForRing *res);

#if defined __cplusplus
};
#endif

// clang-format on

#endif  // SMASH_HANDSDK_API
