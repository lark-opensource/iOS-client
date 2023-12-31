//
//  bef_effect_image_decode_define.h
//         amazing_engine
//
//  Created by chaizhong on 2022/10/28.
//  Copyright © 2022 chaizhong. All rights reserved.

#ifndef bef_effect_image_decode_define_h
#define bef_effect_image_decode_define_h

#include "bef_effect_public_frame_info_define.h"
#include "bef_framework_public_geometry_define.h"


#define IMAGE_DECODE_SUCCESS 0  // return successfully
#define IMAGE_DECODE_ERROR -1   // return error
#define IMAGE_DECODE_CONFIG_INVALID -2   //some decode config are not supported

typedef void* image_decoder_handle;

typedef enum
{
    WEBP,
    COUNT
} imageType;

typedef struct bef_anim_info_st
{
    int canvas_width;  //actual width of each frame of the animation
    int canvas_height; //actual height of each frame of the animation
    int durations;     //durations of the animation
    int loop_count;    //loop count of the animation
    int bgcolor;       //background color of the animation
    int frame_counts;  //frame counts of the animation
} bef_anim_info;

typedef struct decode_config_st
{
    bef_pixel_format format; //decode to which format
} decode_config;

/**
 * create image decoder handle
 * @param handle [out] image decoder handle
 * @param filePath the path of image
 * @return -1: error, 0: success
 */
typedef int (*image_decoder_create_handle)(image_decoder_handle* handle, const char* filePath);

/**
 * set decode config
 * @param handle image decoder handle
 * @param config  config of decode
 * @return -2: invalid config, 0: success
 */
typedef int (*image_decoder_initialize_with_config)(image_decoder_handle handle, decode_config config);

/**
 * get anim info
 * @param handle image decoder handle
 * @param animInfo info of anim image
 * @return -1: error, 0: success
 */
typedef int (*image_decoder_get_anim_info)(image_decoder_handle handle, bef_anim_info* animInfo);

/**
 * get frame info by index
 * @param handle image decoder handle
 * @param frame_index the index of frame, 0 means the last frame
 * @param frameInfo info of the frame by index
 * @return -1: error, 0: success
 */
typedef int (*image_decoder_get_frame_info)(image_decoder_handle handle, int frame_index, bef_frame_info* frameInfo);

/**
 * get one frame data
 * @param handle image decoder handle
 * @param frame_index the index of frame, 0 means the last frame
 * @param output_data  decoded data according to format (output_data的内存effect管理, ve把解码后的data memcpy过来）
 * @return -1: error, 0: success
 */
typedef int (*image_decoder_get_frame_data)(image_decoder_handle handle, int frame_index, unsigned char* output_data);

/**
 * destroy image decoder handle
 * @param handle image decoder handle
 * @return -1: error, 0: success
 */
typedef int (*image_decoder_destory_handle)(image_decoder_handle handle);

typedef struct
{
    image_decoder_create_handle createHandle;
    image_decoder_initialize_with_config initWithConfig;
    image_decoder_get_anim_info getAnimInfo;
    image_decoder_get_frame_info getFrameInfo;
    image_decoder_get_frame_data getFrameData;
    image_decoder_destory_handle destroyHandle;
} image_decoder_methods;

#endif /* bef_effect_image_decode_define_h */
