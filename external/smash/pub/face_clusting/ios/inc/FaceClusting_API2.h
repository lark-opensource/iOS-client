#ifndef FaceClusting_API2_H
#define FaceClusting_API2_H
#include "FaceClusting_Define.h"
#include "tt_common.h"

#if defined __cplusplus
extern "C"
{
#endif

  // clang-format off
/*
 *@brief 人物识别时候，需要 加载模型才能使用
 *@note 只做人物人物聚类无需设置
 *@note 根据识别的人物数目的不同，可以设置不同的模型
 *
 **/
AILAB_EXPORT
int FaceClusting_SetModel2(FaceClustingHandle handle, const char* model_path);

/*
 *@brief 人物识别时候，需要 加载模型才能使用
 *@note 只做人物人物聚类无需设置
 *@note 根据识别的人物数目的不同，可以设置不同的模型
 *
 **/
AILAB_EXPORT
int FaceClusting_SetModelFromBuf2(FaceClustingHandle handle, const char* model_buf, const int model_size);

/*
 *@brief 设置参数，默认已经是调好了的，如果需要调整，请联系labcv这边的rd参与
 *
 **/
AILAB_EXPORT
int FaceClusting_SetParam2(FaceClustingHandle handle, FC_ParamType type, float value);

/*
 * @brief 创建句柄
 */

AILAB_EXPORT
int FaceClusting_CreateHandler2(FaceClustingHandle* out);

/*
 *@brief 人脸特征聚类, 分批以减少内存占用, C 接口
 *@param features         人脸特征，大小为 num_samples * FACE_FEATURE_DIM
 *@param num_samples      人脸的数量
 *@param clusters         输出的人脸聚类结果, 长度需要至少为num_samples,
 *每个特征分配一个唯一的聚类id，id相同，表示属于同一个人脸聚类簇
 */
AILAB_EXPORT
int FaceClusting_DoClusteringBatch2(FaceClustingHandle handle,
                                    float* const features,
                                    const int num_samples,
                                    int* clusters);

/*
 *@brief 人脸识别, C 接口
 *@param features         人脸特征，大小为 num_samples * FACE_FEATURE_DIM
 *@param num_samples      人脸的数量
 *@param results          人脸识别结果, 外面需要先分配好空间,长度为num_samples：
 *                            -1  : 非目标识别人物
 *                            其它: 识别的人物ID
 */
AILAB_EXPORT
int FaceClusting_DoRecognition2(FaceClustingHandle handle,
                                float* const features,
                                const int num_samples,
                                int* results);

/*
 *@brief 释放句柄
 *
 */
AILAB_EXPORT
int FaceClusting_ReleaseHandle2(FaceClustingHandle handle);

// clang-format on
#if defined __cplusplus
};
#endif
#endif // LipSegmentationSDK_API_HPP
