//
//  BDCTVideoRecordViewController+Camera.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/18.
//

#import "BDCTVideoRecordViewController.h"

NS_ASSUME_NONNULL_BEGIN


@interface BDCTVideoRecordViewController (Camera) <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong, readonly) AVCaptureVideoPreviewLayer *previewLayer;

@end

NS_ASSUME_NONNULL_END
