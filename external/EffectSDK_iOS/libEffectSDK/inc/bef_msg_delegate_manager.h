//
//  bef_msg_delegate_manager.h
//  byted-effect-sdk
//
//  Created by zhugejingjing on 2020/7/28.
//

#ifndef bef_msg_delegate_manager_h
#define bef_msg_delegate_manager_h

#include "bef_effect_public_define.h"

#if (defined(__APPLE__) && !TARGET_OS_IPHONE) || defined(_WIN32) || defined(_WIN64) || defined(__linux__) || defined(__ANDROID__) || defined(TARGET_OS_WASM)

typedef void * bef_render_msg_delegate_manager;
typedef bool (*bef_render_msg_delegate_manager_callback)(void *, unsigned int, int, int, const char *);

BEF_SDK_API void bef_render_msg_delegate_manager_init(bef_render_msg_delegate_manager *manager);
BEF_SDK_API bool bef_render_msg_delegate_manager_add(bef_render_msg_delegate_manager manager, void *observer, bef_render_msg_delegate_manager_callback func);
BEF_SDK_API bool bef_render_msg_delegate_manager_remove(bef_render_msg_delegate_manager manager, void *observer, bef_render_msg_delegate_manager_callback func);
BEF_SDK_API void bef_render_msg_delegate_manager_destroy(bef_render_msg_delegate_manager *manager);

#endif

#endif /* bef_msg_delegate_manager_h */
