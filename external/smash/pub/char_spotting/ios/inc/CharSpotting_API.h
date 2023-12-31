#ifndef _SMASH_CHARSPOTTINGAPI_H_
#define _SMASH_CHARSPOTTINGAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

#ifdef MODULE_HANDLE
#undef MODULE_HANDLE
#endif
#define MODULE_HANDLE CharSpottingHandle

typedef void* MODULE_HANDLE;

// CharSpottingRecommendConfig 为算法推荐配置的算法参数，如CNN网络输入大小
// TODO: 根据实际情况修改
typedef struct CharSpottingRecommendConfig {
  int InputWidth;
  int InputHeight;
}CharSpottingRecommendConfig;

// 模型参数类型
// TODO: 根据实际情况修改
typedef enum CharSpottingParamType {
  kCharSpottingDetInputWidth,
  kCharSpottingDetInputHeight,
  kCharSpottingDetRoiWidthScale,
  kCharSpottingDetRoiHeightScale,
  kCharSpottingProtInputWidth,
  kCharSpottingProtInputHeight,
  kCharSpottingProtRoiWidth,
  kCharSpottingProtRoiHeight,
  kCharSpottingDetRoiWidthUnit,
  kCharSpottingMaxCandNum,
  kCharSpottingRelocate
}CharSpottingParamType;

// 模型枚举，有些模块可能有多个模型
// TODO: 根据实际情况更改
typedef enum CharSpottingModelType {
  kCharSpottingModel1,
}CharSpottingModelType;


typedef struct CharSpottingArgs {
  ModuleBaseArgs base;
  // 此处可以添加额外的算法参数
  float point_x;
  float point_y;
  float angle;
}CharSpottingArgs;

typedef struct CharSpottingStatus {
  unsigned char* alpha;  // image data base
  int width;
  int height;
  int draw_local;
}CharSpottingStatus;
  
typedef struct CharSpottingRet {
  int cand_box_num;  //total number of candidate boxes
  float* cand_box_xy_score; //xy and score of candidate boxes, ordered as x0, y0, x1, y1, x2, y2, x3, y3, score ...
  int first_index; //the first choice index
}CharSpottingRet;

// 创建句柄
AILAB_EXPORT int CharSpotting_CreateHandle(void** out);

// 加载模型（从文件系统中加载）
AILAB_EXPORT int CharSpotting_LoadModel(void* handle,
                                      CharSpottingModelType type,
                                      const char* model_path);

// 加载模型（从内存中加载，Android 推荐使用该接口）
AILAB_EXPORT int CharSpotting_LoadModelFromBuff(void* handle,
                                              CharSpottingModelType type,
                                              const char* mem_model,
                                              int model_size);

// 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
// 接口进行更换
AILAB_EXPORT int CharSpotting_SetParamF(void* handle,
                                      CharSpottingParamType type,
                                      float value);

// 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
// 接口进行更换
AILAB_EXPORT int CharSpotting_SetParamS(void* handle,
                                      CharSpottingParamType type,
                                      char* value);

// 算法主调用接口
AILAB_EXPORT int CharSpotting_DO(void* handle, CharSpottingArgs* args, CharSpottingRet* ret);
  
AILAB_EXPORT int CharSpotting_SHOW(void* handle, CharSpottingStatus* stat);

// 销毁句柄
AILAB_EXPORT int CharSpotting_ReleaseHandle(void* handle);

// 打印该模块的参数，用于调试
AILAB_EXPORT int CharSpotting_DbgPretty(void* handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

#endif  // _SMASH_CHARSPOTTINGAPI_H_
