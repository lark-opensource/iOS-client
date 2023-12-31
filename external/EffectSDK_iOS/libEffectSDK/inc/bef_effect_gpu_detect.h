#ifndef _BEF_EFFECT_GPU_DETECT_H_
#define _BEF_EFFECT_GPU_DETECT_H_

#include "bef_effect_public_define.h"

typedef enum {
    BEF_CPU,  // Android, iOS, Mac, Windows and Linux
    BEF_GPU,  // Android, iOS, Mac, Windows
    BEF_DSP,  // Android, iOS
    BEF_NPU,  // Android
    BEF_Auto, // Android, iOS, Mac, Windows and Linux

    BEF_METAL,  // iOS
    BEF_OPENCL, // Android, Mac, Windows
    BEF_OPENGL,
    BEF_VULKAN,
    BEF_CUDA,   // Windows, Linux
    BEF_CoreML, // iOS and Mac
} bef_forward_type;

typedef enum {
    BEF_GPU_NO_ERROR = 0,
    BEF_GPU_ERR_MEMORY_ALLOC = 1,
    BEF_GPU_NOT_IMPLEMENTED = 2,
    BEF_GPU_ERR_UNEXPECTED = 3,
    BEF_GPU_ERR_DATANOMATCH = 4,
    BEF_GPU_INPUT_DATA_ERROR = 5,
    BEF_GPU_CALL_BACK_STOP = 6,
    BEF_GPU_BACKEND_FALLBACK = 7,
    BEF_GPU_NULL_POINTER = 8,
    BEF_GPU_INVALID_POINTER = 9,
    BEF_GPU_INVALID_MODEL = 10,
    BEF_GPU_INFER_SIZE_ERROR = 11,
    BEF_GPU_NOT_SUPPORT = 12,
} bef_gpu_error_code;

typedef struct bef_gpu_info_st {
    char** info;
    int count;
} bef_gpu_info;


BEF_SDK_API bef_forward_type bef_effect_detect_gpu_mode();

BEF_SDK_API bef_gpu_error_code bef_effect_get_gpu_info(const char * deviceName, bef_gpu_info* gpuInfo);

BEF_SDK_API bef_effect_result_t bef_effect_release_gpu_info(bef_gpu_info* gpuInfo);

#endif // _BEF_EFFECT_GPU_DETECT_H_
