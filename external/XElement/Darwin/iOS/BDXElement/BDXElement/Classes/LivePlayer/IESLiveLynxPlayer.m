//
//  IESLiveLynxPlayer.m
//  BDXElement
//
//  Created by chenweiwei.luna on 2020/10/13.
//

#import "IESLiveLynxPlayer.h"
#import <Lynx/LynxUI.h>
#import <Lynx/LynxRootUI.h>
#import "IESLiveLynxPlayerView.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import "BDXElementAdapter.h"

NSString * const IESLivePlayerEventPlay = @"play";
NSString * const IESLivePlayerEventPause = @"pause";
NSString * const IESLivePlayerEventEnded = @"ended";
NSString * const IESLivePlayerEventError = @"error";
NSString * const IESLivePlayerEventFrozen = @"frozen";
NSString * const IESLivePlayerEventResume = @"resume";
NSString * const IESLivePlayerEventSEI = @"sei";

@interface IESLiveLynxPlayer () <IESLiveLynxPlayerDelegate>
@property(nonatomic, assign) BOOL hidden;
@property(nonatomic, copy) NSDictionary *logExtraDict; // 前端透传的埋点字段
@end

@implementation IESLiveLynxPlayer

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-live")
#else
LYNX_REGISTER_UI("x-live")
#endif

- (UIView *)createView {
    IESLiveLynxPlayerView *player = [[IESLiveLynxPlayerView alloc] initWithDelegate:self];
    [player setTranslatesAutoresizingMaskIntoConstraints:YES];
    return player;
}

#pragma mark - props

LYNX_PROP_SETTER("streamData", streamData, NSString *)
{
    if ([value isKindOfClass:[NSString class]] && !BTD_isEmptyString(value)) {
        _streamData = value;
        [self.view reloadWithStreamData:value defaultSDKKey:_qualities];
        [self __reportLog:@"x-live_streamData" reportParam:nil];
    }
}

LYNX_PROP_SETTER("stream-data", stream_data, NSString *)
{
    [self streamData:value requestReset:requestReset];
}

LYNX_PROP_SETTER("mute", mute, BOOL)
{
    _mute = value;
    self.view.mute = value;
}

LYNX_PROP_SETTER("volume", volume, NSNumber *)
{
    if (value < 0) return;
    _volume = value;
    self.view.volume = MIN([value floatValue], 1);
}

LYNX_PROP_SETTER("poster", posterURL, NSString *)
{
    if (value && !BTD_isEmptyString(value)) {
        _posterURL = value;
        self.view.posterURL = value;
    }
}

LYNX_PROP_SETTER("objectfit", fitMode, NSString *)
{
    _fitMode = value;
    self.view.fitMode = value;
}

LYNX_PROP_SETTER("autoplay", autoPlay, BOOL)
{
    _autoPlay = value;
    self.view.autoPlay = value;
    [self __reportLog:@"x-live_autoplay" reportParam:nil];
}

LYNX_PROP_SETTER("bgplay", bgPlay, BOOL)
{
    _bgPlay = value;
    self.view.enableBGPlay = value;
    [self __reportLog:@"x-live_bgplay" reportParam:nil];
}

LYNX_PROP_SETTER("qualities", qualities, NSString *)
{
    //判= return
    if ([_qualities isEqualToString:value]) {
        return;
    }
    _qualities = value;
    
    //没有streamData赋值时
    if (BTD_isEmptyString(_streamData)) {
        return;
    }
    [self.view updateVideoQuality:value];
    [self __reportLog:@"x-live_qualities" reportParam:@{@"qualities": value}];
}

LYNX_PROP_SETTER("logextra", logExtraDict, NSDictionary *) {
    if (![value isKindOfClass:[NSDictionary class]] || ![value count]) {
        return;
    }
    
    self.logExtraDict = value;
}

#pragma mark - method

LYNX_UI_METHOD(play) {
    if (self.hidden) {
      return;
    }
    [self.view play];
    [self __reportLog:@"x-live_play" reportParam:nil];
}

LYNX_UI_METHOD(pause) {
    [self.view pause];
    [self __reportLog:@"x-live_pause" reportParam:nil];
}

LYNX_UI_METHOD(stop) {
    [self.view stop];
    [self __reportLog:@"x-live_stop" reportParam:nil];
}

#pragma mark -

- (void)didPlay
{
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:IESLivePlayerEventPlay targetSign:[self sign] detail:@{}];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)didPause
{
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:IESLivePlayerEventPause targetSign:[self sign] detail:@{}];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)didStop
{
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:IESLivePlayerEventEnded targetSign:[self sign] detail:@{}];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)didError:(NSDictionary *)errorDic
{
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:IESLivePlayerEventError targetSign:[self sign] detail:errorDic];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)didStall
{
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:IESLivePlayerEventFrozen targetSign:[self sign] detail:@{}];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)didResume
{
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:IESLivePlayerEventResume targetSign:[self sign] detail:@{}];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)didReceiveSEI:(NSDictionary *)info
{
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:IESLivePlayerEventSEI targetSign:[self sign] detail:info];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)reportLivePlayerLog:(NSString *)url reportParams:(NSDictionary *)reportParam {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:reportParam];
    if (self.logExtraDict) {
        [params addEntriesFromDictionary:self.logExtraDict];
    }
    
    NSString *logType = reportParam[@"log_type"] ?: @"live_client_monitor_log";
    
    [self __reportLog:logType reportParam:params.copy];
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

#pragma mark - private

- (void)__reportLog:(NSString *)eventName reportParam:(NSDictionary *)params {
    id<BDXElementMonitorDelegate> reportDelegate = [BDXElementAdapter sharedInstance].monitorDelegate;
    if (![reportDelegate respondsToSelector:@selector(reportWithEventName:lynxView:metric:category:extra:)]) {
        return;
    }
    
    [reportDelegate reportWithEventName:eventName
                               lynxView:self.context.rootUI.lynxView
                                 metric:nil
                               category:params
                                  extra:nil];
}

@end
