//
//  BDCTFaceVerificationFlow+Download.h
//  byted_cert
//
//  Created by liuminghui.2022 on 2023/2/2.
//

#import "BDCTFaceVerificationFlow.h"

NS_ASSUME_NONNULL_BEGIN


@interface BDCTFaceVerificationFlow (Download)

- (void)downloadAudioWithCompletion:(void (^)(BOOL success, NSDictionary *_Nullable error, NSString *_Nullable path))completion;

@end

NS_ASSUME_NONNULL_END
