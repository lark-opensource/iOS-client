//
//  BytedCertManager+Piper.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/8/22.
//

#import "BytedCertManager.h"
#import "BDCTCertificationFlow.h"

NS_ASSUME_NONNULL_BEGIN


@interface BytedCertManager (Piper)

- (void)p_beginAuthorizationWithParams:(NSDictionary *)params;

- (void)beginAuthorizationWithParameter:(BytedCertParameter *)parameter completion:(void (^)(NSError *_Nullable, NSDictionary *_Nullable))completion;

- (void)beginAuthorizationWithParameter:(BytedCertParameter *)parameter
                     fromViewController:(UIViewController *_Nullable)fromVC
                             completion:(void (^)(NSError *_Nullable, NSDictionary *_Nullable))completion;

- (void)beginAuthorizationWithParameter:(BytedCertParameter *)parameter
                     fromViewController:(UIViewController *_Nullable)fromVC
                           forcePresent:(BOOL)forcePresent
                             completion:(void (^)(NSError *_Nullable, NSDictionary *_Nullable))completion;

- (void)beginAuthorizationWithParameter:(BytedCertParameter *)parameter
                     fromViewController:(UIViewController *_Nullable)fromVC
                           forcePresent:(BOOL)forcePresent
                              superFlow:(BDCTFlow *_Nullable)superFlow
                             completion:(void (^_Nullable)(NSError *_Nullable, NSDictionary *_Nullable))completion;

+ (void)handleWebEventWithParams:(NSDictionary *)params completion:(void (^)(BOOL completed, NSDictionary *_Nullable result))completion;

@end

NS_ASSUME_NONNULL_END
