#ifndef _MUG_DETECT_API_H
#define _MUG_DETECT_API_H

#include "tt_common.h"

// prefix: MUG -> Mug

#define MAX_MUG_NUM 10

typedef void* MugDetectHandle;

typedef struct MugInfos {
  AIRect regions[MAX_MUG_NUM];  ///杯子的框
  AIPoint points[MAX_MUG_NUM]
                [4];  ///杯子的四个顶点，当图片旋转时，可用来定位region 的方向
  float probs[MAX_MUG_NUM];  ///检测到的杯子的概率；
  int ids[MAX_MUG_NUM];      ///杯子跟踪的ID
  int count;                 ///跟踪到的杯子的数目；
} MugInfos, *PtrMugInfos;

AILAB_EXPORT
int MUG_CreateHandler(MugDetectHandle* out);

// param_path 传参数文件的地址，需要 lab-cv 的人提供
AILAB_EXPORT
int MUG_InitModel(MugDetectHandle handle, const char* param_path);

AILAB_EXPORT
int MUG_InitModelFromBuf(MugDetectHandle handle,
                         const unsigned char* model_buf,
                         unsigned int model_buf_len);

// image_width: 传入的大图宽度
// image_heigth: 传入的大图高度
// max_side_len: 此处设为 256
// 此接口已废弃，不再维护
AILAB_EXPORT
int MUG_SetParam(MugDetectHandle handle,
                 int image_width,
                 int image_heigth,
                 int max_side_len);

// 新接口
AILAB_EXPORT
int MUG_SetParam(MugDetectHandle handle, int max_side_len);

// src_image_data 为传入图片的大小，图片大小任意
// pixel_format， width, height, image_stride 为传入图片的信息
AILAB_EXPORT
int MUG_DoMugDetect(MugDetectHandle handle,
                    const unsigned char* src_image_data,
                    PixelFormatType pixel_format,
                    int width,
                    int height,
                    int image_stride,
                    ScreenOrient orient,
                    MugInfos* ptr_results);

AILAB_EXPORT
int MUG_ReleaseHandle(MugDetectHandle handle);

#endif
