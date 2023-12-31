#ifndef __FACE_3DMM_API_H__
#define __FACE_3DMM_API_H__
#include "tt_common.h"
#if defined __cplusplus
extern "C" {
#endif

typedef void *Face3DMMHandle;

#define MOUTH_LANDMARK_NUM 32
#define LANDMARK_NUM 106

typedef struct AIFace3DMMInfo {
  float alpha[MESH_COM_DIM];
  float mvp[16];
  float mv[16];
  float affine_mat[9];
  bool getMeshDone;
} AIFace3DMMInfo, *PtrAIFace3DMMInfo;

typedef struct AIFace3DMMMesh {
  float mesh[MESH_LEVEL * 3];
  float landmarks181[MESH_LANMARK181_NUM * 2];
  float contourPoints[CONTOUR_PTS_NUM * 2];
  float uv[MESH_LEVEL * 2];
  int flist[FLIST_NUM * 3];
  float mouthLandmarks[MOUTH_LANDMARK_NUM * 2];
  float mean_color[3];
} AIFace3DMMMesh, *PtrAIFace3DMMMesh;

AILAB_EXPORT
int F3DMM_CreateHandler(unsigned int config, Face3DMMHandle *handle);

AILAB_EXPORT
int F3DMM_SetParamsFromSingleFile(Face3DMMHandle handle,
                                  const char *res_path,
                                  int net_input_width,
                                  int net_input_height);

AILAB_EXPORT
int F3DMM_SetParamsFromBuf(Face3DMMHandle handle,
                           const char *model_buf,
                           unsigned int model_buf_len,
                           int net_input_width,
                           int net_input_height);

/*
 *@brief from AIFace3DMMInfo to get mesh
 *param: handle
 */

AILAB_EXPORT
int F3DMM_GetMesh(Face3DMMHandle handle,
                  const AIFace3DMMInfo *p_face3mm_info,  // in
                  AIFace3DMMMesh *p_face3mm_mesh         // out
);

AILAB_EXPORT
int F3DMM_Get181Landmarks(Face3DMMHandle handle,
                          AIFace3DMMMesh *p_face3mm_mesh_in,           // in
                          AIFace3DMMMesh *p_face3mm_mesh_landmark_out  // out
);

AILAB_EXPORT
int F3DMM_ContourPoints(Face3DMMHandle handle,
                        AIFace3DMMMesh *p_face3mm_mesh_in,          // in
                        AIFace3DMMMesh *p_face3mm_mesh_contour_out  // out
);

AILAB_EXPORT
int F3DMM_GetMouthLandMarks(
    Face3DMMHandle handle,
    AIFace3DMMMesh *p_face3mm_mesh_in,                  // in
    AIFace3DMMMesh *p_face3mm_mesh_mouth_landmarks_out  // out
);

AILAB_EXPORT
int F3DMM_GetImageMeanColor(Face3DMMHandle handle,
                            unsigned char *image,
                            PixelFormatType pixel_format,
                            int image_width,
                            int image_height,
                            int image_stride,
                            AIFace3DMMMesh *p_mean_color_out);

AILAB_EXPORT
int F3DMM_MergeWithPredParam(Face3DMMHandle handle,
                             float _salpha[],
                             float _ralpha[]);

AILAB_EXPORT
int F3DMM_SetSalp(Face3DMMHandle handle, float slap);

AILAB_EXPORT
int F3DMM_SetEcd(Face3DMMHandle handle, float ecd);

AILAB_EXPORT
int F3DMM_SetSmooth(Face3DMMHandle handle, bool smooth);

AILAB_EXPORT
int F3DMM_FaceDetectAndDoPredit(
    Face3DMMHandle handle,
    unsigned char *image,
    PixelFormatType pixel_format,
    int image_width,
    int image_height,
    int image_stride,
    ScreenOrient orientation,
    AIFace3DMMInfo *p_face3dmm_info,  // out face3dmm_info
    AIFace3DMMMesh *out_mesh          // out mesh
);

/*
 *@brief 释放句柄
 *param: handle 句柄
 */
AILAB_EXPORT
void F3DMM_ReleaseHandle(Face3DMMHandle handle);

// AILAB_EXPORT
// int F3DMM_InitModelWithParam(
//    Face3DMMHandle handle,
//    int net_input_width,
//    int net_input_height
//);

// AILAB_EXPORT
// int F3DMM_SetParamsFromFile(
//    Face3DMMHandle handle,
//    const char * basis_path,
//    const char * vlines_path,
//    const char * hlines2_path,
//    const char * flist_2_path,
//    const char * faces_width_vert_path,
//    const char * uv_path
//);

// AILAB_EXPORT
// int F3DMM_SetParamsFromBuff(
//  Face3DMMHandle handle,
//  float * buffer
//);

// AILAB_EXPORT
// int  F3DMM_GetUV(
// Face3DMMHandle handle,
// AIFace3DMMMesh* p_face3mm_mesh //out
//);
//
// AILAB_EXPORT
// int  F3DMM_GetFlist(
//  Face3DMMHandle handle,
//  AIFace3DMMMesh* p_face3mm_mesh //out
//);

// AILAB_EXPORT
// int F3DMM_GetFace3MMInfo(
//  Face3DMMHandle handle,
//  AIFace3DMMInfo *p_face3mm_info  // out
//);

// AILAB_EXPORT
// int F3DMM_DoPredict(
//  Face3DMMHandle handle,
//  unsigned char *image,
//  float * landmarks,
//  int faceid,
//  PixelFormatType pixel_format,
//  int image_width,
//  int image_height,
//  int image_stride,
//  ScreenOrient orientation,
//  AIFace3DMMInfo *p_face3dmm_info
//);

// AILAB_EXPORT
// void *F3DMM_GetDebugInfo(
//  Face3DMMHandle handle
// );
//
// AILAB_EXPORT
// unsigned char *F3DMM_GetFace3Data(
//  Face3DMMHandle handle
//);

// AILAB_EXPORT
// int F3DMM_GetMeanColor(
//  Face3DMMHandle handle,
//  AIFace3DMMMesh *p_contour_in,
//  float * landmarks_in,
//  AIFace3DMMMesh *p_mean_color_out
//  );

// AILAB_EXPORT
// int F3DMM_GetMeanColorContourPoints(
//  Face3DMMHandle handle,
//  float *p_contour_in,
//  int len,
//  float * landmarks_in,
//  float *p_mean_color_out
//  );

#if defined __cplusplus
};
#endif

#endif
