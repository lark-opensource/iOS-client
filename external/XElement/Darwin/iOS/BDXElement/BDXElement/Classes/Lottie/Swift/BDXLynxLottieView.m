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
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import "BDXElementResourceManager.h"
#import <objc/runtime.h>
#if __has_include("XElement-Swift.h")
#import "XElement-Swift.h"
#else
#import <XElement/XElement-Swift.h>
#endif

@interface BDXLynxLottieView()

@property (nonatomic, assign) BridgeAnimationView *animationView;

@property (nonatomic, assign) BOOL autoPlay;
@property (nonatomic, assign) BOOL layoutFinished;
@property (nonatomic, assign) BOOL playWhenFinishingLayout;
@property (nonatomic, assign) BOOL resourceReady;
@property (nonatomic, copy) NSString *srcFormat;
@property (nonatomic, copy) NSString *srcPolyfill;
@property (nonatomic, strong) NSNumber *startFrame;
@property (nonatomic, strong) NSNumber *endFrame;

@end

@implementation BDXLynxLottieView

- (instancetype)init
{
    self = [super init];
    if (self) {
        _autoPlay = YES;
    }
    return self;
}

- (UIView *)createView
{
    BridgeAnimationView *view = [[BridgeAnimationView alloc] init];
    return view;
}

- (void)layoutDidFinished
{
    [super layoutDidFinished];
    
    self.layoutFinished = true;
    
    if (self.autoPlay && self.playWhenFinishingLayout) {
        [self play];
    }
}

#pragma mark - LynxPropsProcessor & LynxComponentRegistry

//LYNX_REGISTER_UI("x-lottie") // 兼容老版本
//LYNX_REGISTER_UI("lottie-view") // 新版本
+(void)load {
    [LynxComponentRegistry registerUI:self withName:@"x-lottie"];
    [LynxComponentRegistry registerUI:self withName:@"lottie-view"];
}

LYNX_PROP_SETTER("play", play, BOOL)
{
    if (value) {
        [self play];
    } else {
        [self.animationView stop];
    }
}

LYNX_PROP_SETTER("src", src, NSString *)
{
    [self updateSource:value withPolyfill:nil hasPlaceholder:NO];
}

LYNX_PROP_SETTER("src-format", srcFormat, NSString *)
{
    self.srcFormat = value;
    [self updateSourceWithPolyfillIfNeeded];
}

LYNX_PROP_SETTER("src-polyfill", srcPolyfill, NSString *)
{
    self.srcPolyfill = value;
    [self updateSourceWithPolyfillIfNeeded];
}

LYNX_PROP_SETTER("json", json, NSString *)
{
    self.resourceReady = NO;
    if ([value isKindOfClass:[NSNull class]]) {
        return;
    }
    if (value.length > 0) {
        NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
        if (data.length > 0) {
            [self.animationView setAnimationFromJSONData:data];
            self.resourceReady = YES;
            self.playWhenFinishingLayout = YES;
        }
    }
}

LYNX_PROP_SETTER("loop", loop, BOOL)
{
    [self.animationView loopAnimation:value];
}

LYNX_PROP_SETTER("start-frame", startFrame, NSNumber *)
{
    self.startFrame = value;
}

LYNX_PROP_SETTER("end-frame", endFrame, NSNumber *)
{
    self.endFrame = value;
}

LYNX_PROP_SETTER("autoplay", autoplay, BOOL)
{
    self.autoPlay = value;
}

LYNX_PROP_SETTER("speed", speed, NSNumber *)
{
    if ([value isKindOfClass:NSNumber.class]) {
        self.animationView.animationSpeed = value.floatValue;
    }
}

LYNX_UI_METHOD(play) {
    [self play];
}

LYNX_UI_METHOD(stop) {
    [self.animationView stop];
}

LYNX_UI_METHOD(pause) {
    [self.animationView pause];
}

LYNX_UI_METHOD(seek) {
    NSNumber *frame = params[@"frame"];
    if ([frame isKindOfClass:NSNumber.class]) {
        [self.animationView setProgressWithFrame:frame];
    }
}

#pragma mark - Action

- (void)play
{
    __weak __typeof(self) weakSelf = self;
    void (^completion)(BOOL) = ^(BOOL animationFinished) {
        if (animationFinished) {
            [weakSelf callCompletion];
        }
    };
    
    [self.animationView play:completion];
}

- (void)callCompletion
{
    if (!self.layoutFinished) {
        return;
    }

    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"completion" targetSign:[self sign] detail:@{}];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)sendReadyEventIfNeeded
{
    if (self.layoutFinished && self.resourceReady) {
        LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"ready" targetSign:[self sign] detail:@{}];
        [self.context.eventEmitter sendCustomEvent:event];
    }
}

- (void)setResourceReady:(BOOL)resourceReady
{
    _resourceReady = resourceReady;
    if (resourceReady) {
        [self sendReadyEventIfNeeded];
    }
}

- (void)setLayoutFinished:(BOOL)layoutFinished
{
    _layoutFinished = layoutFinished;
    if (layoutFinished) {
        [self sendReadyEventIfNeeded];
    }
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
    self.resourceReady = NO;

    NSURL *lynxViewURL = nil;
    if ([self.context.rootView isKindOfClass:LynxView.class]) {
        LynxView *lynxView = (LynxView *)self.context.rootView;
        if (lynxView.url) {
            lynxViewURL = [NSURL URLWithString:lynxView.url];
        }
    }
    
    NSURL *url = [NSURL URLWithString:source ?: @"" relativeToURL:lynxViewURL];
    if (!url) {
        return;
    }
    
    NSURL *baseURL = nil;
    if ([self.context.rootView isKindOfClass:[LynxView class]]) {
        baseURL = [NSURL URLWithString:[(LynxView *)self.context.rootView url]];
    }
    
    __weak __typeof(self) weakSelf = self;
    [[BDXElementResourceManager sharedInstance] resourceDataWithURL:url baseURL:baseURL context:nil completionHandler:^(NSURL *url, NSData *animationData, NSError *error) {
        if (!animationData) {
            return;
        }
        
        if (hasPlaceholder) {
            NSString *jsonFormat = [[NSString alloc] initWithData:animationData encoding:NSUTF8StringEncoding];
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"%s" options:kNilOptions error:&error];
            if (!jsonFormat || error) {
                return;
            }
            NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:jsonFormat options:kNilOptions range:NSMakeRange(0, jsonFormat.length)];
            NSArray<NSString *> *polyfills = [weakSelf.srcPolyfill componentsSeparatedByString:@","];
            if (polyfills.count != matches.count) {
                return;
            }
            NSMutableString *jsonString = [jsonFormat mutableCopy];
            [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult *match, NSUInteger idx, BOOL *stop) {
                [jsonString replaceCharactersInRange:match.range withString:polyfills[idx]];
            }];
            animationData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
            if (!animationData) {
                return;
            }
        }
        
        NSDictionary *animationJSON = [NSJSONSerialization JSONObjectWithData:animationData options:0 error:&error];
        if (error || !animationJSON) {
            return;
        }
        
        if ([weakSelf.animationView respondsToSelector:@selector(_initializeAnimationContainer)] && [weakSelf.animationView respondsToSelector:@selector(_setupWithSceneModel:)]) {
        } else {
            if (animationData.length > 0) {
                [(BridgeAnimationView *)weakSelf.animationView setAnimationFromJSONData:animationData];
            }
        }
        
        self.resourceReady = YES;
        if (weakSelf.autoPlay && weakSelf.layoutFinished) {
            [weakSelf play];
        } else {
            weakSelf.playWhenFinishingLayout = YES;
        }
    }];
}

#pragma mark - SwiftLottieView

- (BridgeAnimationView *)animationView {
    if (!_animationView) {
        if ([self.view isMemberOfClass:NSClassFromString(@"XElement.BridgeAnimationView")]) {
            _animationView = (BridgeAnimationView *)self.view;
        } else {
            _animationView = [[BridgeAnimationView alloc] init];
        }
    }
    return _animationView;
}

@end
