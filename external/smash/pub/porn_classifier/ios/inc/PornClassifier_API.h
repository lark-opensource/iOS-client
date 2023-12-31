#ifndef _SMASH_PORNCLASSIFIERAPI_H_
#define _SMASH_PORNCLASSIFIERAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

#ifdef MODULE_HANDLE
#undef MODULE_HANDLE
#endif
#define MODULE_HANDLE PornClassifierHandle

typedef void* MODULE_HANDLE;

typedef enum PornClassifierParamType {
  kConfidenceThreshold,
} PornClassifierParamType;

typedef enum PornClassifierModelType {
  kPornClassifierModel1,
} PornClassifierModelType;

typedef struct PornClassifierArgs {
  ModuleBaseArgs base;
} PornClassifierArgs;

/**
 * Return type
 *  is_porn: whether the input image contains porn content
 *  confidence: how confidence the model predicts the image as porn
 */
typedef struct PornClassifierRet {
  bool is_porn;
  float confidence;
} PornClassifierRet;

// 创建句柄
AILAB_EXPORT int PornClassifier_CreateHandle(void** out);

// 加载模型（从文件系统中加载）
AILAB_EXPORT int PornClassifier_LoadModel(void* handle,
                                          PornClassifierModelType type,
                                          const char* model_path);

// 加载模型（从内存中加载，Android 推荐使用该接口）
AILAB_EXPORT int PornClassifier_LoadModelFromBuff(void* handle,
                                                  PornClassifierModelType type,
                                                  const char* mem_model,
                                                  int model_size);

// 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
// 接口进行更换
AILAB_EXPORT int PornClassifier_SetParamF(void* handle,
                                          PornClassifierParamType type,
                                          float value);

// 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
// 接口进行更换
AILAB_EXPORT int PornClassifier_SetParamS(void* handle,
                                          PornClassifierParamType type,
                                          char* value);

// 算法主调用接口
AILAB_EXPORT int PornClassifier_DO(void* handle,
                                   PornClassifierArgs* args,
                                   PornClassifierRet* ret);

// 销毁句柄
AILAB_EXPORT int PornClassifier_ReleaseHandle(void* handle);

// 打印该模块的参数，用于调试
AILAB_EXPORT int PornClassifier_DbgPretty(void* handle);

#ifdef __cplusplus
}
#endif  // __cplusplus

#endif  // _SMASH_PORNCLASSIFIERAPI_H_
