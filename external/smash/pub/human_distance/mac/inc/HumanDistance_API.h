#ifndef _SMASH_HUMANDISTANCEAPI_H_
#define _SMASH_HUMANDISTANCEAPI_H_

#include "AttrSDK_API.h"
#include "FaceSDK_API.h"
#include "smash_module_tpl.h"
#include "tt_common.h"
#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

#ifdef MODULE_HANDLE
#undef MODULE_HANDLE
#endif
#define MODULE_HANDLE HumanDistanceHandle

//***************************** begin Create-Config *****************/
typedef void* MODULE_HANDLE;
// 创建句柄
AILAB_EXPORT int HumanDistance_CreateHandle(void** out);
// pre defined a float vector for extra params
#define AI_HUMAN_DISTANCE_EXTRA_PARAM 100

// 模型参数类型
typedef enum HumanDistanceModelType {
  kHumanDistanceModel1 = 1,
}HumanDistanceModelType;
// 算法参数，相机FOV
typedef enum HumanDistanceParamType {
  kHumanDistanceEdgeMode,
  kHumanDistanceCameraFov,
}HumanDistanceParamType;

//***************************** begin Create-input parameters *****************/
// 算法参数
// 相机内参仅需要一个，其输入的优先等级依次为: params, fov, devicename
typedef struct HumanDistanceArgs {
  ModuleBaseArgs base;  // 输入图像，包含图像数据，尺寸，通道数
  AIFaceInfo* faceInfo;  // 输入多人脸关键点检测结果
  AttrResult* attrInfo;  // 输入多人脸属性检测结果
  float params[AI_HUMAN_DISTANCE_EXTRA_PARAM];  // 其他输入参数，包括相机畸变参数(k_1, k_2, p_1, p_2[, k_3[,
                  // k_4, k_5, k_6]])等
  float fov;      // 相机 field of view
  char* devicename;   // 设备名称
  bool isFront;       // 前置或后置摄像头
//  HumanDistanceArgs(void){
//    for(int i = 0; i< AI_HUMAN_DISTANCE_EXTRA_PARAM; i++){
//      params[i] = 0;
//    }
//    fov = -1;
//    isFront = true;
//    devicename=nullptr;
//  };
}HumanDistanceArgs;

//***************************** begin define return parameters
//*****************/
typedef struct HumanDistanceRet {
  float dists[AI_MAX_FACE_NUM];  // 对应于每个人脸相对于相机的距离
  int facecount;                 // 记录人脸个数
} HumanDistanceRet;

//***************************** begin define function socket *****************/
// 加载模型（从文件系统中加载）
AILAB_EXPORT int HumanDistance_LoadModel(void* handle,
                                         HumanDistanceModelType type,
                                         const char* model_path);

// 加载模型（从内存中加载，Android 推荐使用该接口）
AILAB_EXPORT int HumanDistance_LoadModelFromBuff(void* handle,
                                                 HumanDistanceModelType type,
                                                 const char* mem_model,
                                                 int model_size);

// 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
// 接口进行更换
AILAB_EXPORT int HumanDistance_SetParamF(void* handle,
                                         HumanDistanceParamType type,
                                         float value);

// 算法主调用接口
AILAB_EXPORT int HumanDistance_DO(void* handle,
                                  HumanDistanceArgs* args,
                                  HumanDistanceRet* ret);

// 销毁句柄
AILAB_EXPORT int HumanDistance_ReleaseHandle(void* handle);

// 打印该模块的参数，用于调试
AILAB_EXPORT int HumanDistance_DbgPretty(void* handle);

#ifdef __cplusplus
}
#endif  // __cplusplus

#endif  // _SMASH_HUMANDISTANCEAPI_H_
