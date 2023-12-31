#ifndef _SMASH_C3CLSAPI_H_
#define _SMASH_C3CLSAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

// clang-format off
typedef void* C3ClsHandle;


typedef struct C3CategoryItem {
    int id;
    float confidence;
    bool satisfied;
} C3CategoryItem;


/**
 * @brief 模型参数类型
 *
 */
typedef enum C3ClsParamType {
  kC3ClsEdgeMode = 1,        ///< TODO: 根据实际情况修改
  KC3ClsGetFeatureMode = 2,  /// get feature mode
}C3ClsParamType;



/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum C3ClsModelType {
  kC3ClsModel1 = 1,          ///< TODO: 根据实际情况更改
}C3ClsModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct C3ClsArgs {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
  // 此处可以添加额外的算法参数
}C3ClsArgs;


typedef struct C3ClsFeature {
    float *feature_data;
    int feature_len;
}C3ClsFeature;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct C3ClsRet {
    C3CategoryItem *items;
    int classNum;
    C3ClsFeature *features;
}C3ClsRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return C3Cls_CreateHandle
 */
AILAB_EXPORT
int C3Cls_CreateHandle(C3ClsHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return C3Cls_LoadModel
 */
AILAB_EXPORT
int C3Cls_LoadModel(C3ClsHandle handle,
                         C3ClsModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return C3Cls_LoadModelFromBuff
 */
AILAB_EXPORT
int C3Cls_LoadModelFromBuff(C3ClsHandle handle,
                                 C3ClsModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return C3Cls_SetParamF
 */
AILAB_EXPORT
int C3Cls_SetParamF(C3ClsHandle handle,
                         C3ClsParamType type,
                         float value);




AILAB_EXPORT
C3ClsRet* C3Cls_MallocMemoryForRet(C3ClsHandle handle);


AILAB_EXPORT
int C3Cls_FreeMemoryForRet(C3ClsRet* ret);


/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT C3Cls_DO
 */
AILAB_EXPORT
int C3Cls_DO(C3ClsHandle handle,
                  C3ClsArgs* args,
                  C3ClsRet* ret);



/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT C3Cls_ReleaseHandle
 */
AILAB_EXPORT
int C3Cls_ReleaseHandle(C3ClsHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT C3Cls_DbgPretty
 */
AILAB_EXPORT
int C3Cls_DbgPretty(C3ClsHandle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_C3CLSAPI_H_
