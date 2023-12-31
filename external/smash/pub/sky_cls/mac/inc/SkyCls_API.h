#ifndef _SMASH_SKYCLSAPI_H_
#define _SMASH_SKYCLSAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

// clang-format off
typedef void* SkyClsHandle;


/**
 * @brief 模型参数类型
 *
 */
typedef enum SkyClsParamType {
  kSkyClsEdgeMode = 1,        ///< TODO: 根据实际情况修改
} SkyClsParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum SkyClsModelType {
  kSkyClsModel1 = 1,          ///< TODO: 根据实际情况更改
} SkyClsModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct SkyClsArgs {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
  // 此处可以添加额外的算法参数
} SkyClsArgs;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct SkyClsRet {
  // 下面只做举例，不同的算法需要单独设置
    float probability; //分类为Day的概率
} SkyClsRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return SkyCls_CreateHandle
 */
AILAB_EXPORT
int SkyCls_CreateHandle(SkyClsHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return SkyCls_LoadModel
 */
AILAB_EXPORT
int SkyCls_LoadModel(SkyClsHandle handle,
                         SkyClsModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return SkyCls_LoadModelFromBuff
 */
AILAB_EXPORT
int SkyCls_LoadModelFromBuff(SkyClsHandle handle,
                                 SkyClsModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return SkyCls_SetParamF
 */
AILAB_EXPORT
int SkyCls_SetParamF(SkyClsHandle handle,
                         SkyClsParamType type,
                         float value);



/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT SkyCls_DO
 */
AILAB_EXPORT
int SkyCls_DO(SkyClsHandle handle,
                  SkyClsArgs* args,
                  SkyClsRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT SkyCls_ReleaseHandle
 */
AILAB_EXPORT
int SkyCls_ReleaseHandle(SkyClsHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT SkyCls_DbgPretty
 */
AILAB_EXPORT
int SkyCls_DbgPretty(SkyClsHandle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_SKYCLSAPI_H_
