//
// Created by Ni Guangyao on 2020/1/4.
//

#ifndef EFFECT_SDK_BEF_EFFECT_DYNAMIC_LIBRARY_H
#define EFFECT_SDK_BEF_EFFECT_DYNAMIC_LIBRARY_H

#include "bef_effect_public_define.h"

typedef void (*bef_generic_proc)();
#if defined(_WIN32)
/* Win32 but not WinCE */
typedef bef_generic_proc (__stdcall *bef_get_proc_func)(const char*);
#else
typedef bef_generic_proc (*bef_get_proc_func)(const char*);
#endif

/**
 * @brief Load EGL function address through function pointer
 * @param proc_func 
 * @return If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_load_egl_library_with_func(bef_get_proc_func proc_func);

/**
 * @brief Load GLESv2 function address through function pointer
 * @param proc_func 
 * @return If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_load_glesv2_library_with_func(bef_get_proc_func proc_func);

/**
 * @brief Load EGL dynamic library through path
 * @param fileName 
 * @param searchType 
 * @return If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_load_egl_library_with_path(const char* filename, int type);

/**
 * @brief Load GLESv2 dynamic library through path
 * @param fileName 
 * @param searchType 
 * @return If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_load_glesv2_library_with_path(const char* filename, int type);

#endif //EFFECT_SDK_BEF_EFFECT_DYNAMIC_LIBRARY_H
