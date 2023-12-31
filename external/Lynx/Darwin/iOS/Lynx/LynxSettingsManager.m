// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxSettingsManager.h"
#import "LynxEnv.h"
#import "LynxLog.h"

static NSString *SETTINGS_KEY = @"com.lynx.settings.dict";
static NSString *SETTINGS_TIME_KEY = @"com.lynx.settings.time";

@implementation LynxSettingsManager

+ (instancetype)shareInstance {
  static dispatch_once_t onceToken;
  static LynxSettingsManager *instance = nil;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

- (void)loadSettings {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSDictionary *settingDict = @{};
    if ([[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys]
            containsObject:SETTINGS_KEY]) {
      settingDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:SETTINGS_KEY];
    }
    [[LynxEnv sharedInstance] updateSettings:settingDict];
  });
}

- (void)updateSettings:(NSDictionary *)settingsDic withTime:(NSInteger)time {
  LLogInfo(@"setSettings from external");
  [[NSUserDefaults standardUserDefaults] setInteger:time forKey:SETTINGS_TIME_KEY];
  [[NSUserDefaults standardUserDefaults] setObject:settingsDic ?: @{} forKey:SETTINGS_KEY];
  [[LynxEnv sharedInstance] updateSettings:settingsDic];
}

- (NSInteger)settingsTime {
  return [[NSUserDefaults standardUserDefaults] integerForKey:SETTINGS_TIME_KEY];
}

@end
