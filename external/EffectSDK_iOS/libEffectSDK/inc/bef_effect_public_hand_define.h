//
// Created by lizhiqi on 2018/4/23.
//

#ifndef EFFECT_SDK_BEF_EFFECTED_HAND_DETECT_DEFINE_H
#define EFFECT_SDK_BEF_EFFECTED_HAND_DETECT_DEFINE_H


#include "bef_framework_public_geometry_define.h"
#include <stdbool.h>

#define BEF_TT_HAND_GESTURE_HEART_A           0
#define BEF_TT_HAND_GESTURE_HEART_B           1
#define BEF_TT_HAND_GESTURE_HEART_C           2
#define BEF_TT_HAND_GESTURE_HEART_D           3
#define BEF_TT_HAND_GESTURE_OK                4
#define BEF_TT_HAND_GESTURE_HAND_OPEN         5
#define BEF_TT_HAND_GESTURE_THUMB_UP          6
#define BEF_TT_HAND_GESTURE_THUMB_DOWN        7
#define BEF_TT_HAND_GESTURE_ROCK              8
#define BEF_TT_HAND_GESTURE_NAMASTE           9
#define BEF_TT_HAND_GESTURE_PLAM_UP           10
#define BEF_TT_HAND_GESTURE_FIST              11
#define BEF_TT_HAND_GESTURE_INDEX_FINGER_UP   12
#define BEF_TT_HAND_GESTURE_DOUBLE_FINGER_UP  13
#define BEF_TT_HAND_GESTURE_VICTORY           14
#define BEF_TT_HAND_GESTURE_BIG_V             15
#define BEF_TT_HAND_GESTURE_PHONECALL         16
#define BEF_TT_HAND_GESTURE_BEG               17
#define BEF_TT_HAND_GESTURE_THANKS            18
#define BEF_TT_HAND_GESTURE_UNKNOWN           19
#define BEF_TT_HAND_GESTURE_CABBAGE           20
#define BEF_TT_HAND_GESTURE_THREE             21
#define BEF_TT_HAND_GESTURE_FOUR              22
#define BEF_TT_HAND_GESTURE_PISTOL            23
#define BEF_TT_HAND_GESTURE_ROCK2             24
#define BEF_TT_HAND_GESTURE_SWEAR             25
#define BEF_TT_HAND_GESTURE_HOLDFACE          26
#define BEF_TT_HAND_GESTURE_SALUTE            27
#define BEF_TT_HAND_GESTURE_SPREAD            28
#define BEF_TT_HAND_GESTURE_PRAY              29
#define BEF_TT_HAND_GESTURE_QIGONG            30
#define BEF_TT_HAND_GESTURE_SLIDE             31
#define BEF_TT_HAND_GESTURE_PALM_DOWN         32
#define BEF_TT_HAND_GESTURE_PISTOL2           33
#define BEF_TT_HAND_GESTURE_NARUTO1           34
#define BEF_TT_HAND_GESTURE_NARUTO2           35
#define BEF_TT_HAND_GESTURE_NARUTO3           36
#define BEF_TT_HAND_GESTURE_NARUTO4           37
#define BEF_TT_HAND_GESTURE_NARUTO5           38
#define BEF_TT_HAND_GESTURE_NARUTO7           39
#define BEF_TT_HAND_GESTURE_NARUTO8           40
#define BEF_TT_HAND_GESTURE_NARUTO9           41
#define BEF_TT_HAND_GESTURE_NARUTO10          42
#define BEF_TT_HAND_GESTURE_NARUTO11          43
#define BEF_TT_HAND_GESTURE_NARUTO12          44
#define BEF_TT_HAND_GESTURE_SPIDERMAN         45
#define BEF_TT_HAND_GESTURE_AVENGERS          46

#define BEF_TT_HAND_SEQ_ACTION_NONE         0 // Gesture sequence action, different from the static gesture above
#define BEF_TT_HAND_SEQ_ACTION_PUNCHING     1 // Punch
#define BEF_TT_HAND_SEQ_ACTION_CLAPPING     2 // applaud
#define BEF_TT_HAND_SEQ_ACTION_HIGH_FIVE    4 // high five

#define BEF_MAX_HAND_NUM 2
#define BEF_HAND_KEY_POINT_NUM 22
#define BEF_HAND_KEY_POINT_NUM_EXTENSION 2

#define BEF_MAX_HAND_TV_NUM 20
#define BEF_HAND_TV_KEY_POINT_NUM 22
#define BEF_HAND_TV_KEY_POINT_NUM_EXTENSION 2


struct bef_tt_key_point {
    float x; // Corresponding to cols, the range is between [0, width]
    float y; // Corresponding to rows, the range is between [0, height]
    bool is_detect; // If the value is false, then x,y is meaningless
};
typedef struct bef_hand_st {
    int id;                          
    bef_rect rect;                      ///< hand bbox
    unsigned int action;              ///< hand action 
    float rot_angle;                  ///< Hand rotation angle
    float score;                      ///< hand action confidence
    float rot_angle_bothhand;  ///< Angle between hands
    // Key points of the hand, if not detected, set to 0
    struct bef_tt_key_point key_points[BEF_HAND_KEY_POINT_NUM];
    // Hand extension point, if not detected, set to 0
    struct bef_tt_key_point key_points_extension[BEF_HAND_KEY_POINT_NUM_EXTENSION];
    unsigned int seq_action;        ///< 0 如果没有序列动作设置为0， 其他为有效值
} bef_hand, *ptr_bef_hand;

typedef struct bef_hand_info_st {
    bef_hand p_hands[BEF_MAX_HAND_NUM];    
    int hand_count;                       
} bef_hand_info, *ptr_bef_hand_info;

typedef struct bef_hand_tv_st {
    int id;
    int person_id;
    int hand_side;
    bef_rect rect;                      ///< hand bbox
    unsigned int action;              ///< hand action
    float rot_angle;                  ///< Hand rotation angle
    float score;                      ///< hand detect confidence
    float action_score;               ///< gesture action confidence
    float rot_angle_bothhand;  ///< Angle between hands
    // Key points of the hand, if not detected, set to 0
    struct bef_tt_key_point key_points[BEF_HAND_TV_KEY_POINT_NUM];
    // Hand extension point, if not detected, set to 0
    struct bef_tt_key_point key_points_extension[BEF_HAND_TV_KEY_POINT_NUM_EXTENSION];
} bef_hand_tv, *ptr_bef_hand_tv;

typedef struct bef_hand_tv_info_st {
    bef_hand_tv p_hands[BEF_MAX_HAND_TV_NUM];
    int hand_count;
} bef_hand_tv_info, *ptr_bef_hand_tv_info;

typedef void *bef_hand_sdk_handle;

#define EFFECT_HAND_DETECT_DELAY_FRAME_COUNT 4

#endif //EFFECT_SDK_BEF_EFFECTED_HAND_DETECT_DEFINE_H
