// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_LYNXCONTEXT_H_
#define DARWIN_COMMON_LYNX_LYNXCONTEXT_H_

#import <Foundation/Foundation.h>
#import "JSModule.h"
#import "LynxView.h"
@class LynxGetUIResultDarwin;

NS_ASSUME_NONNULL_BEGIN

@interface LynxContext : NSObject

- (void)sendGlobalEvent:(nonnull NSString *)name withParams:(nullable NSArray *)params;
- (nullable JSModule *)getJSModule:(nonnull NSString *)name;
- (nullable NSNumber *)getLynxRuntimeId;

- (void)reportModuleCustomError:(NSString *)message;
- (nullable LynxView *)getLynxView;

- (void)runOnTasmThread:(dispatch_block_t)task;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_LYNXCONTEXT_H_
