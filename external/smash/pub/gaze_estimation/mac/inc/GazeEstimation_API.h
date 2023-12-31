#ifndef _SMASH_GAZEESTIMATIONAPI_H_
#define _SMASH_GAZEESTIMATIONAPI_H_

#include "FaceSDK_API.h"
#include "smash_module_tpl.h"
#include "tt_common.h"
#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

  // clang-format off
typedef void* GazeEstimationHandle;

typedef struct AIGazeInfoBase {
  unsigned long face_id;
  bool valid;
  float head_r[3], head_t[3];
  float leye_pos[3], reye_pos[3];
  float leye_gaze[3], reye_gaze[3], mid_gaze[3];
  float leye_pos2d[2], reye_pos2d[2];
  float leye_gaze2d[2], reye_gaze2d[2]; // 2d point on screen of gaze end point
} AIGazeInfoBase;

/**
 * @brief 模型参数类型
 * kGazeEstimationCameraFov          : 相机Field of View，默认60度
 * kGazeEstimationDivergence           : 双眼视线发散度，设置范围  [-inf, inf]，默认0
 *                                0表示双眼3D视线汇聚一点，由于空间近大远小的关系，此时投影至2D空间中时视线是平行的
 *                                1表示双眼3D视线平行，此时投影至2D空间中时视线是发散的。
 */
typedef enum GazeEstimationParamType {
  kGazeEstimationEdgeMode = 1,
  kGazeEstimationCameraFov,
  kGazeEstimationDivergence
}GazeEstimationParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum GazeEstimationModelType {
  kGazeEstimationModel1 = 1,
} GazeEstimationModelType;


/**
 * @brief 封装预测接口的输入数据
 * ModuleBaseArgs base : 对视频帧数据做了基本的封装
 * AIFaceInfo *faceInfo     : 人脸检测结果
 * float LineLen                 : 视线长度，0为无限长

 */
typedef struct GazeEstimationArgs {
  ModuleBaseArgs base;
  AIFaceInfo *faceInfo;
  float LineLen;
} GazeEstimationArgs;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct GazeEstimationRet {
  AIGazeInfoBase * eye_infos; // eye information, includes eye positions, gaze
  int face_count;
} GazeEstimationRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return GazeEstimation_CreateHandle
 */
AILAB_EXPORT
int GazeEstimation_CreateHandle(GazeEstimationHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return GazeEstimation_LoadModel
 */
AILAB_EXPORT
int GazeEstimation_LoadModel(GazeEstimationHandle handle,
                         GazeEstimationModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return GazeEstimation_LoadModelFromBuff
 */
AILAB_EXPORT
int GazeEstimation_LoadModelFromBuff(GazeEstimationHandle handle,
                                 GazeEstimationModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return GazeEstimation_SetParamF
 */
AILAB_EXPORT
int GazeEstimation_SetParamF(GazeEstimationHandle handle,
                         GazeEstimationParamType type,
                         float value);


/**
 * @brief 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置的参数类型
 * @param value 设置参数的值
 * @return GazeEstimation_SetParamS
 */
AILAB_EXPORT
int GazeEstimation_SetParamS(GazeEstimationHandle handle,
                         GazeEstimationParamType type,
                         char* value);


/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT GazeEstimation_DO
 */
AILAB_EXPORT
int GazeEstimation_DO(GazeEstimationHandle handle,
                  GazeEstimationArgs* args,
                  GazeEstimationRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT GazeEstimation_ReleaseHandle
 */
AILAB_EXPORT
int GazeEstimation_ReleaseHandle(GazeEstimationHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT GazeEstimation_DbgPretty
 */
AILAB_EXPORT
int GazeEstimation_DbgPretty(GazeEstimationHandle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_GAZEESTIMATIONAPI_H_
