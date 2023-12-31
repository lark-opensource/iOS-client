#ifndef _SMASH_IDREAMAPI_H_
#define _SMASH_IDREAMAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

#define TT_IDREAM_GAN_MAX_FACE_NUM 10

// clang-format off
typedef void* idreamHandle;


/**
 * @brief 模型参数类型
 *
 */
typedef enum idreamParamType {
    kidreamParamTypeCrop = 0,
    kidreamP0 = 100, //渐变参数
    kidreamP1 = 101,
    kidreamP2 = 102,
    kidreamP3 = 103,
    kidreamP4 = 104,
    kidreamP5 = 105,
    kidreamP6 = 106,
    kidreamP7 = 107,
    
} idreamParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum idreamModelType {
    kidreamModel0 = 0
} idreamModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct idreamArgs {
    ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
    int face_count;
    int id[TT_IDREAM_GAN_MAX_FACE_NUM];
    float *landmark106[TT_IDREAM_GAN_MAX_FACE_NUM]; // 人脸106关键点
} idreamArgs;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct idreamRet {
    // 下面只做举例，不同的算法需要单独设置
    unsigned char* alpha;        ///< alpha[i, j] 表示第 (i, j) 点的 mask 预测值，值位于[0, 255] 之间
    int width;                   ///< 指定alpha的宽度
    int height;                  ///< 指定alpha的高度
    float matrix[6];
    int face_count;
} idreamRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return idream_CreateHandle
 */
AILAB_EXPORT
int idream_CreateHandle(idreamHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return idream_LoadModel
 */
AILAB_EXPORT
int idream_LoadModel(idreamHandle handle,
                     idreamModelType type,
                     const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return idream_LoadModelFromBuff
 */
AILAB_EXPORT
int idream_LoadModelFromBuff(idreamHandle handle,
                             idreamModelType type,
                             const char* mem_model,
                             int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return idream_SetParamF
 */
AILAB_EXPORT
int idream_SetParamF(idreamHandle handle,
                     idreamParamType type,
                     float value);



/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT idream_DO
 */
AILAB_EXPORT
int idream_DO(idreamHandle handle,
              idreamArgs* args,
              idreamRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT idream_ReleaseHandle
 */
AILAB_EXPORT
int idream_ReleaseHandle(idreamHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT idream_DbgPretty
 */
AILAB_EXPORT
int idream_DbgPretty(idreamHandle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

/**
 * @brief 申请内存buf
 *
 * @param handle
 * @return AILAB_EXPORT BeautyGan_MallocResultMemory
 */
AILAB_EXPORT
idreamRet* idream_MallocResultMemory(idreamHandle handle);

/**
 * @brief 释放结果buf内存
 *
 * @param handle
 * @return AILAB_EXPORT BeautyGan_FreeResultMemory
 */
AILAB_EXPORT
int idream_ReleaseRet(idreamRet* ret);

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_IDREAMAPI_H_
