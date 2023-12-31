#ifndef _BLING_API_H_
#define _BLING_API_H_

#include "tt_common.h"
#if defined __cplusplus
extern "C" {
#endif

// prefix: BB -> Bling Bling

#define MAX_CORNERS_NUM 50

typedef void *BlingHandle;

typedef struct AILAB_EXPORT AIBlingResult {
  float points_buff[MAX_CORNERS_NUM * 3];
  int out_pts_num;
} AIBlingResult, *PtrAIBlingResult;

int BB_CreateHandler(BlingHandle *handle);
int BB_Corner_OP(BlingHandle handle,
                  const unsigned char *src_image_data,
                  PixelFormatType pixel_format,
                  int width,
                  int height,
                  int bytesPerRow,
                  AIBlingResult *blingResult);

int BB_ReleaseHandle(BlingHandle handle);

int BB_SetQualityLevel(BlingHandle handle, double QualityLevel);

int BB_GetQualityLevel(BlingHandle handle, double &QualityLevel);

int BB_SetMinDistance(BlingHandle handle, double MinDistance);

int BB_GetMinDistance(BlingHandle handle, double &MinDistance);

int BB_SetMaxCorners(BlingHandle handle, int MaxCorners);

int BB_GetMaxCorners(BlingHandle handle, int &MaxCorners);

#if defined __cplusplus
};
#endif
#endif  // _BLING_API_H_
