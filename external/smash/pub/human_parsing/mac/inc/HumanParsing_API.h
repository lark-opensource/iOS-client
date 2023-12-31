#ifndef _SMASH_HUMANPARSINGAPI_H_
#define _SMASH_HUMANPARSINGAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

#ifdef MODULE_HANDLE
#undef MODULE_HANDLE
#endif
#define MODULE_HANDLE HumanParsingHandle

typedef void* MODULE_HANDLE;

#define HUMANPARSING_INPUTWIDTH 128
#define HUMANPARSING_INPUTHEIGHT 224
#define HUMANPARSING_CATEGORIES 8
#define HUMANPARSING_MAX_SIZE 112
#define HUMANPARSING_IMAGE_MODE 1
#define HUMANPARSING_VIDEO_MODE 2


// 模型参数类型
// TODO: 根据实际情况修改
typedef enum HumanParsingParamType {
    HP_Mode = 4,
    kHumanParsingParam1,
//  kHumanParsingPointsAmount,
//  kHumanParsingFrameRate,
} HumanParsingParamType;

// 模型枚举，有些模块可能有多个模型
// TODO: 根据实际情况更改
typedef enum HumanParsingModelType {
  kHumanParsingModel1,
} HumanParsingModelType;


typedef struct HumanParsingArgs {
  ModuleBaseArgs base;
  // 此处可以添加额外的算法参数
} HumanParsingArgs;

typedef struct HumanParsingRet {
  // TODO: 以下换成你自己的算法模块返回内容定义
  unsigned char* alpha[HUMANPARSING_CATEGORIES];  // alpha[i, j] 表示第 (i, j) 点的 mask 预测值，值位于
  int width; // alpha 宽度 最大为112
  int height; // alpha 高度 最大为112
} HumanParsingRet;

// 创建句柄
AILAB_EXPORT int HumanParsing_CreateHandle(void** out);

// 加载模型（从文件系统中加载）
AILAB_EXPORT int HumanParsing_LoadModel(void* handle,
                                      HumanParsingModelType type,
                                      const char* model_path);

// 加载模型（从内存中加载，Android 推荐使用该接口）
AILAB_EXPORT int HumanParsing_LoadModelFromBuff(void* handle,
                                              HumanParsingModelType type,
                                              const char* mem_model,
                                              int model_size);

// 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
// 接口进行更换
AILAB_EXPORT int HumanParsing_SetParamF(void* handle,
                                      HumanParsingParamType type,
                                      float value);

// 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
// 接口进行更换
AILAB_EXPORT int HumanParsing_SetParamS(void* handle,
                                      HumanParsingParamType type,
                                      char* value);

// 算法主调用接口
AILAB_EXPORT int HumanParsing_DO(void* handle, HumanParsingArgs* args, HumanParsingRet* ret);

// 销毁句柄
AILAB_EXPORT int HumanParsing_ReleaseHandle(void* handle);

// 打印该模块的参数，用于调试
AILAB_EXPORT int HumanParsing_DbgPretty(void* handle);

// 内存申请
AILAB_EXPORT HumanParsingRet* HumanParsing_MallocResultMemory(void* handle);

// 内存释放
AILAB_EXPORT int HumanParsing_FreeResultMemory(HumanParsingRet* res);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

#endif  // _SMASH_HUMANPARSINGAPI_H_
