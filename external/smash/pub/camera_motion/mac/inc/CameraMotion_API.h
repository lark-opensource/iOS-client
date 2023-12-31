#ifndef _SMASH_CAMERAMOTIONAPI_H_
#define _SMASH_CAMERAMOTIONAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

  // clang-format off
typedef void* CameraMotionHandle;


/**
 * @brief 模型参数类型
 *
 */
typedef enum CameraMotionParamType {
  kCameraMotionWorkSize = 1,        /// 图像长边，默认360
} CameraMotionParamType;



/**
 * @brief 封装预测接口的输入数据
 *
 */
typedef struct CameraMotionArgs {
  ModuleBaseArgs base;
} CameraMotionArgs;


/**
 * @brief 封装预测接口的返回值
 *
 */
typedef struct CameraMotionRet {
  float motion_value;
} CameraMotionRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return CameraMotion_CreateHandle
 */
AILAB_EXPORT
int CameraMotion_CreateHandle(CameraMotionHandle* out);



/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return CameraMotion_SetParamF
 */
AILAB_EXPORT
int CameraMotion_SetParamF(CameraMotionHandle handle,
                         CameraMotionParamType type,
                         float value);


/**
 * @brief 算法的主要调用接口
 */
AILAB_EXPORT
int CameraMotion_DO(CameraMotionHandle handle,
                  CameraMotionArgs* args,
                  CameraMotionRet* ret);


/**
 * @brief 销毁句柄，释放资源
 */
AILAB_EXPORT
int CameraMotion_ReleaseHandle(CameraMotionHandle handle);



#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_CAMERAMOTIONAPI_H_
