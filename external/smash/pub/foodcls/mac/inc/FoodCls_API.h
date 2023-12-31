//
// Created by wangshiyin on 2018/12/07.
//

#ifndef FOODCLS_API_HPP
#define FOODCLS_API_HPP

#include <map>
#include "tt_common.h"
#include "iostream"

#if defined __cplusplus
extern "C" {
#endif
#define FOOD_CLASSES 2

static std::string FoodStr[FOOD_CLASSES] = {
    "Sweet",
    "Salt"
};


static float FoodProbThresh[FOOD_CLASSES] = {
    0.65,
    0.65,
};

typedef struct FoodClsResult {
    int selected_index; // index of FoodStr and FoodProbThresh
    float prob;
    std::string name;
}FoodClsResult;

typedef void *FoodClsHandle;

AILAB_EXPORT
int FC_CreateHandler(const char* model_path, FoodClsHandle *out, int fps=5);

AILAB_EXPORT
int FC_CreateHandlerFromBuf(const char* model_buf, int model_buf_len, FoodClsHandle *out, int fps=5);


AILAB_EXPORT
int FC_DoPredict(FoodClsHandle handle,
                 const unsigned char *image,
                 PixelFormatType pixel_format,
                 int image_width,
                 int image_height,
                 int image_stride,
                 ScreenOrient orientation,
                 FoodClsResult *ptr_output);

AILAB_EXPORT
int FC_ReleaseHandle(FoodClsHandle handle);

#if defined __cplusplus
};
#endif
#endif
