//
//  BDCTEventTracker+VideoRecord.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/30.
//

#import "BDCTEventTracker.h"
#import "BytedCertError.h"

NS_ASSUME_NONNULL_BEGIN


@interface BDCTEventTracker (VideoRecord)

- (void)trackAuthVideoCheckingStart;
- (void)trackAuthVideoCheckingResultWithError:(BytedCertError *)error params:(NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
