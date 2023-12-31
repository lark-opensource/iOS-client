//
//  ACCVideoEditTipsServiceImpl.h
//  CameraClient
//
//  Created by yangying on 2020/12/14.
//

#import <Foundation/Foundation.h>
#import "ACCVideoEditTipsService.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;

@interface ACCVideoEditTipsServiceImpl : NSObject<ACCVideoEditTipsService>

@property (nonatomic, weak) AWEVideoPublishViewModel *repository;

- (void)sendShowMusicBubbleSignalByType:(ACCMusicBubbleType)type;
- (void)sendShowSmartMovieBubbleSignal;
- (void)sendShowQuickPublishBubbleSignal;
- (void)sendShowCanvasInteractionGuideSignal;
- (void)sendShowImageAlbumSwitchModeBubbleSignal;
- (void)sendShowImageAlbumSlideGuideSignal;

@end

NS_ASSUME_NONNULL_END
