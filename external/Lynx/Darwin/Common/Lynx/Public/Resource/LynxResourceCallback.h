// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_RESOURCE_LYNXRESOURCECALLBACK_H_
#define DARWIN_COMMON_LYNX_RESOURCE_LYNXRESOURCECALLBACK_H_

#import <Foundation/Foundation.h>
#import "LynxResourceResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxResourceCallback : NSObject

- (void)onResponse:(LynxResourceResponse *)response;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_RESOURCE_LYNXRESOURCECALLBACK_H_
