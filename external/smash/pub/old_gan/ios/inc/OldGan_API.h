#ifndef _SMASH_OLDGANAPI_H_
#define _SMASH_OLDGANAPI_H_

#include "smash_runtime_info.h"
#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

// clang-format off
typedef void* OldGanHandle;
#define TT_OLD_GAN_MAX_FACE_LIMIT 1  // 最大支持人脸数


/**
 * @brief 模型参数类型
 *
 */
typedef enum OldGanParamType {
  kOldGanEdgeMode = 1,        ///< TODO: 根据实际情况修改
} OldGanParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum OldGanModelType {
  kOldGanModel1 = 1,          ///< TODO: 根据实际情况更改
} OldGanModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct OldGanArgs {
    ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
    int face_count;   //人脸个数
    int id[TT_OLD_GAN_MAX_FACE_LIMIT];
    float *landmark106[TT_OLD_GAN_MAX_FACE_LIMIT];
    float yaw[TT_OLD_GAN_MAX_FACE_LIMIT];
} OldGanArgs;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct OldGanRet {
    unsigned char* alpha;        ///< alpha[i, j] 表示第 (i, j) 点的 mask 预测值，值位于[0, 255] 之间
    int width;                   ///< 指定alpha的宽度
    int height;                  ///< 指定alpha的高度
    float matrix[6];             ///< affine matrix
    int face_count;
} OldGanRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return OldGan_CreateHandle
 */
AILAB_EXPORT
int OldGan_CreateHandle(OldGanHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return OldGan_LoadModel
 */
AILAB_EXPORT
int OldGan_LoadModel(OldGanHandle handle,
                         OldGanModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return OldGan_LoadModelFromBuff
 */
AILAB_EXPORT
int OldGan_LoadModelFromBuff(OldGanHandle handle,
                                 OldGanModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return OldGan_SetParamF
 */
AILAB_EXPORT
int OldGan_SetParamF(OldGanHandle handle,
                         OldGanParamType type,
                         float value);


/**
 * @brief 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置的参数类型
 * @param value 设置参数的值
 * @return OldGan_SetParamS
 */
AILAB_EXPORT
int OldGan_SetParamS(OldGanHandle handle,
                         OldGanParamType type,
                         char* value);


/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT OldGan_DO
 */
AILAB_EXPORT
int OldGan_DO(OldGanHandle handle,
                  OldGanArgs* args,
                  OldGanRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT OldGan_ReleaseHandle
 */
AILAB_EXPORT
int OldGan_ReleaseHandle(OldGanHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT OldGan_DbgPretty
 */
AILAB_EXPORT
int OldGan_DbgPretty(OldGanHandle handle);

/**
 * @breif 获取运行时数据
 * @return
 *
 */
AILAB_EXPORT int OldGan_GetRuntimeInfo(OldGanHandle handle, ModuleRunTimeInfo * result);

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif  // _SMASH_OLDGANAPI_H_
