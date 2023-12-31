//
// Created by liuzhichao on 2018/1/11.
//

#ifndef HeadSegmentationSDK_API_HPP
#define HeadSegmentationSDK_API_HPP

#include "tt_common.h"
#if defined __cplusplus
extern "C" {
#endif
typedef void* HeadSegHandle;

#define HS_FACE_KEY_POINT_NUM 106

typedef struct {
  int net_input_width;  //网络输入的大小
  int net_input_height;
} HeadSegConfig;

typedef struct {
  int face_id;
  AIPoint points[HS_FACE_KEY_POINT_NUM];
} HeadSegFaceInfo;

typedef struct {
  int face_id;
  unsigned char* alpha;
  unsigned char* crop;
  int width;
  int height;
  int channel;
  double matrix[6];
} HeadSegFaceResult;

typedef struct {
  unsigned char* image;
  int image_width;
  int image_height;
  int image_stride;
  PixelFormatType
      pixel_format;  // kPixelFormat_BGRA8888 或者 kPixelFormat_RGBA8888
  ScreenOrient orient;
  HeadSegFaceInfo* face_info;
  int face_count;

} HeadSegInput;

typedef struct {
  HeadSegFaceResult* face_result;
  int face_count;
} HeadSegOutput;

typedef enum {
  HS_ENABLE_TRACKING = 1,  // default set to 1 传递true 用于 防抖
  HS_MAX_FACE = 2,
} HeadSegParamType;

AILAB_EXPORT
int HSeg_CreateHandler(HeadSegHandle* out);

//设置网络输入参数
AILAB_EXPORT
int HSeg_SetConfig(HeadSegHandle handle, HeadSegConfig* config);

//设置模型参数
AILAB_EXPORT
int HSeg_SetModelFromBuff(HeadSegHandle handle,
                          const unsigned char* param,
                          unsigned int param_len);

//设置模块参数
AILAB_EXPORT
int HSeg_SetParam(HeadSegHandle handle, HeadSegParamType type, float value);

AILAB_EXPORT
// int HS_InitModel(HeadSegHandle handle, const char* param);
int HSeg_InitModel(HeadSegHandle handle, const char* param_path);

AILAB_EXPORT
int HSeg_DoHeadSeg(HeadSegHandle handle,
                   HeadSegInput* input,
                   HeadSegOutput* output);

AILAB_EXPORT
int HSeg_ReleaseHandle(HeadSegHandle handle);

#if defined __cplusplus
};
#endif

#endif  // LipSegmentationSDK_API_HPP
