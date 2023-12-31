#ifndef _SMASH_AIMOMENTAPI_H_
#define _SMASH_AIMOMENTAPI_H_

#include "smash_module_tpl.h"
#include "smash_moment_base.h"
#include "stdbool.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

  // clang-format off
typedef void* AIMomentHandle;

/**
 * @brief 模型参数类型
 *
 */
typedef enum AIMomentParamType {
    kAIMomentParamType1 = 1,
}AIMomentParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum AIMomentModelType {
  kAIMomentModel1 = 1,
}AIMomentModelType;

/**
 *
 */
typedef MomentInfo AIMomentArgs;

/**
 */
typedef struct AIMomentRet {
  AIMoment* moments;
  int numMoments;
}AIMomentRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return AIMoment_CreateHandle
 */
AILAB_EXPORT
int AIMoment_CreateHandle(AIMomentHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return AIMoment_LoadModel
 */
AILAB_EXPORT
int AIMoment_LoadModel(AIMomentHandle handle, AIMomentModelType type, const char* model_path);



/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return AIMoment_LoadModelFromBuff
 */
AILAB_EXPORT
int AIMoment_LoadModelFromBuff(AIMomentHandle handle,
                               AIMomentModelType type,
                               const char* mem_model,
                               int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return AIMoment_SetParamF
 */
AILAB_EXPORT
int AIMoment_SetParamF(AIMomentHandle handle,
                       AIMomentParamType type,
                       float value);



/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return  AIMoment_DO
 */
AILAB_EXPORT
int AIMoment_DO(AIMomentHandle handle,
                AIMomentArgs* args,
                AIMomentRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return  AIMoment_ReleaseHandle
 */
AILAB_EXPORT
int AIMoment_ReleaseHandle(AIMomentHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return  AIMoment_DbgPretty
 */
AILAB_EXPORT
int AIMoment_DbgPretty(AIMomentHandle handle);

/**
 * @brief 释放返回值的内存
 *
 * @param handle
 * @return  AIMoment_ReleaseRet
 */
AILAB_EXPORT
int AIMoment_ReleaseRet(AIMomentHandle handle);

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_AIMOMENTAPI_H_
