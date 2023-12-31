#ifndef _SMASH_VIDEOCLSAPI_H_
#define _SMASH_VIDEOCLSAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

  // clang-format off
typedef void* VideoClsHandle;


/**
 * @brief 模型参数类型
 *
 */
typedef enum VideoClsParamType {
  kVideoClsEdgeMode = 1,        ///< TODO: 根据实际情况修改
} VideoClsParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum VideoClsModelType {
  kVideoClsModel1 = 1,          ///< TODO: 根据实际情况更改
} VideoClsModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct VideoClsArgs {
  ModuleBaseArgs *bases;           ///< 对视频帧数据做了基本的封装
  int is_last; //是否为最后一帧
} VideoClsArgs;


typedef struct VideoClsType {
  int id; //类别id
  float confidence; //类别的置信度
  float thres; //类别的默认阈值
} VideoClsType;



/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct VideoClsRet {
  // 下面只做举例，不同的算法需要单独设置
  VideoClsType* classes;//内存由sdk分配，由sdk释放
  int n_classes;
} VideoClsRet;

  /**
   * @brief 封装预测接口的返回值
   *
   * @note 不同的算法，可以在这里添加自己的自定义数据
   */
typedef struct VideoClsFeat {
    float* feat;//内存由sdk分配，由sdk释放
    int len_feat;
} VideoClsFeat;

/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return VideoCls_CreateHandle
 */
AILAB_EXPORT
int VideoCls_CreateHandle(VideoClsHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return VideoCls_LoadModel
 */
AILAB_EXPORT
int VideoCls_LoadModel(VideoClsHandle handle,
                       VideoClsModelType type,
                       const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return VideoCls_LoadModelFromBuff
 */
AILAB_EXPORT
int VideoCls_LoadModelFromBuff(VideoClsHandle handle,
                               VideoClsModelType type,
                               const char* mem_model,
                               int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return VideoCls_SetParamF
 */
AILAB_EXPORT
int VideoCls_SetParamF(VideoClsHandle handle,
                       VideoClsParamType type,
                       float value);


/**
 * @brief 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置的参数类型
 * @param value 设置参数的值
 * @return VideoCls_SetParamS
 */
AILAB_EXPORT
int VideoCls_SetParamS(VideoClsHandle handle,
                       VideoClsParamType type,
                       char* value);


/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT VideoCls_DO
 */
AILAB_EXPORT
int VideoCls_DO(VideoClsHandle handle,
                VideoClsArgs* args,
                VideoClsRet* ret);

/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT VideoCls_ReleaseHandle
 */
AILAB_EXPORT
int VideoCls_ReleaseHandle(VideoClsHandle handle);



/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT VideoCls_DbgPretty
 */
AILAB_EXPORT
int VideoCls_DbgPretty(VideoClsHandle handle);

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
  VideoClsFeat* VideoCls_InitFeat(VideoClsHandle handle);

  /**
   * @brief 释放返回值的内存
   *
   * @param handle 句柄
   * @param ret
   * @return C2_ReleaseRet
   */
  AILAB_EXPORT
  int VideoCls_ReleaseFeat(VideoClsFeat* ret);



/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT VideoCls_DO
 */
  AILAB_EXPORT
  int VideoCls_Extract(VideoClsHandle handle,
                       VideoClsArgs* args,
                       VideoClsFeat* feat);


  /**
   * @brief 算法的主要调用接口
   *
   * @param handle
   * @param args
   * @param ret
   * @return AILAB_EXPORT VideoCls_DO
   */
  AILAB_EXPORT
  int VideoCls_GetThres(VideoClsHandle handle,
                        VideoClsFeat* feat);


  int VideoCls_GetClassName(VideoClsHandle handle, int id, char const** name);



#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_VIDEOCLSAPI_H_
