//
//  BDNativeLiveVideoView.h
//  BDNativeWebComponent
//
//  Created by Bytedance on 2021/9/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDNativeLottieErrorCode) {
    BDNativeLottieErrorCodeInvalidData = 1,
    // Reserved 2
    // Reserved 3
    BDNativeLottieErrorCodeLocalResourcesNotFound = 4,
    BDNativeLottieErrorCodeCDNResourceNotFound,
    BDNativeLottieErrorCodeCDNResourceInvalidData,
};

typedef NS_ENUM(NSUInteger, BDNativeLottiePlayStateCode) {
    BDNativeLottiePlaying = 1,
    BDNativeLottiePaused,
    BDNativeLottieSeeked,
    BDNativeLottieFinished,
    BDNativeLottieCanceled,
    BDNativeLottieStopped,
};

typedef NS_ENUM(NSUInteger, BDNativeLottieStatusCode) {
    BDNativeLottieSourceLoaded = 1,
    BDNativeLottiePlayStateChanged,
    BDNativeLottieFrameUpdated,
    BDNativeLottieErrorHappened,
};

@class BDNativeLottieView;
@protocol BDNativeLottieViewDelegate <NSObject>

- (void)onNativeLottieSourceLoaded:(nonnull BDNativeLottieView *)view extraDetail:(nullable NSDictionary *)extraDetail;
- (void)onNativeLottiePlayStateChanged:(nonnull BDNativeLottieView *)view extraDetail:(nullable NSDictionary *)extraDetail;
- (void)onNativeLottieFrameUpdated:(nonnull BDNativeLottieView *)view extraDetail:(nullable NSDictionary *)extraDetail;
- (void)onNativeLottieErrorHappened:(nonnull BDNativeLottieView *)view extraDetail:(nullable NSDictionary *)extraDetail;

- (NSString *)fetchWebURL;

@end

@interface BDNativeLottieView : UIView

@property (nonatomic, weak) id<BDNativeLottieViewDelegate> delegate;

- (void)bdNativeAnimationWithURL:(nonnull NSString *)animationUrl;
- (void)bdNativeAnimationWithJSON:(nonnull NSDictionary *)animationJSON;
- (void)bdNativeUpdateAnimationPosition:(nonnull NSNumber *)delta withFrame:(BOOL)withFrame;
- (void)bdNativeStopAnimation;
- (void)bdNativeUpdateAnimationPlayState;
- (void)bdNativeUpdateAnimationProperties;

- (void)bdNativeSubscribeUpdateEvent:(nonnull NSNumber *)frame;
- (void)bdNativeUnsubscribeUpdateEvent:(nonnull NSNumber *)frame;

- (CGFloat)bdNativeAnimationDuration;
- (CGFloat)bdNativeAnimationProgress;
- (BOOL)bdNativeIsAnimationPlaying;
- (NSUInteger)bdNativeCurrentLoopIndex;
- (NSNumber *)bdNativeCurrentFrame;
- (NSNumber *)bdNativeTotalFrameCount;

@property (nonatomic, assign) BOOL loop;
@property (nonatomic, assign) BOOL autoReverse;
@property (nonatomic, assign) BOOL autoPlay;
@property (nonatomic, assign) BOOL couldPlay;
@property (nonatomic, assign) float speed;
@property (nonatomic, assign) NSInteger loopCount;
@property (nonatomic, strong) NSNumber *startFrame;
@property (nonatomic, strong) NSNumber *endFrame;
@property (nonatomic, copy) NSString *objectfitMode;

@end

NS_ASSUME_NONNULL_END
