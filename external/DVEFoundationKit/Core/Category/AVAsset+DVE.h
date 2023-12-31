//
//  AVAsset+DVE.h
//  DVEFoundationKit
//
//  Created by bytedance on 2021/4/14.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAsset (DVE)

- (CGSize)dve_videoSize;

- (AVCaptureVideoOrientation)dve_fixedOrientation;

- (CMTime)dve_videoTrackDuration;

@end

NS_ASSUME_NONNULL_END
