#ifndef _SMASH_AVATARUPPERBODY3DAPI_H_
#define _SMASH_AVATARUPPERBODY3DAPI_H_

#include "Skeleton_API.h"
#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

#define AI_MAX_SKELETON_NUM 2
#define AI_MAX_AVATAR_UPPERBODY_POINT_NUM 12

typedef void* AvatarUpperbody3DHandle;

/**
 * @brief 为算法推荐配置的算法参数，如CNN网络输入大小
 *
 */
struct AvatarUpperbody3DRecommendConfig {
  int InputWidth = 128;  ///< TODO: 根据实际情况修改
  int InputHeight = 224;
};

/**
 * @brief 模型参数类型
 *
 */
enum AvatarUpperbody3DParamType {
  kAvatarUpperbody3DEdgeMode = 1,  ///< TODO: 根据实际情况修改
};

/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
enum AvatarUpperbody3DModelType {
  kAvatarUpperbody3DModel1 = 1,  ///< TODO: 根据实际情况更改
};

/**
 * @brief 封装预测接口的输入数据
 *
 * @note 2D 人体关键点，skeleton模块的输出
 */
struct AvatarUpperbody3DArgs {
  bool has_skeleton;
  AIKeypoint keypoints[AI_MAX_SKELETON_NUM][KPOINT_NUM];
};

/**
 * @brief 封装预测接口的返回值
 *
 * @note 3D人体关键点
 */
struct AvatarUpperbody3DRet {
  float pose3d[AI_MAX_SKELETON_NUM][AI_MAX_AVATAR_UPPERBODY_POINT_NUM*3];
};

/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return AvatarUpperbody3D_CreateHandle
 */
AILAB_EXPORT
int AvatarUpperbody3D_CreateHandle(AvatarUpperbody3DHandle* out);

/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return AvatarUpperbody3D_LoadModel
 */
AILAB_EXPORT
int AvatarUpperbody3D_LoadModel(AvatarUpperbody3DHandle handle,
                                AvatarUpperbody3DModelType type,
                                const char* model_path);

/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return AvatarUpperbody3D_LoadModelFromBuff
 */
AILAB_EXPORT
int AvatarUpperbody3D_LoadModelFromBuff(AvatarUpperbody3DHandle handle,
                                        AvatarUpperbody3DModelType type,
                                        const char* mem_model,
                                        int model_size);

/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用
 * #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return AvatarUpperbody3D_SetParamF
 */
AILAB_EXPORT
int AvatarUpperbody3D_SetParamF(AvatarUpperbody3DHandle handle,
                                AvatarUpperbody3DParamType type,
                                float value);

/**
 * @brief 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用
 * #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置的参数类型
 * @param value 设置参数的值
 * @return AvatarUpperbody3D_SetParamS
 */
AILAB_EXPORT
int AvatarUpperbody3D_SetParamS(AvatarUpperbody3DHandle handle,
                                AvatarUpperbody3DParamType type,
                                char* value);

/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT AvatarUpperbody3D_DO
 */
AILAB_EXPORT
int AvatarUpperbody3D_DO(AvatarUpperbody3DHandle handle,
                         AvatarUpperbody3DArgs* args,
                         AvatarUpperbody3DRet* ret);

/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT AvatarUpperbody3D_ReleaseHandle
 */
AILAB_EXPORT
int AvatarUpperbody3D_ReleaseHandle(AvatarUpperbody3DHandle handle);

/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT AvatarUpperbody3D_DbgPretty
 */
AILAB_EXPORT
int AvatarUpperbody3D_DbgPretty(AvatarUpperbody3DHandle handle);

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif  // _SMASH_AVATARUPPERBODY3DAPI_H_
