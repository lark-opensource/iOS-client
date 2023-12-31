//
//  BDXLynxVideoView.m
//  BDLynx
//
//  Created by pacebill on 2020/3/18.
//

#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSURL+BTDAdditions.h>
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxLayoutStyle.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import <objc/runtime.h>
#import "BDXLynxVideoView.h"
#import "BDXVideoDefines.h"
#import "BDXVideoManager.h"
#import "BDXVideoPlayer.h"
#import "BDXVideoPlayerVideoModel.h"
#import "BDXElementResourceManager.h"
#import <Lynx/LynxView.h>
#import <Lynx/LynxRootUI.h>

@interface BDXLynxVideoView ()

@property (nonatomic, strong) NSDictionary *paramsDict;
@property (nonatomic, strong) BDXVideoPlayerVideoModel *videoModel;

// subviews from Lynx ttml under x-video label
@property(nonatomic, strong) NSMutableArray<UIView *>* childrenView;
@property(nonatomic, assign) BOOL hidden;

@end

@implementation BDXLynxVideoView (RenamedVersion)

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-property-implementation"
@implementation BDXLynxVideoView
#pragma clang diagnostic pop


+ (Class)videoCorePlayerClazz
{
    return BDXVideoManager.videoCorePlayerClazz;
}

+ (Class)videoModelConverterClz
{
    return BDXVideoManager.videoModelConverterClz;
}

+ (Class)fullScreenPlayerClz
{
    return BDXVideoManager.fullScreenPlayerClz;
}



- (instancetype)init
{
    self = [super init];
    self.childrenView = [[NSMutableArray alloc] init];
    return self;
}

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-video")
#else
LYNX_REGISTER_UI("x-video")
#endif

- (BOOL)hasCustomLayout
{
    return YES;
}

- (UIView*)createView
{
    BDXVideoPlayer *player = [[BDXVideoPlayer alloc] initWithDelegate:self];
    player.backgroundColor = [UIColor blackColor];
    [player setTranslatesAutoresizingMaskIntoConstraints:YES];
    return player;
}

- (void)layoutDidFinished
{
    [super layoutDidFinished];

    [self.childrenView enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];

    @weakify(self);
    [self.children enumerateObjectsUsingBlock:^(LynxUI<UIView *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @strongify(self);
        UIView *subView = obj.view;
        [self.childrenView addObject:subView];
        [self.view addSubview:subView];
        // set native view from frame calculated by lynx, assigned in .ttss
        subView.frame = obj.frame;
    }];
}

LYNX_PROP_SETTER("src", schema, NSString *)
{
    if ([value isKindOfClass:[NSString class]] && value.length > 0) {
        BDXVideoPlayerVideoModel *videoModel = [self __resolveSrcAsJSON:value];
        if (!videoModel) {
            videoModel = [self __resolveSrcAsSchema:value];
        }
        if (!videoModel) {
            videoModel = [self __resolveSrcAsUrl:value];
        }
        if (videoModel) {
            [self __setupVideoModel:videoModel];
        }
    }
}

LYNX_PROP_SETTER("log-extra", logExtraDict, NSDictionary *)
{
    if (![value isKindOfClass:[NSDictionary class]] || ![value count]) {
        return;
    }

    NSDictionary *formattedValue = [self formatLogExtraDict:value];
    _logExtraDict = formattedValue;
    [self.view refreshLogExtraDict:formattedValue];
}

- (NSDictionary *)formatLogExtraDict:(NSDictionary *)logExtraDict
{
    NSMutableDictionary *formatLogExtraDict = [NSMutableDictionary dictionary];
    for (NSString *key in logExtraDict) {
        // reqeust_id是已有字段, 不进行长度限制
        if ([[logExtraDict objectForKey:key] isKindOfClass:[NSString class]] && ![[logExtraDict objectForKey:key] isEqualToString:@"request_id"]) {
            NSString *param = [logExtraDict objectForKey:key];
            if (param.length > 32) {
                [formatLogExtraDict addEntriesFromDictionary:@{
                    key: [param substringToIndex:32]
                }];
            } else {
                [formatLogExtraDict addEntriesFromDictionary:@{
                    key: param
                }];
            }
        } else {
            [formatLogExtraDict addEntriesFromDictionary:@{
                key: [logExtraDict objectForKey:key]
            }];
        }
    }
    return formatLogExtraDict;
}

LYNX_PROP_SETTER("autoplay", autoPlay, BOOL)
{
    _autoPlay = value;
    self.view.autoPlay = value;
}

LYNX_PROP_SETTER("preload", preload, BOOL)
{
    _needPreload = value;
    self.view.needPreload = value;
}

LYNX_PROP_SETTER("inittime", startTime, NSNumber *)
{
    _startTime = value;
    self.view.startTime = value.doubleValue;
}

LYNX_PROP_SETTER("repeat", setRepeat, BOOL)
{
    _isLoop = value;
    self.view.isLoop = value;
}

LYNX_PROP_SETTER("muted", mute, BOOL)
{
    _mute = value;
    self.view.mute = value;
}

LYNX_PROP_SETTER("volume", volume, NSNumber *)
{
    if (value < 0) return;
    _volume = value;
    if ([value floatValue] > 1) {
        self.view.volume = 1;
        return;
    }
    self.view.volume = [value floatValue];
}

LYNX_PROP_SETTER("rate", rate, NSNumber *)
{
    _rate = value;
    self.view.rate = value.doubleValue;
}

LYNX_PROP_SETTER("autolifecycle", autoLifecycle, BOOL)
{
    _autoLifecycle = value;
    self.view.autoLifecycle = value;
}

LYNX_PROP_SETTER("poster", posterURL, NSString *)
{
    if (value && !BTD_isEmptyString(value) && ![value isKindOfClass:[NSNull class]]) {
        _posterURL = value;
        self.view.posterURL = value;
    }
}

LYNX_PROP_SETTER("objectfit", fitMode, NSString *)
{
    _fitMode = value;
    self.view.fitMode = value;
}

LYNX_PROP_SETTER("singleplayer", useSinglePlayer, BOOL)
{
    _useSinglePlayer = value;
    self.view.useSharedPlayer = value;
}

LYNX_PROP_SETTER("devicechangeaware", listenDeviceChange, BOOL)
{
    _listenDeviceChange = value;
}

LYNX_PROP_SETTER("__control", control, NSString *)
{
    if (self.hidden) {
      return;
    }
    _control = value;
    [self __controlPlayerWithCommand:value];
}

LYNX_UI_METHOD(getDuration) {
    callback(kUIMethodSuccess, @{ @"data": @(self.view.duration * 1000) });
}

#pragma mark - Private

- (void)__controlPlayerWithCommand:(NSString *)command
{
    if (!command || BTD_isEmptyString(command) || [command isKindOfClass:[NSNull class]]) return;
    NSArray<NSString *> *controlComponents = [command componentsSeparatedByString:@"_*_"];
    if (controlComponents.count == 3) {
        NSString *action = controlComponents[0];
        NSString *params = controlComponents[1];
        NSNumber *actionTimestamp = (NSNumber *)controlComponents[2];
        NSDictionary *paramsDict = [NSJSONSerialization JSONObjectWithData:[params dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:NULL];
        if ([action isEqualToString:@"play"]) {
            if (actionTimestamp) {
                [self.view refreshActionTimestamp:actionTimestamp];
            }
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
            [self.view exitFullScreen];
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
    Class videoModelConverterClz = self.class.videoModelConverterClz;
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
    NSString *playerVersion = [query btd_stringValueForKey:@"player_version"];
    NSString *playerAuth = [query btd_stringValueForKey:@"player_auth"];
    NSString *playerToken = [query btd_stringValueForKey:@"player_token"];
    NSArray *hosts = [query btd_arrayValueForKey:@"hosts"];

    if (playerVersion.length > 0) {
        if (itemID.length > 0 || playerAuth.length > 0) {
            BDXVideoPlayerVideoModel *videoModel = [BDXVideoPlayerVideoModel new];
            videoModel.itemID = itemID;
            videoModel.playAutoToken = playerToken;
            videoModel.hosts = hosts;
            videoModel.apiVersion = BDXVideoPlayerAPIVersion2;
            return videoModel;
        }
    } else {
        if (itemID.length > 0 || videoURL.length > 0) {
            BDXVideoPlayerVideoModel *videoModel = [BDXVideoPlayerVideoModel new];
            videoModel.itemID = itemID;
            videoModel.apiVersion = BDXVideoPlayerAPIVersion1;
            videoModel.playUrlString = videoURL;
            return videoModel;
        }
    }
    
    return nil;
}

- (BDXVideoPlayerVideoModel *)__resolveSrcAsUrl:(NSString *)urlString {
    if (urlString.length == 0) {
        return nil;
    }
    if ([urlString hasPrefix:@"http://"] || [urlString hasPrefix:@"https://"]) {
        BDXVideoPlayerVideoModel *videoModel = [[BDXVideoPlayerVideoModel alloc] init];
        videoModel.playUrlString = urlString;
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
    if (self.logExtraDict) {
        [self.view refreshBDXVideoModel:videoModel params:@{
            @"logExtraDict": self.logExtraDict
        }];
    } else {
        [self.view refreshBDXVideoModel:videoModel params:@{}];
    }
}

#pragma mark - BDXLynxVideoDelegate

- (void)didPlay
{
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXVideoPlayEvent targetSign:[self sign] detail:@{}];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)didPause
{
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXVideoPauseEvent targetSign:[self sign] detail:@{}];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)didEnd
{
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXVideoEndedEvent targetSign:[self sign] detail:@{}];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)didError
{
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXVideoErrorEvent targetSign:[self sign] detail:@{}];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)didError:(NSDictionary *)errorInfo
{
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXVideoErrorEvent targetSign:[self sign] detail:errorInfo];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)didTimeUpdate:(NSDictionary *)info
{
    if (self.view.currentPlayState != BDXVideoPlayStatePlay) {
        return;
    }
    
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXVideoTimeUpdateEvent targetSign:[self sign] detail:info];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)didFullscreenChange:(NSDictionary *)info
{
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXVideoFullscreenChangeEvent targetSign:[self sign] detail:info];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)didBufferChange
{
    [self didBufferChangeWithInfo:@{@"buffer" : @"0"}];
}

- (void)didBufferChangeWithInfo:(NSDictionary *)info
{
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXVideoBufferingEvent targetSign:[self sign] detail:info];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)didDeviceChange:(NSDictionary *)info
{
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXVideoDeviceChangeEvent targetSign:[self sign] detail:info];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)didSeek:(NSTimeInterval)time
{
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXVideoSeekEvent targetSign:[self sign] detail:@{}];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)fetchByResourceManager:(NSURL *)aURL completionHandler:(void (^)(NSURL * _Nonnull, NSURL * _Nonnull, NSError * _Nullable))completionHandler {
    NSURL *baseURL = nil;
    if ([self.context.rootView isKindOfClass:[LynxView class]]) {
        baseURL = [NSURL URLWithString:[(LynxView *)self.context.rootView url]];
    }

    NSMutableDictionary *context = [NSMutableDictionary dictionary];
    context[BDXElementContextContainerKey] = self.context.rootUI.lynxView;

    __weak __typeof(self) weakSelf = self;
    [[BDXElementResourceManager sharedInstance] fetchLocalFileWithURL:aURL
                                                              baseURL:baseURL
                                                              context:[context copy]
                                                    completionHandler:^(NSURL * _Nonnull localUrl, NSURL * _Nonnull remoteUrl, NSError * _Nullable error) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (error) {
            LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXVideoErrorEvent targetSign:[strongSelf sign] detail:@{@"error" : error.localizedDescription ? : @""}];
            [strongSelf.context.eventEmitter sendCustomEvent:event];
        }
        if (completionHandler) {
            completionHandler(localUrl, remoteUrl, error);
        }
    }];
}

- (void)didStateChange:(NSDictionary *)info {
  LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXVideoStateChangeEvent targetSign:[self sign] detail:info];
  [self.context.eventEmitter sendCustomEvent:event];
}

- (void)onListCellAppear:(NSString *)itemKey withList:(LynxUICollection *)list {
  self.hidden = NO;
}

- (void)onListCellDisappear:(NSString *)itemKey exist:(BOOL)isExist withList:(LynxUICollection *)list {
  self.hidden = YES;
  [self.view pause];
}

- (void)onListCellPrepareForReuse:(NSString *)itemKey withList:(LynxUICollection *)list {
  self.hidden = NO;
}

@end
