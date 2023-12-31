//
//  BDXLynxLottieView_Deprecated.m
//  BDXElement
//
//  Created by li keliang on 2020/3/17.
//

#import "BDXLynxLottieView_Deprecated.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxLayoutStyle.h>
#import <Lynx/LynxView.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#if OCLottieEnable
#import <lottie-ios/Lottie/LOTAsset.h>
#import <lottie-ios/Lottie/LOTCompositionContainer.h>
#import <lottie-ios/Lottie/LOTAnimationDelegate.h>
#endif
#import "BDXElementResourceManager.h"
#import <Lynx/LynxRootUI.h>

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

@interface BDXLynxLottieView_Deprecated() <LOTAnimationDelegate>

@property (nonatomic, assign) BOOL autoPlay;
@property (nonatomic, assign) BOOL layoutFinished;
@property (nonatomic, assign) BOOL playWhenFinishingLayout;
@property (nonatomic, copy) NSString *srcFormat;
@property (nonatomic, copy) NSString *srcPolyfill;
@property (nonatomic, strong) NSNumber *startFrame;
@property (nonatomic, strong) NSNumber *endFrame;
@property (nonatomic, strong) NSNumber *repeatCount;
@property (nonatomic, assign) NSUInteger loopCount;
@property (nonatomic, assign) NSUInteger lastFrame;
@property (nonatomic, copy) NSString *animationID;
@property (nonatomic, strong) LOTCompositionContainer *compContainer;
@property (nonatomic, assign) BOOL listenAnimationUpdate;

@end

@implementation BDXLynxLottieView_Deprecated

- (instancetype)init
{
    self = [super init];
    if (self) {
        _autoPlay = YES;
        _repeatCount = @(-1);
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
    self.layoutFinished = true;
    [self refreshAnimationID];
    if (self.autoPlay && self.playWhenFinishingLayout) {
        [self play];
    }
}

#pragma mark - LynxPropsProcessor & LynxComponentRegistry

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-lottie")
#else
LYNX_REGISTER_UI("x-lottie")
#endif

LYNX_PROP_SETTER("src", src, NSString *)
{
    if (![value isKindOfClass:NSString.class]) {
        return;
    }
    
    [self updateSource:value withPolyfill:nil hasPlaceholder:NO];
}

LYNX_PROP_SETTER("src-format", srcFormat, NSString *)
{
    if (![value isKindOfClass:NSString.class]) {
        return;
    }
    
    self.srcFormat = value;
    [self updateSourceWithPolyfillIfNeeded];
}

LYNX_PROP_SETTER("src-polyfill", srcPolyfill, NSString *)
{
    if (![value isKindOfClass:NSString.class]) {
        return;
    }
    
    self.srcPolyfill = value;
    [self updateSourceWithPolyfillIfNeeded];
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
    
    self.playWhenFinishingLayout = YES;
    [self sendEventNamed:@"ready" extraDetail:nil];
#endif
}

LYNX_PROP_SETTER("loop", loop, BOOL)
{
#if OCLottieEnable
    self.view.loopAnimation = value;
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
    
    self.view.repeatCount = value.floatValue;
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
    self.autoPlay = value;
    if (value) {
        [self play];
    }
}

LYNX_PROP_SETTER("speed", speed, NSNumber *)
{
    if (![value isKindOfClass:NSNumber.class]) {
        return;
    }
    
    self.view.animationSpeed = value.floatValue;
}

LYNX_UI_METHOD(play) {
    [self play];
    callback(kUIMethodSuccess, nil);
}

LYNX_UI_METHOD(stop) {
    [self.view stop];
    self.loopCount = 0;
    callback(kUIMethodSuccess, nil);
}

LYNX_UI_METHOD(pause) {
    [self.view pause];
    callback(kUIMethodSuccess, nil);
}

LYNX_UI_METHOD(getDuration) {
    callback(kUIMethodSuccess, @{ @"data": @(self.view.animationDuration * 1000) });
}

LYNX_UI_METHOD(isAnimating) {
    callback(kUIMethodSuccess, @{ @"data": @(self.view.isAnimationPlaying) });
}

LYNX_UI_METHOD(listenAnimationUpdate) {
    NSNumber *listen = params[@"listen"];
    if ([listen isKindOfClass:NSNumber.class]) {
        self.listenAnimationUpdate = [listen boolValue];
    }
}

LYNX_UI_METHOD(seek) {
    NSNumber *frame = params[@"frame"];
    if ([frame isKindOfClass:NSNumber.class]) {
        [self.view setProgressWithFrame:frame];
    }
}

#pragma mark - Accessors

- (LOTCompositionContainer *)compContainer
{
    return [self.view valueForKeyPath:@"compContainer"];
}

#pragma mark - Action

- (void)play
{
    __weak __typeof(self) weakSelf = self;
    LOTAnimationCompletionBlock completion = ^(BOOL animationFinished) {
        if (animationFinished) {
            [weakSelf sendEventNamed:@"completion" extraDetail:nil];
        } else {
            [weakSelf sendEventNamed:@"cancel" extraDetail:nil];
        }
    };
    
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
        NSError *error = [NSError errorWithDomain:@"BDXElementErrorDomain" code:-1 userInfo:@{
            NSLocalizedDescriptionKey: @"Empty URL.",
        }];
        !completionHandler ?: completionHandler(nil, error);
        return;
    }
    NSMutableDictionary* context = [NSMutableDictionary dictionary];
    context[BDXElementContextContainerKey] = self.context.rootUI.lynxView;
    [BDXElementResourceManager.sharedInstance resourceDataWithURL:[self updateURLQuery:url resolvingAgainstBaseURL:YES]
                                                          baseURL:nil
                                                          context:[context copy]
                                                completionHandler:^(NSURL *url, NSData *data, NSError *error) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *image = [UIImage imageWithData:data];
            !completionHandler ?: completionHandler(image, error);
        });
    }];
}

- (void)animationView:(LOTAnimationView *)animationView didLoadResourcesWithError:(NSError *)error
{
    if (error) {
        NSString *message = error ? error.localizedDescription : @"Failed to load resources.";
        [self sendErrorEventWithCode:-1 message:message];
    } else {
        [self sendEventNamed:@"ready" extraDetail:nil];
        
        if (self.autoPlay && self.layoutFinished) {
            [self play];
        } else {
            self.playWhenFinishingLayout = YES;
        }
    }
}

- (void)animationViewDidStart:(LOTAnimationView *)animationView
{
    [self sendEventNamed:@"start" extraDetail:nil];
}

- (void)animationView:(LOTAnimationView *)animationView isDisplayingFrame:(float)frame
{
    NSUInteger currentFrame = (NSUInteger)frame;
    if (self.view.animationSpeed > 0) {
        if (currentFrame < self.lastFrame) {
            self.loopCount = 0;
        }
    } else {
        if (currentFrame > self.lastFrame) {
            self.loopCount = 0;
        }
    }
    self.lastFrame = currentFrame;
    
    //    [self sendEventNamed:@"update" extraDetail:nil];
}

#pragma mark - Helpers

- (void)updateSourceWithPolyfillIfNeeded
{
    if (self.srcFormat.length > 0 && self.srcPolyfill.length > 0) {
        [self updateSource:self.srcFormat withPolyfill:self.srcPolyfill hasPlaceholder:YES];
    }
}

- (void)updateSource:(NSString *)source withPolyfill:(NSString *)polyfill hasPlaceholder:(BOOL)hasPlaceholder
{
    if (![source isKindOfClass:NSString.class] || source.length == 0) {
        return;
    }
    
    NSURL *lynxViewURL = nil;
    if ([self.context.rootView isKindOfClass:LynxView.class]) {
        LynxView *lynxView = (LynxView *)self.context.rootView;
        if (lynxView.url) {
            lynxViewURL = [NSURL URLWithString:lynxView.url];
        }
    }
    
    lynxViewURL = [self updateURLQuery:lynxViewURL resolvingAgainstBaseURL:NO];
    NSURL *url = [NSURL URLWithString:source ?: @"" relativeToURL:lynxViewURL];
    if (!url) {
        [self sendErrorEventWithCode:-1 message:@"Malformed URL: %@", url];
        return;
    }
    
    NSURL *baseURL = nil;
    if ([self.context.rootView isKindOfClass:[LynxView class]]) {
        baseURL = [NSURL URLWithString:[(LynxView *)self.context.rootView url]];
    }
    
    __weak __typeof(self)weakSelf = self;
    NSMutableDictionary* context = [NSMutableDictionary dictionary];
    context[BDXElementContextContainerKey] = self.context.rootUI.lynxView;
    [[BDXElementResourceManager sharedInstance] resourceDataWithURL:url baseURL:baseURL context:[context copy] completionHandler:^(NSURL *url, NSData *animationData, NSError *error) {
        if (!animationData) {
            [weakSelf sendErrorEventWithCode:-1 message:@"Malformed animation data: %@", error.localizedDescription];
            return;
        }
        
        if (hasPlaceholder) {
            NSString *jsonFormat = [[NSString alloc] initWithData:animationData encoding:NSUTF8StringEncoding];
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"%s" options:kNilOptions error:&error];
            if (!jsonFormat || error) {
                [weakSelf sendErrorEventWithCode:-1 message:@"Malformed animation json format string: %@", error.localizedDescription];
                return;
            }
            NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:jsonFormat options:kNilOptions range:NSMakeRange(0, jsonFormat.length)];
            NSArray<NSString *> *polyfills = [weakSelf.srcPolyfill componentsSeparatedByString:@","];
            if (polyfills.count != matches.count) {
                [weakSelf sendErrorEventWithCode:-1 message:@"The polyfill items count(%ld) should be equal to the placeholder count(%ld).", polyfills.count, matches.count];
                return;
            }
            NSMutableString *jsonString = [jsonFormat mutableCopy];
            [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult *match, NSUInteger idx, BOOL *stop) {
                [jsonString replaceCharactersInRange:match.range withString:polyfills[idx]];
            }];
            animationData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
            if (!animationData) {
                [weakSelf sendErrorEventWithCode:-1 message:@"Malformed animation json string."];
                return;
            }
        }
        
        NSDictionary *animationJSON = [NSJSONSerialization JSONObjectWithData:animationData options:0 error:&error];
        if (error || !animationJSON) {
            [weakSelf sendErrorEventWithCode:-1 message:@"Malformed animation json: %@.", error.localizedDescription];
            return;
        }
        
        if ([weakSelf.view respondsToSelector:@selector(_initializeAnimationContainer)] && [weakSelf.view respondsToSelector:@selector(_setupWithSceneModel:)]) {
#if OCLottieEnable
            LOTComposition *composition = [LOTComposition animationFromJSON:animationJSON];
            if (url.isFileURL) {
                composition.rootDirectory = url.path.stringByDeletingLastPathComponent;
            } else if (url) {
                composition.baseURL = url;
            }
            [weakSelf.view _initializeAnimationContainer];
            [weakSelf.view _setupWithSceneModel:composition];
#endif
        } else {
#if OCLottieEnable
            [weakSelf.view setAnimationFromJSON:animationJSON];
#else
            if (animationData.length > 0) {
                [(BridgeAnimationView *)weakSelf.view setAnimationFromJSONData:animationData];
            }
#endif
        }
        
#if !OCLottieEnable
        [weakSelf sendEventNamed:@"ready" extraDetail:nil];
        
        if (weakSelf.autoPlay && weakSelf.layoutFinished) {
            [weakSelf play];
        } else {
            weakSelf.playWhenFinishingLayout = YES;
        }
#endif
    }];
}

- (void)sendEventNamed:(NSString *)eventName extraDetail:(NSDictionary *)extraDetail
{
    if (eventName.length == 0) {
        return;
    }
    
    NSMutableDictionary *detail = [NSMutableDictionary dictionary];
    detail[@"animationID"] = self.animationID;
    detail[@"current"] = self.compContainer.currentFrame ?: @(0);
    detail[@"total"] = @(self.view.sceneModel.endFrame.unsignedIntValue - self.view.sceneModel.startFrame.unsignedIntValue);
    detail[@"loopCount"] = @(self.loopCount);
    if (extraDetail) {
        [detail addEntriesFromDictionary:extraDetail];
    }
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:eventName targetSign:[self sign] detail:[detail copy]];
    [self.context.eventEmitter sendCustomEvent:event];
    
    NSLog(@"hulizhen --- event: %@, detail: %@", eventName, detail);
}

- (void)sendErrorEventWithCode:(NSInteger)code message:(NSString *)message, ...
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
    
}

- (void)refreshAnimationID
{
    self.animationID = [[NSUUID UUID] UUIDString];
}

- (NSURL *)updateURLQuery:(NSURL *)url resolvingAgainstBaseURL:(BOOL)resolvingAgainstBaseURL
{
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
    components.queryItems = ({
        NSMutableArray<NSURLQueryItem *> *queryItems = [components.queryItems mutableCopy];
        [queryItems addObject:[[NSURLQueryItem alloc] initWithName:@"dynamic" value:@"2"]];
        [queryItems copy];
    });
    return components.URL;
}

@end
