#ifndef _SMASH_IMAGEFLOWAPI_H_
#define _SMASH_IMAGEFLOWAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

// 流动区域类别定义
#define IMAGE_FLOW_BG 0         // 背景（非流动区域）
#define IMAGE_FLOW_HAIR 1       // 头发
#define IMAGE_FLOW_CLOTH 2      // 衣服
#define IMAGE_FLOW_SKY 3        // 天空
#define IMAGE_FLOW_FUR 4        // 动物毛发
#define IMAGE_FLOW_WATER 5      // 水流
#define IMAGE_FLOW_OTHERS 6     // 其他

// clang-format off
typedef void* ImageFlowHandle;  // 图片流动预测句柄


/**
 * @brief 模型参数枚举
 *
 */
typedef enum ImageFlowParamType {
  kImageFlowEdgeMode = 1,        // 图片流动边缘模式
} ImageFlowParamType;


/**
 * @brief 模型枚举
 *
 */
typedef enum ImageFlowModelType {
  kImageFlowModel1 = 1,          // 图片流动预测模型
} ImageFlowModelType;


/**
 * @brief 封装预测接口的输入数据
 */
typedef struct ImageFlowArgs {
  ModuleBaseArgs base;           // 图片(视频帧)输入数据
} ImageFlowArgs;


/**
 * @brief 封装预测接口的返回值
 */
typedef struct ImageFlowRet {
  int height;         // 输入图片的高度
  int width;          // 输入图片的宽度
  
  float* mask;        // 流动区域分割结果，元素个数为height * width * 2，取值范围为[0, 1]，
                      // mask[i, j, 0] 表示第 (i, j) 点属于流动区域的概率，mask[i, j, 1] 表示第 (i, j) 点属于非流动区域的概率；
  
  float* masks;       // 显著性分割结果，元素个数为height * width * 2，取值范围为[0, 1]，
                      // mask[i, j, 0] 表示第 (i, j) 点属于非显著性区域的概率，mask[i, j, 1] 表示第 (i, j) 点属于显著性区域的概率；
  
  float* maskm;       // 流动区域多类别分割结果，元素个数为height * width * 7，取值范围为[0, 1]，
                      // maskm_alpha[i, j, 0] 表示第 (i, j) 点属于IMAGE_FLOW_BG类的概率，maskm_alpha[i, j, 1] 表示第 (i, j) 点属于IMAGE_FLOW_HAIR类的概率，
                      // maskm_alpha[i, j, 2] 表示第 (i, j) 点属于IMAGE_FLOW_CLOTH类的概率，maskm_alpha[i, j, 3] 表示第 (i, j) 点属于IMAGE_FLOW_SKY类的概率，
                      // maskm_alpha[i, j, 4] 表示第 (i, j) 点属于IMAGE_FLOW_FUR类的概率，maskm_alpha[i, j, 5] 表示第 (i, j) 点属于IMAGE_FLOW_WATER类的概率，
                      // maskm_alpha[i, j, 6] 表示第 (i, j) 点属于IMAGE_FLOW_OTHERS类的概率；
  
  float* motion;      // 流动向量预测结果，元素个数为height * width * 2，取值范围为[-1, 1]，
                      // motion[i, j, 0] 表示第 (i, j) 点的在x方向上的相对流动距离，负值表示流动方向为左，正值表示流动方向为右；
                      // motion[i, j, 1] 表示第 (i, j) 点的在y方向上的相对流动距离，负值表示流动方向为上，正值表示流动方向为下；
                      // motion[i, j, 0] * width和motion[i, j, 1] * height分别对应x方向上和y方向上的绝对流动距离，单位为pixel；
} ImageFlowRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return ImageFlow_CreateHandle
 */
AILAB_EXPORT
int ImageFlow_CreateHandle(ImageFlowHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return ImageFlow_LoadModel
 */
AILAB_EXPORT
int ImageFlow_LoadModel(ImageFlowHandle handle,
                         ImageFlowModelType type,
                         const char* model_path);


/**
 * @brief 从内存中加载模型
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return ImageFlow_LoadModelFromBuff
 */
AILAB_EXPORT
int ImageFlow_LoadModelFromBuff(ImageFlowHandle handle,
                                 ImageFlowModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return ImageFlow_SetParamF
 */
AILAB_EXPORT
int ImageFlow_SetParamF(ImageFlowHandle handle,
                         ImageFlowParamType type,
                         float value);



/**
 * @brief 对输入数据进行预测并返回结果
 *
 * @param handle 句柄
 * @param args 输入数据
 * @param ret 返回数据
 * @return AILAB_EXPORT ImageFlow_DO
 */
AILAB_EXPORT
int ImageFlow_DO(ImageFlowHandle handle,
                  ImageFlowArgs* args,
                  ImageFlowRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle 句柄
 * @return AILAB_EXPORT ImageFlow_ReleaseHandle
 */
AILAB_EXPORT
int ImageFlow_ReleaseHandle(ImageFlowHandle handle);


/**
 * @brief 打印部分模块的参数
 *
 * @param handle 句柄
 * @return AILAB_EXPORT ImageFlow_DbgPretty
 */
AILAB_EXPORT
int ImageFlow_DbgPretty(ImageFlowHandle handle);


#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_IMAGEFLOWAPI_H_
