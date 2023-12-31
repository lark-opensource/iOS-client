#ifndef _SMASH___SAMPLE__API_H_
#define _SMASH___SAMPLE__API_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

// clang-format off
typedef void* __Sample__Handle;


/**
 * @brief 模型参数类型
 *
 */
typedef enum __Sample__ParamType {
  k__Sample__EdgeMode = 1,        ///< TODO: 根据实际情况修改
} __Sample__ParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum __Sample__ModelType {
  k__Sample__Model1 = 1,          ///< TODO: 根据实际情况更改
} __Sample__ModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct __Sample__Args {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
  // 此处可以添加额外的算法参数
} __Sample__Args;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct __Sample__Ret {
  // 下面只做举例，不同的算法需要单独设置
  unsigned char* alpha;        ///< alpha[i, j] 表示第 (i, j) 点的 mask 预测值，值位于[0, 255] 之间
  int width;                   ///< 指定alpha的宽度
  int height;                  ///< 指定alpha的高度
} __Sample__Ret;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return __Sample___CreateHandle
 */
AILAB_EXPORT
int __Sample___CreateHandle(__Sample__Handle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return __Sample___LoadModel
 */
AILAB_EXPORT
int __Sample___LoadModel(__Sample__Handle handle,
                         __Sample__ModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return __Sample___LoadModelFromBuff
 */
AILAB_EXPORT
int __Sample___LoadModelFromBuff(__Sample__Handle handle,
                                 __Sample__ModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return __Sample___SetParamF
 */
AILAB_EXPORT
int __Sample___SetParamF(__Sample__Handle handle,
                         __Sample__ParamType type,
                         float value);



/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT __Sample___DO
 */
AILAB_EXPORT
int __Sample___DO(__Sample__Handle handle,
                  __Sample__Args* args,
                  __Sample__Ret* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT __Sample___ReleaseHandle
 */
AILAB_EXPORT
int __Sample___ReleaseHandle(__Sample__Handle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT __Sample___DbgPretty
 */
AILAB_EXPORT
int __Sample___DbgPretty(__Sample__Handle handle);

/**
 * @brief 为算法结果结构体申请空间, 如果空间是固定大小或者有上限的，可以无需传入参数
 *
 * @param width
 * @param height
 * @return AILAB_EXPORT __Sample___MallocResultMemory
 */
AILAB_EXPORT
__Sample__Ret* __Sample___MallocResultMemory(__Sample__Handle handle, int width, int height);

/**
 * @brief 释放算法输出结构体空间
 *
 * @param ret
 * @return AILAB_EXPORT __Sample___FreeResultMemory
 */
AILAB_EXPORT
int __Sample___FreeResultMemory(__Sample__Ret* ret);


////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH___SAMPLE__API_H_
