#ifndef _SMASH_GENERALOBJECTDETECTIONAPI_H_
#define _SMASH_GENERALOBJECTDETECTIONAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

  // clang-format off
typedef void* GeneralObjectDetectionHandle;


/**
 * @brief 模型参数类型
 * kDetectShortSideLen: 检测模型输入图片的短边边长，值越大，小目标检测效果越好，初始值为128
 */
typedef enum GeneralObjectDetectionParamType {
  kDetectShortSideLen = 1,
} GeneralObjectDetectionParamType;


/**
 * @brief 模型枚举
 * kPureDetect: 仅做物体检测
 */
typedef enum GeneralObjectDetectionModelType {
  kPureDetect = 1,
} GeneralObjectDetectionModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 */
typedef struct GeneralObjectDetectionArgs {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
  // 此处可以添加额外的算法参数
} GeneralObjectDetectionArgs;

/**
 * @brief 物体信息
 * bbox:  物体在图片中的位置
 * label: 物体的类别，类别详情请联系：tianyuan@bytedance.com
 */
typedef struct ObjectInfo {
  AIRect bbox;
  int label;
} ObjectInfo;

/**
 * @brief 封装预测接口的返回值
 * obj_infos: 物体信息
 * obj_num:   物体数量
 */
typedef struct GeneralObjectDetectionRet {
  ObjectInfo *obj_infos;
  int obj_num;
} GeneralObjectDetectionRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return GeneralObjectDetection_CreateHandle
 */
AILAB_EXPORT
int GeneralObjectDetection_CreateHandle(GeneralObjectDetectionHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return GeneralObjectDetection_LoadModel
 */
AILAB_EXPORT
int GeneralObjectDetection_LoadModel(GeneralObjectDetectionHandle handle,
                         GeneralObjectDetectionModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return GeneralObjectDetection_LoadModelFromBuff
 */
AILAB_EXPORT
int GeneralObjectDetection_LoadModelFromBuff(GeneralObjectDetectionHandle handle,
                                 GeneralObjectDetectionModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return GeneralObjectDetection_SetParamF
 */
AILAB_EXPORT
int GeneralObjectDetection_SetParamF(GeneralObjectDetectionHandle handle,
                         GeneralObjectDetectionParamType type,
                         float value);


/**
 * @brief 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置的参数类型
 * @param value 设置参数的值
 * @return GeneralObjectDetection_SetParamS
 */
AILAB_EXPORT
int GeneralObjectDetection_SetParamS(GeneralObjectDetectionHandle handle,
                         GeneralObjectDetectionParamType type,
                         char* value);


/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT GeneralObjectDetection_DO
 */
AILAB_EXPORT
int GeneralObjectDetection_DO(GeneralObjectDetectionHandle handle,
                  GeneralObjectDetectionArgs* args,
                  GeneralObjectDetectionRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT GeneralObjectDetection_ReleaseHandle
 */
AILAB_EXPORT
int GeneralObjectDetection_ReleaseHandle(GeneralObjectDetectionHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT GeneralObjectDetection_DbgPretty
 */
AILAB_EXPORT
int GeneralObjectDetection_DbgPretty(GeneralObjectDetectionHandle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_GENERALOBJECTDETECTIONAPI_H_
