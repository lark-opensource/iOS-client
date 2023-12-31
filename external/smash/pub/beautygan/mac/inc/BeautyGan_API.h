#ifndef _SMASH_BEAUTYGANAPI_H_
#define _SMASH_BEAUTYGANAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

// clang-format off
typedef void* BeautyGanHandle;
#define TT_BEAUTY_GAN_MAX_FACE_NUM 10

/**
 * @brief 模型参数类型
 *
 */
typedef enum BeautyGanParamType {
    kBeautyGanUsedModelType = 1,   //当前使用的模型index
} BeautyGanParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum BeautyGanModelType {
    kBeautyGanModel1 = 1,   // 混血男模型
    kBeautyGanModel2 = 2,   // 混血女模型
    kBeautyGanModel3 = 3,   // 混血女模型
    kBeautyGanModel4 = 4,   // 混血女模型
    kBeautyGanModelMax = 10000,
} BeautyGanModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct BeautyGanArgs {
    ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
    int face_count;
    int id[TT_BEAUTY_GAN_MAX_FACE_NUM];
    float *landmark106[TT_BEAUTY_GAN_MAX_FACE_NUM]; // 人脸106关键点
} BeautyGanArgs;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct BeautyGanRet {
  // 下面只做举例，不同的算法需要单独设置
    unsigned char* alpha;        ///< alpha[i, j] 表示第 (i, j) 点的 mask 预测值，值位于[0, 255] 之间
    int width;                   ///< 指定alpha的宽度
    int height;                  ///< 指定alpha的高度
    float matrix[6];
    int face_count;
} BeautyGanRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return BeautyGan_CreateHandle
 */
AILAB_EXPORT
int BeautyGan_CreateHandle(BeautyGanHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return BeautyGan_LoadModel
 */
AILAB_EXPORT
int BeautyGan_LoadModel(BeautyGanHandle handle,
                         BeautyGanModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return BeautyGan_LoadModelFromBuff
 */
AILAB_EXPORT
int BeautyGan_LoadModelFromBuff(BeautyGanHandle handle,
                                 BeautyGanModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return BeautyGan_SetParamF
 */
AILAB_EXPORT
int BeautyGan_SetParamF(BeautyGanHandle handle,
                         BeautyGanParamType type,
                         float value);



/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT BeautyGan_DO
 */
AILAB_EXPORT
int BeautyGan_DO(BeautyGanHandle handle,
                  BeautyGanArgs* args,
                  BeautyGanRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT BeautyGan_ReleaseHandle
 */
AILAB_EXPORT
int BeautyGan_ReleaseHandle(BeautyGanHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT BeautyGan_DbgPretty
 */
AILAB_EXPORT
int BeautyGan_DbgPretty(BeautyGanHandle handle);

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
BeautyGanRet* BeautyGan_MallocResultMemory(BeautyGanHandle handle);

/**
* @brief 释放结果buf内存
*
* @param handle
* @return AILAB_EXPORT BeautyGan_FreeResultMemory
*/
AILAB_EXPORT
int BeautyGan_ReleaseRet(BeautyGanRet* ret);


#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_BEAUTYGANAPI_H_
