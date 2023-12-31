//
// Created by bytedance on 2018/5/3.
//

#ifndef EFFECT_SDK_BEF_EFFECT_BUSINESS_C_DEFINE_H
#define EFFECT_SDK_BEF_EFFECT_BUSINESS_C_DEFINE_H

#include "bef_framework_public_base_define.h"
#include "bef_effect_public_face_define.h"
#include <stdbool.h>

//#define BEF_REQUIREMENT_NONE                 0x00000000
#define BEF_REQUIREMENT_FACE_DETECT          0x00000001
#define BEF_REQUIREMENT_MATTING              0x00000002

#define BEF_REQUIREMENT_HAIR                 0x00000004
#define BEF_REQUIREMENT_SLAM                 0x00000008
#define BEF_REQUIREMENT_BODY                 0x00000010
#define BEF_REQUIREMENT_FACE_TRACK           0x00000020
#define BEF_REQUIREMENT_JOINT                0x00000040
#define BEF_REQUIREMENT_FACE_CAT_DETECT      0x00000080
//#define BEF_REQUIREMENT_FACE_240             0x00000100
#define BEF_REQUIREMENT_FACE_3D_MESH_BASE    0x00000200
#define BEF_REQUIREMENT_HAND_BASE            0x00000400
#define BEF_REQUIREMENT_SKELETON2            0x00000800
#define BEF_REQUIREMENT_EXPRESS_BASE_DETECT  0x00001000
#define BEF_REQUIREMENT_FACE_3D_DETECT       0x00002000
#define BEF_REQUIREMENT_SKY_SEG              0x00004000
#define BEF_REQUIREMENT_SKELETON_LIUXING      0x00008000
#define BEF_REQUIREMENT_ENIGMA_DETECT        0x00010000
#define BEF_REQUIREMENT_AR_PLANE             0x00020000
#define BEF_REQUIREMENT_ACTION_DETECT_BASE   (BEF_REQUIREMENT_SKELETON2 | 0x00040000)
#define BEF_REQUIREMENT_LICENSE_PLATE_DETECT     0x00080000
#define BEF_REQUIREMENT_GAZE_ESTIMATION     0x100000
#define BEF_REQUIREMENT_MUG                 0x200000
#define BEF_REQUIREMENT_BLING_DETECT        0x400000
#define BEF_REQUIREMENT_SKELETON_POSE_3D    0x800000
#define BEF_REQUIREMENT_BIG_GAN             0x1000000
//#define BEF_REQUIREMENT_BIG_GAN ((BitSet(1)) << 89)
#ifndef TRANSPARENCY_CENTER_I18N
#define BEF_REQUIREMENT_FACE_VERIFY         0x2000000
#endif
#ifndef TRANSPARENCY_CENTER_I18N
#define BEF_REQUIREMENT_FACE_CLUSTING       0x4000000
#endif
#define BEF_REQUIREMENT_OLDGAN              0x10000000
#define BEF_REQUIREMENT_YOUNG_GAN           0x20000000
#define BEF_REQUIREMENT_MODEL_TEST          0x40000000
#define BEF_REQUIREMENT_GENDER_GAN          0x80000000

#define BEF_REQUIREMENT_FACE_PET_DETECT     0x100000000
#define BEF_REQUIREMENT_OBJECT_DETECT       0x200000000
#define BEF_REQUIREMENT_JOINTV2             0x400000000
#define BEF_REQUIREMENT_HEADSEG             0x800000000
#define BEF_REQUIREMENT_ATTRIBUTE_BASE      0x1000000000
#define BEF_REQUIREMENT_FEMALE_GAN          0x4000000000
#define BEF_REQUIREMENT_NAIL                0x10000000000
#define BEF_REQUIREMENT_CLOTHESSEG          0x40000000000
#define BEF_REQUIREMENT_FACE_BEAUTIFY       0x80000000000
#define BEF_REQUIREMENT_AVATAR_DRIVE        0x100000000000
#define BEF_REQUIREMENT_ARSCAN              0x200000000000
#define BEF_REQUIREMENT_CAR_BASE            0x400000000000
#define BEF_REQUIREMENT_FACEPART_BEAUTY     0x800000000000

#define BEF_REQUIREMENT_MICROPHONE_ATTENTION 0x1000000000000
#define BEF_REQUIREMENT_FACE_ATTRIBUTES      0x2000000000000
#define BEF_REQUIREMENT_HDRNET               0x4000000000000
#define BEF_REQUIREMENT_HDRNET_PICTURE       0x8000000000000

#define BEF_REQUIREMENT_GYROSCOPE           0x10000000000000
#define BEF_REQUIREMENT_SNAPSHOT_DETECT     0x20000000000000
#define BEF_REQUIREMENT_FACE_GAN            0x40000000000000

#define BEF_REQUIREMENT_SKY_SEG_US_LAB      0x80000000000000

#define BEF_REQUIREMENT_OBJECT_TRACKING     0x0100000000000000

#define BEF_REQUIREMENT_SCENE_RECOGNITION   0x0400000000000000
#define BEF_REQUIREMENT_TEETH               0x0800000000000000
#define BEF_REQUIREMENT_EARSEG              0x1000000000000000

#define BEF_REQUIREMENT_UPPER_BODY_3D       0x2000000000000000

#define BEF_REQUIREMENT_TRACKING_AR         0x4000000000000000 // effect 580 changes from BEF_REQUIREMENT_OBJECT_TRACK
#if BEF_ALGORITHM_CONFIG_NOT_USE_MEMEFIT || BEF_ALGORITHM_CONFIG_NOT_USE_MEMEFIT_SAFE
#define BEF_REQUIREMENT_MEMOJI_MATCH        0x8000000000000000
#endif

#define BEF_REQUIREMENT_STRUCTXT                        (BEF::BitSet(1) << 65)
#define BEF_REQUIREMENT_GROUND_SEG                      (BEF::BitSet(1) << 66)
#define BEF_REQUIREMENT_LAUGH_GAN                       (BEF::BitSet(1) << 67)
#define BEF_REQUIREMENT_WATERCOLOR                      (BEF::BitSet(1) << 68)
#define BEF_REQUIREMENT_FACE_SMOOTH_CPU                 (BEF::BitSet(1) << 69)
#define BEF_REQUIREMENT_GENERAL_OBJECT_DETECTION        (BEF::BitSet(1) << 70)
#define BEF_REQUIREMENT_MANGA                           (BEF::BitSet(1) << 71)
#define BEF_REQUIREMENT_FOOD_COMICS                     (BEF::BitSet(1) << 72)
#define BEF_REQUIREMENT_SCENE_NORMAL                    (BEF::BitSet(1) << 73)
#define BEF_REQUIREMENT_AVATAR_3D                       (BEF::BitSet(1) << 74)
#define BEF_REQUIREMENT_FOOT                            (BEF::BitSet(1) << 75)
#define BEF_REQUIREMENT_BUILDINGSEG                     (BEF::BitSet(1) << 76)
#define BEF_REQUIREMENT_BLOCKGAN                        (BEF::BitSet(1) << 77)
#define BEF_REQUIREMENT_BEAUTYGAN                       (BEF::BitSet(1) << 79)
#define BEF_REQUIREMENT_HIGH_FREQUENCE_ROTATION_SENSOR_DATA     (BitSet(1) << 80)
#define BEF_REQUIREMENT_SKIN_SEG                        (BEF::BitSet(1) << 81)
#define VIDEO_MATTING_SHIFT 82
#define BEF_REQUIREMENT_VIDEO_MATTING                   (BEF::BitSet(1) << 82)
#define BEF_REQUIREMENT_SWAPPER_ME                      (BEF::BitSet(1) << 83)
#define BEF_REQUIREMENT_CLOTH_MESH                      (BEF::BitSet(1) << 84)
#define BEF_REQUIREMENT_OILPAINT                        (BEF::BitSet(1) << 85)
#define BEF_REQUIREMENT_SALIENCY_SEG                    (BEF::BitSet(1) << 86)
#define BEF_REQUIREMENT_ENABLE_BACH                     (BEF::BitSet(1) << 87)  // special placeholder for enable bach algorithm system
#define BEF_REQUIREMENT_PET_MATTING                     (BEF::BitSet(1) << 88)
#define BEF_REQUIREMENT_HAND_ROI                        (BEF::BitSet(1) << 89)
#define BEF_REQUIREMENT_INTERACTIVE_MATTING             (BEF::BitSet(1) << 90)
#define BEF_REQUIREMENT_HAND_TV                         (BEF::BitSet(1) << 91)
#define BEF_REQUIREMENT_KIRA                            (BEF::BitSet(1) << 92)
#define BEF_REQUIREMENT_SENSOR_PASS_BY                  (BEF::BitSet(1) << 93)
#define GREEN_SCREEN_VIDEO_SHIFT 94
#define BEF_REQUIREMENT_GREEN_SCREEN_VIDEO              (BEF::BitSet(1) << 94)  // special bit for green-screen video algorithm
// #define {{BEF_REQUIREMENT_XXX}} (BitSet(1) << n)
// Don't delete above comment line which used by add_algorithm.sh

//#define BEF_FACE_BASE_NUM  (0x100 000)
// FACE_DETECT USE 0x F7 F00 001

//#define BEF_REQUIREMENT_FACE_240            (BEF_REQUIREMENT_FACE_DETECT | (0x100 * 0x100000))
//#define BEF_REQUIREMENT_FACE_280            (BEF_REQUIREMENT_FACE_DETECT | (0x900 * 0x100000))

#define ALGORITHM_PARAM_BLING_HIGHLIGHT_DETECT (BEF_REQUIREMENT_BLING_DETECT | 0x000010)    // set bling algorithm type

#define BEF_REQUIREMENT_EXTEND_FACE_DETECT_240  { BEF_REQUIREMENT_FACE_DETECT, ALGORITHM_PARAM_FACE_DETECT_240}
#define BEF_REQUIREMENT_FACE_DETECT_240       (((uint64_t)0x00000100 * BEF_FACE_BASE_NUM) | BEF_REQUIREMENT_FACE_DETECT) // Mouth 64 points
#define BEF_REQUIREMENT_EXTEND_GENDER_DETECT  {BEF_REQUIREMENT_EXPRESS_BASE_DETECT, ALGORITHM_PARAM_GENDER_DETECT}
#define BEF_REQUIREMENT_EXTEND_EXPRESS_DETECT  {BEF_REQUIREMENT_EXPRESS_BASE_DETECT, ALGORITHM_PARAM_EXPRESS_DETECT}
#define BEF_REQUIREMENT_GENDER_DETECT    (BEF_REQUIREMENT_EXPRESS_BASE_DETECT|\
(BEF_REQUIREMENT_ATTRIBUTE_BASE * 0x00000002))
#define BEF_REQUIREMENT_EXPRESS_DETECT  (BEF_REQUIREMENT_EXPRESS_BASE_DETECT|\
(BEF_REQUIREMENT_ATTRIBUTE_BASE * (0x00000004|0x00000010)))
#define BEF_REQUIREMENT_EXTEND_CAR_SEGMENTATION  {BEF_REQUIREMENT_CAR_BASE, ALGORITHM_PARAM_CAR_SEGMENTATION}
#define BEF_REQUIREMENT_CAR_SEGMENTATION     (BEF_REQUIREMENT_CAR_BASE | 0x20000000000)
#define BEF_REQUIREMENT_EXTEND_HAND  {BEF_REQUIREMENT_HAND_BASE, ALGORITHM_PARAM_HAND}
#define BEF_REQUIREMENT_HAND                 (BEF_REQUIREMENT_HAND_BASE | 0x1000000000000000)

#define BEF_REQUIREMENT_EXTEND_HAND_KEYPOINT  {BEF_REQUIREMENT_HAND_BASE, ALGORITHM_PARAM_HAND_KEYPOINT}
#define BEF_REQUIREMENT_EXTEND_2HAND_KEYPOINT  {BEF_REQUIREMENT_HAND_BASE, ALGORITHM_PARAM_2HAND_KEYPOINT}
#define BEF_REQUIREMENT_EXTEND_2HAND  {BEF_REQUIREMENT_HAND_BASE, ALGORITHM_PARAM_2HAND}
#define BEF_REQUIREMENT_EXTEND_HAND_SEG  {BEF_REQUIREMENT_HAND_BASE, ALGORITHM_PARAM_HAND_SEG}

#define BEF_REQUIREMENT_HAND_KEYPOINT        (BEF_REQUIREMENT_HAND_BASE | 0x2000000000000000)
#define BEF_REQUIREMENT_2HAND_KEYPOINT       (BEF_REQUIREMENT_HAND_BASE | 0x4000000000000000)
#define BEF_REQUIREMENT_2HAND                (BEF_REQUIREMENT_HAND_BASE | 0x8000000000000000)
#define BEF_REQUIREMENT_HAND_SEG             (BEF_REQUIREMENT_HAND_BASE | 0x0800000000000000)
#define BEF_REQUIREMENT_HAND_KEYPOINT3D      (BEF_REQUIREMENT_HAND_BASE | 0x0010000000000000)
#define BEF_REQUIREMENT_HAND_LEFTRIGHT       (BEF_REQUIREMENT_HAND_BASE | 0x0020000000000000)
#define BEF_REQUIREMENT_HAND_RING            (BEF_REQUIREMENT_HAND_BASE | 0x0040000000000000)


#define BEF_REQUIREMENT_EXTEND_ACTION_DETECT_STATIC  {BEF_REQUIREMENT_ACTION_DETECT_BASE, ALGORITHM_PARAM_ACTION_DETECT_STATIC}
#define BEF_REQUIREMENT_EXTEND_ACTION_DETECT_SEQUENCE  {BEF_REQUIREMENT_ACTION_DETECT_BASE, ALGORITHM_PARAM_ACTION_DETECT_SEQUENCE}
#define BEF_REQUIREMENT_ACTION_DETECT_STATIC (BEF_REQUIREMENT_ACTION_DETECT_BASE | 0x0100000000000000)
#define BEF_REQUIREMENT_ACTION_DETECT_SEQUENCE (BEF_REQUIREMENT_ACTION_DETECT_BASE | 0x0200000000000000)

// The bits that can be used by BefRequirement's algorithmReq after the algorithm bit modification, the macro definition starts with BEF_REQUIREMENT_
// Available bits, occupy one, please put this line in the back Note xxx
//0x0000 0000 0000 0001                 xxx FaceDetect
//0x0000 0000 0000 0002                 xxx Matting
//0x0000 0000 0000 0004                 xxx Hair
//0x0000 0000 0000 0008                 xxx Slam
//0x0000 0000 0000 0010                 xxx Body
//0x0000 0000 0000 0020                 xxx FaceTrack
//0x0000 0000 0000 0040                 xxx Joint
//0x0000 0000 0000 0080                 xxx FaceCat
//0x0000 0000 0000 0100                 // #define BEF_REQUIREMENT_FACE_240             0x00000100
//0x0000 0000 0000 0200                 xxx FaceFitting
//0x0000 0000 0000 0400                 xxx Hand
//0x0000 0000 0000 0800                 xxx SKELETON2
//0x0000 0000 0000 1000                 xxx EXPRESS
//0x0000 0000 0000 2000                 xxx FACE3DDETECT
//0x0000 0000 0000 4000                 xxx SKY_SEG
//0x0000 0000 0000 8000                 xxx SKELETON_CHRY
//0x0000 0000 0001 0000                 xxx ENIGMA_DETECT
//0x0000 0000 0002 0000                 xxx AR_PLANE
//0x0000 0000 0004 0000                 xxx BEF_REQUIREMENT_ACTION_DETECT_BASE
//0x0000 0000 0008 0000                 xxx LICENSE_PLATE_DETECT
//0x0000 0000 0010 0000                 xxx GAZE_ESTIMATION
//0x0000 0000 0020 0000                 xxx MUG 
//0x0000 0000 0040 0000                 xxx BLING_DETECT  
//0x0000 0000 0080 0000                 xxx SKELETON_POSE_3D  
//0x0000 0000 0100 0000                 xxx BIG_GAN  
//0x0000 0000 0200 0000                 xxx FACE_VERIFY    
//0x0000 0000 0400 0000                 xxx FACE_CLUSTING  
//0x0000 0000 1000 0000                 xxx OLDGAN
//0x0000 0000 2000 0000                 xxx YOUNGGAN  
//0x0000 0000 4000 0000                 xxx MODEL_TEST
//0x0000 0000 8000 0000                 xxx GENDER_GAN
//0x0000 0001 0000 0000                 xxx FACE_PET_DETECT  
//0x0000 0002 0000 0000                 xxx OBJECT_DETECT  
//0x0000 0004 0000 0000                 xxx JOINTV2  
//0x0000 0008 0000 0000                 xxx HEADSEG  
//0x0000 0010 0000 0000                 xxx ATTRIBUTE_BASE  
//0x0000 0020 0000 0000                 xxx  
//0x0000 0040 0000 0000                 xxx FEMALE_GAN
//0x0000 0100 0000 0000                 xxx Nail
//0x0000 0200 0000 0000                 xxx ！！！ This algorithm bit conflicts with BEF_REQUIREMENT_EXPRESS_DETECT set by VE error
//0x0000 0400 0000 0000                 xxx CLOTHESSEG  
//0x0000 0800 0000 0000                 xxx FACE_BEAUTIFY  
//0x0000 1000 0000 0000                 xxx AVATAR_DRIVE 
//0x0000 2000 0000 0000                 xxx ARSCAN  
//0x0000 4000 0000 0000                 xxx CAR_BASE  
//0x0000 8000 0000 0000                 xxx FACEPART_BEAUTY   
//0x0001 0000 0000 0000                 xxx MICROPHONE_ATTENTION  
//0x0002 0000 0000 0000                 xxx FACE_ATTRIBUTES  
//0x0004 0000 0000 0000                 xxx HDRNET  
//0x0008 0000 0000 0000                 xxx HDRNET_PICTURE  
//0x0010 0000 0000 0000                 xxx GYROSCOPE  
//0x0020 0000 0000 0000                 xxx SNAPSHOT_DETECT  
//0x0040 0000 0000 0000                 xxx FACE_GAN  
//0x0080 0000 0000 0000                 xxx SKY_SEG_US_LAB  
//0x0100 0000 0000 0000                 xxx Object_Tracking
//0x0200 0000 0000 0000                 xxx SkinUnified  
//0x0400 0000 0000 0000                 xxx SCENE_RECOGNITION  
//0x0800 0000 0000 0000                 xxx TEETH  
//0x1000 0000 0000 0000                 xxx EARSEG
//0x2000 0000 0000 0000                 xxx UPPER_BODY_3D  
//0x4000 0000 0000 0000                 xxx TRACKING_AR
//0x8000 0000 0000 0000                 xxx ******_MATCH !!! keyword masked

// The bits that can be used by algorithmParam of BefRequirement after the algorithm bit modification, the macro definition starts with ALGORITHM_PARAM_
// Available bits, occupy one, please put this line in the back Note xxx
//0x1
//0x2                       xxx FACE_3D_MESH_845
//0x4                       xxx FACE_3D_MESH_1220
//0x8                       xxx FACE_3D_MESH_PERSPECTIVE
//0x10                      xxx NAIL_KEYPOINT
//0x20
//0x40
//0x80
//0x100
//0x200
//0x400
//0x800
//0x1000
//0x2000
//0x4000
//0x8000
//0x10000
//0x20000
//0x40000
//0x80000
//0x10 0000 0000
//0x80 0000 0000
//0x400 0000 0000
//0x1000 0000 0000
//0x2000 0000 0000
//0x4000 0000 0000
//0x8000 0000 0000
//0x1 0000 0000 0000
//0x2 0000 0000 0000
//0x4 0000 0000 0000
//0x8 0000 0000 0000
//0x10 0000 0000 0000
//0x20 0000 0000 0000
//0x40 0000 0000 0000
//0x80 0000 0000 0000

#define ALGORITHM_PARAM_FACE_3D_MESH_845        0x2
#define ALGORITHM_PARAM_FACE_3D_MESH_1220       0x4
#define ALGORITHM_PARAM_FACE_3D_MESH_PERSPECTIVE       0x8
#define ALGORITHM_PARAM_NAIL_KEYPOINT           0x10

#define ALGORITHM_PARAM_CAR_SEGMENTATION 0x20000000000

#define ALGORITHM_PARAM_ACTION_DETECT_STATIC 0x0100000000000000
#define ALGORITHM_PARAM_ACTION_DETECT_SEQUENCE 0x0200000000000000

#define ALGORITHM_PARAM_HAND_SEG               0x0800000000000000
#define ALGORITHM_PARAM_HAND                   0x1000000000000000
#define ALGORITHM_PARAM_HAND_KEYPOINT          0x2000000000000000
#define ALGORITHM_PARAM_2HAND_KEYPOINT         0x4000000000000000
#define ALGORITHM_PARAM_2HAND                  0x8000000000000000
#define ALGORITHM_PARAM_HAND_KEYPOINT3D        0x0010000000000000
#define ALGORITHM_PARAM_HAND_LEFTRIGHT         0x0020000000000000
#define ALGORITHM_PARAM_HAND_RING      0x0040000000000000

#define ALGORITHM_PARAM_HANDTV                               0x20
#define ALGORITHM_PARAM_HANDTV_KEYPOINT                      0x40
#define ALGORITHM_PARAM_2HANDTV                              0x80
#define ALGORITHM_PARAM_2HANDTV_KEYPOINT                    0x100
#define ALGORITHM_PARAM_HANDTV_SEG                          0x200
#define ALGORITHM_PARAM_HANDTV_SKELETON                     0x400
#define ALGORITHM_PARAM_HANDTV_DYNAMIC                      0x800
#define ALGORITHM_PARAM_HANDTV_PERSON_RECOGNITION          0x1000

#define ALGORITHM_PARAM_FACE_DETECT_240  ((uint64_t)0x00000100 * BEF_FACE_BASE_NUM)
#define ALGORITHM_PARAM_FACE_DETECT_280  ((uint64_t)0x00000900 * BEF_FACE_BASE_NUM)
#define ALGORITHM_PARAM_MOUTH_MASK_DETECT  ((uint64_t)0x00000300 * BEF_FACE_BASE_NUM)
#define ALGORITHM_PARAM_FACE_MASK_DETECT  ((uint64_t)0x00000500 * BEF_FACE_BASE_NUM)
#define ALGORITHM_PARAM_GENDER_DETECT (BEF_REQUIREMENT_ATTRIBUTE_BASE * 0x00000002)
#define ALGORITHM_PARAM_AGE_DETECT (BEF_REQUIREMENT_ATTRIBUTE_BASE * 0x00000001)
#define ALGORITHM_PARAM_EXPRESS_DETECT (BEF_REQUIREMENT_ATTRIBUTE_BASE * (0x00000004|0x00000010))
#define ALGORITHM_PARAM_HAIR_HIGHLIGHT 0x0001000000000000
#define ALGORITHM_PARAM_PET_DETECT_CAT 0x0002000000000000
#define ALGORITHM_PARAM_PET_DETECT_DOG 0x0004000000000000
#define BEF_REQUIREMENT_SKIN_UNIFIED     0x0200000000000000

#define BEF_REQUIREMENT_OBJECT_TRACKING     0x0100000000000000

#define BEF_INTENSITY_TYPE_NONE                 0
#define BEF_INTENSITY_TYPE_BEAUTY_BRIGHTEN        1
#define BEF_INTENSITY_TYPE_BEAUTY_SMOOTH        2
#define BEF_INTENSITY_TYPE_FACE_SHAPE           3
#define BEF_INTENSITY_TYPE_FACE_EYE             4
#define BEF_INTENSITY_TYPE_FACE_CHEEK           5
#define BEF_INTENSITY_TYPE_GLOBAL_FILTER        6
#define BEF_INTENSITY_TYPE_MUSIC_EFFECT         7
#define BEF_INTENSITY_TYPE_HAIR_COLOR           8
#define BEF_INTENSITY_TYPE_BEAUTY_SHARP         9
#define BEF_INTENSITY_TYPE_SKIN_TONE            10
#define BEF_INTENSITY_TYPE_MAKEUPV2             11
#define BEF_INTENSITY_TYPE_GLOBAL_FILTER_V2     12
#define BEF_INTENSITY_TYPE_NIGHT_GAMMA          13
#define BEF_INTENSITY_TYPE_NIGHT_CONTRASTK      14
#define BEF_INTENSITY_TYPE_NIGHT_CONTRASTB      15
#define BEF_INTENSITY_TYPE_DISTORTION_RATIO     16
#define BEF_INTENSITY_TYPE_BUILDIN_LIP          17
#define BEF_INTENSITY_TYPE_BUILDIN_BLUSHER      18
#define BEF_INTENSITY_TYPE_BUILDIN_NASOLABIAL   19
#define BEF_INTENSITY_TYPE_BUILDIN_POUCH        20

#define BEF_INTENSITY_TYPE_FAR_EYE              21
#define BEF_INTENSITY_TYPE_ROTATE_EYE           22
#define BEF_INTENSITY_TYPE_ZOOM_NOSE            23
#define BEF_INTENSITY_TYPE_MOVE_NOSE            24
#define BEF_INTENSITY_TYPE_ZOOM_MOUTH           25
#define BEF_INTENSITY_TYPE_MOVE_MOUTH           26
#define BEF_INTENSITY_TYPE_MOVE_CHIN            27
#define BEF_INTENSITY_TYPE_ZOOM_FOREHEAD        28
#define BEF_INTENSITY_TYPE_CUT_FACE             29
#define BEF_INTENSITY_TYPE_SMALL_FACE           30
#define BEF_INTENSITY_TYPE_ZOOM_JAW_BONE        31
#define BEF_INTENSITY_TYPE_ZOOM_CHEEK_BONE      32
#define BEF_INTENSITY_TYPE_DRAG_LIPS            33
#define BEF_INTENSITY_TYPE_CORNER_EYE           34
#define BEF_INTENSITY_TYPE_LIP_ENHANCE          35
#define BEF_INTENSITY_TYPE_POINTY_CHIN          36
#define BEF_INTENSITY_TYPE_FACE_SMOOTH          37

#define BEF_INTENSITY_TYPE_BUILDIN_HDRNET       38


// Picture adjustment items
#define BEF_INTENSITY_TYPE_ADJUSTMENT_BRIGHTNESS        1001
#define BEF_INTENSITY_TYPE_ADJUSTMENT_CONTRAST          1002
#define BEF_INTENSITY_TYPE_ADJUSTMENT_SATURATION        1003
#define BEF_INTENSITY_TYPE_ADJUSTMENT_SHARP             1004
#define BEF_INTENSITY_TYPE_ADJUSTMENT_HIGH_LIGHT        1005
#define BEF_INTENSITY_TYPE_ADJUSTMENT_SHADOW            1006
#define BEF_INTENSITY_TYPE_ADJUSTMENT_COLOR_TEMPERTURE  1007
#define BEF_INTENSITY_TYPE_ADJUSTMENT_COLOR_TONE        1008
#define BEF_INTENSITY_TYPE_ADJUSTMENT_COLOR_FADE        1009



// algorithm result two buffer
#define ALGORITHM_DETECT_DATA_COUNT 2

#define ALGORITHM_DETECT_DATA_FRONT 0
#define ALGORITHM_DETECT_DATA_BACK 1
// MV audio type
#define BEF_MV_AUDIO_NONE      0
#define BEF_MV_AUDIO_VOLUME    1
#define BEF_MV_AUDIO_ONSET     2

typedef enum {
    BEF_CLIENT_STATE_UNKNOW = 0,   // Preview status/Friends shooting page
    BEF_CLIENT_STATE_PREVIEW = 1,  // Preview status
    BEF_CLIENT_STATE_CAPTURE = 2,  // Photo status
    BEF_CLIENT_STATE_RECORD = 3,   // Recording status
    BEF_CLIENT_STATE_ALBUM = 4,    // Album import
    BEF_CLIENT_STATE_EDITOR = 5,     // Status after taking pictures
} bef_client_state;
/*
 *@brief Monitoring status
 **/
typedef enum {
    BEF_MONITOR_NONE = 0,
    BEF_MONITOR_START = 1,
    BEF_MONITOR_RUNNING = 2,
    BEF_MONITOR_STOP = 3,
    BEF_MONITOR_END = 4,
}bef_monitor_state;

const static char *BeautyTypeNone = "";
const static char *BeautyTypeNature = "BeautyTypeNature";
const static char *BeautyTypeNormal = "BeautyTypeNormal";
const static char *BeautyTypeQingyan = "BeautyTypeQingyan";
const static char *BeautyTypeQingyanLive = "BeautyTypeQingyanLive";
const static char *BeautyTypeIES = "BeautyTypeIESBeauty";
const static char *BeautyTypeB612 = "BeautyTypeB612";
const static char *NightModeTypeNormal = "NightModeTypeNormal";

#define BEF_CAT_POINT_NUM 82
#define BEF_MAX_CAT_NUM 10
typedef struct bef_face_cat_st {
    bef_rect rect;          ///< Cat face bbox
    float score;            ///< Confidence
    bef_fpoint points_array[BEF_CAT_POINT_NUM];  ///< Array of 82 key points of cat face
    float yaw;              ///< Yaw angle
    float pitch;            ///< Pitch angle
    float roll;             ///< Roll angle
    int ID;                 ///< The cat face has a unique faceID, and it will get a new faceID after being detected again
    unsigned int action;     ///< Cat face action, whether the left eye is open(corresponds to the first bit), the right eye is open(corresponds to the second bit), and the mouth is open(Corresponds to the third bit)
} bef_face_cat;

#define BEF_MAX_OBJECT_NUM 5
typedef struct bef_object_detect_st{
    bef_rect rect; // bbox
    int Id;
    float score;
}bef_object_detect;

#define BEF_SCENE_NUM_CLASSES 22

typedef struct bef_scene_category_st {
    float prob;
    bool satisfied;
} bef_scene_category;

typedef struct bef_scene_detect_result_st {
    bef_scene_category items[BEF_SCENE_NUM_CLASSES];
    int choose;
} bef_scene_detect_result;

#define BEF_PET_POINT_NUM 90
#define BEF_CAT_POINT_NUM 82
#define BEF_DOG_POINT_NUM 76
#define BEF_MAX_PET_NUM 10
typedef struct bef_face_pet_st {
    int type;                          /// < Pet type
    bef_rect rect;                     /// face bbox
    float score;                       /// < Confidence
    bef_fpoint points_array[BEF_PET_POINT_NUM]; /// < Array of key points of pet face
    float yaw;                  ///< Yaw angle
    float pitch;                ///< Pitch angle
    float roll;                 ///< Roll angle
    int ID;                     ///< The cat face has a unique ID, and it will get a new ID after being detected again
    unsigned int action;        ///< Cat face action, whether the left eye is open(corresponds to the first bit), the right eye is open(corresponds to the second bit), and the mouth is open(Corresponds to the third bit)
    int ear_type;               ///< 0 means the ears stand and 1 means the ears 
} bef_face_pet;

typedef struct bef_matting_st {
    unsigned int alphaTextureId;
} bef_matting;

typedef struct bef_hand_t {
    int id;                         ///< hand ID
    bef_rect rect;                  ///< hand bbox
    bef_fpoint p_key_points[10];    ///< Key points of hand
    int key_points_count;           ///< Number of key points in hand
    unsigned long long hand_action; ///< Hand action
    float score;                    ///< Confidence
} bef_hand_t, *p_bef_hand_t;


typedef struct bef_music_effect_data_st {
    float volume;
} bef_music_effect_data;

typedef struct bef_AR_effect_st {
    //matrix
    float P[16];
    float R[9];
    float T[3];

} bef_AR_effect;

// bgm recording information
typedef struct bef_bgmRecordNode_st {
    char* path;
    unsigned path_len;
    float trim_in;
    float trim_out;
    float des_in;
    float des_out;
} bef_bgmRecordNode;

// 3D audio algorithm parameters
typedef struct bef_3Daudio_param_st {
    float pos[3];
} bef_3Daudio_param;

//: public bef_base_effect_info
typedef struct bef_face_cat_detect_st  {
    bef_face_cat faceAction[BEF_MAX_CAT_NUM];
    int faceCount;
} bef_face_cat_detect;

typedef struct bef_face_pet_detect_st {
    bef_face_pet faceAction[BEF_MAX_PET_NUM];
    int faceCount;
} bef_face_pet_detect;

//: public bef_base_effect_info
typedef struct bef_body_dance_result_st{
    int score;
    //hit result[0 = no, 1 = good, 2 = perfect]
    int hitResult;
    int combatCount;
    int guideIndex;  // current detect guideIndex
    int templateID;  // current detect templateID
    bool resultUsable;
} bef_body_dance_result;

//: public bef_base_effect_info
typedef struct bef_action_detect_st {
    long long action_result;
} bef_action_detect_result;

typedef struct bef_enigma_point {
    float x;
    float y;
} bef_enigma_point;

typedef struct bef_enigma {
    int type;
    char *text;
    bef_enigma_point *points;
    int points_len;
}bef_enigma;

typedef struct  bef_enigma_detect_st {
    bef_enigma *enigma;
    int codeCount;
    float zoom_in_factor;
}bef_enigma_result;

typedef struct bef_text_content_st {
    int *length;
    char **text;
    int count;
}bef_text_content;

#define BEF_NUM_EXPRESSION_DEF 7 // add for VE demo compile
typedef enum {
    BEF_ANGRY = 0,                   // angry
    BEF_DISGUST = 1,                 // disgust
    BEF_FEAR = 2,                    // afraid
    BEF_HAPPY = 3,                   // happy
    BEF_SAD = 4,                     // sad
    BEF_SURPRISE = 5,                // surprise
    BEF_NEUTRAL = 6,                 // calm
    BEF_NUM_EXPRESSION = BEF_NUM_EXPRESSION_DEF           // number of emoticons 
}bef_expression_type;

typedef struct bef_face_attribute_info_st{
    float age;                          // Predicted age value, value range [0, 100]
    float boy_prob;                     // Probability value predicted as male, value range [0.0, 1.0]
    float attractive;                   // Predicted face value score, range [0, 100]
    float happy_score;                  // Predicted smile level, range [0, 100]
    bef_expression_type exp_type;            // Predicted emoji category
    float exp_probs[BEF_NUM_EXPRESSION_DEF];    // The predicted probability of each expression, without smoothing
    float real_face_prob;               // Predict the probability of belonging to a real face, used to distinguish non-real faces such as sculptures and comics
    float quality;                      // Predict the quality score of the face, range [0, 100]
    float arousal;                      // Emotional intensity
    float valence;                      // The degree of positive and negative emotions
    float sad_score;                    // Sadness
    float angry_score;                  // Angry degree
    float surprise_score;               // Degree of surprise
    float mask_prob;                    // Predict the probability of wearing a mask
    float wear_hat_prob;                // Probability of wearing a hat
    float mustache_prob;                // Bearded probability
    float lipstick_prob;                // Probability of applying lipstick
    float wear_glass_prob;              // Probability with ordinary glasses
    float wear_sunglass_prob;           // Probability with sunglasses
    float blur_score;                   // Blur degree
    float illumination;                 // illumination
#if BEF_EFFECT_AI_LABCV_TOBSDK
    float confused_prob;                ///< 疑惑表情概率
#endif
} bef_face_attribute_info;

typedef struct bef_expersion_detect_st {
    bef_face_attribute_info     faceAttributeInfo[BEF_MAX_FACE_NUM];
    int faceCount;
}bef_expression_detect_result;

// Face attribute related
typedef struct bef_face_attrs_info_st{
    int id;
    float left_plump;
    float left_plump_score;
    float right_plump;
    float right_plump_score;
    float left_double;
    float left_double_score;
    float right_double;
    float right_double_score;
    float face;
    float face_score;
    float facelong;
    float facelong_score;
    float eye;
    float eye_score;
    float jaw;
    float jaw_score;
    float facewidth;
    float facewidth_score;
    float facesmooth;
    float facesmooth_score;
    float nosewidth;
    float nosewidth_score;
    float forehead;
    float forehead_score;
    float chin;
    float chin_score;
    float lwrinkle;
    float lwrinkle_score;
    float leyebag;
    float leyebag_score;
    float rwrinkle;
    float rwrinkle_score;
    float reyebag;
    float reyebag_score;
    float faceratio;
    float faceratio_score;
    float mouthwidth;
    float mouthwidth_score;
    float eyeshape;
    float eyeshape_score;
    float eyedist;
    float eyedist_score;
    float eyebrowdist;
    float eyebrowdist_score;
} bef_face_attrs_info;

typedef struct bef_face_attrs_result_st {
    int face_count;
    bef_face_attrs_info attr_array[BEF_MAX_FACE_NUM];
} bef_face_attrs_result;

// microphone attention detection
typedef struct bef_microphone_attention_detect_st {
    unsigned char* alpha;  // alpha[i, j] represents the predicted value of the mask at point (i, j), the value is between [0, 255]
    int width;
    int height;
    float show;
}bef_microphone_attention_result;


//car segmentation  （no used）
#define     CarSegWidth 480
#define     CarSegHeight 640

typedef struct bef_single_car_info{
    int bounding_box[4];
    int brand_bounding_box[4];          // License plate bbox
    int direction;
    int car_id;
    bool is_new;
    int landmarks[8];                   // Key points of license plate
    bool valid_landmarks;
    float car_prob;                     // Confidence
    int color;                          // Car color
    bool valid_segmentation;
    unsigned char *segmented_car;       // Mask
    int left_seg_border;                // X-direction offset of the split edge
    int up_seg_border;                  // Y-direction offset of the split edge
    int seg_width;
    int seg_height;
}bef_car_info;

#define BEF_CAR_MAX_NUM 5
typedef struct bef_car_segmentation_st {
    unsigned int alphaTextureId;
    int detected_car_number;
    bef_rotate_type rotateType;
    struct bef_single_car_info car_info[BEF_CAR_MAX_NUM];
} bef_car_segmentation;

enum bef_body_dance_mode_type : int {
    bef_body_dance_mode_type_normal = 0,
    bef_body_dance_mode_type_crazy,
};

//license plate
#define     PlateInputWidth 480
#define     PlateInputHeight 640

typedef struct bef_single_plate_info_st {
    float landmarks[8];
    int plate_id;
}bef_single_plate_info;

#define BEF_LICENSE_PLATE_DETECT_MAX_NUM 5

typedef struct bef_license_plate_detect_st {
    int plate_count;
    bef_single_plate_info plate_info[BEF_LICENSE_PLATE_DETECT_MAX_NUM];
} bef_license_plate_detect;
//

typedef enum {
    bef_music_beat_type_unknown = 0,
    bef_music_beat_type_nearest = 1,
    bef_music_beat_type_linear
} bef_music_beat_type;

typedef struct bef_music_beat_config_st {
    bef_music_beat_type type;
    float max_beat;
    float min_beat;
    int step;
    float radius;
    float offset;
    float music_duration;
    int music_framerate;
    
}bef_music_beat_config;

typedef void *bef_hand_sdk_handle;

typedef void *bef_enigma_sdk_handle;

typedef enum {
    BEF_KEEP_ROI_SIZE = 1,  // Set whether to change the size of ROI(Not currently supported)
    BEF_CODE_TYPE = 2, // Specify the type of QR code, there are currently 2 types {CODE_TYPE_QRCODE, CODE_TYPE_DY_CODE}
    BEF_EC_LEVEL = 3, // Set the verification level, there are currently 4 levels: {0, 1, 2, 3}, the larger the number, the higher the level, the higher the level, the stronger the fault tolerance of the QR code, but the fewer characters can be encoded
    BEF_VERSION = 4, // Set the version level, there are currently 6 versions: {1, 2, 3, 4, 5, 6}, the higher the version, the more data can be accommodated
    BEF_DECODE_MULTIPLE = 5, // If there are multiple codes on the captured picture, then set this value to 1, it will return the results of multiple codes, by default only one result is returned
    BEF_AUTO_ZOOM_IN = 6, // When the QR code is relatively small, set whether to automatically scale
    BEF_BACKGROUND_MODE = 7, // Specify whether the image generated by the encoding has a transparent channel, 0 means no transparent channel, and a three-channel picture is generated, 1 means that the ring area of ​​the QR and the outside of the logo are transparent, and a four-channel picture is generated, and 2 means that all other parts except the DY QR area For transparency, generate four-channel pictures
    BEF_SCAN_TYPE = 8, //camera mode or photo mode
    
    BEF_ENABLE_RF = 9, //support inverse mode and mirror mode
    
    BEF_ENHANCE_CAMERA = 10, //enhance camera but slow
} bef_enigma_param_type;

#define     SkySegSmallWidth 128
#define     SkySegSmallHeight 224

#define     BuildingSegSmallWidth 153
#define     BuildingSegSmallHeight 268

#if defined(TARGET_OS_ANDROID) && BEF_ALGORITHM_CONFIG_CHRY_CUSTOMIZED
#define     HairColorSmallWidth 192
#define     HairColorSmallHeight 384 // Long side length limit
#else
#define     HairColorSmallWidth 128
#define     HairColorSmallHeight 256 // Long side length limit
#endif

#define MattingNPUSmallWidth   192
#define MattingNPUSmallHeight  336

#define MattingSmallWidth     128
#define MattingSmallHeight    224

#define ClothesSegSmallWidth     224
#define ClothesSegSmallHeight    224

#define     HeadSegWidth 128
#define     HeadSegHeight 128

#define BIG_GAN_HEIGHT 256
#define BIG_GAN_WIDTH 256

#define     NailSegWidth 448
#define     NailSegHeight 448

#define GroundSegSmallWidth     128
#define GroundSegSmallHeight    224

#define SaliencySegWidth 360
#define SaliencySegHeight 360

#define OilPaintWidth 720
#define OilPaintHeight 1280

typedef struct _HeadSegAlphaMask
{
    unsigned char mask[HeadSegWidth*HeadSegHeight];
} HeadSegAlphaMask;

// Hair Color
typedef struct bef_hair_color_mixture_param_st {
    float mixtureParam;
} bef_hair_color_mixture_param;

typedef union _HairColorMask
{
    unsigned char mask[4*HairColorSmallWidth*HairColorSmallHeight];
    unsigned char mask2[2*HairColorSmallHeight][2*HairColorSmallWidth];
} HairColorMask;


typedef struct bef_hair_color_st {
    unsigned int alphaTextureId;
    bef_hair_color_mixture_param mixtureParam;
    bef_rectf hairMaskRect;
    bef_rotate_type rotateType;
} bef_hair_color;

//: public bef_base_effect_info
typedef struct bef_auxiliary_data_st {
    bef_face_info *face_detect_data;
    bef_matting *matting_data;
    bef_hair_color *hair_color_data;
    bef_music_effect_data *music_effect_data;
    bef_AR_effect *ar_Data;
    bool ignoreAlpha;
} bef_auxiliary_data;

typedef struct bef_audio_progress_st {
    int audioIndex;
    int currentLoopIndex;
    float currentPlayingTime;
} bef_audio_progress;

typedef struct bef_srt_line_st {
    int index;
    float startTime;
    float endTime;
    unsigned int* text;
    int length;
} bef_srt_line;

typedef struct bef_srt_data_st {
    bef_srt_line* data;
    int count;
} bef_srt_data;

// M        charSize, letterSpacing, lineWidth, lineHeight, textAlign, textIndent, split
// Aweme    charSize, lineWidth, textAlign, split, lineCount, familyName, textColor, backColor, isPlaceholder
typedef struct bef_text_layout_st {
    int charSize;
    int letterSpacing;
    int lineWidth;
    float lineHeight;
    int textAlign;
    int textIndent;
    int split;
    
    int lineCount;
    char * familyName;
    unsigned int textColor;
    unsigned int backColor;
    bool isPlaceholder;
} bef_text_layout;

#define Matrix4dSize 16
#define Matrix3dSize 9
#define Vector3dSize 3

typedef struct {
    float rotation[Matrix3dSize];
    float position[Vector3dSize];
} bef_pose;

typedef struct {
    float matrix[16];
} bef_matrix4x4;


// intrinsic: An array storing the camera intrinsic matrix. This matrix can be
//         computed from FOV and frame size.
//         For example, a valid camera matrix for a 360p frame is:
//             camMat = {994.171204, 0.000000,   630.943665,
//                       0.000000,   994.171204, 359.941803,
//                       0.000000,   0.000000,   1.000000}
typedef struct bef_camera_intrinsic_st {
    float intrinsic[Matrix3dSize];
} bef_camera_intrinsic;

typedef struct bef_src_texture_st {
    unsigned int index;
    int width;
    int height;
    int bufferWidth; // Two-way buffer width
    int bufferHeight; // Two-way buffer height
    bef_pixel_format format; // Two-way buffer format
    const unsigned char *buffer;
    const unsigned char *detectBuffer; // Two-way buffer
    void *nativeBuffer; // native buffer (CVPixelBufferRef/AHardwareBuffer)
    bef_pixel_buffer *yuvData;  // yuv data for windows
} bef_src_texture;

typedef struct bef_src_device_texture_st {
    device_texture_handle deviceTexture;
    int width;
    int height;
    int bufferWidth; // Two-way buffer width
    int bufferHeight; // Two-way buffer height
    bef_pixel_format format; // Two-way buffer format
    const unsigned char *buffer;
    const unsigned char *detectBuffer; // Two-way buffer
    void *nativeBuffer; // native buffer (CVPixelBufferRef/AHardwareBuffer)
} bef_src_device_texture;

#define BEF_TEXTURE_USAGE_DEFAULT   0
#define BEF_TEXTURE_USAGE_IN  0x00010000
#define BEF_TEXTURE_USAGE_OUT 0x00100000
#define BEF_TEXTURE_USAGE_CAMERA0 0x0001
#define BEF_TEXTURE_USAGE_CAMERA1 0x0002
#define BEF_TEXTURE_USAGE_GAME0   0x0004
#define BEF_TEXTURE_USAGE_GAME1   0x0008
#define BEF_TEXTURE_USAGE_LAYOUT0 0x0010
#define BEF_TEXTURE_USAGE_LAYOUT1 0x0020

typedef struct bef_texture_param_st {
    unsigned int index; // texture id
    int width;  //width
    int height; //height
    bef_pixel_format format; //texture pixel format
    void *nativeBuffer; // native buffer (CVPixelBufferRef/AHardwareBuffer)
    unsigned int usage;
} bef_texture_param;

typedef struct bef_texture_param_device_texture_st {
    device_texture_handle deviceTexture;
    int width;  //width
    int height; //height
    bef_pixel_format format; //texture pixel format
    void *nativeBuffer; // native buffer (CVPixelBufferRef/AHardwareBuffer)
    unsigned int usage;
} bef_texture_param_device_texture;

// Algorithm detection parameters
typedef struct bef_algorithm_param_st {
    double timeStamp;
    bool isForce; // Whether to force the detection (force the algorithm to be executed once in the current frame to avoid every other frame)
    bool isSync; // Whether synchronization is detected (used when forced synchronization is required under the parallel framework)
    bool record; // Whether to save algorithm data
    unsigned int renderTexture; // Used when the rendering image and the algorithm recognition image are different
    unsigned long frameId;
    bool isBufferChange; //Whether image buffer size changes
    int skinUnifiedInputIndex; //Used for specify whether the input of skin unify
                               //has been processed with face beautify in retouch
    bool isForceDraw; //feature to force draw
    //reference texture used for correcting image tone when taking photo
    unsigned int referenceTexture;
    int referenceTextureWidth;
    int referenceTextureHeight;
    device_texture_handle referenceDeviceTexture;
} bef_algorithm_param;

typedef enum {
    BEF_ALGORITHM_REPLAY_NONE = 0,
    BEF_ALGORITHM_REPLAY_RECORD = 1, // Recording mode
    BEF_ALGORITHM_REPLAY_PLAY = 2, // Playback mode
    BEF_ALGORITHM_REPLAY_STOP = 3 // Save mode
} bef_algorithm_replay_mode;

// algorithm result of corner recognition
typedef struct bef_bling_data_st {
    bef_fpoint point;
    float quality;
} bef_bling_data;

#define MAX_CORNERS_NUM 50
typedef struct bef_bling_result_st {
    bef_bling_data cornersPoint[MAX_CORNERS_NUM];
    int cornersCount;
} bef_bling_result;

// algorithm result of corner recognition
typedef struct bef_kira_data_st {
    bef_fpoint point;
    float quality;
} bef_kira_data;
#define MAX_KIRA_CORNERS_NUM 4096
typedef struct bef_kira_result_st {
    bef_kira_data cornersPoint[MAX_KIRA_CORNERS_NUM];
    int cornersCount;
} bef_kira_result;

// algorithm result of portait matting / sky seg
typedef struct bef_matting_result_st {
    unsigned char alphaMask[MattingSmallWidth*MattingSmallHeight*4];
    int realW;
    int realH;
    int alphaMaskChannels;
} bef_matting_result;

// algorithm result of mug recognition
#define MAX_MUG_NUM 10
typedef struct bef_mug_result_st {
    bef_rectf mugRects[MAX_MUG_NUM];
    bef_fpoint points[MAX_MUG_NUM][4];
    float probs[MAX_MUG_NUM];
    int ids[MAX_MUG_NUM];
    int mug_num;
}bef_mug_result;

// algorithm result of head seg
typedef struct bef_headseg_data_st {
    HeadSegAlphaMask headseg_mask_alpha;
    double matrix[6];
    double xScale;
    double yScale;
} bef_headseg_data;

#define BEF_MAX_HEADSEGFACE_NUM 2
typedef struct bef_head_seg_result_st {
    bef_headseg_data headseg_infos[BEF_MAX_HEADSEGFACE_NUM];
    int head_count;
} bef_head_seg_result;

typedef struct bef_hair_color_result_st {
    unsigned int alphaTextureId;
    HairColorMask alphaMask;
    bef_rotate_type rotateType;
    bef_hair_color_mixture_param mixtureParam;
    bef_rectf hairMaskRect;
    int realW;
    int realH;
} bef_hair_color_result;

// algorithm result of 3d face fitting mesh
typedef struct bef_face_fitting_mesh_info_st {
    int id;                     // id
    const float* vertex;        // The vertex of 3D model
    int vertex_count;           // The length of vertex array
    const float* landmark;      // An array of landmark coordinate values ​​projected from the 3d model to image coordinates
    int landmark_count;         // The length of landmark array
    const float* param;         // Solution optimized parameters, [scale，rotatex, rotatey, rotatez, tx, ty, alpha0, alpha1 ......]
    int param_count;            // The length of param array
    float mvp[16];
    float model[16];            // Model matrix
    const float * normal;       // Normals in model space, the length is the same as vertex_count
    const float * tangent;      // The tangent under the model space has the same length as vertex_count
    const float * bitangent;    // The secondary tangent in model space is the same length as vertex_count
    float rvec[3];              // Opencv solvepnp output rotation vector
    float tvec[3];              // Opencv solvepnp output translation vector
} bef_face_fitting_mesh_info;

typedef struct bef_face_fitting_mesh_config_st {
    int version_code;                           // Model version number
    const float* uv;                            // Uv coordinates of standard expanded image
    int uv_count;                               // The length of the uv array
    const unsigned short* flist;                // 3d model vertex index array (face)
    int flist_count;                            // The length of the flist array
    const unsigned short* landmark_triangle;    // landmark triangle array after triangulation
    int landmark_triangle_count;                // The length of the landmark array
    
    int num_vertex;                             // = uv_count/2 = vertex_count/3    Number of vertices
    int num_flist;                              // = flist_count / 3                Number of faces
    int num_landmark_triangle;                  // = landmark_triangle_count / 2    Number of triangles
    int mum_landmark;                           // = landmark_count / 3             the number of landmrk
    int num_param;                              // = param_count                    Number of solving parameters
}bef_face_fitting_mesh_config;

typedef struct bef_face_fitting_mesh_result_st {
    bef_face_fitting_mesh_info* face_mesh_info;
    int face_mesh_info_count;
    bef_face_fitting_mesh_config* face_mesh_cfg;
    int view_width;
    int view_height;
} bef_face_fitting_mesh_result;

typedef struct bef_object_tracking_result_st {
     int   status;   // 1 tracking success, not 1 tracking fail.
     float width;    // tracking area width, normalized: 0.0 ~ 1.0
     float height;   // tracking area height, normalized: 0.0 ~ 1.0
     float center_x; // tracking area center x, normalized: 0.0 ~ 1.0
     float center_y; // tracking area center y, normalized: 0.0 ~ 1.0
     float rotate;   // // tracking area roate angle, clockwise.
}bef_object_tracking_result;

typedef enum {
    BEF_FACE_TRACKING_STATUS_UNKNOWN = 0,
    BEF_FACE_TRACKING_STATUS_APPEAR = 1, // New, unknown feature
    BEF_FACE_TRACKING_STATUS_REGISTER = 2, // New, known features
    BEF_FACE_TRACKING_STATUS_TRACK = 3,
    BEF_FACE_TRACKING_STATUS_MISS = 4
} bef_face_tracking_status;

#ifndef TRANSPARENCY_CENTER_I18N
// face features with extra infos of face ID and status，
typedef struct bef_face_verify_dynamic_info_st {
    bef_face_106 faceInfos[BEF_MAX_FACE_NUM];
    bef_face_tracking_status faceStatus[BEF_MAX_FACE_NUM];
    float faceFeatures[BEF_MAX_FACE_NUM][BEF_FACE_FEATURE_DIM];
    int valid_face_num;
    const char* model_version;
} bef_face_verify_dynamic_info;
#endif

// skinunified
typedef struct xt_algorithm_result_skin_unified_st {
    const unsigned char *imageData;
    int width;
    int height;
} xt_algorithm_result_skin_unified;

// skeleton
#define SKELETON_KEY_POINT_NUM 18
typedef struct xt_bef_skeleton_info_st {
    bef_fpoint_detect point[SKELETON_KEY_POINT_NUM];
    bef_rectf rect;
    int ID;
} xt_bef_skeleton_info;
#define BEF_MAX_SKELETON_NUM 5
typedef struct xt_algorithm_result_skeleton_st {
    bef_rotate_type orient;
    int body_count;
    xt_bef_skeleton_info body[BEF_MAX_SKELETON_NUM];
    float xScale;
    float yScale;
    float width;
    float height;
} xt_algorithm_result_skeleton;

#define MouthMaskWidth 256
typedef struct xt_bef_mouth_mask_st {
    int face_mask_size;        // face_mask_size
    unsigned char face_mask[MouthMaskWidth * MouthMaskWidth];  // face_mask
    float warp_mat[6];          // warp mat data ptr, size 2*3
    int id;
} xt_bef_mouth_mask;
typedef struct xt_algorithm_result_mouth_mask_info_st {
    xt_bef_mouth_mask mouth_mask[10];
    int face_count;
} xt_algorithm_result_mouth_mask_info;
typedef struct xt_algorithm_result_face_st {
    xt_algorithm_result_mouth_mask_info* mouthInfo;
    bef_face_info faceInfo;
    bef_hand_t p_hands[10];
    int hand_count;
    bef_image image;
    bef_face_info rawFaceInfo;
    double xScale;
    double yScale;
    bool is_aux_data; // Distinguish whether it is fake face data, fake face data comes from _fillRenderInfo setBundle.
} xt_algorithm_result_face;

typedef struct xt_algorithm_result_structxt_st {
    unsigned char *StereoH;
    unsigned char *StereoS;
    int StereoH_w;
    int StereoH_h;
    int StereoS_w;
    int StereoS_h;
} xt_algorithm_result_structxt;

// struct for xt
typedef struct bef_xt_algorithm_result_public_st {
    xt_algorithm_result_skin_unified* xt_skinunified;
    xt_algorithm_result_skeleton* xt_skeleton;
    xt_algorithm_result_face* xt_face;
    xt_algorithm_result_structxt* xt_structxt;
} bef_xt_algorithm_result_public;

#define LOCAL_EDIT_MAX_POINT_COUNT 8
typedef struct bef_local_edit_info_st {
    float pointX;
    float pointY;
    float scaleSize;
    float intensity;
    float maskFlag;
    int count;
} bef_local_edit_info;

typedef struct bef_xt_local_edit_param_st{
    int xtPointCount;
    float xtPointX[LOCAL_EDIT_MAX_POINT_COUNT];
    float xtPointY[LOCAL_EDIT_MAX_POINT_COUNT];
    float xtScale[LOCAL_EDIT_MAX_POINT_COUNT];
    float xtIntensity[LOCAL_EDIT_MAX_POINT_COUNT];
    float xtFlagMask[LOCAL_EDIT_MAX_POINT_COUNT];
} bef_xt_local_edit_param;


typedef struct bef_red_envelope_frame_client_path
{
    bool isVisible;
    float* vertexes;
    unsigned int count;
} bef_red_envelope_frame_client_path;

typedef enum {
    BEF_FLUSH_MODE_NONE = 0,   // not flush
    BEF_FLUSH_MODE_FBO = 1,  // flush after bind fbo
    BEF_FLUSH_MODE_AFTER_RENDER = 2,  // flush after render
} bef_flush_mode;

typedef struct bef_statistics_frame_cost_st
{
    double processTextureTime;
    double pureRenderTime;
    double waitAlgorithmTime;
    double pureAlgorithmTime;
} bef_statistics_frame_cost;

#endif //EFFECT_SDK_BEF_EFFECT_BUSINESS_C_DEFINE_H
