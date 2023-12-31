// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LynxSettingsManager : NSObject

/// Lazy Singleton
+ (instancetype _Nonnull)shareInstance;

/// This time depends on the definition of the server, and the specific meaning is not understood by
/// the client. This time will only be returned to the server for use when the next request is made.
- (NSInteger)settingsTime;

/// Load local data, it will only be executed once during runtime.
- (void)loadSettings;

/*!
 Update settings data.
 @settingsDic The settings data dictionary
 @time The time of this data
 */
- (void)updateSettings:(NSDictionary *)settingsDic withTime:(NSInteger)time;

@end

NS_ASSUME_NONNULL_END
