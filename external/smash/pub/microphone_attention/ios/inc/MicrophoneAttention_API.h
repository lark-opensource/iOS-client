#ifndef _SMASH_MICROPHONEATTENTIONAPI_H_
#define _SMASH_MICROPHONEATTENTIONAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"
#include "FaceSDK_API.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

#ifdef MODULE_HANDLE
#undef MODULE_HANDLE
#endif
#define MODULE_HANDLE MicrophoneAttentionHandle

typedef void* MODULE_HANDLE;


// 模型参数类型
// TODO: 根据实际情况修改
typedef enum MicrophoneAttentionParamType {
  kMicrophoneAttentionInterval,             //设置检测间隔
} MicrophoneAttentionParamType;

// 模型枚举，有些模块可能有多个模型
// TODO: 根据实际情况更改
typedef enum MicrophoneAttentionModelType {
  kMicrophoneAttentionModel1,
} MicrophoneAttentionModelType;


typedef struct MicrophoneAttentionArgs {
  ModuleBaseArgs base;
  AIFaceInfo * faces;
  // 此处可以添加额外的算法参数
} MicrophoneAttentionArgs;

typedef struct MicrophoneAttentionRet {
  // TODO: 以下换成你自己的算法模块返回内容定义
  unsigned char* alpha;  // alpha[i, j] 表示第 (i, j) 点的 mask 预测值，值位于
                         // [0, 255] 之间
  int width;
  int height;
  float show;
} MicrophoneAttentionRet;

// 创建句柄
AILAB_EXPORT int MicrophoneAttention_CreateHandle(void** out);

// 加载模型（从文件系统中加载）
AILAB_EXPORT int MicrophoneAttention_LoadModel(void* handle,
                                      MicrophoneAttentionModelType type,
                                      const char* model_path);

// 加载模型（从内存中加载，Android 推荐使用该接口）
AILAB_EXPORT int MicrophoneAttention_LoadModelFromBuff(void* handle,
                                              MicrophoneAttentionModelType type,
                                              const char* mem_model,
                                              int model_size);

// 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
// 接口进行更换
AILAB_EXPORT int MicrophoneAttention_SetParamF(void* handle,
                                      MicrophoneAttentionParamType type,
                                      float value);

// 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
// 接口进行更换
AILAB_EXPORT int MicrophoneAttention_SetParamS(void* handle,
                                      MicrophoneAttentionParamType type,
                                      char* value);

// 算法主调用接口
AILAB_EXPORT int MicrophoneAttention_DO(void* handle, MicrophoneAttentionArgs* args, MicrophoneAttentionRet* ret);

// 销毁句柄
AILAB_EXPORT int MicrophoneAttention_ReleaseHandle(void* handle);

// 打印该模块的参数，用于调试
AILAB_EXPORT int MicrophoneAttention_DbgPretty(void* handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

#endif  // _SMASH_MICROPHONEATTENTIONAPI_H_
