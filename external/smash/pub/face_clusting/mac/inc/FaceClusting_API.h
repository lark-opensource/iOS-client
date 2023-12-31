#ifndef FaceClusting_API_H
#define FaceClusting_API_H
#include "FaceClusting_Define.h"
#include "tt_common.h"
#include <map>
#include <vector>

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
int FaceClusting_SetModel(FaceClustingHandle handle, const char* model_path);

/*
 *@brief 人物识别时候，需要 加载模型才能使用
 *@note 只做人物人物聚类无需设置
 *@note 根据识别的人物数目的不同，可以设置不同的模型
 *
 **/
AILAB_EXPORT
int FaceClusting_SetModelFromBuf(FaceClustingHandle handle, const char* model_buf, const int model_size);

/*
 *@brief 设置参数，默认已经是调好了的，如果需要调整，请联系labcv这边的rd参与
 *
 **/
AILAB_EXPORT
int FaceClusting_SetParamF(FaceClustingHandle handle, FC_ParamType type, float value);

/*
 * @brief 创建句柄
 */

AILAB_EXPORT
int FaceClusting_CreateHandler(FaceClustingHandle* out);

/*
 *@brief 人脸特征聚类
 *@param features         人脸特征，大小为 num_samples * FACE_FEATURE_DIM
 *@param num_samples      人脸的数量
 *@param clusters         输出的人脸聚类结果
 */
AILAB_EXPORT
int FaceClusting_DoClustering(FaceClustingHandle handle,
                              float* const features,
                              const int num_samples,
                              std::vector<std::vector<int>>& clusters);

/*
 *@brief 人脸特征聚类, 分批以减少内存占用
 *@param features         人脸特征，大小为 num_samples * FACE_FEATURE_DIM
 *@param num_samples      人脸的数量
 *@param clusters         输出的人脸聚类结果
 */
AILAB_EXPORT
int FaceClusting_DoClusteringBatch(FaceClustingHandle handle,
                                   float* const features,
                                   const int num_samples,
                                   std::vector<std::vector<int>>& clusters);

/*
 *@brief 增量人脸特征聚类
 *@param old_features          旧人脸特征，大小为 old_num_smaples *
 *FACE_FEATURE_DIM
 *@param old_num_smaples       旧人脸的数量
 *@param old_clusters 旧人脸聚类，key为聚类id，value为old_features的索引
 *@param new_features          新增人脸特征，大小为 new_num_samples *
 *FACE_FEATURE_DIM
 *@param new_num_samples       新增人脸数量
 *@param incremental_clusters
 *输出的人脸聚类结果，key为聚类id，value为new_features的索引
 *
 *@note 这是增量的结果，与old_clusters合并之后才是全量的结果
 */
AILAB_EXPORT
int FaceClusting_DoIncrementallyClusting(FaceClustingHandle handle,
                                         const float* old_features,
                                         const int old_num_smaples,
                                         const std::map<int, std::vector<int>>& old_clusters,
                                         const float* new_features,
                                         const int new_num_samples,
                                         std::map<int, std::vector<int>>& incremental_clusters);

/*
 *@brief 人脸识别
 *@param features         人脸特征，大小为 num_samples * FACE_FEATURE_DIM
 *@param num_samples      人脸的数量
 *@param results          人脸识别结果：
 *                            -1  : 非目标识别人物
 *                            其它: 识别的人物ID
 */
AILAB_EXPORT
int FaceClusting_DoRecognition(FaceClustingHandle handle,
                               float* const features,
                               const int num_samples,
                               std::vector<int>& results);

/*
 *@brief 释放句柄
 *
 */
AILAB_EXPORT
int FaceClusting_ReleaseHandle(FaceClustingHandle handle);

// clang-format on
#if defined __cplusplus
};
#endif
#endif // LipSegmentationSDK_API_HPP
