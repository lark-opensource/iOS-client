#ifndef _SMASH_HAVATARAPI_H_
#define _SMASH_HAVATARAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

// clang-format off
typedef void* HAvatarHandle;

#define HAVATAR_MAX_HAND_NUM 2
#define HAVATAR_MAX_HAND_NUM_FOR_AVATAR3D 10
#define HAVATAR_KEY_POINT_2D_NUM 22
#define HAVATAR_KEY_POINT_3D_NUM 21

typedef struct HAvatarInfo {
  int id;
  float rect[4];                                      /// 手框 (x, y, w, h)  默认: 0
  float hand_prob;                                    /// 为手的概率 默认: 0
  int hand_valid;                                     /// 手结果是否有效,  与Avatar3D联合调用时使用 1有效，0无效 默认:0
  float left_prob;                                    /// 左手的概率 默认: 0
  unsigned int action;                                /// 手部动作, 默认: 99
  float pose_prob;                                    /// 姿态置信度 默认: 0  (预留接口, 请勿使用)
  float quaternion[HAVATAR_KEY_POINT_3D_NUM][4];      /// 每个关节点旋转四元数 ( w, x, y, z)  默认: 0
  float shape[10];                                    /// 3D手形状参数 默认: 0  (预留接口, 请勿使用)
  float root[3];                                      /// 根节点在相机坐标下的位置向量  默认: 0
  float kpt2d[HAVATAR_KEY_POINT_2D_NUM][2];           /// 2D关键点坐标 默认: 0
  float kpt2d_prob[HAVATAR_KEY_POINT_2D_NUM];         /// 2D关键点置信度  默认: 0
  float kpt3d[HAVATAR_KEY_POINT_3D_NUM][3];           /// 3D关键点坐标 默认: 0
  float kpt3d_prob[HAVATAR_KEY_POINT_3D_NUM];         /// 3D关键点置信度  默认: 0  (预留接口, 请勿使用)
  unsigned char *mask;                                /// 手分割mask 取值范围 0～255 默认: nullptr   (预留接口, 请勿使用)
  int mask_width;                                     /// mask宽 默认: 0  (预留接口, 请勿使用)
  int mask_height;                                    /// mask高 默认: 0  (预留接口, 请勿使用)
} HAvatarInfo, *ptr_HAvatarInfo;


/**
 * @brief 模型参数类型
 *
 */
typedef enum HAvatarParamType {
  HAVATAR_PARAM_MAX_HAND_NUM = 1,           /// 设置最多的手的个数，默认为2
  HAVATAR_PARAM_DELAY_FRAME_CNT = 2,        /// 设置算法结果延迟输出，默认延迟3帧
  HAVATAR_PARAM_MOTION_POSTPROC = 3,        /// 设置是否运动估计后处理，默认开启
  HAVATAR_PARAM_CAM_FOVY = 4,               /// 设置相机fovy参数，默认7.33
  HAVATAR_PARAM_WITH_AVATAR3D = 5,          /// 设置是否开启与Avatar3D联合调用，默认关闭
} HAvatarParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum HAvatarModelType {
  HAVATAR_MODEL_DETECT = 0x0001,            /// 手检测模型
  HAVATAR_MODEL_TRACK = 0x0002,             /// 手跟踪模型
  HAVATAR_MODEL_LR_BOX = 0x0004,            /// 左右手框回归模型
  HAVATAR_MODEL_ACTION_CLS = 0x0008,        /// 手势分类模型
  HAVATAR_MODEL_LR_CLS = 0x0010,            /// 左右手分类模型
  HAVATAR_MODEL_POSE = 0x0020,              /// 手姿态估计模型
} HAvatarModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct HAvatarArgs {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
  // 此处可以添加额外的算法参数
  int box_num;                                             /// number of boxes
  float hand_boxes[HAVATAR_MAX_HAND_NUM_FOR_AVATAR3D*4];   /// hand boxes returned
  int hand_ids[HAVATAR_MAX_HAND_NUM_FOR_AVATAR3D];         /// hand ids returned
  int new_hand[HAVATAR_MAX_HAND_NUM_FOR_AVATAR3D];         /// indicate if the hand is newly detected
  float left_probs[HAVATAR_MAX_HAND_NUM_FOR_AVATAR3D];     /// probability that a hand is left rather than right
  int box_valid[HAVATAR_MAX_HAND_NUM_FOR_AVATAR3D];        /// if the returned box is valid
} HAvatarArgs;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct HAvatarRet {
  HAvatarInfo havatars[HAVATAR_MAX_HAND_NUM_FOR_AVATAR3D];       /// 单只手的信息
  int hand_count;                                                /// 检测到的手部数目，havatars数组中只有前hand_count个结果是有效的；
} HAvatarRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return HAvatar_CreateHandle
 */
AILAB_EXPORT
int HAvatar_CreateHandle(HAvatarHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return HAvatar_LoadModel
 */
AILAB_EXPORT
int HAvatar_LoadModel(HAvatarHandle handle,
                      HAvatarModelType type,
                      const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return HAvatar_LoadModelFromBuff
 */
AILAB_EXPORT
int HAvatar_LoadModelFromBuff(HAvatarHandle handle,
                              HAvatarModelType type,
                              const char* mem_model,
                              int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return HAvatar_SetParamF
 */
AILAB_EXPORT
int HAvatar_SetParamF(HAvatarHandle handle,
                      HAvatarParamType type,
                      float value);


/**
 * @brief 算法的主要调用接口
 *
 * @param handle 句柄
 * @param args 输入算法参数
 * @param ret 算法结果
 * @return AILAB_EXPORT HAvatar_DO
 */
AILAB_EXPORT
int HAvatar_DO(HAvatarHandle handle,
               HAvatarArgs* args,
               HAvatarRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle 句柄
 * @return AILAB_EXPORT HAvatar_ReleaseHandle
 */
AILAB_EXPORT
int HAvatar_ReleaseHandle(HAvatarHandle handle);


/**
 * @brief 为算法结果结构体申请空间, 如果空间是固定大小或者有上限的，可以无需传入参数
 *
 * @param handle 句柄
 * @return AILAB_EXPORT HAvatar_MallocResultMemory
 */
AILAB_EXPORT
HAvatarRet* HAvatar_MallocResultMemory(HAvatarHandle handle);


/**
 * @brief 释放算法输出结构体空间
 *
 * @param ret 算法结果结构体
 * @return AILAB_EXPORT HAvatar_FreeResultMemory
 */
AILAB_EXPORT
int HAvatar_FreeResultMemory(HAvatarRet* ret);


////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_HAVATARAPI_H_
