#ifndef _SMASH_GENERALOCRAPI_H_
#define _SMASH_GENERALOCRAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

#define GeneralOCR_MAX_DET_NUM 500
    
// clang-format off
typedef void* GeneralOCRHandle;

/**
 * @brief 模型参数类型
 *
 */
typedef enum GeneralOCRParamType {
  kGeneralOCREdgeMode = 1,
} GeneralOCRParamType ;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum GeneralOCRModelType {
  kGeneralOCRModel1 = 1,
} GeneralOCRModelType;


/**
 * @brief 封装预测接口的输入数据
 */
typedef struct GeneralOCRArgs {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
  int num_kernels;               ///< 分割核个数,最大为3,最小为1,demo设置为3
  float min_kernel_area;         ///< 分割核的最小区域大小,demo设置为0.1
  float min_score;               ///< 是否为文字阈值,demo设置为0.5
  float min_area;                ///< 文字的最小区域大小,demo设置为5.0
} GeneralOCRArgs;

/**
 * @brief 用于存储每个文字行的检测及识别结果
 * 
 */
typedef struct GeneralOCRInfo {
  int bounding_box[8];           ///< 检测框像素位置,顺时针左上角起x1,y1,x2,y2,x3,y3,x4,y4
  int has_recog_info;            ///< 是否识别到图片内容, 0-否, 1-是
  char recog_res[300];           ///< 识别结果
} GeneralOCRInfo;

/**
 * @brief 封装预测接口的返回值
 */
typedef struct GeneralOCRRet {
  int det_num;
  GeneralOCRInfo general_ocr_res[GeneralOCR_MAX_DET_NUM];
} GeneralOCRRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return GeneralOCR_CreateHandle
 */
AILAB_EXPORT
int GeneralOCR_CreateHandle(GeneralOCRHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return GeneralOCR_LoadModel
 */
AILAB_EXPORT
int GeneralOCR_LoadModel(GeneralOCRHandle handle,
                         GeneralOCRModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return GeneralOCR_LoadModelFromBuff
 */
AILAB_EXPORT
int GeneralOCR_LoadModelFromBuff(GeneralOCRHandle handle,
                                 GeneralOCRModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return GeneralOCR_SetParamF
 */
AILAB_EXPORT
int GeneralOCR_SetParamF(GeneralOCRHandle handle,
                         GeneralOCRParamType type,
                         float value);


/**
 * @brief 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置的参数类型
 * @param value 设置参数的值
 * @return GeneralOCR_SetParamS
 */
AILAB_EXPORT
int GeneralOCR_SetParamS(GeneralOCRHandle handle,
                         GeneralOCRParamType type,
                         char* value);


/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT GeneralOCR_DO
 */
AILAB_EXPORT
int GeneralOCR_DO(GeneralOCRHandle handle,
                  GeneralOCRArgs* args,
                  GeneralOCRRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT GeneralOCR_ReleaseHandle
 */
AILAB_EXPORT
int GeneralOCR_ReleaseHandle(GeneralOCRHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT GeneralOCR_DbgPretty
 */
AILAB_EXPORT
int GeneralOCR_DbgPretty(GeneralOCRHandle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_GENERALOCRAPI_H_
