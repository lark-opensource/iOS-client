//
//  bef_effect_algorithm_rect_doc_det_api.h
//  effect_sdk
//
//  Created by bytedance on 2021/3/12.
//

#ifndef bef_effect_algorithm_rect_doc_det_api_h
#define bef_effect_algorithm_rect_doc_det_api_h

#include "bef_effect_public_define.h"

typedef void* bef_RectDocDet_Handle;

typedef enum bef_RectDocDetModelType
{
    bef_kRectDocDetModel1 = 1,
} bef_RectDocDetModelType;

typedef enum bef_RectDocDetIsVideoType {
    bef_kRectDocDetIsVideoTypeYes = 1,
    bef_kRectDocDetIsVideoTypeNo = 2,
} bef_RectDocDetIsVideoType;

typedef enum bef_RectDocDetParamType
{
    bef_kRectDocDetPreProcessMode = 1,
    bef_kRectDocDetIsVideoMode = 2,
    bef_kRectDocDetAngleThr = 3,
} bef_RectDocDetParamType;

typedef struct bef_RectDocDetArgs
{
    bef_ModuleBaseArgs base;
} bef_RectDocDetArgs;

typedef struct bef_RectDocDetTargetArea
{
    float top_left_x;
    float top_left_y;
    float top_right_x;
    float top_right_y;
    float bottom_left_x;
    float bottom_left_y;
    float bottom_right_x;
    float bottom_right_y;
} bef_RectDocDetTargetArea;

typedef struct bef_RectDocDetRatio
{
    float ratio;
    int width_val;
    int height_val;
} bef_RectDocDetRatio;

typedef struct bef_RectDocDetRet {
    bef_RectDocDetTargetArea target_area;
    bef_RectDocDetRatio rectangle_ratio;
    int buffer[1];
} bef_RectDocDetRet;

/**
 * @brief Create algorithm handle
 * @param out Output algorithm handle
 * @return BEF_RESULT_SUC means successful call, BEF_RESULT_FAIL means failed
 */
BEF_SDK_API bef_effect_result_t bef_RectDocDet_CreateHandle(bef_RectDocDet_Handle *out);

/**
 * @brief Initialize the model using finder
 * @param handle Algorithm handle
 * @param type Initialized model type
 * @param finder ResourceFinder pointer
 * @return BEF_RESULT_SUC means successful call, BEF_RESULT_FAIL means failed
*/
BEF_SDK_API bef_effect_result_t bef_RectDocDet_init(bef_RectDocDet_Handle handle,
        bef_RectDocDetModelType type, bef_resource_finder finder);

/**
 * @brief Initialize the model using the resource path
 * @param handle Algorithm handle
 * @param type Initialized model type
 * @param assetModelPath resource path
 * @return BEF_RESULT_SUC means successful call, BEF_RESULT_FAIL means failed
*/
BEF_SDK_API bef_effect_result_t bef_RectDocDet_init_with_path(bef_RectDocDet_Handle handle,
        bef_RectDocDetModelType type, const char* path);

/**
 * @brief Set parameters of type float
 * @param handle Algorithm handle
 * @param type Parameter Type
 * @return BEF_RESULT_SUC means successful call, BEF_RESULT_FAIL means failed
*/
BEF_SDK_API bef_effect_result_t bef_RectDocDet_SetParamF(bef_RectDocDet_Handle handle,
        bef_RectDocDetParamType type, float value);

/**
 * @brief Perform recognition
 * @param handle Algorithm handle
 * @param args Input image and image parameters
 * @param ret Recognition result
 * @return BEF_RESULT_SUC means successful call, BEF_RESULT_FAIL means failed
*/
BEF_SDK_API bef_effect_result_t bef_RectDocDet_Do(bef_RectDocDet_Handle handle,
        bef_RectDocDetArgs* args, bef_RectDocDetRet* out);

/**
 * @brief Release handle
 * @param handle Algorithm handle
 * @return BEF_RESULT_SUC means successful call, BEF_RESULT_FAIL means failed
*/
BEF_SDK_API bef_effect_result_t bef_RectDocDet_ReleaseHandle(bef_RectDocDet_Handle handle);

#endif  /* bef_effect_algorithm_rect_doc_det_api_h */
