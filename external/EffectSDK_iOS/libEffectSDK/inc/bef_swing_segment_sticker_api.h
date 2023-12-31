/**
 * @file bef_swing_segment_sticker_api.h
 * @author yankai.ff (yankai.ff@bytedance.com)
 * @brief 
 * @version 0.1
 * @date 2021-11-17
 * 
 * @copyright Copyright (c) 2021
 * 
 */

#ifndef bef_swing_segment_sticker_api_h
#define bef_swing_segment_sticker_api_h
#pragma once

#include "bef_swing_define.h"
#include "bef_framework_public_base_define.h" // BEF_SDK_API
#include "bef_info_sticker_public_define.h"

// Information sticker coordinate system:
//
//                                (0，1)
//       Screen or DrawBoard    ^ X axis
//      (-1.0, 1.0) ------------|-------------    (1, 1)
//                 |            |            |
//                 |            |            |
//                 |            |            |
//                 |            |            |
//                 |            |            |
//         (0, -1) |            | origin(0,0)|
//                 |--------------------------> y (1, 0)
//                 |            |            |
//                 |            |            |
//                 |            |            |
//                 |            |            |
//                 |            |            |
//                 |            |            |
//         (-1,-1) |            |            |    (1,-1)
//                 -------------|-------------
//                               (0, 1)
//
// The coordinates of the information stickers (x, y) are consistent with the OpenGL normalized coordinates
// The corresponding pixel coordinates are determined according to the size of Screen or DrawBoard.
// The screen size is set according to the set_width_height interface.
// e.g.
// screen size is 720 * 1280
// (1.0, 0.5) -> (360.0, 320.0)
//----------------------------------------------------------------------------

/**
 * @brief set sticker alpha
 * @param segmentHandle instance of swing segment
 * @param alpha default value is 1
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_set_alpha(bef_swing_segment_t* segmentHandle,
                                    float alpha);

/**
 * @brief get sticker alpha
 * @param segmentHandle instance of swing segment
 * @param alpha  [out]
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_get_alpha(bef_swing_segment_t* segmentHandle,
                                    float* alpha);

/**
 * @brief set sticker scale
 * @param segmentHandle instance of swing segment
 * @param x scale x
 * @param x scale y
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_set_scale(bef_swing_segment_t* segmentHandle,
                                    float x, float y);

/**
 * @brief get sticker scale
 * @param segmentHandle instance of swing segment
 * @param x  [out]
 * @param y  [out]
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_get_scale(bef_swing_segment_t* segmentHandle,
                                    float* x, float* y);

/**
 * @brief set sticker position
 * @param segmentHandle instance of swing segment
 * @param x position  x value range [-1.0, 1.0], default 0.0
 * @param x position y value range [-1.0, 1.0], default 0.0
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_set_position(bef_swing_segment_t* segmentHandle,
                                       float x, float y);

/**
 * @brief get sticker position
 * @param segmentHandle instance of swing segment
 * @param x  [out]
 * @param y  [out]
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_get_position(bef_swing_segment_t* segmentHandle, float* x, float* y);

/**
 * @brief set sticker rotation
 * @param segmentHandle instance of swing segment
 * @param rotation
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_set_rotation(bef_swing_segment_t* segmentHandle,
                                       float angle);

/**
 * @brief get sticker rotation
 * @param segmentHandle instance of swing segment
 * @param rotation  [out]
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_get_rotation(bef_swing_segment_t* segmentHandle,
                                       float* angle);

/**
 * @brief set sticker anchor
 * @param segmentHandle instance of swing segment
 * @param x anchor x
 * @param x anchor y
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_set_anchor(bef_swing_segment_t* segmentHandle,
                                     float x, float y);

/**
 * @brief get sticker anchor
 * @param segmentHandle instance of swing segment
 * @param x  [out]
 * @param y  [out]
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_get_anchor(bef_swing_segment_t* segmentHandle,
                                     float* x, float* y);

/**
 * @brief set sticker flip
 * @param segmentHandle instance of swing segment
 * @param x flip x
 * @param x flip y
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_set_flip(bef_swing_segment_t* segmentHandle,
                                   bool flipX, bool flipY);

/**
 * @brief get sticker flip
 * @param segmentHandle instance of swing segment
 * @param flipX  [out]
 * @param flipY  [out]
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_get_flip(bef_swing_segment_t* segmentHandle,
                                   bool* flipX, bool* flipY);

/**
 * @brief set sticker anim
 * @param segmentHandle instance of stick segment
 * @param type [ANI_IN, ANI_OUT, ANI_LOOP]
 * @param path anim resource package path
 * @param duration anim duration, in microsecond
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_set_animation(bef_swing_segment_t* segmentHandle,
                                        int type,
                                        const char* path,
                                        bef_swing_time_t duration);

/**
 * @brief set sticker anim property
 * @param segmentHandle instance of stick segment
 * @param type [ANI_IN, ANI_OUT, ANI_LOOP]
 * @param key anim property key
 * @param value anim property value
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_set_animation_property(bef_swing_segment_t* segmentHandle,
                                        int type,
                                        const char* key,
                                        const char* value);

/**
 * @brief set sticker anim absolute update
 * @param segmentHandle instance of stick segment
 * @param absoluteUpdate
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_set_anim_absolute_update(bef_swing_segment_t* segmentHandle,
                                                   bool absoluteUpdate);

/**
 * @brief set sticker anim preview mode, under preview mode, when sticker has anim, need to play anim
 * @param segmentHandle instance of stick segment
 * @param mode preview mode
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_set_preview_mode(bef_swing_segment_t* segmentHandle,
                                           unsigned short mode);

/**
 * @brief set sticker resolution type
 * @param segmentHandle instance of stick segment
 * @param type bef_infoSticker_resolution_type
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_set_resolution_type(bef_swing_segment_t* segmentHandle,
                                              bef_InfoSticker_resolution_type type);

/**
 * @brief set sticker entrance time
 * @param segmentHandle instance of stick segment
 * @param timeStamp
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_set_entrance_time(bef_swing_segment_t* segmentHandle,
                                            bef_swing_time_t timeStamp);

/**
 * @brief get sticker offset
 * @param segmentHandle instance of swing segment
 * @param x offset x  [out]
 * @param y offset y [out]
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_get_offset(bef_swing_segment_t* segmentHandle,
                                     float* x, float* y);

/**
 * @brief get sticker canvas width and height
 * @param segmentHandle instance of swing segment
 * @param width  [out]
 * @param height  [out]
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_get_canvas_width_height(bef_swing_segment_t* segmentHandle,
                                                  unsigned int* width, unsigned int* height);

/**
 * @brief get sticker local bbox with scale, The display area is an AABB bounding box, which is described by bef_BoundingBox_2d. The client uses this area to determine whether the user selected the sticker.(The bounding box contains only scaling transformation, not rotation and translation.)
 * @param segmentHandle instance of swing segment
 * @param outBox  [out]
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_get_local_bbox_with_scale(bef_swing_segment_t* segmentHandle,
                                                    bef_BoundingBox_2d* outBox);
/**
 * @brief set sticker enable release texute, when export the video need to set true
 * @param segmentHandle instance of swing segment
 * @param enable
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_set_enable_release_texture(bef_swing_segment_t* segmentHandle,
                                                     bool enable);

/**
 * @brief set sticker sys fontpaths for pc
 * @param path [sys font path]
 * @param count
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_set_sys_fontpaths(char** path, int count);

/**
 * @brief get template params before render by hencan
 * @param stickerPath
 * @param outParams [out json string]
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_get_pre_add_template_params(const char* stickerPath, char** outParams);

/**
 * @brief convert text to template by hencan
 * @param params [contain text info]
 * @param outParams [out json string]
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_get_convert_text_to_textTemplate(const char* params, char** outParams);

/**
 * @brief set sticker alpha
 * @param segmentHandle instance of swing segment
 * @param info Number of additional parameters
 * @note The following variable parameters are passed in the type const char *
 * Variable participants will be transferred to sticker resource package in order. The parameters are negotiated by the client RD and TA.
 * @note When png is passed in, the variable parameters can be represented by 4 dynamic parameters: left, right, bottom, top.
 * left, right, bottom, top represent the rectangular area of ​​the image displayed on the screen.(Coordinate normalization)
 */
BEF_SDK_API bef_effect_result_t
bef_swing_segment_sticker_set_params(bef_swing_segment_t* segmentHandle,
                                    bef_InfoSticker_info *info);

#endif /* bef_swing_segment_sticker_api_h */
