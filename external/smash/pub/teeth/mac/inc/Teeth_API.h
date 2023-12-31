#ifndef _SMASH_TEETHAPI_H_
#define _SMASH_TEETHAPI_H_

#include "FaceSDK_API.h"
#include "smash_module_tpl.h"
#include "tt_common.h"
#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

#define AI_MAX_FACE_NUM_IN_TEETH AI_MAX_FACE_NUM
#define TEETH_ALIGN_FACE_KEY_POINT_NUM 106
#define TEETH_POINT_NUM 8
#define TEETH_NET_INPUT 112
// 原始thred
//#define TEETH_THRED_VIS_L 18
//#define TEETH_THRED_VIS_S 16
// thred 2
//#define TEETH_THRED_VIS_L 21
//#define TEETH_THRED_VIS_S 19
// thred 3
#define TEETH_THRED_VIS_L 20
#define TEETH_THRED_VIS_S 19

  typedef void* TeethHandle;

  typedef struct TeethConfig
  {
    int m_escale_teeth;
  } TeethConfig; // todo 添加平滑参数

  typedef struct
  {
    int face_id;
    AIPoint points[TEETH_ALIGN_FACE_KEY_POINT_NUM];
  } TeethFaceInfo;

  typedef struct
  {
    int face_id;
    AIPoint teeth_pts[TEETH_POINT_NUM]; // 牙齿关键点一共8个点
  } TeethFaceResult;

  typedef struct
  {
    unsigned char* image;
    int image_width;
    int image_height;
    int image_stride;
    PixelFormatType pixel_format; // kPixelFormat_BGRA8888 或者 kPixelFormat_RGBA8888
    ScreenOrient orient;
    TeethFaceInfo* face_info;
    int face_count;
  } TeethInput;

  typedef struct
  {
    TeethFaceResult teeth_result[AI_MAX_FACE_NUM_IN_TEETH];
    int face_count;
  } TeethOutput;

  // teeth 相关的模型选择，暂时没有用到 有些模块可能有多个模型
  typedef enum TeethModelType
  {
    kTeethModel1 = 1, ///< TODO: 根据实际情况更改
  } TeethModelType;
  // teeth 相关参数
  typedef enum TeethParamType
  {
    kTeethEdgeMode = 1, ///< TODO: 根据实际情况修改
  } TeethParamType;
  // teeth 相关参数设置
  AILAB_EXPORT
  int Teeth_SetParamF(TeethHandle handle, TeethParamType type, float value);

  AILAB_EXPORT
  int Teeth_CreateHandle(TeethHandle* out);
  // 新增申请内存。check
  AILAB_EXPORT
  TeethOutput* Teeth_MallocResultMemory(TeethHandle handle);
  AILAB_EXPORT
  int Teeth_FreeResultMemory(TeethOutput* teeth_result);
  // ***********************check

  AILAB_EXPORT
  int Teeth_LoadModel(TeethHandle handle, TeethModelType type, const char* model_path);
  AILAB_EXPORT
  int Teeth_LoadModelFromBuff(TeethHandle handle, TeethModelType type, const char* mem_model, int model_size);

  AILAB_EXPORT
  int Teeth_DoPredict(TeethHandle teethhandle, TeethInput* input_info, TeethOutput* p_teeth_info);

  AILAB_EXPORT
  int Teeth_ReleaseHandle(TeethHandle handle);

#ifdef __cplusplus
}
#endif // __cplusplus

#endif // _SMASH_TEETHAPI_H_
