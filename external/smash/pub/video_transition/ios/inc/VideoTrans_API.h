#ifndef _SMASH_VIDEOTRANSAPI_H_
#define _SMASH_VIDEOTRANSAPI_H_

#include "VideoCls_API.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

  // clang-format off
typedef void* VideoTransHandle;

/**
 * @brief 为算法推荐配置的算法参数，如CNN网络输入大小
 *
 */
typedef struct VideoTransRecommendConfig {
  int InputWidth;            ///< TODO: 根据实际情况修改
  int InputHeight;
} VideoTransRecommendConfig;


/**
 * @brief 模型参数类型
 *
 */
typedef enum VideoTransParamType {
  kVideoTransEdgeMode = 1,        /// 带随机模式
} VideoTransParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum VideoTransModelType {
  kVideoTransModel1 = 1,          ///< TODO: 根据实际情况更改
} VideoTransModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct VideoTransArgs {
  VideoClsFeat* leftFeats;
  VideoClsFeat* rightFeats;
  VideoClsFeat* thres;
  int n_features;
  // 此处可以添加额外的算法参数
} VideoTransArgs;



/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct VideoTransRet {
  // 下面只做举例，不同的算法需要单独设置
  VideoClsType* types;
  int n_types;
} VideoTransRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return VideoTrans_CreateHandle
 */
AILAB_EXPORT
int VideoTrans_CreateHandle(VideoTransHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return VideoTrans_LoadModel
 */
AILAB_EXPORT
int VideoTrans_LoadModel(VideoTransHandle handle,
                         VideoTransModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return VideoTrans_LoadModelFromBuff
 */
AILAB_EXPORT
int VideoTrans_LoadModelFromBuff(VideoTransHandle handle,
                                 VideoTransModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return VideoTrans_SetParamF
 */
AILAB_EXPORT
int VideoTrans_SetParamF(VideoTransHandle handle,
                         VideoTransParamType type,
                         float value);


/**
 * @brief 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置的参数类型
 * @param value 设置参数的值
 * @return VideoTrans_SetParamS
 */
AILAB_EXPORT
int VideoTrans_SetParamS(VideoTransHandle handle,
                         VideoTransParamType type,
                         char* value);


/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT VideoTrans_DO
 */
AILAB_EXPORT
int VideoTrans_DO(VideoTransHandle handle,
                  VideoTransArgs* args,
                  VideoTransRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT VideoTrans_ReleaseHandle
 */
AILAB_EXPORT
int VideoTrans_ReleaseHandle(VideoTransHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT VideoTrans_DbgPretty
 */
AILAB_EXPORT
int VideoTrans_DbgPretty(VideoTransHandle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////


/**
 * @brief 为返回值分配内存
 *
 * @param handle 句柄
 * @param ret
 * @return C2_InitRet
 */
  AILAB_EXPORT
  VideoTransRet* VideoTrans_MallocResultMemory(VideoTransHandle handle);

  /**
   * @brief 释放返回值的内存
   *
   * @param handle 句柄
   * @param ret
   * @return C2_ReleaseRet
   */
  AILAB_EXPORT
  int VideoTrans_FreeResultMemory(VideoTransRet* ret);



#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_VIDEOTRANSAPI_H_
