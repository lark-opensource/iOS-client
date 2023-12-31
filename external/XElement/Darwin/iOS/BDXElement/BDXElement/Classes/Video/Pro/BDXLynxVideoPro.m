//
//  BDXLynxVideoPro.m
//
// Copyright 2022 The Lynx Authors. All rights reserved.
//

#import "BDXLynxVideoPro.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import <Lynx/UIView+Lynx.h>
#import <Lynx/LynxRootUI.h>
#import <Lynx/LynxUnitUtils.h>
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSURL+BTDAdditions.h>
#import <Lynx/LynxView.h>
#import "BDXElementResourceManager.h"
#import "BDXLynxVideoPlayerPro.h"
#import "BDXLynxVideoProInterface.h"
#import "BDXPixelBufferTransformer.h"
#import "BDXLynxVideoProFullScreen.h"

typedef NS_ENUM(NSUInteger, BDXLynxVideoProStatus) {
  BDXLynxVideoProStatusInit = 0,
  BDXLynxVideoProStatusCreate,
  BDXLynxVideoProStatusReady,
  BDXLynxVideoProStatusPlaying,
  BDXLynxVideoProStatusStop,
};


@interface BDXLynxVideoPro () <BDXLynxVideoProUIProtocol>

@property (nonatomic, assign) BOOL renderByMetal;

@property (nonatomic, assign) BOOL asyncClose;

@property (nonatomic, assign) BDXLynxVideoProStatus status;

@property (nonatomic, strong) BDXLynxVideoProModel *propsModel;

@property (nonatomic, strong) BDXLynxVideoPlayerPro *player;

@property (nonatomic, strong) BDXLynxVideoProFullScreen *fullScreen;

@end

@implementation BDXLynxVideoPro

- (instancetype)init {
  if (self = [super init]) {
    _renderByMetal = YES;
    _asyncClose = YES;
    _propsModel = [[BDXLynxVideoProModel alloc] init];
    _propsModel.propsAutoplay = NO;
    _propsModel.propsLoop = NO;
    _propsModel.propsInitTime = 0;
    _propsModel.propsRate = 1000 / 6;
    _propsModel.propsAutoLifeCycle = NO;
    _propsModel.initMuted = NO;
    _propsModel.objectfit = @"contain";
  }
  return self;
}

#pragma mark - LynxUI

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-video-pro")
#else
LYNX_REGISTER_UI("x-video-pro")
#endif


- (UIView *)createView {
  self.player = [[BDXLynxVideoPlayerPro alloc] init];
  self.player.uiDelegate = self;
  self.player.backgroundColor = [UIColor blackColor];
  [self.player setTranslatesAutoresizingMaskIntoConstraints:YES];
  UIView *container = [[UIView alloc] init];
  [container addSubview:self.player];
  return container;
}

- (void)layoutDidFinished {
  [super layoutDidFinished];
  self.player.frame = self.view.bounds;
}

- (void)propsDidUpdate {
  [super propsDidUpdate];
  if (self.status == BDXLynxVideoProStatusInit) {
    
    self.player.renderByMetal = self.renderByMetal;
    self.player.asyncClose = self.asyncClose;
    
    BDXLynxVideoProModel *playingModel = [self resolveSrcAsJSON:self.propsModel.propsSrc];
    if (!playingModel) {
      playingModel = [self resolveSrcAsSchema:self.propsModel.propsSrc];
    }
    if (!playingModel) {
      playingModel = [self resolveSrcAsUrl:self.propsModel.propsSrc];
    }
    if (playingModel) {
      self.status = BDXLynxVideoProStatusCreate;
      [self.player setPlayingModel:playingModel];
    } else {
      [self didError:@(1) msg:@"can not resolve src" url:self.propsModel.propsSrc];
    }
  }
}

#pragma mark - LYNX_PROPS

LYNX_PROP_SETTER("src", setSrc, NSString *) {
  if ([value isKindOfClass:[NSString class]]) {
    if (![value isEqualToString:self.propsModel.propsSrc]) {
      self.status = BDXLynxVideoProStatusInit;
    }
    self.propsModel.propsSrc = value;
  } else {
    @throw [NSException exceptionWithName:@"x-video-pro"
                                   reason:@"src must be a string"
                                 userInfo:nil];
  }
}



LYNX_PROP_SETTER("poster", posterURL, NSString *) {
  if ([value isKindOfClass:[NSString class]]) {
    self.propsModel.propsPoster = value;
  }
}

LYNX_PROP_SETTER("objectfit", setObjectfit, NSString *) {
  self.propsModel.objectfit = value;
}

LYNX_PROP_SETTER("autoplay", setAutoPlay, BOOL) {
  self.propsModel.propsAutoplay = value;
}

LYNX_PROP_SETTER("loop", setLoop, BOOL) {
  self.propsModel.propsLoop = value;
}

LYNX_PROP_SETTER("inittime", setInittime, NSNumber *) {
  self.propsModel.propsInitTime = [value floatValue] / 1000.0;
}


LYNX_PROP_SETTER("rate", setRate, int) {
  self.propsModel.propsRate = value;
}


LYNX_PROP_SETTER("autolifecycle", setAutoLifeCycle,  BOOL) {
  self.propsModel.propsAutoLifeCycle = value;
}

LYNX_PROP_SETTER("video-tag", setTag,  NSString *) {
  self.propsModel.propsTag = value;
}


LYNX_PROP_SETTER("muted", setMuted,  BOOL) {
  self.propsModel.initMuted = value;
  [self.player mute:value];
}

LYNX_PROP_SETTER("preload-key", setPreloadKey,  NSString *) {
  self.propsModel.preloadKey = value;
}


LYNX_PROP_SETTER("__control", control, NSString *) {
  [self controlPlayerWithCommand:value];
}

LYNX_PROP_SETTER("ios_create_engine_everytime", createEngineEverytime, BOOL) {
  self.player.createEngineEveryTime = value;
}

LYNX_PROP_SETTER("header", setHeader, NSString *) {
  if ([value isKindOfClass:[NSString class]] && value.length > 0) {
      NSData *Data = [value dataUsingEncoding:NSUTF8StringEncoding];
      self.propsModel.header = [NSJSONSerialization JSONObjectWithData:Data options:0 error:nil];
  }
}

- (void)controlPlayerWithCommand:(NSString *)command {
  if (![self controllable]) {
    return;
  }
  if (!command || BTD_isEmptyString(command) || [command isKindOfClass:[NSNull class]]) return;
  NSArray<NSString *> *controlComponents = [command componentsSeparatedByString:@"_*_"];
  if (controlComponents.count == 3) {
    NSString *action = controlComponents[0];
    NSString *params = controlComponents[1];
    NSDictionary *paramsDict =
        [NSJSONSerialization JSONObjectWithData:[params dataUsingEncoding:NSUTF8StringEncoding]
                                        options:NSJSONReadingMutableContainers
                                          error:NULL];
    if ([action isEqualToString:@"play"]) {
      [self.player play];
    } else if ([action isEqualToString:@"pause"]) {
      [self.player pause];
    } else if ([action isEqualToString:@"stop"]) {
      [self.player stop];
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
        if (!shouldPlay) {
          [self.player pause];
        }
        __weak __typeof(self) weakSelf = self;
        [self.player seek:position / 1000.0
               completion:^(BOOL success) {
          
          [weakSelf playerDidSeek:@{
            @"success" : @(success)
          }];
          
          if (shouldPlay) {
            [weakSelf.player play];
          }
        }];
      }
    } else if ([action isEqualToString:@"requestfullscreen"]) {
      [self zoom];
    } else if ([action isEqualToString:@"exitfullscreen"]) {
      [self dismiss];
    }
  }
}


#pragma mark - LYNX_UI_METHOD
LYNX_UI_METHOD(play) {
  if (![self controllable]) {
    if (callback) {
      callback(kUIMethodUnknown,
               @{@"msg" :     [NSString stringWithFormat:@"state error: %@", @(self.status)]});
    }
    return;
  }
  
  NSString *msg = nil;
  
  switch (self.status) {
    case BDXLynxVideoProStatusReady:
      [self.player play];
      break;
    case BDXLynxVideoProStatusPlaying:
      msg = @"already play";
      break;
    case BDXLynxVideoProStatusStop:
      [self.player play];
      break;
    default:
      break;
  }
  if (callback) {
    callback(kUIMethodSuccess, msg ? @{@"msg" : msg} : nil);
  }
}

LYNX_UI_METHOD(pause) {
  if (![self controllable]) {
    if (callback) {
      callback(kUIMethodUnknown,
               @{@"msg" :     [NSString stringWithFormat:@"state error: %@", @(self.status)]});
    }
    return;
  }
  
  NSString *msg = nil;
  
  switch (self.status) {
    case BDXLynxVideoProStatusReady:
      msg = @"just ready";
      break;
    case BDXLynxVideoProStatusPlaying:
      [self.player pause];
      break;
    case BDXLynxVideoProStatusStop:
    // We should pause it again, because we don't know whether we are stopped by a loop-finish callback from TTVideoEngine
      [self.player pause];
      msg = @"already pause";
      break;
    default:
      break;
  }
  if (callback) {
    callback(kUIMethodSuccess, msg ? @{@"msg" : msg} : nil);
  }
}

LYNX_UI_METHOD(stop) {
  if (![self controllable]) {
    if (callback) {
      callback(kUIMethodUnknown,
               @{@"msg" :     [NSString stringWithFormat:@"state error: %@", @(self.status)]});
    }
    return;
  }
  
  NSString *msg = nil;
  
  switch (self.status) {
    case BDXLynxVideoProStatusReady:
      msg = @"just ready";
      break;
    case BDXLynxVideoProStatusPlaying:
    case BDXLynxVideoProStatusStop:
      [self.player stop];
      break;
    default:
      break;
  }
  if (callback) {
    callback(kUIMethodSuccess, msg ? @{@"msg" : msg} : nil);
  }
}

LYNX_UI_METHOD(seek) {
  if (![self controllable]) {
    if (callback) {
      callback(kUIMethodUnknown,
               @{@"msg" :     [NSString stringWithFormat:@"state error: %@", @(self.status)]});
    }
    return;
  }
  
  
  double time = [params[@"position"] doubleValue];
  BOOL play = NO;
  if (params[@"play"]) {
    play = [params[@"play"] boolValue];
  }
  
  __weak __typeof(self) weakSelf = self;
  
  if (!play) {
    [self.player pause];
  }

  [self.player seek:time / 1000.0
             completion:^(BOOL success) {
    if (success) {
      [weakSelf playerDidSeek:@{
        @"success" : @(success),
      }];
    }
    
    if (play) {
      [weakSelf.player play];
    }
    
  }];
  
  if (callback) {
    callback(kUIMethodSuccess, nil);
  }
  
}


LYNX_UI_METHOD(requestFullScreen) {
  if (self.fullScreen) {
    callback(kUIMethodUnknown, @{@"msg" : @"already in full screen"});
  } else {
    [self zoom];
    if (callback) {
      callback(kUIMethodSuccess, nil);
    }
  }
}

LYNX_UI_METHOD(exitFullScreen) {
  if (!self.fullScreen) {
    callback(kUIMethodUnknown, @{@"msg" : @"not in full screen"});
  } else {
    [self dismiss];
    if (callback) {
      callback(kUIMethodSuccess, nil);
    }
  }
}



#pragma mark - BDXLynxVideoProUIProtocol

- (void)markPlay {
  if ([self controllable]) {
    self.status = BDXLynxVideoProStatusPlaying;
  }
}

- (void)markStop {
  if ([self controllable]) {
    self.status = BDXLynxVideoProStatusStop;
  }
}

- (void)markReady {
  if (self.status == BDXLynxVideoProStatusCreate) {
    self.status = BDXLynxVideoProStatusReady;
  }
}

- (void)playerDidHitCache:(NSDictionary *)params {
  [self.context.eventEmitter sendCustomEvent:[[LynxDetailEvent alloc] initWithName:@"videoinfos"
                                                                        targetSign:[self sign]
                                                                            detail:params]];
}

- (void)playerDidPlay:(NSDictionary *)params {
  if ([self controllable]) {
    self.status = BDXLynxVideoProStatusPlaying;
    [self.context.eventEmitter sendCustomEvent:[[LynxDetailEvent alloc] initWithName:@"play"
                                                                          targetSign:[self sign]
                                                                              detail:params]];
  }
}

- (void)playerDidLoopStop:(NSDictionary *)params {
  if ([self controllable]) {
    self.status = BDXLynxVideoProStatusStop;
    [self.context.eventEmitter sendCustomEvent:[[LynxDetailEvent alloc] initWithName:@"loopended"
                                                                          targetSign:[self sign]
                                                                              detail:params]];
  }
}

- (void)playerDidStop:(NSDictionary *)params {
  if ([self controllable]) {
    self.status = BDXLynxVideoProStatusStop;
    [self.context.eventEmitter sendCustomEvent:[[LynxDetailEvent alloc] initWithName:@"ended"
                                                                          targetSign:[self sign]
                                                                              detail:params]];
  }
}

- (void)playerDidPause:(NSDictionary *)params {
  if ([self controllable]) {
    self.status = BDXLynxVideoProStatusStop;
    [self.context.eventEmitter sendCustomEvent:[[LynxDetailEvent alloc] initWithName:@"pause"
                                                                          targetSign:[self sign]
                                                                              detail:params]];
  }
}


- (void)playerDidReady:(NSDictionary *)params {
  [self.context.eventEmitter sendCustomEvent:[[LynxDetailEvent alloc] initWithName:@"ready"
                                                                        targetSign:[self sign]
                                                                            detail:params]];
}

- (void)playerBuffering:(NSDictionary *)params {
  [self.context.eventEmitter sendCustomEvent:[[LynxDetailEvent alloc] initWithName:@"bufferingchange"
                                                                        targetSign:[self sign]
                                                                            detail:params]];
}

- (void)playerDidTimeUpdate:(NSDictionary *)params {
  [self.context.eventEmitter sendCustomEvent:[[LynxDetailEvent alloc] initWithName:@"timeupdate"
                                                                        targetSign:[self sign]
                                                                            detail:params]];
}

- (void)playerDidSeek:(NSDictionary *)params {
  [self.context.eventEmitter sendCustomEvent:[[LynxDetailEvent alloc] initWithName:@"seek"
                                                                        targetSign:[self sign]
                                                                            detail:params]];
}

- (void)didFullScreenChanged:(NSDictionary *)params {
  [self.context.eventEmitter sendCustomEvent:[[LynxDetailEvent alloc] initWithName:@"fullscreenchange"
                                                                        targetSign:[self sign]
                                                                            detail:params]];
}

- (void)playerDidRenderFirstFrame:(NSDictionary *)params {
  [self.context.eventEmitter sendCustomEvent:[[LynxDetailEvent alloc] initWithName:@"firstframe"
                                                                        targetSign:[self sign]
                                                                            detail:params]];
}


- (void)didError:(NSNumber *)errCode msg:(NSString *)errMsg url:(NSString *)url {
  [self.context.eventEmitter sendCustomEvent:[[LynxDetailEvent alloc] initWithName:@"error"
                                                                        targetSign:[self sign]
                                                                            detail:@{
    @"errorCode" : (errCode ? : @(-2333)),
    @"errorMsg" : (errMsg ? : @"unknown"),
    @"url" : (url ? : @"unknown"),
  }]];
}



- (void)fetchByResourceManager:(NSURL *)aURL
             completionHandler:
                 (void (^)(NSURL *_Nonnull, NSURL *_Nonnull, NSError *_Nullable))completionHandler {
  
  id<LynxResourceFetcher> fetcher = self.context.resourceFetcher;
  if ([fetcher respondsToSelector:@selector(fetchResourceWithURL:type:completion:)]) {
    [fetcher fetchResourceWithURL:aURL
                             type:LynxFetchResURLOnlineOrOffline
                       completion:^(BOOL isSyncCallback, NSData * _Nullable data, NSError * _Nullable error, NSURL * _Nullable resURL) {
      
      BOOL isLocal = [resURL isFileReferenceURL];
      NSURL *localUrl = isLocal ? resURL : nil;
      NSURL *remoteUrl = isLocal ? nil : resURL;
      if (error) {
        localUrl = nil;
        remoteUrl = aURL;
      }
      if (!isSyncCallback) {
        dispatch_async(dispatch_get_main_queue(), ^{
          if (completionHandler) {
            completionHandler(localUrl, remoteUrl, error);
          }
        });
      } else {
        if (completionHandler) {
          completionHandler(localUrl, remoteUrl, error);
        }
      }
    }];
    return;
  }
  
  
  
  NSURL *baseURL = nil;
  if ([self.context.rootView isKindOfClass:[LynxView class]]) {
    baseURL = [NSURL URLWithString:[(LynxView *)self.context.rootView url]];
  }

  NSMutableDictionary *context = [NSMutableDictionary dictionary];
  context[BDXElementContextContainerKey] = self.context.rootUI.lynxView;

  
  [[BDXElementResourceManager sharedInstance]
   fetchLocalFileWithURL:aURL
   baseURL:baseURL
   context:[context copy]
   completionHandler:^(NSURL *_Nonnull localUrl, NSURL *_Nonnull remoteUrl,
                       NSError *_Nullable error) {
    if (completionHandler) {
      completionHandler(localUrl, remoteUrl, error);
    }
  }];
}



#pragma mark - Internal


- (BDXLynxVideoProModel *)resolveSrcAsJSON:(NSString *)jsonString {
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
  NSString *itemID = [jsonDict btd_stringValueForKey:@"video_id"];
  NSString *domain = [jsonDict btd_stringValueForKey:@"domain"];
  NSString *auth = [jsonDict btd_stringValueForKey:@"token"];
  NSString *videoModelStr = [jsonDict btd_stringValueForKey:@"video_model"];
  NSString *videoURL = [jsonDict btd_stringValueForKey:@"play_url"];

  // check video_model first, than url and video_id

  if (videoModelStr) {
    NSData *data = [videoModelStr dataUsingEncoding:NSUTF8StringEncoding];
    if (data.length) {
      NSDictionary *videoModel = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
      if (videoModel) {
        BDXLynxVideoProModel *model = [self.propsModel copy];
        model.videoModel = videoModel;
        return model;
      }
    }
  }
  
  if (videoURL.length > 0) {
    BDXLynxVideoProModel *model = [self.propsModel copy];
    model.playUrlString = videoURL;
    return model;
  }
  
  if (itemID.length > 0) {
    BDXLynxVideoProModel *model = [self.propsModel copy];
    model.itemID = itemID;
    model.playAuthToken = auth;
    model.playAuthDomain = domain;
    return model;
  }
  
  return nil;
}


- (BDXLynxVideoProModel *)resolveSrcAsSchema:(NSString *)schemaString {
  if (schemaString.length == 0) {
    return nil;
  }
  NSURL *schema = [NSURL URLWithString:schemaString];
  NSDictionary *query = [schema btd_queryItemsWithDecoding];
  NSString *itemID = [query btd_stringValueForKey:@"video_id"];
  NSString *videoURL = [query btd_stringValueForKey:@"play_url"];
  NSString *domain = [query btd_stringValueForKey:@"domain"];
  NSString *auth = [query btd_stringValueForKey:@"token"];
  NSString *videoModelStr = [query btd_stringValueForKey:@"video_model"];
  // check video_model first, than url and video_id
  if (videoModelStr) {
    NSData *data = [videoModelStr dataUsingEncoding:NSUTF8StringEncoding];
    if (data.length) {
      NSDictionary *videoModel = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
      if (videoModel) {
        BDXLynxVideoProModel *model = [self.propsModel copy];
        model.videoModel = videoModel;
        return model;
      }
    }
  }
  
  if (videoURL.length > 0) {
    BDXLynxVideoProModel *model = [self.propsModel copy];
    model.playUrlString = videoURL;
    return model;
  }
  
  if (itemID.length > 0) {
    BDXLynxVideoProModel *model = [self.propsModel copy];
    model.itemID = itemID;
    model.playAuthToken = auth;
    model.playAuthDomain = domain;
    return model;
  }
  
  return nil;
}

- (BDXLynxVideoProModel *)resolveSrcAsUrl:(NSString *)urlString {
  if (urlString.length == 0) {
    return nil;
  }
  if ([urlString hasPrefix:@"http://"] || [urlString hasPrefix:@"https://"]) {
    BDXLynxVideoProModel *model = [self.propsModel copy];
    model.playUrlString = urlString;
    return model;
  }
  return nil;
}

- (BOOL)controllable {
  return self.status >= BDXLynxVideoProStatusReady;
}


- (void)zoom {
  if (self.fullScreen) {
    return;
  }

  @weakify(self);
  
  Class fullScreenClz = BDXLynxVideoProFullScreen.class;
  Class injectedFullScreenClass = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
  if ([self.player.class respondsToSelector:@selector(fullScreenClz)]) {
    injectedFullScreenClass = [self.player.class performSelector:@selector(fullScreenClz)];
  }
#pragma clang diagnostic pop
  if ([injectedFullScreenClass isSubclassOfClass:BDXLynxVideoProFullScreen.class]) {
    fullScreenClz = injectedFullScreenClass;
  }
  
  self.fullScreen = [[fullScreenClz alloc] initWithPlayerView:self.player dismiss:^{
    @strongify(self);
    [self.view addSubview:self.player];
    self.player.frame = self.view.bounds;
    self.fullScreen = nil;
    [self didFullScreenChanged:@{
      @"fullscreen" : @(0),
    }];
  }];
  
  
  
  
  [self.fullScreen show:^{
    @strongify(self);
    [self didFullScreenChanged:@{
      @"fullscreen" : @(1),
    }];
  }];
}

- (void)dismiss {
  [self.fullScreen dismiss];
}

LYNX_PROPS_GROUP_DECLARE(
	LYNX_PROP_DECLARE("cache-size", setCacheSize, NSInteger),
	LYNX_PROP_DECLARE("ios-async-release", setIOSAsyncRelease, BOOL),
	LYNX_PROP_DECLARE("ios-use-metal", setIOSUseMetal, BOOL))

/**
 * @name: ios-use-metal
 * @description: use metal as the render engine, which was opengl
 * @category: experimental
 * @standardAction: offline
 * @supportVersion: 2.8
**/
LYNX_PROP_DEFINE("ios-use-metal", setIOSUseMetal, BOOL) {
  self.renderByMetal = value;
}

/**
 * @name: ios-async-release
 * @description: release instance asynchronously, to speed up dealloc
 * @category: experimental
 * @standardAction: offline
 * @supportVersion: 2.8
**/
LYNX_PROP_DEFINE("ios-async-release", setIOSAsyncRelease, BOOL) {
  self.asyncClose = value;
}

/**
 * @name: cache-size
 * @description: download cache size for video resource, in bytes, int_32. The default size is unlimited, which may consume a lot of bandwidth.
 * @category: stable
 * @standardAction: keep
 * @supportVersion: 2.8
**/
LYNX_PROP_DEFINE("cache-size", setCacheSize, NSInteger) {
  self.propsModel.propsCacheSize = value;
}

@end
