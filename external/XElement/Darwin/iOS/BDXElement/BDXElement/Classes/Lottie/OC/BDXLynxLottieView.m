//
//  BDXLynxLottieView.m
//  BDXElement
//
//  Created by li keliang on 2020/3/17.
//

#import "BDXLynxLottieView.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxLayoutStyle.h>
#import <Lynx/LynxView.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import <Lynx/LynxRootUI.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#if OCLottieEnable
#import <lottie-ios/Lottie/LOTAsset.h>
#import <lottie-ios/Lottie/LOTCompositionContainer.h>
#import <lottie-ios/Lottie/LOTAnimationDelegate.h>
#endif
#import "BDXElementResourceManager.h"
#import "BDXElementAdapter.h"
#import <BDWebImage/BDWebImage.h>
#import <Lynx/LynxLog.h>
#import <Lynx/LynxService.h>
#import <Lynx/LynxServiceTrackEventProtocol.h>

static NSString * const kBDXLynxLottieCurrentFrameKeyPath = @"compContainer.currentFrame";
static NSString * const kBDXLynxLottieObjectfitCover = @"cover";
static NSString * const kBDXLynxLottieObjectfitContain = @"contain";
static NSString * const kBDXLynxLottieObjectfitCenter = @"center";

#if OCLottieEnable
@interface LOTAnimationView (BDXLynxLottieView)

- (void)_initializeAnimationContainer;
- (void)_setupWithSceneModel:(LOTComposition *)model;

@end
#endif

@interface BDXLynxLottieView() <LOTAnimationDelegate>

@property (nonatomic, assign) BOOL loop;
@property (nonatomic, assign) BOOL autoReverse;
@property (nonatomic, assign) BOOL autoplay;
@property (nonatomic, assign) float speed;
@property (nonatomic, assign) NSInteger loopCount;
@property (nonatomic, assign) BOOL layoutReady;
@property (nonatomic, assign) BOOL resourceReady;
@property (nonatomic, assign) BOOL playWhenAllReady;
@property (nonatomic, assign) BOOL onlyLocal;
@property (nonatomic, copy) NSString *currentSource;
@property (nonatomic, copy) NSString *srcFormat;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *srcPolyfill;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *currentSrcPolyfill;
@property (nonatomic, strong) NSNumber *startFrame;
@property (nonatomic, strong) NSNumber *endFrame;
@property (nonatomic, assign) NSUInteger loopIndex;
@property (nonatomic, strong) NSNumber *lastFrame;
@property (nonatomic, copy) NSString *animationID;
@property (nonatomic, strong) LOTCompositionContainer *compContainer;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *subscribedFrames;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDate *> *reportContext;

@end

@implementation BDXLynxLottieView

- (instancetype)init
{
    self = [super init];
    if (self) {
        _loop = NO;
        _autoReverse = NO;
        _autoplay = YES;
        _loopCount = 0;
        _speed = 1.f;
        
        _subscribedFrames = [NSMutableDictionary dictionary];
        _reportContext = [NSMutableDictionary dictionary];

        [self refreshAnimationID];
    }
    return self;
}

- (UIView *)createView
{
#if OCLottieEnable
    LOTAnimationView *view = [[LOTAnimationView alloc] init];
    view.animationDelegate = self;
#else
    BridgeAnimationView *view = [[BridgeAnimationView alloc] init];
#endif
    return view;
}

- (void)layoutDidFinished
{
    [super layoutDidFinished];
    self.layoutReady = YES;
}

#pragma mark - LynxPropsProcessor & LynxComponentRegistry

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("lottie-view")
#else
LYNX_REGISTER_UI("lottie-view")
#endif

LYNX_PROP_SETTER("src", src, NSString *)
{
    if (![value isKindOfClass:NSString.class] || [value isEqualToString:self.currentSource]) {
        return;
    }

    [self updateSource:value formatWithPolyfill:NO];
}

LYNX_PROP_SETTER("src-format", srcFormat, NSString *)
{
    if (![value isKindOfClass:NSString.class] || [value isEqualToString:self.srcFormat]) {
        return;
    }
    
    self.srcFormat = value;
    [self updateSourceIfNeeded];
}

LYNX_PROP_SETTER("src-polyfill", srcPolyfill, NSDictionary *)
{
    if (![value isKindOfClass:NSDictionary.class] || [value isEqualToDictionary:self.srcPolyfill]) {
        return;
    }
    
    self.srcPolyfill = value;
    [self updateSourceIfNeeded];
}

LYNX_PROP_SETTER("json", json, NSString *)
{
    if (![value isKindOfClass:NSString.class] || value.length == 0) {
        return;
    }

#if OCLottieEnable
    NSError *error;
    NSDictionary *animationJSON = [value btd_jsonDictionary:&error];
    if (error || !animationJSON) {
        return;
    }
    [self.view setAnimationFromJSON:animationJSON];
#else
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    if (data.length == 0) {
        return;
    }
    [(BridgeAnimationView *)self.view setAnimationFromJSONData:data];
    
    [self sendEventNamed:@"ready" extraDetail:nil];
    self.resourceReady = YES;
#endif
}

LYNX_PROP_SETTER("loop", loop, BOOL)
{
#if OCLottieEnable
    self.view.loopAnimation = value;
    self.loop = value;
#else
    [(BridgeAnimationView *)self.view loopAnimation:value];
#endif
}

LYNX_PROP_SETTER("start-frame", startFrame, NSNumber *)
{
    if (![value isKindOfClass:NSNumber.class]) {
        return;
    }
    
    self.startFrame = value;
}

LYNX_PROP_SETTER("end-frame", endFrame, NSNumber *)
{
    if (![value isKindOfClass:NSNumber.class]) {
        return;
    }
    
    self.endFrame = value;
}

LYNX_PROP_SETTER("auto-reverse", autoReverse, BOOL)
{
    self.view.autoReverseAnimation = value;
    self.autoReverse = value;
}

LYNX_PROP_SETTER("progress", progress, NSNumber *)
{
    if (![value isKindOfClass:NSNumber.class]) {
        return;
    }
    
    self.view.animationProgress = value.floatValue;
}

LYNX_PROP_SETTER("loop-count", repeatCount, NSNumber *)
{
#if OCLottieEnable
    if (![value isKindOfClass:NSNumber.class]) {
        return;
    }
    
    self.view.loopAnimation = true;
    self.loop = true;
    self.view.repeatCount = value.floatValue;
    self.loopCount = value.integerValue;
#endif
}

LYNX_PROP_SETTER("objectfit", objectfit, NSString *)
{
    if (![value isKindOfClass:NSString.class]) {
        return;
    }
    
    if ([kBDXLynxLottieObjectfitCover isEqualToString:value]) {
        self.view.contentMode = UIViewContentModeScaleAspectFill;
    } else if ([kBDXLynxLottieObjectfitContain isEqualToString:value]) {
        self.view.contentMode = UIViewContentModeScaleAspectFit;
    } else if ([kBDXLynxLottieObjectfitCenter isEqualToString:value]) {
        self.view.contentMode = UIViewContentModeCenter;
    }
}

LYNX_PROP_SETTER("autoplay", autoplay, BOOL)
{
    self.autoplay = value;
    if (value) {
        [self playIfReady];
    }
}

LYNX_PROP_SETTER("speed", speed, NSNumber *)
{
    if (![value isKindOfClass:NSNumber.class]) {
        return;
    }
    
    self.speed = value.floatValue;
    self.view.animationSpeed = value.floatValue;
}

LYNX_PROP_SETTER("only-local", onlyLocal, BOOL)
{
    self.onlyLocal = value;
}

LYNX_UI_METHOD(play) {
    self.view.animationProgress = 0;
    [self playIfReady];
    !callback ?: callback(kUIMethodSuccess, nil);
}

LYNX_UI_METHOD(resume) {
    [self playIfReady];
    !callback ?: callback(kUIMethodSuccess, nil);
}

LYNX_UI_METHOD(stop) {
    [self.view stop];
    !callback ?: callback(kUIMethodSuccess, nil);
}

LYNX_UI_METHOD(pause) {
    [self.view pause];
    !callback ?: callback(kUIMethodSuccess, nil);
}

LYNX_UI_METHOD(getDuration) {
    !callback ?: callback(kUIMethodSuccess, @{ @"data": @(self.view.animationDuration * 1000) });
}

LYNX_UI_METHOD(isAnimating) {
    !callback ?: callback(kUIMethodSuccess, @{ @"data": @(self.view.isAnimationPlaying) });
}

LYNX_UI_METHOD(subscribeUpdateEvent) {
    NSNumber *frame = params[@"frame"];
    if ([frame isKindOfClass:NSNumber.class]) {
        if (!self.subscribedFrames[frame]) {
            self.subscribedFrames[frame] = @NO;
        }
        !callback ?: callback(kUIMethodSuccess, nil);
    } else {
        !callback ?: callback(kUIMethodParamInvalid, nil);
    }
}

LYNX_UI_METHOD(unsubscribeUpdateEvent) {
    NSNumber *frame = params[@"frame"];
    if ([frame isKindOfClass:NSNumber.class]) {
        self.subscribedFrames[frame] = nil;
        !callback ?: callback(kUIMethodSuccess, nil);
    } else {
        !callback ?: callback(kUIMethodParamInvalid, nil);
    }
}

LYNX_UI_METHOD(seek) {
    NSNumber *frame = params[@"frame"];
    if ([frame isKindOfClass:NSNumber.class]) {
        [self.view setProgressWithFrame:frame];
        !callback ?: callback(kUIMethodSuccess, nil);
    } else {
        !callback ?: callback(kUIMethodParamInvalid, nil);
    }
}

LYNX_UI_METHOD(getCurrentFrame) {
    !callback ?: callback(kUIMethodSuccess, self.lastFrame);
}

#pragma mark - Accessors

- (void)setLayoutReady:(BOOL)layoutReady
{
    _layoutReady = layoutReady;
    if (self.playWhenAllReady) {
        [self playIfReady];
    }
}

- (void)setResourceReady:(BOOL)resourceReady
{
    _resourceReady = resourceReady;
    if (self.playWhenAllReady) {
        [self playIfReady];
    }
}

- (LOTCompositionContainer *)compContainer
{
    return [self.view valueForKeyPath:@"compContainer"];
}

#pragma mark - Action

- (void)playIfReady
{
    if (self.layoutReady && self.resourceReady) {
        self.playWhenAllReady = NO;
    } else {
        self.playWhenAllReady = YES;
        return;
    }
    
    __weak __typeof(self) weakSelf = self;
    LOTAnimationCompletionBlock completion = ^(BOOL animationFinished) {
        if (animationFinished) {
            weakSelf.loopIndex = 0;
            [weakSelf sendEventNamed:@"completion" extraDetail:nil];
        } else {
            [weakSelf sendEventNamed:@"cancel" extraDetail:nil];
        }
    };
    
    if (self.view.isAnimationPlaying) {
        [self.view stop];
    }
    
    [self updateAnimationProperties];
    self.loopIndex = 0;
    
#if OCLottieEnable
    if (self.startFrame && self.endFrame) {
        [self.view playFromFrame:self.startFrame toFrame:self.endFrame withCompletion:completion];
    } else if (self.endFrame) {
        [self.view playToFrame:self.endFrame withCompletion:completion];
    } else {
        [self.view playWithCompletion:completion];
    }
#else
    [(BridgeAnimationView *)self.view play:completion];
#endif
}

#pragma mark - LOTAnimationDelegate

- (void)animationView:(LOTAnimationView *)animationView fetchResourceWithURL:(NSURL *)url completionHandler:(LOTResourceCompletionHandler)completionHandler
{
    if (!url) {
        NSError *error = [NSError errorWithDomain:@"BDXElementErrorDomain" code:BDXLottieErrorCodeInvalidData userInfo:@{
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
        NSString *image_url = [NSString stringWithFormat:@"lottie: %@", key];
                NSDictionary* reportData = @{
                  @"image_url" : image_url ?: @"",
                  @"memoryCost" : @(cachedImage.size.width * cachedImage.size.height * 4),
                };
                [LynxService(LynxServiceTrackEventProtocol) kProbe_SpecialEventName:@"image_request" format:@"image info: %@" data:reportData];

    } else {
        NSMutableDictionary* context = [NSMutableDictionary dictionary];
        context[BDXElementContextContainerKey] = self.context.rootUI.lynxView;
        context[BDXElementContextShouldFallbackBlockKey] = [self shouldFallbackBlock];
        __weak __typeof(self) weakSelf = self;
        url = [weakSelf updateURLQuery:url];
        [BDXElementResourceManager.sharedInstance resourceDataWithURL:url
                                                              baseURL:nil
                                                              context:[context copy]
                                                    completionHandler:^(NSURL *url, NSData *data, NSError *error) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                BDImage *image;
                if (![[BDImageCache sharedImageCache] containsImageForKey:key type:cacheType]) {
                    image = [BDImage imageWithData:data];
                    [[BDImageCache sharedImageCache] setImage:image
                                                    imageData:nil
                                                       forKey:key
                                                     withType:cacheType];
                } else {
                    image = (BDImage *)[[BDImageCache sharedImageCache] imageForKey:key withType:(BDImageCacheType *)&cacheType];
                }
                
                !completionHandler ?: completionHandler(image, error);
                NSString *image_url = [NSString stringWithFormat:@"lottie: %@", key];
                        NSDictionary* reportData = @{
                          @"image_url" : image_url ?: @"",
                          @"memoryCost" : @(image.size.width * image.size.height * 4),
                        };
                        [LynxService(LynxServiceTrackEventProtocol) kProbe_SpecialEventName:@"image_request" format:@"image info: %@" data:reportData];

            });
        }];
    }
}

- (void)animationView:(LOTAnimationView *)animationView didLoadResourcesWithError:(NSError *)error
{
    if (error) {
        NSString *message = error ? error.localizedDescription : @"Failed to load resources.";
        NSURL *url = error.userInfo[LOTResourceURLKey];
        BDXLottieErrorCode errorCode = error.code == BDXLottieErrorCodeLocalResourcesNotFound ? error.code : BDXLottieErrorCodeInvalidData;
        [self sendErrorEventWithCode:errorCode resourceURL:url message:message];
    } else {
        if (self.autoplay) {
            self.playWhenAllReady = YES;
        }
        self.resourceReady = YES;
        
        [self sendEventNamed:@"ready" extraDetail:nil];
        
        if (self.currentSource.length > 0) {
            NSDate *startDate = self.reportContext[self.currentSource];
            if ([startDate isKindOfClass:NSDate.class]) {
                [self reportCost:[[NSDate date] timeIntervalSinceDate:startDate] resourceURL:[NSURL URLWithString:self.currentSource]];
            }
            self.reportContext[self.currentSource] = nil;
        }
    }
}

- (void)animationViewDidStart:(LOTAnimationView *)animationView
{
    [self sendEventNamed:@"start" extraDetail:nil];
}

- (void)animationView:(LOTAnimationView *)animationView isDisplayingFrame:(float)frame
{
    BOOL reversed = self.view.animationSpeed < 0;
    __block NSNumber *currentFrame = [NSNumber numberWithInteger:reversed ? ceilf(frame) : floorf(frame)];
    __block BOOL subscribed = !!self.subscribedFrames[currentFrame];
    __block BOOL eventSent = YES;

    void (^reset)(void) = ^(void) {
        ++self.loopIndex;
        [self sendEventNamed:@"repeat" extraDetail:nil];
        [self.subscribedFrames.allKeys enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL *stop) {
            self.subscribedFrames[obj] = @NO;
        }];
    };
    
    [self.subscribedFrames.allKeys enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL *stop) {
        if (self.subscribedFrames[obj].boolValue) {
            return;
        }
        if (reversed) {
            if (obj.integerValue >= currentFrame.integerValue) {
                self.subscribedFrames[obj] = @YES;
                currentFrame = [NSNumber numberWithInteger:obj.integerValue];
                subscribed = YES;
                eventSent = NO;
            }
        } else {
            if (obj.integerValue <= currentFrame.integerValue) {
                self.subscribedFrames[obj] = @YES;
                currentFrame = [NSNumber numberWithInteger:obj.integerValue];
                subscribed = YES;
                eventSent = NO;
            }
        }
    }];
    if (subscribed && !eventSent) {
        [self sendEventNamed:@"update" extraDetail:@{
            @"current": currentFrame,
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

- (void)updateSourceIfNeeded
{
    if ([self.srcFormat isEqualToString:self.currentSource]) {
        [self updateCompositionIfNeeded:self.view.sceneModel];
    } else {
        [self updateSource:self.srcFormat formatWithPolyfill:YES];
    }
}

- (void)updateCompositionIfNeeded:(LOTComposition *)composition
{
    NSMutableDictionary<NSString *, LOTAsset *> *assetMap = [composition valueForKeyPath:@"assetGroup.assetMap"];
    if (assetMap.count == 0 ||
        self.srcPolyfill.count == 0 ||
        [self.srcPolyfill isEqualToDictionary:self.currentSrcPolyfill]) {
        return;
    }
    self.currentSrcPolyfill = self.srcPolyfill;
    
    [self.srcPolyfill enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        LOTAsset *asset = assetMap[key];
        if (asset && obj) {
            [asset setValue:obj forKey:@"imageName"];
        }
    }];
    [self.view _setupWithSceneModel:composition];
}

- (void)updateSource:(NSString *)source formatWithPolyfill:(BOOL)formatWithPolyfill
{
    if (![source isKindOfClass:NSString.class] || source.length == 0 || [source isEqualToString:self.currentSource]) {
        return;
    }
    self.currentSource = source;
        
    NSURL *lynxViewURL = nil;
    if ([self.context.rootView isKindOfClass:LynxView.class]) {
        LynxView *lynxView = (LynxView *)self.context.rootView;
        if (lynxView.url) {
            lynxViewURL = [NSURL URLWithString:lynxView.url];
        }
    }
    
    NSURL *url = [NSURL URLWithString:source ?: @"" relativeToURL:lynxViewURL];
    if (!url) {
        [self sendErrorEventWithCode:BDXLottieErrorCodeInvalidData resourceURL:url message:@"Malformed URL: %@", url];
        return;
    }
    url = [self updateURLQuery:url];

    NSURL *baseURL = nil;
    if ([self.context.rootView isKindOfClass:[LynxView class]]) {
        baseURL = [NSURL URLWithString:[(LynxView *)self.context.rootView url]];
    }
    
    self.reportContext[source] = [NSDate date];

    __weak __typeof(self) weakSelf = self;
    NSMutableDictionary *context = [NSMutableDictionary dictionary];
    context[BDXElementContextContainerKey] = self.context.rootUI.lynxView;
    context[BDXElementContextShouldFallbackBlockKey] = [self shouldFallbackBlock];
    [[BDXElementResourceManager sharedInstance] resourceDataWithURL:url baseURL:baseURL context:[context copy] completionHandler:^(NSURL *url, NSData *animationData, NSError *error) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *newError = nil;
            NSData *newAnimationData = animationData;
            if (error || !newAnimationData) {
                BDXLottieErrorCode errorCode = error.code == BDXLottieErrorCodeLocalResourcesNotFound ? error.code : BDXLottieErrorCodeInvalidData;
                [weakSelf sendErrorEventWithCode:errorCode resourceURL:url message:@"Malformed animation data: %@", error.localizedDescription];
                return;
            }
            
            NSDictionary *animationJSON = [NSJSONSerialization JSONObjectWithData:newAnimationData options:0 error:&newError];
            if (newError || !animationJSON) {
                [weakSelf sendErrorEventWithCode:BDXLottieErrorCodeInvalidData resourceURL:url message:@"Malformed animation json: %@.", newError.localizedDescription];
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
#if OCLottieEnable
                if ([weakSelf.view respondsToSelector:@selector(_initializeAnimationContainer)] && [weakSelf.view respondsToSelector:@selector(_setupWithSceneModel:)]) {
                    LOTComposition *composition = [LOTComposition animationFromJSON:animationJSON];
                    if (formatWithPolyfill) {
                        [weakSelf updateCompositionIfNeeded:composition];
                    }
                    if (url.isFileURL) {
                        composition.rootDirectory = url.path.stringByDeletingLastPathComponent;
                        composition.ignoreBundleResource = NO;
                    } else if (url) {
                        composition.baseURL = url;
                        composition.ignoreBundleResource = YES;
                    }
                    [weakSelf.view _initializeAnimationContainer];
                    [weakSelf.view _setupWithSceneModel:composition];
                } else {
                    [weakSelf.view setAnimationFromJSON:animationJSON];
#else
                    if (newAnimationData.length > 0) {
                        [(BridgeAnimationView *)weakSelf.view setAnimationFromJSONData:newAnimationData];
                    }
#endif
                }
                
#if !OCLottieEnable
                [weakSelf sendEventNamed:@"ready" extraDetail:nil];
                weakSelf.resourceReady = YES;
#endif
            });
        });
    }];
}

- (void)sendEventNamed:(NSString *)eventName extraDetail:(NSDictionary *)extraDetail
{
    if (eventName.length == 0) {
        return;
    }
    
    NSMutableDictionary *detail = [NSMutableDictionary dictionary];
    detail[@"animationID"] = self.animationID;
    detail[@"current"] = @(self.compContainer.currentFrame.integerValue);
    detail[@"total"] = @(self.view.sceneModel.endFrame.unsignedIntValue - self.view.sceneModel.startFrame.unsignedIntValue);
    detail[@"loopIndex"] = @(self.loopIndex);
    if (extraDetail) {
        [detail addEntriesFromDictionary:extraDetail];
    }
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:eventName targetSign:[self sign] detail:[detail copy]];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)sendErrorEventWithCode:(BDXLottieErrorCode)code resourceURL:(NSURL *)resourceURL message:(NSString *)message, ...
{
    if (message) {
        va_list args;
        va_start(args, message);
        message = [[NSString alloc] initWithFormat:message arguments:args];
        va_end(args);
    }

    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"error" targetSign:[self sign] detail:@{
        @"code": @(code),
        @"message": message ?: @"Unknown error."
    }];
    [self.context.eventEmitter sendCustomEvent:event];
    
    [self reportErrorCode:code message:message resourceURL:resourceURL];
}

- (void)updateAnimationProperties
{
#if OCLottieEnable
    LOTAnimationView *animationView = self.view;
#else
    BridgeAnimationView *animationView = self.view;
#endif
    
    if (!animationView) {
        return;
    }
    
    animationView.loopAnimation = self.loop;
    animationView.autoReverseAnimation = self.autoReverse;
    animationView.animationSpeed = self.speed;
    
#if OCLottieEnable
    animationView.repeatCount = self.loopCount;
#endif
}

- (void)refreshAnimationID
{
    self.animationID = [[NSUUID UUID] UUIDString];
}

- (BDXElementShouldFallbackBlock)shouldFallbackBlock
{
    __weak __typeof(self) weakSelf = self;
    return ^BOOL(NSError *error) {
        // Prevent from falling back to fetch resources via NSURLSession if necessary.
        return !(weakSelf.onlyLocal && error.code == BDXLottieErrorCodeLocalResourcesNotFound);
    };
}

- (NSURL *)updateURLQuery:(NSURL *)url
{
    if (!self.onlyLocal) {
        return url;
    }
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
    NSString *query = components.percentEncodedQuery;
    NSString *onlyLocalQuery = @"onlyLocal=1";
    query = (query && ![query isEqualToString:@""]) ? [query stringByAppendingString:[NSString stringWithFormat:@"&%@", onlyLocalQuery]] : onlyLocalQuery;
    components.query = query;
    return components.URL;
}

- (void)reportCost:(NSTimeInterval)cost resourceURL:(NSURL *)resourceURL
{
    if (self.currentSource.length == 0) {
        return;
    }
    
    id<BDXElementMonitorDelegate> delegate = BDXElementAdapter.sharedInstance.monitorDelegate;
    if ([delegate respondsToSelector:@selector(reportWithEventName:lynxView:metric:category:extra:)]) {
        [delegate reportWithEventName:@"lottie_fetch_total_cost"
                             lynxView:self.context.rootUI.lynxView
                               metric:@{
                                   @"cost": @(cost)
                               }
                             category:@{
                                 @"resource_url": resourceURL.absoluteString ?: @"",
                                 @"lottie_url": self.currentSource ?: @"",
                             }
                                extra:nil];
    }
}

- (void)reportErrorCode:(BDXLottieErrorCode)code message:(NSString *)message resourceURL:(NSURL *)resourceURL
{
    if (self.currentSource.length == 0) {
        return;
    }
    LLogError(@"BDXLynxLottieView.mm reportErrorCode: code: %@, message: %@, resourceURL: %@, lottie_url:%@", @(code), resourceURL.absoluteString, self.currentSource, message);

    id<BDXElementMonitorDelegate> delegate = BDXElementAdapter.sharedInstance.monitorDelegate;
    if ([delegate respondsToSelector:@selector(reportWithEventName:lynxView:metric:category:extra:)]) {
        [delegate reportWithEventName:@"lottie_fetch_error"
                             lynxView:self.context.rootUI.lynxView
                               metric:nil
                             category:@{
                                 @"code": @(code),
                                 @"resource_url": resourceURL.absoluteString ?: @"",
                                 @"lottie_url": self.currentSource ?: @"",
                                 @"message": message ?: @"",
                             }
                                extra:nil];
    }
}

@end
