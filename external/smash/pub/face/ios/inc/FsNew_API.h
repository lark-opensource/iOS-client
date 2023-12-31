#ifndef _SMASH_FSNEWAPI_H_
#define _SMASH_FSNEWAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"
#include "FaceSDK_API.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

  // clang-format off
typedef void* FsNewHandle;

// 检测结果
typedef struct AIFsNewAllInfoRet {
  AIFaceInfoBase *base_infos;  // 检测到的基本的人脸信息，包含106点、动作、姿态
  AIFaceInfoExtra *extra_infos;  // 眼睛，眉毛，嘴唇、虹膜关键点等额外的信息
  int face_count;  // 检测到的人脸数目
} AIFsNewAllInfoRet, *PtrAIFsNewAllInfoRet;

//***************************** begin old-style API *****************/
//***************************** 与老人脸SDK API定义一致，前缀发生变化 *****************/

AILAB_EXPORT
int FsNew_CreateHandler(unsigned long long config, const char *param_path, FsNewHandle* out);

AILAB_EXPORT
int FsNew_CreateHandlerFromBuf(unsigned long long config, const char *param_buf, unsigned int param_buf_len, FsNewHandle *handle);

AILAB_EXPORT
int FsNew_AddExtraModel(FsNewHandle handle, unsigned long long config, const char *param_path);

AILAB_EXPORT
int FsNew_AddExtraModelFromBuf(FsNewHandle handle, unsigned long long config, const char *param_buf, unsigned int param_buf_len);

AILAB_EXPORT
int FsNew_ReloadBaseModel(unsigned long long config, const char *param_path, FsNewHandle handle);

AILAB_EXPORT
int FsNew_ReloadBaseModelBuf(unsigned long long config, const char *param_buf, unsigned int param_buf_len, FsNewHandle handle);

AILAB_EXPORT
int FsNew_ReloadExtraModel(FsNewHandle handle, unsigned long long config, const char *param_path);

AILAB_EXPORT
int FsNew_ReloadExtraModelFromBuf(FsNewHandle handle, unsigned long long config, const char *param_buf, unsigned int param_buf_len);

AILAB_EXPORT
int FsNew_AddExtraFastModel(FsNewHandle handle,
                         const char *param_path);

AILAB_EXPORT
int FsNew_AddExtraFastModelFromBuf(FsNewHandle handle,
                            const char *param_buf,
                                unsigned int param_buf_len);

AILAB_EXPORT
int FsNew_DoPredict(
    FsNewHandle handle,
    const unsigned char *image,
    PixelFormatType pixel_format,  // 图片格式，支持RGBA, BGRA, BGR, RGB,
                                   // GRAY(YUV暂时不支持)
    int image_width,               // 图片宽度
    int image_height,              // 图片高度
    int image_stride,              // 图片行跨度
    ScreenOrient orientation,      // 图片的方向
    unsigned long long detection_config,
    AIFaceInfo *p_face_info  // 存放结果信息，需外部分配好内存，需保证空间大于等于设置的最大检测人脸数；
);

AILAB_EXPORT
int FsNew_SetInitBbox(FaceHandle handle, AIRect *rect, int face_count);

AILAB_EXPORT
int FsNew_GetMouthMaskResult(FsNewHandle handle,
                          unsigned long long det_cfg,
                          AIMouthMaskInfo *mouthInfo);

AILAB_EXPORT
int FsNew_GetFaceOcclusionInfo(FsNewHandle handle, AIFaceOcclusionInfo *occinfo);

AILAB_EXPORT
int FsNew_GetTeenMaskResult(FsNewHandle handle,
                          unsigned long long det_cfg,
                          AITeenMaskInfo *teenInfo);

AILAB_EXPORT
int FsNew_GetFaceMaskResult(FsNewHandle handle,
                          unsigned long long det_cfg,
                          AIFaceMaskInfo *faceInfo);

AILAB_EXPORT
int FsNew_GetAllInfoResult(FsNewHandle handle,
                           AIFsNewAllInfoRet *allfaceInfo);

// 设置检测参数
AILAB_EXPORT int FsNew_SetParam(FsNewHandle handle,
                             fs_face_param_type type,
                             float value);

AILAB_EXPORT int FsNew_GetFrameFaceOrientation(const AIFaceInfoBase *result);

AILAB_EXPORT int FsNew_GetRuntimeInfo(FaceHandle handle, ModuleRunTimeInfo * result);

/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT FsNew_ReleaseHandle
 */
AILAB_EXPORT
void FsNew_ReleaseHandle(FsNewHandle handle);

//***************************** end old-style API *****************/

//***************************** begin new-style API *****************/
//***************************** 新定义了些API，简化调用 *****************/

typedef struct FsNewArgs {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
} FsNewArgs;

//***************************** end new-style API *****************/

//***************************** begin common API *****************/

typedef enum {
  kPerformanceAnalysis = 10,
  kUseLinearUpsample = 11,
  kKeepBboxInEdge = 12,
  kOnlyDetect = 13,
  kNumCircleInVideoForceDetectMode = 14,
  kNumCircleInImageMode = 15,
  kDetectorForce = 16,
  kAlwaysFirstFrameForVideo = 17,
  kOnly106det = 18,
  kOnly106base = 19,
  kOnly240 = 20,
  kDetectAllFaceInfo = 21
} FsNewParamType;

AILAB_EXPORT
int FsNew_SetParamF(FsNewHandle handle,
                    FsNewParamType type,
                    float value);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT FsNew_DbgPretty
 */
AILAB_EXPORT
int FsNew_DbgPretty(FsNewHandle handle);

//***************************** end common API *****************/

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_FSNEWAPI_H_
