#ifndef _SMASH_CLOTHESSEGAPI_H_
#define _SMASH_CLOTHESSEGAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

#ifdef MODULE_HANDLE
#undef MODULE_HANDLE
#endif
#define MODULE_HANDLE ClothesSegHandle

typedef void* MODULE_HANDLE;

#define CLOTHESSEG_INPUTWIDTH 128
#define CLOTHESSEG_INPUTHEIGHT 224
// 模型参数类型
// TODO: 根据实际情况修改
typedef enum ClothesSegParamType {
  kClothesSegPointsAmount,
    kClothesSegFrameRate,
} ClothesSegParamType;

// 模型枚举，有些模块可能有多个模型
// TODO: 根据实际情况更改
typedef enum ClothesSegModelType {
  kClothesSegModel1,
} ClothesSegModelType;


typedef struct ClothesSegArgs {
  ModuleBaseArgs base;
  //  int frame_rate;        //[1,5],数值越大，点运动的速度越慢
  //  int points_amount;    //[1,10],数值越大，点越密集
  // 此处可以添加额外的算法参数
} ClothesSegArgs;

typedef struct ClothesSegRet {
  // TODO: 以下换成你自己的算法模块返回内容定义
  unsigned char* alpha;  // alpha[i, j] 表示第 (i, j) 点的 mask 预测值，值位于
                         // [0, 255] 之间
  int width; // alpha 宽度 最大为224
  int height; // alpha 高度 最大为224
  float x_shift; // 水平方向 偏移量 [0, 1] 之间
  float y_shift; // 垂直方向 偏移量 [0, 1] 之间
  AIRect rect; // alpha大于128部分的 外接矩形框 left right范围 [0, width-1], y范围 [0, height - 1]
} ClothesSegRet;

// 创建句柄
AILAB_EXPORT int ClothesSeg_CreateHandle(void** out);

// 加载模型（从文件系统中加载）
AILAB_EXPORT int ClothesSeg_LoadModel(void* handle,
                                      ClothesSegModelType type,
                                      const char* model_path);

// 加载模型（从内存中加载，Android 推荐使用该接口）
AILAB_EXPORT int ClothesSeg_LoadModelFromBuff(void* handle,
                                              ClothesSegModelType type,
                                              const char* mem_model,
                                              int model_size);

// 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
// 接口进行更换
AILAB_EXPORT int ClothesSeg_SetParamF(void* handle,
                                      ClothesSegParamType type,
                                      float value);

// 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
// 接口进行更换
AILAB_EXPORT int ClothesSeg_SetParamS(void* handle,
                                      ClothesSegParamType type,
                                      char* value);

// 算法主调用接口
AILAB_EXPORT int ClothesSeg_DO(void* handle, ClothesSegArgs* args, ClothesSegRet* ret);

// 销毁句柄
AILAB_EXPORT int ClothesSeg_ReleaseHandle(void* handle);

// 打印该模块的参数，用于调试
AILAB_EXPORT int ClothesSeg_DbgPretty(void* handle);

// 内存申请
AILAB_EXPORT ClothesSegRet* ClothesSeg_MallocResultMemory(void* handle);

// 内存释放
AILAB_EXPORT int ClothesSeg_FreeResultMemory(ClothesSegRet* res);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

#endif  // _SMASH_CLOTHESSEGAPI_H_
