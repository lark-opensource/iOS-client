//
//  DouyinOpenSDKAuth+Privates.h
//
//
//  Created by Spiker on 2019/7/9.
//

#import "DouyinOpenSDKAuth.h"
#import "DouyinOpenSDKAuthLicenseAgreement.h"
NS_ASSUME_NONNULL_BEGIN
@interface DouyinOpenSDKAuthRequest ()

- (NSDictionary *)postExtraInfo;
+ (NSDictionary *)authCommonParamters;
@property (nonatomic, copy) NSArray <NSNumber *> *fallbackIgnore;
@property (nonatomic, strong, nullable)DouyinOpenSDKAuthLicenseAgreement *license;
@property (nonatomic, readonly) BOOL isVaild;
@property (nonatomic, copy) NSDictionary *customPlatformInfo;
@property (nonatomic, copy, nullable) NSString *customWebAuthDomain;

@end

@interface DouyinOpenSDKAuthResponse ()

@property (nonatomic, copy, readwrite, nullable) NSString *code;

/**
 第三方应用程序用来标识请求的唯一性，最后跳转回第三方程序时由 Douyin 回传
 */
@property (nonatomic, copy, readwrite, nullable) NSString *state;
@end
NS_ASSUME_NONNULL_END
