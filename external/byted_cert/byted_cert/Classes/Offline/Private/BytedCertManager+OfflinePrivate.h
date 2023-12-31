//
//  BytedCertManager+OfflinePrivate.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/8/23.
//

#import "BytedCertManager.h"

@class BytedCertError, BytedCertOfflineDetectPatameter;

NS_ASSUME_NONNULL_BEGIN


@interface BytedCertManager (OfflinePrivate)

+ (void)p_beginOfflineFaceVerificationWithParameter:(BytedCertOfflineDetectPatameter *)parameter completion:(void (^)(NSDictionary *_Nullable result, BytedCertError *_Nullable bytedCertError))completion;

@end

NS_ASSUME_NONNULL_END
