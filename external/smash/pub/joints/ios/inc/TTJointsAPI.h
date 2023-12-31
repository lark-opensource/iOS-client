#ifndef _TTJOINTSAPI_H_
#define _TTJOINTSAPI_H_

#ifdef __cplusplus
extern "C" {
#endif

#include "tt_common.h"

// prefix: TT -> TouTiao

typedef void *TTJointsHandle;

AILAB_EXPORT
int TTJointsCreate(TTJointsHandle *handle_ptr);
  
AILAB_EXPORT
int TTJointsCreateFestival(TTJointsHandle *handle_ptr);

AILAB_EXPORT
void TTJointsFree(TTJointsHandle handle);

AILAB_EXPORT
int TTJointsInit(TTJointsHandle handle, const char *param_path_ptr);

AILAB_EXPORT
int TTJointsInitFromBuf(TTJointsHandle handle,
                        const char *param_buf,
                        unsigned int len);

AILAB_EXPORT
int TTJointsPredict(TTJointsHandle handle,
                    const unsigned char *img_data_ptr,
                    PixelFormatType img_format,
                    int img_width,
                    int img_height,
                    int img_stride,
                    ScreenOrient img_orient,
                    TTJoint **joints_ptr,
                    int *joints_num_ptr);

AILAB_EXPORT
int TTJointsDelayedPredict(TTJointsHandle handle,
                           const unsigned char *img_data_ptr,
                           PixelFormatType img_format,
                           int img_width,
                           int img_height,
                           int img_stride,
                           ScreenOrient img_orient,
                           int delay_num,
                           TTJoint **joints_ptr,
                           int *joints_num_ptr);
#ifdef __cplusplus
}
#endif

#endif /* _TTJOINTSAPI_H_ */
