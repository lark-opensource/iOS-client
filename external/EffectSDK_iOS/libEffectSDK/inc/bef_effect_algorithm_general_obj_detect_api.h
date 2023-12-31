
//
//  bef_effect_algorithm_general_obj_detect_api.h
//
//  Created by hqh on 2020/01/10.
//

#ifndef bef_effect_algorithm_general_obj_detect_api_h
#define bef_effect_algorithm_general_obj_detect_api_h
#include "bef_effect_public_define.h"

typedef void* bef_smash_GeneralObjectDetectHandle;

/**
 * @brief Model parameter type
 * bef_smash_GeneralObjectDetectParamType_kDetectShortSideLen: 
The larger the short side length of the input image of the detection model, the better the detection effect of small targets, the initial value is 128
*/
typedef enum bef_smash_GeneralObjectDetectParamType {
    bef_smash_GeneralObjectDetectParamType_kDetectShortSideLen = 1,
}bef_smash_GeneralObjectDetectParamType;

/**
 * @brief Model enumeration
 * bef_smash_GeneralObjectDetectModelType_kPureDetect: Object detection only
*/
typedef enum bef_smash_GeneralObjectDetectModelType {
    bef_smash_GeneralObjectDetectModelType_kPureDetect = 1,
}bef_smash_GeneralObjectDetectModelType;

/**
 * @brief Encapsulate the input data of the prediction interface
 * @param base Basic encapsulation of video frame data
*/
typedef struct bef_smash_GeneralObjectDetectArgs {
    bef_ModuleBaseArgs base;
}bef_smash_GeneralObjectDetectArgs;

/**
 * @brief Object information
 * @param bbox:  The position of the object in the image
 * @param label: Object category(tianyuan@bytedance.com)
*/
typedef struct bef_smash_ObjectInfo {
    bef_rect bbox;
    int label;
}bef_smash_ObjectInfo;
  
/**
 * @brief Encapsulation prediction interface return value
 * obj_infos: Object information
 * obj_num:   Object number
*/
typedef struct bef_smash_GeneralObjectDetectRet {
    bef_smash_ObjectInfo *obj_infos;
    int obj_num;
}bef_smash_GeneralObjectDetectRet;

/**
 * @brief Create algorithm handle
 * @param out Output algorithm handle
 * @return 0 means successful call, negative means failed
 */
BEF_SDK_API
int bef_smash_GeneralObjectDetect_CreateHandle(bef_smash_GeneralObjectDetectHandle* out);

/**
 * @brief Initialize the model using finder
 * @param handle Algorithm handle
 * @param type Initialized model type
 * @param finder ResourceFinder pointer
 * @return 0 means successful call, negative means failed
*/
BEF_SDK_API
int bef_smash_GeneralObjectDetect_init(bef_smash_GeneralObjectDetectHandle handle,
                                       bef_smash_GeneralObjectDetectModelType type,
                                       bef_resource_finder finder);

/**
 * @brief Initialize the model using the resource path
 * @param handle Algorithm handle
 * @param type Initialized model type
 * @param assetModelPath resource path
 * @return 0 means successful call, negative means failed
*/
BEF_SDK_API
int bef_smash_GeneralObjectDetect_init_with_path(bef_smash_GeneralObjectDetectHandle handle,
                                                 bef_smash_GeneralObjectDetectModelType type,
                                                 const char assetModelPath[]);

/**
 * @brief Set parameters of type float
 * @param handle Algorithm handle
 * @param type Parameter Type
 * @return 0 means successful call, negative means failed
*/
BEF_SDK_API
int bef_smash_GeneralObjectDetect_SetParamF(bef_smash_GeneralObjectDetectHandle handle,
                                            bef_smash_GeneralObjectDetectParamType type,
                                            float value);

/**
 * @brief Set parameters of type string
 * @param handle Algorithm handle
 * @param type Parameter Type
 * @return 0 means successful call, negative means failed
*/
BEF_SDK_API
int bef_smash_GeneralObjectDetect_SetParamS(bef_smash_GeneralObjectDetectHandle handle,
                                            bef_smash_GeneralObjectDetectParamType type,
                                            char* value);

/**
 * @brief Perform recognition
 * @param handle Algorithm handle
 * @param args Input image and image parameters
 * @param ret Recognition result
 * @param retJsonString Output json string
 * @return 0 means successful call, negative means failed
*/
BEF_SDK_API
int bef_smash_GeneralObjectDetect_DO(bef_smash_GeneralObjectDetectHandle handle,
                                     bef_smash_GeneralObjectDetectArgs* args,
                                     bef_smash_GeneralObjectDetectRet* ret,
                                     char **retData);

/**
 * @brief Release handle
 * @param handle Algorithm handle
 * @return 0 means successful call, negative means failed
*/
BEF_SDK_API
int bef_smash_GeneralObjectDetect_ReleaseHandle(bef_smash_GeneralObjectDetectHandle handle);

#endif /* bef_effect_algorithm_general_obj_detect_api_h */
