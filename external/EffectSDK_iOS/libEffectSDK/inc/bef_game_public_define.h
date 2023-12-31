#pragma once

//handle
typedef void* bef_game_handle_t;


// return code
typedef int bef_game_result_t;
#define BEF_GAME_RESULT_SUC 0
#define BEF_GAME_RESULT_INVALID_HANDLE 1
#define BEF_GAME_RESULT_INTERNAL_FAIL  2
#define BEF_GAME_RESULT_INVALID_PARAMS 3

#ifdef __cplusplus
#    ifdef _EFFECT_SDK_EXPORTS_
#        ifdef WIN32
#            define BEF_GAME_API extern "C" __declspec(dllexport)
#        else
#            define BEF_GAME_API extern "C" __attribute__((visibility("default")))
#        endif
#    else
#        define BEF_GAME_API extern "C"
#    endif
#else
#    ifdef _EFFECT_SDK_EXPORTS_
#        ifdef WIN32
#            define BEF_GAME_API __declspec(dllexport)
#        else
#            define BEF_GAME_API __attribute__((visibility("default")))
#        endif
#    else
#        define BEF_GAME_API
#    endif
#endif


// game message receive function definition
typedef int(*bef_game_msg_receive_func)(
    void* userdata,
    unsigned int msgid,
    long arg1,
    long arg2,
    const char *arg3);
