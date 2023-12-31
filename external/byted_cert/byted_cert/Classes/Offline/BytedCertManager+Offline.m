//
//  BytedCertManager+Offline.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/8/23.
//

#import "BytedCertManager+Offline.h"
#import "BytedCertWrapper+Offline.h"
#import "BytedCertWrapper+Download.h"
#import "BDCTOfflineFaceVerificationFlow.h"
#import "BytedCertManager+OfflinePrivate.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>


@implementation BytedCertOfflineDetectPatameter

@end


@implementation BytedCertManager (Offline)

+ (void)beginOfflineFaceVerificationWithParameter:(BytedCertOfflineDetectPatameter *)parameter completion:(void (^)(NSError *_Nullable, NSDictionary *_Nullable))completion {
    [self p_beginOfflineFaceVerificationWithParameter:parameter completion:^(NSDictionary *_Nullable result, BytedCertError *_Nullable bytedCertError) {
        if (!bytedCertError) {
            !completion ?: completion(nil, result);
        } else {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : bytedCertError.errorMessage ?: @""};
            NSError *error = [NSError errorWithDomain:BytedCertManagerErrorDomain code:bytedCertError.errorCode userInfo:userInfo];
            !completion ?: completion(error, result);
        }
    }];
}

@end
