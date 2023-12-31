//
//  AWESingleMusicView.h
//  AWEStudio
//
//  Created by 李彦松 on 2018/9/7.
//  Copyright © 2018年 bytedance. All rights reserved.
//


#import "ACCAudioPlayerProtocol.h"
#import "ACCMusicEnumDefines.h"
#import <CreationKitArch/ACCMusicModelProtocol.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, AWESingleMusicViewLayoutStatus) {
    AWESingleMusicViewLayoutStatusNormal = 0,
    AWESingleMusicViewLayoutStatusNormalShowApply,
    AWESingleMusicViewLayoutStatusNormalHideLabel
};

@class AWESingleMusicView;
@protocol AWESingleMusicViewDelegate <NSObject>

/**
 *@brief 点击“使用音乐”
 */
- (void)singleMusicViewDidTapUse:(AWESingleMusicView *)musicView
                           music:(id<ACCMusicModelProtocol>)music;

/**
 *@brief 点击“更多”按钮
 */
- (void)singleMusicViewDidTapMoreButton:(id<ACCMusicModelProtocol>)music;

/**
 *@brief 音乐是否可裁剪
 */
- (BOOL)singleMusicView:(AWESingleMusicView *)musicView
        enableClipMusic:(id<ACCMusicModelProtocol>)music;

/**
 *@brief 点击“裁剪”按钮
 */
- (void)singleMusicViewDidTapClip:(AWESingleMusicView *)musicView
                            music:(id<ACCMusicModelProtocol>)music;

/**
 *@brief 点击“收藏”按钮
 */
- (void)singleMusicViewDidTapFavouriteMusic:(id<ACCMusicModelProtocol>)music;

/**
 *@brief 音乐下载的过程中，点击“使用音乐”按钮
 */
- (void)singleMusicViewDidTapUseWhileLoading;

@end

@interface AWESingleMusicView : UIView

@property (nonatomic, weak)   id<AWESingleMusicViewDelegate>delegate;
@property (nonatomic, assign) BOOL isEliteVersion;
@property (nonatomic, assign) BOOL isSearchMusic;
@property (nonatomic, assign) BOOL isFavoriteList;

@property (nonatomic, assign) BOOL showMoreButton;
@property (nonatomic, assign) BOOL showCollectionButton;
@property (nonatomic, assign) BOOL showLyricLabel;
@property (nonatomic, assign) BOOL enableSongTag;
@property (nonatomic, assign) BOOL needShowPGCMusicInfo;
@property (nonatomic, assign) BOOL showClipButton;
@property (nonatomic, assign) BOOL newPlayerType;
@property (nonatomic, assign) CGFloat contentPadding;

@property (nonatomic, copy) void (^changePlayingStatusBlock)(void);

- (instancetype)initWithEnableSongTag:(BOOL)enable;

- (void)switchToDarkBackgroundMode;

- (void)configWithMusicModel:(id<ACCMusicModelProtocol>)model rank:(NSInteger)rank;
- (void)configWithMusicModel:(id<ACCMusicModelProtocol>)model;

- (void)configWithPlayerStatus:(ACCAVPlayerPlayStatus)playerStatus;
- (void)configWithPlayerStatus:(ACCAVPlayerPlayStatus)playerStatus animated:(BOOL)animated;

- (void)configWithNewPlayerStatus:(ACCMusicServicePlayStatus)playerStatus;
- (void)configWithFavoriteListStatus:(ACCMusicServicePlayStatus)playerStatus;
- (void)configWithCollectionSelected:(BOOL)selected;
+ (CGFloat)heightWithMusic:(id<ACCMusicModelProtocol>)model
                baseHeight:(CGFloat)baseHeight
            contentPadding:(CGFloat)contentPadding;

@end

NS_ASSUME_NONNULL_END
