//
//  BytedCertManager+VideoRecord.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/5.
//

#import "BytedCertManager.h"
#import "BytedCertVideoRecordParameter.h"
#import "BytedCertError.h"

NS_ASSUME_NONNULL_BEGIN


@interface BytedCertManager (VideoRecord)

+ (void)recordVideoWithParameter:(BytedCertVideoRecordParameter *)parameter fromViewController:(UIViewController *_Nullable)fromViewController completion:(void (^)(BytedCertError *error))completion;

@end

NS_ASSUME_NONNULL_END
