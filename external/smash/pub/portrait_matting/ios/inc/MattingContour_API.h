#ifndef _SMASH_MATTING_CONTOUR_API_H_
#define _SMASH_MATTING_CONTOUR_API_H_

#ifdef DEBUG_WITH_MASK
  #include <mobilecv2/core.hpp>
#endif

#include <vector>
#include "tt_common.h"


#if defined __cplusplus
extern "C" {
#endif

typedef enum {
  kMattingContourKeypointHead = 0,  // 头

  kMattingContourKeypointRightShoulder = 1,  // 右肩
  kMattingContourKeypointRightShoulderInner = 2,
  kMattingContourKeypointRightElbow = 3,  // 右手肘
  kMattingContourKeypointRightElbowInner = 4,
  kMattingContourKeypointRightHand = 5,  // 右手

  kMattingContourKeypointLeftShoulder = 6,  // 左肩
  kMattingContourKeypointLeftShoulderInner = 7,
  kMattingContourKeypointLeftElbow = 8,  // 左手肘
  kMattingContourKeypointLeftElbowInner = 9,
  kMattingContourKeypointLeftHand = 10,  // 左手

  kMattingContourKeypointRightHip = 11,  // 右臀
  kMattingContourKeypointLeftHip = 12,   // 左臀
  kMattingContourKeypointHipInner = 13,

  kMattingContourKeypointRightKnee = 14,  // 右膝
  kMattingContourKeypointRightKneeInner = 15,

  kMattingContourKeypointLeftKnee = 16,  // 左膝
  kMattingContourKeypointLeftKneeInner = 17,

  kMattingContourKeypointRightFoot = 19,  // 右脚
  kMattingContourKeypointLeftFoot = 20,   // 左脚

  kMattingContourKeypointNum = 21,
} MattingContourKeypointType;

typedef void* MattingContourHandle;

typedef struct MattingContourArgs {
  unsigned char* alpha;
  int alpha_w;
  int alpha_h;
  int output_w;
  int output_h;
  int density;  // density不得小于2
  int contour_thickness;

  // 当 kAlgoVers 为 2 需要传以下字段
  // 需要先调用 SK_DoSkeletonTracking 获得骨架关键点 sk_keypoints
  std::vector<std::vector<AIKeypoint>> sk_keypoints;
} MattingContourArgs;

typedef struct Contours {
  Contours() : points(nullptr), keypoint_position(nullptr) {}

  AIPoint* points;  // 当 kAlgoVers 为 2 时, points[i] = (-100,
                    // -100)表示该点不用渲染。
  int point_num;

  // 当 kAlgoVers 为 2 时会获到以下信息
  int skeleton_idx;  // 轮廓对应的骨架id，默认值为 -1，
                     // -1表示该轮廓点集无有效骨架信息
  int* keypoint_position;  // 基于骨架的轮廓关键点（具体参见MattingContourKeypointType）在
                           // points 中的序号，-1 表示该关键点不在轮廓点集中
                           // 如points的第0个数据是头的关键点坐标，那么keypoint_position[kMattingContourKeypointHead]
                           // = 0
  int keypoint_position_num;  // 该值为定值，21
} Contour;

typedef struct MattingContourResult {
  Contour* contours;
  int contour_num;

#ifdef DEBUG_WITH_MASK
  mobilecv2::Mat mask;
#endif
} MattingContourResult;

typedef struct MattingContourParamType {
  // 0 表示 line
  // 1 表示 block
  // 2 表示 line with skeleton
  int kAlgoVers;
} MattingContourParamType;

AILAB_EXPORT
int MattingContour_SetParamF(MattingContourHandle handle,
                             MattingContourParamType type,
                             float value);

////////////////// 以下2个接口将在之后的版本废弃 ///////////////////////////////

typedef enum {
  CONTOUR_LINE = 0,
  CONTOUR_BLOCK = 1,
  CONTOUR_WITH_SKELETON = 2,
  CONTOUR_TYPE_NUM = 3,
} eContourType;

AILAB_EXPORT
int MattingContour_SetParam(
    MattingContourHandle handle,
    MattingContourParamType type,
    float stable = 0.98);  // the value is to control stabel

///////////////////////////////////////////////////////////////////////////

AILAB_EXPORT
int MattingContour_CreateHandle(MattingContourHandle* handle);

// 返回值为1表示结果出错，返回值为0表示结果正确
AILAB_EXPORT
int MattingContour_GetContour(MattingContourHandle handle,
                              MattingContourArgs* args,
                              MattingContourResult* result);

AILAB_EXPORT
int MattingContour_ReleaseHandle(MattingContourHandle handle);


#if defined __cplusplus
};
#endif
#endif  // _SMASH_MATTING_CONTOUR_API_H_
