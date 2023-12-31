#ifndef _SMASH_RECTDOCDETAPI_H_
#define _SMASH_RECTDOCDETAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

// clang-format off
typedef void* RectDocDetHandle;


/**
 * @brief 模型参数类型
 *
 */
typedef enum RectDocDetPreprocessType {
  kRectDocDetPreprocessTypeNN = 1,
  kRectDocDetPreprocessTypeCenterCut = 2,
} RectDocDetPreprocessType;

typedef enum RectDocDetIsVideoType {
  kRectDocDetIsVideoTypeYes = 1,
  kRectDocDetIsVideoTypeNo = 2,
} RectDocDetIsVideoType;

typedef enum RectDocDetParamType {
  kRectDocDetPreProcessMode = 1,        ///< TODO: 根据实际情况修改
  kRectDocDetIsVideoMode = 2,
  kRectDocDetAngleThr = 3,
} RectDocDetParamType;

typedef enum RectDocDetInternalStatus {
  kRectDocDetInternalStatus_SEARCHING = 1,
  kRectDocDetInternalStatus_MATCHED = 2,
  kRectDocDetInternalStatus_TRACKING = 3,
  kRectDocDetInternalStatus_INTERNAL_ERROR = -1,
  kRectDocDetInternalStatus_PARAMETER_ERROR = -2,
  kRectDocDetInternalStatus_UNKNOW_ERROR = -3,
} RectDocDetInternalStatus;

/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum RectDocDetModelType {
  kRectDocDetModel1 = 1,          ///< TODO: 根据实际情况更改
} RectDocDetModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct RectDocDetArgs {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
  // 此处可以添加额外的算法参数
} RectDocDetArgs;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */

// rectangle area in homogeneous coordinates
typedef struct RectDocDetTargetArea {
  float top_left_x;
  float top_left_y;
  float top_right_x;
  float top_right_y;
  float bottom_left_x;
  float bottom_left_y;
  float bottom_right_x;
  float bottom_right_y;
} RectDocDetTargetArea;

// ratio for the result
//   - ratio: width/height
//   - width_val/height_val: common ratio, like 4:3, 16:9, 210:297(A4);
//                           -1 for not common
// not implemented right now
typedef struct RectDocDetRatio {
  float ratio;
  int width_val;
  int height_val;
} RectDocDetRatio;



// buffer: reserved variable
typedef struct RectDocDetRet {
  RectDocDetInternalStatus status;
  RectDocDetTargetArea target_area;
  RectDocDetRatio rectangle_ratio;
  int buffer[1];
} RectDocDetRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return RectDocDet_CreateHandle
 */
AILAB_EXPORT
int RectDocDet_CreateHandle(RectDocDetHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return RectDocDet_LoadModel
 */
AILAB_EXPORT
int RectDocDet_LoadModel(RectDocDetHandle handle,
                         RectDocDetModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return RectDocDet_LoadModelFromBuff
 */
AILAB_EXPORT
int RectDocDet_LoadModelFromBuff(RectDocDetHandle handle,
                                 RectDocDetModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return RectDocDet_SetParamF
 */
AILAB_EXPORT
int RectDocDet_SetParamF(RectDocDetHandle handle,
                         RectDocDetParamType type,
                         float value);



/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT RectDocDet_DO
 */
AILAB_EXPORT
int RectDocDet_DO(RectDocDetHandle handle,
                  RectDocDetArgs* args,
                  RectDocDetRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT RectDocDet_ReleaseHandle
 */
AILAB_EXPORT
int RectDocDet_ReleaseHandle(RectDocDetHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT RectDocDet_DbgPretty
 */
AILAB_EXPORT
int RectDocDet_DbgPretty(RectDocDetHandle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_RECTDOCDETAPI_H_
