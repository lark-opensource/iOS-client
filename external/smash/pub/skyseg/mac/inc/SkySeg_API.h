#ifndef _SKY_SEG_API_H
#define _SKY_SEG_API_H

#include "tt_common.h"

#if defined __cplusplus
extern "C" {
#endif
// prefix: SS -> Sky Seg

typedef void* SkySegHandle;

AILAB_EXPORT
int SS_CreateHandler(SkySegHandle* out);

// param_path 传参数文件的地址，需要 lab-cv 的人提供
AILAB_EXPORT
int SS_InitModel(SkySegHandle handle, const char* param_path);

AILAB_EXPORT
int SS_InitModelFromBuf(SkySegHandle handle,
                        const char* param_buf,
                        unsigned int len);

// net_input_width 和 net_input_height
// 表示神经网络的传入，一般情况下不同模型不太一样，具体值需要 lab-cv 的人提供。
// 此处（SkySeg）传入值约定为 net_input_width = 128, net_input_height = 224
AILAB_EXPORT
int SS_SetParam(SkySegHandle handle, int net_input_width, int net_input_height);

// output_width, output_height, channel 用于得到 SS_DoSkySegment 接口输出的
// alpha 大小 如果在 SS_SetParam 的参数中，net_input_width，net_input_height
// 已按约定传入，即 net_input_width = 128, net_input_height = 224
// 那么返回值：output_width = 64, output_height = 112
//
// (net_input_width, net_input_height) 与 (output_width, output_height)
// 之间的关系不同模型 不太一样，需要询问 lab-cv 的同学 在该接口中，channel
// 始终返回 1
AILAB_EXPORT
int SS_GetOutputShape(SkySegHandle handle,
                      int* output_width,
                      int* output_height,
                      int* channel);

// Param:
//   src_image_data 为传入图片的大小，图片大小任意
//   pixel_format， width, height, image_stride 为传入图片的信息
//   has_sky_check 表示是否需要判断当前帧是否有天空
//   has_sky 表示当时帧是否有天空
AILAB_EXPORT
int SS_DoSkySegment(SkySegHandle handle,
                    const unsigned char* src_image_data,
                    PixelFormatType pixel_format,
                    int width,
                    int height,
                    int image_stride,
                    ScreenOrient orient,
                    unsigned char* dst_alpha_data,
                    bool need_flip_alpha,
                    bool has_sky_check,
                    int* has_sky);

AILAB_EXPORT
int SS_ReleaseHandle(SkySegHandle handle);

#if defined __cplusplus
};
#endif
#endif  // _SKY_SEG_API_H
