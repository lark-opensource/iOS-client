#ifndef __AVATARDRIVE_H_API_H__
#define __AVATARDRIVE_H_API_H__
#include "tt_common.h"
#if defined __cplusplus
extern "C" {
#endif

typedef void *AvatarDriveHandle;
const static int TT_AVATAR_DRIVE_MAX_FACE_LIMIT = 10;  // 最大支持人脸数

#define ADM_E_DIM 52
#define ADM_U_DIM 75

typedef struct AIAvatarDriveInfo {
  float alpha[ADM_U_DIM];
  float beta[ADM_E_DIM];
  float landmarks[240*2];
  float rot[3];
  float mvp[16];
  float mv[16];
  float affine_mat[9];
  int succ;
  int face_id;
} AIAvatarDriveInfo, *PtrAIAvatarDriveInfo;

AILAB_EXPORT
int ADM_CreateHandler(unsigned int config, AvatarDriveHandle *handle);

AILAB_EXPORT
int ADM_SetParamsFromSingleFile(AvatarDriveHandle handle,
                                  const char *res_path,
                                  int net_input_width,
                                  int net_input_height);

AILAB_EXPORT
int ADM_SetParamsFromBuf(AvatarDriveHandle handle,
                           const char *model_buf,
                           unsigned int model_buf_len,
                           int net_input_width,
                           int net_input_height);



AILAB_EXPORT
int ADM_FaceDetectAndDoPredit(
    AvatarDriveHandle handle,
    unsigned char *image,
    PixelFormatType pixel_format,
    int image_width,
    int image_height,
    int image_stride,
    ScreenOrient orientation,
    AIAvatarDriveInfo *p_avatarDrive_info // out p_avatarDrive_info
);

AILAB_EXPORT
int ADM_FaceDetectAndDoPreditWOFD(
    AvatarDriveHandle handle,
    unsigned char *image,
    PixelFormatType pixel_format,
    int image_width,
    int image_height,
    int image_stride,
    ScreenOrient orientation,
    int face_count,
    int id[TT_AVATAR_DRIVE_MAX_FACE_LIMIT],
    float landmark106[TT_AVATAR_DRIVE_MAX_FACE_LIMIT][212],
    AIAvatarDriveInfo *p_avatarDrive_info // out p_avatarDrive_info
);

AILAB_EXPORT
void ADM_SetEscale(
    AvatarDriveHandle handle,
    int escale
);
/*
 *@brief 释放句柄
 *param: handle 句柄
 */
AILAB_EXPORT
void ADM_ReleaseHandle(AvatarDriveHandle handle);

#if defined __cplusplus
};
#endif

#endif
