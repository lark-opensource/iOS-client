//
//  Copyright 2020 The Lynx Authors. All rights reserved.
//  BDXAudioModelPlayer.h
//  XElement-Pods-Aweme
//
//  Created by bytedance on 2021/9/17.
//

#import <Foundation/Foundation.h>
#import "BDXAudioDefines.h"
#import "BDXAudioModel.h"

NS_ASSUME_NONNULL_BEGIN
@protocol BDXAudioModelPlayerDelegate;
@interface BDXAudioModelPlayer : NSObject

@property (nonatomic, weak) id<BDXAudioModelPlayerDelegate> delegate;
@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign, readonly) NSTimeInterval currentTime;
@property (nonatomic, assign, readonly) NSTimeInterval cacheTime;
@property (nonatomic, assign, readonly) NSInteger status;
@property (nonatomic, assign, readonly) NSInteger loadStatus;

@property (nonatomic, assign, readonly) NSInteger playBitrate;
@property (nonatomic, assign) BOOL loop;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *headers;
@property (nonatomic, assign) BOOL needNowPlayingInfo;
@property (nonatomic, assign) NSTimeInterval updateInterval;
@property (nonatomic, strong) BDXAudioModel *curModel;

- (NSString *)transferStatusDesByStatus:(NSInteger )status;
- (NSString *)transferLoadStatusDesByStatus:(NSInteger )status;

- (instancetype)initWithPlayerType:(BDXAudioPlayerType )type;


- (void)updateTag:(NSString *)tag;
@end

@interface BDXAudioModelPlayer (Control)

- (void)setPlayModel:(BDXAudioModel *)m;
- (void)prepare;
- (void)play;
- (void)stop;
- (void)pause;
- (void)resume;
- (void)seekTo:(NSTimeInterval )offset;
- (void)mute:(BOOL )muted;

@end

// default can pre and next
@interface BDXAudioModelPlayer (NowPlayingInfo)

@property (nonatomic, strong ,readonly) id playCommandTarget;
@property (nonatomic, strong ,readonly) id pauseCommandTarget;
@property (nonatomic, strong ,readonly) id previousCommandTarget;
@property (nonatomic, strong ,readonly) id nextCommandTarget;
@property (nonatomic, strong ,readonly) id seekCommandTarget;

- (void)setupNowPlayingInfo:(BDXAudioModel *)m;
- (void)setupRemoteCommand;
- (void)clearRemoteCommand;
- (void)preRemoteCommandEnable:(BOOL )enable;
- (void)nextRemoteCommandEnable:(BOOL )enable;

- (void)setupNotifications;
- (void)clearNotifications;

@end

@protocol BDXAudioModelPlayerDelegate <NSObject>

- (void)player:(BDXAudioModelPlayer *)player loadingStateChanged:(NSInteger )ttState;
- (void)player:(BDXAudioModelPlayer *)player playbackStateChanged:(NSInteger )ttState;
- (void)player:(BDXAudioModelPlayer *)player progressChanged:(NSTimeInterval )cur;
- (void)playerPrepared:(BDXAudioModelPlayer *)player;
- (void)playerDidSeeked:(BDXAudioModelPlayer *)player success:(BOOL)success;
- (void)playerReadyToPlay:(BDXAudioModelPlayer *)player;
- (void)playerUserStopped:(BDXAudioModelPlayer *)player;
- (void)playerDidFinish:(BDXAudioModelPlayer *)player error:(nullable NSError *)error;

- (void)playerDidTapPreRemoteCommand:(BDXAudioModelPlayer *)player;
- (void)playerDidTapNextRemoteCommand:(BDXAudioModelPlayer *)player;

@end



NS_ASSUME_NONNULL_END
