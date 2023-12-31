// Copyright 2022 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LynxBaseDeviceInfo <NSObject>

@required
+ (NSString *)getDeviceModel;
+ (NSString *)getSystemVersion;
+ (NSString *)getLynxVersion;
+ (NSString *)getNetworkType;

@end

NS_ASSUME_NONNULL_END
