/**
 * @file bef_effect_public_frame_info_define.h
 * @author leo xu (xuliyou@bytedance.com)
 * @brief struct definition for extra frame info in every effect frame
 * @version 1.0
 * @date 2022-07-11
 * @copyright Copyright (c) 2022
 */

#ifndef EFFECT_SDK_BEF_EFFECT_PUBLIC_FRAME_INFO_DEFINE_H
#define EFFECT_SDK_BEF_EFFECT_PUBLIC_FRAME_INFO_DEFINE_H

// 
typedef struct bef_frame_info_t {
    int frame_width;    //decoded wide, not actual width of the frame
    int frame_height;   //decoded height, not actual height of the frame
    int frame_duration; //frame duration
    int frame_index;    //frame index
    bool enabled;
    bool skipRecording;
} bef_frame_info;

#endif