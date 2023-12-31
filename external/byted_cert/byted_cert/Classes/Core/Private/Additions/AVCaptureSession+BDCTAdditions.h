//
//  AVCaptureSession+BDCTAdditions.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/3/31.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface AVCaptureSession (BDCTAdditions)

- (void)bdct_reorientCamera;

- (void)bdct_mirrorSetting;

- (void)bdct_startRunning;

- (void)bdct_stopRunning;

@end

NS_ASSUME_NONNULL_END
