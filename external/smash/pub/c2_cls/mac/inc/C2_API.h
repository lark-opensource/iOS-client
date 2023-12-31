#ifndef _SMASH_C2API_H_
#define _SMASH_C2API_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus


// clang-format off
typedef void* C2Handle;

/**
 * @brief 为算法推荐配置的算法参数，如CNN网络输入大小
 *
 */
    

  typedef struct C2CategoryItem {
    int id;
    float confidence;
    float thres;
    bool satisfied;
  } C2CategoryItem;

/**
 * @brief 模型参数类型
 *
 */
typedef enum C2ParamType {
  C2_USE_VIDEO_MODE,  //默认值为0，表示图像模式, 1:视频模式
  C2_USE_MultiLabels,  // 默认值为0，表示单标签模式，1:多标签模式
} C2ParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum C2ModelType {
  kC2Model1 = 1,          ///< TODO: 根据实际情况更改
} C2ModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct C2Args {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
  // 此处可以添加额外的算法参数
} C2Args;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct C2Ret {
  // 下面只做举例，不同的算法需要单独设置
  C2CategoryItem* items;
  int n_classes;
} C2Ret;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return C2_CreateHandle
 */
AILAB_EXPORT
int C2_CreateHandle(C2Handle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return C2_LoadModel
 */
AILAB_EXPORT
int C2_LoadModel(C2Handle handle,
                 C2ModelType type,
                 const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return C2_LoadModelFromBuff
 */
AILAB_EXPORT
int C2_LoadModelFromBuff(C2Handle handle,
                         C2ModelType type,
                         const char* mem_model,
                         int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return C2_SetParamF
 */
AILAB_EXPORT
int C2_SetParamF(C2Handle handle,
                 C2ParamType type,
                 float value);


/**
 * @brief 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置的参数类型
 * @param value 设置参数的值
 * @return C2_SetParamS
 */
AILAB_EXPORT
int C2_SetParamS(C2Handle handle,
                 C2ParamType type,
                 char* value);

/**
* @brief 为返回值分配内存
*
* @param handle 句柄
* @param ret
* @return C2_InitRet
*/
AILAB_EXPORT
C2Ret* C2_InitRet(C2Handle handle);

/**
* @brief 释放返回值的内存
*
* @param handle 句柄
* @param ret
* @return C2_ReleaseRet
*/
AILAB_EXPORT
int C2_ReleaseRet(C2Ret* ret);



/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT C2_DO
 */
AILAB_EXPORT
int C2_DO(C2Handle handle,
          C2Args* args,
          C2Ret* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT C2_ReleaseHandle
 */
AILAB_EXPORT
int C2_ReleaseHandle(C2Handle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT C2_DbgPretty
 */
AILAB_EXPORT
int C2_DbgPretty(C2Handle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif  // _SMASH_C2API_H_
