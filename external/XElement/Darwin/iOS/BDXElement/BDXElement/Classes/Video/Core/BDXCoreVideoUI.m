//
//  BDXCoreVideoUI.m
//  BDXElement
//
//  Created by 李柯良 on 2020/7/13.
//

#import "BDXCoreVideoUI.h"
#import "BDXVideoPlayer.h"
#import "BDXVideoPlayerVideoModel.h"
#import "BDXVideoDefines.h"
#import "BDXVideoManager.h"
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSURL+BTDAdditions.h>
#import <objc/runtime.h>

@interface BDXCoreVideoUI()<BDXVideoPlayerDelegate>

@property (nonatomic, strong) NSDictionary *paramsDict;

@property (nonatomic, strong) BDXVideoPlayerVideoModel *videoModel;

@end

@implementation BDXCoreVideoUI

+ (NSString *)tagName
{
    return @"x-video";
}

- (UIView*)createView
{
    BDXVideoPlayer *player = [[BDXVideoPlayer alloc] initWithDelegate:self];
    player.backgroundColor = [UIColor purpleColor];
    [player setTranslatesAutoresizingMaskIntoConstraints:YES];
    return player;
}

BDX_PROP_SETTER(src, NSString *)
{
    if ([value isKindOfClass:[NSString class]] && value.length > 0) {
        BDXVideoPlayerVideoModel *videoModel = [self __resolveSrcAsJSON:value];
        if (!videoModel) {
            videoModel = [self __resolveSrcAsSchema:value];
        }
        if (videoModel) {
            [self __setupVideoModel:videoModel];
        }
    }
}

BDX_PROP_SETTER(autoplay, BOOL)
{
    _autoPlay = value;
    self.view.autoPlay = value;
}

BDX_PROP_SETTER(preload, BOOL)
{
    _needPreload = value;
    self.view.needPreload = value;
}

BDX_PROP_SETTER(inittime, NSNumber *)
{
    _startTime = value;
    self.view.startTime = value.doubleValue;
}

BDX_PROP_SETTER(repeat, BOOL)
{
    _isLoop = value;
    self.view.isLoop = value;
}

BDX_PROP_SETTER(muted, BOOL)
{
    _mute = value;
    self.view.mute = value;
}

BDX_PROP_SETTER(volume, NSNumber *)
{
    if (value < 0) return;
    _volume = value;
    if ([value floatValue] > 1) {
        self.view.volume = 1;
        return;
    }
    self.view.volume = [value floatValue];
}

BDX_PROP_SETTER(rate, NSNumber *)
{
    _rate = value;
    self.view.rate = value.doubleValue;
}

BDX_PROP_SETTER(autolifecycle, BOOL)
{
    _autoLifecycle = value;
    self.view.autoLifecycle = value;
}

BDX_PROP_SETTER(poster, NSString *)
{
    if (value && !BTD_isEmptyString(value) && ![value.class isKindOfClass:[NSNull class]]) {
        _posterURL = value;
        self.view.posterURL = value;
    }
}

BDX_PROP_SETTER(objectfit, NSString *)
{
    _fitMode = value;
    self.view.fitMode = value;
}

BDX_PROP_SETTER(singleplayer, BOOL)
{
    _useSinglePlayer = value;
    self.view.useSharedPlayer = value;
}

BDX_PROP_SETTER(devicechangeaware, BOOL)
{
    _listenDeviceChange = value;
}

BDX_PROP_SETTER(__control, NSString *)
{
    _control = value;
    [self __controlPlayerWithCommand:value];
}

#pragma mark - Private

- (void)__controlPlayerWithCommand:(NSString *)command
{
    if (!command || BTD_isEmptyString(command) || [command isKindOfClass:[NSNull class]]) return;
    NSArray<NSString *> *controlComponents = [command componentsSeparatedByString:@"_*_"];
    if (controlComponents.count == 3) {
        NSString *action = controlComponents[0];
        NSString *params = controlComponents[1];
        NSDictionary *paramsDict = [NSJSONSerialization JSONObjectWithData:[params dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:NULL];
        if ([action isEqualToString:@"play"]) {
            [self.view play];
        } else if ([action isEqualToString:@"pause"]) {
            [self.view pause];
        } else if ([action isEqualToString:@"stop"]) {
            [self.view stop];
        } else if ([action isEqualToString:@"seek"]) {
            CGFloat position = 0.0;
            BOOL shouldPlay = NO;
            if ([paramsDict btd_floatValueForKey:@"position"]) {
                position = [paramsDict btd_floatValueForKey:@"position"];
            }
            if ([paramsDict btd_boolValueForKey:@"play"]) {
                shouldPlay = [paramsDict btd_boolValueForKey:@"play"];
            }
            if (position) {
                [self.view seekToTime:position / 1000.0 completion:^(BOOL finished) {
                    if (shouldPlay) {
                        [self.view play];
                    }
                }];
            }
        } else if ([action isEqualToString:@"requestfullscreen"]) {
            [self.view zoom];
        } else if ([action isEqualToString:@"exitfullscreen"]) {
            // Nothing to do
        }
    }
}

- (BDXVideoPlayerVideoModel *)__resolveSrcAsJSON:(NSString *)jsonString
{
    if (jsonString.length == 0) {
        return nil;
    }
    NSError *error = nil;
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    if (data.length == 0) {
        return nil;
    }
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (jsonDict.count == 0) {
        return nil;
    }
    Class videoModelConverterClz = BDXVideoManager.videoModelConverterClz;
    if (videoModelConverterClz && class_conformsToProtocol(videoModelConverterClz, @protocol(BDXVideoPlayerVideoModelConverter))) {
        id<BDXVideoPlayerVideoModelConverter> converter = [[videoModelConverterClz alloc] init];
        BDXVideoPlayerVideoModel *videoModel = [converter convertFromJSONDict:jsonDict];
        return videoModel;
    }
    NSString *itemID = [jsonDict btd_stringValueForKey:@"item_id"];
    NSString *videoURL = [jsonDict btd_stringValueForKey:@"video_url"];
    if (itemID.length > 0) {
        BDXVideoPlayerVideoModel *videoModel = [BDXVideoPlayerVideoModel new];
        videoModel.itemID = itemID;
        videoModel.playUrlString = videoURL;
        return videoModel;
    }
    return nil;
}

- (BDXVideoPlayerVideoModel *)__resolveSrcAsSchema:(NSString *)schemaString
{
    if (schemaString.length == 0) {
        return nil;
    }
    NSURL *schema = [NSURL URLWithString:schemaString];
    NSDictionary *query = [schema btd_queryItemsWithDecoding];
    NSString *itemID = [query btd_stringValueForKey:@"video_id"];
    NSString *videoURL = [query btd_stringValueForKey:@"play_url"];
    if (itemID.length > 0 || videoURL.length > 0) {
        BDXVideoPlayerVideoModel *videoModel = [BDXVideoPlayerVideoModel new];
        videoModel.itemID = itemID;
        videoModel.playUrlString = videoURL;
        return videoModel;
    }
    return nil;
}

- (void)__setupVideoModel:(BDXVideoPlayerVideoModel *)videoModel
{
    if (videoModel == nil) {
        return;
    }
    self.videoModel = videoModel;
    [self.view refreshBDXVideoModel:videoModel params:@{}];
}

#pragma mark - BDXLynxVideoDelegate

- (void)didPlay
{
    [self.eventDispatcher sendCustomEvent:BDXVideoPlayEvent params:@{}];
}

- (void)didPause
{
    [self.eventDispatcher sendCustomEvent:BDXVideoPauseEvent params:@{}];
}

- (void)didEnd
{
    [self.eventDispatcher sendCustomEvent:BDXVideoEndedEvent params:@{}];
}

- (void)didError
{
    [self.eventDispatcher sendCustomEvent:BDXVideoErrorEvent params:@{}];
}

- (void)didTimeUpdate
{
    [self.eventDispatcher sendCustomEvent:BDXVideoTimeUpdateEvent params:@{}];
}

- (void)didFullscreenChange
{
    [self.eventDispatcher sendCustomEvent:BDXVideoFullscreenChangeEvent params:@{}];
}

- (void)didBufferChange
{
    [self.eventDispatcher sendCustomEvent:BDXVideoBufferingEvent params:@{}];
}

- (void)didBufferChangeWithInfo:(NSDictionary *)info
{
    [self.eventDispatcher sendCustomEvent:BDXVideoBufferingEvent params:info];
}

- (void)didDeviceChange:(NSDictionary *)info
{
    [self.eventDispatcher sendCustomEvent:BDXVideoDeviceChangeEvent params:@{}];
}

- (void)didSeek
{
    [self.eventDispatcher sendCustomEvent:BDXVideoSeekEvent params:@{}];
}

@end
