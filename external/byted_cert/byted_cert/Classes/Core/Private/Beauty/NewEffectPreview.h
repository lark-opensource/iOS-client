//
//  NewEffectView.h
//  smash_demo
//

#import <GLKit/GLKit.h>
#import "BDCTCaptureRenderView.h"

NS_ASSUME_NONNULL_BEGIN


@interface NewEffectPreview : GLKView <BDCTCaptureRenderProtocol>

- (void)setBeautuyIntensity:(int)beautyIntensity;
- (void)update:(CVPixelBufferRef)pixelBuffer;
- (void)render;

@end

NS_ASSUME_NONNULL_END
