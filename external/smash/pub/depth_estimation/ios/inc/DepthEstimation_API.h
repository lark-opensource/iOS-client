#ifndef _SMASH_DEPTHESTIMATIONAPI_H_
#define _SMASH_DEPTHESTIMATIONAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

  // clang-format off
typedef void* DepthEstimationHandle;


/**
 * @brief 模型参数类型
 *
 */
typedef enum DepthEstimationParamType{
  kDepthEstimationOpticalFlowWeight = 2,        ///< 是否使用光流平滑后处理阈值
} DepthEstimationParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum DepthEstimationModelType {
  kDepthEstimationModelLite = 1,          ///< 实时深度模型
  kDepthEstimationModelHeavy = 2,          ///< 拍后深度模型
} DepthEstimationModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct DepthEstimationArgs {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
  // 此处可以添加额外的算法参数
} DepthEstimationArgs;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct DepthEstimationRet {
  float* alpha;                ///< alpha[i, j] 表示第 (i, j) 点的 逆深度 预测值
  int width;                   ///< 指定disp的宽度
  int height;                  ///< 指定disp的高度
} DepthEstimationRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return DepthEstimation_CreateHandle
 */
AILAB_EXPORT
int DepthEstimation_CreateHandle(DepthEstimationHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return DepthEstimation_LoadModel
 */
AILAB_EXPORT
int DepthEstimation_LoadModel(DepthEstimationHandle handle,
                         DepthEstimationModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return DepthEstimation_LoadModelFromBuff
 */
AILAB_EXPORT
int DepthEstimation_LoadModelFromBuff(DepthEstimationHandle handle,
                                 DepthEstimationModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return DepthEstimation_SetParamF
 */
AILAB_EXPORT
int DepthEstimation_SetParamF(DepthEstimationHandle handle,
                         DepthEstimationParamType type,
                         float value);



/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT DepthEstimation_DO
 */
AILAB_EXPORT
int DepthEstimation_DO(DepthEstimationHandle handle,
                  DepthEstimationArgs* args,
                  DepthEstimationRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT DepthEstimation_ReleaseHandle
 */
AILAB_EXPORT
int DepthEstimation_ReleaseHandle(DepthEstimationHandle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_DEPTHESTIMATIONAPI_H_
