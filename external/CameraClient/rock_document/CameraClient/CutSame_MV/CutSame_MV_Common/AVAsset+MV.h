//
//  AVAsset+LV.h
//  CameraClient
//
//  Created by xulei on 2020/6/1.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAsset (MV)

/**
 修正方向

 @return 修正后的方向
 */
- (AVCaptureVideoOrientation)mv_fixedOrientation;

- (CGSize)mv_videoSize;

@end

NS_ASSUME_NONNULL_END
