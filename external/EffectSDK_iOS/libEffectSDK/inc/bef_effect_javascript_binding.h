//
//  bef_effect_javascript_binding.h
//  effect-sdk
//
//  Created by brillian.ni on 10/14/2020.
//

#ifndef bef_effect_javascript_binding_h
#define bef_effect_javascript_binding_h

#include "bef_effect_public_define.h"

typedef void (*bef_gl_save_func)(void*);
typedef void (*bef_gl_restore_func)(void*);
typedef bool (*bef_url_translate_func)(const char*, char*, int*, void*);
typedef void (*bef_download_model_callback)(void*, bool, int64_t, const char*);
typedef void (*bef_download_model_func)(void*, const char*[], int, const char*, bef_download_model_callback, void*);
typedef void (*bef_download_sticker_callback)(void*, bool, float, const char*, int64_t, const char*);
typedef void (*bef_download_sticker_func)(void*, const char*, bef_download_sticker_callback, void*);
typedef char* (*bef_resource_finder)(bef_effect_handle_t, const char*, const char*);
typedef void (*bef_resource_finder_releaser)(void*);
typedef void (*bef_update_listener)(void*, const unsigned int*, unsigned long, unsigned int);
typedef unsigned int (*bef_get_texture_func)(void*, void* napi_value);

BEF_SDK_API bef_effect_result_t bef_effect_javascript_set_scene_key(void* _env, const char* sceneKey);

BEF_SDK_API bef_effect_result_t bef_effect_javascript_binding_engine(void* _env, void* _obj, void* data);

BEF_SDK_API bef_effect_result_t bef_effect_javascript_set_gl_save_func(void* _env, bef_gl_save_func func);

BEF_SDK_API bef_effect_result_t bef_effect_javascript_set_gl_restore_func(void* _env, bef_gl_restore_func func);

BEF_SDK_API bef_effect_result_t bef_effect_javascript_set_url_translate_func(void* _env, bef_url_translate_func func);

BEF_SDK_API bef_effect_result_t bef_effect_javascript_set_download_model_fuc(void* _env, bef_download_model_func func);

BEF_SDK_API bef_effect_result_t bef_effect_javascript_set_download_sticker_fuc(void* _env, bef_download_sticker_func func);

BEF_SDK_API bef_effect_result_t bef_effect_javascript_set_resource_finder(void* _env, bef_resource_finder func, bef_resource_finder_releaser release_func);

BEF_SDK_API bef_effect_result_t bef_effect_javascript_set_before_update_func(void* _env, bef_update_listener func);

BEF_SDK_API bef_effect_result_t bef_effect_javascript_set_after_update_func(void* _env, bef_update_listener func);

BEF_SDK_API bef_effect_result_t bef_effect_javascript_set_get_texture_func(void* _env, bef_get_texture_func func);

#endif /* bef_effect_javascript_binding_h */
