#ifndef _SMASH_SKINSEGAPI_H_
#define _SMASH_SKINSEGAPI_H_

#include "FaceSDK_API.h"
#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus


// clang-format off
typedef void* SkinSegHandle;


/**
 * @brief SDK参数
 * kSkinSegEdgeMode:
 *    算法参数，用来设置边界的模式
 *    - 1: 不加边界
 *    - 2: 加边界
 * kSkinSegVideoMode:
 *    算法参数，用来设置视频/图片模式，默认设置为0
 *    - 0: 开启视频模式
 *    - 1: 开启图片模式
 * kSkinSegSmoothMode:
 *    算法参数，用来设置视频/图片模式，默认设置为0
 *    - 0: 关闭边缘优化模式
 *    - 1: 开启边缘优化模式
 */
typedef enum SkinSegParamType {
  kSkinSegEdgeMode = 1,
  kSkinSegVideoMode = 2,
  kSkinSegSmoothMode = 3
} SkinSegParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum SkinSegModelType {
  kSkinSegModel1 = 1
} SkinSegModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct SkinSegArgs {
  ModuleBaseArgs base;
  // 此处可以添加额外的算法参数
} SkinSegArgs;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 返回结果结构体，调用SkinSeg_MallocResultMemory申请内存，SkinSeg_FreeResultMemory释放
 */
typedef struct SkinSegRet {
  // 下面只做举例，不同的算法需要单独设置
  unsigned char* alpha;        ///< alpha[i, j] 表示第 (i, j) 点的 mask 预测值，值位于[0, 255] 之间
  int width;                   ///< 指定alpha的宽度
  int height;                  ///< 指定alpha的高度
} SkinSegRet;


/**
 * @brief 后处理操作参数，调用SkinSeg_PostProcess执行抠五官操作需要
 *
 */
typedef struct SkinSegPostInput {
  int img_w;                            // 原图宽
  int img_h;                            // 原图高
  AIFaceInfo face_info;                 // 人脸信息
  AIFaceMaskInfo facemask_info;         // 人脸遮挡信息
} SkinSegPostInput;


/**
 视频模式下，去除前面帧对当前帧的影响（注意此操作可能会降低当前帧的效果）

 @param handle SkinSegHandle句柄
 @return SMASH_OK
 */
AILAB_EXPORT
int SkinSeg_IgnorePreviousFrames(SkinSegHandle handle);


/**
 申请分割结果内存
 
 @param handle SkinSegHandle句柄
 @param ret 需要初始化的结果指针
 @return SMASH_OK
 */
AILAB_EXPORT
int SkinSeg_MallocResultMemory(SkinSegHandle handle, SkinSegRet *ret);


/**
 释放申请的内存
 
 @param skinseg_out调用SkinSeg_MallocResultMemory得到的SkinSegRet指针
 @return SMASH_OK
 */
AILAB_EXPORT
int SkinSeg_FreeResultMemory(SkinSegRet* skinseg_out);
    
    
/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return SkinSeg_CreateHandle
 */
AILAB_EXPORT
int SkinSeg_CreateHandle(SkinSegHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return SkinSeg_LoadModel
 */
AILAB_EXPORT
int SkinSeg_LoadModel(SkinSegHandle handle,
                         SkinSegModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return SkinSeg_LoadModelFromBuff
 */
AILAB_EXPORT
int SkinSeg_LoadModelFromBuff(SkinSegHandle handle,
                                 SkinSegModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return SkinSeg_SetParamF
 */
AILAB_EXPORT
int SkinSeg_SetParamF(SkinSegHandle handle,
                         SkinSegParamType type,
                         float value);


/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT SkinSeg_DO
 */
AILAB_EXPORT
int SkinSeg_DO(SkinSegHandle handle,
                  SkinSegArgs* args,
                  SkinSegRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT SkinSeg_ReleaseHandle
 */
AILAB_EXPORT
int SkinSeg_ReleaseHandle(SkinSegHandle handle);


/**
 * @brief 后处理
 * @param skin_mask 皮肤mask，原图大小
 * @param keypoints 人脸关键点
 * @param face_mask 人脸遮挡mask，原图大小
 * @param face_num  人脸数量
 * @param img_h     原图高
 * @param img_w     原图宽
 * @return AILAB_EXPORT SkinSeg_PostProcess
 */
AILAB_EXPORT
int SkinSeg_PostProcess(SkinSegHandle handle, SkinSegRet* ret, SkinSegPostInput* face_input);

    
/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT SkinSeg_DbgPretty
 */
AILAB_EXPORT
int SkinSeg_DbgPretty(SkinSegHandle handle);

AILAB_EXPORT
float SkinSeg_GetSkinParam(SkinSegHandle handle);
    
AILAB_EXPORT
int SKinSeg_SetInputShape(SkinSegHandle handle, int input_h, int input_w);
    
#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_SKINSEGAPI_H_
