#ifndef _SMASH_FOREHEADSEGAPI_H_
#define _SMASH_FOREHEADSEGAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"
#include "FaceSDK_API.h"
#define FOREHEADSEG_ALIGN_FACE_KEY_POINT_NUM 106

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

  // clang-format off
typedef void* ForeheadSegHandle;


/**
 * @brief 模型参数类型
 *
 */
typedef enum ForeheadSegParamType {
  kForeheadSegEdgeMode = 1,        ///< TODO: 根据实际情况修改
} ForeheadSegParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum ForeheadSegModelType {
  kForeheadSegModel1 = 1,          ///< TODO: 根据实际情况更改
} ForeheadSegModelType;

    
/**
 * @brief 当前模块的输入
 *  包括： 1.输入的图像
 *        2.人脸sdk预测得到的106点信息，使用106点信息来对齐crop人脸
 */
typedef struct
{
    int face_id;
    AIPoint points[FOREHEADSEG_ALIGN_FACE_KEY_POINT_NUM];
} ForeheadSegFaceInfo;
typedef struct
{
    unsigned char* image;
    int image_width;
    int image_height;
    int image_stride;
    PixelFormatType pixel_format; // kPixelFormat_BGRA8888 或者 kPixelFormat_RGBA8888
    ScreenOrient orient;
    ForeheadSegFaceInfo* face_info; // 每个人脸的106点信息
    int face_count;
} ForeheadSegInput;
    
    
 /**
 * @brief 当前模块的返回值
 *
 */

// 单人的额头mask
typedef struct ForeheadMaskInfoBase {
    int forehead_mask_width;        // forehead_mask_width
    int forehead_mask_height;        // forehead_mask_height
    unsigned char *forehead_mask;  // forehead_mask[i, j] 表示第 (i, j) 点的 mask 预测值，值位于[0, 255] 之间
    float *warp_mat;           // warp mat data ptr, size 2*3， 表示转换到原图的矩阵
    int id;
} ForeheadMaskInfoBase, *PtrForeheadMaskInfoBase;
// 所有人（多人）的额头mask
typedef struct ForeheadSegResultInfo {
    ForeheadMaskInfoBase base_forehead_info[AI_MAX_FACE_NUM];
    int face_count;
} ForeheadSegResultInfo, *PtrForeheadSegResultInfo;

    
    

// 单人的 所有mask( facemask + 额头mask)
typedef struct BaseSegResultInfo {
    unsigned char *face_forehead_mask;
    int face_id;
    float *face_forehead_warp_mat;         // warp mat data ptr, size 2*3， 表示转换到原图的矩阵
    int face_forehead_mask_width;          // mask的宽
    int face_forehead_mask_height;         // mask的高
    } BaseSegResultInfo, *PtrBaseSegResultInfo;
// 所有人（多人）的 所有mask( facemask + 额头mask)
typedef struct AllSegResultInfo {
    BaseSegResultInfo base_all_mask[AI_MAX_FACE_NUM];
    int face_count;
} AllSegResultInfo, *PtrAllSegResultInfo;



/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return ForeheadSeg_CreateHandle
 */
AILAB_EXPORT
int ForeheadSeg_CreateHandle(ForeheadSegHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return ForeheadSeg_LoadModel
 */
AILAB_EXPORT
int ForeheadSeg_LoadModel(ForeheadSegHandle handle,
                         ForeheadSegModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return ForeheadSeg_LoadModelFromBuff
 */
AILAB_EXPORT
int ForeheadSeg_LoadModelFromBuff(ForeheadSegHandle handle,
                                 ForeheadSegModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return ForeheadSeg_SetParamF
 */
AILAB_EXPORT
int ForeheadSeg_SetParamF(ForeheadSegHandle handle,
                         ForeheadSegParamType type,
                         float value);



/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args  // 输入
 * @param ret    // 输出
 * @return AILAB_EXPORT ForeheadSeg_DO
 */
AILAB_EXPORT
int ForeheadSeg_DO(ForeheadSegHandle handle,
                  ForeheadSegInput* args,
                  ForeheadSegResultInfo* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT ForeheadSeg_ReleaseHandle
 */
AILAB_EXPORT
int ForeheadSeg_ReleaseHandle(ForeheadSegHandle handle);


AILAB_EXPORT
int ForeheadSeg_DbgPretty(ForeheadSegHandle handle);

/**
 * @brief 申请结果的内存
 *
 * @param handle
 * @return AILAB_EXPORT ForeheadSeg_MallocResultMemory
 */
AILAB_EXPORT
ForeheadSegResultInfo* ForeheadSeg_MallocResultMemory(ForeheadSegHandle handle);

AILAB_EXPORT
// 申请 额头mask + 眉毛下方区域mask的结果内存
AllSegResultInfo*  ForeheadSeg_MallocAllSegResultsMemory(ForeheadSegHandle handle);
    
AILAB_EXPORT
int ForeheadSeg_GetALLfaceMask(ForeheadSegHandle handle, ForeheadSegResultInfo* ForeHeadSegResult, AIFaceMaskInfo facemask_info,  AllSegResultInfo* allSegResults);


AILAB_EXPORT
// 释放额头分割的内存
int ForeheadSeg_Free_ForeheadSegResult_Memory(ForeheadSegResultInfo*  ForeHeadSegResult);

AILAB_EXPORT
// 释放全脸分割的内存 （额头分割 + 下半脸分割）
int ForeheadSeg_Free_AllSegResult_Memory(AllSegResultInfo*  allSegResults);



////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_FOREHEADSEGAPI_H_
