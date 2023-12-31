#ifndef _SKELETON_API_H
#define _SKELETON_API_H

#include <vector>
#include "tt_common.h"

#if defined __cplusplus
extern "C" {
#endif

#define KPOINT_NUM 18
#define SK_MAX_HEATMAP_SIZE 11232 // 18 * 24 * 26
#define SK_MAX_BACKBONE_FEAT_SIZE 6912 // 9 * 12 * 64

// prefix: SK -> SKeleton
typedef void* SkeletonHandle;

/*
int gPersonKeyPointOrder[] = {
  kNose, kNeck, kRightShoulder, kRightElbow, kRightWrist, kLeftShoulder,
kLeftElbow, kLeftWrist, kRightHip, kRightKnee, kRightAnkle, kLeftHip, kLeftKnee,
kLeftAnkle, kRightEye, kLeftEye, kRightEar, kLeftEar
};

int gLimb[][2] = {
  {kNeck, kRightShoulder},
  {kNeck, kLeftShoulder},
  {kRightShoulder, kRightElbow},
  {kRightElbow, kRightWrist},
  {kLeftShoulder, kLeftElbow},
  {kLeftElbow, kLeftWrist},
  {kNeck, kRightHip},
  {kRightHip, kRightKnee},
  {kRightKnee, kRightAnkle},
  {kNeck, kLeftHip},
  {kLeftHip, kLeftKnee},
  {kLeftKnee, kLeftAnkle},
  {kNeck, kNose},
  {kNose, kRightEye},
  {kRightEye, kRightEar},
  {kNose, kLeftEye},
  {kLeftEye, kLeftEar}
};*/

// 创建模型句柄
AILAB_EXPORT
int SK_CreateHandle(SkeletonHandle* out);

AILAB_EXPORT
int SK_InitModelFromBuf(SkeletonHandle handle,
                        const char* param_buf,
                        unsigned int len);

// 初始化模型
// param_path 传参数文件的地址，需要 lab-cv 的人提供
AILAB_EXPORT
int SK_InitModel(SkeletonHandle handle, const char* param_path);

// net_input_width 和 net_input_height
// 表示神经网络的传入，一般情况下不同模型不太一样，具体值需要 lab-cv
// 的人提供，一般情况下与屏幕输入的图像大小要成比例，算法的效果会比较好。
// 此处（Skeleton）iOS 传入值约定为 net_input_width = 128, net_input_height =
// 224 Android 具体多少待定
AILAB_EXPORT
int SK_SetParam(SkeletonHandle handle,
                int net_input_width,
                int net_input_height);

AILAB_EXPORT
int SK_SetSmoothSigma(SkeletonHandle handle,
                      const float sigma);


AILAB_EXPORT
int SK_SetDetectionInputSize(SkeletonHandle handle,
                             const int width,
                             const int height);

AILAB_EXPORT
int SK_SetTrackingInputSize(SkeletonHandle handle,
                            const int width,
                            const int height);

AILAB_EXPORT
int SK_DoSkeletonEstimationSinglePerson(
        SkeletonHandle handle,
        const unsigned char* src_image_data,
        PixelFormatType pixel_format,
        int width,
        int height,
        int image_stride,
        ScreenOrient orient,
        std::vector<std::vector<TTKeyPoint> >& keypoint_position,
        std::vector<AIRect>& boxes);

AILAB_EXPORT
int SK_DoSkeletonEstimationMultiPerson(
                                       SkeletonHandle handle,
                                       const unsigned char* src_image_data,
                                       PixelFormatType pixel_format,
                                       int width,
                                       int height,
                                       int image_stride,
                                       ScreenOrient orient,
                                       std::vector<std::vector<TTKeyPoint> >& keypoint_position,
                                       std::vector<AIRect>& boxes);

AILAB_EXPORT
int SK_DoSkeletonTracking(
                          SkeletonHandle handle,
                          const unsigned char* src_image_data,
                          PixelFormatType pixel_format,
                          int width,
                          int height,
                          int image_stride,
                          ScreenOrient orient,
                          std::vector<std::vector<AIKeypoint> >& keypoints,
                          std::vector<AIRect>& boxes,
                          std::vector<int>& track_id);

AILAB_EXPORT
int SK_DoSkeletonEstimationInImage(
                                   SkeletonHandle handle,
                                   const unsigned char* src_image_data,
                                   PixelFormatType pixel_format,
                                   int width,
                                   int height,
                                   int image_stride,
                                   ScreenOrient orient,
                                   std::vector<std::vector<AIKeypoint> >& keypoints,
                                   std::vector<AIRect>& boxes,
                                   std::vector<int>& track_id,
                                   const int iter_num=3);

AILAB_EXPORT
int SK_SetTargetNum(SkeletonHandle handle, const int target_num);

AILAB_EXPORT
int SK_GetBackboneFeatandHeatmap(SkeletonHandle handle,
                                 float* backbone_feats,
                                 float* heatmaps,
                                 int& target_num,
                                 int& backbone_feat_dim,
                                 int& heatmap_dim);

enum SKParamType {
  kReset = 1,
  kTargetNumber = 2,
  kIterationNumberAfterDetection = 3,
  kExtractBackboneFeature = 4,
  kResultKptsSet = 5,
  kFiltObj = 6,
  kOutputMode = 7,
};

AILAB_EXPORT
int SK_SetParamF(void* handle,
                 SKParamType type,
                 float value);

AILAB_EXPORT
int SK_ReleaseHandle(SkeletonHandle handle);

#if defined __cplusplus
};
#endif

#endif  // _SKELETON_API_H
