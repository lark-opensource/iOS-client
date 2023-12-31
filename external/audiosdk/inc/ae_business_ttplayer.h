#ifndef audiosdk_ae_business_ttplayer_h
#define audiosdk_ae_business_ttplayer_h

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct mammon_ttplayer_wrapper_t {
    void (*open)(void* context, int samplerate, int channels, int duration);        //创建资源
    void (*process)(void* context, float** inout, int samples, int64_t timestamp);  //处理函数
    void (*close)(void* context);    //释放资源，须与open成对调用
    void (*release)(void* context);  //在release里销毁mammon_ttplayer_wrapper_t，必须且仅需调用一次
    void* context;  // 业务方不需要管理这个参数, 但是必须将它透传给mammon_ttplayer_wrapper_t的4个回调函数
} mammon_ttplayer_wrapper_t;

typedef mammon_ttplayer_wrapper_t* mammon_ttplayer_wrapper_ref;

/// init ttplayeer business API
/// @param out_inst the initialized ttplayer wrapper instance on output
/// @param effect_name effect name, you can use "compressor" only at present
int32_t mammon_business_ttplayer_init(mammon_ttplayer_wrapper_ref* out_inst, const char* effect_name);

/// set parameter if necessary, for example when the client receives settings from server side
int32_t mammon_business_ttplayer_set_param(mammon_ttplayer_wrapper_ref inst, const char* param_name,
                                           const float param_value);

/* ---------------------------------------------------------------------------------------*/
/* ------------------------------ ttplayer business API v2 ------------------------------ */
/* ---------------------------------------------------------------------------------------*/

#if 0  // in order to reduce size, don't compile ttplayer business API v2 before ttplayer actually want to use it

/// forward declaration of ttplayer context type
typedef struct mammon_ttmp_context_t *mammon_ttmp_context_ref;

/// query newest API version
int32_t mammon_ttmp_api_version(void);

int32_t mammon_ttmp_init(mammon_ttmp_context_ref *out_context, const char *business_name);
int32_t mammon_ttmp_release(mammon_ttmp_context_ref *context);

int32_t mammon_ttmp_open(mammon_ttmp_context_ref context, int32_t sample_rate, int32_t channels, int32_t duration);
int32_t mammon_ttmp_close(mammon_ttmp_context_ref context);

/// process audio data
/// @param ctx ttplayer context instance
/// @param inBuf input audio data
/// @param inSize An inout pointer parameter
///     On input, points to the samples per channel of inBuf. On return, points to the actually used input samples.
/// @param outBuf output buffer to store processed audio samples
/// @param outSize An inout pointer parameter
///     On input, points to the maximum samples per channel outBuf can store. On return, points to the actual output samples.
int32_t mammon_ttmp_process_planar(mammon_ttmp_context_ref ctx, float **inBuf, int32_t *inSize, float **outBuf, int32_t *outSize);
int32_t mammon_ttmp_process_interleaved(mammon_ttmp_context_ref ctx, float *inBuf, int32_t *inSize, float *outBuf, int32_t *outSize);

int32_t mammon_ttmp_get_param(mammon_ttmp_context_ref context, const char *param_name, float *out_param_value);
int32_t mammon_ttmp_set_param(mammon_ttmp_context_ref context, const char *param_name, const float new_param_value);

#endif  // disable ttplayer business API v2

#ifdef __cplusplus
}
#endif

#endif /* audiosdk_ae_business_ttplayer_h */
