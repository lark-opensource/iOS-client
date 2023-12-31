//
//  BDPUserInfoManager.h
//  Timor
//
//  Created by liuxiangxin on 2019/6/25.
//

#import <Foundation/Foundation.h>
#import "BDPJSBridgeProtocol.h"

typedef NS_ENUM(NSInteger, BDPUserInfoErrorCode) {
    BDPUserInfoErrorCodeNone = 0,
    BDPUserInfoErrorCodeServerError = 2000,
    BDPUserInfoErrorCodeInvalidSession = 4000,
    BDPUserInfoErrorCodeNotLogin = 4001,
    BDPUserInfoErrorCodeUnknow = 6000
};

FOUNDATION_EXPORT NSErrorDomain const _Nonnull BDPUserInfoErrorDomain;
FOUNDATION_EXPORT NSString * _Nonnull const BDPUserInfoServerErrorKey;
FOUNDATION_EXPORT NSString *const BDPUserInfoAvatarURLKey;
FOUNDATION_EXPORT NSString *const BDPUserInfoCityKey;
FOUNDATION_EXPORT NSString *const BDPUserInfoCountryKey;
FOUNDATION_EXPORT NSString *const BDPUserInfoGenderKey;
FOUNDATION_EXPORT NSString *const BDPUserInfoLanguageKey;
FOUNDATION_EXPORT NSString *const BDPUserInfoNickNameKey;
FOUNDATION_EXPORT NSString *const BDPUserInfoProvicneKey;
FOUNDATION_EXPORT NSString *const BDPUserInfoRawDataKey;
FOUNDATION_EXPORT NSString *const BDPUserInfoUserIDKey;
FOUNDATION_EXPORT NSString *const BDPUserInfoUserInfoKey;
FOUNDATION_EXPORT NSString *const BDPUserInfosessionIDKey;

NS_ASSUME_NONNULL_BEGIN

@interface BDPUserInfoManager : NSObject

+ (void)fetchUserInfoWithCredentials:(BOOL)credentials
                             context:(BDPPluginContext)context
                          completion:(void (^)(NSDictionary *userInfo, NSError *error))completion;
@end

NS_ASSUME_NONNULL_END
