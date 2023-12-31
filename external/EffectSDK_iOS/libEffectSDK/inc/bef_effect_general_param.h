//
//  bef_effect_general_param.h
//  effect_sdk
//
//  Created by lvqingyang on 2020/6/18.
//

#ifndef bef_effect_general_param_h
#define bef_effect_general_param_h

#include "bef_effect_public_define.h"

typedef void (*bef_effect_get_general_param_callback)(const char* url, char* params, const int maxParamSize);
typedef void (*bef_effect_get_header_info_callback)(const char* url, char* params, const int maxHeaderSize);
typedef int (*bef_effect_check_url_callback)(const char* url);

/**
 * @brief add or update general params
 * @param keys array of keys for mapping params
 * @param values array of values, the order corresponds to the keys
 * @param size params count
 */
BEF_SDK_API void bef_effect_set_params(const char** keys, const char** values, const int size);

/**
 * @brief add or update general param with key
 * @param key key for mapping this param
 * @param value param value
 */
BEF_SDK_API void bef_effect_set_param_with_key(const char* key, const char* value);

/**
 * @brief get general param by key
 * @param key key for mapping this param
 * @param value a char array used for saving param
 * @param size size of char array
 * @return If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_param_by_key(const char* key, char* value, const int size);

/**
 * @brief set the callback to get general param
 * @param getParamsFunc pointer of callback function
 * @return void
 */
BEF_SDK_API void bef_effect_set_param_callback(bef_effect_get_general_param_callback getParamsFunc);

/**
 * @brief set the callback to get general param (only for fix compile error, will be removed in future)
 * @param getParamsFunc pointer of callback function
 * @return void
 */
BEF_SDK_API void bef_effect_set_get_param_callback(bef_effect_get_general_param_callback getParamsFunc);
/**
 * @brief set the callback to get header info
 * @param getParamsFunc pointer of callback function
 * @return void
 */
BEF_SDK_API void bef_effect_set_header_callback(bef_effect_get_header_info_callback getHeadersFunc);
/**
 * @brief set the callback to check url validity
 * @param checkUrlFunc pointer of callback function
 * @return void
 */
BEF_SDK_API void bef_effect_set_check_url_callback(bef_effect_check_url_callback checkUrlFunc);
#endif /* bef_effect_general_param_h */