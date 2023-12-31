// Copyright 2021 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import <Lynx/LynxUI.h>
#import "BDXLynxFlowerVideoPlayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxFlowerVideoView : LynxUI <BDXLynxFlowerVideoPlayer *>

@property(nonatomic, assign) NSTimeInterval seekTime;  // s

@property(nonatomic, assign) BOOL needReplay;
@property(nonatomic, assign) BOOL autoPlay;
@property(nonatomic, assign) BOOL mute;
@property(nonatomic, assign) BOOL isLoop;
@property(nonatomic, assign) BOOL useSinglePlayer;
@property(nonatomic, assign) BOOL needPreload;
@property(nonatomic, assign) BOOL autoLifecycle;
@property(nonatomic, assign) BOOL listenDeviceChange;

@property(nonatomic, strong) NSNumber *startTime;
@property(nonatomic, strong) NSNumber *volume;
@property(nonatomic, strong) NSNumber *rate;

@property(nonatomic, copy) NSString *posterURL;
@property(nonatomic, copy) NSString *fitMode;

@property(nonatomic, copy) NSString *control;
@property(nonatomic, copy) NSDictionary *logExtraDict;

@end

NS_ASSUME_NONNULL_END
