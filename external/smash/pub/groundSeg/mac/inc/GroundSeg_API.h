#ifndef _SMASH_GROUNDSEGAPI_H_
#define _SMASH_GROUNDSEGAPI_H_

#include "tt_common.h"
// prefix: GS -> GroundParser

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

typedef void* GroundSegHandle;

// 模型参数类型
typedef enum GS_ParamType {
  MODEL_TYPE,
  NET_IN_WIDTH,
  NET_IN_HEIGHT,
  USE_TRACKING_GROUND_SEG,
} GS_ParamType;

//// 模型枚举，有些模块可能有多个模型
typedef enum GS_ModelType {
  GS_Model_In,
  GS_Model_Out,
} GS_ModelType;

AILAB_EXPORT
int GS_CreateHandler(GroundSegHandle* out);

// param_path 传参数文件的地址，需要 lab-cv 的人提供
AILAB_EXPORT
int GS_InitModel(GroundSegHandle handle, const char* param_path, const char* model_last_layer);

AILAB_EXPORT
int GS_InitParam(void* handle);

AILAB_EXPORT
int GS_InitModelFromBuf(GroundSegHandle handle,
                        const char* param_buff,
                        int len,
                        const char* model_last_layer);

AILAB_EXPORT
int GS_SetParamF(GroundSegHandle handle, GS_ParamType type, float value);


// output_width, output_height, channel 用于得到 GS_DoGroundSegmentation 接口输出的
// alpha 大小
//
// (net_input_width, net_input_height) 与 (output_width, output_height)
// 之间的关系不同模型 不太一样，需要询问 lab-cv 的同学 在该接口中，channel
// 始终返回 1
AILAB_EXPORT
int GS_GetOutputShape(GroundSegHandle handle,
                      int* output_width,
                      int* output_height,
                      int* channel);

// src_image_data 为传入图片的大小，图片大小任意
// pixel_format， width, height, image_stride 为传入图片的信息
AILAB_EXPORT
int GS_DoGroundSegmentation(GroundSegHandle handle,
                            const unsigned char* src_image_data,
                            PixelFormatType pixel_format,
                            int width,
                            int height,
                            int image_stride,
                            ScreenOrient orient,
                            unsigned char* dst_alpha_data,
                            bool need_flip_alpha);

AILAB_EXPORT
int GS_SetHomography(GroundSegHandle handle,
                     int state,
                     float h[9],
                     float k_big[9],
                     float k_small[9]);

AILAB_EXPORT
int GS_ReleaseHandle(GroundSegHandle handle);

#ifdef __cplusplus
}
#endif  // __cplusplus
#endif  // _SMASH_GROUNDSEGAPI_H_
