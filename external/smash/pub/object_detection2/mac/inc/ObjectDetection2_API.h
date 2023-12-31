#ifndef _SMASH_OBJECTDETECTION2API_H_
#define _SMASH_OBJECTDETECTION2API_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

  // clang-format off
typedef void* ObjectDetection2Handle;


/**
 * @brief 模型参数类型
 *
 */
typedef enum ObjectDetection2ParamType {
  kObjectDetection2EdgeMode = 1,        ///< TODO: 根据实际情况修改
} ObjectDetection2ParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum ObjectDetection2ModelType {
  kObjectDetection2Model1 = 1,          ///< TODO: 根据实际情况更改

} ObjectDetection2ModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct ObjectDetection2Args {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
  // 此处可以添加额外的算法参数
} ObjectDetection2Args;


///**
// * @brief 封装预测接口的返回值
// *
// * @note 不同的算法，可以在这里添加自己的自定义数据
// */
//typedef struct ObjectDetection2Ret {
//  // 下面只做举例，不同的算法需要单独设置
//  unsigned char* alpha;        ///< alpha[i, j] 表示第 (i, j) 点的 mask 预测值，值位于[0, 255] 之间
//  int width;                   ///< 指定alpha的宽度
//  int height;                  ///< 指定alpha的高度
//} ObjectDetection2Ret;

/**
 * @brief 物体信息
 * bbox:  物体在图片中的位置
 * label: 物体的类别
 */
typedef struct ObjectDetection2ObjectInfo {
  AIRect bbox;
  float prob;
  int IR_label;
  int label;
  int obj_id;
} ObjectDetection2ObjectInfo;
  
/**
 * @brief 封装预测接口的返回值
 * obj_infos: 物体信息
 * obj_num:   物体数量
 */
typedef struct ObjectDetection2Ret {
  ObjectDetection2ObjectInfo *obj_infos;
  int obj_num;
} ObjectDetection2Ret;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return ObjectDetection2_CreateHandle
 */
AILAB_EXPORT
int ObjectDetection2_CreateHandle(ObjectDetection2Handle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return ObjectDetection2_LoadModel
 */
AILAB_EXPORT
int ObjectDetection2_LoadModel(ObjectDetection2Handle handle,
                         ObjectDetection2ModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return ObjectDetection2_LoadModelFromBuff
 */
AILAB_EXPORT
int ObjectDetection2_LoadModelFromBuff(ObjectDetection2Handle handle,
                                 ObjectDetection2ModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return ObjectDetection2_SetParamF
 */
AILAB_EXPORT
int ObjectDetection2_SetParamF(ObjectDetection2Handle handle,
                         ObjectDetection2ParamType type,
                         float value);



/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT ObjectDetection2_DO
 */
AILAB_EXPORT
int ObjectDetection2_DO(ObjectDetection2Handle handle,
                  ObjectDetection2Args* args,
                  ObjectDetection2Ret* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT ObjectDetection2_ReleaseHandle
 */
AILAB_EXPORT
int ObjectDetection2_ReleaseHandle(ObjectDetection2Handle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT ObjectDetection2_DbgPretty
 */
AILAB_EXPORT
int ObjectDetection2_DbgPretty(ObjectDetection2Handle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_OBJECTDETECTION2API_H_
