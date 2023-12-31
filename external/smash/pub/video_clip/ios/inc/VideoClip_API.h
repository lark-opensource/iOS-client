#ifndef _SMASH_VIDEOCLIPAPI_H_
#define _SMASH_VIDEOCLIPAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

  // clang-format off
typedef void* VideoClipHandle;


/**
 * @brief 模型参数类型
 *
 */
typedef enum VideoClipParamType {
  CLIP_THRES,
} VideoClipParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum VideoClipModelType {
  kVideoClipModel1 = 1,          ///< TODO: 根据实际情况更改
} VideoClipModelType;



/**
* @brief 封装一个视频片段
*
* @note 不同的算法，可以在这里添加自己的数据
*/
typedef struct VideoClipCut{
  int start; //开始的帧号
  int end; //结束的帧号
} VideoClipCut;

/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct VideoClipArgs {
  float* embeds;   // similarity模块得到的浮点特征
  int is_last; //是否为最后一帧
} VideoClipArgs;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct VideoClipRet {
  // 下面只做举例，不同的算法需要单独设置
  VideoClipCut* cuts; //内存由sdk分配，调用VideoClip_ReleaseRet接口释放
  int n_cuts; //视频片段的数量
} VideoClipRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return VideoClip_CreateHandle
 */
AILAB_EXPORT
int VideoClip_CreateHandle(VideoClipHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return VideoClip_LoadModel
 */
AILAB_EXPORT
int VideoClip_LoadModel(VideoClipHandle handle,
                         VideoClipModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return VideoClip_LoadModelFromBuff
 */
AILAB_EXPORT
int VideoClip_LoadModelFromBuff(VideoClipHandle handle,
                                 VideoClipModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return VideoClip_SetParamF
 */
AILAB_EXPORT
int VideoClip_SetParamF(VideoClipHandle handle,
                         VideoClipParamType type,
                         float value);


/**
 * @brief 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置的参数类型
 * @param value 设置参数的值
 * @return VideoClip_SetParamS
 */
AILAB_EXPORT
int VideoClip_SetParamS(VideoClipHandle handle,
                        VideoClipParamType type,
                        char* value);

  /**
   * @brief 释放返回值的内存
   *
   * @param handle 句柄
   * @param ret
   * @return C2_ReleaseRet
   */
  AILAB_EXPORT
  int VideoClip_ReleaseRet(VideoClipHandle handle,VideoClipRet* ret);



/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT VideoClip_DO
 */
AILAB_EXPORT
int VideoClip_DO(VideoClipHandle handle,
                 VideoClipArgs* args,
                 VideoClipRet* ret);




/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT VideoClip_ReleaseHandle
 */
AILAB_EXPORT
int VideoClip_ReleaseHandle(VideoClipHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT VideoClip_DbgPretty
 */
AILAB_EXPORT
int VideoClip_DbgPretty(VideoClipHandle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

/**
* @brief 释放资源
*
* @param handle
* @return AILAB_EXPORT VideoClip_ReleaseRet
*/
AILAB_EXPORT
int VideoClip_ReleaseRet(VideoClipHandle handle,
                         VideoClipRet* ret);



#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_VIDEOCLIPAPI_H_
