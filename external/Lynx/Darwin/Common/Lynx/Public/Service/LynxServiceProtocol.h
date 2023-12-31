//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICEPROTOCOL_H_
#define DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICEPROTOCOL_H_

#import <Foundation/Foundation.h>
#import "LynxServiceProtocol.h"

#define DEFAULT_LYNX_SERVICE @"lynx_default_service"

typedef NS_OPTIONS(NSUInteger, LynxServiceType) {
  LynxServiceTypeMonitor = 1 << 0,
#if __ENABLE_LYNX_NET__
  LynxServiceTypeNetwork = 1 << 1,
#endif
  LynxServiceHybridAPI = 1 << 2,
  LynxServiceTrail = 1 << 3,
  LynxServiceDev = 1 << 4,
#ifdef OS_IOS
  LynxServiceImage = 1 << 5,
#endif
  LynxServiceResource = 1 << 6,
  LynxServiceTrack = 1 << 7,
  LynxServiceAppLog = 1 << 8,
  LynxServiceSettings = 1 << 9,
};

typedef NS_OPTIONS(NSUInteger, LynxServiceScope) {
  LynxServiceScopeDefault = 1 << 0,
  LynxServiceScopeBiz = 1 << 1
};

@protocol LynxServiceProtocol <NSObject>

/// Service Scope type
+ (LynxServiceScope)serviceScope;

/// The type of current service
+ (LynxServiceType)serviceType;

/// The biz tag of current service.
+ (NSString *)serviceBizID;

@end

#endif  // DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICEPROTOCOL_H_
