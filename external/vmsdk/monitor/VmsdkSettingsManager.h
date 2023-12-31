// Copyright 2022 The vmsdk Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VmsdkSettingsManager : NSObject
@property(nonatomic, nullable, readonly) NSDictionary *settingDict;
@property(nonatomic, readonly) NSInteger settingTime;
+ (instancetype _Nonnull)shareInstance;
- (void)initSettings;
- (void)setSettings:(NSDictionary *)settingDic withTime:(NSInteger)time;
- (bool)getSettingsFromCache:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
