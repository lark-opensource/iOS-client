#ifndef _SMASH_FACELIGHTAPI_H_
#define _SMASH_FACELIGHTAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"
// #include "FaceSDK_API.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

// clang-format off
typedef void* FaceLightHandle;
// #define AI_FACE_LIGHT_MAX_FACE_NUM AI_MAX_FACE_NUM // 支持的最大人脸数
#define AI_FACE_LIGHT_MAX_FACE_NUM 10 // 支持的最大人脸数
#define AI_FACE_LIGHT_SH_VALUE_NUM 27 // 球谐光权重个数
#define AI_FACE_LIGHT_FACE_KEYPOINT_NUM 106 //人脸检测使用的关键点个数

/**
 * @brief 模型参数类型
 *
 */
typedef enum FaceLightParamType {
  kFaceLightFilterWeight = 1,        // 时序滤波的参数。值从0～1.0. 越大越稳定。
  kFaceLightDefaultValue0 = 2,      // default value for sh light. We output this once face is out of the image.
  kFaceLightDefaultValue1 = 3,
  kFaceLightDefaultValue2 = 4,
  kFaceLightDefaultValue3 = 5,
  kFaceLightDefaultValue4 = 6,
  kFaceLightDefaultValue5 = 7,
  kFaceLightDefaultValue6 = 8,
  kFaceLightDefaultValue7 = 9,
  kFaceLightDefaultValue8 = 10,
  kFaceLightDefaultValue9 = 11,
  kFaceLightDefaultValue10 = 12,
  kFaceLightDefaultValue11 = 13,
  kFaceLightDefaultValue12 = 14,
  kFaceLightDefaultValue13 = 15,
  kFaceLightDefaultValue14 = 16,
  kFaceLightDefaultValue15 = 17,
  kFaceLightDefaultValue16 = 18,
  kFaceLightDefaultValue17 = 19,
  kFaceLightDefaultValue18 = 20,
  kFaceLightDefaultValue19 = 21,
  kFaceLightDefaultValue20 = 22,
  kFaceLightDefaultValue21 = 23,
  kFaceLightDefaultValue22 = 24,
  kFaceLightDefaultValue23 = 25,
  kFaceLightDefaultValue24 = 26,
  kFaceLightDefaultValue25 = 27,
  kFaceLightDefaultValue26 = 28
} FaceLightParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum FaceLightModelType {
  kFaceLightModel1 = 1,          // 小模型
} FaceLightModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct FaceLightArgs {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
  int face_count;                 //人脸个数
  int face_id[AI_FACE_LIGHT_MAX_FACE_NUM];
  AIPoint face_points[AI_FACE_LIGHT_MAX_FACE_NUM][AI_FACE_LIGHT_FACE_KEYPOINT_NUM];
  // 此处可以添加额外的算法参数
} FaceLightArgs;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct FaceLightRet {
  int face_id[AI_FACE_LIGHT_MAX_FACE_NUM];
  bool has_lighting[AI_FACE_LIGHT_MAX_FACE_NUM];
  float SH_lighting_RGB[AI_FACE_LIGHT_MAX_FACE_NUM][AI_FACE_LIGHT_SH_VALUE_NUM];
}FaceLightRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return FaceLight_CreateHandle
 */
AILAB_EXPORT
int FaceLight_CreateHandle(FaceLightHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return FaceLight_LoadModel
 */
AILAB_EXPORT
int FaceLight_LoadModel(FaceLightHandle handle,
                         FaceLightModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return FaceLight_LoadModelFromBuff
 */
AILAB_EXPORT
int FaceLight_LoadModelFromBuff(FaceLightHandle handle,
                                 FaceLightModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return FaceLight_SetParamF
 */
AILAB_EXPORT
int FaceLight_SetParamF(FaceLightHandle handle,
                         FaceLightParamType type,
                         float value);



/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT FaceLight_DO
 */
AILAB_EXPORT
int FaceLight_DO(FaceLightHandle handle,
                  FaceLightArgs* args,
                  FaceLightRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT FaceLight_ReleaseHandle
 */
AILAB_EXPORT
int FaceLight_ReleaseHandle(FaceLightHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT FaceLight_DbgPretty
 */
AILAB_EXPORT
int FaceLight_DbgPretty(FaceLightHandle handle);


#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_FACELIGHTAPI_H_
