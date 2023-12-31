//
//  ACCMusicPanelViewProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/6/24.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModelDefine.h>
#import <CreativeKit/ACCPanelViewProtocol.h>

@class HTSVideoSoundEffectPanelView, AWEMusicSelectItem, ACCVideoEditMusicViewModel;
@protocol ACCMusicModelProtocol, ACCMusicSelectViewProtocol, AWEVideoPublishMusicSelectViewUserCollectedMusicDelegate;

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMusicPanelViewProtocol <ACCPanelViewProtocol>

@required
// common
@property (nonatomic, weak, readonly) ACCVideoEditMusicViewModel *musicViewModel;

// original music panel (AWEVideoPublishMusicPanelView)
@property (nonatomic, readonly) UIView<ACCMusicSelectViewProtocol> *musicSelectView;
@property (nonatomic, strong) void (^showHandler)(void);
@property (nonatomic, strong) void (^dismissHandler)(void);
      
@property (nonatomic, strong) void (^tapClickCloseHandler)(void);
@property (nonatomic, copy) void (^willAddLyricStickerHandler)(id<ACCMusicModelProtocol> music,  NSString * _Nullable coordinateRatio);
@property (nonatomic, copy) void (^willRemoveLyricStickerHandler)(void);
@property (nonatomic, copy) void (^queryLyricStickerHandler)(UIButton *lyricStickerButton);
@property (nonatomic, strong) void (^clipButtonClickHandler)(void);
@property (nonatomic, copy) void (^favoriteButtonClickHandler)(id<ACCMusicModelProtocol> music, BOOL collect);
@property (nonatomic, copy) void (^didSelectMusicHandler)(id<ACCMusicModelProtocol> _Nullable selectedMusic, id<ACCMusicModelProtocol> _Nullable canceledMusic, NSError *error, BOOL autoPlay);
@property (nonatomic, strong) void (^enterMusicLibraryHandler)(void);
@property (nonatomic, strong) HTSVideoSoundEffectPanelView *volumeView;

- (instancetype)initWithFrame:(CGRect)frame
              musicSelectView:(ACCVideoEditMusicViewModel *)musicViewModel
       userCollectedMusicList:(NSMutableArray <AWEMusicSelectItem *> * _Nullable)userCollectedMusicList;

- (void)setSelectViewUserCollectedMusicDelegate:(NSObject<AWEVideoPublishMusicSelectViewUserCollectedMusicDelegate> *)delegate;

- (void)updateWithMusicList:(NSMutableArray <AWEMusicSelectItem *>*)musicList
               playingMusic:(id<ACCMusicModelProtocol>)playingMusic;

- (void)updateWithUserCollectedMusicList:(NSMutableArray <AWEMusicSelectItem *> *)userCollectedMusicList;
- (void)updateCurrentPlayMusicClipRange:(HTSAudioRange)range;
- (void)show;
- (void)dismiss;
- (void)updateSelectedPanel:(NSUInteger)index aniamted:(BOOL)animated;
- (void)updateActionButtonState;
- (void)resetFirstAnimation;
- (void)refreshMusicVolumeAfterAiClip:(CGFloat)musicVolume;

// new music panel

@optional

#pragma mark - only for AWEVideoPublishMusicSelectView (线上老面板)

- (void)updatePlayerTime:(NSTimeInterval)playerTime; // 无调用方，后续需删除

@end

NS_ASSUME_NONNULL_END
