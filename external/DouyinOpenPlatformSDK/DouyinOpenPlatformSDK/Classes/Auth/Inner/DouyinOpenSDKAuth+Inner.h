//
//  DouyinOpenSDKAuth+Inner.h
//
//
//  Created by Spiker on 2019/7/9.
//

#import "DouyinOpenSDKAuth.h"
#import "DouyinOpenSDKAuthLicenseAgreement.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TikTokAuthProtocolVersion) {
    TikTokAuthProtocolVersionV1 = 0,
    TikTokAuthProtocolVersionV2,
};

@interface DouyinOpenSDKAuthRequest (Inner)

@property (nonatomic, copy, nullable) NSArray <NSNumber *> *fallbackIgnore; // 无用属性
@property (nonatomic, readonly) NSArray<NSString *> *schemaListForRequest;
@property (nonatomic, strong, nullable)DouyinOpenSDKAuthLicenseAgreement *license;
@property (nonatomic, copy) NSDictionary *customPlatformInfo;
@property (nonatomic, copy, nullable) NSString *customWebAuthDomain;

- (BOOL)sendAuthRequestWithWebInViewController:(UIViewController *)viewController completeBlock:(DouyinOpenSDKAuthCompleteBlock)completed;
+ (void)configWithAuthParameters:(NSDictionary *_Nullable)parameters;
+ (BOOL)isAppSupportCertification;
+ (BOOL)isAppSupportSwitchMutleUser;

@end

@interface DouyinOpenSDKAuthRequest (NSMutableCopying)
- (id)mutableCopy;
@end

NS_ASSUME_NONNULL_END
