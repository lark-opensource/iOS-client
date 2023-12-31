//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICEMONITORPROTOCOL_H_
#define DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICEMONITORPROTOCOL_H_

#import <Foundation/Foundation.h>
#import "LynxView.h"

@protocol LynxServiceProtocol;
NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
  LynxContextTagLastLynxURL,
  LynxContextTagLastLynxAsyncComponentURL,
} LynxContextTagType;

@protocol LynxServiceMonitorProtocol <LynxServiceProtocol>

- (void)reportTrailEvent:(NSString *)event data:(NSDictionary *)data;
- (void)reportImageStatus:(NSString *)event data:(NSDictionary *)data;

- (void)reportTrail;
- (void)reportErrorGlobalContextTag:(LynxContextTagType)type data:(NSString *)data;
- (void)reportResourceStatus:(LynxView *__nonnull)LynxView
                        data:(NSDictionary *__nonnull)data
                       extra:(NSDictionary *__nullable)extra;
+ (void)reportResourceErrorStatus:(LynxView *__nonnull)LynxView data:(NSDictionary *__nonnull)data;
NS_ASSUME_NONNULL_END
@end

#endif  // DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICEMONITORPROTOCOL_H_
