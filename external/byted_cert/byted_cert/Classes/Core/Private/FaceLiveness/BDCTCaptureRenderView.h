//
//  BytedCertCaptureRenderView.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/3/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDCTCaptureRenderProtocol <NSObject>

- (void)update:(CVPixelBufferRef)pixelBuffer;

@end


@interface BDCTCaptureRenderView : UIImageView <BDCTCaptureRenderProtocol>

@end

NS_ASSUME_NONNULL_END
