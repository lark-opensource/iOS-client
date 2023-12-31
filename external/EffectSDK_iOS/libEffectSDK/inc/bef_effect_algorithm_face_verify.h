//
//  bef_effect_algorithm_face_verify.h
//  Pods
//
//  Created by lvshaohui1234 on 2019/10/11.
//

#ifndef bef_effect_algorithm_face_verify_h
#define bef_effect_algorithm_face_verify_h
#include "bef_effect_public_define.h"

typedef void *bef_FaceVerifyHandle;  // Face verify handle

#define BEF_FACE_FEATURE_DIM 128  // Dimension of facial features


// Results information
typedef struct bef_FaceVerifyInfo {
    bef_face_106
    base_infos[BEF_MAX_FACE_NUM];  // Basic face information, including 106 points, actions, posture
    float features[BEF_MAX_FACE_NUM][BEF_FACE_FEATURE_DIM];  // Facial features
    int valid_face_num;  // Number of detected faces
} bef_FaceVerifyInfo;

/**
 * @brief Create handle
 * @param face_verify_param_path    Model path
 * @param max_face_num              The maximum number of faces to be processed, this value cannot be greater than AI_MAX_FACE_NUM
 * @param handle
 * @return 0 means successful call, negative means failed
 */
BEF_SDK_API
int bef_FVS_CreateHandler_path(const char *face_verify_path,
                      const int max_face_num,
                      bef_FaceVerifyHandle *handle);
BEF_SDK_API
int bef_FVS_CreateHandler(bef_resource_finder finder,
                               const int max_face_num,
                               bef_FaceVerifyHandle *handle);

BEF_SDK_API
int bef_FVS_CreateHandlerFromBuf_path(const char *face_verify_buf,
                             unsigned int face_verify_buf_len,
                             const int max_face_num,
                             bef_FaceVerifyHandle *handle);

/**
 * @brief Extract features
 * 
 * @param handle    Face verify handle
 * @param image     Image data
 * @param pixel_format      Image format, support RGBA, BGRA, BGR, RGB, GRAY (YUV is not supported yet)
 * @param image_width       Image width
 * @param image_height      Image height
 * @param image_stride      Stride
 * @param orientation       Image orientation
 * @param face_input_ptr    Face information obtained by calling the face detect SDK
 * @param face_info_ptr     To store the result information, the external memory needs to be allocated, and the space must be greater than or equal to the maximum number of detected faces
 * @return 0 means successful call, negative means failed
 */
BEF_SDK_API
int bef_FVS_DoExtractFeature(
                         bef_FaceVerifyHandle handle,
                         const unsigned char *image,
                         bef_pixel_format pixel_format,
                         int image_width,
                         int image_height,
                         int image_stride,
                         bef_rotate_type orientation,
                         const bef_face_info *face_input_ptr,
                         bef_FaceVerifyInfo* face_info_ptr
);

/**
 * @brief Extract features
 * @param handle    Face verify handle
 * @param image     Image data
 * @param pixel_format      Image format, support RGBA, BGRA, BGR, RGB, GRAY (YUV is not supported yet)
 * @param image_width       Image width
 * @param image_height      Image height
 * @param image_stride      Stride
 * @param orientation       Image orientation
 * @param base_info         Basic face information, including 106 points, actions, posture
 * @param features          Facial features
 * @return 0 means successful call, negative means failed
 */
BEF_SDK_API
int bef_FVS_DoExtractFeatureSingle(
                               bef_FaceVerifyHandle handle,
                               const unsigned char *image,
                               bef_pixel_format pixel_format,
                               int image_width,
                               int image_height,
                               int image_stride,
                               bef_rotate_type orientation,
                               bef_face_106 base_info,
                               float *features
);

/**
 * @brief Release handle
 * @param: handle Face verify handle
 */
BEF_SDK_API void bef_FVS_ReleaseHandle(bef_FaceVerifyHandle handle);

#define BEF_FACE_VERIFY_SIZE 112         // The size of the face used to extract features
typedef void *bef_FaceVerifyCropHandle;  // face crop handle

typedef struct  bef_FaceVerifyCropInfo {
    bef_face_info base_infos; // input: Basic face information, including 106 points, actions, posture
    unsigned char crop_img[BEF_FACE_VERIFY_SIZE * BEF_FACE_VERIFY_SIZE * 3]; // output: used to store image buffer after crop
} bef_FaceVerifyCropInfo;

/**
 * @brief Initialize handle
 */
BEF_SDK_API int bef_fvs_alingCropInitHandle(bef_FaceVerifyCropHandle *handle);

BEF_SDK_API int bef_fvs_alignCrop(
                               bef_FaceVerifyCropHandle handle,
                               const unsigned char *image,
                               bef_pixel_format pixel_format,  // Image format, support RGBA, BGRA, BGR, RGB
                               int image_width,               // Image width
                               int image_height,              // Image height
                               int image_stride,              // Stride
                               bef_rotate_type orientation,      // Image orientation
                               bef_FaceVerifyCropInfo *face_crop_info_ptr);

BEF_SDK_API int bef_fvs_alignCropRelease(bef_FaceVerifyCropHandle handle);


#endif /* bef_effect_algorithm_face_verify_h */
