//
//  BDUGAccountOnekeyLogin+Mobile.h
//  BDUGAccountOnekeyLogin
//
//  Created by chenzhendong.ok@bytedance.com on 2021/1/27.
//

#import "BDUGAccountOnekeyLogin.h"

NS_ASSUME_NONNULL_BEGIN


@interface BDUGAccountOnekeyLogin (Mobile)

- (void)mobileGetPhoneNumberCompletion:(void (^)(NSString *phoneNumber, NSString *serviceName, NSError *error))completedBlock;

- (void)mobileGetTokenWithCompletion:(void (^)(BDUGOnekeyAuthInfo *_Nullable authInfo, NSString *_Nullable serviceName, NSError *_Nullable error))completedBlock;

- (void)mobileGetMobileValidateTokenWithCompletion:(void (^)(NSString *_Nullable token, NSString *_Nullable service, NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
