//
//  AVAsset+LV.h
//  DraftComponent
//
//  Created by xiongzhuang on 2019/7/25.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAsset (LV)

/**
 修正方向

 @return 修正后的方向
 */
- (AVCaptureVideoOrientation)lv_fixedOrientation;

- (CGSize)lv_videoSize;

- (CMTime)lv_videoDuration;

@end

NS_ASSUME_NONNULL_END
