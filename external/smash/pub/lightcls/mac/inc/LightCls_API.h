//
// Created by wangshiyin on 2018/11/27.
//

#ifndef LIGHTCLS_API_HPP
#define LIGHTCLS_API_HPP
#include <map>
#include "tt_common.h"
#include "iostream"

#if defined __cplusplus
extern "C" {
#endif

#define LIGHT_CLASSES 7

typedef enum {
    Indoor_Yellow = 0,
    Indoor_White,
    Indoor_weak,
    Sunny,
    Cloudy,
    Night,
    Backlight
} LightType;

static std::string LightStr[LIGHT_CLASSES] = {
    "Indoor_Yellow",
    "Indoor_White",
    "Indoor_weak",
    "Sunny",
    "Cloudy",
    "Night",
    "Backlight"
};


static float LightProbThresh[LIGHT_CLASSES] = {
    0.6,
    0.6,
    0.6,
    0.66,
    0.62,
    0.7,
    0.85
};

typedef struct LightClsResult {
    int selected_index; 
    float prob;
    std::string name;
}LightClsResult;

typedef void *LightClsHandle;

AILAB_EXPORT
int LC_CreateHandler(const char* model_path, LightClsHandle *out, int fps=5);

AILAB_EXPORT
int LC_CreateHandlerFromBuf(const char* model_buf, int len, LightClsHandle *out, int fps=5);


AILAB_EXPORT
int LC_DoPredict(LightClsHandle handle,
                 const unsigned char *image,
                 PixelFormatType pixel_format,
                 int image_width,
                 int image_height,
                 int image_stride,
                 ScreenOrient orientation,
                 LightClsResult *ptr_output);

AILAB_EXPORT
int LC_ReleaseHandle(LightClsHandle handle);

#if defined __cplusplus
};
#endif
#endif
