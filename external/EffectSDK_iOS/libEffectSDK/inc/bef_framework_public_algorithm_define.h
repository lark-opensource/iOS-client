//
// Created by bytedance on 2018/5/3.
//

#ifndef EFFECT_SDK_BEF_EFFECT_ALGORITHM_DEFINE_H
#define EFFECT_SDK_BEF_EFFECT_ALGORITHM_DEFINE_H

#include "bef_framework_public_enum_define.h"
#include "bef_framework_public_geometry_define.h"
#include <stdbool.h>

// algorithm param
#define BEF_ALGO_FACE_PARAM_BASE_SMOOTH_LEVEL       100             // 106 face detection smooth param
#define BEF_ALGO_FACE_PARAM_EXTRA_SMOOTH_LEVEL      101             // face detection smooth param
#define BEF_ALGO_FACE_ATTR_MALE_SCORE_RANGE         102             // face detection male confidence
#define BEF_ALGO_FACE_ATTR_FEMALE_SCORE_RANGE       103             // face detection female confidence
#define BEF_ALGO_FACE_ATTR_FORCE_DETECT             104             // force detect face
#define BEF_ALGO_SKELETON_FORCE_DETECT              105             // force detect skeleton
#define BEF_TRACKING_AR_DETECT_RESET                106             // detect bingo ar detection
#define BEF_ALGO_TEETH_FILTER_MOUTH_STATUS          107             // whether teeth result filters no mouth open
#define BEF_ALGO_TEETH_FILTER_TEETH_STATUS          108             // whether teeth result filters no teeth exposed
#define BEF_ALGO_TEETH_MOUTH_THRESHLOD              109             // teeth mouth filter threshold
#define BEF_ALGO_FACE_PARAM_USE_FILTER_V2           110             // face detection smooth param, corresponding to FS_USE_FILTER_V2
#define BEF_ALGO_MANGA_PARAM_MODEL_IDX              111             // change manga model index in algorithm runtime
#define BEF_ALGO_TEST_FOR_SYNC                      112             // change some algorithms to execute synchronously only work in test
#define BEF_ALGO_RESET_OPTICAL_FLOW                 113             // reset optical flow
#define BEF_ALGO_FACE_DETECT_MODE                   114             // face detect mode: image/video
#define BEF_ALGO_BASE_IMAGE_MODE                    115        // base image mode (1 means image 0 means video) for all algorithms, currently applied on hand, headseg, skeleton and skinseg

typedef struct algorithm_result_st
{
    int m_type;
    double m_timeStamp;
} algorithm_result;
// def byted algorithm requirement
typedef unsigned long long bef_algorithm_requirement;

// def bef_algorithm_change_type
typedef int bef_algorithm_change_type;

// face detect
typedef struct bef_face_detect_ext_param_st {
    int dectectIntervalTime; //dafault 30,and must be divided by 3.
    bool imageMode;
    bool useFastModel;       // use fast mode
    int maxFaceNum;
} bef_face_detect_ext_param;


typedef struct bef_hand_detect_ext_param_st {
    int handLowPowerMode;
    bef_hand_model_type mode;
    int handDetectMaxNum;     // max hand number to detect
    int handDetectFrequency;  // hand detection frequency
} bef_hand_detect_ext_param;

typedef struct bef_handtv_ext_param_st {
    int handtvLowPowerMode;
    bef_handtv_model_type mode;
    int handtvMaxNum;     // max hand number to detect
    int handtvFrequency;  // hand detection frequency
} bef_handtv_ext_param;

typedef struct bef_matting_ext_param_st {
    bool useLargeModel;
    bool useContour;
    bool useSkeleton;
    int contour_width;
    int contour_height;
    int density;//density should be no less than 2
    int contour_thickness;
    int contour_type;
    float contour_stable;
    bool supportNPU;
    bool useNoRealTimeMode;
    bool useSubjectModel;
}bef_matting_ext_param;


#define BEF_CODE_TYPE_QRCODE        0x00000001  // QR code
#define BEF_CODE_TYPE_DY_CODE   0x00000002  // code
#define BEF_CODE_TYPE_UPC_A_CODE    0x00000004  // The following are all different types of barcodes
#define BEF_CODE_TYPE_UPC_E_CODE    0x00000008
#define BEF_CODE_TYPE_EAN_8_CODE    0x00000010
#define BEF_CODE_TYPE_EAN_13_CODE   0x00000020
#define BEF_CODE_TYPE_CODE39_CODE   0x00000040
#define BEF_CODE_TYPE_CODE128_CODE  0x00000080

typedef struct bef_enigma_detect_ext_param_st {
    float roiLeft;          // The distance from the recognition area to the left of the picture (normalized value)
    float roiTop;           // The distance of the recognition area from the top of the picture (normalized value)
    float roiWidth;         // Recognition area width (normalized value)
    float roiHeight;        // Recognition area height (normalized value)
    bool useExtROI;         // Whether the above parameters take effect, false will identify the full screen, true will read the above parameters
    bool scanMode;          // Scanning mode, the default is 0, 0 means camera mode, 1 means album (picture) mode
    unsigned int codeType;  // Types of codes to be recognized, see above BEF_CODE_TYPE_XXX
    bool decodeMultiple;    // If there are multiple codes on the captured picture, whether to return the result of multiple codes
    bool enhanceCamera;
}bef_enigma_detect_ext_param;

typedef struct bef_hair_color_detect_ext_param_st {
    bool noUseTracking; // detection mode, 0 for video, 1 for picture, 0 by default
    bool noUseBlur; // deprecated, no use
    int minSideLength; // shortest side of Mask, must be multiple of 8, 128 by default. Larger value can improve precision.
} bef_hair_color_detect_ext_param;

typedef struct bef_face_beauty_detect_ext_param_st {
    bool useV3Model;                 // Whether to use beauty V3 model
} bef_face_beauty_detect_ext_param;

typedef struct bef_face_beautify_detect_ext_param_st {
    bool algoDebug;                     // Whether to use debug
    bool algoDespeckle;                 // Whether to use freckle removal algorithm, mutually exclusive with algoDespeckleReserve
    bool algoDespeckleReserve;          // Whether to use freckle removal and keep mole algorithm, mutually exclusive with algoDespeckle
} bef_face_beautify_detect_ext_param;

// Beautyme reviving photo param to set model size
typedef struct bef_hdrnet_detect_ext_param_st {
    unsigned int modelType;         // front/back model switch, 1 for back, 2 for front
    bool useExternalModel;          // Whether to use external model file
    char modelPath[1024];            // model path
} bef_hdrnet_detect_ext_param;

#ifdef BEF_ALGORITHM_CONFIG_FACE_VERIFY
// dynamic face verify detection params
typedef struct bef_face_verify_ext_param_st {
    bool useDynamicMode;
    float faceScoreThresh;
    float faceMaxYawAngle;
    float faceMaxPitchAngle;
    int faceMinLengthSide;
} bef_face_verify_ext_param;
#endif

typedef struct bef_object_tracking_ext_param_st {
    float width;       // tracking area width, normalized: 0.0 ~ 1.0
    float height;      // tracking area height, normalized: 0.0 ~ 1.0
    float center_x;    // tracking area center x pos, normalized: 0.0 ~ 1.0
    float center_y;    // tracking area center y pos, normalized: 0.0 ~ 1.0
    float rotateAngle; // tracking area roate angle, clockwise
    int   speed;       // 0, 1, 2.
}bef_object_tracking_ext_param;

typedef struct bef_petface_detect_ext_param_st {
    bool useImageMode;  // image-detection switch, 0 for video, 1 for picture, 0 by default
} bef_petface_detect_ext_param;

typedef struct bef_algorithm_ext_param_st {
    bef_face_detect_ext_param faceDetectExtParam;
    bef_hand_detect_ext_param handDetectExtParam;
    bef_handtv_ext_param handtvExtParam;
    bef_matting_ext_param mattingExtParam;
    bef_algorithm_requirement requirement;
    bef_enigma_detect_ext_param    enigmaExtParam;
    bef_hair_color_detect_ext_param hairColorDetectExtParam;
    bef_face_beauty_detect_ext_param faceBeautyDetectExtParam;
    bef_face_beautify_detect_ext_param faceBeautifyDetectExtParam;
    bef_hdrnet_detect_ext_param hdrnetDetectExtParam;  // hdr param
    bef_object_tracking_ext_param objectTrackingExtParam;
    bef_petface_detect_ext_param petFaceDetectExtParam;
    int forceDetect;  // force detect every frame
    char* algGraphConfigPath; // new algorithm system config path
} bef_algorithm_ext_param;


typedef struct BefRequirementNew_ST
{
    unsigned long long algorithmReq;      // old algorithm type for compatibility
    unsigned long long algorithmParam;  // old algorithm detailed param for compatibility
    int algorithmNum;                // new algorithm array length, 1000 for maximum
    int* algorithmRequirement;  // New algorithm array, each integer element represents a new algorithm type. Caller should allocate an array with size 1000 beforehand.
} bef_requirement_new;

typedef struct bef_algorithm_array_ext_param_st {
    bef_face_detect_ext_param faceDetectExtParam;
    bef_hand_detect_ext_param handDetectExtParam;
    bef_handtv_ext_param handtvExtParam;
    bef_matting_ext_param mattingExtParam;
    bef_requirement_new requirement;
    bef_enigma_detect_ext_param    enigmaExtParam;
    bef_hair_color_detect_ext_param hairColorDetectExtParam;
    bef_face_beauty_detect_ext_param faceBeautyDetectExtParam;
    bef_face_beautify_detect_ext_param faceBeautifyDetectExtParam;
    bef_hdrnet_detect_ext_param hdrnetDetectExtParam;  // hdr param
    bef_object_tracking_ext_param objectTrackingExtParam;
    bef_petface_detect_ext_param petFaceDetectExtParam;
    int forceDetect;  // force detect every frame
    char* algGraphConfigPath; // new algorithm system config path
} bef_algorithm_array_ext_param;

typedef struct bef_image_baseParam_st{
    // image size
    int h;
    int w;
    int stride;
    void* data;
    bef_pixel_format pixel_format;
    bef_rotate_type oritention;
    
}bef_image_baseParam;

typedef struct bef_ModuleBaseArgs {
    const unsigned char* image;
    bef_pixel_format pixel_fmt;
    int image_width;
    int image_height;
    int image_stride;
    bef_rotate_type orient;
}bef_ModuleBaseArgs;

//SmashBench_GaussianBlur param
typedef struct bef_gaussianBlur_param_st{
    int kernel_size;
    int sigma;
    
}bef_gaussian_param;

typedef struct bef_bench_input_param_st{
    bef_image_baseParam image_param;
    bef_gaussian_param gaussian_blur_param;
}bef_bench_input_param;

typedef struct bef_bench_ret_st{
    // error code, 0 for running correctly
    int err_code;
    // Unit: ms
    long time;
}bef_bench_ret;

#endif //EFFECT_SDK_BEF_EFFECT_ALGORITHM_DEFINE_H
