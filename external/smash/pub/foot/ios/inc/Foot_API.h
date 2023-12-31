// -----------------------------------------------------
//  Created by zhuyongming@bytedance.com on 2020/6/3.
// -----------------------------------------------------

#ifndef _SMASH_FOOTAPI_H_
#define _SMASH_FOOTAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#define FOOT_MAX_FEET_NUM 2
#define FOOT_KEYPOINTS_NUM 66

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

// clang-format off
typedef void* FootHandle;


/**
 * @brief 模型参数类型
 *
 */
typedef enum FootParamType {
  UseMask = 1, // 是否使用mask
  delayMode = 2, // 是否启用延时模式，目前延时3帧
  kMotionPostProcess = 3, // 是否启用快速模式
  kDetectionInterval = 4,
} FootParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum FootModelType {
  FootJoints2dModel = 1, // 使用时请指定此值，以下的值暂时无用，请勿指定
  FootJoints3dModel = 2,
  FootDetectionModel = 3,
  FootFilterModel = 4,
  FootLeftRightModel = 5,
  FootLegSegModel = 6,
} FootModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct FootArgs {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
} FootArgs, *ptr_FootArgs;

typedef struct FootInfo{
  int id; // id
  AIRect box; // 脚框
  float left_prob; // 脚是左脚的概率
  bool is_left;  // 脚是否是左脚
  float foot_prob; // 是脚的概率

  struct TTKeyPoint joints2d[FOOT_KEYPOINTS_NUM]; // 脚的2d关键点，66x2
  struct TTKeyPoint3D shank_orient; // 小腿的朝向
  unsigned char* segment; // 目标腿部的分割
  unsigned char* segmentBro; // 非目标腿部的分割
  AIRect segment_box; // 腿部分割的框
  float trans[12]; // 脚的3d姿态的旋转矩阵，3x4
} FootInfo, *ptr_FootInfo;

/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct FootRet {
  FootInfo p_feet[FOOT_MAX_FEET_NUM]; // foot 信息
  int feet_count; // 检出的feet总数
  bool use_shank; // 是否采用虚拟小腿
  //unsigned char* debug_image;
  //float debugValue[1000];
  //int valueNum;
} FootRet, *ptr_FootResult;

    
/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return Foot_CreateHandle
 */
AILAB_EXPORT
int Foot_CreateHandle(FootHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return Foot_LoadModel
 */
AILAB_EXPORT
int Foot_LoadModel(FootHandle handle,
                   FootModelType type,
                   const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return Foot_LoadModelFromBuff
 */
AILAB_EXPORT
int Foot_LoadModelFromBuff(FootHandle handle,
                           FootModelType type,
                           const char* mem_model,
                           int model_size);


/**
 * @brief 配置 int/bool 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置的参数的值
 * @return Foot_SetParamF
 */
AILAB_EXPORT
int Foot_SetParamF(FootHandle handle, FootParamType type, int value);
  
/**
* @brief 设置分辨率，以得到正确旋转矩阵
*
* @param handle 句柄
* @param w 输入宽
* @param h 输入高
* @return Foot_SetParamF
*/
AILAB_EXPORT
int Foot_SetRenderResolution(FootHandle handle, int w, int h);

/**
 * @brief 算法的主要调用接口
 *
 * @param handle 句柄
 * @param args 输入参数
 * @param p_foot_result 结果
 * @return AILAB_EXPORT Foot_DO
 */
AILAB_EXPORT
int Foot_DO(FootHandle handle,
            FootArgs* args,
            FootRet* p_foot_result);

/**
 * @brief 计算脚部遮挡的调用接口
 *
 * @param handle 句柄
 * @param p_foot_result 算法计算结果
 * @param footIndex 脚的index
 * @param inner3D 鞋口的3D顶点
 * @param vertNum 鞋口的3D顶点的数量
 * @param imageWidth mask的宽
 * @param imageHeight mask的高
 * @param mask 计算结果
 */
AILAB_EXPORT
int Foot_GetMask(FootHandle handle,
                 FootRet* p_foot_result,
                 int footIndex,
                 TTKeyPoint3D* inner3D,
                 int vertNum,
                 int imageWidth,
                 int imageHeight,
                 unsigned char* mask);
/**
 * @brief 设置脚部检测区域的调用接口
 *
 * @param handle 句柄
 * @param detectionArea 检测区域的框
 * @param isValid 检测框是否有效
 */
AILAB_EXPORT
int Foot_SetDetectionArea(FootHandle handle,
                          AIRect detectionArea,
                          bool isValid);

/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle 句柄
 * @return AILAB_EXPORT Foot_ReleaseHandle
 */
AILAB_EXPORT
int Foot_ReleaseHandle(FootHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle 句柄
 * @return AILAB_EXPORT Foot_DbgPretty
 */
AILAB_EXPORT
int Foot_DbgPretty(FootHandle handle);

AILAB_EXPORT
FootRet* Foot_MallocResultMemory(FootHandle handle);
    
AILAB_EXPORT
int Foot_FreeResultMemory(FootRet * ret);


#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_FOOTAPI_H_
