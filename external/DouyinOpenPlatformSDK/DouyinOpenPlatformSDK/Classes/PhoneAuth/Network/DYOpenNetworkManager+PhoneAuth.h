//
//  DYOpenNetworkManager+PhoneAuth.h
//  DouyinOpenPlatformSDK-af734e60
//
//  Created by arvitwu on 2023/3/15.
//

#import "DYOpenNetworkManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface DYOpenNetworkManager (PhoneAuth)

/// 宿主手机号授权页面信息
/// @param hostTicket 在新版可传 nil 了
+ (void)phoneAuth_requestAuthInfoWithClientKey:(NSString *_Nonnull)clientKey
                                         scope:(NSString *_Nonnull)scope
                                    hostTicket:(NSString *_Nullable)hostTicket
                           isSkipUIInThirdAuth:(BOOL)isSkipUIInThirdAuth
                                thirdAuthScene:(NSString *_Nonnull)thirdAuthScene
                                    completion:(DouyinOpenNetworkCompletion _Nullable)completion;

/// 宿主手机号一键授权
+ (void)phoneAuth_requestOneAuthWithOnly:(BOOL)isOnly
                                  ticket:(NSString *_Nonnull)ticket
                               clientKey:(NSString *_Nonnull)clientKey
                             appIdentity:(NSString *_Nonnull)appIdentity
                                   scope:(NSString *_Nonnull)scope
                              completion:(DYOpenNetworkCompletion _Nullable)completion;

@end

NS_ASSUME_NONNULL_END
