#ifndef _SMASH_CARLANDMARKSAPI_H_
#define _SMASH_CARLANDMARKSAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

#ifdef MODULE_HANDLE
#undef MODULE_HANDLE
#endif
#define MODULE_HANDLE CarLandmarksHandle
	
#define AI_MAX_BRAND_NUM 10

typedef void* MODULE_HANDLE;

typedef struct AILAB_EXPORT AIBrandInfoBase{
	AIPoint points_array[4];   //车牌关键点数组
	int brand_id;   //车牌id
}AIBrandInfoBase;

// CarLandmarksRecommendConfig 为算法推荐配置的算法参数，如CNN网络输入大小
struct CarLandmarksRecommendConfig {
  int InputWidth = 200;
  int InputHeight = 200;
};

// 模型参数类型
enum CarLandmarksParamType {
  kCarLandmarksScopeMode,    //检测距离*2，1表示开启，默认关闭，对应kCarLandmarksPatchSize = 350
	kCarLandmarksTeleScopeMode,  //检测距离*6，1表示开启，默认关闭，对应kCarLandmarksPatchSize = 250
	kCarLandmarksPatchSize,   //高端机推荐250-400，参数越小表示检测的更精细，检测距离也就越远，低端机建议不设置这里的三项参数。
														//检测距离计算方法：round(image_width/patchSize) * round(image_height/patchSize)
};

// 模型枚举，有些模块可能有多个模型
enum CarLandmarksModelType {
  kCarLandmarksModel1,
};

struct CarLandmarksArgs {
  ModuleBaseArgs base;
};

struct CarLandmarksRet {
	AIBrandInfoBase base_infos[AI_MAX_BRAND_NUM];    //检测到的车牌信息，包括关键点、id
	int brand_count = 0;   //检测到的车牌数量
};

// 创建句柄
AILAB_EXPORT int CarLandmarks_CreateHandle(void** out);

// 加载模型（从文件系统中加载）
AILAB_EXPORT int CarLandmarks_LoadModel(void* handle,
                                      CarLandmarksModelType type,
                                      const char* model_path);

// 加载模型（从内存中加载，Android 推荐使用该接口）
AILAB_EXPORT int CarLandmarks_LoadModelFromBuff(void* handle,
                                              CarLandmarksModelType type,
                                              const unsigned char* mem_model,
                                              int model_size);

// 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
// 接口进行更换
AILAB_EXPORT int CarLandmarks_SetParamF(void* handle,
                                      CarLandmarksParamType type,
                                      float value);

// 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
// 接口进行更换
AILAB_EXPORT int CarLandmarks_SetParamS(void* handle,
                                      CarLandmarksParamType type,
                                      char* value);

// 算法主调用接口
AILAB_EXPORT int CarLandmarks_DO(void* handle, CarLandmarksArgs* args, CarLandmarksRet* ret);

// 销毁句柄
AILAB_EXPORT int CarLandmarks_ReleaseHandle(void* handle);

// 打印该模块的参数，用于调试
AILAB_EXPORT int CarLandmarks_DbgPretty(void* handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

#endif  // _SMASH_CARLANDMARKSAPI_H_
