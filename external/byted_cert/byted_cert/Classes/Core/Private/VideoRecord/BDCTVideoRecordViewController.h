//
//  BDCTVideoRecordViewController.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/5.
//

#import "BDCTBaseCameraViewController.h"
#import "BytedCertVideoRecordParameter.h"
#import "BytedCertError.h"

NS_ASSUME_NONNULL_BEGIN


@interface BDCTVideoRecordViewController : BDCTBaseCameraViewController

@property (nonatomic, copy, nullable) void (^completionBlock)(BytedCertError *error);

- (void)startVideoRecord;

@end

NS_ASSUME_NONNULL_END
