//
// Created by bytedance on 2018/5/3.
//

#ifndef EFFECT_SDK_BEF_EFFECT_GEOMETRY_DEFINE_H
#define EFFECT_SDK_BEF_EFFECT_GEOMETRY_DEFINE_H
#include <stdbool.h>

// @brief image rotate type definition
typedef enum {
    BEF_CLOCKWISE_ROTATE_0 = 0, // no rotation to make face straight
    BEF_CLOCKWISE_ROTATE_90 = 1, // rotate 90 degrees clockwise to make face straight
    BEF_CLOCKWISE_ROTATE_180 = 2, // rotate 180 degrees to make face straight
    BEF_CLOCKWISE_ROTATE_270 = 3  // rotate 270 degrees clockwise to make face straight
} bef_rotate_type;

// ORDER!!!
typedef enum {
    BEF_PIX_FMT_RGBA8888, // RGBA 8:8:8:8 32bpp ( 4 channel 32 bit RGBA )
    BEF_PIX_FMT_BGRA8888, // BGRA 8:8:8:8 32bpp ( 4 channel 32 bit RGBA )
    BEF_PIX_FMT_BGR888,   // BGR 8:8:8 24bpp ( 3 channel 24 bit RGBA )
    BEF_PIX_FMT_RGB888,   // RGB 8:8:8 24bpp ( 3 channel 24 bit RGBA )
    BEF_PIX_FMT_GRAY8,    // GRAY 8bpp ( 1 channel 8bit gray ) not supported
    BEF_PIX_FMT_YUV420P,  // YUV  4:2:0   12bpp ( 3 channels, one brightness, the others are U and V, all channels are continuous ), not supported yet
    BEF_PIX_FMT_NV12,     // YUV  4:2:0   12bpp ( 3 channels, one brightness, the others are U and V, all channels are continuous ), not supported yet
    BEF_PIX_FMT_NV21,      // YUV  4:2:0   12bpp ( 3 channels, one brightness, the others are U and V, all channels are continuous ), not supported yet
    BEF_PIX_FMT_YUY2,
    BEF_CVPIX_FMT_NV12     //cvpixelBuffer nv12
} bef_pixel_format;


typedef struct bef_fpoint_t {
    float x;
    float y;
} bef_fpoint;

typedef struct bef_fpoint3d_t {
    float x;
    float y;
    float z;
} bef_fpoint3d;

typedef struct bef_fpoint_detect_t {
    float x;
    float y;
    bool is_detect;
    float score;
} bef_fpoint_detect;

typedef struct bef_rect_t {
    int left;   // Left most coordinate in rectangle
    int top;    // Top coordinate in rectangle
    int right;  // Right most coordinate in rectangle
    int bottom; // Bottom coordinate in rectangle
} bef_rect;

// Same definition as bef_rect, but in float type
typedef struct bef_rectf_t {
    float left;
    float top;
    float right;
    float bottom;
} bef_rectf;


typedef enum bef_camera_position_t {
    bef_camera_position_front,
    bef_camera_position_back,
    bef_camera_position_none
} bef_camera_position;



typedef struct bef_frect_st {
    float left;   ///< left coordinate
    float top;    ///< top coordinate
    float right;  ///< right coordinate
    float bottom; ///< bottom coordinate
} bef_frect;

typedef struct bef_image_t {
    const unsigned char *data;
    int width;
    int height;
    int stride;
    int format;
    bef_rotate_type orientation;
} bef_image;

typedef struct
{
    void *pixels;
    void *plane[3];
    int size;
    int width[3];
    int height[3];
    int stride[3];
    int offset[3];
    bef_pixel_format format;
    int flipMode;
    void* userdata;///maybe a Texture ID which convert from cpu buffer
}bef_pixel_buffer;

typedef enum
{
    BEF_EFFECT_PROCESS_MODE_GPU,
    BEF_EFFECT_PROCESS_MODE_CPU
}bef_effect_process_mode;

#endif //EFFECT_SDK_BEF_EFFECT_GEOMETRY_DEFINE_H
