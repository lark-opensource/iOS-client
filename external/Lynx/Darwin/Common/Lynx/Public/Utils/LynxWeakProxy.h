// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_UTILS_LYNXWEAKPROXY_H_
#define DARWIN_COMMON_LYNX_UTILS_LYNXWEAKPROXY_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LynxWeakProxy : NSObject

@property(nonatomic, weak, readonly, nullable) id target;

+ (instancetype)proxyWithTarget:(id)target;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_UTILS_LYNXWEAKPROXY_H_
