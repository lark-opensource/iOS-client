//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICEAPPLOGPROTOCOL_H_
#define DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICEAPPLOGPROTOCOL_H_

#import <Foundation/Foundation.h>
#import "LynxServiceProtocol.h"
#import "LynxView.h"

NS_ASSUME_NONNULL_BEGIN
@protocol LynxServiceAppLogProtocol <LynxServiceProtocol>

/// Upload onTimingSetup event by Applog
/// @param timingInfo All timing info of setup phase.
/// @param extraData  Extra data of lynx view, eg: url, page, lynx_sdk_version, thread_mode.
/// extraData can be a nullptr. If extraData isn't a nullptr, it will be merged in data and reported
/// with data together.
- (void)onTimingSetup:(NSDictionary *)timingInfo withExtraData:(NSDictionary *_Nullable)extraData;

/// Upload onTimingUpdate event by Applog
/// @param allTimingInfo All timing info of setup and update.
/// @param updateTiming All timing info  about this update.
/// @param extraData Extra data of lynx view, eg: url, page, lynx_sdk_version, thread_mode.
/// extraData can be a nullptr. If extraData isn't a nullptr, it will be merged in data and reported
/// with data together.
- (void)onTimingUpdate:(NSDictionary *)allTimingInfo
          updateTiming:(NSDictionary *)updateTiming
             extraData:(NSDictionary *_Nullable)extraData;

/// report custom event,
/// @param eventName eventName
/// @param props Properties
/// @param extraData  Extra data of lynx view, eg: url, page, lynx_sdk_version, thread_mode.
/// extraData can be a nullptr. If extraData isn't a nullptr, it will be merged in data and reported
/// with data together.
- (void)onReportEvent:(NSString *)eventName
                props:(NSDictionary *_Nullable)props
            extraData:(NSDictionary *_Nullable)extraData;

- (NSString *)getDeviceID;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICEAPPLOGPROTOCOL_H_
