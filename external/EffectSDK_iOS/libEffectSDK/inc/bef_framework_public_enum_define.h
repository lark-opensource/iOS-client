//
// Created by bytedance on 2018/5/3.
//

#ifndef EFFECT_SDK_BEF_EFFECT_ENUM_DEFINE_H
#define EFFECT_SDK_BEF_EFFECT_ENUM_DEFINE_H


typedef enum {
    BEF_RS_INIT,
    BEF_RS_LOADING,
    BEF_RS_VALID,
    BEF_RS_INVALID
} bef_resource_status;


// hand
typedef enum {
    BEF_HAND_MODEL_DETECT = 0x0001,
    BEF_HAND_MODEL_BOX_REG = 0x0002,
    BEF_HAND_MODEL_GESTURE_CLS = 0x0004,
    BEF_HAND_MODEL_KEY_POINT = 0x0008,
} bef_hand_model_type;

//handtv
typedef enum {
    BEF_HANDTV_MODEL_DETECT = 0x0001,
    BEF_HANDTV_MODEL_BOX_REG = 0x0002,
    BEF_HANDTV_MODEL_GESTURE_CLS = 0x0004,
    BEF_HANDTV_MODEL_KEY_POINT = 0x0008,
    BEF_HANDTV_MODEL_SEG = 0x0010,
    BEF_HANDTV_MODEL_SKELETON = 0x0020,
    BEF_HANDTV_MODEL_DYNAMIC = 0x0040,
    BEF_HANDTV_MODEL_PERSON_RECOGNITION = 0x0080,
} bef_handtv_model_type;



// @brief beautify param type
typedef enum {
    BEF_REQ = 1, /// contrast [0,1.0]
    BEF_BEAUTIFY_SMOOTH_STRENGTH = 3,   /// smooth intensity, [0,1.0]
    BEF_BEAUTIFY_BRIGHTEN_STRENGTH = 4,   /// brighten intensity, [0,1.0]
    BEF_BEAUTIFY_ENLARGE_EYE_RATIO = 5, /// enlarge eye ratio, [0,1.0], 0.0 for no efect
    BEF_BEAUTIFY_SHRINK_FACE_RATIO = 6,     /// shrink face ratio, [0,1.0], 0.0 for no effect
    BEF_BEAUTIFY_SHRINK_JAW_RATIO = 7,    /// shrink jaw ratio, [0,1.0], 0.0 for no effect
    BEF_BEAUTIFY_FILTER_TYPE = 8    /// filter type
} bef_beautify_type;



// Global filter direction
typedef enum {
    BEF_FILTER_DIRECTION_LEFT = -1,
    BEF_FILTER_DIRECTION_RIGHT = 1,
} bef_filter_direction;


typedef enum {
    IMU_ACCELERATOR = 1 << 0,
    IMU_GYROSCOP = 1 << 1,
    IMU_GRAVITY = 1 << 2,
    IMU_ORIENTATION = 1 << 3
} bef_imuinfo_flag;


typedef enum {
    IAT_BONE,   // bone skin animation
    IAT_SHADER, // shader param control animation
    IAT_UV,     // UV animation
    IAT_SEQUENCE_FRAME, // 2D sequence frame
    IAT_NONE
} bef_animation_type;

typedef enum {
    PAT_GESTURE, // particles follow hand
    PAT_HEADER, // particles follow face
    PAT_KEYFRAME,    // particles follow specified key frame
    PAT_NONE     // particles don't follow
}bef_particle_attach_type;



#endif //EFFECT_SDK_BEF_EFFECT_ENUM_DEFINE_H
