#ifndef _SMASH_FACEMASK_API_H_
#define _SMASH_FACEMASK_API_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

#ifdef MODULE_HANDLE
#undef MODULE_HANDLE
#endif
#define MODULE_HANDLE FaceMaskHandle

typedef void* MODULE_HANDLE;

#define FM_FACE_KEY_POINT_NUM 106
#define FM_MAX_FACE_NUM 10
#define FM_MASK_KPTS_NUM 9
#define FM_MAX_MASK_NUM 1
// #define FM_2DTO3D_FACE_KPTS_NUM 28
// #define FM_2DTO3D_KPTS_NUM (FM_2DTO3D_FACE_KPTS_NUM + FM_MASK_KPTS_NUM)
// 模型参数类型
// TODO: 根据实际情况修改
typedef enum FaceMaskParamType {
  kFaceMaskPointsAmount,
    kFaceMaskFrameRate,
} FaceMaskParamType;

// 模型枚举，有些模块可能有多个模型
// TODO: 根据实际情况更改
typedef enum FaceMaskModelType {
  kFaceMaskModel1,
} FaceMaskModelType;

typedef struct FaceMaskArgs {
  ModuleBaseArgs base;
  AIPoint face_array[FM_MAX_FACE_NUM][FM_FACE_KEY_POINT_NUM];
  // AIRect face_bbox[FM_MAX_FACE_NUM];
  int face_count; // 人脸模块返回的人脸个数
  int face_image_width; // 人脸模块点坐标x最大值
  int face_image_height; // 人脸模块点坐标y最大值
  float yaw[FM_MAX_FACE_NUM];
  // 此处可以添加额外的算法参数
} FaceMaskArgs;

typedef struct FaceMaskRet {
  // TODO: 以下换成你自己的算法模块返回内容定义
  unsigned char* alpha;  // alpha[i, j] 表示第 (i, j) 点的 mask 预测值，值位于0-255之间
  AIRect bboxes[FM_MAX_MASK_NUM]; // 戴口罩人脸的人脸框
  AIKeypoint kpts[FM_MAX_MASK_NUM][FM_MASK_KPTS_NUM];
  int mask_count; // 口罩个数 不超过 FM_MAX_MASK_NUM
  int width; // alpha 宽度 最大为112
  int height; // alpha 高度 最大为112
} FaceMaskRet;

// 创建句柄
AILAB_EXPORT int FaceMask_CreateHandle(void** out);

// 加载模型（从文件系统中加载）
AILAB_EXPORT int FaceMask_LoadModel(void* handle,
                                      FaceMaskModelType type,
                                      const char* model_path);

// 加载模型（从内存中加载，Android 推荐使用该接口）
AILAB_EXPORT int FaceMask_LoadModelFromBuff(void* handle,
                                              FaceMaskModelType type,
                                              const char* mem_model,
                                              int model_size);

// 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
// 接口进行更换
AILAB_EXPORT int FaceMask_SetParamF(void* handle,
                                      FaceMaskParamType type,
                                      float value);

// 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
// 接口进行更换
AILAB_EXPORT int FaceMask_SetParamS(void* handle,
                                      FaceMaskParamType type,
                                      char* value);

// 算法主调用接口
AILAB_EXPORT int FaceMask_DO(void* handle, FaceMaskArgs* args, FaceMaskRet* ret);

// 销毁句柄
AILAB_EXPORT int FaceMask_ReleaseHandle(void* handle);

// 打印该模块的参数，用于调试
AILAB_EXPORT int FaceMask_DbgPretty(void* handle);

// 内存申请
AILAB_EXPORT FaceMaskRet* FaceMask_MallocResultMemory(void* handle);

// 内存释放
AILAB_EXPORT int FaceMask_FreeResultMemory(FaceMaskRet* res);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

#endif  // _SMASH_HUMANPARSINGAPI_H_
