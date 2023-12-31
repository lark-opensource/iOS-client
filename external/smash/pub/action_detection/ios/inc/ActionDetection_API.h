#ifndef __ACTION_DETECTION2_API_h__
#define __ACTION_DETECTION2_API_h__

#include "tt_common.h"

#if defined __cplusplus
extern "C" {
#endif
// wiki ref : https://wiki.bytedance.net/pages/viewpage.action?pageId=240239121

typedef void *ActionDetectionHandle;

#define NumActionTypes 8
#define NumModelTypes 2
#define NumKeyPoint 18
// clang-format off
typedef enum ActionTypes {
  LeftStrong     = 0x00000001,
  RightStrong    = 0x00000002,
  TShape         = 0x00000004,
  LeftSwag       = 0x00000008,
  RightSwag      = 0x00000010,
  LeftMoe        = 0x00000020,
  RightMoe       = 0x00000040,
  WaveHand       = 0x00000080,
  Stomping       = 0x00000100,
  PushingOutward = 0x00000200,
  LeftHalfHeart  = 0x00000400,
  RightHalfHeart = 0x00000800,
} ActionTypes;

/*
 * @brief: 模型类别，目前支持两种静态模型和系列模型
**/
typedef enum ModelTypes {
  StaticModel    = 0x00000001,
  SequenceModel  = 0x00000002,
} ModelTypes;

/*
 * @brief 创建句柄
* */
AILAB_EXPORT
int AD_CreateHandler(ActionDetectionHandle *handle);

/*
 * @brief 初始化模型
 * @param model_path 模型路径
 * @param type 模型类别，ModelTypes 之一
 */
AILAB_EXPORT
int AD_InitModel(ActionDetectionHandle handle,
                 char *model_path,
                 ModelTypes type);

/*
 * @brief 初始化模型
 * @param model_buf 模型数据
 * @param buf_len 模型长度（in bytes）
 * @param type 模型类别，ModelTypes 之一
 */
AILAB_EXPORT
int AD_InitModelFromBuf(ActionDetectionHandle handle,
                        char *model_buf,
                        unsigned int buf_len,
                        ModelTypes type);

/*
 * @brief 输入数据结构
 * @param keypoints 人体关键点信息
 * @param request_type 请求为ModelType枚举变量的与
 * @note request_type 按需调用，可以节约时间；调用方保证要调的模型已经初始化过
**/
typedef struct ActionInput {
  TTKeyPoint keypoints[NumKeyPoint];
  long long request_type;
} ActionInput;

/*
 * @breif 返回结构体
 * @param result 为ActionType 检测到的动作枚举的与操作
 */
typedef struct ActionOutput {
  long long result;
} ActionOutput;

/*
 * @brief 进行动作检测
 * @param ptr_input 输入结构指针
 * @param ptr_input 返回结构指针
 */
AILAB_EXPORT
int AD_DoActionDetection(ActionDetectionHandle handle,
                         ActionInput *ptr_input,
                         ActionOutput *ptr_output);

/*
 *@brief 释放句柄
 */
AILAB_EXPORT
int AD_ReleaseHandle(ActionDetectionHandle handle);

#if defined __cplusplus
};
#endif
// clang-format on
#endif
