//
//  ActionRecognition_ToB_API.hpp
//  smash_algo-action_recognition
//
//  Created by bytedance on 2021/7/7.
//

#ifndef ActionRecognition_ToB_API_h
#define ActionRecognition_ToB_API_h

#include "tt_common.h"
#include "ActionRecognition_API.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus


/**
 初始姿态类别
 */
typedef enum ActionRecognitionToBStartPoseType {
  kStand = 1,
  kLying = 2,
  kSitting = 3,
  kSideLeft = 4,
  kSideRight = 5
} ActionRecognitionToBStartPoseType;

/**
 反馈的身体部位类别
 */
typedef enum FeedbackBodyPart {
  kFeedbackNone = 0,
  kFeedbackLeftArm = 1,
  kFeedbackRightArm = 2,
  kFeedbackLeftLeg = 3,
  kFeedbackRightLeg = 4,
} FeedbackBodyPart;


AILAB_EXPORT
int ActionRecognitionToB_CreateHandle(ActionRecognitionHandle* out);

/**
 * @brief 动作计数
 * @param handle
 * @param actionrec_ret, 输入参数，ActionRecognition_Do返回的结构体
 * @param count_ret, 返回动作计数结果，如果当前帧计数到动作，返回1；否则返回0
 * @param clock_trigger, 返回是否触发计时器，如果计数接口检测到关键姿态，则clock_trigger返回true，需要重置外部计时器；否则返回false
 *
 * @return AILAB_EXPORT ActionRecognitionToB_Count
 */
AILAB_EXPORT
int ActionRecognitionToB_Count(ActionRecognitionHandle handle,
                               ActionRecognitionRet* actionrec_ret,
                               int& count_ret,
                               bool& clock_trigger);

/**
 * @brief 反馈接口
 * @param handle
 * @param actionrec_ret, 输入参数，ActionRecognition_Do返回的结构体
 * @param feedback_ret, 返回不规范的身体部位，身体部位类型参见FeedbackBodyPart枚举类型
 *
 * @return AILAB_EXPORT ActionRecognitionToB_Feedback
 */
AILAB_EXPORT
int ActionRecognitionToB_Feedback(ActionRecognitionHandle handle,
                               ActionRecognitionRet* actionrec_ret,
                               FeedbackBodyPart& feedback_ret);

/**
 * @brief 重置计数状态
 * @param handle
 *
 * @return AILAB_EXPORT ActionRecognitionToB_CountReset
 */
AILAB_EXPORT
int ActionRecognitionToB_CountReset(ActionRecognitionHandle handle);

/**
 * @brief 检测初始姿态
 * @param handle
 * @param type, 初始姿态类型，参见ActionRecognitionToBStartPoseType枚举类型
 * @param keypoints, 2D关键点位置
 * @param kpt_num, 2D关键点个数
 * @param image_width, 输入图片的宽
 * @param image_height, 输入图片的高
 * @param is_detected, 返回是否检测到指定类型的出事姿态
 *
 * @return AILAB_EXPORT ActionRecognitionToB_DetectStartPose
 */
AILAB_EXPORT
int ActionRecognitionToB_DetectStartPose(ActionRecognitionHandle handle,
                                         ActionRecognitionToBStartPoseType type,
                                         AIKeypoint *keypoints,
                                         const int kpt_num,
                                         const int image_width,
                                         const int image_height,
                                         bool& is_detected);

#ifdef __cplusplus
}
#endif  // __cplusplus

#endif /* ActionRecognition_ToB_API_h */
