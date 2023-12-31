//
//  Copyright 2020 The Lynx Authors. All rights reserved.
//  BDLynxTTAudioUI.m
//  XElement-Pods-Aweme
//
//  Created by zhenglaixian on 2021/9/17.
//

#import "BDLynxTTAudioUI.h"
#import "BDXAudioDefines.h"
#import <Lynx/LynxUIMethodProcessor.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxLayoutStyle.h>
#import <Lynx/LynxRootUI.h>
#import <Lynx/LynxForegroundProtocol.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>
#import <Lynx/LynxLog.h>
#import "BDXAudioQueueModel.h"
#import "BDXAudioService.h"
#import <AVFoundation/AVFoundation.h>
#import "BDXAudioNativeIMPs.h"
#import <objc/runtime.h>
#import "BDXElementResourceManager.h"
#import "BDXElementAdapter.h"
#import "BDXElementMonitorDelegate.h"
#import "BDXAudioModelPlayer.h"
#import <TTVideoEngine/TTVideoEngine.h>


@interface BDLynxTTAudioUI()<BDXAudioModelPlayerDelegate, LynxForegroundProtocol>

@property (nonatomic, strong) BDXAudioModel *curModel;
@property (nonatomic, assign) BOOL loop;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *headers;
@property (nonatomic, assign) BOOL autoplay;
@property (nonatomic, assign) BDXAudioPlayerType playerType;
@property (nonatomic, strong) BDXAudioModelPlayer *player;
@property (nonatomic, assign) BOOL needNowPlayingInfo;
@property (nonatomic, assign) NSTimeInterval updateInterval;
@property (nonatomic, copy  ) NSString *src; //record for event upload
@property (nonatomic, assign) BOOL willReloadSrc;
@property (nonatomic, assign) BOOL needToPlayAfterResLoaded;
@property (nonatomic, assign) BOOL stopLoopAfterPlayFinished;
@property (nonatomic, assign) BDXAudioSrcLoadingState loadingState;
@property (nonatomic, assign) BOOL disappeared;
@property (nonatomic, assign) BOOL pauseOnHide;

@end

@implementation BDLynxTTAudioUI

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-audio-tt")
#else
LYNX_REGISTER_UI("x-audio-tt")
#endif

- (instancetype)init {
  if (self = [super init]) {
    self.loadingState = BDXAudioSrcLoadingStateInit;
  }
  return self;
}

- (UIView*)createView {
    BDXAudioView *view = [[BDXAudioView alloc] init];
    return view;
}

- (void)dealloc {
    [_player stop];
}

- (BDXAudioModel *)_resolveSrcAsJSON:(NSString *)jsonString {
    NSError *error = nil;
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    if (data.length == 0) {
        [self reportErrorCode:BDXAudioErrorCodeJsonError message:[NSString stringWithFormat:@"jsonString length error:%@",self.src]];
        return nil;
    }
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

    if (BTD_isEmptyDictionary(jsonDict) || error) {
        [self reportErrorCode:BDXAudioErrorCodeJsonError message:[NSString stringWithFormat:@"json to dic error:%@",self.src]];
        return nil;
    }
    return [[BDXAudioModel alloc] initWithJSONDict:jsonDict];
}


- (void)propsDidUpdate {
  [super propsDidUpdate];
  if (self.willReloadSrc) {
    self.willReloadSrc = NO;
    NSString *loadingSrc = self.src;
    if ([loadingSrc isKindOfClass:[NSString class]] && loadingSrc.length > 0) {
      self.curModel = [self _resolveSrcAsJSON:loadingSrc];
      
      [self updateLoadingState:BDXAudioSrcLoadingStateLoading
                           src:self.curModel.modelId
                     errorCode:0
                         error:nil];
      
      if (self.curModel.playUrl) {
        
        [self.player updateTag:self.curModel.playUrl];
        
        NSMutableDictionary* context = [NSMutableDictionary dictionary];
        context[BDXElementContextContainerKey] = self.context.rootUI.lynxView;
        NSURL *baseURL;
        if ([self.context.rootView isKindOfClass:[LynxView class]]) {
          baseURL = [NSURL URLWithString:[(LynxView *)self.context.rootView url]];
        }
        @weakify(self)
        id<LynxResourceFetcher> fetcher = self.context.resourceFetcher;
        if ([fetcher respondsToSelector:@selector(fetchResourceWithURL:type:completion:)]) {
          [fetcher fetchResourceWithURL:[NSURL URLWithString:self.curModel.playUrl]
                                   type:LynxFetchResURLOnlineOrOffline
                             completion:^(BOOL isSyncCallback, NSData * _Nullable data, NSError * _Nullable error, NSURL * _Nullable resURL) {
            @strongify(self)
            if ([self.src isEqualToString:loadingSrc]) {
              if (!error) {
                BOOL isLocal = [resURL isFileReferenceURL] || [resURL isFileURL];
                if (isLocal) {
                  self.curModel.localUrl = resURL.absoluteString;
                } else {
                  // set localUrl to nil, cause we will check localUrl first
                  self.curModel.localUrl = nil;
                  self.curModel.playUrl = resURL.absoluteString;
                }
                self.stopLoopAfterPlayFinished = YES;
                [self.player stop]; // stop first, then update loading event
                [self updateLoadingState:BDXAudioSrcLoadingStateSuccess
                                     src:self.curModel.modelId
                               errorCode:0
                                   error:nil];
                [self prepareAndTryToPlay];
              } else {
                [self updateLoadingState:BDXAudioSrcLoadingStateFailed
                                     src:self.curModel.modelId
                               errorCode:BDXAudioAllErrorCodeResLoaderDownloadError
                                   error:error.description];
              }
            }
          }];
        } else {
          [[BDXElementResourceManager sharedInstance] fetchFileWithURL:[NSURL URLWithString:self.curModel.playUrl] baseURL:baseURL context:[context copy] completionHandler:^(NSURL * _Nonnull localUrl, NSURL * _Nonnull remoteUrl, NSError * _Nullable error) {
            @strongify(self)
            if ([self.src isEqualToString:loadingSrc]) {
              if (!error && localUrl) {
                self.curModel.localUrl = localUrl.absoluteString;
                self.stopLoopAfterPlayFinished = YES;
                [self.player stop]; // stop first, then update loading event
                [self updateLoadingState:BDXAudioSrcLoadingStateSuccess
                                     src:self.curModel.modelId
                               errorCode:0
                                   error:nil];
                [self prepareAndTryToPlay];
              } else {
                [self updateLoadingState:BDXAudioSrcLoadingStateFailed
                                     src:self.curModel.modelId
                               errorCode:BDXAudioAllErrorCodeResLoaderDownloadError
                                   error:error.description];
              }
            }
          }];
        }
      } else if (self.curModel.playModel.encryptType == BDXAudioPlayerEncryptTypeModel) {
        self.stopLoopAfterPlayFinished = YES;
        [self.player stop]; // stop first, then update loading event
        [self updateLoadingState:BDXAudioSrcLoadingStateSuccess
                             src:self.curModel.modelId
                       errorCode:0
                           error:nil];
        [self prepareAndTryToPlay];
      } else {
        [self updateLoadingState:BDXAudioSrcLoadingStateFailed
                             src:self.curModel.modelId
                       errorCode:BDXAudioAllErrorCodeResLoaderSrcJsonError
                           error:[NSString stringWithFormat:@"src format error: %@", self.src]];
      }
    } else {
      [self updateLoadingState:BDXAudioSrcLoadingStateFailed
                           src:nil
                     errorCode:BDXAudioAllErrorCodeResLoaderSrcError
                         error:[NSString stringWithFormat:@"src error: %@", self.src]];
    }
  }
}

- (void)updateLoadingState:(BDXAudioSrcLoadingState)loadingState src:(NSString *)src errorCode:(BDXAudioAllErrorCode)errCode error:(NSString *)errStr {
  self.loadingState = loadingState;
  switch (loadingState) {
    case BDXAudioSrcLoadingStateLoading:
      [self.context.eventEmitter sendCustomEvent:
       [[LynxDetailEvent alloc] initWithName:BDXAudioSrcLoadingStateChangedEvent
                                  targetSign:[self sign]
                                      detail:@{
        @"currentSrcID": src?:@"",
        @"code" : @(BDXAudioSrcLoadingStateLoading),
        @"type" : @"loading",
       }]];
      break;
    case BDXAudioSrcLoadingStateFailed:
      [self handleError:@{
        @"currentSrcID" : src ? : @"",
        @"from" : @"res loader",
        @"code" : @(errCode),
        @"err" : errStr ? : @""
      }];
      break;
    case BDXAudioSrcLoadingStateSuccess:
      [self.context.eventEmitter sendCustomEvent:
       [[LynxDetailEvent alloc] initWithName:BDXAudioSrcLoadingStateChangedEvent
                                  targetSign:[self sign]
                                      detail:@{
        @"currentSrcID": src?:@"",
        @"code" : @(BDXAudioSrcLoadingStateSuccess),
        @"type" : @"success",
       }]];
      break;
    default:
      break;
  }
}

- (void)prepareAndTryToPlay {
                
  self.player.needNowPlayingInfo = self.needNowPlayingInfo;
  self.player.updateInterval = self.updateInterval>0.0?self.updateInterval:0.5;
  [self.player setPlayModel:self.curModel];
  if (self.autoplay || self.needToPlayAfterResLoaded) {
    self.stopLoopAfterPlayFinished = NO;
    [self play];
  } else {
    [self.player prepare];
    if (self.playerType != BDXAudioPlayerTypeDefault) {
      [self.player pause]; // pause system player， advice from TTVideoEngine
    }
  }
  self.needToPlayAfterResLoaded = NO;
    
}
  
  
- (void)play {
  if (!self.disappeared) {
    [self.player play];
  }
}
  



#pragma mark - Setter
LYNX_PROP_SETTER("src", src, NSString *) {
  if (![self.src isEqualToString:value]) {
    self.willReloadSrc = YES;
  }
    self.src = value;
}

LYNX_PROP_SETTER("loop", loop, BOOL) {
    self.loop = value;
}

LYNX_PROP_SETTER("headers", headers, NSString *) {
    if ([value isKindOfClass:[NSString class]] && value.length > 0) {
        NSData *Data = [value dataUsingEncoding:NSUTF8StringEncoding];
        self.headers = [NSJSONSerialization JSONObjectWithData:Data options:0 error:nil];
    }
}

LYNX_PROP_SETTER("needNowPlayingInfo", needNowPlayingInfo, BOOL) {
    self.needNowPlayingInfo = value;
}

LYNX_PROP_SETTER("autoplay", autoplay, BOOL) {
    self.autoplay = value;
}

LYNX_PROP_SETTER("interval", interval, NSNumber *) { // avoid toNSTimeInterval
    self.updateInterval = [value doubleValue] / 1000.0f;
}

LYNX_PROP_SETTER("player-type", player_type, NSString *) {
  [self playerType:value requestReset:requestReset];
}

LYNX_PROP_SETTER("playerType", playerType, NSString *) {
    if ([value isKindOfClass:[NSString class]] && value.length > 0) {
        if ([value isEqualToString:@"short"]) {
            self.playerType = BDXAudioPlayerTypeShort;
        }
        else if ([value isEqualToString:@"light"]){
            self.playerType = BDXAudioPlayerTypeLight;
        }
        else{
            self.playerType = BDXAudioPlayerTypeDefault;
        }
    }
}


LYNX_PROPS_GROUP_DECLARE(
  LYNX_PROP_DECLARE("pause-on-hide", setPauseOnHide, BOOL))

/**
 * @name: pause-on-hide
 * @description: pause audio when lynxview in background
 * @category: stable
 * @standardAction: align
 * @supportVersion: 3.0
**/
LYNX_PROP_DEFINE("pause-on-hide", setPauseOnHide, BOOL) {
  self.pauseOnHide = value;
}

#pragma mark - Method
LYNX_UI_METHOD(play) {
  self.stopLoopAfterPlayFinished = NO;
  if (self.loadingState == BDXAudioSrcLoadingStateLoading) {
    self.needToPlayAfterResLoaded = YES;
    !callback ?: callback(kUIMethodSuccess, @{
      @"loadingSrcID" : self.curModel.modelId ? : @""
    });
  } else if (self.loadingState == BDXAudioSrcLoadingStateSuccess) {
    [self play];
    !callback ?: callback(kUIMethodSuccess, @{
      @"currentSrcID" : self.player.curModel.modelId ? : @""
    });
  } else {
    !callback ?: callback(kUIMethodUnknown, @{
      @"currentSrcID" : self.player.curModel.modelId ? : @""
    });
  }
}

LYNX_UI_METHOD(pause) {
  self.needToPlayAfterResLoaded = NO;
  self.stopLoopAfterPlayFinished = YES;
  [self.player pause];
  !callback ?: callback(kUIMethodSuccess, @{
    @"currentSrcID" : self.player.curModel.modelId ? : @""
  });
  //    LLogInfo(@"x-audio message:%@", NSStringFromSelector(_cmd));
}

LYNX_UI_METHOD(resume) {
  self.stopLoopAfterPlayFinished = NO;
  if (self.loadingState == BDXAudioSrcLoadingStateLoading) {
    self.needToPlayAfterResLoaded = YES;
    !callback ?: callback(kUIMethodSuccess, @{
      @"loadingSrcID" : self.curModel.modelId ? : @""
    });
  } else if (self.loadingState == BDXAudioSrcLoadingStateSuccess) {
    [self.player resume];
    !callback ?: callback(kUIMethodSuccess, @{
      @"currentSrcID" : self.player.curModel.modelId ? : @""
    });
  } else {
    !callback ?: callback(kUIMethodUnknown, @{
      @"currentSrcID" : self.player.curModel.modelId ? : @""
    });
  }
}

LYNX_UI_METHOD(stop) {
  self.needToPlayAfterResLoaded = NO;
  self.stopLoopAfterPlayFinished = YES;
  [self.player stop];
  !callback ?: callback(kUIMethodSuccess, @{
    @"currentSrcID" : self.player.curModel.modelId ? : @""
  });
  //    LLogInfo(@"x-audio message:%@", NSStringFromSelector(_cmd));
}

LYNX_UI_METHOD(seek) {
  self.needToPlayAfterResLoaded = NO;
  if (self.loadingState == BDXAudioSrcLoadingStateSuccess) {
    NSTimeInterval time = [params btd_doubleValueForKey:@"currentTime"] / 1000;
    [self.player seekTo:time];
    !callback ?: callback(kUIMethodSuccess, @{
      @"currentSrcID" : self.player.curModel.modelId ? : @""
    });
  } else {
    !callback ?: callback(kUIMethodUnknown, @{
      @"currentSrcID" : self.player.curModel.modelId ? : @"",
      @"msg" : @"res not ready"
    });
  }
  
  //    LLogInfo(@"x-audio message:%@", NSStringFromSelector(_cmd));
}

LYNX_UI_METHOD(mute) {
  BOOL mute = [params btd_boolValueForKey:@"mute"];
  [self.player mute:mute];
  !callback ?: callback(kUIMethodSuccess, @{
    @"currentSrcID" : self.player.curModel.modelId ? : @""
  });
  //    LLogInfo(@"x-audio message:%@", NSStringFromSelector(_cmd));
}

//LYNX_UI_METHOD(setupRemoteCommand) {
//    [self.player setupRemoteCommand];
//    !callback ?: callback(kUIMethodSuccess, nil);
//}
//
//LYNX_UI_METHOD(clearRemoteCommand) {
//    [self.player clearRemoteCommand];
//    !callback ?: callback(kUIMethodSuccess, nil);
//}
//
//LYNX_UI_METHOD(preRemoteCommand) {
//    BOOL enable = [params btd_boolValueForKey:@"enable"];
//    [self.player preRemoteCommandEnable:enable];
//    !callback ?: callback(kUIMethodSuccess, nil);
////    LLogInfo(@"x-audio message:%@", NSStringFromSelector(_cmd));
//}
//
//LYNX_UI_METHOD(nextRemoteCommand) {
//    BOOL enable = [params btd_boolValueForKey:@"enable"];
//    [self.player nextRemoteCommandEnable:enable];
//    !callback ?: callback(kUIMethodSuccess, nil);
////    LLogInfo(@"x-audio message:%@", NSStringFromSelector(_cmd));
//}

#pragma mark - Method With Callback
LYNX_UI_METHOD(playerInfo) {
  if (callback) {
    callback(
             kUIMethodSuccess,
             @{
      @"currentSrcID" : self.player.curModel.modelId ? : @"",
      @"duration" : @(self.player.duration * 1000.0),
      @"playbackState" :  @{@"type" :  [self.player transferStatusDesByStatus:self.player.status]?:@"",
                            @"code" : @(self.player.status)
      },
      @"playBitrate" : @(self.player.playBitrate),
      @"currentTime" : @(self.player.currentTime * 1000.0),
      @"cacheTime" : @(self.player.cacheTime * 1000.0)
      
    }
             );
  }
}

LYNX_UI_METHOD(setPlayMode) {
  NSString *mode = [params objectForKey:@"mode"];

  NSString *current = [[AVAudioSession sharedInstance] category];
  
  if (current && mode) {
    [[AVAudioSession sharedInstance] setCategory:mode error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    if (callback) {
      callback(kUIMethodSuccess, @{
        @"current" : current
      });
    }
  }
}





#pragma mark - BDXAudioModelPlayerDelegate
- (void)player:(BDXAudioModelPlayer *)player loadingStateChanged:(NSInteger )ttState{
  if (ttState == TTVideoEngineLoadStateError) {
    [self handleError:@{
      @"currentSrcID" : player.curModel.modelId ? : @"",
      @"from" : @"player",
      @"code" : @(BDXAudioAllErrorCodePlayerLoadingError),
      @"err" : [self.player transferLoadStatusDesByStatus:ttState]
    }];
  } else {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXAudioLoadingStateChangedEvent targetSign:[self sign] detail:@{
      @"code": @(ttState),
      @"type": [self.player transferLoadStatusDesByStatus:ttState],
      @"currentSrcID": self.player.curModel.modelId?:@""
    }];
    [self.context.eventEmitter sendCustomEvent:event];
  }
}

- (void)player:(BDXAudioModelPlayer *)player playbackStateChanged:(NSInteger )ttState{
  if (ttState == TTVideoEnginePlaybackStateError) {
    [self handleError:@{
      @"currentSrcID" : player.curModel.modelId ? : @"",
      @"from" : @"player",
      @"code" : @(BDXAudioAllErrorCodePlayerPlaybackError),
      @"err" : [self.player transferStatusDesByStatus:ttState]
    }];
  } else {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXAudioPlaybackStateChangedEvent targetSign:[self sign] detail:@{
      @"code": @(ttState),
      @"type": [self.player transferStatusDesByStatus:ttState],
      @"currentSrcID": self.player.curModel.modelId?:@""
    }];
    [self.context.eventEmitter sendCustomEvent:event];
  }
}
- (void)player:(BDXAudioModelPlayer *)player progressChanged:(NSTimeInterval )cur{
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXAudioTimeUpdateEvent targetSign:[self sign] detail:@{
        @"currentTime": @(cur * 1000),
        @"currentSrcID": self.player.curModel.modelId?:@""
    }];
    [self.context.eventEmitter sendCustomEvent:event];
//    LLogInfo(@"x-audio message:%@", NSStringFromSelector(_cmd));
}
- (void)playerPrepared:(BDXAudioModelPlayer *)player{
//    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXAudioPreparedEvent targetSign:[self sign] detail:@{
//        @"currentSrcID": self.player.curModel.modelId?:@""
//    }];
//    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)playerDidSeeked:(BDXAudioModelPlayer *)player success:(BOOL)success {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXAudioSeekEvent targetSign:[self sign] detail:@{
        @"currentSrcID": self.player.curModel.modelId?:@"",
        @"seekresult": success ? @(1) : @(0),
    }];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)playerReadyToPlay:(BDXAudioModelPlayer *)player{
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXAudioReadyedEvent targetSign:[self sign] detail:@{
        @"currentSrcID": self.player.curModel.modelId?:@""
    }];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)playerUserStopped:(BDXAudioModelPlayer *)player{
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXAudioStopedEvent targetSign:[self sign] detail:@{
        @"currentSrcID": self.player.curModel.modelId?:@""
    }];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)playerDidFinish:(BDXAudioModelPlayer *)player error:(nullable NSError *)error{
    if (!error) {
      BOOL willLoop = self.loop && !self.stopLoopAfterPlayFinished;
        LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXAudioFinishedEvent targetSign:[self sign] detail:@{
            @"currentSrcID": self.player.curModel.modelId?:@"",
            @"loop" : @(willLoop)
        }];
        [self.context.eventEmitter sendCustomEvent:event];
        if (willLoop) {
          [self.player stop];
          [self play];
        }
    }else{
      [self handleError:@{
        @"currentSrcID" : player.curModel.modelId ? : @"",
        @"from" : @"player",
        @"code" : @(BDXAudioAllErrorCodePlayerFinishedError),
        @"err" : error.description ? : @""
      }];
      [self reportErrorCode:BDXAudioErrorCodePlayError message:[NSString stringWithFormat:@"%@ play fail; errorCode:%@, description:%@",player.curModel.modelId ? : @"",  @(error.code), error.localizedDescription]];
    }
}

- (void)playerDidTapPreRemoteCommand:(BDXAudioModelPlayer *)player{
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXAudioPreRemoteCommandEvent targetSign:[self sign] detail:@{
        @"currentSrcID": self.player.curModel.modelId?:@""
    }];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)playerDidTapNextRemoteCommand:(BDXAudioModelPlayer *)player{
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXAudioNextRemoteCommandEvent targetSign:[self sign] detail:@{
        @"currentSrcID": self.player.curModel.modelId?:@""
    }];
    [self.context.eventEmitter sendCustomEvent:event];
}


- (void)handleError:(NSDictionary *)detail {
  LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXAudioErrorEvent targetSign:[self sign] detail:detail];
  [self.context.eventEmitter sendCustomEvent:event];
  [self reportErrorCode:BDXAudioErrorCodeOtherError message:[NSString stringWithFormat:@"id:%@ from:%@ code:%@ err:%@", detail[@"currentSrcID"], detail[@"from"], detail[@"code"], detail[@"err"]]];
}

#pragma mark - Report
- (NSMutableDictionary*)reportCommonParams {
    NSMutableDictionary* params = [NSMutableDictionary dictionary];
    params[@"playerType"] = @(self.playerType);
    params[@"autoPlay"] = @(self.autoplay);
    params[@"src"] = self.src;
    return params;
}

- (void)reportErrorCode:(BDXAudioErrorCode)code message:(NSString *)message {
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithDictionary:[self reportCommonParams]];
    params[@"code"] = @(code);
    params[@"msg"] = message;
    params[@"eventName"] = @"x_audio_error";
    LLogError(@"BDLynxTTAudioUI reportErrorCode: code: %@, params: %@", @(code), params);

    id<BDXElementMonitorDelegate> delegate = BDXElementAdapter.sharedInstance.monitorDelegate;
    if ([delegate respondsToSelector:@selector(reportWithEventName:lynxView:metric:category:extra:)]) {
        [delegate reportWithEventName:@"x_audio_error"
                             lynxView:self.context.rootUI.lynxView
                               metric:nil
                             category:params
                                extra:nil];
    }

//    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXAudioErrorEvent targetSign:[self sign] detail:@{
//        @"currentSrcID": self.player.curModel.modelId?:@"",
//        @"msg": message?:@"",
//        @"code": @(code)
//    }];
//    [self.context.eventEmitter sendCustomEvent:event];

}

#pragma mark - getters
- (BDXAudioModelPlayer *)player{
    if (!_player) {
        _player = [[BDXAudioModelPlayer alloc]initWithPlayerType:self.playerType];
        _player.delegate = self;
        [_player setHeaders:self.headers];
    }
    return _player;
}


- (void)onListCellAppear:(NSString *)itemKey withList:(LynxUICollection *)list {
  self.disappeared = NO;
}

- (void)onListCellDisappear:(NSString *)itemKey exist:(BOOL)isExist withList:(LynxUICollection *)list {
  self.disappeared = YES;
  [self.player pause];
}

- (void)onListCellPrepareForReuse:(NSString *)itemKey withList:(LynxUICollection *)list {
  self.disappeared = NO;
}

- (void)onEnterBackground {
  if(_pauseOnHide) {
    [self pause:nil withResult:nil];
  }
}

- (void)onEnterForeground {
  
}
@end
