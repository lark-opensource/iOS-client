#ifndef _SMASH_BIGGANAPI_H_
#define _SMASH_BIGGANAPI_H_

#include "smash_module_tpl.h"
#include "smash_runtime_info.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus
  
// clang-format off
typedef void* BigGanHandle;
#define TT_BIGGAN_MAX_FACE_LIMIT 10  // 最大支持人脸数

/**
 * @brief 模型参数类型
 *
 */
typedef enum BigGanParamType {
    kBigGanParam1 = 1,
} BigGanParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum BigGanModelType {
    kBigGanModel1 = 1,
    kBigGanModel2,
} BigGanModelType;


/**
 * @brief 封装预测接口的输入数据
 */
typedef struct BigGanArgs {
  ModuleBaseArgs base;                    // 对视频帧数据做了基本的封装
  int face_count;                         //人脸个数
  int id[TT_BIGGAN_MAX_FACE_LIMIT];
  float *landmark106[TT_BIGGAN_MAX_FACE_LIMIT];
} BigGanArgs;


/**
 * @brief 封装预测接口的返回值
 */
typedef struct BigGanRet {
  unsigned char* alpha;        ///< 输出的3通道的数据，排列RGB的顺序
  int width;                   ///< 输出数据alpha的宽度
  int height;                  ///< 输出数据alpha的高度
  float matrix[6];             ///< affine matrix
  int face_count;
} BigGanRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return BigGan_CreateHandle
 */
AILAB_EXPORT
int BigGan_CreateHandle(BigGanHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return BigGan_LoadModel
 */
AILAB_EXPORT
int BigGan_LoadModel(BigGanHandle handle,
                     BigGanModelType type,
                     const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return BigGan_LoadModelFromBuff
 */
AILAB_EXPORT
int BigGan_LoadModelFromBuff(BigGanHandle handle,
                             BigGanModelType type,
                             const char* mem_model,
                             int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return BigGan_SetParamF
 */
AILAB_EXPORT
int BigGan_SetParamF(BigGanHandle handle,
                     BigGanParamType type,
                     float value);


/**
 * @brief 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置的参数类型
 * @param value 设置参数的值
 * @return BigGan_SetParamS
 */
AILAB_EXPORT
int BigGan_SetParamS(BigGanHandle handle,
                     BigGanParamType type,
                     char* value);


/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT BigGan_DO
 */
AILAB_EXPORT
int BigGan_DO(BigGanHandle handle,
              BigGanArgs* args,
              BigGanRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT BigGan_ReleaseHandle
 */
AILAB_EXPORT
int BigGan_ReleaseHandle(BigGanHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT BigGan_DbgPretty
 */
AILAB_EXPORT
int BigGan_DbgPretty(BigGanHandle handle);
  
/**
 * @breif 获取运行时数据
 * @return
 *
 */
AILAB_EXPORT int BigGan_GetRuntimeInfo(BigGanHandle handle, ModuleRunTimeInfo * result);

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif  // _SMASH_BIGGANAPI_H_
