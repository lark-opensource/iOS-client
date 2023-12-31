//  Copyright 2023 The Lynx Authors. All rights reserved.

#import "LynxGenericReportInfo.h"
#import "LynxLog.h"
#import "LynxService.h"
#import "LynxServiceAppLogProtocol.h"
#import "LynxVersion.h"

// GeneralInfo props name:
// The last loaded URL in this lynxView, will be updated when lynxView render new template.
static NSString *const kPropURL = @"url";
// the relative_path would be equivalent to the url to remove applicationExternalCacheDir,
// applicationFilesDir and GeckoDir.
// It can be more accurate to filter info by relative_path than by url on the tea platform.
static NSString *const kPropRelativePath = @"relative_path";
// The last thread strategy this lynxView is using, will be updated when the lynxView is init.
static NSString *const kPropThreadMode = @"thread_mode";
// Lynx SDK's Version, set by LynxEnv.
static NSString *const kPropLynxSDKVersion = @"lynx_sdk_version";
// lynx_session_id is an unique id for all living LynxView, constructed with these three info:
// A unique device id, timestamp when first LoadTemplate, lynxViewIdentify.
// It would be like "$currentTimestamp-$deviceID-$lynxViewIdentify"
// It's assigned when LoadTemplate, shouldn't be modified anywhere.
static NSString *const kPropLynxSessionID = @"lynx_session_id";
// lynx_dsl could be ttml, react, react_nodiff or unkown.
static NSString *const kPropLynxDSL = @"lynx_dsl";
// lepus_type could be lepus or lepusNG.
static NSString *const kPropLynxLepusType = @"lynx_lepus_type";
// targetSdkVersion set by FE.
NSString *const kPropLynxTargetSDKVersion = @"lynx_target_sdk_version";
// template's page version set by FE.
NSString *const kPropLynxPageVersion = @"lynx_page_version";
// Property value of lepusNG.
static NSString *const kPropValueLepusNG = @"lepusNG";
// Property value of lepus.
static NSString *const kPropValueLepus = @"lepus";
// DSL's property value of tt.
static NSString *const kPropValueTT = @"tt";
// DSL's property value of ttml.
static NSString *const kPropValueTTML = @"ttml";

@interface LynxGenericReportInfo ()

@property(nonatomic, weak) NSObject *targetObj;
@property(nonatomic, strong) NSMutableDictionary *props;
@property(nonatomic, strong) NSDictionary *immutableProps;

@end

@implementation LynxGenericReportInfo

#pragma mark - Public
+ (instancetype)infoWithTarget:(NSObject *)targetObj {
  LynxGenericReportInfo *instance = [[LynxGenericReportInfo alloc] init];
  instance.targetObj = targetObj;
  [instance setup];
  return instance;
}

- (NSDictionary *)toJson {
  if (!self.immutableProps) {
    return [self.props copy];
  }
  return self.immutableProps;
}

- (void)updatePropOpt:(id)value forKey:(NSString *)key {
  if (!key || !value) {
    return;
  }
  if (self.immutableProps) {
    LLogInfo(@"LynxGenericReportInfo updatePropOpt:%@ forKey:%@ after marking immutable", value,
             key);
    return;
  }
  [_props setValue:value forKey:key];
}

- (void)updateEnableLepusNG:(BOOL)enableLepusNG {
  [self updatePropOpt:enableLepusNG ? kPropValueLepusNG : kPropValueLepus
               forKey:kPropLynxLepusType];
}

- (void)updateDSL:(NSString *)dsl {
  NSString *pageType = [dsl isEqualToString:kPropValueTT] ? kPropValueTTML : dsl;
  [self updatePropOpt:pageType forKey:kPropLynxDSL];
}

// URL Info
- (void)updateLynxUrl:(NSString *)templateURL {
  if (!templateURL) {
    LLogInfo(@"LynxGenericReportInfo updateLynxUrl with nil");
    return;
  }
  if (self.immutableProps) {
    LLogInfo(@"LynxGenericReportInfo updateLynxUrl %@ after marking immutable", templateURL);
    return;
  }
  NSString *originUrl = [self propValueForKey:kPropURL];
  if (originUrl && [originUrl isEqualToString:templateURL]) {
    return;
  }
  [self updatePropOpt:templateURL forKey:kPropURL];
  [self updateRelativeURL:templateURL];
}

- (void)updateThreadStrategy:(NSInteger)threadStrategyForRendering {
  [self updatePropOpt:@(threadStrategyForRendering) forKey:kPropThreadMode];
}

- (void)markImmutable {
  if (self.immutableProps) {
    return;
  }
  self.immutableProps = self.props.copy;
}

#pragma mark - Private
- (void)setup {
  _props = [NSMutableDictionary dictionary];
  // SessionID Info
  NSString *did = [LynxService(LynxServiceAppLogProtocol) getDeviceID];
  NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970] * 1000;
  NSString *sessionID =
      [NSString stringWithFormat:@"%f-%@-%p", currentTimestamp, did, self.targetObj];
  [self updatePropOpt:sessionID forKey:kPropLynxSessionID];
  // lynx sdk version
  [self updatePropOpt:[LynxVersion versionString] forKey:kPropLynxSDKVersion];
}

- (nullable id)propValueForKey:(NSString *)aKey {
  if (!aKey) {
    return nil;
  }
  id value = [self.props objectForKey:aKey];
  return value;
}

- (void)updateRelativeURL:(NSString *)urlStr {
  // 0. try removing unencoded AppSupportDir
  NSString *relative_path =
      [urlStr stringByReplacingOccurrencesOfString:[LynxGenericReportInfo appSupportDir]
                                        withString:@""];
  // 1. try removing encoded AppSupportDir
  NSString *encodeAppSupportDir = [[LynxGenericReportInfo appSupportDir]
      stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet
                                                             URLQueryAllowedCharacterSet]];
  relative_path = [relative_path stringByReplacingOccurrencesOfString:encodeAppSupportDir
                                                           withString:@""];
  [self updatePropOpt:relative_path forKey:kPropRelativePath];
}

static NSString *kApplicationSupportPath;
+ (NSString *)appSupportDir {
  if (!kApplicationSupportPath) {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                          NSUserDomainMask, YES) firstObject];

    kApplicationSupportPath = [NSString stringWithFormat:@"file://%@", path ?: @""];
  }
  return kApplicationSupportPath;
}

@end
