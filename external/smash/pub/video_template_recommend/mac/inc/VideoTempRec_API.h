#ifndef _SMASH_VIDEOTEMPRECAPI_H_
#define _SMASH_VIDEOTEMPRECAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#include "AIMoment_API.h"

#include "AfterEffect_API.h"
#include "AttrSDK_API.h"
#include "VideoCls_API.h"

#include "smash_moment_base.h"

#include <stdint.h>

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

// clang-format off
typedef void* VideoTempRecHandle;


/**
 * @brief 模型参数类型
 *
 */
typedef enum VideoTempRecParamType {
  kVideoTempRecEdgeMode = 1,
} VideoTempRecParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum VideoTempRecModelType {
  kVideoTempRecModel1 = 1,
} VideoTempRecModelType;

typedef MomentInfo VideoTempRecArgs;

/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct VideoTempRecRet {
  VideoTempRecType* templates;
  int numTemplates;
} VideoTempRecRet;

/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return VideoTempRec_CreateHandle
 */
AILAB_EXPORT
int VideoTempRec_CreateHandle(VideoTempRecHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return VideoTempRec_LoadModel
 */
AILAB_EXPORT
int VideoTempRec_LoadModel(VideoTempRecHandle handle,
                         VideoTempRecModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return VideoTempRec_LoadModelFromBuff
 */
AILAB_EXPORT
int VideoTempRec_LoadModelFromBuff(VideoTempRecHandle handle,
                                 VideoTempRecModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return VideoTempRec_SetParamF
 */
AILAB_EXPORT
int VideoTempRec_SetParamF(VideoTempRecHandle handle,
                         VideoTempRecParamType type,
                         float value);



/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT VideoTempRec_DO
 */
AILAB_EXPORT
int VideoTempRec_DO(VideoTempRecHandle handle,
                  VideoTempRecArgs* args,
                  VideoTempRecRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT VideoTempRec_ReleaseHandle
 */
AILAB_EXPORT
int VideoTempRec_ReleaseHandle(VideoTempRecHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT VideoTempRec_DbgPretty
 */
AILAB_EXPORT
int VideoTempRec_DbgPretty(VideoTempRecHandle handle);



AILAB_EXPORT
int VideoTempRec_ReleaseRet(VideoTempRecHandle handle);

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_VIDEOTEMPRECAPI_H_
