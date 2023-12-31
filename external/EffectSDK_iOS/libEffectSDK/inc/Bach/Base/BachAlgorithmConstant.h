#ifdef __cplusplus
#ifndef _BACH_ALGORITHM_CONSTANT_H_
#define _BACH_ALGORITHM_CONSTANT_H_

#include "Bach/BachCommon.h"
#include <vector>
#include <string>

NAMESPACE_BACH_BEGIN

BACH_VAR_EXPORT extern const char* _SRC_DATA_KEY_;
BACH_VAR_EXPORT extern const char* _SRC_ARRAY_KEY_;
BACH_VAR_EXPORT extern const char* _SRC_AUDIO_KEY_;

BACH_VAR_EXPORT extern const char* _SRC_DATA_KEY_0_;
BACH_VAR_EXPORT extern const char* _SRC_DATA_KEY_1_;
BACH_VAR_EXPORT extern const char* _SRC_ARRAY_KEY_0_;
BACH_VAR_EXPORT extern const char* _SRC_ARRAY_KEY_1_;
BACH_VAR_EXPORT extern const char* _SRC_AUDIO_KEY_0_;
BACH_VAR_EXPORT extern const char* _SRC_AUDIO_KEY_1_;

BACH_VAR_EXPORT extern const char* _SRC_ARFRAME_KEY_;

enum class AlgorithmType
{
    INVALID = -1,
    RAW_IMAGE_PRODUCER,
    EXT_TEXTURE_PRODUCER,
    ARRAY_BUFFER_PRODUCER,
    TEXTURE_BLIT,
    FACE,
    FAKE_FACE,
    HAND,
    SKELETON,
    FACE_VERIFY,
    FACE_ATTR,
    FACE_CLUSTING,
    HAIR,
    MATTING,
    SLAM_NAIL,
    CAT_FACE,
    MUG,
    FACE_FITTING,
    AVATAR_DRIVE,
    OBJECT_DETECT,
    ARSCAN,
    CLOTHES_SEG,
    CAR_SEG,
    HEAD_SEG,
    ENIGMA,
    FACE_PART_BEAUTY,
    SCENE_RECOGNITION,
    FACE_GAN,
    OLD_GAN,
    TRACKING_AR,
    SIMILARITY,
    AFTER_EFFECT,
    AUTO_REFRAME,
    SCENE_RECOG_V2,
    PORN_CLS,
    VIDEO_MOMENT,
    VIDEO_TEMP_REC,
    VIDEO_CLS,
    VIDEO_MATTING,
    BLING,
    YOUNG_GAN,
    LAUGH_GAN,
    SKELETON_POSE_3D,
    UPPERBODY3D,
    AVATAR_3D,
    GROUND_SEG,
    FOOT,
    EXPRESSION_DETECT,
    BUILDING_SEG,
    BEAUTY_GAN,
    SKIN_SEG,
    SWAPPERME,
    FACE_LIGHT,
    IDREAM,
    FCEALIGN,
    CVTCOLOR,
    RESIZE,
    DATACONVERT,
    BYTENN,
    SCENE_RECOG_V3,
    DEPTH,
    SALIENCY_SEG,
    DYNAMIC_GESTURE,
    HEAD_FITTING,
    DEEP_INPAINT,
    SKY_SEG,
    HUMAN_PARSING,
    PICTURE_AR,
    EAR_SEG,
    CLOTH_CLASS,
    SCENE_NORMAL,
    FOOD_COMICS,
    PET_MATTING,
    ACTION_DETECT,
    GAZE_ESTIMATION,
    TEETH,
    NAIL,
    NODE_HUB_IMAGE_TRANSFORM,
    NODE_HUB_FACE_SELECT,
    NODE_HUB_FACE_ALIGN,
    NODE_HUB_HAND_ALIGN,
    NODE_HUB_INFERENCE,
    KIRA,
    HAND_TV,
    LICENSE_PLATE_DETECT,
    MEMOJI_MATCH,
    HDR_NET,
    FACE_MASK,
    MV_TEMP_REC,
    BLOCKGAN,
    JOINTS1,
    JOINTS2,
    FIND_CONTOUR,
    RGBD2MESH,
    OIL_PAINT,
    BIG_GAN,
    FACE_PET_DETECT,
    GENDER_GAN,
    FEMALE_GAN,
    MANGA,
    VIDEO_SR,
    OBJECT_DETECTION2,
    AUDIO_PRODUCER,
    AUDIO_AVATAR,
    APOLLOFACE3D,
    AVACAP,
    SCENE_LIGHT,
    CAR_SERIES,
    ACTION_RECOGNITION,
    FACE_SMOOTH_CPU,
    INDOOR_SEG,
    BUILDING_NORMAL,
    FACE_NEW_LANDMARK,
    INTERACTIVE_MATTING,
    FACE_BEAUTIFY,
    SKIN_UNIFIED,
    HAND_OBJECT_SEG_TRACK,
    NH_INFERENCE,
    NH_MODEL_PREVIEW,
    NH_IMAGE_TRANSFORM,
    NH_CONVERT_TO_TENSOR,
    NH_STYLE_TRANSFER_POST_PROCESS,
    NH_CLASSIFICATION,
    NH_FACE_ALIGN,
    NH_HAND_ALIGN,
    NH_FACE_SELECT,
    NAVI_AVATAR_DRIVE,
    OBJECT_TRACKING,
    HAIR_FLOW,
    HAVATAR,
    WATCH_TRYON,
    RELATION_RECOG,
    FREID,
    FACE_REENACT_ANIMATION,
    FACE_REENACT_KEYPOINT_DETECTION,
    AVATAR3D_FUSION,
    FOREHEAD_SEG,
    CONTENT_RECOMMEND,
    SWAP_LIVE,
    GPU_RENDER,
    COLOR_MAPPING,
    CLOTH_GAN,
    SCRIPT,
    F_PARSING,
    EYE_FITTING,
    AVATAR_SCORE,
    NECK,
    MULTI_OBJECT_TRACKING_AR,
    FLOWER_MA,
    SENSOR,
    COLOR_TRANSFER,
    VIDEO_SELECT_FRAME,
    SALIENT_HUMAN,
    CLEANGAN,
    AUTOFOCUS,
    CHROMA_KEYING,
    AVATAR_FIT,
    NAVI_FIT,
    STOP_MOTION,
    MEME_FIT,
    MEGA,
    LEGO_FIT,
    CLOTH_SERIES,
    KEY_POINT,
    GENERAL_AR,
    AUTO_DETECTION,
    MOUTH_REENACT,
    MOUTH_REENACT_POST_PROCESS,
    EFFECTGANRT,
    MOBILE_VOS,
    VIDEO_INPAINTING,
    LICENSECAKE_DETECTION,
    OPTICAL_FLOW_TRACK,
    SMOOTH_FILTER,
    CINE_MOVE,
    CAMERA_MOTION,
    GENERAL_OCR,
    LM_3D,
    FACEFITTING_3D,
    COMPUTE_ENGINE,
    GENERAL_LENS,
    VIDEO_RELIT,
    AVA_BOOST,
    COMPRESS_SHOT_DETECT,
    STRUCTXT,
    NH_OBJECT_DETECTION_POST_PROCESS,
    SMASH_MATTING,
    VIDEO_REFRAME,
};

enum class AlgorithmResultType
{
    INVALID = -1,
    INPUT_SOURCE,
    IMAGE_BUFFER,
    TEXTURE,
    BLIT_IMAGE_BUFFER,
    GAN_IMAGE_BUFFER,
    GAN_IMAGE_ARRAY,
    BLIT_TEXTURE,
    ARRAY_BUFFER,
    FACE,
    FAKE_FACE,
    HAND,
    SKELETON,
    FACE_VERIFY,
    FACE_ATTR,
    FACE_CLUSTING,
    HAIR,
    MATTING,
    SLAM_NAIL,
    CAT_FACE,
    MUG,
    FACE_FITTING,
    AVATAR_DRIVE,
    OBJECT_DETECT,
    ARSCAN,
    CLOTHES_SEG,
    CAR_SEG,
    HEAD_SEG,
    ENIGMA,
    FACE_PART_BEAUTY,
    SCENE_RECOGNITION,
    FACE_GAN,
    OLD_GAN,
    TRACKING_AR,
    SIMILARITY,
    AFTER_EFFECT,
    AUTO_REFRAME,
    SCENE_RECOG_V2,
    PORN_CLS,
    VIDEO_MOMENT,
    VIDEO_TEMP_REC,
    VIDEO_CLS,
    FOOT,
    BEAUTY_GAN,
    FACE_LIGHT,
    IDREAM,
    APOLLO_PROCESS,
    BYTENN,
    SALIENCY_SEG,
    SCENE_RECOG_V3,
    DEPTH_ESTIMATION,
    DYNAMIC_GESTURE,
    HEAD_FITTING,
    DEEP_INPAINT,
    SKY_SEG,
    BUILDING_SEG,
    HUMAN_PARSING,
    PICTURE_AR,
    EAR_SEG,
    CLOTH_CLASS,
    SKIN_SEG,
    SCENE_NORMAL,
    FOOD_COMICS,
    SKELETON_POSE_3D,
    PET_MATTING,
    ACTION_DETECT,
    BLING,
    GAZE_ESTIMATION,
    TEETH,
    NAIL,
    UPPERBODY3D,
    AVATAR_3D,
    NODE_HUB_IMAGE_BUFFER,
    KIRA,
    LAUGH_GAN,
    SWAPPERME,
    HAND_TV,
    LICENSE_PLATE_DETECT,
    MEMOJI_MATCH,
    HDR_NET,
    FACE_MASK,
    MV_TEMP_REC,
    BLOCKGAN,
    JOINTS1,
    JOINTS2,
    FIND_CONTOUR,
    RGBD2MESH,
    GROUND_SEG,
    OIL_PAINT,
    BIG_GAN,
    FACE_PET_DETECT,
    GENDER_GAN,
    FEMALE_GAN,
    MANGA,
    VIDEO_SR,
    OBJECT_DETECTION2,
    AUDIO_PRODUCER,
    AUDIO_AVATAR,
    APOLLOFACE3D,
    AVACAP,
    SCENE_LIGHT,
    CAR_SERIES,
    ACTION_RECOGNITION,
    FACE_SMOOTH_CPU,
    INDOOR_SEG,
    BUILDING_NORMAL,
    FACE_NEW_LANDMARK,
    INTERACTIVE_MATTING,
    FACE_BEAUTIFY,
    SKIN_UNIFIED,
    HAND_OBJECT_SEG_TRACK,
    CPU_RENDER,
    NH_TENSOR_BUFFER,
    NH_IMAGE_TFM_BUFFER,
    NH_MODEL_INFO,
    NH_IMAGE_BUFFER,
    NH_CLASSIFICATION_BUFFER,
    NH_MUL_IMAGE_BUFFER,
    NAVI_AVATAR_DRIVE,
    OBJECT_TRACKING,
    HAIR_FLOW,
    HAVATAR,
    WATCH_TRYON,
    RELATION_RECOG,
    FREID,
    FACE_REENACT,
    FACE_REENACT_KEYPOINT,
    AVATAR3D_FUSION,
    FOREHEAD_SEG,
    CONTENT_RECOMMEND,
    SWAP_LIVE,
    COLOR_MAPPING,
    CLOTH_GAN,
    NH_IMAGE_WITH_TFM_BUFFER,
    F_PARSING,
    EYE_FITTING,
    AVATAR_SCORE,
    NECK,
    MULTI_OBJECT_TRACKING_AR,
    FLOWER_MA,
    SCRIPT,
    SENSOR,
    COLOR_TRANSFER,
    VIDEO_SELECT_FRAME,
    SALIENT_HUMAN,
    CLEANGAN,
    AUTOFOCUS,
    CHROMA_KEYING,
    AVATAR_FIT,
    NAVI_FIT,
    STOP_MOTION,
    MEME_FIT,
    MEGA,
    LEGO_FIT,
    CLOTH_SERIES,
    KEY_POINT,
    GENERAL_AR,
    AUTO_DETECTION,
    MOUTH_REENACT,
    MOUTH_REENACT_POST_PROCESS,
    EFFECTGANRT,
    MOBILE_VOS,
    VIDEO_INPAINTING,
    LICENSECAKE_DETECTION,
    OPTICAL_FLOW_TRACK,
    SMOOTH_FILTER,
    CINE_MOVE,
    CAMERA_MOTION,
    GENERAL_OCR,
    LM_3D,
    FACEFITTING_3D,
    COMPUTE_ENGINE,
    GENERAL_LENS,
    VIDEO_RELIT,
    AVA_BOOST,
    COMPRESS_SHOT_DETECT_RESULT,
    STRUCTXT,
    NH_OBJECT_DETECTION_POST_PROCESS,
    VIDEO_REFRAME,
};

enum class AlgorithmMessageType
{
    EMPTY = 0,
    IMU_ACC = 1,      // double[3]
    IMU_GYR,          // double[3]
    IMU_GRA,          // double[3]
    IMU_WRB,          // double[9]
    IMU_COMBINE,      // double[15] = acc[3]+gyr[3]+wrb[9]: combination of above types, only for iOS
    CAMERA_INTRINSIC, // double[5] = [fx,fy,cx,cy,deltaTimestamp]
    CAMERA_INFO,      // double[2] = [fovx, fovy]
    SENSOR_AVAILABLE, // int[4] = [has_accelerometer, has_gyroscope, has_gravity, has_orientation]
    TOUCH,            // double[2] = [x,y] <==> int[2] = [hasActive, isPickedEntityGroup]: touch-info, for now only used in nailSlam.
};

struct AlgorithmMessage
{
    AlgorithmMessageType mType = AlgorithmMessageType::EMPTY;
    void* dt = nullptr;
    std::vector<void*> mDataPtr;
    std::vector<double> mData;
    std::vector<int> mDataI;
    std::vector<std::string> mDataS;
    double mTimestamp = 0.0;
};

typedef struct camera_intrinsic_data_st
{
    double fx = 0.0;
    double fy = 0.0;
    double cx = 0.0;
    double cy = 0.0;
    double deltaTimestamp = 0.0;
    bool isSet = false;
} camera_intrinsic_data;

typedef struct camera_info_data_st
{
    double fovx = 0.0;
    double fovy = 0.0;
    bool isSet = false;
} camera_info_data;

typedef struct sensor_available_data_st
{
    int has_accelerometer = 0;
    int has_gyroscope = 0;
    int has_gravity = 0;
    int has_orientation = 0;
} sensor_available_data;

typedef struct device_info_data_st
{
    camera_intrinsic_data camera_intrinsic;
    sensor_available_data sensor_available;
    camera_info_data camera_info;
} device_info_data;

class BachImageInfo
{
public:
    int width = 0;
    int height = 0;
    int stride = 0;
    unsigned char* data = nullptr;
    AEPixelFormat format = AEPixelFormat::RGBA8UNORM;
};

NAMESPACE_BACH_END
#endif

#endif