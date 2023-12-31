//
//  bef_effect_api.h
//  byted-effect-sdk
//
//  Created by bytedance on 05/29/2018.
//

#ifndef bef_effect_touch_api_h
#define bef_effect_touch_api_h

#include "bef_framework_public_base_define.h"

typedef struct bef_one_touch_t {
    int id;
    float x;
    float y;
    float force;
    float maxForce;
} bef_one_touch;

typedef enum 
{
    BEF_TOUCH_BEGAN,//0
    BEF_TOUCH_MOVED,//deprecated
    BEF_TOUCH_ENDED,//2
    BEF_TOUCH_CANCELLED,//3
    BEF_PAN,//4
    BEF_ROTATE,//5
    BEF_SCALE,//6
    BEF_LONG_PRESS,//7,
    BEF_DOUBLE_CLICK//8
} EventCode;

typedef enum
{
    BEF_GESTURE_TYPE_UNKNOWN,
    BEF_GESTURE_TYPE_TAP,
    BEF_GESTURE_TYPE_PAN,
    BEF_GESTURE_TYPE_ROTATE,
    BEF_GESTURE_TYPE_SCALE,
    BEF_GESTURE_TYPE_LONG_PRESS
} bef_gesture_type;

typedef enum
{
    TOUCH_BEGAN = 0,
    TOUCH_MOVED = 1,
    TOUCH_STATIONARY = 2,
    TOUCH_ENDED = 3, 
    TOUCH_CANCELED = 4
}bef_touch_type;

typedef enum
{
    GESTURE_TAP = 0,
    GESTURE_SWIPE,
    GESTURE_PINCH,
    GESTURE_LONG_TAP,
    GESTURE_DRAG,
    GESTURE_DROP,
    GESTURE_DOUBLE_CLICK,
    ANY_SUPPORTED = -1,
}bef_gesture_event;

static const int BEF_MAX_TOUCHES = 6;
static const int BEF_MAX_PATCH_TOUCHES = 20;

typedef struct bef_touchs_t {
    EventCode       eventCode;
    bef_one_touch touches[BEF_MAX_TOUCHES];
} bef_touchs;

typedef struct bef_duet_touchs_t {
    EventCode       eventCode;
    bef_one_touch touches[BEF_MAX_TOUCHES];
} bef_duet_touchs;

typedef struct bef_touch_pointer_t{
    bef_touch_type  type;
    unsigned int pointerId;
    float x;
    float y;
    float force;
    float majorRadius;
    int   count;
}bef_touch_pointer;

// xinyguan, for AR feature, 2018/07/12
typedef struct bef_manipulate_data_st {
    EventCode       eventCode;
    float m_x;
    float m_y;
    float m_dx;
    float m_dy;
    float m_factor;
    bef_gesture_type m_type;
} bef_manipulate_data;

typedef struct bef_manipulate_duet_data_st {
    EventCode       eventCode;
    float m_x;
    float m_y;
    float m_dx;
    float m_dy;
    float m_factor;
    bef_gesture_type m_type;
} bef_manipulate_duet_data;

typedef struct bef_batch_touchs_t {
    bef_manipulate_data toucheArry[BEF_MAX_PATCH_TOUCHES];
    int count;
} bef_batch_touchs;


BEF_SDK_API bool bef_effect_touch_event(bef_effect_handle_t handle, unsigned int pointerId, float x, float y, 
    float force, float majorRadius, bef_touch_type evt, int pointerCount);

BEF_SDK_API bool bef_effect_is_gesture_registered(bef_effect_handle_t handle, bef_gesture_event evt);

BEF_SDK_API bool bef_effect_suspend_gesture_recognizer(bef_effect_handle_t handle, bef_gesture_event evt, bool suspend);

BEF_SDK_API void bef_effect_update_touches(bef_touchs touches);

BEF_SDK_API void bef_effect_update_manipulation(bef_effect_handle_t handle, bef_manipulate_data manipulations);

//************************** Compatible with previous slam Touch events ***************************

BEF_SDK_API void bef_effect_process_touchEvent(bef_effect_handle_t handle, float x, float y);

BEF_SDK_API void bef_effect_process_panEvent(bef_effect_handle_t handle, float x, float y, float factor);

BEF_SDK_API void bef_effect_process_scaleEvent(bef_effect_handle_t handle, float scale, float factor);

BEF_SDK_API void bef_effect_process_rotationEvent(bef_effect_handle_t handle, float rotation, float factor);

BEF_SDK_API void bef_effect_process_touchDownEvent(bef_effect_handle_t handle, float x, float y);

BEF_SDK_API void bef_effect_process_touchUpEvent(bef_effect_handle_t handle, float x, float y);


BEF_SDK_API void bef_effect_process_pan_event(bef_effect_handle_t handle, float x, float y, float dx, float dy, float factor);

BEF_SDK_API void bef_effect_process_long_press_event(bef_effect_handle_t handle, float x, float y);

BEF_SDK_API void bef_effect_process_double_click_event(bef_effect_handle_t handle, float x, float y);

BEF_SDK_API void bef_effect_process_touch_down_event(bef_effect_handle_t handle, float x, float y, bef_gesture_type type);

BEF_SDK_API void bef_effect_process_touch_up_event(bef_effect_handle_t handle, float x, float y, bef_gesture_type type);

BEF_SDK_API void bef_effect_process_batch_pan_event(bef_effect_handle_t handle, bef_batch_touchs* touchInfo);

#endif /* bef_effect_touch_api_h */
