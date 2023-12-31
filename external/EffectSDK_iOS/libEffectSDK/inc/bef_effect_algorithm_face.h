//
//  bef_effect_algorithm_face.h
//  Pods
//
//  Created by bytedance on 2019/10/11.
//

#ifndef bef_effect_algorithm_face_h
#define bef_effect_algorithm_face_h

#include "bef_effect_public_define.h"

// Config when creating handle
#define BEF_TT_INIT_LARGE_MODEL 0x00100000  // 106 model initialization parameters, more accurate, now obsolete
#define BEF_TT_INIT_SMALL_MODEL 0x00200000  // 106 model initialization parameters, faster
#define BEF_TT_MOBILE_FACE_240_DETECT_FASTMODE \
0x00300000  // 240 model initialization parameters, faster
//**************************** end of Create-Config *****************/

//***************************** begin Mode-Config ******************/
#define BEF_TT_MOBILE_DETECT_MODE_VIDEO 0x00020000  // Video detection, initialization + prediction parameters
#define BEF_TT_MOBILE_DETECT_MODE_IMAGE 0x00040000  // Image detection, initialization + prediction parameters
#define BEF_TT_MOBILE_DETECT_MODE_IMAGE_SLOW \
0x00080000  // Picture detection, face detection model is better, can detect smaller faces, initialization + prediction parameters
//***************************** enf of Mode-Config *****************/

//***************************** Begin Config-106 point and action **/
// for 106 key points detect
// NOTE open mouth, shadke head, nod, raise esybrows detection is enabled by default
#define BEF_TT_MOBILE_FACE_DETECT 0x00000001
// Face action
#define BEF_TT_MOBILE_EYE_BLINK 0x00000002   // Blink
#define BEF_TT_MOBILE_MOUTH_AH 0x00000004    // Open mouth
#define BEF_TT_MOBILE_HEAD_YAW 0x00000008    // Shake head
#define BEF_TT_MOBILE_HEAD_PITCH 0x00000010  // nod
#define BEF_TT_MOBILE_BROW_JUMP 0x00000020   // Raise eyebrows
#define BEF_TT_MOBILE_MOUTH_POUT 0x00000040  // Duck face / pouts lips

#define BEF_TT_MOBILE_DETECT_FULL 0x0000007F  // Detect all the above features, initialize + predict parameters

// Left eye blink, only used to extract the corresponding action, motion detection is still blink
#define BEF_TT_MOBILE_EYE_BLINK_LEFT \
0x00000080

// Right eye blink, only used to extract the corresponding action, motion detection is still blink
#define BEF_TT_MOBILE_EYE_BLINK_RIGHT \
0x00000100

// a special gesture of shaking head to convey agreement, only used to extract the corresponding action, motion detection is still blink
#define BEF_TT_MOBILE_SIDE_NOD \
0x00000200
//**************************** End Config-106 point and action *******/

//******************************* Begin Config-280 point *************/
// for 280 points
// NOTE: Now the second-level strategy has been changed. The key points of eyebrows, eyes, and mouth will appear in a model.

// Second-level key points: eyebrows, eyes, mouth, initialization + prediction parameters
#define BEF_TT_MOBILE_FACE_240_DETECT \
0x00000100
#define BEF_BROW_EXTRA_DETECT TT_MOBILE_FACE_240_DETECT   // eyebrows 13*2 points
#define BEF_EYE_EXTRA_DETECT TT_MOBILE_FACE_240_DETECT    // eyes 22*2 points
#define BEF_MOUTH_EXTRA_DETECT TT_MOBILE_FACE_240_DETECT  // mouth 64 points
#define BEF_MOUTH_MASK_DETECT 0x00000300                  // mouth mask
#define BEF_IRIS_EXTRA_DETECT 0x00000800                  // Iris 20*2 points

// Second-level key points: eyebrows, eyes, mouth, iris, initialization + prediction parameters
#define BEF_TT_MOBILE_FACE_280_DETECT \
0x00000900
//******************************* End Config-280 point ***************/

#define BEF_TT_MOBILE_FORCE_DETECT 0x00001000  // Mandatory face detection

typedef void *bef_FaceHandle;  // Key point detection handle




// Mask
typedef struct bef_AIMouthMaskInfoBase {
    int face_mask_size;        // face_mask_size
    unsigned char *face_mask;  // face_mask
    float *warp_mat;           // warp mat data ptr, size 2*3
    int id;
} bef_AIMouthMaskInfoBase, *bef_PtrAIMouthMaskInfoBase;

typedef struct bef_AIMouthMaskInfo {
    bef_AIMouthMaskInfoBase base_mouth_infos[BEF_MAX_FACE_NUM];
    int face_count;
} bef_AIMouthMaskInfo, *bef_PtrAIMouthMaskInfo;

/**
 *@brief Initialize the handle
 *@param [in] config Specify the model parameters, e.g. TT_INIT_SMALL_MODEL | TT_MOBILE_DETECT_FULL， Image mode: TT_INIT_SMALL_MODEL | TT_MOBILE_DETECT_FULL | TT_MOBILE_DETECT_MODE_IMAGE or TT_INIT_SMALL_MODEL | TT_MOBILE_DETECT_FULL | TT_MOBILE_DETECT_MODE_IMAGE_SLOW
 *@param [in] param_path File path of the first-level model
 *@param [in|out] handle
 */
BEF_SDK_API
int bef_fs_createHandler_path(unsigned long long config,
                     const char *param_path,
                     bef_FaceHandle *handle);

BEF_SDK_API int bef_fs_createHandler(unsigned long long config, 
                                 bef_resource_finder finder,
                                 bef_FaceHandle *handle);

/**
 *@param [in] config Specify the model parameters, e.g. TT_INIT_SMALL_MODEL | TT_MOBILE_DETECT_FULL， Image mode: TT_INIT_SMALL_MODEL | TT_MOBILE_DETECT_FULL | TT_MOBILE_DETECT_MODE_IMAGE or TT_INIT_SMALL_MODEL | TT_MOBILE_DETECT_FULL | TT_MOBILE_DETECT_MODE_IMAGE_SLOW
 *@param [in] param_buf Model cache data
 *@param [in] param_buf_len Model data length
 *@param [in|out] handle
 **/
BEF_SDK_API
int bef_fs_createHandlerFromBuf(unsigned long long config,
                            const char *param_buf,
                            unsigned int param_buf_len,
                            bef_FaceHandle *handle);

/**
 * @brief Initialize the handle
 * @param handle
 * @param [in] config Specify model parameters(240 | 280)
 *Config-240，TT_MOBILE_FACE_240_DETECT
 *Config-280，TT_MOBILE_FACE_280_DETECT
 *Config-240 fast mode, TT_MOBILE_FACE_240_DETECT | TT_MOBILE_FACE_240_DETECT_FASTMODE
 *Config-280 fast mode, TT_MOBILE_FACE_280_DETECT | TT_MOBILE_FACE_240_DETECT_FASTMODE
 * @param [in] param_path The file path of the model(240 | 280)
 */
BEF_SDK_API
int bef_fs_addExtraModel_path(
                     bef_FaceHandle handle,
                     unsigned long long config,
                     const char *param_path);
BEF_SDK_API
int bef_fs_addExtraModel(bef_FaceHandle handle,
                         unsigned long long
                         config,bef_resource_finder finder);


/**
 * @brief Initialize the handle
 * @param handle
 * @param [in] config Specify model parameters(240 | 280)
 *Config-240，TT_MOBILE_FACE_240_DETECT
 *Config-280，TT_MOBILE_FACE_280_DETECT
 *Config-240 fast mode, TT_MOBILE_FACE_240_DETECT | TT_MOBILE_FACE_240_DETECT_FASTMODE
 *Config-280 fast mode, TT_MOBILE_FACE_280_DETECT | TT_MOBILE_FACE_240_DETECT_FASTMODE
 * @param [in] param_buf Model cache data
 * @param [in] param_buf_len Model cache data length
 */
BEF_SDK_API
int bef_fs_addExtraModelFromBuf_path(bef_FaceHandle handle,
                            unsigned long long config,
                            const char *param_buf,
                            unsigned int param_buf_len);

/**
 * @param detection_config
 * Config-106: TT_MOBILE_DETECT_MODE_VIDEO | TT_MOBILE_DETECT_FULL(TT_MOBILE_FACE_DETECT | TT_MOBILE_MOUTH_POUT)
 * Config-240: TT_MOBILE_DETECT_MODE_VIDEO | TT_MOBILE_DETECT_FULL | TT_MOBILE_FACE_240_DETECT
 * Config-240-fast-mode: TT_MOBILE_DETECT_MODE_VIDEO | TT_MOBILE_DETECT_FULL | TT_MOBILE_FACE_240_DETECT | TT_MOBILE_FACE_240_DETECT_FASTMODE Config-Image TT_MOBILE_DETECT_MODE_IMAGE | TT_MOBILE_DETECT_FULL or TT_MOBILE_DETECT_MODE_IMAGE_SLOW | TT_MOBILE_DETECT_FULL
*/
BEF_SDK_API
int bef_fs_doPredict(
                 bef_FaceHandle handle,
                 const unsigned char *image,
                 bef_pixel_format pixel_format,         // image format, support RGBA, BGRA, BGR, RGB, GRAY (YUV is not supported yet)
                 int image_width,                       // image width
                 int image_height,                      // image height
                 int image_stride,                      // stride
                 bef_rotate_type orientation,           // image orientation
                 unsigned long long detection_config,
                 bef_face_info * p_face_info            // To store the result information, it is necessary to allocate memory externally, and ensure that the space is greater than or equal to the maximum number of detected faces
);

BEF_SDK_API
int bef_fs_getMouthMaskResult(bef_FaceHandle handle,
                          unsigned long long det_cfg,
                          bef_AIMouthMaskInfo *mouthInfo);

typedef enum {
    // Set how many frames to perform face detection every time (default is 24 when there is a face, 8 when there is no face), the larger the value, the lower the CPU usage, but the longer it takes to detect a new face.
    BEF_FS_FACE_PARAM_FACE_DETECT_INTERVAL = 1,
    // Set the maximum number of faces that can be detected (default value 5), the set value cannot be greater than AI_MAX_FACE_NUM
    BEF_FS_FACE_PARAM_MAX_FACE_NUM = 2,
    // Dynamic adjustment can detect the size of the face. The video mode is forced to 4, and the picture mode can be set to 8 to detect smaller faces. The higher the detection level, the smaller the face can be detected. Value range: 4～10
    BEF_FS_FACE_PARAM_MIN_DETECT_LEVEL = 3,
    // base: debounce parameters[1-30]
    BEF_FS_FACE_PARAM_BASE_SMOOTH_LEVEL = 4,
    // extra: debounce parameters[1-30]
    BEF_FS_FACE_PARAM_EXTRA_SMOOTH_LEVEL = 5,
    // Mouth mask debounce parameter, [0-1], default 0, the better the smoothing effect, the slower the speed
    BEF_FS_FACE_PARAM_MASK_SMOOTH_TYPE = 6,
} bef_fs_face_param_type;

// Set detection parameters
BEF_SDK_API int bef_fs_setParam(bef_FaceHandle handle,
                             bef_fs_face_param_type type,
                             float value);

BEF_SDK_API int bef_fs_getFrameFaceOrientation(const bef_face_106 *result);

/**
 *@brief release handle
 */
BEF_SDK_API void bef_fs_releaseHandle(bef_FaceHandle handle);


#endif /* bef_effect_algorithm_face_h */
