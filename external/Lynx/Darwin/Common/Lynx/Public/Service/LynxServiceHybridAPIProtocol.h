//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICEHYBRIDAPIPROTOCOL_H_
#define DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICEHYBRIDAPIPROTOCOL_H_

#import <Foundation/Foundation.h>

@protocol LynxServiceProtocol;

@protocol LynxServiceHybridAPIProtocol <LynxServiceProtocol>

+ (void)setupHybridKit;

@end

#endif  // DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICEHYBRIDAPIPROTOCOL_H_
