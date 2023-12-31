#ifndef _SMASH_BASE_H_
#define _SMASH_BASE_H_

#include "tt_common.h"
/**
 * @brief 基本的模型图像(视频帧)输入数据
 *
 */
typedef struct ModuleBaseArgs {
  const unsigned char* image;      ///< 图像帧数据地址
  PixelFormatType pixel_fmt;       ///< 图像格式
  int image_width;                 ///< 图像的宽度
  int image_height;                ///< 图像的高度
  int image_stride;                ///< 图像的步长(每行的字节数，可能存在padding)
  ScreenOrient orient;             ///< 图像的方向
} ModuleBaseArgs;

#define MODULE_CREATE(ModName) int ModName##_CreateHandle(void** out)

#define MODULE_LOAD_MODEL(ModName, ModelType) \
  int ModName##_LoadModel(void* handle, ModelType type, const char* model_path)

#define MODULE_LOAD_MODEL_FROM_BUF(ModName, ModelType)          \
  int ModName##_LoadModelFromBuff(void* handle, ModelType type, \
                                  const char* mem_model, int model_size)

#define MODULE_SET_PARAM_F(ModName, ParamType) \
  int ModName##_SetParamF(void* handle, ParamType type, float value)

#define MODULE_SET_PARAM_S(ModName, ParamType) \
  int ModName##_SetParamS(void* handle, ParamType type, char* value)

#define MODULE_DO(ModName, Args, Ret) \
  int ModName##_DO(void* handle, Args* args, Ret* ret)

#define MODULE_RELEASE(ModName) int ModName##_ReleaseHandle(void* handle)

#define MODULE_DBG_PRETTY(ModName) int ModName##_DbgPretty(void* handle)

#endif  // _SMASH_BASE_H_
