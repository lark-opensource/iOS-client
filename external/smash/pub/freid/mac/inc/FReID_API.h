#ifndef _SMASH_FREIDAPI_H_
#define _SMASH_FREIDAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"
#include "FaceSDK_API.h"
#define FREID_MAX_SUPPORT 10

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus 

// clang-format off
typedef void* FReIDHandle;


/**
 * @brief 模型参数类型
 *
 */
typedef enum FReIDParamType {
  kFReIDUseMode1 = 1,        ///<
  kFReIDUseMode2 = 2,        ///<
  kFReIDMaxSaved = 3,
} FReIDParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum FReIDModelType {
  kFReIDModel1 = 1,          ///< TODO: 根据实际情况更改
} FReIDModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct FReIDArgs {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
  AIFaceInfo *face_info;      ///< 原始图像上的人脸SDK检测结果
  bool is_force;
} FReIDArgs;

typedef struct AIFReIDInfoBase {
  int faceid; // 原始人脸SDK的id
  int trackid; // 带有人脸身份跟踪的id
} AIFReIDInfoBase;

/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct FReIDRet {
  AIFReIDInfoBase *track_items;
  int track_items_count;         ///< 当前结果中有效的track_infos的个数
  int track_items_alloced;       ///< 分配的track_infos个数
} FReIDRet;

typedef struct FReIDSeriaRet {
  void *buf;
  int buf_len;
} FReIDSeriRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return FReID_CreateHandle
 */
AILAB_EXPORT
int FReID_CreateHandle(FReIDHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return FReID_LoadModel
 */
AILAB_EXPORT
int FReID_LoadModel(FReIDHandle handle,
                         FReIDModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return FReID_LoadModelFromBuff
 */
AILAB_EXPORT
int FReID_LoadModelFromBuff(FReIDHandle handle,
                                 FReIDModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return FReID_SetParamF
 */
AILAB_EXPORT
int FReID_SetParamF(FReIDHandle handle,
                         FReIDParamType type,
                         float value);



/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT FReID_DO
 */
AILAB_EXPORT
int FReID_DO(FReIDHandle handle,
                  FReIDArgs* args,
                  FReIDRet* ret);

/**
 * @brief 序列化的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT FReID_DO
 */
AILAB_EXPORT
int FReID_Serialization(FReIDHandle handle, FReIDSeriRet* seriaRet);

AILAB_EXPORT
int FReID_DeSerialization(FReIDHandle handle, FReIDSeriRet* seriaRet);

/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT FReID_ReleaseHandle
 */
AILAB_EXPORT
int FReID_ReleaseHandle(FReIDHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT FReID_DbgPretty
 */
AILAB_EXPORT
int FReID_DbgPretty(FReIDHandle handle);

/**
 * @brief 为算法结果结构体申请空间, 如果空间是固定大小或者有上限的，可以无需传入参数
 *
 * @param width
 * @param height
 * @return AILAB_EXPORT FReID_MallocResultMemory
 */
AILAB_EXPORT
FReIDRet* FReID_MallocResultMemory(FReIDHandle handle, int num);

/**
 * @brief 释放算法输出结构体空间
 *
 * @param ret
 * @return AILAB_EXPORT FReID_FreeResultMemory
 */
AILAB_EXPORT
int FReID_FreeResultMemory(FReIDRet* ret);


////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_FREIDAPI_H_
