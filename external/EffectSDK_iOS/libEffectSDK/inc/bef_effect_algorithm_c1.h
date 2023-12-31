//
//  bef_effect_algorithm_c1.h
//  Pods
//
//  Created by lvshaohui1234 on 2019/10/11.
//

#ifndef bef_effect_algorithm_c1_h
#define bef_effect_algorithm_c1_h

#include "bef_effect_public_define.h"
#include <stdbool.h>
#define BEF_NUM_CLASSES 22

/**
 * @brief Model enumeration
 **/
typedef enum {
    BEF_C1_MODEL_SMALL = 0x00000001,
    BEF_C1_MODEL_LARGE = 0x00000002
} BEF_C1ModelType;

typedef enum {
    BEF_Baby = 0,
    BEF_Beach,
    BEF_Building,
    BEF_Car,
    BEF_Cartoon,
    BEF_Cat,
    BEF_Dog,
    BEF_Flower,
    BEF_Food,
    BEF_Group,
    BEF_Hill,
    BEF_Indoor,
    BEF_Lake,
    BEF_Nightscape,
    BEF_Selfie,
    BEF_Sky,
    BEF_Statue,
    BEF_Street,
    BEF_Sunset,
    BEF_Text,
    BEF_Tree,
    BEF_Other
} BEF_C1Type;

static float BEF_C1SmallModelProbThreshold[BEF_NUM_CLASSES] = {
    0.75, // Baby
    0.75,  // Beach
    0.75,  // Building
    0.7, // Car
    0.7, // Cartoon
    0.7, // Cat
    0.7, // Dog
    0.6, // Flower
    0.75, // Food   0.9893
    0.6, // Group
    0.6, // Hill
    0.75, // Indoor
    0.55, // Lake
    0.55, // Nightscape
    0.55,  // Selfie
    0.6,  // Sky
    0.75,  // Statue
    0.6, // Street
    0.4,  // Sunset 0.7016
    0.75, // Text
    0.6, // Tree
    0.95 // Other
};

static float BEF_C1LargeModelProbThreshold[BEF_NUM_CLASSES] = {
    0.7,    // Baby
    0.7,    // Beach
    0.7,    // Building
    0.7,    // Car
    0.7,    // Cartoon
    0.9,    // Cat
    0.9,    // Dog
    0.7,    // Flower
    0.7,    // Food   0.9893
    0.7,    // Group
    0.7,    // Hill
    0.7,    // Indoor
    0.7,    // Lake
    0.7,    // Nightscape
    0.7,    // Selfie
    0.7,    // Sky
    0.7,    // Statue
    0.7,    // Street
    0.7,    // Sunset 0.7016
    0.7,    // Text
    0.7,    // Tree
    0.9920  // other
};

typedef struct BEF_C1CategoryItem {
    float prob;
    bool satisfied;
} BEF_C1CategoryItem;

typedef struct BEF_C1Output {
    BEF_C1CategoryItem items[BEF_NUM_CLASSES];
} BEF_C1Output;

typedef void *bef_C1Handle;

/**
 @brief create c1 handle
 @param model_path Model file path
 @param model_type Initialized model type
 @param handle c1 handle
 @param status
 */
BEF_SDK_API
int bef_c1_CreateHandler_path(const char *model_path,
                     BEF_C1ModelType model_type,
                     bef_C1Handle *handle);
BEF_SDK_API
int bef_c1_CreateHandler(bef_resource_finder finder,
                              BEF_C1ModelType model_type,
                              bef_C1Handle *handle);

/**
 @brief Create classification handle from memory buffer
 @param model_buf model buffer
 @param len the length of buffer
 @param: model_type Initialized model type
 @param handle c1 handle
 @param status
 */
BEF_SDK_API
int bef_c1_CreateHandlerFromBuf_path(const char *model_buf,
                            int len,
                            BEF_C1ModelType model_type,
                            bef_C1Handle *handle);

/**
 @brief The classification result is stored in ptr_output
 @param: handle Detection handle
 @param: image Picture memory address
 @param: pixel_format Image Format
 @param: image_width image width
 @param: image_height image height
 @param: image_stride Step size of each line of the picture
 @param: orientation Picture rotation direction
 @param: ptr_output Scene classification detection results, need to allocate memory
 @return status
 */
BEF_SDK_API
int bef_c1_DoPredict(bef_C1Handle handle,
                 const unsigned char *image,
                 bef_pixel_format pixel_format,
                 int image_width,
                 int image_height,
                 int image_stride,
                 bef_rotate_type orientation,
                 BEF_C1Output *ptr_output);

BEF_SDK_API
typedef enum {
    BEF_C1_USE_VIDEO_MODE = 1,  // The default value is 1, which means video mode, 0: image mode
    BEF_C1_USE_MultiLabels = 2,  // The default is 0, which means no multi-label mode, 1: multi-label mode
} BEF_C1ParamType;

/**
 @brief: Hyperparameter setting
 @param: handle Detection handle
 @param: type Parameter Type
 @param: value Parameter value
 */
BEF_SDK_API
int bef_C1_SetParam(bef_C1Handle handle, BEF_C1ParamType type, float value);

/**
 @brief: release c1 handle
 @param: handle Detection handle
 */
BEF_SDK_API
int bef_C1_ReleaseHandle(bef_C1Handle handle);


#endif /* bef_effect_algorithm_c1_h */
