#ifndef _SMASH_AVATAR3DAPI_H_
#define _SMASH_AVATAR3DAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

#define AI_AVATAR_JOINT_NUM 24 // 身体3D关键点个数
#define AI_AVATAR_SHAPE_COEFF_DIM 10 // 身体shape系数的维数
#define AI_AVATAR_ONE_HAND_JOINT_NUM 21 // 单个手3D关键点个数
#define AI_AVATAR_EXTENDED_JOINT_NUM 64 // 身体+双手3D关键点个数
#define AI_AVATAR_MAX_TARGET_NUM 5 // 所允许的最多目标个数
#define AI_AVATAR_INPUT_KEYPOINT2D_NUM 18 // 输入的2D关键点个数
#define AI_AVATAR_HEATMAP_KEYPOINT_NUM 27

// clang-format off
typedef void* Avatar3DHandle;


/**
 * @brief 模型参数类型
 *kAvatar3DWHOLEBODY: 0 upper body;   1 whole body
 */
typedef enum Avatar3DParamType {
  kAvatar3DWHOLEBODY = 0,        ///< TODO: 根据实际情况修改
  kAvatar3DWITHHANDS = 1,
  kAvatar3DMAXTARGETNUM = 2,
  kAvatar3DTARGETSPEFRAME = 3,
  kAvatar3DWRISTSCORETHRES = 4,
  kAvatar3DHSWRISTSCORETHRES = 5,
  kAvatar3DCHECKROOTINVERSE = 6,
  kAvatar3DTASKPERTICK = 7,
  kAvatar3DSMOOTHWINSIZE = 8,
  kAvatar3DSMOOTHORIGINSIGMAXY = 9,
  kAvatar3DSMOOTHORIGINSIGMAZ = 10,
  kAvatar3DWITHWRISTOFFSET = 11,
  kAvatar3DHANDPROBTHRES = 12,
  kAvatar3DCHECKWRISTROT = 13,
  kAvatar3DSMOOTHSIGMABETAS = 14,
  kAvatar3DFITTINGENABLE = 15,
  kAvatar3DFITTINGROOTENABLE = 16
} Avatar3DParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum Avatar3DModelType {
  kAvatar3DModel1 = 1,          ///< TODO: 根据实际情况更改
}Avatar3DModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct Avatar3DArgs {
  ModuleBaseArgs base;
  float points2d[AI_AVATAR_MAX_TARGET_NUM*AI_AVATAR_INPUT_KEYPOINT2D_NUM*2]; // 2D关键点位置
  int point_valid[AI_AVATAR_MAX_TARGET_NUM*AI_AVATAR_INPUT_KEYPOINT2D_NUM]; // 2D关键点是否有效
  int keypoint_num; // 2D关键点个数
  int target_num; // 目标个数
}Avatar3DArgs;

/**
 * @brief 封装Avatar3D单个目标信息的结构体
 *
 */
typedef struct Avatar3DTarget {
  float quaternion[AI_AVATAR_EXTENDED_JOINT_NUM*4]; // 3D关键点四元数
  float betas[10]; // blendshape系数
  float root[3]; // 根3D关键点在相机坐标下的位置
  float joints[AI_AVATAR_EXTENDED_JOINT_NUM*3]; // 3D关键点在相机坐标下的位置
  float scores[AI_AVATAR_EXTENDED_JOINT_NUM]; // 3D关键点的置信度，仅提供（L-shoulder, R-shoulder, L-elbow, R-elbow, L-wrist, R-wrist, L-knee, R-knee, L-ankle, R-ankle）10个3D关键点的置信度，其它点为默认值0
  float   joint_valid[AI_AVATAR_EXTENDED_JOINT_NUM]; // 关键点是否有效, whole_body下全为1, 非whole_body下半身3D关键点为0
  float heatmap_kpts_2d[AI_AVATAR_HEATMAP_KEYPOINT_NUM*2];
  float box[4]; // 输入网络的人体框
  int joint_num; // 3D关键点个数
  int tracking_id; // 目标id
  int new_target; // 是否是新目标
}Avatar3DTarget;

/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct Avatar3DRet {
  Avatar3DTarget targets[AI_AVATAR_MAX_TARGET_NUM]; // 目标列表
  int target_num; // 目标个数
  float focal_length; // 摄像机焦距
  int tracking; // 下一帧是tracking模式还是detect模式，detect模式下需要输入人体2D关键点坐标得到人体bbox，tracking模式下通过前一帧的3D关键点结果计算人体bbox
}Avatar3DRet;

/**
 * @brief 分配Avatar3DRet结构体内存
 *
 * @return Avatar3D_CreateRet
 */
AILAB_EXPORT
Avatar3DRet* Avatar3D_CreateRet();

/**
 * @brief 释放Avatar3DRet结构体内存
 *
 * @param result Avatar3DRet
 * @return Avatar3D_ReleaseRet
 */
AILAB_EXPORT
int Avatar3D_ReleaseRet(Avatar3DRet* result);

/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return Avatar3D_CreateHandle
 */
AILAB_EXPORT
int Avatar3D_CreateHandle(Avatar3DHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return Avatar3D_LoadModel
 */
AILAB_EXPORT
int Avatar3D_LoadModel(Avatar3DHandle handle,
                         Avatar3DModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return Avatar3D_LoadModelFromBuff
 */
AILAB_EXPORT
int Avatar3D_LoadModelFromBuff(Avatar3DHandle handle,
                                 Avatar3DModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return Avatar3D_SetParamF
 */
AILAB_EXPORT
int Avatar3D_SetParamF(Avatar3DHandle handle,
                         Avatar3DParamType type,
                         float value);

/**
* @brief set world coordinate
*
* @param handle 句柄
* @param value normal vectors pointing directions of right, up, backward under the world coordinate
* @return error code
* @value: 世界坐标系（正交），默认 [1,0,0,0,1,0,0,0,1]
* @right_or_left : 右手或左手系坐标，右手 0 （默认），左手 1.
*/
AILAB_EXPORT
int Avatar3D_SetWorldCoordinates(Avatar3DHandle handle,
                                const float value[9], const int right_or_left);

/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT Avatar3D_DO
 */
AILAB_EXPORT
int Avatar3D_DO(Avatar3DHandle handle, Avatar3DArgs* args, Avatar3DRet* ret);

/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT Avatar3D_ReleaseHandle
 */
AILAB_EXPORT
int Avatar3D_ReleaseHandle(Avatar3DHandle handle);

/**
 * @brief add hand result to body and return full-body result
 *
 * @param handle handle to module handler
 * @param hand_ids hand ids
 * @param extra_rotmat rotation matrix of hand joints
 * @param hand_probs probability that the hand really appears
 * @param hand_kpts 2d keypoints of hand
 * @param hand_num number of hands to add
 * @param ret pointer to the full-body result returned
 * @return AILAB_EXPORT Avatar3D_AddHands
 */
AILAB_EXPORT
int Avatar3D_AddHands(Avatar3DHandle handle,
                       const int* const hand_ids,
                       const float* const extra_rotmat,
                      const int* const hand_valids,
                      const float* const hand_probs,
                       const float* const hand_kpts,
                      const float* const wrist_kpt3d,
                       const int hand_num,
                      Avatar3DRet* ret);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

/**
 * @brief get boxes to be fed to Hand SDK for hand tracking
 *
 * @param handle handle to module handler
 * @param hand_ids hand ids returned
 * @param new_hand indicate if the hand is newly detected
 * @param hand_boxes hand boxes returned
 * @param left_probs probability that a hand is left rather than right
 * @param box_valid if the returned box is valid
 * @param box_num number of boxes
 * @return AILAB_EXPORT Avatar3D_ReleaseHandle
 */
AILAB_EXPORT
int Avatar3D_GetHandBoxes(Avatar3DHandle handle,
                          int* hand_ids,
                          int* new_hand,
                          float* hand_boxes,
                          float* left_probs,
                          int* box_valid,
                          int* box_num);

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_AVATAR3DAPI_H_
