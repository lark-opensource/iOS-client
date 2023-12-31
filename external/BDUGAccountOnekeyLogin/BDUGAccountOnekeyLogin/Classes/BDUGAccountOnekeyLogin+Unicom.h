//
//  BDUGAccountOnekeyLogin+Unicom.h
//  BDUGAccountOnekeyLogin
//
//  Created by chenzhendong.ok@bytedance.com on 2021/1/27.
//

#import "BDUGAccountOnekeyLogin.h"

NS_ASSUME_NONNULL_BEGIN


@interface BDUGAccountOnekeyLogin (Unicom)

- (void)unionGetPhoneNumberCompleted:(void (^)(NSString *phoneNumber, NSString *serviceName, NSError *error))completedBlock;

- (void)unionGetTokenWithCompleted:(void (^)(BDUGOnekeyAuthInfo *_Nullable authInfo, NSString *_Nullable serviceName, NSError *_Nullable error))completedBlock;

@end

NS_ASSUME_NONNULL_END
