//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "BDXLynxLiveLight.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxCustomMeasureShadowNode.h>
#import <Lynx/LynxNativeLayoutNode.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/UIView+Lynx.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import <Lynx/LynxUI+Internal.h>
#import <Lynx/LynxEventHandler.h>
#import <Lynx/LynxTouchHandler.h>
#import <Lynx/LynxRootUI.h>
#import <IESLivePlayer/IESLivePlayerManager.h>
#import <IESLivePlayer/IESLivePlayerLynxController.h>
#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import "BDXElementAdapter.h"

// If you see this, it means i forget to do something. Disapprove it.
#define X_LIVE_NG_DEFAULT_ROOM_ID 233
#define X_LIVE_NG_DEFAULT_TAG @"x-live-ng"


@protocol BDLynxLiveLightContainerDelegate <NSObject>

- (UIView *)innerView;

@end

@interface BDLynxLiveLightContainer : UIView

@property (nonatomic, weak) id<BDLynxLiveLightContainerDelegate> uiDelegate;

@end

@implementation BDLynxLiveLightContainer

- (void)setFrame:(CGRect)frame {
  [super setFrame:frame];
  [self checkPlayer];
}

- (void)checkPlayer {
  if (self.uiDelegate.innerView.superview != self) {
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
      [obj removeFromSuperview];
    }];
    [self addSubview:self.uiDelegate.innerView];
  }
  self.uiDelegate.innerView.frame = self.bounds;
}

@end

/**
 * BDXLynxLiveLight is basically a wrapper of IESLivePlayer.
 * Notice: Some props of IESLivePlayer can responds to the changes dynamically, but some others are not, such as volume. 
 */

@interface BDXLynxLiveLight () <IESLivePlayerControllerDelegate, BDLynxLiveLightContainerDelegate>
@property (nonatomic, strong) IESLivePlayerLynxController *innerPlayer;
//@property (nonatomic, assign) BOOL propsMute;
//@property (nonatomic, strong) NSString *propsQualities;
@property (nonatomic, strong) IESLivePlayerControllerConfig *liveConfig;

// A flag marks whether qualities should be set to IESLivePlayer
@property (nonatomic, assign) BOOL hiddenInList;
@property (nonatomic, assign) BOOL inListOpt;
@property (nonatomic, strong) NSDictionary *logExtra;
@end

@implementation BDXLynxLiveLight

LYNX_REGISTER_UI("x-live-ng")

- (instancetype)init {
  if (self = [super init]) {
  }
  return self;
}


#pragma mark - LynxUI

- (UIView *)createView {
  BDLynxLiveLightContainer *container = [[BDLynxLiveLightContainer alloc] init];
  container.uiDelegate = self;
  return container;
}


#pragma mark - LYNX_PROPS


/**
 * @name: stream-data
 * @description: Live stream data
 * @category: standardized
 * @standardAction: keep
 * @supportVersion: 2.9
**/
LYNX_PROP_SETTER("stream-data", stream_data, NSString *) {
  self.liveConfig.streamData = value;
}


/**
 * @name: mute
 * @description: Live player should muted.
 * @category: standardized
 * @standardAction: keep
 * @supportVersion: 2.9
**/
LYNX_PROP_SETTER("mute", volume, BOOL) {
  self.liveConfig.muted = value;
  [self.innerPlayer setMuted:value];
}

/**
 * @name: objectfit
 * @description: Live player scale mode. [contain | cover | fill]
 * @category: standardized
 * @enum: contain | cover | fill
 * @standardAction: keep
 * @supportVersion: 2.9
**/
LYNX_PROP_SETTER("objectfit", fitMode, NSString *) {
  if ([value isEqualToString:@"contain"]) {
    self.liveConfig.scaleType = IESLivePlayerScaleTypeAspectFit;
    [self.innerPlayer setScaleType:IESLivePlayerScaleTypeAspectFit];
  } else if ([value isEqualToString:@"cover"]) {
    self.liveConfig.scaleType = IESLivePlayerScaleTypeAspectFill;
    [self.innerPlayer setScaleType:IESLivePlayerScaleTypeAspectFill];
  } else if ([value isEqualToString:@"fill"]) {
    self.liveConfig.scaleType = IESLivePlayerScaleTypeScaleFill;
    [self.innerPlayer setScaleType:IESLivePlayerScaleTypeScaleFill];
  }
}

/**
 * @name: qualities
 * @description: Live stream qualities. [origin | hd | ld | sd | uhd]
 * @category: standardized
 * @enum: origin | hd | ld | sd | uhd
 * @standardAction: keep
 * @supportVersion: 2.9
**/
LYNX_PROP_SETTER("qualities", qualities, NSString *) {
  if (![value isEqualToString:self.liveConfig.sdkKey]) {
    self.liveConfig.sdkKey = value;
    [self.innerPlayer updateSDKKey:value];
  }
}

/**
 * @name: room-id
 * @description: Room id for live stream.
 * @category: standardized
 * @standardAction: keep
 * @supportVersion: 2.9
**/
LYNX_PROP_SETTER("room-id", roomID, NSString *) {
  self.liveConfig.roomID = @(value.integerValue);
}

/**
 * @name: biz-domain
 * @description: Biz domain for live player. For statistics.
 * @category: standardized
 * @standardAction: keep
 * @supportVersion: 2.9
**/
LYNX_PROP_SETTER("biz-domain", bizDomain, NSString *) {
  self.liveConfig.trackerConfig.stainedTrackInfo.bizDomain = value;
}

/**
 * @name: page
 * @description: Page for live player. For statistics.
 * @category: standardized
 * @standardAction: keep
 * @supportVersion: 2.9
**/
LYNX_PROP_SETTER("page", page, NSString *) {
  self.liveConfig.trackerConfig.stainedTrackInfo.pageName = value;
}

/**
 * @name: block
 * @description: Block for live player. For statistics.
 * @category: standardized
 * @standardAction: keep
 * @supportVersion: 2.9
**/
LYNX_PROP_SETTER("block", block, NSString *) {
  self.liveConfig.trackerConfig.stainedTrackInfo.blockName = value;
}

/**
 * @name: index
 * @description: Index for live player. For statistics.
 * @category: standardized
 * @standardAction: keep
 * @supportVersion: 2.9
**/
LYNX_PROP_SETTER("index", index, NSString *) {
  self.liveConfig.trackerConfig.stainedTrackInfo.index = value;
}

/**
 * While a x-live-ng is in list, the view may be detached from window but being restored in list's reuse pool.
 * In this situation, the x-live-ng instance can not be operated such as stop or muted normally.
 * So, in list, after a cell end displaying, we forcibly close the live stream, and further play actions are not allowed until the cell will display again.
 */
/**
 * @name: in-list
 * @description: If live player is in a list.
 * @category: standardized
 * @standardAction: keep
 * @supportVersion: 2.9
**/
LYNX_PROP_SETTER("in-list", inList, BOOL) {
  self.inListOpt = value;
}



#pragma mark - LYNX_UI_METHOD


/**
 * @name: play
 * @description: Invoke play method on the LivePlayer
 * @category: standardized
 * @standardAction: keep
 * @supportVersion: 2.9
**/
LYNX_UI_METHOD(play) {
  if (self.hiddenInList) {
    if (callback) {
      callback(kUIMethodUnknown, @{@"msg" : @"hidden in list"});
    }
    return;
  }
  [((BDLynxLiveLightContainer *)(self.view)) checkPlayer];
  [self.innerPlayer updateSDKKey:self.liveConfig.sdkKey];
  [self.innerPlayer setMuted:self.liveConfig.muted];
  [self.innerPlayer setScaleType:self.liveConfig.scaleType];
  [self.innerPlayer reloadWithStreamData];
  if ([[BDXElementAdapter sharedInstance].liveDelegate respondsToSelector:@selector(xlive:didPlay:)]) {
    [[BDXElementAdapter sharedInstance].liveDelegate xlive:[NSString stringWithFormat:@"%ld_%ld", self.sign, (uintptr_t)_innerPlayer] didPlay:self.logExtra];
  }
  if (callback) {
    callback(kUIMethodSuccess, nil);
  }
}

/**
 * @name: stop
 * @description: Invoke stop method on the LivePlayer
 * @category: standardized
 * @standardAction: keep
 * @supportVersion: 2.9
**/
LYNX_UI_METHOD(stop) {
  [self.innerPlayer stop];
  if (callback) {
    callback(kUIMethodSuccess, nil);
  }
  if ([[BDXElementAdapter sharedInstance].liveDelegate respondsToSelector:@selector(xlive:didStop:)]) {
    [[BDXElementAdapter sharedInstance].liveDelegate xlive:[NSString stringWithFormat:@"%ld_%ld", self.sign, (uintptr_t)_innerPlayer] didStop:self.logExtra];
  }
}

LYNX_UI_METHOD(stopAudioRendering) {
  if ([self.innerPlayer respondsToSelector:@selector(stopAudioRendering)]) {
    [self.innerPlayer performSelector:@selector(stopAudioRendering)];
    callback(kUIMethodSuccess, nil);
  } else {
    callback(kUIMethodUnknown, @"please implement @selector(stopAudioRendering) in your App");
  }
}

LYNX_UI_METHOD(startAudioRendering) {
  if ([self.innerPlayer respondsToSelector:@selector(startAudioRendering)]) {
    [self.innerPlayer performSelector:@selector(startAudioRendering)];
    callback(kUIMethodSuccess, nil);
  } else {
    callback(kUIMethodUnknown, @"please implement @selector(startAudioRendering) in your App");
  }
}

LYNX_UI_METHOD(iosShare) {
  self.liveConfig.prepareForReuse = YES;
  [self.innerPlayer setPrepareForReuse:YES];
  [self.innerPlayer enqueueLivePlayer];
  if (self.innerPlayer.playerView.superview == self.view) {
    [self.innerPlayer.playerView removeFromSuperview];
  }
  self.innerPlayer = nil;
  if (callback) {
    callback(kUIMethodSuccess, nil);
  }
}

/**
 * @name: enterLiveRoom
 * @description: Enter Live Room from x-live-ng directly. Notice, not all apps have this capability, please check the CHANGELOG for details.
 * @category: standardized
 * @standardAction: keep
 * @supportVersion: 2.9
**/
LYNX_UI_METHOD(enterLiveRoom) {
  id<BDXElementLivePlayerDelegate> liveDelegate = [BDXElementAdapter sharedInstance].liveDelegate;
  if ([liveDelegate respondsToSelector:@selector(xliveEnterRoom:wrapperView:)]) {
    
    self.liveConfig.prepareForReuse = YES;
    [self.innerPlayer setPrepareForReuse:YES];
    // Notice: room_id will be an int_64 value, so we need to use string in JS
    NSNumber *roomId = @([params[@"room_id"] integerValue]);
    self.liveConfig.roomID = roomId;
    [_innerPlayer enqueueLivePlayer];
    
    [liveDelegate xliveEnterRoom:params wrapperView:self.view];
    
    if (self.innerPlayer.playerView.superview == self.view) {
      [self.innerPlayer.playerView removeFromSuperview];
    }
    _innerPlayer = nil;
    
    if (callback) {
      callback(kUIMethodSuccess, nil);
    }
  } else {
    if (callback) {
      callback(kUIMethodUnknown, @"please implement [BDXElementLivePlayerDelegate xliveEnterRoom:wrapperView:] in your App");
    }
  }
}


#pragma mark - IESLivePlayerControllerDelegate

- (void)player:(id<IESLivePlayerProtocol>)player loadStateDidChange:(IESLivePlayerLoadState)loadState {
  switch (loadState) {
    case IESLivePlayerLoadStateFirstFrame: 
      [self sendEvent:@"firstframe" detail:nil];
      break;
    case IESLivePlayerLoadStateFinishPlay: 
      [self sendEvent:@"ended" detail:nil];
      break;
    case IESLivePlayerLoadStatePlayError: 
      [self sendEvent:@"error" detail:@{
        @"msg" : @"load state error"
      }];
      break;
    case IESLivePlayerLoadStateReadyToPlay: 
      [self sendEvent:@"ready" detail:nil];
      break;
    default:
      break;
  }
  if ([[BDXElementAdapter sharedInstance].liveDelegate respondsToSelector:@selector(xlive:loadStateDidChange:logExtra:)]) {
    [[BDXElementAdapter sharedInstance].liveDelegate xlive:[NSString stringWithFormat:@"%ld_%ld", self.sign, (uintptr_t)_innerPlayer] loadStateDidChange:loadState logExtra:self.logExtra];
  }
  
}

- (void)player:(id<IESLivePlayerProtocol>)player playbackStateDidChange:(IESLivePlayerPlaybackState)playbackState {
  switch (playbackState) {
    case  IESLivePlayerPlaybackStateStopped: 
      [self sendEvent:@"stop" detail:nil];
      break;
    case IESLivePlayerPlaybackStatePlaying:  
      [self sendEvent:@"play" detail:nil];
      break;
    case IESLivePlayerPlaybackStatePaused:   
      [self sendEvent:@"pause" detail:nil];
      break;
    default:
      break;
  }
  
}


- (void)playerFrozen:(id<IESLivePlayerProtocol>)player { 
  [self sendEvent:@"stalled" detail:nil];
}

- (void)playerResume:(id<IESLivePlayerProtocol>)player {
  [self sendEvent:@"resume" detail:nil];
}

- (void)player:(id<IESLivePlayerProtocol>)player didReceiveError:(NSError *)error {
  [self sendEvent:@"error" detail:@{
    @"msg" : (error.description ? : @"did receive unknown error")
  }];
}


- (void)player:(id<IESLivePlayerProtocol>)player didReceiveMetaInfo:(NSDictionary *)metaInfo processed:(BOOL)processed {
  [self sendEvent:@"sei" detail:@{
    @"sei" : (metaInfo ? : @{})
  }];
}


#pragma mark - BDLynxLiveLightContainerDelegate

- (UIView *)innerView {
  return self.innerPlayer.playerView;
}

#pragma mark - Internal

- (IESLivePlayerControllerConfig *)liveConfig {
  if (!_liveConfig) {
    _liveConfig = [[IESLivePlayerControllerConfig alloc] init];
    _liveConfig.trackerConfig = [[IESLivePlayerTrackerConfig alloc] init];
    _liveConfig.trackerConfig.stainedTrackInfo = [[IESLivePlayerBizStainedTrackInfo alloc] init];
    _liveConfig.trackerConfig.stainedTrackInfo.bizDomain = X_LIVE_NG_DEFAULT_TAG;
    _liveConfig.trackerConfig.stainedTrackInfo.pageName = X_LIVE_NG_DEFAULT_TAG;
    _liveConfig.trackerConfig.stainedTrackInfo.index = X_LIVE_NG_DEFAULT_TAG;
    _liveConfig.trackerConfig.stainedTrackInfo.blockName = X_LIVE_NG_DEFAULT_TAG;
    _liveConfig.roomID = @(X_LIVE_NG_DEFAULT_ROOM_ID);
    _liveConfig.muted = YES;
    _liveConfig.scaleType = IESLivePlayerScaleTypeAspectFit;
  }
  return _liveConfig;
}

- (IESLivePlayerLynxController *)innerPlayer {
  if (!_innerPlayer) {
    _innerPlayer = [[IESLivePlayerLynxController alloc] initWithPlayerConfig:self.liveConfig];
    _innerPlayer.delegate = self;
    __weak typeof(self) weakSelf = self;
    _innerPlayer.reportStateBlock = ^(NSString *url, NSDictionary *reportParam) {
      [weakSelf reportLog:url params:reportParam];
    };
    id<BDXElementLivePlayerDelegate> liveDelegate = [BDXElementAdapter sharedInstance].liveDelegate;
    if ([liveDelegate respondsToSelector:@selector(tvlSetting)]) {
      [_innerPlayer updateTVLSettings:[liveDelegate tvlSetting]];
    }
    
    if ([liveDelegate respondsToSelector:@selector(appInfoWithLogExtra:)]) {
      _innerPlayer.appInfoFetchBlock = ^NSDictionary *{
        return [liveDelegate appInfoWithLogExtra:weakSelf.logExtra];
      };
    }
    _innerPlayer.playerView.translatesAutoresizingMaskIntoConstraints = YES;
  }
  return _innerPlayer;
}

- (void)reportLog:(NSString *)url params:(NSDictionary *)params {
  id<BDXElementLivePlayerDelegate> liveDelegate = [BDXElementAdapter sharedInstance].liveDelegate;
  if ([liveDelegate respondsToSelector:@selector(xlive:reportWithUrl:params:logExtra:)]) {
    [liveDelegate xlive:[NSString stringWithFormat:@"%ld_%ld", self.sign, (uintptr_t)_innerPlayer] reportWithUrl:url params:params logExtra:self.logExtra];
  }
}


- (void)onListCellAppear:(NSString *)itemKey withList:(LynxUICollection *)list {
  self.hiddenInList = NO;
}

- (void)onListCellDisappear:(NSString *)itemKey exist:(BOOL)isExist withList:(LynxUICollection *)list {
  if (self.inListOpt) {
    self.hiddenInList = YES;
    [self.innerPlayer stop];
  }
}

- (void)onListCellPrepareForReuse:(NSString *)itemKey withList:(LynxUICollection *)list {
  self.hiddenInList = NO;
}


- (void)sendEvent:(NSString *)name detail:(NSDictionary *)detail {
  LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:name targetSign:[self sign] detail:detail];
  [self.context.eventEmitter sendCustomEvent:event];
}

- (void)dealloc {
  if ([[BDXElementAdapter sharedInstance].liveDelegate respondsToSelector:@selector(xlive:didDestroy:)]) {
    [[BDXElementAdapter sharedInstance].liveDelegate xlive:[NSString stringWithFormat:@"%ld_%ld", self.sign, (uintptr_t)_innerPlayer] didDestroy:self.logExtra];
  }
  [_innerPlayer close];
}

LYNX_PROPS_GROUP_DECLARE(
	LYNX_PROP_DECLARE("log-extra", setLogExtra, / type /))

/**
 * @name: log-extra
 * @description: For statistics.
 * @category: standardized
 * @standardAction: keep
 * @supportVersion: 2.9
**/
LYNX_PROP_DEFINE("log-extra", setLogExtra, NSDictionary *) {
  self.logExtra = value;
}

@end
