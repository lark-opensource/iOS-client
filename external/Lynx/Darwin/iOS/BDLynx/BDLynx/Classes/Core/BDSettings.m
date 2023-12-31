//
//  BDSettings.m
//  Lynx
//
//  Created by admin on 2020/10/21.
//

#import "BDSettings.h"
#import <TTNetworkManager/TTNetworkManager.h>
#import <sys/utsname.h>
#import <vmsdk/monitor/VmsdkSettingsManager.h>
#import "BDLHostProtocol.h"
#import "BDLSDKManager.h"
#import "BDLSDKProtocol.h"
#import "LynxEnv.h"
#import "LynxLog.h"
#import "LynxService.h"
#import "LynxServiceSettingsProtocol.h"
#import "LynxSettingsManager.h"
#import "LynxVersion.h"

static long BDLYNX_SETTINGS_UPDATE_CHECK_INTERVAL = 24 * 60 * 60;

static NSString* const kNetworkTagIsFirstStartUp = @"lynx_network_tag_is_first_start_up";
static NSString* const kNetworkTagRequestKey = @"x-tt-request-tag";
static NSString* SETTINGS_LASTCHECK_KEY = @"com.lynx.settings.lastCheck";

@implementation BDSettings {
  NSInteger lastCheck;
}

static BDSettings* _instance = nil;

+ (instancetype)shareInstance {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _instance = [[self alloc] init];
  });
  return _instance;
}

- (instancetype)init {
  return self;
}

- (void)initSettings {
  [[LynxSettingsManager shareInstance] loadSettings];
}

- (NSString*)modelString {
  struct utsname systemInfo;
  uname(&systemInfo);
  NSString* deviceModel = [NSString stringWithCString:systemInfo.machine
                                             encoding:NSUTF8StringEncoding];
  return deviceModel;
}

- (void)syncSettings {
  if (![LynxEnv getBoolExperimentSettings:@"rollback_to_bd_settings_sync"]) {
    [self setupServices];
    return;
  }

  NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
  NSInteger time = interval;
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  lastCheck = [defaults integerForKey:SETTINGS_LASTCHECK_KEY];
  if (time - lastCheck < BDLYNX_SETTINGS_UPDATE_CHECK_INTERVAL) {
    LLogInfo(@"syncSettings: The time since last execution is too short");
    return;
  }
  NSString* settingsDomain = (NSString*)[BDLSDKManager getSystemInfoByKey:@"SETTINGS_DOMAIN"];
  if (settingsDomain == nil || [settingsDomain isEqualToString:@""]) {
    LLogInfo(@"syncSettings: SETTINGS_DOMAIN is empty");
    return;
  }
  lastCheck = interval;
  NSString* aid = [BDL_SERVICE(BDLHostProtocol) appID];
  NSString* did = [BDL_SERVICE(BDLHostProtocol) deviceID];
  NSString* lynxVersion = [LynxVersion versionString];
  NSString* pVersion = [[UIDevice currentDevice] systemVersion];
  NSString* pModel = [self modelString];
  NSString* appVersion = [BDL_SERVICE(BDLSDKProtocol) appVersion];
  NSString* channel = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CHANNEL_NAME"];
  NSInteger lastSettingTime = [[LynxSettingsManager shareInstance] settingsTime];

  NSString* urlString = [NSString
      stringWithFormat:@"https://%@/service/settings/v3/"
                       @"?caller_name=lynx&os_type=ios&aid=%@&sdk_version=%@&os_version=%@&model=%@"
                       @"&app_version=%@&device_id=%@&channel=%@&settings_time=%ld",
                       settingsDomain, aid, lynxVersion, pVersion, pModel, appVersion, did, channel,
                       lastSettingTime];
  __weak __typeof(self) weakSelf = self;
  [[TTNetworkManager shareInstance]
      requestForJSONWithResponse:urlString
                          params:nil
                          method:@"GET"
                needCommonParams:YES
                     headerField:@{
                       kNetworkTagRequestKey :
                           [NSString stringWithFormat:@"t=0;n=%d", [self isNewUser]]
                     }
               requestSerializer:nil
              responseSerializer:nil
                      autoResume:YES
                        callback:^(NSError* error, id jsonObj, TTHttpResponse* response) {
                          @try {
                            __strong __typeof(weakSelf) strongSelf = weakSelf;
                            if (strongSelf == nil) {
                              return;
                            }
                            if (error) {
                              LLogError(@"syncSettings error: network %@", error.description);
                              return;
                            }
                            if (![jsonObj isKindOfClass:[NSDictionary class]]) {
                              LLogError(@"syncSettings error: response is not a valid json obj");
                              return;
                            }
                            NSString* messageResult = jsonObj[@"message"];
                            if (messageResult == nil ||
                                ![messageResult isEqualToString:@"success"]) {
                              return;
                            }
                            NSDictionary* dataDict = jsonObj[@"data"];
                            if (dataDict == nil) {
                              return;
                            }

                            NSInteger settingTime = 0;
                            NSDictionary* settingDict = nil;
                            if ([dataDict objectForKey:@"settings_time"]) {
                              settingTime = [[dataDict objectForKey:@"settings_time"] intValue];
                            }
                            if ([dataDict objectForKey:@"settings"]) {
                              settingDict = [dataDict objectForKey:@"settings"];
                            }
                            [[VmsdkSettingsManager shareInstance] setSettings:settingDict
                                                                     withTime:time];
                            [[LynxSettingsManager shareInstance] updateSettings:settingDict
                                                                       withTime:settingTime];
                            [defaults setInteger:self->lastCheck forKey:SETTINGS_LASTCHECK_KEY];
                          } @catch (NSException* exception) {
                            LLogError(@"syncSettings error: %@", exception.description);
                          }
                        }];
}

- (BOOL)isNewUser {
  static BOOL isFirstStarUp;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    isFirstStarUp =
        [[NSUserDefaults standardUserDefaults] boolForKey:kNetworkTagIsFirstStartUp] == NO;
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kNetworkTagIsFirstStartUp];
  });
  return isFirstStarUp;
}

#pragma mark - LynxServices

- (void)setupServices {
  LynxServiceSettingsConfig* config = [[LynxServiceSettingsConfig alloc] init];
  config.appID = [BDL_SERVICE(BDLHostProtocol) appID];
  config.deviceID = [BDL_SERVICE(BDLHostProtocol) deviceID];
  config.appVersion = [BDL_SERVICE(BDLSDKProtocol) appVersion];
  config.settingsDomain = (NSString*)[BDLSDKManager getSystemInfoByKey:@"SETTINGS_DOMAIN"];
  [LynxService(LynxServiceSettingsProtocol) setupSettings:config];
}

@end
