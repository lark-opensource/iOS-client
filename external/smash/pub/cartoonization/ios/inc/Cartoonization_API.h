#ifndef _SMASH_CARTOONIZATIONAPI_H_
#define _SMASH_CARTOONIZATIONAPI_H_

// #include <mobilecv2/core.hpp>
#include "smash_module_tpl.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

#ifdef MODULE_HANDLE
#undef MODULE_HANDLE
#endif
#define MODULE_HANDLE CartoonizationHandle

typedef void* MODULE_HANDLE;

typedef enum CartoonizationParamType {
  kCartoonizationEdgeMode,
} CartoonizationParamType;

typedef enum CartoonizationModelType {
  kCartoonizationModel1,
} CartoonizationModelType;

typedef struct CartoonizationArgs {
  ModuleBaseArgs base;
  // 此处可以添加额外的算法参数
} CartoonizationArgs;

typedef struct CartoonizationRet {
  // 以下换成你自己的算法模块返回内容定义
  unsigned char* image_buffer;
  int width;
  int height;
  int image_stride;
  PixelFormatType output_pixel_fmt;
} CartoonizationRet;

// 创建句柄
AILAB_EXPORT int Cartoonization_CreateHandle(void** out);

// 加载模型（从文件系统中加载）
AILAB_EXPORT int Cartoonization_LoadModel(void* handle,
                                          CartoonizationModelType type,
                                          const char* model_path);

// 加载模型（从内存中加载，Android 推荐使用该接口）
AILAB_EXPORT int Cartoonization_LoadModelFromBuff(void* handle,
                                                  CartoonizationModelType type,
                                                  const char* mem_model,
                                                  int model_size);

// 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
// 接口进行更换
AILAB_EXPORT int Cartoonization_SetParamF(void* handle,
                                          CartoonizationParamType type,
                                          float value);

// 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
// 接口进行更换
AILAB_EXPORT int Cartoonization_SetParamS(void* handle,
                                          CartoonizationParamType type,
                                          char* value);

// 算法主调用接口
AILAB_EXPORT int Cartoonization_DO(void* handle,
                                   CartoonizationArgs* args,
                                   CartoonizationRet* ret);

// 销毁句柄
AILAB_EXPORT int Cartoonization_ReleaseHandle(void* handle);

// 打印该模块的参数，用于调试
AILAB_EXPORT int Cartoonization_DbgPretty(void* handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

#endif  // _SMASH_CARTOONIZATIONAPI_H_
