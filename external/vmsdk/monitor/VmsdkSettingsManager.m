// Copyright 2022 The vmsdk Authors. All rights reserved.

#import "VmsdkSettingsManager.h"

static NSString* SETTINGS_CACHE_KEY = @"com.vmsdk.settings.dict";
static NSString* SETTINGS_CACHE_TIME_KEY = @"com.vmsdk.settings.time";
static NSString* VMSDK_SETTINGS_NAME = @"vmsdk_common";

@implementation VmsdkSettingsManager

static VmsdkSettingsManager* _instance = nil;

+ (instancetype)shareInstance {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _instance = [[self alloc] init];
  });
  return _instance;
}

- (void)initSettings {
  @synchronized(self) {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    if ([[[defaults dictionaryRepresentation] allKeys] containsObject:SETTINGS_CACHE_KEY]) {
      _settingDict = [defaults dictionaryForKey:SETTINGS_CACHE_KEY];
    } else {
      _settingDict = @{};
    }
    if ([[[defaults dictionaryRepresentation] allKeys] containsObject:SETTINGS_CACHE_TIME_KEY]) {
      _settingTime = [defaults integerForKey:SETTINGS_CACHE_TIME_KEY];
    } else {
      _settingTime = 0;
    }
  }
}

- (void)setSettings:(NSDictionary*)settingDic withTime:(NSInteger)time {
  NSLog(@"VmsdkSettingsManager setSettings settingDic: %@", settingDic);
  @try {
    @synchronized(self) {
      if (settingDic) {
        _settingDict = [settingDic copy];
      } else {
        _settingDict = @{};
      }
      _settingTime = time;
      NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
      [defaults setInteger:_settingTime forKey:SETTINGS_CACHE_TIME_KEY];
      [defaults setObject:_settingDict forKey:SETTINGS_CACHE_KEY];
    }
  } @catch (NSException* exception) {
    NSLog(@"VmsdkSettingsManager setSettings error: %@", exception.description);
  }
}

- (bool)getSettingsFromCache:(NSString*)key {
  if (_settingDict == nil || key == nil) {
    return false;
  }
  @try {
    NSDictionary* vmsdkCommonDic = [_settingDict objectForKey:VMSDK_SETTINGS_NAME];
    if (vmsdkCommonDic != nil) {
      NSObject* settingsValue = [vmsdkCommonDic objectForKey:key];
      if ([settingsValue isEqual:@"True"] || [settingsValue isEqual:@"true"] ||
          [settingsValue isEqual:@"TRUE"]) {
        NSLog(@"VmsdkSettingsManager getSettingsFromCache true forkey: %@", key);
        return true;
      }
    }
  } @catch (NSException* exception) {
    NSLog(@"VmsdkSettingsManager getSettingsFromCache error: %@", exception.description);
  }
  NSLog(@"VmsdkSettingsManager getSettingsFromCache false forkey: %@", key);
  return false;
}

@end
