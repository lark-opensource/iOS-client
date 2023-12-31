#ifndef _SMASH_ACTIONRECOGNITIONAPI_H_
#define _SMASH_ACTIONRECOGNITIONAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"
#include "Skeleton_API.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

// clang-format off
typedef void* ActionRecognitionHandle;

#define ACTIONRECOGNITION_MAX_TMPL_NUM 50
#define ACTIONRECOGNITION_MAX_CENTER_NUM 5
#define ACTIONRECOGNITION_MAX_TARGET_NUM 5

#define ACTIONRECOGNITION_BACKBONE_FEAT_DIM 6912
#define ACTIONRECOGNITION_HEATMAP_DIM 7344
#define ACTIONRECOGNITION_TMPL_FEAT_SIZE 768

/**
 * @brief 模型参数类型
 *
 */
typedef enum ActionRecognitionParamType {
  ActionRecognitionMode = 1,        ///< TODO: 根据实际情况修改
  ActionRecognitionVideoOrImageMode = 2,
} ActionRecognitionParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum ActionRecognitionModelType {
  kActionRecognitionScoringMode = 0,
  kActionRecognitionDetectionMode = 1,
} ActionRecognitionModelType;


/**
 * @brief 封装预测接口的输入数据
 * @brief backbone_feat, backbone特征
 * @brief backbone_feat_dim, backbone特征的维度
 * @brief heatmap, heatmap
 * @brief heatmap_dim, heatmap维度
 * @brief target_num, 输入人体的个数
 *
 */
typedef struct ActionRecognitionArgs {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
  // 此处可以添加额外的算法参数
  float* backbone_feat;
  int backbone_feat_dim;
  float* heatmap;
  int heatmap_dim;
  int target_num;
} ActionRecognitionArgs;


/**
 * @brief 封装预测接口的返回值
 *
 * @brief is_detected, 是否检测到人体
 * @brief target_num, 检测到人体的个数, 仅在打分模式下有效
 * @brief boxes, 人体bonding box列表, 仅在打分模式下有效
 * @brief keypoints, 关节点坐标列表, 仅在打分模式下有效
 * @brief track_ids, track ids列表, 尽在打分模式下有效
 * @brief is_valid, 是否有效列表，
 * @brief kpt_dists, 每一个关键点特征到中心的距离
 * @brief pose_scores, 人体姿态打分列表。
 * @brief output_labels, 输出姿态编号列表，没有检测到姿态，输出-1
 *
 */
typedef struct ActionRecognitionRet {
  bool is_detected;
  int target_num;
  AIRect* boxes;
  AIKeypoint *keypoints;
  int* track_ids;
  int* is_valid;
  float* kpt_dists;
  float* pose_scores;
  int* output_labels;
} ActionRecognitionRet;


/**
 * @brief 封装姿态模板数据
 *
 * @brief template_feats, 姿态模板特征
 * @brief template_num, 模板特征个数
 * @brief template_center_nums, 模版中心的个数
 * @brief kpt_weights, 关键点权重
 * @brief low_params, 用于score归一化的左边界值
 * @brief high_params, 用于score归一化的右边界值
 * @brief thresholds, 每一个姿态的响应阈值
 *
 */
typedef struct ActionRecognitionTemplate{
  float* template_feats;
  int template_num;
  int* template_center_nums;
  float* kpt_weights;
  float* low_params;
  float* high_params;
  float* thresholds;
} ActionRecognitionTemplate;

/**
 * @brief 从buffer中加载 ActionRecognitionTemplate
 *
 */
AILAB_EXPORT
ActionRecognitionTemplate* ActionRecognition_LoadTemplateFromBuff(ActionRecognitionHandle handle, const char* buffer, int buffer_size);

/**
 * @brief 释放 ActionRecognitionTemplate
 *
 */
AILAB_EXPORT
int ActionRecognition_FreeTemplateMemory(ActionRecognitionTemplate* tmpl);


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return ActionRecognition_CreateHandle
 */
AILAB_EXPORT
int ActionRecognition_CreateHandle(ActionRecognitionHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return ActionRecognition_LoadModel
 */
AILAB_EXPORT
int ActionRecognition_LoadModel(ActionRecognitionHandle handle,
                         ActionRecognitionModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return ActionRecognition_LoadModelFromBuff
 */
AILAB_EXPORT
int ActionRecognition_LoadModelFromBuff(ActionRecognitionHandle handle,
                                 ActionRecognitionModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return ActionRecognition_SetParamF
 */
AILAB_EXPORT
int ActionRecognition_SetParamF(ActionRecognitionHandle handle,
                         ActionRecognitionParamType type,
                         float value);

/**
 * @brief 设置模板特征相关参数
 * @param handle
 * @param template_feat, 姿态模板特征
 * @param template_num, 模板特征个数
 * @param template_center_num, 模版中心的个数
 * @param low_param, 用于score归一化的左边界值
 * @param high_param, 用于score归一化的右边界值
 * @param threshold, 姿态响应阈值
 *
 * @return AILAB_EXPORT ActionRecognition_SetTemplateParams
 */
AILAB_EXPORT
int ActionRecognition_SetTemplateParams(ActionRecognitionHandle handle,
                                        const float* template_feats,
                                        const int template_num,
                                        const int* template_center_nums,
                                        const float* kpt_weights,
                                        const float* low_params,
                                        const float* high_params,
                                        const float* thresholds);

/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT ActionRecognition_DO
 */
AILAB_EXPORT
int ActionRecognition_DO(ActionRecognitionHandle handle,
                  ActionRecognitionArgs* args,
                  ActionRecognitionRet* ret);

/**
 * @brief 设置SKeleton Handle
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT ActionRecognition_SetSkeletonHandle
 */
AILAB_EXPORT
int ActionRecognition_SetSkeletonHandle(ActionRecognitionHandle handle,
                                          SkeletonHandle sk_handle);

/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT ActionRecognition_ReleaseHandle
 */
AILAB_EXPORT
int ActionRecognition_ReleaseHandle(ActionRecognitionHandle handle);


AILAB_EXPORT
ActionRecognitionRet* ActionRecognition_MallocResultMemory(ActionRecognitionHandle handle);
    
AILAB_EXPORT
int ActionRecognition_FreeResultMemory(ActionRecognitionRet* ret);

/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT ActionRecognition_DbgPretty
 */
AILAB_EXPORT
int ActionRecognition_DbgPretty(ActionRecognitionHandle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_ACTIONRECOGNITIONAPI_H_
