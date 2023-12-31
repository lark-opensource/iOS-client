//
// Don't edit this file directly.
// This file is generated from TTPlayerView.h.in
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "TTPlayerViewProtocol.h"
#import "TTAVPlayer.h"
#import "TTAVPlayerItem.h"

#if TTAVPLAYER_MACOS
@interface TTPlayerView : NSView<TTPlayerViewProtocol>
#else
@interface TTPlayerView : UIView<TTPlayerViewProtocol>
#endif

@property (nonatomic, strong) id<TTAVPlayerProtocol> player;
@property (nonatomic, assign) TTPlayerViewAlignMode alignMode;
@property (nonatomic, assign) CGFloat alignRatio;
@property (nonatomic, assign) TTPlayerViewScaleType scaleType;
@property (nonatomic, assign) TTPlayerViewRenderType renderType;
@property (nonatomic, assign) TTPlayerViewRenderType lastRenderType;
@property (nonatomic, assign) TTPlayerViewRotateType rotateType;
@property (nonatomic, assign) BOOL memoryOptimizeEnabled;
@property (nonatomic, assign) CGRect cropAreaFrame;
@property (nonatomic, assign) CGRect normalizeCropArea;
@property (nonatomic, assign) BOOL useNormalizeCropArea;
@property (nonatomic, assign, readonly) CGRect videoAreaFrame;
@property (nonatomic, assign, getter=isSupportPictureInPictureMode) BOOL supportPictureInPictureMode;

+ (instancetype)playerViewWithPlayer:(id<TTAVPlayerProtocol>)player;

+ (instancetype)playerViewWithPlayer:(id<TTAVPlayerProtocol>)player type:(TTPlayerViewRenderType)type;

- (BOOL)needRemoveView:(id<TTAVPlayerProtocol>) player;

- (void)setOptionForKey:(NSInteger)key value:(id)value;

- (void)updateVideoFrame;

- (void)play;

- (void)pause;

- (void)releaseContents;

- (CVPixelBufferRef)copyPixelBuffer;

- (void)setRenderRotation:(int)rotation;

- (void)setColorPrimaries:(int)colorPrimaries;

- (void)setRenderPaused:(BOOL)paused;

@end
