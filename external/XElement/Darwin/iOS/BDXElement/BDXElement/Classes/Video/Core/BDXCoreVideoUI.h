//
//  BDXCoreVideoUI.h
//  BDXElement
//
//  Created by 李柯良 on 2020/7/13.
//

#import <UIKit/UIKit.h>
#import "BDXVideoPlayer.h"
#import "BDXHybridUI.h"
#import <Lynx/LynxUI.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXCoreVideoUI : BDXHybridUI<BDXVideoPlayer *>

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
@property (nonatomic, strong) NSNumber * rate;

@property (nonatomic, copy) NSString *posterURL;
@property (nonatomic, copy) NSString *fitMode;

@property (nonatomic, copy) NSString *control;

@end

NS_ASSUME_NONNULL_END
