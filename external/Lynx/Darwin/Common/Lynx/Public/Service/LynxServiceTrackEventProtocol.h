//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICETRACKEVENTROTOCOL_H_
#define DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICETRACKEVENTROTOCOL_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LynxServiceProtocol;

@protocol LynxServiceTrackEventProtocol <LynxServiceProtocol>

// eg: KProbe_SpecialEventFormat(@"Zephyr", @"willparse", @"Zephyr will parse item :
// moduleVersion:%@", moduleVersion);
- (void)kProbe_SpecialEventName:(NSString *)eventName format:(NSString *)format data:(id)formatData;

- (void)kProbe_SpecialEventDirectWithName:(NSString *)eventName
                                   format:(NSString *)format
                                     data:(id)formatData;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICETRACKEVENTROTOCOL_H_
