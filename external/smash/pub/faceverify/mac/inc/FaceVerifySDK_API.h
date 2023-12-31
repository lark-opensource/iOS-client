#ifndef _FACEVERIFYSDK_API_H_
#define _FACEVERIFYSDK_API_H_

#include "FaceSDK_API.h"

#if defined __cplusplus
extern "C" {
#endif
// prefix: FVS -> FaceVerifySDK

typedef void *FaceVerifyHandle;  // 人脸验证句柄

#define AI_FACE_FEATURE_DIM 128  // 人脸特征的维数

// 结果信息
typedef struct AIFaceVerifyInfo {
  AIFaceInfoBase
      base_infos[AI_MAX_FACE_NUM];  // 基本的人脸信息，包含106点、动作、姿态
  float features[AI_MAX_FACE_NUM][AI_FACE_FEATURE_DIM];  // 存放人脸特征
  int valid_face_num;  // 检测到的人脸数目
} AIFaceVerifyInfo;

/*
 *@brief 初始化handle
 *@param face_verify_param_path  人脸识别模型的文件路径
 *@param max_face_num            要处理的最大人脸数，该值不能大于AI_MAX_FACE_NUM
 */
AILAB_EXPORT
int FVS_CreateHandler(const char *face_verify_path,
                      const int max_face_num,
                      FaceVerifyHandle *handle);

AILAB_EXPORT
int FVS_CreateHandlerFromBuf(const char *face_verify_buf,
                             unsigned int face_verify_buf_len,
                             const int max_face_num,
                             FaceVerifyHandle *handle);

AILAB_EXPORT
int FVS_DoExtractFeature(
    FaceVerifyHandle handle,
    const unsigned char *image,
    PixelFormatType pixel_format,  // 图片格式，支持RGBA, BGRA, BGR, RGB,
                                   // GRAY(YUV暂时不支持)
    int image_width,               // 图片宽度
    int image_height,              // 图片高度
    int image_stride,              // 图片行跨度
    ScreenOrient orientation,      // 图片的方向
    const AIFaceInfo *face_input_ptr, // 调用人脸SDK得到的人脸信息
    AIFaceVerifyInfo *
        face_info_ptr  // 存放结果信息，需外部分配好内存，需保证空间大于等于设置的最大检测人脸数
);

AILAB_EXPORT
int FVS_DoExtractFeatureSingle(
    FaceVerifyHandle handle,
    const unsigned char *image,
    PixelFormatType pixel_format,  // 图片格式，支持RGBA, BGRA, BGR, RGB,
                                   // GRAY(YUV暂时不支持)
    int image_width,               // 图片宽度
    int image_height,              // 图片高度
    int image_stride,              // 图片行跨度
    ScreenOrient orientation,      // 图片的方向
    AIFaceInfoBase base_info,      // 基本的人脸信息，包含106点、动作、姿态
    float *features               // 存放人脸特征
);

/*
 *@brief 释放句柄
 *param: handle 句柄
 */
AILAB_EXPORT void FVS_ReleaseHandle(FaceVerifyHandle handle);

#define FACE_VERIFY_SIZE 112         // 用于提取特征的人脸的尺寸
typedef void *FaceVerifyCropHandle;  // face crop handle

typedef struct AIFaceVerifyCropInfo {
  AIFaceInfoBase base_infos;  //（输入）基本的人脸信息，包含106点、动作、姿态
  unsigned char crop_img[FACE_VERIFY_SIZE * FACE_VERIFY_SIZE *
                         3];  // （输出）用于存储crop后的image buffer
} AIFaceVerifyCropInfo;

/*
 *@brief 初始化handle
 */
AILAB_EXPORT int FVS_AlingCropInitHandle(FaceVerifyCropHandle *handle);

AILAB_EXPORT int FVS_AlignCrop(
    FaceVerifyCropHandle handle,
    const unsigned char *image,
    PixelFormatType pixel_format,  // 图片格式，支持RGBA, BGRA, BGR, RGB,
    int image_width,               // 图片宽度
    int image_height,              // 图片高度
    int image_stride,              // 图片行跨度
    ScreenOrient orientation,      // 图片的方向
    AIFaceVerifyCropInfo *face_crop_info_ptr);

AILAB_EXPORT int FVS_AlignCropRelease(FaceVerifyCropHandle handle);

#if defined __cplusplus
};
#endif
#endif  // _FACEVERIFYSDK_API_H_
