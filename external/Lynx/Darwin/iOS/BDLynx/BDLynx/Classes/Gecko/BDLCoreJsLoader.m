//
//  BDLCoreJsLoader.m
//  Pods
//
//  Created by admin on 2020/8/31.
//

#import "BDLCoreJsLoader.h"
#import <sys/utsname.h>
#import "BDLGeckoProtocol.h"
#import "BDLHostProtocol.h"
#import "BDLSDKManager.h"
#import "BDLUtils.h"
#import "LynxVersion.h"
#import "LynxView.h"

static NSString* LYNX_CORE_JS_ACCESS_KEY = @"d232c45c76efd1601acd851990af3683";
static NSString* LYNX_CORE_JS_DEBUG_ACCESS_KEY = @"6fe52b3d47cb62db6716952f51ec973e";
static NSString* LYNX_CORE_JS_CHANNEL = @"lynx_core";
static NSString* LYNX_CORE_JS_FILE = @"lynx_core.js";
static NSString* LYNX_CORE_JS_ASSET_VERSION_FILE = @"lynxCoreJSBundleCheck";
static NSString* LYNX_CORE_EVENT_NAME = @"lynx_core";
static NSString* LYNX_CORE_EVENT_KEY_FROM = @"coreJsFrom";
static NSString* LYNX_CORE_EVENT_KEY_VERSION = @"core_js_version";
// at last 5min interval to check js update
static long LYNX_CORE_JS_UPDATE_CHECK_INTERVAL = 5 * 60;

@implementation BDLCoreJsLoader {
  NSString* accesskey;
  int versionFromServer;
  int versionFromLocal;
  long lastCheck;
  // flag for up to date
  bool jsCoreUpdated;
}

- (instancetype)initWithOnline:(bool)isOnline {
  if (isOnline) {
    accesskey = LYNX_CORE_JS_ACCESS_KEY;
  } else {
    accesskey = LYNX_CORE_JS_DEBUG_ACCESS_KEY;
  }
  [self obtainLocalGurdCoreJSVersion];
  [self obtainLocalCoreJSVersion];
  [BDL_SERVICE(BDLGeckoProtocol) registerChannels:@[ LYNX_CORE_JS_CHANNEL ] forAccessKey:accesskey];
  jsCoreUpdated = NO;
  lastCheck = 0;
  return self;
}

- (instancetype)init {
  return [self initWithOnline:true];
}

/**
    Get the downloaded version number
 */
- (void)obtainLocalGurdCoreJSVersion {
  NSString* path = [BDL_SERVICE(BDLGeckoProtocol) rootDirectoryForAccessKey:accesskey
                                                                    channel:LYNX_CORE_JS_CHANNEL];
  NSFileManager* manager = [NSFileManager defaultManager];
  if (path == nil) {
    return;
  }
  NSString* bundleCheckPath = [path stringByAppendingPathComponent:LYNX_CORE_JS_ASSET_VERSION_FILE];
  if ([manager fileExistsAtPath:bundleCheckPath]) {
    NSString* str = [NSString stringWithContentsOfFile:bundleCheckPath
                                              encoding:NSUTF8StringEncoding
                                                 error:nil];
    if (str != nil && ![str isEqualToString:@""]) {
      int newVersion = [str intValue];
      if (newVersion != versionFromServer) {
        jsCoreUpdated = true;
        versionFromServer = newVersion;
      }
    }
  }
}
/**
  Get the existing version number in the package
 */
- (void)obtainLocalCoreJSVersion {
  NSBundle* frameworkBundle = [NSBundle bundleForClass:[LynxView class]];
  NSURL* bundleUrl = [frameworkBundle URLForResource:@"LynxResources" withExtension:@"bundle"];
  NSBundle* bundle = [NSBundle bundleWithURL:bundleUrl];
  NSString* path = [bundle pathForResource:LYNX_CORE_JS_ASSET_VERSION_FILE ofType:nil];
  if (path != nil && ![path isEqualToString:@""]) {
    NSString* str = [NSString stringWithContentsOfFile:path
                                              encoding:NSUTF8StringEncoding
                                                 error:nil];
    if (str != nil && ![str isEqualToString:@""]) {
      versionFromLocal = [str intValue];
    }
  }
}
/**
  Returns whether updates are needed
 */
- (BOOL)jsCoreUpdate {
  return jsCoreUpdated;
}

- (NSString*)modelString {
  struct utsname systemInfo;
  uname(&systemInfo);
  NSString* deviceModel = [NSString stringWithCString:systemInfo.machine
                                             encoding:NSUTF8StringEncoding];
  return deviceModel;
}

/**
  Start an update request
  */
- (void)checkUpdate {
  NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
  NSInteger time = interval;
  if (time - lastCheck < LYNX_CORE_JS_UPDATE_CHECK_INTERVAL) {
    return;
  }
  lastCheck = interval;
  NSString* aid = [BDL_SERVICE(BDLHostProtocol) appID];
  NSString* phoneVersion = [[UIDevice currentDevice] systemVersion];
  NSString* phoneModel = [self modelString];
  NSDictionary* params = @{
    @"business_version" : [LynxVersion versionString],
    @"aid" : aid,
    @"os_version" : phoneVersion,
    @"model" : phoneModel
  };
  if ([BDL_SERVICE(BDLGeckoProtocol)
          respondsToSelector:@selector
          (syncResourcesWithAccessKey:
                             channels:businessDomain:forceSync:customParams:completion:)]) {
    [BDL_SERVICE(BDLGeckoProtocol)
        syncResourcesWithAccessKey:accesskey
                          channels:@[ LYNX_CORE_JS_CHANNEL ]
                    businessDomain:nil
                         forceSync:NO
                      customParams:params
                        completion:^(BOOL succeed,
                                     NSDictionary<NSString*, NSNumber*>* _Nonnull dict) {
                          if (succeed) {
                            [self obtainLocalGurdCoreJSVersion];
                          }
                        }];
  } else if ([BDL_SERVICE(BDLGeckoProtocol)
                 respondsToSelector:@selector
                 (syncResourcesWithAccessKey:channels:businessDomain:customParams:completion:)]) {
    [BDL_SERVICE(BDLGeckoProtocol)
        syncResourcesWithAccessKey:accesskey
                          channels:@[ LYNX_CORE_JS_CHANNEL ]
                    businessDomain:nil
                      customParams:params
                        completion:^(BOOL succeed,
                                     NSDictionary<NSString*, NSNumber*>* _Nonnull dict) {
                          if (succeed) {
                            [self obtainLocalGurdCoreJSVersion];
                          }
                        }];
  }
}
/**
  Get the latest core.js
 */
- (NSString* _Nullable)getCoreJs {
  jsCoreUpdated = NO;
  if (versionFromServer == 0 || versionFromLocal == 0 || versionFromServer <= versionFromLocal) {
    NSLog(@"no server lynx_core.js version found, use assets resource");
    [self eventBuildInVersion];
    return nil;
  }
  NSString* jsPath = [[BDL_SERVICE(BDLGeckoProtocol) rootDirectoryForAccessKey:accesskey
                                                                       channel:LYNX_CORE_JS_CHANNEL]
      stringByAppendingPathComponent:LYNX_CORE_JS_FILE];
  NSFileManager* manager = [NSFileManager defaultManager];
  if ([manager fileExistsAtPath:jsPath]) {
    NSString *gurdPrefix = @"Ge";
    [BDLUtils event:LYNX_CORE_EVENT_NAME
             params:@{
               LYNX_CORE_EVENT_KEY_FROM : [gurdPrefix stringByAppendingString:@"cko"],
               LYNX_CORE_EVENT_KEY_VERSION : [NSString stringWithFormat:@"%d", versionFromServer]
             }];
    return jsPath;
  }
  [self eventBuildInVersion];
  return nil;
}

- (void)eventBuildInVersion {
  NSString* reportVersion = @"unknow";
  if (versionFromLocal != 0) {
    reportVersion = [NSString stringWithFormat:@"%d", versionFromLocal];
  }
  [BDLUtils event:LYNX_CORE_EVENT_NAME
           params:@{
             LYNX_CORE_EVENT_KEY_FROM : @"build-in",
             LYNX_CORE_EVENT_KEY_VERSION : reportVersion
           }];
}

@end
