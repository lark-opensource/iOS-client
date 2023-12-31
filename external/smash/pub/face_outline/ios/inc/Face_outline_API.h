#ifndef _SMASH_FACE_OUTLINEAPI_H_
#define _SMASH_FACE_OUTLINEAPI_H_

#include "FaceSDK_API.h"
#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus
#define BASE_ALIGN_FACE_POINT_NUM 106
#define FACE_OUTLINE_NUM_CUR 88  // 44理想点+44实际点  目前模型只预测88点，之后升级会新增4个点，增在最后4位
#define FACE_OUTLINE_NUM_FINAL 92  //完善的92新轮廓点 前88是 44理想点+44实际点  +2（14/15中点）+2 （30/29中点）（预留出接口，理想点和实际点各增2 ）
#define AI_MAX_FACE_NUM_THIS_MODULE AI_MAX_FACE_NUM
#define Face_Outline_NET_INPUT 120

  AILAB_EXPORT
  typedef void* Face_outline_Handle;
  // 设置平滑参数
  typedef struct AILAB_EXPORT Face_outline_Config
  {
    int m_escale_outline;
  } Face_outline_Config;
  // faceSDK预测得到的人脸106关键点，用来对齐
  typedef struct AILAB_EXPORT FaceBaseInfo
  {
    int face_id;
    AIPoint points[BASE_ALIGN_FACE_POINT_NUM];
  } FaceBaseInfo;

  typedef struct AILAB_EXPORT
  {
    unsigned char* image;
    int image_width;
    int image_height;
    int image_stride;
    PixelFormatType pixel_format; // kPixelFormat_BGRA8888 或者 kPixelFormat_RGBA8888
    ScreenOrient orient;
    FaceBaseInfo* faceBase_info;
    int face_count;
  } Face_outline_Input;
  // 单独一个人的轮廓点预测结果
  typedef struct AILAB_EXPORT
  {
    int face_id;
    AIPoint face_outline_pts[FACE_OUTLINE_NUM_FINAL]; // 人脸新轮廓点92个点： 包括44理想点/44实际点/4预留接口
  } Face_outline_Single_Result;

  // 当前图像所有人的轮廓点预测结果
  // 最终输出到外部
  typedef struct AILAB_EXPORT
  {
    Face_outline_Single_Result all_face_outline_result[AI_MAX_FACE_NUM_THIS_MODULE];
    int face_count;
  } Face_outline_Output;

  //  模型参数类型
  enum Face_outlineParamType
  {
    kFace_outlineEdgeMode = 1,
  };

  // @brief 相关的模型选择，暂时没有用到 有些模块可能有多个模型

  enum Face_outlineModelType
  {
    kFace_outlineModel1 = 1, ///< TODO: 根据实际情况更改
  };

  // 申请预测结果内存
  AILAB_EXPORT
  Face_outline_Output* Face_outline_MallocResultMemory(Face_outline_Handle handle);

  // 退出释放结果内存
  AILAB_EXPORT
  int Face_outline_FreeResultMemory(Face_outline_Output* p_face_outline_info);

  // 创建句柄

  AILAB_EXPORT
  int Face_outline_CreateHandle(Face_outline_Handle* out);

  // 从文件路径加载模型
  AILAB_EXPORT
  int Face_outline_LoadModel(Face_outline_Handle handle, Face_outlineModelType type, const char* model_path);

  // 加载模型（从内存中加载，Android 推荐使用该接口）
  AILAB_EXPORT
  int Face_outline_LoadModelFromBuff(Face_outline_Handle handle,
                                     Face_outlineModelType type,
                                     const char* mem_model,
                                     int model_size);

  /**
   * @param handle 句柄
   * @param type 设置参数的类型
   * @param value 设置参数的值
   * @return Face_outline_SetParamF
   */
  AILAB_EXPORT
  int Face_outline_SetParamF(Face_outline_Handle handle, Face_outlineParamType type, float value);

  // 预测模型
  AILAB_EXPORT
  int Face_outline_DO(Face_outline_Handle handle,
                      Face_outline_Input* input_info,
                      Face_outline_Output* p_face_outline_info);

  // 销毁句柄，释放资源
  AILAB_EXPORT
  int Face_outline_ReleaseHandle(Face_outline_Handle handle);

#ifdef __cplusplus
}
#endif // __cplusplus

#endif // _SMASH_FACE_OUTLINEAPI_H_
