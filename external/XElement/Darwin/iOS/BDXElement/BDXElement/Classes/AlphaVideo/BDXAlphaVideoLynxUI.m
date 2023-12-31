//
//  BDXAlphaVideoLynxUI.m
//  BDXElement
//
//  Created by li keliang on 2020/11/23.
//

#import "BDXAlphaVideoLynxUI.h"
#import "BDXAlphaVideoUI.h"

#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxLayoutStyle.h>
#import <Lynx/LynxView.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxLazyLoad.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import <Lynx/LynxRootUI.h>

@interface BDXAlphaVideoLynxUI()<BDXHybridUIEventDispatcher, BDXHybridUIContext, BDXAlphaVideoUIDelegate>

@property (nonatomic) BDXAlphaVideoUI *videoUI;
@property (nonatomic, assign) BOOL incompatible;

@end

@implementation BDXAlphaVideoLynxUI


#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-alpha-video")
#else
LYNX_REGISTER_UI("x-alpha-video")
#endif

- (UIView *)createView
{
    return [self.videoUI createView];
}

- (void)layoutDidFinished
{
    [super layoutDidFinished];
    [self.videoUI layoutDidFinished];
}

- (void)frameDidChange {
    [super frameDidChange];
    [self.videoUI updateFrameSize];
}

LYNX_PROP_SETTER("src", src, NSString *) {
    [self.videoUI updateAttribute:@"src" value:value requestReset:YES];
}

LYNX_PROP_SETTER("loop", loop, BOOL) {
    [self.videoUI updateAttribute:@"loop" value:@(value) requestReset:YES];
}

LYNX_PROP_SETTER("autoplay", autoplay, BOOL) {
    [self.videoUI updateAttribute:@"autoplay" value:@(value) requestReset:YES];
}

LYNX_PROP_SETTER("poster", poster, NSString *) {
    [self.videoUI updateAttribute:@"poster" value:value requestReset:YES];
}

LYNX_PROP_SETTER("last-frame", lastframe, NSString *) {
    [self.videoUI updateAttribute:@"lastframe" value:value requestReset:YES];
}

LYNX_PROP_SETTER("keep-last-frame", keepLastframe, BOOL) {
    [self.videoUI updateAttribute:@"keepLastframe" value:@(value) requestReset:YES];
}

LYNX_PROP_SETTER("keep-previous-view", keepPreviousView, BOOL) {
    [self.videoUI updateAttribute:@"keepPreviousView" value:@(value) requestReset:YES];
}

LYNX_PROP_SETTER("compatible", setCompatible, BOOL) {
  self.incompatible = !value;
}


LYNX_UI_METHOD(play) {
  if (!self.incompatible) {
    [self.videoUI updateAttribute:@"play" value:params requestReset:YES];
    !callback ?: callback(kUIMethodSuccess, nil);
  } else {
    if ([self.videoUI isPrepared]) {
      if ([self.videoUI getState] == 1) {
        !callback ? : callback(kUIMethodUnknown, @{@"message" : @"already playing"});
      } else {
        [self.videoUI updateAttribute:@"play" value:params requestReset:YES];
        !callback ? : callback(kUIMethodSuccess, nil);
      }
    } else {
      !callback ? : callback(kUIMethodUnknown, @{@"message" : @"not prepared"});
    }
  }
}

LYNX_UI_METHOD(stop) {
  if (!self.incompatible) {
    [self.videoUI updateAttribute:@"stop" value:params requestReset:YES];
    !callback ?: callback(kUIMethodSuccess, nil);
  } else {
    if ([self.videoUI isPrepared]) {
      [self.videoUI updateAttribute:@"stop" value:params requestReset:YES];
      !callback ? : callback(kUIMethodSuccess, nil);
    } else {
      !callback ? : callback(kUIMethodUnknown, @{@"message" : @"not prepared"});
    }
  }
}

LYNX_UI_METHOD(pause) {
  if (!self.incompatible) {
    [self.videoUI updateAttribute:@"pause" value:params requestReset:YES];
    !callback ?: callback(kUIMethodSuccess, nil);
  } else {
    if ([self.videoUI isPrepared]) {
      [self.videoUI updateAttribute:@"pause" value:params requestReset:YES];
      !callback ? : callback(kUIMethodSuccess, nil);
    } else {
      !callback ? : callback(kUIMethodUnknown, @{@"message" : @"not prepared"});
    }
  }
}

LYNX_UI_METHOD(resume) {
  if (!self.incompatible) {
    [self.videoUI updateAttribute:@"resume" value:params requestReset:YES];
    !callback ?: callback(kUIMethodSuccess, nil);
  } else {
    if ([self.videoUI isPrepared]) {
      if ([self.videoUI getState] == 1) {
        !callback ? : callback(kUIMethodUnknown, @{@"message" : @"already playing"});
      } else {
        [self.videoUI updateAttribute:@"resume" value:params requestReset:YES];
        !callback ? : callback(kUIMethodSuccess, nil);
      }
    } else {
      !callback ? : callback(kUIMethodUnknown, @{@"message" : @"not prepared"});
    }
  }
}


/**
 * @name: seek
 * @description: seek video on the AlphaPlayer
 * @category: standardized
 * @standardAction: keep
 * @supportVersion: 3.0
**/
LYNX_UI_METHOD(seek) {
  if (self.incompatible) {
      if (![self.videoUI isPrepared]) {
          if (callback) {
              callback(kUIMethodUnknown, @{@"message" : @"not prepared"});
          }
        return;
      }
  }
  
  if (!params || ![params objectForKey:@"ms"]) {
      if (callback) {
          callback(kUIMethodParamInvalid, @{@"message" : @"params not valid"});
      }
      return;
  }
  
  [self.videoUI updateAttribute:@"seek" value:params requestReset:YES];
  if (callback) {
      callback(kUIMethodSuccess, nil);
  }
  
}

LYNX_UI_METHOD(release) {
    [self.videoUI updateAttribute:@"release" value:params requestReset:YES];
    !callback ?: callback(kUIMethodSuccess, nil);
}

LYNX_UI_METHOD(subscribeUpdateEvent) {
    NSNumber *seconds = params[@"ms"];
    if ([seconds isKindOfClass:NSNumber.class]) {
        [self.videoUI updateAttribute:@"subscribeUpdateEvent" value:params requestReset:YES];
        !callback ?: callback(kUIMethodSuccess, nil);
    } else {
        !callback ?: callback(kUIMethodParamInvalid, nil);
    }
}

LYNX_UI_METHOD(unsubscribeUpdateEvent) {
    NSNumber *seconds = params[@"ms"];
    if ([seconds isKindOfClass:NSNumber.class]) {
        [self.videoUI updateAttribute:@"unsubscribeUpdateEvent" value:params requestReset:YES];
        !callback ?: callback(kUIMethodSuccess, nil);
    } else {
        !callback ?: callback(kUIMethodParamInvalid, nil);
    }
}

LYNX_UI_METHOD(isPlaying) {
  if (!self.incompatible) {
    [self.videoUI updateAttribute:@"isPlaying" value:params requestReset:YES];
    !callback ?: callback(kUIMethodSuccess, @{ @"data": @{@"isPlaying" : @([self.videoUI isVideoPlaying])}});
  } else {
    if ([self.videoUI isPrepared]) {
      [self.videoUI updateAttribute:@"isPlaying" value:params requestReset:YES];
      !callback ?: callback(kUIMethodSuccess, @{ @"data": @{@"isPlaying" : @([self.videoUI isVideoPlaying])}});
    } else {
      !callback ? : callback(kUIMethodUnknown, @{@"message" : @"not prepared"});
    }
  }
}


LYNX_UI_METHOD(getDuration) {
  if (!self.incompatible) {
    [self.videoUI updateAttribute:@"getDuration" value:params requestReset:YES];
    int duration =[[self.videoUI getVideoDuration] intValue];
    !callback ?: callback(kUIMethodSuccess, @{ @"data": @{@"duration": @(duration)}});
  } else {
    if ([self.videoUI isPrepared]) {
      int duration =[[self.videoUI getVideoDuration] intValue];
      !callback ?: callback(kUIMethodSuccess, @{ @"data": @{@"duration": @(duration)}});
    } else {
      !callback ? : callback(kUIMethodUnknown, @{@"message" : @"not prepared"});
    }
  }
}


- (BOOL)loadZipFromResourceFetcher:(NSURL *)URL
                        completion:(void (^)(NSURL *URL, NSURL *unzipURL, NSError * _Nullable error))completion {
  id<LynxResourceFetcher> fetcher = self.context.resourceFetcher;
  if ([fetcher respondsToSelector:@selector(fetchResourceWithURL:type:completion:)]) {
    [fetcher fetchResourceWithURL:URL
                             type:LynxFetchResURLUnzipped
                       completion:^(BOOL isSyncCallback, NSData * _Nullable data, NSError * _Nullable error, NSURL * _Nullable resURL) {
      if (!isSyncCallback) {
        dispatch_async(dispatch_get_main_queue(), ^{
          if (completion) {
            completion(URL, resURL, error);
          }
        });
      } else {
        if (completion) {
          completion(URL, resURL, error);
        }
      }
    }];
    return YES;
  } else {
    return NO;
  }
}


#pragma mark - BDXHybridUIEventDispatcher

- (void)sendCustomEvent:(NSString * _Nonnull)event params:(NSDictionary * _Nullable)params
{
    LynxCustomEvent *customEvent = [[LynxDetailEvent alloc] initWithName:event targetSign:[self sign] detail:params];
    [self.context.eventEmitter sendCustomEvent:customEvent];
}

#pragma mark - BDXHybridUIContext

- (nullable id)bdx_context
{
    return self.context;
}

- (CGRect)bdx_frame
{
    return self.frame;
}

- (nullable NSURL *)bdx_containerURL
{
    if ([self.context.rootView isKindOfClass:LynxView.class]) {
        NSString *URLString = [(LynxView*)self.context.rootView url];
        if (URLString) {
            return [NSURL URLWithString:URLString];
        }
    }
    return nil;
}

#pragma mark - Accessors

- (BDXAlphaVideoUI *)videoUI
{
    if (!_videoUI) {
        _videoUI = [[BDXAlphaVideoUI alloc] init];
        _videoUI.context = self;
        _videoUI.eventDispatcher = self;
      _videoUI.uiDelegate = self;
    }
    return _videoUI;
}

LYNX_PROPS_GROUP_DECLARE(
	LYNX_PROP_DECLARE("ios-async-render", iosAsyncRender, BOOL))

/**
 * @name: ios-async-render
 * @description: enable async render
 * @category: different
 * @standardAction: keep
 * @supportVersion: 2.9
**/
LYNX_PROP_DEFINE("ios-async-render", iosAsyncRender, BOOL) {
  [self.videoUI updateAttribute:@"iosAsyncRender" value:@(value) requestReset:YES];
}

@end
