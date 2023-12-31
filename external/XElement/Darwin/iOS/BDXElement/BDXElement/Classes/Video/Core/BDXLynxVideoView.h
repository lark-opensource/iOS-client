//
//  BDXLynxVideoView.h
//  BDLynx
//
//  Created by pacebill on 2020/3/18.
//

#import <Foundation/Foundation.h>
#import <Lynx/LynxUI.h>
#import "BDXVideoPlayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxVideoView : LynxUI <BDXVideoPlayer *> <BDXVideoPlayerDelegate>

@property (nonatomic, assign) NSTimeInterval seekTime; // s

@property (nonatomic, assign) BOOL needReplay;
@property (nonatomic, assign) BOOL autoPlay;
@property (nonatomic, assign) BOOL mute;
@property (nonatomic, assign) BOOL isLoop;
@property (nonatomic, assign) BOOL useSinglePlayer;
@property (nonatomic, assign) BOOL needPreload;
@property (nonatomic, assign) BOOL autoLifecycle;
@property (nonatomic, assign) BOOL listenDeviceChange;

@property (nonatomic, strong) NSNumber *startTime;
@property (nonatomic, strong) NSNumber *volume;
@property (nonatomic, strong) NSNumber *rate;

@property (nonatomic, copy) NSString *posterURL;
@property (nonatomic, copy) NSString *fitMode;

@property (nonatomic, copy) NSString *control;
@property (nonatomic, copy) NSDictionary *logExtraDict;

@property (nonatomic, class, copy) Class videoCorePlayerClazz;
@property (nonatomic, class, copy) Class videoModelConverterClz;
@property (nonatomic, class, copy) Class fullScreenPlayerClz;

@end

NS_ASSUME_NONNULL_END
