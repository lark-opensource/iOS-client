//
// Created by liuzhichao on 2018/1/11.
//

#ifndef LipSegmentationSDK_API_HPP
#define LipSegmentationSDK_API_HPP

#include <map>
#include "tt_common.h"

struct LipSegResult {
  int faceID;
  unsigned char *alpha;
  int outWidth;
  int outHeight;
  int outChannel;
  double matrix[6];
};

#define TT_LIPSEG_SINGLE_LIP_MODEL 0
#define TT_LIPSEG_LIP_HIGHLIGHT_TEETH_MODEL 1

typedef void *LipSegmentationHandle;

AILAB_EXPORT
int LS_CreateHandler(LipSegmentationHandle *out);

/**
 * @param handle Created handle
 * @param net_input_width   网络输入的大小
 * @param net_input_height
 * @param use_tracking      传递true 用于 防抖
 * @param max_face_count    最大支持的人脸个数
 * @return 0 success
 */
AILAB_EXPORT
int LS_InitModelWithParam(LipSegmentationHandle handle,
                          int net_input_width,
                          int net_input_height,
                          bool use_tracking,
                          int max_face_count,
                          int model = TT_LIPSEG_SINGLE_LIP_MODEL);

/**h
 *  对每一个人脸id进行 跑 分割网络
 * @param faces     <id, pt106>
 * @param pixelFormat   kPixelFormat_BGRA8888 或者 kPixelFormat_RGBA8888
 * @param segResult   <id, LipSegResult>
 * @return 0 success
 */
AILAB_EXPORT
int LS_DoLipSegmentation(LipSegmentationHandle handle,
                         std::map<int, float *> &faces,
                         int viewWidth,
                         int viewHeight,
                         const unsigned char *srcData,
                         PixelFormatType pixelFormat,
                         int width,
                         int height,
                         int stride,
                         ScreenOrient orient,
                         std::map<int, LipSegResult> &segResult);

// Return 0 if succ
AILAB_EXPORT
int LS_ReleaseHandle(LipSegmentationHandle handle);

#endif  // LipSegmentationSDK_API_HPP
