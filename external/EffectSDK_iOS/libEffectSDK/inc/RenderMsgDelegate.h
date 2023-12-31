//
//  GpuMsgDelegate
//
//  Created by youdong on 2017-06-13.
//  Copyright © 2017 bytedance. All rights reserved.
//
#import <TargetConditionals.h>
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR

#import <UIKit/UIKit.h>

#elif TARGET_OS_OSX

#import <AppKit/AppKit.h>

#endif

#import "bef_framework_public_base_define.h"

@protocol RenderMsgDelegate <NSObject>

// Message processing, returns TRUE after processing the message, otherwise returns FALSE

/// @brief message callback
/// @param unMsgID Message ID
/// @param nArg1 Additional parameters
/// @param nArg2 Additional parameters
/// @param cArg3 Additional parameters
/// @return Return YES on success, NO on failure
- (BOOL) msgProc : (unsigned int) unMsgID
             arg1: (int) nArg1
             arg2: (int) nArg2
             arg3: (const char*) cArg3;

@end

@interface IRenderMsgDelegateManager : NSObject

- (void)addDelegate : (id<RenderMsgDelegate>) pMsgDelegate;

- (void)removeDelegate : (id<RenderMsgDelegate>) pMsgDelegate;

- (BOOL) delegateProc : (unsigned int) unMsgID
                  arg1: (int) nArg1
                  arg2: (int) nArg2
                  arg3: (const char*) cArg3;

- (void)destoryDelegate;

@end

#if (defined(__APPLE__) && TARGET_OS_IPHONE)

typedef void * bef_render_msg_delegate_manager;
typedef bool (*bef_render_msg_delegate_manager_callback)(void *, unsigned int, int, int, const char *);

BEF_SDK_API void bef_render_msg_delegate_manager_init(bef_render_msg_delegate_manager *manager);
BEF_SDK_API bool bef_render_msg_delegate_manager_add(bef_render_msg_delegate_manager manager, void *observer, bef_render_msg_delegate_manager_callback func);
BEF_SDK_API bool bef_render_msg_delegate_manager_remove(bef_render_msg_delegate_manager manager, void *observer, bef_render_msg_delegate_manager_callback func);
BEF_SDK_API void bef_render_msg_delegate_manager_destroy(bef_render_msg_delegate_manager *manager);

#endif
