#ifndef SRC_NAPI_ENV_H_
#define SRC_NAPI_ENV_H_

#include "js_native_api.h"

EXTERN_C_START

NAPI_EXTERN napi_env napi_new_env();

NAPI_EXTERN void napi_free_env(napi_env);

NAPI_EXTERN void napi_setup_loader(napi_env env, const char* name);

EXTERN_C_END

#endif
