//
//  BDNativeLiveComponent.m
//  BDNativeWebComponent
//
//  Created by Bytedance on 2021/9/22.
//

#import "BDNativeLottieComponent.h"
#import "BDNativeLottieView.h"
#import "BDNativeWebBaseComponent+Private.h"
#import <WebKit/WebKit.h>
#import <NSDictionary+BDNativeWebHelper.h>
#import <BDWebImage/BDWebImage.h>
#import <ByteDanceKit/ByteDanceKit.h>

@interface BDNativeLottieComponent () <BDNativeLottieViewDelegate>

@end

@implementation BDNativeLottieComponent

+ (NSString *)nativeTagName
{
    return @"lottie_view";
}

+ (NSNumber *)nativeTagVersion {
    return @(1);
}

- (UIView *)insertInNativeContainerObject:(BDNativeWebContainerObject *)containerObject params:(NSDictionary *)params
{
    BDNativeLottieView *lottieView = [[BDNativeLottieView alloc] init];
    lottieView.delegate = self;
    [self handlePropertyForLottieView:lottieView withParams:params];
    [self handleAnimationSourceForLottieView:lottieView withParams:params];
    [self handleAnimationProgressForLottieView:lottieView withParams:params];
    [self handleAnimationPlayStateForLottieView:lottieView withParams:params];
    return lottieView;
}

- (void)updateInNativeContainerObject:(BDNativeWebContainerObject *)containerObject params:(NSDictionary *)params {
    BDNativeLottieView *lottieView = (BDNativeLottieView *)containerObject.nativeView;
    [self handlePropertyForLottieView:lottieView withParams:params];
    [self handleAnimationSourceForLottieView:lottieView withParams:params];
    [self handleAnimationProgressForLottieView:lottieView withParams:params];
    [self handleAnimationPlayStateForLottieView:lottieView withParams:params];
}

- (void)deleteInNativeContainerObject:(BDNativeWebContainerObject *)containerObject params:(NSDictionary *)params {
    
}

#pragma mark - private method

- (void)handlePropertyForLottieView:(BDNativeLottieView *)view withParams:(NSDictionary *)params
{
    if (!view || !params || ![params isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    BOOL shouldUpdate = NO;
    if ([params objectForKey:@"loop"]) {
        NSNumber *loop = [params bdNative_objectForKey:@"loop"];
        view.loop = [loop boolValue];
        shouldUpdate = YES;
    }
    
    if ([params objectForKey:@"autoReverse"]) {
        NSNumber *autoReverse = [params bdNative_objectForKey:@"autoReverse"];
        view.autoReverse = [autoReverse boolValue];
        shouldUpdate = YES;
    }
    
    if ([params objectForKey:@"autoPlay"]) {
        NSNumber *autoPlay = [params bdNative_objectForKey:@"autoPlay"];
        view.autoPlay = [autoPlay boolValue];
        shouldUpdate = YES;
    }
    
    if ([params objectForKey:@"speed"]) {
        NSNumber *speed = [params bdNative_objectForKey:@"speed"];
        view.speed = [speed floatValue];
        shouldUpdate = YES;
    }
    
    if ([params objectForKey:@"loopCount"]) {
        NSNumber *loopCount = [params bdNative_objectForKey:@"loopCount"];
        view.loopCount = [loopCount integerValue];
        shouldUpdate = YES;
    }
    
    if ([params objectForKey:@"startFrame"]) {
        NSNumber *startFrame = [params bdNative_objectForKey:@"startFrame"];
        view.startFrame = startFrame;
        shouldUpdate = YES;
    }
    
    if ([params objectForKey:@"endFrame"]) {
        NSNumber *endFrame = [params bdNative_objectForKey:@"endFrame"];
        view.endFrame = endFrame;
        shouldUpdate = YES;
    }
    
    if ([params objectForKey:@"objectFit"]) {
        NSString *objectFit = [params bdNative_objectForKey:@"objectFit"];
        view.objectfitMode = objectFit;
        shouldUpdate = YES;
    }
    
    if ([params objectForKey:@"subscribeUpdateEvent"]) {
        NSNumber *frame = [params bdNative_objectForKey:@"subscribeUpdateEvent"];
        if ([frame isKindOfClass:[NSNumber class]]) {
            [view bdNativeSubscribeUpdateEvent:frame];
        }
    }
    
    if ([params objectForKey:@"unsubscribeUpdateEvent"]) {
        NSNumber *frame = [params bdNative_objectForKey:@"unsubscribeUpdateEvent"];
        if ([frame isKindOfClass:[NSNumber class]]) {
            [view bdNativeUnsubscribeUpdateEvent:frame];
        }
    }
    
    if (shouldUpdate) {
        [view bdNativeUpdateAnimationProperties];
    }
}

- (void)handleAnimationSourceForLottieView:(BDNativeLottieView *)view withParams:(NSDictionary *)params
{
    if (!view || !params || ![params isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    if ([params objectForKey:@"url"]) {
        NSString *url = [params bdNative_objectForKey:@"url"];
        [view bdNativeAnimationWithURL:url];
        return;
    }
    
    if ([params objectForKey:@"jsonData"]) {
        NSString *jsonData = [params bdNative_objectForKey:@"jsonData"];
        NSError *error;
        NSDictionary *json = [jsonData btd_jsonDictionary:&error];
        if (!error && json) {
            [view bdNativeAnimationWithJSON:json];
        } else {
            [self onNativeLottieErrorHappened:view extraDetail:@{
                @"errorCode": @(BDNativeLottieErrorCodeInvalidData),
                @"errorExt" : @"Invalid json data.",
            }];
        }
        return;
    }
}

- (void)handleAnimationPlayStateForLottieView:(BDNativeLottieView *)view withParams:(NSDictionary *)params
{
    if (!view || !params || ![params isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    if ([params objectForKey:@"stop"]) {
        NSNumber *stop = [params bdNative_objectForKey:@"stop"];
        BOOL willStop = [stop boolValue];
        if (willStop) {
            view.couldPlay = NO;
            [view bdNativeStopAnimation];
        }
    } else {
        if ([params objectForKey:@"play"]) {
            NSNumber *play = [params bdNative_objectForKey:@"play"];
            view.couldPlay = [play boolValue];
            [view bdNativeUpdateAnimationPlayState];
        }
    }
}

- (void)handleAnimationProgressForLottieView:(BDNativeLottieView *)view withParams:(NSDictionary *)params
{
    if (!view || !params || ![params isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    if ([params objectForKey:@"seek"]) {
        NSNumber *seekFrame = [params bdNative_objectForKey:@"seek"];
        [view bdNativeUpdateAnimationPosition:seekFrame withFrame:YES];
    }
    
    if ([params objectForKey:@"progress"]) {
        NSNumber *progress = [params bdNative_objectForKey:@"progress"];
        [view bdNativeUpdateAnimationPosition:progress withFrame:NO];
    }
}

#pragma mark - BDNativeLottieViewDelegate

- (NSString *)fetchWebURL
{
    if (self.webView && self.webView.URL) {
        return self.webView.URL.absoluteString ?: @"";
    }
    return @"";
}

- (void)onNativeLottieFrameUpdated:(BDNativeLottieView *)view extraDetail:(NSDictionary *)extraDetail
{
    [self sendEvent:view withEventCode:BDNativeLottieFrameUpdated extraDetail:extraDetail];
}

- (void)onNativeLottieSourceLoaded:(BDNativeLottieView *)view extraDetail:(NSDictionary *)extraDetail
{
    [self sendEvent:view withEventCode:BDNativeLottieSourceLoaded extraDetail:extraDetail];
}

- (void)onNativeLottieErrorHappened:(BDNativeLottieView *)view extraDetail:(NSDictionary *)extraDetail
{
    [self sendEvent:view withEventCode:BDNativeLottieErrorHappened extraDetail:extraDetail];
}

- (void)onNativeLottiePlayStateChanged:(BDNativeLottieView *)view extraDetail:(NSDictionary *)extraDetail
{
    [self sendEvent:view withEventCode:BDNativeLottiePlayStateChanged extraDetail:extraDetail];
}

- (void)sendEvent:(BDNativeLottieView *)view withEventCode:(BDNativeLottieStatusCode)code extraDetail:(NSDictionary *)extraDetail
{
    NSMutableDictionary *detail = [NSMutableDictionary dictionary];
    detail[@"code"] = @(code);
    detail[@"currentFrame"] = @([[view bdNativeCurrentFrame] integerValue]);
    detail[@"currentProgress"] = @(floorf([view bdNativeAnimationProgress] * 100));
    detail[@"totalFrameCount"] = @([[view bdNativeTotalFrameCount] integerValue]);
    detail[@"animationDuration"] = @(floorf([view bdNativeAnimationDuration]));
    detail[@"currentLoopIndex"] = @([view bdNativeCurrentLoopIndex]);
    detail[@"isAnimationPlaying"] = @([view bdNativeIsAnimationPlaying]);
    if (extraDetail) {
        [detail addEntriesFromDictionary:extraDetail];
    }
    [self fireComponentAction:@"onStateChange" params:[detail copy]];
}


@end
