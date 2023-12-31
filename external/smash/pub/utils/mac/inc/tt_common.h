#ifndef TT_COMMON_H_
#define TT_COMMON_H_

#include <stdbool.h>

#ifdef DEBUG
#define AILAB_EXPORT
#else
#ifdef _MSC_VER
#define AILAB_EXPORT __declspec(dllexport)
#else
#define AILAB_EXPORT __attribute__((visibility("default")))
#endif
#endif

typedef enum {
  kClockwiseRotate_0 = 0,
  kClockwiseRotate_90 = 1,
  kClockwiseRotate_180 = 2,
  kClockwiseRotate_270 = 3,
  kClockwiseRotate_Unknown = 99
} ScreenOrient;

typedef enum {
  kPixelFormat_RGBA8888 = 0,
  kPixelFormat_BGRA8888 = 1,
  kPixelFormat_BGR888 = 2,
  kPixelFormat_RGB888 = 3,
  kPixelFormat_NV12 = 4,
  kPixelFormat_GRAY = 5,
  kPixelFormat_Unknown = 255,
} PixelFormatType;

typedef struct AIRect {
  int left;    ///< 矩形最左边的坐标
  int top;     ///< 矩形最上边的坐标
  int right;   ///< 矩形最右边的坐标
  int bottom;  ///< 矩形最下边的坐标
} AIRect;

typedef struct AIPoint {
  float x;  ///< 点的水平方向坐标
  float y;  ///< 点的竖直方向坐标
} AIPoint;

typedef struct TTShape {
  int h;  // height
  int w;  // width
} TTShape;

typedef struct TTKeyPoint {
  float x;         // 对应 cols, 范围在 [0, width] 之间
  float y;         // 对应 rows, 范围在 [0, height] 之间
  bool is_detect;  // 如果该值为 false, 则 x,y 无意义
} TTKeyPoint;

typedef struct TTKeyPoint3D {
  float x;         // 对应 cols, 范围在 [0, width] 之间
  float y;         // 对应 rows, 范围在 [0, height] 之间
  float z;
  bool is_detect;  // 如果该值为 false, 则 x,y 无意义
} TTKeyPoint3D;

typedef struct AIKeypoint {
  float x;
  float y;
  float score;
  int detected;
} AIKeypoint;

// 该枚举尽量不要用，后面会y废弃。Error 代码可以使用下面的 SMASH_E_xxx
typedef enum {
  TT_SUCESS = 1,
  TT_OK = 0,
  TT_FAILED = -1,
  TT_SCALE_FAILED = -2,
  TT_NULL = -3,
  TT_FILE_OPEN_FAILED = -4,
  TT_LOAD_MODEL_FAILED = -5,
  TT_MODEL_COMPUTE_FAILED = -6,
  TT_IMAGE_FORMAT_WRONG = -7,
  TT_IMAGE_ORIENT_WRONG = -8,
  TT_NOT_IMPLEMENT = -9,
  TT_MODEL_NOT_INIT = -10,
  TT_NULL_THRUSTOR = -11,
  TT_GET_PARAM_FAIL = -13,
  TT_CREATE_NET_FAIL = -14,
  TT_EMPTY_IMAGE = -15,
  TT_INVALID_HANDLE = -16,
  TT_INVALID_PARAM_TYPE = -17,
  TT_MALLOC_FAIL = -18,
  TT_INCOMPLETE_MODEL = -19,
  // INIT_PARAM_OK = 0,

} TTReturnCode;

#define SMASH_OK 0
#define SMASH_E_INTERNAL -101    // 未知错误
#define SMASH_E_NOT_INITED -102  // 未初始化相关资源
#define SMASH_E_MALLOC -103      // 申请内存失败
#define SMASH_E_INVALID_PARAM -104
#define SMASH_E_ESPRESSO -105
#define SMASH_E_MOBILECV -106
#define SMASH_E_INVALID_CONFIG -107
#define SMASH_E_INVALID_HANDLE -108
#define SMASH_E_INVALID_MODEL -109
#define SMASH_E_INVALID_PIXEL_FORMAT -110
#define SMASH_E_INVALID_POINT -111
#define SMASH_E_REQUIRE_FEATURE_NOT_INIT -112
#define SMASH_E_NOT_IMPL -113
// module specific error code
// #define SMASH_E_MATTING_xxx          -1001

// For skeleton, bodydance, joints
typedef enum {
  kNose,           // 鼻子
  kNeck,           // 脖子
  kRightShoulder,  // 右肩
  kRightElbow,     // 右手肘
  kRightWrist,     // 右手腕
  kLeftShoulder,   // 左肩
  kLeftElbow,      // 左手肘
  kLeftWrist,      // 左手腕
  kRightHip,       // 右臀
  kRightKnee,      // 右膝
  kRightAnkle,     // 右踝
  kLeftHip,        // 左臀
  kLeftKnee,       // 左膝
  kLeftAnkle,      // 左踝
  kRightEye,       // 右眼
  kLeftEye,        // 左眼
  kRightEar,       // 右耳
  kLeftEar,        // 左耳
  kRightHand,      // 右手
  kLeftHand,       // 左手
} PersonKeyPointType;

typedef struct TTJoint {
  int x;                    // 对应 cols, 范围在 [0, width] 之间
  int y;                    // 对应 rows, 范围在 [0, height] 之间
  int r;                    // 关节点大致的范围
  PersonKeyPointType type;  // 关节点的类别
} TTJoint;

// 当前18个CPM关键点信息！
#define KeyPointNUM 18

/////////////////////////////
// face3dMM Macro
#define MESH_LEVEL3_PTS 845
#define MESH_LEVEL2_PTS 3300

#define MESH_LEVEL_3 1026
#define MESH_LEVEL_2 3481

#define MESH_COM_DIM 186
#define MESH_COM_CUT 160

#define FLILT2_NUM 6440
#define FLILT3_NUM 1610

#define CONTOUR_PTS_NUM_LEVEL3 72
#define MESH_VL_NUM_LEVEL3 4
#define MESH_HL_NUM_LEVEL3 15

#define CONTOUR_PTS_NUM_LEVEL2 76
#define MESH_VL_NUM_LEVEL2 8
#define MESH_HL_NUM_LEVEL2 30

#define MESH_LANMARK181_NUM 181

#define MESH_TYPE_SWITCH

#ifdef MESH_TYPE_SWITCH
#define MESH_LEVEL_PTS MESH_LEVEL3_PTS
#define MESH_LEVEL MESH_LEVEL_3
#define FLIST_NUM FLILT3_NUM
#define CONTOUR_PTS_NUM CONTOUR_PTS_NUM_LEVEL3
#define MESH_VL_NUM MESH_VL_NUM_LEVEL3
#define MESH_HL_NUM MESH_HL_NUM_LEVEL3
#else
#define MESH_LEVEL_PTS MESH_LEVEL2_PTS
#define MESH_LEVEL MESH_LEVEL_2
#define FLIST_NUM FLILT2_NUM
#define CONTOUR_PTS_NUM CONTOUR_PTS_NUM_LEVEL2
#define MESH_VL_NUM MESH_VL_NUM_LEVEL2
#define MESH_HL_NUM MESH_HL_NUM_LEVEL2
#endif
///////////////////////////////
// animoji
#define AM_E_DIM 52
#define AM_U_DIM 75
//
//////////////////////////////
#endif  // COMMON_H_
