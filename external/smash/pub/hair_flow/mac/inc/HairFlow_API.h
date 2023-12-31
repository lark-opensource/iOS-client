#ifndef _SMASH_HAIRFLOWAPI_H_
#define _SMASH_HAIRFLOWAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

// clang-format off
typedef void* HairFlowHandle;


/**
 * @brief 模型参数类型
 *
 */
typedef enum HairFlowParamType {
  kHairFlowEdgeMode = 1,        ///< TODO: 根据实际情况修改
} HairFlowParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum HairFlowModelType {
  kHairFlowModel1 = 1,          ///< TODO: 根据实际情况更改
} HairFlowModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct HairFlowArgs {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
  // 此处可以添加额外的算法参数
} HairFlowArgs;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct HairFlowRet {
  int height;         // 输出图片的高度，不一定等于输入图片的高度
  int width;          // 输出图片的宽度，不一定等于输入图片的宽度
  
  float* mask;        // 头发区域分割结果，元素个数为height * width，取值范围为[0, 1]，表示第 (i, j) 点属于头发区域的概率；
  
  float* motion;      // 头发流动向量预测结果，元素个数为height * width * 2，取值范围为[-1, 1]，
                      // motion[i, j, 0] 表示第 (i, j) 点的在x方向上的相对流动距离，负值表示流动方向为左，正值表示流动方向为右；
                      // motion[i, j, 1] 表示第 (i, j) 点的在y方向上的相对流动距离，负值表示流动方向为上，正值表示流动方向为下；
                      // motion[i, j, 0] * width和motion[i, j, 1] * height分别对应x方向上和y方向上的绝对流动距离，单位为pixel；
  bool do_inpaint;    // 当前帧是否需要inpaint，只有当前帧和之前帧的长宽/纵横比一致且光流很小时do_inpaint才为false

} HairFlowRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return HairFlow_CreateHandle
 */
AILAB_EXPORT
int HairFlow_CreateHandle(HairFlowHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return HairFlow_LoadModel
 */
AILAB_EXPORT
int HairFlow_LoadModel(HairFlowHandle handle,
                         HairFlowModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return HairFlow_LoadModelFromBuff
 */
AILAB_EXPORT
int HairFlow_LoadModelFromBuff(HairFlowHandle handle,
                                 HairFlowModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return HairFlow_SetParamF
 */
AILAB_EXPORT
int HairFlow_SetParamF(HairFlowHandle handle,
                         HairFlowParamType type,
                         float value);



/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT HairFlow_DO
 */
AILAB_EXPORT
int HairFlow_DO(HairFlowHandle handle,
                  HairFlowArgs* args,
                  HairFlowRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT HairFlow_ReleaseHandle
 */
AILAB_EXPORT
int HairFlow_ReleaseHandle(HairFlowHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT HairFlow_DbgPretty
 */
AILAB_EXPORT
int HairFlow_DbgPretty(HairFlowHandle handle);

/**
 * @brief 为算法结果结构体申请空间, 如果空间是固定大小或者有上限的，可以无需传入参数
 *
 * @param width
 * @param height
 * @return AILAB_EXPORT HairFlow_MallocResultMemory
 */
AILAB_EXPORT
HairFlowRet* HairFlow_MallocResultMemory(HairFlowHandle handle, int width, int height);

/**
 * @brief 释放算法输出结构体空间
 *
 * @param ret
 * @return AILAB_EXPORT HairFlow_FreeResultMemory
 */
AILAB_EXPORT
int HairFlow_FreeResultMemory(HairFlowRet* ret);


////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_HAIRFLOWAPI_H_
