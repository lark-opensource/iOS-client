#ifndef _SMASH_FOODFINECLSAPI_H_
#define _SMASH_FOODFINECLSAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

#ifdef MODULE_HANDLE
#undef MODULE_HANDLE
#endif
#define MODULE_HANDLE FoodFineClsHandle

#define NUM_FOOD_CLASSES 11
typedef void* MODULE_HANDLE;

typedef enum {
  Food_Coffe = 0,
  Food_Wine,        //酒
  Food_Drink,       //饮料
  Food_Fruit,       //水果
  Food_Vegetables,  //蔬菜
  Food_Grill,       // 烤肉
  Food_Hotpot,      //火锅
  Food_Sushi,       //日料
  Food_Aff,         // Americal_Fast_Food, 美式快餐
  Food_Snacks,      //零食
  Food_Other
} FineFoodType;

static float FineFoodProbThreshold[NUM_FOOD_CLASSES] = {
    0.65,  // Coffe
    0.65,  // Wine
    0.65,  // Drink
    0.65,  // Fruit
    0.65,  // Vegetables
    0.65,  // Grill
    0.65,  // Hotpot
    0.65,  // Sushi
    0.65,  // Aff
    0.65,  // Snacks
    0.98   // Other
};

static float FineFoodProbHigherThreshold[NUM_FOOD_CLASSES] = {
    0.7,  // Coffe
    0.7,  // Wine
    0.7,  // Drink
    0.7,  // Fruit
    0.7,  // Vegetables
    0.7,  // Grill
    0.7,  // Hotpot
    0.7,  // Sushi
    0.7,  // Aff
    0.7,  // Snacks
    0.98  // Other
};

typedef struct FineFoodCategoryItem {
  float prob;
  bool satisfied;
} FineFoodCategoryItem;

// 模型参数类型
// TODO: 根据实际情况修改
typedef enum FoodFineClsParamType {
  kFoodFineClsEdgeMode,
} FoodFineClsParamType;

// 模型枚举，有些模块可能有多个模型
// TODO: 根据实际情况更改
typedef enum FoodFineClsModelType {
  kFoodFineClsModel1,
} FoodFineClsModelType;

typedef struct FoodFineClsArgs {
  ModuleBaseArgs base;
  // 此处可以添加额外的算法参数
} FoodFineClsArgs;

typedef struct FoodFineClsRet {
  // TODO: 以下换成你自己的算法模块返回内容定义
  FineFoodCategoryItem items[NUM_FOOD_CLASSES];
}FoodFineClsRet;

// 创建句柄
AILAB_EXPORT int FoodFineCls_CreateHandle(void** out);

// 加载模型（从文件系统中加载）
AILAB_EXPORT int FoodFineCls_LoadModel(void* handle,
                                       FoodFineClsModelType type,
                                       const char* model_path);

// 加载模型（从内存中加载，Android 推荐使用该接口）
AILAB_EXPORT int FoodFineCls_LoadModelFromBuff(void* handle,
                                               FoodFineClsModelType type,
                                               const char* mem_model,
                                               int model_size);

AILAB_EXPORT int FoodFineCls_SetParamF(void* handle,
                                       FoodFineClsParamType type,
                                       float value);

AILAB_EXPORT int FoodFineCls_SetParamS(void* handle,
                                       FoodFineClsParamType type,
                                       char* value);

// 算法主调用接口
AILAB_EXPORT int FoodFineCls_DO(void* handle,
                                FoodFineClsArgs* args,
                                FoodFineClsRet* ret);

// 销毁句柄
AILAB_EXPORT int FoodFineCls_ReleaseHandle(void* handle);

// 打印该模块的参数，用于调试
AILAB_EXPORT int FoodFineCls_DbgPretty(void* handle);

#ifdef __cplusplus
}
#endif  // __cplusplus

#endif  // _SMASH_FOODFINECLSAPI_H_
