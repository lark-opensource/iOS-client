#ifndef _SMASH_OCRWARPAPI_H_
#define _SMASH_OCRWARPAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

// clang-format off
typedef void* OCRWarpHandle;

#define OCRWARP_INPUTWIDTH 128
#define OCRWARP_INPUTHEIGHT 128


/**
 * @brief 模型参数类型
 *
 */
typedef enum OCRWarpParamType {
  kOCRWarpEdgeMode = 1,        ///< TODO: 根据实际情况修改
} OCRWarpParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum OCRWarpModelType {
  kOCRWarpModel1 = 1,          ///< TODO: 根据实际情况更改
} OCRWarpModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct OCRWarpArgs {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
  // 此处可以添加额外的算法参数
  int actionType; // 0, warp; 1, do BW
} OCRWarpArgs;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct OCRWarpRet {
  // 下面只做举例，不同的算法需要单独设置
  unsigned char* alpha;  // alpha[i, j] 表示第 (i, j) 点的 mask 预测值，值位于
                         // [0, 255] 之间
  int width;
  int height;
} OCRWarpRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return OCRWarp_CreateHandle
 */
AILAB_EXPORT
int OCRWarp_CreateHandle(OCRWarpHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return OCRWarp_LoadModel
 */
AILAB_EXPORT
int OCRWarp_LoadModel(OCRWarpHandle handle,
                         OCRWarpModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return OCRWarp_LoadModelFromBuff
 */
AILAB_EXPORT
int OCRWarp_LoadModelFromBuff(OCRWarpHandle handle,
                                 OCRWarpModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return OCRWarp_SetParamF
 */
AILAB_EXPORT
int OCRWarp_SetParamF(OCRWarpHandle handle,
                         OCRWarpParamType type,
                         float value);


/**
 * @brief 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置的参数类型
 * @param value 设置参数的值
 * @return OCRWarp_SetParamS
 */
AILAB_EXPORT
int OCRWarp_SetParamS(OCRWarpHandle handle,
                         OCRWarpParamType type,
                         char* value);


/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT OCRWarp_DO
 */
AILAB_EXPORT
int OCRWarp_DO(OCRWarpHandle handle,
                  OCRWarpArgs* args,
                  OCRWarpRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT OCRWarp_ReleaseHandle
 */
AILAB_EXPORT
int OCRWarp_ReleaseHandle(OCRWarpHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT OCRWarp_DbgPretty
 */
AILAB_EXPORT
int OCRWarp_DbgPretty(OCRWarpHandle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif  // _SMASH_OCRWARPAPI_H_
