#ifndef SMASH_PLATE_SDK_H_
#define SMASH_PLATE_SDK_H_

#include "tt_common.h"
#if defined __cplusplus
extern "C" {
#endif

// Algorithm handler
typedef void *PlateHandle;

/*
 * Corresponding to a detected plate area
 * corners: pointer to a list of `corner_count` AIPoint objects
 * corner_count: each plate area is represented by `corner_count` points
 */
typedef struct PLRegion {
  AIPoint *corners;
  int corner_count;
} PLRegion;

/*
 *  Prediction result of an input image
 *  regions: pointer to a list of `region_num` PLRegion objects
 *  region_num: number of PLRegion objects
 */
typedef struct PLResult {
  PLRegion *regions;
  int region_num;
} PLResult, *PtrPLResult;

/*
 * Optional configurations
 */
typedef enum PLParamType {
  MaxRegionNum = 1,  // maximum number of plate regions in one image
} PLParamType;

/*
 * Create handle, only create handle but not init internal models
 * After creating handle, you should call either PL_InitModel or
 * PL_InitModelFromBuf to initialize internal model
 */
AILAB_EXPORT
int PL_CreateHandle(PlateHandle *handle);

AILAB_EXPORT
int PL_SetParam(PlateHandle handle, PLParamType, float value);

/*
 * Initialize model from file for prediction
 * Must be called right after PL_CreateHandle
 */
AILAB_EXPORT
int PL_InitModel(PlateHandle handle, const char *model_path);

/*
 * Initialize model from buffer for prediction
 * Must be called right after PL_CreateHandle
 */
AILAB_EXPORT
int PL_InitModelFromBuf(PlateHandle handle,
                        const char *model_buff,
                        int model_size);

/*
 * Predict plate regions in one image
 * Param
 *  handle, algorithm handler
 *  image, pointer to image data
 *  pixel_format, format of pixel of input image
 *  image_width, width of input image
 *  image_height, height of input image
 *  image_stride, stride of input image
 *  p_regions, pointer to pointer to PLResult
 *
 * Notes:
 * [1] user should not modify object pointed by p_regions, which is maintained
 * inside lib.
 * [2] every time PL_DoInfer is called the object pointed by p_regions may be
 * updated. Actual number of detected regions are recorded by
 * (*p_regions)->region_num. Illegal memory access may happen if the user had
 * not checkouted this value
 */
AILAB_EXPORT int PL_DoInfer(PlateHandle handle,
                            const unsigned char *image,
                            PixelFormatType pixel_format,
                            int image_width,
                            int image_height,
                            int image_stride,
                            PtrPLResult *p_regions);
/*
 * Release resources
 */
AILAB_EXPORT int PL_ReleaseHandle(PlateHandle handle);

#if defined __cplusplus
};
#endif
#endif  // SMASH_PLATE_SDK_H_
