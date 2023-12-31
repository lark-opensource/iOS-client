//
//  BDTuringSettingsHelper.h
//  BDTuring
//
//  Created by bytedance on 2021/11/10.
//


#import <Foundation/Foundation.h>

FOUNDATION_EXTERN NSString *const kBDTuringSettingsPeriod;
FOUNDATION_EXTERN NSString *const kBDTuringSettingsAlpha;
FOUNDATION_EXTERN NSString *const kBDTuringSettingsRetryCount;
FOUNDATION_EXTERN NSString *const kBDTuringSettingsRetryInterval;
FOUNDATION_EXTERN NSString *const kBDTuringSettingsRGB;
FOUNDATION_EXTERN NSString *const kBDTuringSettingsUseJSB;
FOUNDATION_EXTERN NSString *const kBDTuringSettingsPreCreate;
FOUNDATION_EXTERN NSString *const kBDTuringSettingsEncrypt;

FOUNDATION_EXTERN NSString *const kBDTuringSettingsURL;
FOUNDATION_EXTERN NSString *const kBDTuringSettingsHost;
FOUNDATION_EXTERN NSString *const kBDTuringSettingsBackupHost;

FOUNDATION_EXTERN NSString *const kBDTuringSettingsPreload;

FOUNDATION_EXTERN NSString *const kBDTuringSettingsPluginCommon;
FOUNDATION_EXTERN NSString *const kBDTuringSettingsPluginPicture;
FOUNDATION_EXTERN NSString *const kBDTuringSettingsPluginQA;
FOUNDATION_EXTERN NSString *const kBDTuringSettingsPluginSMS;
FOUNDATION_EXTERN NSString *const kBDTuringSettingsPluginSeal;

FOUNDATION_EXTERN NSString *const kBDTuringSettingsPluginAutoVerify;
FOUNDATION_EXTERN NSString *const kBDTuringSettingsPluginFullAutoVerify;

FOUNDATION_EXTERN NSString *const kBDTuringSettingsPluginTwiceVerify;

FOUNDATION_EXTERN NSString *const kBDTuringSettingsHeight;
FOUNDATION_EXTERN NSString *const kBDTuringSettingsWidth;

FOUNDATION_EXTERN NSString *const kBDTuringUseNativeReport;
FOUNDATION_EXTERN NSString *const kBDTuringUseJSBRequest;


typedef void (^BDTuringSettingServiceInterceptorBlock)(NSString * service,
                                                       NSString * key1,
                                                       NSString * region,
                                                       NSString * url);

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringSettingsHelper : NSObject

+ (instancetype)sharedInstance;

- (void) updateSettingCustomBlock:(NSString *)service
                     key1:(NSString *)key1
                      value:(NSString *)value
             forAppId:(NSString *)appID
          inRegion:(NSString *)region;

@end

NS_ASSUME_NONNULL_END
