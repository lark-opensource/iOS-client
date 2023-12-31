//
//  BDNativeLiveVideoView.m
//  BDNativeWebComponent
//
//  Created by Bytedance on 2021/9/23.
//

#import "BDNativeLottieView.h"

#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import <lottie-ios/Lottie/LOTAsset.h>
#import <lottie-ios/Lottie/LOTCompositionContainer.h>
#import <lottie-ios/Lottie/LOTAnimationDelegate.h>
#import <Lottie/Lottie.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import <BDWebImage/BDWebImage.h>
#import <ByteDanceKit/ByteDanceKit.h>

@interface LOTAnimationView (BDNativeLottieView)

- (void)_initializeAnimationContainer;
- (void)_setupWithSceneModel:(LOTComposition *)model;

@end

@interface BDNativeLottieView() <LOTAnimationDelegate>

@property (nonatomic, strong) LOTAnimationView *lottieView;
@property (nonatomic, copy) NSString *currentAnimationURL;
@property (nonatomic, assign) NSUInteger loopIndex;
@property (nonatomic, strong) NSNumber *lastFrame;
@property (nonatomic, assign) BOOL resourceHasReady;
@property (nonatomic, assign) BOOL playWhenAllReady;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *subscribedFrames;
@property (nonatomic, strong) NSDate *lastDateOfSourceUpdate;

@end

@implementation BDNativeLottieView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _lottieView = [[LOTAnimationView alloc] init];
        _lottieView.animationDelegate = self;
        _couldPlay = YES;
        _resourceHasReady = NO;
        _playWhenAllReady = NO;
        _speed = 1.0;
        _subscribedFrames = [NSMutableDictionary dictionary];
        
        [self addSubview:self.lottieView];
    }
    return self;
}

- (void)dealloc
{
    [self.lottieView stop];
    [self.lottieView removeFromSuperview];
    self.lottieView = nil;
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.lottieView.frame = self.bounds;
}

#pragma mark - LOTAnimationView

- (void)updateAnimation:(NSDictionary *)data withURL:(NSString *)source
{
    if (![data isKindOfClass:[NSDictionary class]] || ![source isKindOfClass:[NSString class]]) {
        return;
    }
    NSDictionary *jsonData = [data copy];
    NSURL *baseURL = [NSURL btd_URLWithString:source];
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([weakSelf.lottieView respondsToSelector:@selector(_initializeAnimationContainer)] && [weakSelf.lottieView respondsToSelector:@selector(_setupWithSceneModel:)]) {
            LOTComposition *composition = [LOTComposition animationFromJSON:jsonData];
            if (baseURL.isFileURL) {
                composition.rootDirectory = baseURL.path.stringByDeletingLastPathComponent;
                composition.ignoreBundleResource = NO;
            } else {
                composition.baseURL = baseURL;
                composition.ignoreBundleResource = YES;
            }
            [weakSelf.lottieView _initializeAnimationContainer];
            [weakSelf.lottieView _setupWithSceneModel:composition];
        } else {
            [weakSelf.lottieView setAnimationFromJSON:jsonData];
        }
    });
}

- (void)bdNativeAnimationWithURL:(NSString *)animationUrl
{
    if (![animationUrl isKindOfClass:[NSString class]] || animationUrl.length == 0 || [animationUrl isEqualToString:self.currentAnimationURL]) {
        [self.delegate onNativeLottieErrorHappened:self extraDetail:@{
            @"errorCode": @(BDNativeLottieErrorCodeInvalidData),
            @"errorExt" : @"Empty animation URL",
        }];
        return;
    }
    
    self.resourceHasReady = NO;
    self.lastDateOfSourceUpdate = [NSDate date];
    self.currentAnimationURL = animationUrl;
    NSURL *url = [NSURL btd_URLWithString:self.currentAnimationURL];
    if (!url) {
        [self.delegate onNativeLottieErrorHappened:self extraDetail:@{
            @"errorCode": @(BDNativeLottieErrorCodeInvalidData),
            @"errorExt" : @"Wrong animation URL",
        }];
        return;
    }
    
    __weak __typeof(self) weakSelf = self;
    [TTNetworkManager.shareInstance requestForBinaryWithURL:url.absoluteString ?: @""
                                                     params:nil
                                                     method:@"GET"
                                           needCommonParams:YES
                                                   callback:^(NSError *error, id obj) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if ([obj isKindOfClass:[NSData class]]) {
                NSError *jsonError = nil;
                NSDictionary *animationJSON = [NSJSONSerialization JSONObjectWithData:(NSData *)obj
                                                                              options:0
                                                                                error:&jsonError];
                if (jsonError || !animationJSON) {
                    [weakSelf.delegate onNativeLottieErrorHappened:self extraDetail:@{
                        @"errorCode": @(BDNativeLottieErrorCodeCDNResourceInvalidData),
                        @"errorExt" : jsonError ? jsonError.localizedDescription : @"Parse cdn data error.",
                    }];
                    return;
                }
                
                [weakSelf updateAnimation:[animationJSON copy] withURL:url.absoluteString ?: @""];
            } else {
                [weakSelf.delegate onNativeLottieErrorHappened:self extraDetail:@{
                    @"errorCode": @(BDNativeLottieErrorCodeCDNResourceNotFound),
                    @"errorExt" : error ? error.localizedDescription : @"Failed to load resources.",
                }];
            }
        });
    }];
    
}

- (void)bdNativeAnimationWithJSON:(NSDictionary *)animationJSON
{
    if (![animationJSON isKindOfClass:[NSDictionary class]]) {
        [self.delegate onNativeLottieErrorHappened:self extraDetail:@{
            @"errorCode": @(BDNativeLottieErrorCodeInvalidData),
            @"errorExt" : @"Invalid json data.",
        }];
        return;
    }
    self.resourceHasReady = NO;
    self.lastDateOfSourceUpdate = [NSDate date];
    NSString *baseURL = [self.delegate fetchWebURL];
    [self updateAnimation:[animationJSON copy] withURL:baseURL];
}

- (void)bdNativeStopAnimation
{
    self.couldPlay = NO;
    [self.lottieView stop];
}

- (void)bdNativeUpdateAnimationPosition:(NSNumber *)delta withFrame:(BOOL)withFrame
{
    if (![delta isKindOfClass:[NSNumber class]]) {
        return;
    }
    if (withFrame) {
        // seek to target frame
        [self.lottieView setProgressWithFrame:delta];
    } else {
        // set progress to relative position, and call completion block
        self.lottieView.animationProgress = delta.floatValue;
    }
    [self.delegate onNativeLottiePlayStateChanged:self extraDetail:@{
        @"playState"    : @(BDNativeLottieSeeked),
        @"playStateExt" : @"Animation progress has changed.",
    }];
}

- (void)bdNativeUpdateAnimationPlayState
{
    if (self.couldPlay) {
        [self playIfReady];
    } else {
        [self.lottieView pause];
    }
}

- (CGFloat)bdNativeAnimationDuration
{
    return self.lottieView.animationDuration * 1000;
}

- (CGFloat)bdNativeAnimationProgress
{
    return self.lottieView.animationProgress;
}

- (BOOL)bdNativeIsAnimationPlaying
{
    return self.lottieView.isAnimationPlaying;
}

- (NSUInteger)bdNativeCurrentLoopIndex
{
    return self.loopIndex;
}

- (NSNumber *)bdNativeCurrentFrame
{
    LOTCompositionContainer *container = [self.lottieView valueForKeyPath:@"compContainer"];
    return container.currentFrame;
}

- (NSNumber *)bdNativeTotalFrameCount
{
    LOTComposition *scene = self.lottieView.sceneModel;
    if (scene && scene.endFrame && scene.startFrame) {
        return @(scene.endFrame.unsignedIntValue - scene.startFrame.unsignedIntValue);
    }
    
    return @(0);
}

- (void)__configFitMode
{
    if ([self.objectfitMode isEqualToString:@"contain"]) {
        self.lottieView.contentMode = UIViewContentModeScaleAspectFit;
    } else if ([self.objectfitMode isEqualToString:@"cover"]) {
        self.lottieView.contentMode = UIViewContentModeScaleAspectFill;
    } else if ([self.objectfitMode isEqualToString:@"fill"]) {
        self.lottieView.contentMode = UIViewContentModeScaleToFill;
    } else if ([self.objectfitMode isEqualToString:@"none"]){
        self.lottieView.contentMode = UIViewContentModeCenter;
    }
}

- (void)bdNativeUpdateAnimationProperties
{
    LOTAnimationView *animationView = self.lottieView;
    if (!animationView) {
        return;
    }
    
    animationView.loopAnimation = self.loop;
    animationView.autoReverseAnimation = self.autoReverse;
    animationView.animationSpeed = self.speed;
    animationView.repeatCount = self.loopCount;
    [self __configFitMode];
}

- (void)bdNativeSubscribeUpdateEvent:(NSNumber *)frame
{
    if (!self.subscribedFrames[frame]) {
        self.subscribedFrames[frame] = @NO;
    }
}

- (void)bdNativeUnsubscribeUpdateEvent:(NSNumber *)frame
{
    self.subscribedFrames[frame] = nil;
}

- (void)playIfReady
{
    // sync playState with JS-Controller
    if (!self.couldPlay) {
        return;
    }

    if (self.resourceHasReady) {
        self.playWhenAllReady = NO;
    } else {
        // resource not ready, try play when resource ready
        self.playWhenAllReady = YES;
        return;
    }
    
    __weak __typeof(self) weakSelf = self;
    LOTAnimationCompletionBlock completion = ^(BOOL animationFinished) {
        if (animationFinished) {
            weakSelf.loopIndex = 0;
            [weakSelf.delegate onNativeLottiePlayStateChanged:self extraDetail:@{
                @"playState"    : @(BDNativeLottieFinished),
                @"playStateExt" : @"Animation completion block.",
            }];
        } else {
            [weakSelf.delegate onNativeLottiePlayStateChanged:self extraDetail:@{
                @"playState"    : @(BDNativeLottieCanceled),
                @"playStateExt" : @"Animation completion block.",
            }];
        }
    };
    
    if (self.lottieView.isAnimationPlaying) {
        [self.lottieView stop];
    }
    
    [self bdNativeUpdateAnimationProperties];
    self.loopIndex = 0;

    if (self.startFrame && self.endFrame) {
        [self.lottieView playFromFrame:self.startFrame toFrame:self.endFrame withCompletion:completion];
    } else if (self.endFrame) {
        [self.lottieView playToFrame:self.endFrame withCompletion:completion];
    } else {
        [self.lottieView playWithCompletion:completion];
    }
}

#pragma mark - LOTAnimationDelegate

- (void)animationView:(LOTAnimationView *)animationView fetchResourceWithURL:(NSURL *)url completionHandler:(LOTResourceCompletionHandler)completionHandler
{
    if (!url) {
        NSError *error = [NSError errorWithDomain:@"BDNativeLottieView"
                                             code:BDNativeLottieErrorCodeInvalidData
                                         userInfo:@{
            NSLocalizedDescriptionKey: @"Empty URL.",
        }];
        !completionHandler ?: completionHandler(nil, error);
        return;
    }
    NSString *key = url.absoluteString;
    BDImageCacheType cacheType = BDImageCacheTypeMemory;
    if ([[BDImageCache sharedImageCache] containsImageForKey:key type:cacheType]) {
        UIImage *cachedImage = [[BDImageCache sharedImageCache] imageForKey:key withType:&cacheType];
        !completionHandler ?: completionHandler(cachedImage, nil);
    } else {
        [TTNetworkManager.shareInstance requestForBinaryWithURL:url.absoluteString ?: @""
                                                         params:nil
                                                         method:@"GET"
                                               needCommonParams:YES
                                                       callback:^(NSError *error, id obj) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                if ([obj isKindOfClass:[NSData class]]) {
                    BDImageCacheType type = BDImageCacheTypeMemory;
                    if (![[BDImageCache sharedImageCache] containsImageForKey:key type:type]) {
                        BDImage *image = [BDImage imageWithData:(NSData *)obj];
                        [[BDImageCache sharedImageCache] setImage:image
                                                        imageData:nil
                                                           forKey:key
                                                         withType:type];
                        !completionHandler ?: completionHandler(image, error);
                    } else {
                        UIImage *cachedImage = [[BDImageCache sharedImageCache] imageForKey:key withType:&type];
                        !completionHandler ?: completionHandler(cachedImage, error);
                    }
                } else {
                    // no network data
                    !completionHandler ?: completionHandler(nil, error);
                }
            });
        }];
    }
}

- (void)animationView:(LOTAnimationView *)animationView didLoadResourcesWithError:(NSError *)error
{
    if (!error) {
        NSTimeInterval cost = [[NSDate date] timeIntervalSinceDate:self.lastDateOfSourceUpdate];
        NSInteger costMilliSec = cost * 1000;
        [self.delegate onNativeLottieSourceLoaded:self extraDetail:@{
            @"sourceLoadedCost" : @(costMilliSec),
        }];
        if (self.autoPlay) {
            self.playWhenAllReady = YES;
        }
        self.resourceHasReady = YES;
        if (self.playWhenAllReady) {
            [self playIfReady];
        }
    }
}

- (void)animationViewDidStart:(LOTAnimationView *)animationView
{
    [self.delegate onNativeLottiePlayStateChanged:self extraDetail:@{
        @"playState"    : @(BDNativeLottiePlaying),
        @"playStateExt" : @"Animation start to play.",
    }];
}

- (void)animationViewDidPause:(LOTAnimationView *)animationView
{
    [self.delegate onNativeLottiePlayStateChanged:self extraDetail:@{
        @"playState"    : @(BDNativeLottiePaused),
        @"playStateExt" : @"User paused animation.",
    }];
}

- (void)animationViewDidStop:(LOTAnimationView *)animationView
{
    [self.delegate onNativeLottiePlayStateChanged:self extraDetail:@{
        @"playState"    : @(BDNativeLottieStopped),
        @"playStateExt" : @"User make animation stopped.",
    }];
}

- (void)animationView:(LOTAnimationView *)animationView isDisplayingFrame:(float)frame
{
    BOOL reversed = self.lottieView.animationSpeed < 0;
    NSNumber *currentFrame = [NSNumber numberWithInteger:reversed ? ceilf(frame) : floorf(frame)];
    BOOL subscribed = !!self.subscribedFrames[currentFrame];
    __block BOOL eventSent = YES;
    
    void (^reset)(void) = ^(void) {
        ++self.loopIndex;
        [self.subscribedFrames.allKeys enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            self.subscribedFrames[obj] = @NO;
        }];
    };
    
    [self.subscribedFrames.allKeys enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (self.subscribedFrames[obj].boolValue) {
            return;
        }
        if (reversed) {
            if (obj.integerValue >= currentFrame.integerValue) {
                self.subscribedFrames[obj] = @YES;
                eventSent = NO;
            }
        } else {
            if (obj.integerValue <= currentFrame.integerValue) {
                self.subscribedFrames[obj] = @YES;
                eventSent = NO;
            }
        }
    }];
    if (subscribed && !eventSent) {
        [self.delegate onNativeLottieFrameUpdated:self extraDetail:@{
            @"frameUpdate" : currentFrame,
        }];
    }
    
    if (reversed) {
        if (currentFrame.integerValue > self.lastFrame.integerValue) {
            reset();
        }
    } else {
        if (currentFrame.integerValue < self.lastFrame.integerValue) {
            reset();
        }
    }
    
    self.lastFrame = currentFrame;
}

#pragma mark - Helpers

- (void)sendErrorEventWithCode:(BDNativeLottieErrorCode)code resourceURL:(NSURL *)resourceURL message:(NSString *)message, ...
{
    if (message) {
        va_list args;
        va_start(args, message);
        message = [[NSString alloc] initWithFormat:message arguments:args];
        va_end(args);
    }
    
    [self reportErrorCode:code message:message resourceURL:resourceURL];
}

- (void)reportErrorCode:(BDNativeLottieErrorCode)code message:(NSString *)message resourceURL:(NSURL *)resourceURL
{
    [BDTrackerProtocol eventV3:@"bdnative_lottie_view_error"
                        params:@{
                            @"error_code": @(code),
                            @"resource_url": resourceURL.absoluteString ?: @"",
                            @"lottie_url": @"",
                            @"message": message ?: @"",
    }];
}

@end
