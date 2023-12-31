#ifndef _SMASH_SCENELIGHTAPI_H_
#define _SMASH_SCENELIGHTAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

// clang-format off
typedef void* SceneLightHandle;

#define AI_SCENE_LIGHT_SH_VALUE_NUM 27 // 球谐光权重个数


/**
 * @brief 模型参数类型
 * kSceneLightInputType:
 *    算法参数，用来设置是否使用视频模式
 *    - 0: 图片模式
 *    - 1: 视频模式（默认）
 *
 */

typedef enum SceneLightParamType {
  kSceneLightInputType = 1,        // 输入数据的类型。 1为时序
} SceneLightParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum SceneLightModelType {
  kSceneLightModel1 = 1,          ///< TODO: 根据实际情况更改
} SceneLightModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct SceneLightArgs {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
  // 此处可以添加额外的算法参数
} SceneLightArgs;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct SceneLightRet {
  // 下面只做举例，不同的算法需要单独设置
  float SH_lighting_RGB[AI_SCENE_LIGHT_SH_VALUE_NUM];    ///< 球谐光照
} SceneLightRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return SceneLight_CreateHandle
 */
AILAB_EXPORT
int SceneLight_CreateHandle(SceneLightHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return SceneLight_LoadModel
 */
AILAB_EXPORT
int SceneLight_LoadModel(SceneLightHandle handle,
                         SceneLightModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return SceneLight_LoadModelFromBuff
 */
AILAB_EXPORT
int SceneLight_LoadModelFromBuff(SceneLightHandle handle,
                                 SceneLightModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return SceneLight_SetParamF
 */
AILAB_EXPORT
int SceneLight_SetParamF(SceneLightHandle handle,
                         SceneLightParamType type,
                         float value);



/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT SceneLight_DO
 */
AILAB_EXPORT
int SceneLight_DO(SceneLightHandle handle,
                  SceneLightArgs* args,
                  SceneLightRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT SceneLight_ReleaseHandle
 */
AILAB_EXPORT
int SceneLight_ReleaseHandle(SceneLightHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT SceneLight_DbgPretty
 */
AILAB_EXPORT
int SceneLight_DbgPretty(SceneLightHandle handle);

/**
 * @brief 为算法结果结构体申请空间, 如果空间是固定大小或者有上限的，可以无需传入参数
 *
 * @param width
 * @param height
 * @return AILAB_EXPORT SceneLight_MallocResultMemory
 */
AILAB_EXPORT
SceneLightRet* SceneLight_MallocResultMemory(SceneLightHandle handle, int width, int height);

/**
 * @brief 释放算法输出结构体空间
 *
 * @param ret
 * @return AILAB_EXPORT SceneLight_FreeResultMemory
 */
AILAB_EXPORT
int SceneLight_FreeResultMemory(SceneLightRet* ret);


////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_SCENELIGHTAPI_H_
