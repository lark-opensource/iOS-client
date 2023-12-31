//  Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICESETTINGSPROTOCOL_H_
#define DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICESETTINGSPROTOCOL_H_

#import <Foundation/Foundation.h>
#import "LynxServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxServiceSettingsConfig : NSObject

@property(nonatomic, copy) NSString *appID;
@property(nonatomic, copy) NSString *deviceID;
@property(nonatomic, copy) NSString *appVersion;
@property(nonatomic, copy) NSString *settingsDomain;

@end

@protocol LynxServiceSettingsProtocol <LynxServiceProtocol>

- (void)setupSettings:(LynxServiceSettingsConfig *)config;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICESETTINGSPROTOCOL_H_
