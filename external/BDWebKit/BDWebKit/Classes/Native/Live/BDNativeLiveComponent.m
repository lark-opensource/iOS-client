//
//  BDNativeLiveComponent.m
//  BDNativeWebComponent
//
//  Created by Bytedance on 2021/9/22.
//

#import "BDNativeLiveComponent.h"
#import "BDNativeLiveVideoView.h"
#import <NSDictionary+BDNativeWebHelper.h>
#import <BDWebImage/BDWebImage.h>

@interface BDNativeLiveComponent () <BDNativeLiveVideoViewPlayerDelegate>

@property (nonatomic, assign) BOOL autoPlay;
@property (nonatomic, weak) BDNativeLiveVideoView *videoView;

@end

@implementation BDNativeLiveComponent

+ (NSString *)nativeTagName
{
    return @"live_player";
}

+ (NSNumber *)nativeTagVersion {
    return @(1);
}

- (UIView *)insertInNativeContainerObject:(BDNativeWebContainerObject *)containerObject params:(NSDictionary *)params
{
    BDNativeLiveVideoView *liveVideoView = [[BDNativeLiveVideoView alloc] init];
    liveVideoView.delegate = self;
    [self handleAutoplayWithVideoView:liveVideoView params:params];
    [self handleSrcWithVideoView:liveVideoView params:params];
    [self handleControlsWithVideoView:liveVideoView params:params];
    [self handleVolumeWithVideoView:liveVideoView params:params];
    [self handleMutedWithVideoView:liveVideoView params:params];
    [self handlePoster:liveVideoView params:params];
    [self handleObjectFitWithImageView:liveVideoView params:params];
    [self handleCornerRadiusWithImageView:liveVideoView params:params];
    self.videoView = liveVideoView;
    return liveVideoView;
}

- (void)updateInNativeContainerObject:(BDNativeWebContainerObject *)containerObject params:(NSDictionary *)params {
    BDNativeLiveVideoView *liveVideoView = (BDNativeLiveVideoView *)containerObject.nativeView;
    [self handleAutoplayWithVideoView:liveVideoView params:params];
    [self handleSrcWithVideoView:liveVideoView params:params];
    [self handleControlsWithVideoView:liveVideoView params:params];
    [self handleVolumeWithVideoView:liveVideoView params:params];
    [self handleMutedWithVideoView:liveVideoView params:params];
    [self handlePoster:liveVideoView params:params];
    [self handleObjectFitWithImageView:liveVideoView params:params];
    [self handleCornerRadiusWithImageView:liveVideoView params:params];
}

- (void)deleteInNativeContainerObject:(BDNativeWebContainerObject *)containerObject params:(NSDictionary *)params {
    
}

#pragma mark - private method

- (void)handleSrcWithVideoView:(BDNativeLiveVideoView *)videoView params:(NSDictionary *)params
{
    NSString *src = [params bdNative_stringValueForKey:@"src"];
    if (src.length <= 0) {
        return;
    }
    
    [videoView setupSrc:src];
    if (self.autoPlay) {
        [videoView play];
    }
}

- (void)handleControlsWithVideoView:(BDNativeLiveVideoView *)videoView params:(NSDictionary *)params
{
    NSNumber *playNum = [params bdNative_objectForKey:@"play"];
    if (playNum == nil) {
        return;
    }
    BOOL play = [playNum boolValue];
    videoView.couldPlay = play;
    if (play) {
        [videoView play];
    } else{
        [videoView pause];
    }
}

- (void)handleAutoplayWithVideoView:(BDNativeLiveVideoView *)videoView params:(NSDictionary *)params
{
    NSNumber *autoplayNum = [params bdNative_objectForKey:@"autoPlay"];
    if (autoplayNum == nil) {
        return;
    }
    BOOL autoplay = [autoplayNum boolValue];
    videoView.autoPlay = autoplay;
}

- (void)handleVolumeWithVideoView:(BDNativeLiveVideoView *)videoView params:(NSDictionary *)params
{
    if (![params objectForKey:@"volume"]) {
        return;
    }
    NSNumber *volume = [params bdNative_objectForKey:@"volume"];
    videoView.volume = [volume floatValue];
}

- (void)handleMutedWithVideoView:(BDNativeLiveVideoView *)videoView params:(NSDictionary *)params
{
    if (![params objectForKey:@"muted"]) {
        return;
    }

    BOOL muted = [params bdNative_boolValueForKey:@"muted"];
    videoView.mute = muted;
}

- (void)handlePoster:(BDNativeLiveVideoView *)videoView params:(NSDictionary *)params
{
    NSString *poster = [params bdNative_stringValueForKey:@"poster"];
    if (poster.length <= 0) {
        return;
    }

    NSURL *URL = [NSURL URLWithString:poster];
    [videoView.posterImageView bd_setImageWithURL:URL];
}

- (void)handleObjectFitWithImageView:(BDNativeLiveVideoView *)videoView params:(NSDictionary *)params
{
    NSString *objectFit = [params bdNative_stringValueForKey:@"objectFit"];
    if (objectFit.length <= 0) {
        return;
    }
    [videoView setFitMode:objectFit];
}

- (void)handleCornerRadiusWithImageView:(BDNativeLiveVideoView *)videoView params:(NSDictionary *)params
{
    if (![params objectForKey:@"cornerRadius"]) {
        return;
    }
    NSNumber *radius = [params bdNative_objectForKey:@"cornerRadius"];
    [videoView setCornerRadius:[radius floatValue]];
}

#pragma mark - BDNativeLiveVideoViewPlayerDelegate

- (void)didIdle {
    [self fireComponentAction:@"onStateChange" params:@{
        @"code" : @(0),
        @"ext" :  @""
    }];
}

- (void)didReady {
    [self fireComponentAction:@"onStateChange" params:@{
        @"code" : @(2),
        @"ext" :  @""
    }];
}

- (void)didPlay
{    
    [self fireComponentAction:@"onStateChange" params:@{
        @"code" : @(3),
        @"ext" :  @""
    }];
}

- (void)didPause
{
    [self fireComponentAction:@"onStateChange" params:@{
        @"code" : @(5),
        @"ext" :  @""
    }];
}

- (void)didStop
{
    [self fireComponentAction:@"onStateChange" params:@{
        @"code" : @(6),
        @"ext" :  @""
    }];
}

- (void)didError:(NSDictionary *)errorDic
{
    [self fireComponentAction:@"onStateChange" params:@{
        @"code" : @(7),
        @"ext" :  errorDic
    }];
}

- (void)didStall
{
    [self fireComponentAction:@"onStateChange" params:@{
        @"code" : @(4),
        @"ext" :  @""
    }];
}

- (void)didResume
{
    [self fireComponentAction:@"onStateChange" params:@{
        @"code" : @(3),
        @"ext" :  @"resume"
    }];
}


- (void)didVideoSizChange:(CGSize)size {
    [self fireComponentAction:@"onVideoSizeChange" params:@{
        @"height" : @(size.height),
        @"width" : @(size.width),
    }];
}

@end
