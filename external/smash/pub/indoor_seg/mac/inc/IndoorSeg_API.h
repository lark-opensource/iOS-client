#ifndef _SMASH_INDOORSEGAPI_H_
#define _SMASH_INDOORSEGAPI_H_

#include "tt_common.h"
// prefix: IS -> IndoorParser

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

#define IndoorSeg_HOMOGRAPHY_NUM 9
#define IndoorSeg_ANGLE_ORDER 3
#define IndoorSeg_CATEGORIES 3
#define IndoorSeg_MAX_SIZE 224

typedef void* IndoorSegHandle;

// 模型参数类型
typedef enum IndoorSeg_ParamType {
  IndoorSeg_MODEL_TYPE,
  IndoorSeg_NET_IN_WIDTH,
  IndoorSeg_NET_IN_HEIGHT,
  IndoorSeg_USE_TRACKING_INDOOR_SEG,
  IndoorSeg_ANGLE_FULL,
  IndoorSeg_ANGLE_BG,
  IndoorSeg_Track_Ceiling,//1调用平滑0不调用,默认为1
  IndoorSeg_Track_Wall,//1调用平滑0不调用,默认为1
  IndoorSeg_Track_Ground,//1调用平滑0不调用,默认为1
} IndoorSeg_ParamType;

//// 模型枚举，有些模块可能有多个模型
typedef enum IndoorSeg_ModelType {
  IndoorSeg_Model_In,
  IndoorSeg_Model_Out,
} IndoorSeg_ModelType;

typedef struct IndoorSegInfo {
  // 给算法输入图片大小为 HxW, mask[0]为天花板，mask[1]为墙壁，mask[2]为地面
  unsigned char* mask[IndoorSeg_CATEGORIES]; // 天花板墙壁地面分割分割的mask, 其长宽高会根据输入图片大小把最长边resize到224
  int width; // mask的宽度, 不超过224
  int height; // mask的高度, 不超过224
} IndoorSegInfo;


AILAB_EXPORT
IndoorSegInfo* IndoorSeg_MallocResultMemory(IndoorSegHandle handle);

AILAB_EXPORT
int IndoorSeg_FreeResultMemory(IndoorSegInfo *res);

// src_image_data 为传入图片的大小，图片大小任意
// pixel_format， width, height, image_stride 为传入图片的信息


AILAB_EXPORT
int IndoorSeg_DoIndoorSegmentation(IndoorSegHandle handle,
                            const unsigned char* src_image_data,
                            PixelFormatType pixel_format,
                            int width,
                            int height,
                            int image_stride,
                            ScreenOrient orient,
                            IndoorSegInfo* image_info,
                            float euler_angles[3]); // pitch 范围 [-3.14, 3.14] 代表 手机的俯仰角

AILAB_EXPORT
int IndoorSeg_CreateHandler(IndoorSegHandle* out);

// param_path 传参数文件的地址，需要 lab-cv 的人提供
AILAB_EXPORT
int IndoorSeg_InitModel(IndoorSegHandle handle, IndoorSeg_ModelType type, const char* param_path);

AILAB_EXPORT
int IndoorSeg_InitParam(void* handle);

AILAB_EXPORT
int IndoorSeg_InitModelFromBuf(IndoorSegHandle handle,
                               IndoorSeg_ModelType type,
                                const char* param_buff,
                                int len);

AILAB_EXPORT
int IndoorSeg_SetParamF(IndoorSegHandle handle, IndoorSeg_ParamType type, float value);


// output_width, output_height, channel 用于得到 IndoorSeg_DoIndoorSegmentation 接口输出的
// alpha 大小
//
// (net_input_width, net_input_height) 与 (output_width, output_height)
// 之间的关系不同模型 不太一样，需要询问 lab-cv 的同学 在该接口中，channel
// 始终返回 1
AILAB_EXPORT
int IndoorSeg_GetOutputShape(IndoorSegHandle handle,
                      int* output_width,
                      int* output_height,
                      int* channel);

AILAB_EXPORT
int IndoorSeg_SetHomography(IndoorSegHandle handle,
                     int state,
                     float h[IndoorSeg_HOMOGRAPHY_NUM],
                     float k_big[IndoorSeg_HOMOGRAPHY_NUM],
                     float k_small[IndoorSeg_HOMOGRAPHY_NUM]);

// a 建议为 [2,0,1] 的数组 wRb 为imu的9个wRb信息，返回res返回3个值 先申请长度为3的数组res
AILAB_EXPORT
int IndoorSeg_IMU2EulerAngles(IndoorSegHandle handle,
                     float wRb[IndoorSeg_HOMOGRAPHY_NUM],
                       int a[IndoorSeg_ANGLE_ORDER],
                     float *res);




AILAB_EXPORT
int IndoorSeg_ReleaseHandle(IndoorSegHandle handle);

#ifdef __cplusplus
}
#endif  // __cplusplus
#endif  // _SMASH_INDOORSEGAPI_H_
