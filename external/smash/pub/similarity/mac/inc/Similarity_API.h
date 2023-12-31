/**
   picture dedup api.
   1. 对每张图片提取特征
   features = std::vector<Feature>;
   for(img : album){
      Similarity_Feature(handle, args, ret); //提取特征
      features.push_back(fea); //保存提取出的特征
   }
   2. 将相册中所有图片的特征输入，得到聚类结果：
   Similarity_Cluster(handle, args, ret);
*/

#ifndef _SMASH_SIMILARITYAPI_H_
#define _SMASH_SIMILARITYAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

#ifdef MODULE_HANDLE
#undef MODULE_HANDLE
#endif
#define MODULE_HANDLE SimilarityHandle

  typedef void* MODULE_HANDLE;

  /**
   * @brief 模型枚举，有些模块可能有多个模型
   *
   */
  typedef enum SimilarityModelType
  {
    kSimilarityModel1 = 1, ///< TODO: 根据实际情况更改
  } SimilarityModelType;

  // 模型参数类型
  typedef enum SimilarityParamType
  {
    THRES, // 判断图片相似的阈值
  } SimilarityParamType;

  typedef struct Feature
  {
    char* feature_data; //特征的二进制数据
    int feature_len;    //特征的长度
  } Feature;

  // 创建句柄
  AILAB_EXPORT int Similarity_CreateHandle(MODULE_HANDLE* out);

  /**
   * @brief 从文件路径加载模型
   *
   * @param handle 句柄
   * @param type 需要初始化的句柄
   * @param model_path 模型路径
   * @note 模型路径不能为中文、火星文等无法识别的字符
   * @return Similarity_LoadModel
   */
  AILAB_EXPORT
  int Similarity_LoadModel(MODULE_HANDLE handle, SimilarityModelType type, const char* model_path);

  /**
   * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
   *
   * @param handle 句柄
   * @param type 初始化的模型类型
   * @param mem_model 模型文件buf指针
   * @param model_size buf文件的大小
   * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
   * @return Similarity_LoadModelFromBuff
   */
  AILAB_EXPORT
  int Similarity_LoadModelFromBuff(MODULE_HANDLE handle,
                                   SimilarityModelType type,
                                   const char* mem_model,
                                   int model_size);

  // 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
  // 接口进行更换
  AILAB_EXPORT int Similarity_SetParamF(MODULE_HANDLE handle, SimilarityParamType type, float value);

  // 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
  // 接口进行更换
  AILAB_EXPORT int Similarity_SetParamS(MODULE_HANDLE handle, SimilarityParamType type, char* value);

  ///////////////////////////////////////////////////
  ////////////  1. 两张图片的相似度得分
  ///////////////////////////////////////////////////
  // 输入参数
  typedef struct SimilarityArgs
  {
    Feature* fea1;
    Feature* fea2;
  } SimilarityArgs;

  // 返回值
  typedef struct SimilarityRet
  {
    float score; //两张图片的相似度得分
  } SimilarityRet;

  // 算法主调用接口
  AILAB_EXPORT int Similarity_DO(MODULE_HANDLE handle, SimilarityArgs* args, SimilarityRet* ret);

  ///////////////////////////////////////////////////
  ////////////  2. 提取图片特征
  ///////////////////////////////////////////////////
  // 输入参数
  typedef struct SimilarityFeatureArgs
  {
    ModuleBaseArgs img; //待提取特征的图片
  } SimilarityFeatureArgs;

  // 返回值
  typedef struct SimilarityFeatureRet
  {
    // 内存由sdk分配，由调用方释放
    Feature fea; //提取的特征
  } SimilarityFeatureRet;

  // 算法主调用接口
  /**
     args为图片的二进制数据。
     返回ret为图片的二进制特征。
  */
  AILAB_EXPORT int Similarity_Feature(MODULE_HANDLE handle, SimilarityFeatureArgs* args, SimilarityFeatureRet* ret);

  // 释放图片特征的二进制数据内存
  AILAB_EXPORT int Similarity_Feature_Destroy(MODULE_HANDLE handle, SimilarityFeatureRet* ret);

  // 特征解码
  AILAB_EXPORT int Similarity_DecodeFeat(MODULE_HANDLE handle, SimilarityFeatureRet* ret, float** feat);

  ///////////////////////////////////////////////////
  ////////////  3. 对相册中图片进行聚类
  ///////////////////////////////////////////////////
  // 输入参数
  typedef struct SimilarityClusterArgs
  {
    Feature* features; //待去重的图片特征集合
    int n_features;    //待去重的图片数量
  } SimilarityClusterArgs;

  // 返回值
  typedef struct SimilarityClusterRet
  {
    // 内存由sdk分配，由调用方释放
    int* cluster_ids; //长度为n_features,id相同的图片为相似图片
  } SimilarityClusterRet;

  AILAB_EXPORT int Similarity_Cluster(MODULE_HANDLE handle, SimilarityClusterArgs* args, SimilarityClusterRet* ret);

  // 销毁句柄
  AILAB_EXPORT int Similarity_ReleaseHandle(MODULE_HANDLE handle);

  // 打印该模块的参数，用于调试
  AILAB_EXPORT int Similarity_DbgPretty(MODULE_HANDLE handle);

#ifdef __cplusplus
}
#endif // __cplusplus

#endif // _SMASH_SIMILARITYAPI_H_
