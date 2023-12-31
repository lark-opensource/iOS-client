#ifndef __ANIMOJI_H_API_H__
#define __ANIMOJI_H_API_H__
#include "tt_common.h"
#if defined __cplusplus
extern "C" {
#endif

typedef void *AnimojiHandle;
const static int TT_ANIMOJI_MAX_FACE_LIMIT = 10;  // 最大支持人脸数


typedef struct AIAnimojiInfo {
  float alpha[AM_U_DIM];
  float beta[AM_E_DIM];
  float landmarks[240*2];
  float rot[3];
  float mvp[16];
  float mv[16];
  float affine_mat[9];
  int succ;
  int face_id;
} AIAnimojiInfo, *PtrAIAnimojiInfo;

AILAB_EXPORT
int AM_CreateHandler(unsigned int config, AnimojiHandle *handle);

AILAB_EXPORT
int AM_SetParamsFromSingleFile(AnimojiHandle handle,
                                  const char *res_path,
                                  int net_input_width,
                                  int net_input_height);

AILAB_EXPORT
int AM_SetParamsFromBuf(AnimojiHandle handle,
                           const char *model_buf,
                           unsigned int model_buf_len,
                           int net_input_width,
                           int net_input_height);



AILAB_EXPORT
int AM_FaceDetectAndDoPredit(
    AnimojiHandle handle,
    unsigned char *image,
    PixelFormatType pixel_format,
    int image_width,
    int image_height,
    int image_stride,
    ScreenOrient orientation,
    AIAnimojiInfo *p_animoji_info // out p_animoji_info
);

AILAB_EXPORT
int AM_FaceDetectAndDoPreditWOFD(
    AnimojiHandle handle,
    unsigned char *image,
    PixelFormatType pixel_format,
    int image_width,
    int image_height,
    int image_stride,
    ScreenOrient orientation,
    int face_count,
    int id[TT_ANIMOJI_MAX_FACE_LIMIT],
    float landmark106[TT_ANIMOJI_MAX_FACE_LIMIT][212],
    AIAnimojiInfo *p_animoji_info // out p_animoji_info
);

AILAB_EXPORT
void AM_SetEscale(
    AnimojiHandle handle,
    int escale
);
/*
 *@brief 释放句柄
 *param: handle 句柄
 */
AILAB_EXPORT
void AM_ReleaseHandle(AnimojiHandle handle);

#if defined __cplusplus
};
#endif

#endif
