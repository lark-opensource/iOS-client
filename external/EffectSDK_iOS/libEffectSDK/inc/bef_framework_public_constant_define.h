//
// Created by lizhiqi on 2018/5/3.
//

#ifndef EFFECT_SDK_BEF_EFFECT_CONSTANT_DEFINE_H
#define EFFECT_SDK_BEF_EFFECT_CONSTANT_DEFINE_H


#define BEF_RESULT_SUC                       0  // return successfully
#define BEF_RESULT_SUC_EMPTY_DRAW            1  // return successfully
#define BEF_RESULT_SUC_EMPTY_ALG             2  // return successfully
#define BEF_RESULT_SUC_VRSR_FRAME            3  // return successfully for vrsr frame
#define BEF_RESULT_FAIL                     -1  // internal error
#define BEF_RESULT_FILE_NOT_FIND            -2  // file not found

#define BEF_RESULT_INVALID_INTERFACE        -3  // interface not implemented
#define BEF_RESULT_PARSE_FAIL               -4  // protocol parse failed

#define BEF_RESULT_INVALID_EFFECT_HANDLE    -5  // invalid Effect handle
#define BEF_RESULT_INVALID_EFFECT_MANAGER   -6  // invalid EffectManager
#define BEF_RESULT_INVALID_FEATURE_HANDLE   -7  // invalid Feature handle
#define BEF_RESULT_INVALID_FEATURE          -8  // invalid Feature
#define BEF_RESULT_INVALID_RENDER_MANAGER   -9  // invalid RenderManager

#define BEF_RESULT_INVALID_ALG_SYSTEM       -10  // invalid AlgorithmSystem

//Algorithm
#define BEF_RESULT_INVALID_ALG_RES          -11 // invalid algorithm result
#define BEF_RESULT_INVALID_ALG_FACE_RES     -12 // invalid face detection algorithm result
#define BEF_RESULT_INVALID_ALG_CAT_FACE_RES -13 // invalid cat face detection algorithm result
#define BEF_RESULT_INVALID_ALG_HAND_RES     -14 // invalid hand detection algorithm result
#define BEF_RESULT_INVALID_ALG_BODY_RES     -15 // invalid body detection algorithm result

#define BEF_RESULT_INVALID_ALG_DETECT       -16 // invalid algorithm handle

#define BEF_RESULT_ALG_INIT_FAIL            -17 // algorithm failed to init
#define BEF_RESULT_ALG_ENABLE_FAIL          -18 // algorithm failed to enable
#define BEF_RESULT_ALG_PROCESS_FAIL         -19 // algorithm failed to create
#define BEF_RESULT_ALG_TASK_FAIL            -20 // algorithm task failed to create

#define BEF_RESULT_ALG_FACE_INIT_FAIL       -21 // face detection failed to init
#define BEF_RESULT_ALG_FACE_106_CREATE_FAIL -22 // 106 face detection failed to create
#define BEF_RESULT_ALG_FACE_280_CREATE_FAIL -23 // 280 face detection failed to create
#define BEF_RESULT_ALG_FACE_PREDICT_FAIL    -24 // face detection failed to predict

#define BEF_RESULT_ALG_EXP_CREATE_FAIL      -25 // expression detection failed to create

#define BEF_RESULT_ALG_HAND_CREATE_FAIL     -26 // hand detection failed to create
#define BEF_RESULT_ALG_HAND_PREDICT_FAIL    -27 // hand detection failed to predict

#define BEF_RESULT_ALG_CAT_FACE_CREATE_FAIL -28 // cat face detection failed to create

#define BEF_RESULT_ALG_SKELETON_CREATE_FAIL -29 // skeleton failed to create
#define BEF_RESULT_ALG_SKELETON_INIT_FAIL   -30 // skeleton failed to init

#define BEF_RESULT_ALG_TEMPLATE_CREATE_FAIL -31 // template matching failed to create
#define BEF_RESULT_ALG_TEMPLATE_INIT_FAIL   -32 // template matching failed to init

#define BEF_RESULT_ALG_HAIR_CREATE_FAIL     -33 // hair detection failed to create

#define BEF_RESULT_ALG_MATTING_CREATE_FAIL  -34 // Matting failed to create

#define BEF_RESULT_ALG_SKY_SEG_CREATE_FAIL  -35 // sky seg failed to create

#define BEF_RESULT_INVALID_TEXTURE          -36 // invalid texture
#define BEF_RESULT_INVALID_IMAGE_DATA       -37 // invalid image data
#define BEF_RESULT_INVALID_IMAGE_FORMAT     -38 // invalid image format
#define BEF_RESULT_INVALID_PARAM_TYPE       -39 // invalid param type
#define BEF_RESULT_INVALID_RESOURCE_VERSION -40 // resource sdk version too high
#define EBF_RESULT_ALG_ENIGMA_INIT_FAIL     -41 // enigma detection failed to create
#define BEF_RESULT_ALG_ACTION_DETECT_CREATE_INIT_FAIL     -42 // action detection failed to create
#define BEF_RESULT_ALG_SKELETON_TRACKING_3D_FAIL -43 // 3d skeleton tracking failed to create
#define BEF_RESULT_ALG_PET_FACE_CREATE_FAIL -44 // cat face detection failed to create
#define BEF_RESULT_ALG_FACE_FITTING_INIT_FAIL -45 // 3d face fitting failed to init
#define BEF_RESULT_ALG_OBJECT_DETECT_FAIL -46 // object detection failed to create

#define BEF_RESULT_INVALID_PARAM_VALUE      -47 // invalid param

#define BEF_RESULT_ALG_BIG_HEAD -48         // big head failed to create
#define BEF_RESULT_ALG_CAR_BASE_FAIL -50  // car segmentation failed to create
#define BEF_RESULT_ALG_SCENE_RECOGNITION -49         // scene recognition failed to create
#define BEF_RESULT_ALG_FACEPARTBEAUTY_FAIL -51  // face part beauty failed to create
#define BEF_RESULT_ALG_FACE_ATTRIBUTES_FAIL  -52         // face attributes failed to create
#define BEF_RESULT_ALG_HDRNET_FAIL  -53         // HDRNET failed to create
#define BEF_RESULT_ALG_CLOTHESSEG_FAIL  -56        // clothesseg failed to create
#define BEF_RESULT_ALG_MICROPHONE_FAIL  -54         // microphone detection failed to create
#define BEF_RESULT_ALG_FACE_GAN_FAIL  -55         // FaceGan failed to create
#define BEF_RESULT_ALG_LICENSE_PLATE_FAIL -57// car license plate failed to create
#define BEF_RESULT_ALG_TRACKING_AR_FAIL  -59        // TRACKING_AR failed to create
#define BEF_RESULT_ALG_GAZE_ESTIMATION_FAIL  -60    // gazeEstimation failed to create
#define BEF_RESULT_ALG_MUG_CREATE_FAIL  -61        // Mug failed to create
#define BEF_RESULT_ALG_BLING_CREATE_FAIL  -62       // bling failed to create

#define BEF_RESULT_ALG_BIG_GAN_FAIL  -63
#define BEF_RESULT_ALG_OLD_GAN_CREATE_FAIL  -64        // Oldgan failed to create
#define BEF_RESULT_ALG_YOUNG_GAN_CREATE_FAIL    -65
#define BEF_RESULT_ALG_SKELETON_POSE_3D_CREATE_FAIL  -66  // SkeletonPose3D failed to create
#define BEF_RESULT_ALG_TEETH_FAIL -67 // teeth failed to create
#define BEF_RESULT_ALG_GENDER_GAN_CREATE_FAIL    -68
#define BEF_RESULT_ALG_FEMALE_GAN_FAIL  -69
#define BEF_RESULT_ALG_NAIL_CREATE_FAIL  -70        // Nail failed to create
#define BEF_RESULT_ALG_EARSEG_CREATE_FAIL -71 // earSeg failed to create
#define BEF_RESULT_ALG_MODEL_TEST_CREATE_FAIL -72 // model test failed to create
#define BEF_RESULT_ALG_OBJECT_TRACKING_FAIL -69 // pin tracking failed to create
#define BEF_RESULT_ALG_STRUCTXT_CREATE_FAIL  -73       // structxt failed to create

#define BEF_RESULT_ALG_GROUND_SEG_CREATE_FAIL  -74        // Ground segmentation failed to create
#define BEF_RESULT_ALG_LAUGH_GAN_FAIL -75       // laughgan failed to create
#define BEF_RESULT_ALG_WATERCOLOR_FAIL  -76  // water color failed to create
#define BEF_RESULT_ALG_FOOD_COMICS_FAIL  -77  // create food comics handle failed
#define BEF_RESULT_ALG_SCENE_NORMAL_FAIL -78 // SceneNormal failed to create
#define BEF_RESULT_ALG_AVATAR_3D_FAIL -79       //avatar3d failed to create
#define BEF_RESULT_ALG_FOOT_FAIL -80        //foot algorithm failed to create
#define BEF_RESULT_ALG_BUILDINGSEG_FAIL -81 // create buildingseg handle failed
#define BEF_RESULT_ALG_MANGA_FAIL  -82  // create manga algorithm handle failed
#define BEF_RESULT_ALG_BLOCKGAN_FAIL  -83 // create blockgan failed

#define BEF_RESULT_ALG_BEAUTYGAN_FAIL  -85 // create beautygan failed
#define BEF_RESULT_ALG_SKIN_SEG_FAIL -86 // create skinseg failed
#define BEF_RESULT_ALG_CLOTH_MESH_FAIL -87
#define BEF_RESULT_ALG_SWAPPER_ME_FAIL   -88  // create swapper me algorithm failed
#define BEF_RESULT_ALG_SALIENCY_SEG_FAIL -89 // create SaliencySeg failed

#define BEF_RESULT_ALG_SKIN_UNIFIED_CREATE_FAIL    -99
#define BEF_RESULT_SMASH_E_INTERNAL -101    // unknown error
#define BEF_RESULT_SMASH_E_NOT_INITED -102  // uninitialized resources
#define BEF_RESULT_SMASH_E_MALLOC -103      // failed to malloc
#define BEF_RESULT_SMASH_E_INVALID_PARAM -104
#define BEF_RESULT_SMASH_E_ESPRESSO -105
#define BEF_RESULT_SMASH_E_MOBILECV -106
#define BEF_RESULT_SMASH_E_INVALID_CONFIG -107
#define BEF_RESULT_SMASH_E_INVALID_HANDLE -108
#define BEF_RESULT_SMASH_E_INVALID_MODEL -109
#define BEF_RESULT_SMASH_E_INVALID_PIXEL_FORMAT -110
#define BEF_RESULT_SMASH_E_INVALID_POINT -111
#define BEF_RESULT_SMASH_E_REQUIRE_FEATURE_NOT_INIT -112
#define BEF_RESULT_SMASH_E_NOT_IMPL -113
#define BEF_RESULT_GL_CONTECT               -114 // invalid glcontext
#define BEF_RESULT_GL_TEXTURE               -115 // invalid gltexture

#define BEF_RESULT_ALG_FACE_BEAUTIFY_CREATE_FAIL -120
#define BEF_RESULT_ALG_FACE_BEAUTIFY_DETECT_FAIL -121
#define BEF_RESULT_ALG_OILPAINT_FAIL  -122  // create oilpaint algorithm handle failed
#define BEF_RESULT_INVALID_ALG_HAND_ROI_RES     -123 // invalid hand detection roi algorithm result
#define BEF_RESULT_ALG_INTERACTIVE_MATTING_FAIL -124 // InteractiveMatting failed to create
#define BEF_RESULT_ALG_HANDTV_CREATE_FAIL    -125  // create handtv algorithm handle failed
#define BEF_RESULT_ALG_HANDTV_PREDICT_FAIL   -126  // predict handtv algorithm result failed
#define BEF_RESULT_ALG_KIRA_FAIL   -127  // predict handtv algorithm result failed
#define BEF_CREATE_THREAD_FAIL                 -67  // failed to create thread

#define BEF_RESULT_ALG_FACE_106_LOAD_MODEL_FAIL         -130  // failed to load 106 model
#define BEF_RESULT_ALG_FACE_280_LOAD_MODEL_FAIL         -131  // failed to load 280 model
#define BEF_RESULT_ALG_FACE_106_FILE_FAIL               -132  // 106 file empty
#define BEF_RESULT_ALG_FACE_280_FILE_FAIL               -133  // 280 file empty
#define BEF_RESULT_ALG_FACE_280_LOAD_FAST_MODEL_FAIL    -134  // failed to load 280 fast model
#define BEF_RESULT_ALG_FACE_280_FAST_FILE_FAIL          -135  // 280 fast file empty
#define BEF_PAUSE_TYPE_NONE                  0x00000000
#define BEF_PAUSE_TYPE_BGM                   0x00000001
#define BEF_PAUSE_TYPE_SLAM                  0x00000002
#define BEF_PAUSE_TYPE_GAME                  0x00000004
#define BEF_PAUSE_TYPE_STICKER               0x00000008     // pause sticker updating
#define BEF_PAUSE_TYPE_AMAZ                  0x00010000     // pause amazing
#define BEF_PAUSE_TYPE_ALL                   0xFFFFFFFF

#define BEF_REQUIREMENT_EXTEND_NONE          {0x00000000 , 0x00000000}
#define BEF_REQUIREMENT_NONE                 0x00000000

// Info Sticker GIF ERROR CODE
#define BEF_RESULT_GIF_UNSUPPORT    -301  // GIF not supported
#define BEF_RESULT_GIF_ERROR        -302  // GIF read error
#define BEF_RESULT_LUT_UNSUPPORT    -303  // Cube or 3DL format not supported

// Be used in bef_effect_set_sticker_time_domain
#define BEF_ERROR_TIME                  -1001 // time range error
// Be used in bef_info_sticker_api.h
#define BEF_UNKOWN_TIME                 -1002 // invalid time param
#define BEF_RESULT_BLACK                -1003 // Rendering result is black

// Used in bef_effect_audio_api.h
#define BEF_RESULT_AUDIO_INTERNAL_ERROR  -10000
#define BEF_RESULT_AUDIO_HANDLE_INVALID  -10001

#define BEF_PIXELLOOP_CACHE_KEY "pixelLoopInput"

// ET Type definitions
#define BEF_ET_TYPE_MAIN_ROUTE_TRACKING 0 // for effect main routing tracking
#define BEF_ET_TYPE_EFFECT_SDK_FIRST_FRAME_TRACKING 2 // for effectsdk first camera frame tracking
#define BEF_ET_TYPE_ET_TYPE_SET_STICKER_TRACKING 3 // for regular prop/sticker tracking
#define BEF_ET_TYPE_COMPOSER_TRACKING 4 // for beauty and filter prop/sticker tracking

#endif //EFFECT_SDK_BEF_EFFECT_CONSTANT_DEFINE_H
