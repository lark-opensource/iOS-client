//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICETRAILPROTOCOL_H_
#define DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICETRAILPROTOCOL_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define LynxTrailFreeCanvasMemoryForce @"free_canvas_memory_force"
#define LynxTrailFreeImageMemory @"free_image_memory"
#define LynxTrailFreeImageMemoryForce @"free_image_memory_force"
#define LynxTrailKiteProbeEventEnable @"enable_kite_probe_event"

@protocol LynxServiceProtocol;

@protocol LynxServiceTrailProtocol <LynxServiceProtocol>

- (void)prepareLynxTrails;
- (NSString *)stringValueFromABSettings:(NSString *)key;
- (BOOL)boolValueFromABSettings:(NSString *)key;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICETRAILPROTOCOL_H_
