#ifndef _FACEPACTBEAUTY_SDK_API_H_
#define _FACEPACTBEAUTY_SDK_API_H_

#include "FaceSDK_API.h"

// prefix: FPBS -> FacePartBeauty

typedef void *FacePartBeautyHandle;  // 人脸验证句柄

#define FPBS_FACE_FEATURE_DIM 256  // 人脸特征的维数
#define FPBS_MAX_FACE_NUM 2 //此接口只支持最多同时2个人
//const char *face_part[] = {"brow","eye","nose","mouth","chin"}; //五官名称列表

// 结果信息
typedef struct AIFaceFeatureInfo {
  AIFaceInfoBase base_infos[AI_MAX_FACE_NUM];  // 基本的人脸信息，包含106点、动作、姿态
  float features[AI_MAX_FACE_NUM][FPBS_FACE_FEATURE_DIM];  // 存放人脸特征
  int valid_face_num;  // 检测到的人脸数目
} AIFaceFeatureInfo;

/*
 *@brief 初始化handle
 *@param face_param_path         人脸关键点模型的文件路径
 *@param face_verify_param_path  人脸识别模型的文件路径
 *@param max_face_num            要处理的最大人脸数，该值不能大于AI_MAX_FACE_NUM
 */
AILAB_EXPORT
int FPBS_CreateHandler(const char *face_verify_path,
                       const int max_face_num,
                       FacePartBeautyHandle *handle);

AILAB_EXPORT
int FPBS_CreateHandlerFromBuf(const char *face_verify_buf,
                              unsigned int face_verify_buf_len,
                              const int max_face_num,
                              FacePartBeautyHandle *handle);

AILAB_EXPORT
int FPBS_DoExtractFeature(
        FacePartBeautyHandle handle,
        const unsigned char *image,
        PixelFormatType pixel_format,  // 图片格式，支持RGBA, BGRA, BGR, RGB, // GRAY(YUV暂时不支持)
        int image_width,               // 图片宽度
        int image_height,              // 图片高度
        int image_stride,              // 图片行跨度
        ScreenOrient orientation,      // 图片的方向
        AIFaceInfo *p_faces_info,
        AIFaceFeatureInfo *face_info_ptr  // 存放结果信息，需外部分配好内存，需保证空间大于等于设置的最大检测人脸数
);

/*
 *@brief 释放句柄
 *param: handle 句柄
 */
AILAB_EXPORT void FPBS_ReleaseHandle(FacePartBeautyHandle handle);

/**
 * @brief 获取模块的建议输入大小
 * @param width
 * @param height
 */
AILAB_EXPORT void FPBS_GetInputSize(int *width, int *height);

// 最美五官结果信息
typedef struct AIFacePartBeautyInfo {
    int beauty_id;  // 存放最美五官id，按照{"brow","eye","nose","mouth","chin"}五官名称列表
    int beauty_score[5];  // 存放五官颜值打分
} AIFacePartBeautyInfo;

AILAB_EXPORT int FPBS_FaceBeautyPart(
                                    float *feature,      // 人脸特征
                                    AIFacePartBeautyInfo *face_beauty_part_info_ptr);


#endif  // _FACEPACTBEAUTY_SDK_API_H_
