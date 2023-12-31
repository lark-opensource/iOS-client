//
//  ACCMusicSelectViewProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/7/2.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModelDefine.h>

@protocol ACCMusicModelProtocol;
@class AWEMusicSelectItem, ACCVideoEditMusicViewModel;

NS_ASSUME_NONNULL_BEGIN

typedef void(^AWEUserCollectedMusicFetchCompletion)(BOOL success);

@protocol AWEVideoPublishMusicSelectViewUserCollectedMusicDelegate <NSObject>
/// 询问是否还有更多的音乐，来决定动画是否展示
- (BOOL)hasMore;
/// 获取下一页的音乐list
- (void)fetchNextPage:(AWEUserCollectedMusicFetchCompletion)completion;
- (void)retryFetchFirstPage;
/// 当前是否正在请求数据
- (BOOL)isProcessingFetchingData;

@optional
/// 当前请求的游标
- (NSNumber *)currCursor;

@end

@protocol ACCMusicSelectViewProtocol <NSObject>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong, readonly) UICollectionView *userCollectedMusicCollectionView;
@property (nonatomic, strong, readonly) AWEMusicSelectItem *selectedMusic;

@property (nonatomic, copy) void (^willAddLyricStickerHandler)(id<ACCMusicModelProtocol> music);
@property (nonatomic, copy) void (^willRemoveLyricStickerHandler)(void);
@property (nonatomic, copy) void (^queryLyricStickerHandler)(UIButton *lyricStickerButton);
@property (nonatomic, copy) void (^clipButtonClickHandler)(void);
@property (nonatomic, copy) void (^favoriteButtonClickHandler)(id<ACCMusicModelProtocol> music, BOOL collect);
@property (nonatomic, copy) void (^didSelectMusicHandler)(id<ACCMusicModelProtocol> _Nullable selectedMusic, id<ACCMusicModelProtocol> _Nullable canceledMusic, NSError *error, BOOL autoPlay);
@property (nonatomic, copy) void (^enterMusicLibraryHandler)(void);
@property (nonatomic, copy) void (^didSelectTabHandler)(NSInteger index);
@property (nonatomic, readonly) BOOL loadingAnimation;
@property (nonatomic, weak) NSObject<AWEVideoPublishMusicSelectViewUserCollectedMusicDelegate> *userCollectedMusicDelegate;
@property (nonatomic, assign) BOOL canDeselectMusic; // 是否允许取消选中音乐，默认为YES
@property (nonatomic, copy) void (^deselectMusicBlock)(void);
@property (nonatomic, assign) BOOL mvChangeMusicInProgress; // 音乐动效类型的mv设置音乐过程是异步的，此变量用来标记是否正在设置音乐。

@property (nonatomic, assign) BOOL disableCutMusic;
@property (nonatomic, assign) BOOL disableAddLyric;

- (instancetype)initWithFrame:(CGRect)frame
               musicViewModel:(ACCVideoEditMusicViewModel *)musicViewModel
       userCollectedMusicList:(NSMutableArray <AWEMusicSelectItem *> * _Nullable)userCollectedMusicList;

- (void)updateWithUserCollectedMusicList:(NSMutableArray <AWEMusicSelectItem *> *)userCollectedMusicList;
- (void)updateWithMusicList:(NSMutableArray <AWEMusicSelectItem *>*)musicList
               playingMusic:(id<ACCMusicModelProtocol>)playingMusic;
- (void)updateCurrentPlayMusicClipRange:(HTSAudioRange)range;
- (void)selectMusic:(nullable AWEMusicSelectItem *)musicItem error:(nullable NSError *)error;
- (void)selectMusic:(nullable AWEMusicSelectItem *)musicItem error:(nullable NSError *)error autoPlay:(BOOL)autoPlay;
- (BOOL)selectVisibleMusicItem;
- (void)deselectMusic;
- (void)resetToFirstTabItem;
- (void)updateActionButtonState;

//Do something while view dismissing
- (void)willDismissView;

- (void)resetFirstAnimation;

- (void)resetLyricStickerButtonStatus;
- (void)enableLyricStickerButton;
- (void)unenableLyricStickerButton;

#pragma mark - track

- (void)trackFirstDismissPanelMusicType;

@optional

#pragma mark - only for AWEVideoPublishMusicSelectView (线上面板)

// selectview中的headerView标题是否达到了两行的高度
+ (BOOL)headerViewTitleHeight2Line;

- (void)updatePlayerTime:(NSTimeInterval)playerTime; // 无上层调用方，后续需删除


#pragma mark - only for ACCMusicSelectView (新竖排新音乐面板)

+ (CGSize)adaptionMusicCollectionViewSize;

@end

NS_ASSUME_NONNULL_END
