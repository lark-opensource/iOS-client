#ifndef _SMASH_INTERACTIVEMATTINGAPI_H_
#define _SMASH_INTERACTIVEMATTINGAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

// clang-format off
typedef void* InteractiveMattingHandle;


/**
 * @brief 模型参数类型
 * kInteractiveMattingMethod: 0-tradi; 1: cnn; 2: cnn-enhance
 * kInteractiveMattingPenType: 0 - add pen; 1: del pen (only cnn method support)
 * kInteractiveMattingForwardType: Default = -1, CPU = 0, GPU = 1
 */
typedef enum InteractiveMattingParamType {
  kInteractiveMattingMethod = 0,
  kInteractiveMattingNetInputSize = 1,
  kInteractiveMattingMaxAspectRatio = 2,
  kInteractiveMattingParam1 = 3,
  kInteractiveMattingParam2 = 4,
  kInteractiveMattingParam3 = 5,
  kInteractiveMattingParam4 = 6,
  kInteractiveMattingParam5 = 7,
  kInteractiveMattingParam6 = 8,
  kInteractiveMattingParam7 = 9,
  kInteractiveMattingParam8 = 10,
  kInteractiveMattingPenType = 11,
  kInteractiveMattingForwardType = 12,
} InteractiveMattingParamType;

/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum InteractiveMattingModelType {
  kInteractiveMattingModel0 = 0,
} InteractiveMattingModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct InteractiveMattingArgs {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
  // 此处可以添加额外的算法参数
  ModuleBaseArgs draw;  //< 当前帧涂抹mask
  bool re_init;
  const unsigned char* prev_mask;  //< 上一帧算法结果mask
} InteractiveMattingArgs;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct InteractiveMattingRet {
  // 下面只做举例，不同的算法需要单独设置
  unsigned char* alpha;        ///< alpha[i, j] 表示第 (i, j) 点的 mask 预测值，值位于[0, 255] 之间
  int width;                   ///< 指定alpha的宽度
  int height;                  ///< 指定alpha的高度
  float top;
  float down;
  float left;
  float right;
} InteractiveMattingRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return InteractiveMatting_CreateHandle
 */
AILAB_EXPORT
int InteractiveMatting_CreateHandle(InteractiveMattingHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return InteractiveMatting_LoadModel
 */
AILAB_EXPORT
int InteractiveMatting_LoadModel(InteractiveMattingHandle handle,
                         InteractiveMattingModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return InteractiveMatting_LoadModelFromBuff
 */
AILAB_EXPORT
int InteractiveMatting_LoadModelFromBuff(InteractiveMattingHandle handle,
                                 InteractiveMattingModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return InteractiveMatting_SetParamF
 */
AILAB_EXPORT
int InteractiveMatting_SetParamF(InteractiveMattingHandle handle,
                         InteractiveMattingParamType type,
                         float value);


/**
 * @brief 返回的size
 *
 * @param handle 句柄
 * @param args
 * @param ret
 * @return InteractiveMatting_GetAlphaSize
 */
AILAB_EXPORT
int InteractiveMatting_GetAlphaSize(InteractiveMattingHandle handle,
                         InteractiveMattingArgs* args,
                         InteractiveMattingRet* ret);

/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT InteractiveMatting_DO
 */
AILAB_EXPORT
int InteractiveMatting_DO(InteractiveMattingHandle handle,
                  InteractiveMattingArgs* args,
                  InteractiveMattingRet* ret);


/**
 * @brief reset 内部算法图
 *
 * @param handle
 * @return AILAB_EXPORT InteractiveMatting_Reset
 */
AILAB_EXPORT
int InteractiveMatting_Reset(InteractiveMattingHandle handle);

/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT InteractiveMatting_ReleaseHandle
 */
AILAB_EXPORT
int InteractiveMatting_ReleaseHandle(InteractiveMattingHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT InteractiveMatting_DbgPretty
 */
AILAB_EXPORT
int InteractiveMatting_DbgPretty(InteractiveMattingHandle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_INTERACTIVEMATTINGAPI_H_
