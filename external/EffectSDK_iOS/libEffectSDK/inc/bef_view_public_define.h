//
//  bef_view_public_define.h
//  effect-sdk
//
//  Created by bytedance on 2020/8/23.
//

#ifndef bef_view_public_define_h
#define bef_view_public_define_h

//handle
typedef void* bef_view_handle_t;


// return code
typedef int bef_view_result_t;

#define BEF_VIEW_RESULT_SUC 0
#define BEF_VIEW_RESULT_INVALID_HANDLE 1
#define BEF_VIEW_RESULT_INTERNAL_FAIL  2
#define BEF_VIEW_RESULT_INVALID_PARAMS 3

#ifdef __cplusplus
#    ifdef _EFFECT_SDK_EXPORTS_
#        ifdef WIN32
#            define BEF_VIEW_API extern "C" __declspec(dllexport)
#        else
#            define BEF_VIEW_API extern "C" __attribute__((visibility("default")))
#        endif
#    else
#        define BEF_VIEW_API extern "C"
#    endif
#else
#    ifdef _EFFECT_SDK_EXPORTS_
#        ifdef WIN32
#            define BEF_VIEW_API __declspec(dllexport)
#        else
#            define BEF_VIEW_API __attribute__((visibility("default")))
#        endif
#    else
#        define BEF_VIEW_API
#    endif
#endif

// game message receive function definition
typedef int(*bef_view_msg_receive_func)(
    void* userdata,
    unsigned int msgid,
    long arg1,
    long arg2,
    const char *arg3);

typedef enum
{
    SHOOT = 0,
    LIVE,
    LIVE_OGC,
    GAME,
    M10N
} BEFViewSceneKey;

#endif /* bef_view_public_define_h */
