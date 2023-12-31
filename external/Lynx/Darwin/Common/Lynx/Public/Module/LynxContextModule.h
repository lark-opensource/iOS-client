// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_MODULE_LYNXCONTEXTMODULE_H_
#define DARWIN_COMMON_LYNX_MODULE_LYNXCONTEXTMODULE_H_

#import <Foundation/Foundation.h>
#import "LynxContext.h"
#import "LynxModule.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LynxContextModule <LynxModule>

@required
- (instancetype)initWithLynxContext:(LynxContext*)context;

@optional
- (instancetype)initWithLynxContext:(LynxContext*)context WithParam:(id)param;
- (void)destroy;
@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_MODULE_LYNXCONTEXTMODULE_H_
