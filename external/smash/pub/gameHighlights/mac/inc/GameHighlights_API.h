#ifndef _SMASH_GAMEHIGHLIGHTSAPI_H_
#define _SMASH_GAMEHIGHLIGHTSAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

#ifdef MODULE_HANDLE
#undef MODULE_HANDLE
#endif
#define MODULE_HANDLE GameHLHandle

typedef void* MODULE_HANDLE;

// 模型参数类型
// TODO: 根据实际情况修改
typedef enum GameHLParamType {
  SRC_IMG_WIDTH,    //源图片分辨率(宽度)
  SRC_IMG_HEIGHT,   //源图片分辨率(高度)
  PATT_IMG_WIDTH,   //模版图片分辨率(宽度)
  PATT_IMG_HEIGHT,  //模版图片分辨率(高度)
  TM_MTD,           //模版匹配的方法
} GameHLParamType;

// 模型枚举，有些模块可能有多个模型
typedef enum GameHLModelType {
  kGameHighlightsModel1,
} GameHLModelType;

// 输入参数
typedef struct GameHLArgs {
  ModuleBaseArgs base;  // 输入的源图片
} GameHLArgs;

// 模块返回值
typedef struct GameHLRet {
  int flag;  // 1 为高光，0为非高光
} GameHLRet;

// 创建句柄
AILAB_EXPORT int GameHL_CreateHandle(MODULE_HANDLE* out);

AILAB_EXPORT int GameHL_LoadModel(MODULE_HANDLE handle,
                                  GameHLModelType type,
                                  const char* model_path);

// 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
// 接口进行更换
AILAB_EXPORT int GameHL_SetParamF(MODULE_HANDLE handle,
                                  GameHLParamType type,
                                  float value);

// 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
// 接口进行更换
AILAB_EXPORT int GameHL_SetParamS(MODULE_HANDLE handle,
                                  GameHLParamType type,
                                  char* value);

// 算法主调用接口
// 根据输入图片和模版，判断是否为高光
AILAB_EXPORT int GameHL_Predict(MODULE_HANDLE handle,
                                GameHLArgs* args,
                                GameHLRet* ret);

// 销毁句柄
AILAB_EXPORT int GameHL_ReleaseHandle(MODULE_HANDLE handle);

// 打印该模块的参数，用于调试
AILAB_EXPORT int GameHL_DbgPretty(MODULE_HANDLE handle);

#ifdef __cplusplus
}
#endif  // __cplusplus

#endif  // _SMASH_GAMEHIGHLIGHTSAPI_H_
