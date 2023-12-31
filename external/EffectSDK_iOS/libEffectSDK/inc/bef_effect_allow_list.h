#ifndef bef_effect_allow_list_h
#define bef_effect_allow_list_h

#include "bef_effect_public_define.h"

typedef enum
{
    BEF_ALLOW_LIST_ADD = 0,
    BEF_ALLOW_LIST_REMOVE = 1,
    BEF_ALLOW_LIST_RESET = 2,
    BEF_ALLOW_LIST_CLEAR = 3
} BEF_ALLOW_LIST_OPERATION;

BEF_SDK_API bef_effect_result_t bef_effect_allow_list_set_allowed_paths_global(const char* paths[], int pathCount);

BEF_SDK_API bef_effect_result_t bef_effect_allow_list_operate_allowed_paths_global(const char* strPaths[], int pathCount, BEF_ALLOW_LIST_OPERATION operation);

#endif
