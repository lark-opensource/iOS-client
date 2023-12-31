//
//  ACCMusicSelectView.m
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/6/28.
//

#import "ACCMusicSelectView.h"
#import "AWERepoVideoInfoModel.h"
#import "AWERepoStickerModel.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEMusicSelectItem.h"
#import "AWEAIMusicRecommendManager.h"
#import <CreationKitInfra/ACCToastProtocol.h>
#import "AWEMusicLoadingAnimationCell.h"
#import "AWEVideoPublishMusicSelectTopTabView.h"
#import "ACCMusicSelectCollectionViewCell.h"
#import "ACCMusicSelectCollectionView.h"
#import "ACCMusicCollectionViewProtocol.h"
#import <CreativeKit/NSTimer+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoMVModel.h>
#import <CreationKitArch/ACCPublishMusicTrackModel.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIImage+ACCAdditions.h>
#import <CreationKitInfra/ACCLogProtocol.h>

#import <CameraClient/ACCVideoMusicProtocol.h>
#import <CreationKitInfra/ACCModuleService.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import "ACCFriendsServiceProtocol.h"
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/ACCLoadMoreFooter.h>
#import <CameraClient/UIScrollView+ACCInfiniteScrolling.h>
#import "ACCVideoEditMusicViewModel.h"
#import "ACCPersonalRecommendWords.h"

static const CGFloat kNewCollectionViewHeight = 64.f;
static const CGFloat kUserCollectedCollectionViewInsetRightFetching = 50.f;
static const CGFloat kUserCollectedCollectionViewInsetRightNone = 10.f;
static NSString * const ACCVideoEditMusicIndicatorTextFont = @"acc_video_edit_music_indicator_text_font";

@interface ACCMusicSelectView() <UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, ACCMusicSelectCollectionViewCellDelegate>

@property (nonatomic, strong) UIView *fadingContainerView;

@property (nonatomic, strong) UIButton *lyricStickerButton;//添加歌词贴纸按钮
@property (nonatomic, strong) UIButton *clipButton;  // 裁减按钮
@property (nonatomic, strong) UIButton *favoriteButton;   // 收藏按钮

@property (nonatomic, strong) UIImageView *musicDiscoverImageView;
@property (nonatomic, strong) UILabel *musicDiscoverLabel;
@property (nonatomic, strong) UIButton *musicDiscoverButton;

@property (nonatomic, strong) AWEMusicSelectItem *selectedMusic;

/// 新版配乐选择页面用来切换 推荐 | 收藏 的tab
@property (nonatomic, strong) AWEVideoPublishMusicSelectTopTabView *topTabView;

@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) NSIndexPath *previousSelectedIndexPath;

@property (nonatomic, strong) NSMutableArray <AWEMusicSelectItem *> *musicList;
@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;
@property (nonatomic,   copy) NSString *currentTopTabStr;//当前tab为推荐or收藏
/// 用来生成收藏的音乐的面板
@property (nonatomic, strong) NSMutableArray <AWEMusicSelectItem *> *userCollectedMusicList;

@property (nonatomic, strong) NSIndexPath *selectedUserCollectedMusicIndexPath;
@property (nonatomic, strong) NSIndexPath *previousSelectedUserCollectedMusicIndexPath;

/// 当前正在使用的collectionView，推荐或者收藏
@property (nonatomic, strong) UICollectionView *previousActivedCollectionView;
@property (nonatomic, assign) BOOL isFetchingMoreUserCollectedMusics;
@property (nonatomic, assign) BOOL hasReportSelectMusic;

@property (nonatomic, assign) BOOL musicSelectionInProgress;
@property (nonatomic, strong) NSMutableSet *trackingMusicIDs;
@property (nonatomic,   copy) NSString *musicID;//录制页选好的音乐ID
@property (nonatomic, strong) UICollectionView<ACCMusicCollectionViewProtocol> *userCollectedMusicCollectionView;

@property (nonatomic, strong) NSTimer *stopLoadingTimer;
@property (nonatomic, assign, readwrite) BOOL loadingAnimation;
//本来是进入编辑页立马请求AI数据，计时3秒，3秒内请求未完成展示动画，为了优化弱网体验，PM要求改成打开面板计时3秒
@property (nonatomic, assign) NSTimeInterval aniamtionRefTime;

@property (nonatomic, weak) ACCVideoEditMusicViewModel *musicViewModel;
@property (nonatomic, assign) BOOL userCollectionMusicDisable;
@property (nonatomic, assign) BOOL recommendMusicDisabel;

@property (nonatomic, strong) UISelectionFeedbackGenerator *selectionFeedback NS_AVAILABLE_IOS(10_0);

@end

@implementation ACCMusicSelectView

@synthesize willAddLyricStickerHandler, willRemoveLyricStickerHandler, queryLyricStickerHandler, clipButtonClickHandler, favoriteButtonClickHandler, didSelectMusicHandler, enterMusicLibraryHandler, didSelectTabHandler;
@synthesize collectionView = _collectionView, loadingAnimation, userCollectedMusicDelegate, canDeselectMusic = _canDeselectMusic, deselectMusicBlock, mvChangeMusicInProgress, disableCutMusic, disableAddLyric;

#pragma mark - life cycle

- (void)dealloc {
    if ([_stopLoadingTimer isValid]) {
        [_stopLoadingTimer invalidate];
        _stopLoadingTimer = nil;
    }
}

- (instancetype)initWithFrame:(CGRect)frame
               musicViewModel:(ACCVideoEditMusicViewModel *)musicViewModel
       userCollectedMusicList:(NSMutableArray <AWEMusicSelectItem *> * _Nullable)userCollectedMusicList {
    self = [super initWithFrame:frame];
    if (self) {
        _musicList = [NSMutableArray new];
        _musicViewModel = musicViewModel;
        _publishModel = musicViewModel.repository;
        _userCollectedMusicList = userCollectedMusicList;
        _musicID = musicViewModel.repository.repoMusic.music.musicID;
        _trackingMusicIDs = [NSMutableSet new];
        _canDeselectMusic = YES;
        _userCollectionMusicDisable = YES;
        _recommendMusicDisabel = YES;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.favoriteButton = ({
        UIButton *favoriteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        favoriteButton;
    });
    
    self.clipButton = ({
        UIButton *clipButton = [UIButton buttonWithType:UIButtonTypeCustom];
        clipButton;
    });
    
    /** == lyricStickerButton == */
    self.lyricStickerButton = ({
        UIButton *lyricStickerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        lyricStickerButton;
    });
    // 配置是否有选中的歌词
    [self updateActionButtonsWithMusic:self.selectedMusic];
    
    if (!self.musicViewModel.isCommerceLimitPanel) {
        self.musicDiscoverLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(ACC_SCREEN_WIDTH - 46, 21, 46, 21)];
            label.textAlignment = NSTextAlignmentLeft;
            label.text = @"发现";
            [self addSubview:label];
            label.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightRegular];
            label.textColor = ACCResourceColor(ACCColorTextReverse);
            label.isAccessibilityElement = NO;
            label;
        });
        
        self.musicDiscoverImageView = ({
            UIImage *image = [ACCResourceImage(@"icon_edit_music_panel_opt_more") acc_ImageWithTintColor:ACCResourceColor(ACCColorTextReverse)];
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            [self addSubview:imageView];
            [imageView setFrame:CGRectMake(ACC_SCREEN_WIDTH - 72, 20, 23, 23)];
            [imageView setContentMode:UIViewContentModeScaleAspectFill];
            imageView;
        });
        
        self.musicDiscoverButton = ({
            UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(ACC_SCREEN_WIDTH - 88, 0, 88, 55)];
            [button addTarget:self action:@selector(musicDiscoverButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:button];
            button.isAccessibilityElement = YES;
            button.accessibilityTraits = UIAccessibilityTraitButton;
            button;
        });
        self.musicDiscoverButton.accessibilityLabel = self.musicDiscoverLabel.text;
    }
    
    /** == topTabView == */
    [self addSubview:self.topTabView];
    CGFloat toolbarHeight = self.topTabView.intrinsicContentSize.height;  // 32
    [self.topTabView setFrame:CGRectMake(0, 3.5, 115, toolbarHeight + 19.5)];
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat lineHeight = 1/scale;
    UIView *topToolbarLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 55 - lineHeight, ACC_SCREEN_WIDTH, lineHeight)];
    topToolbarLineView.backgroundColor = ACCResourceColor(ACCUIColorConstLinePrimary);
    [self addSubview:topToolbarLineView];
    
    /** == fadingContainerView == */
    self.fadingContainerView = [[UIView alloc] init];
    [self addSubview:self.fadingContainerView];
    CGSize collectionSize = [ACCMusicSelectView adaptionMusicCollectionViewSize];
    self.fadingContainerView.frame = CGRectMake(0, 55, collectionSize.width, collectionSize.height);
    
    // loading animation cell
    [self.collectionView registerClass:AWEMusicLoadingAnimationCell.class
            forCellWithReuseIdentifier:NSStringFromClass(AWEMusicLoadingAnimationCell.class)];
    
    // Editor optimized cell
    [self.collectionView registerClass:ACCMusicSelectCollectionViewCell.class
            forCellWithReuseIdentifier:NSStringFromClass(ACCMusicSelectCollectionViewCell.class)];
    // 新音乐面板支持loadMore和预加载
    if ([self.musicViewModel.recommendMusicRequestManager canUseLoadMore]) {
        @weakify(self);
        ACCLoadMoreFooter *footer = [ACCLoadMoreFooter footerWithRefreshingBlock:^{
            @strongify(self);
            if ([self.musicViewModel.recommendMusicRequestManager useHotMusic]) {
                if (self.musicViewModel.recommendMusicRequestManager.hotMusicHasMore) {
                    [self.musicViewModel.recommendMusicRequestManager fetchInfiniteHotMusic:^{
                        @strongify(self);
                        [self.musicViewModel updateMusicList];
                        [self p_endRefreshingWithHotMusic:YES];
                    }];
                } else {
                    [self p_endRefreshingWithHotMusic:YES];
                }
            } else {
                if (self.musicViewModel.recommendMusicRequestManager.aiMusicHasMore) {
                    NSString *zipUri = [AWEAIMusicRecommendManager recommendedBachZipUriWithPublishViewModel:self.musicViewModel.repository];
                    [self.musicViewModel.recommendMusicRequestManager fetchInfiniteAIRecommendMusicWithURI:zipUri isCommercialScene:self.musicViewModel.isCommerceLimitPanel fetchResultBlock:^{
                        @strongify(self);
                        [self.musicViewModel updateMusicList];
                        [self p_endRefreshingWithHotMusic:NO];
                    }];
                } else {
                    [self p_endRefreshingWithHotMusic:NO];
                }
            }
        }];
        [footer setLoadingViewBackgroundColor:ACCResourceColor(ACCColorBGReverse)];
        footer.showNoMoreDataText = NO;
        _collectionView.mj_footer = footer;
        
        [_collectionView acc_addInfiniteScrollingWithViewHeight:1 actionHandler:^{
            @strongify(self);
            if ([self.musicViewModel.recommendMusicRequestManager useHotMusic]) {
                if (self.musicViewModel.recommendMusicRequestManager.hotMusicHasMore) {
                    [self.collectionView.acc_infiniteScrollingView startAnimating];
                    [self.musicViewModel.recommendMusicRequestManager fetchInfiniteHotMusic:^{
                        @strongify(self);
                        [self.musicViewModel updateMusicList];
                        [self p_endRefreshingWithHotMusic:YES];
                    }];
                } else {
                    [self p_endRefreshingWithHotMusic:YES];
                }
            } else {
                if (self.musicViewModel.recommendMusicRequestManager.aiMusicHasMore) {
                    [self.collectionView.acc_infiniteScrollingView startAnimating];
                    NSString *zipUri = [AWEAIMusicRecommendManager recommendedBachZipUriWithPublishViewModel:self.musicViewModel.repository];
                    [self.musicViewModel.recommendMusicRequestManager fetchInfiniteAIRecommendMusicWithURI:zipUri isCommercialScene:self.musicViewModel.isCommerceLimitPanel fetchResultBlock:^{
                        @strongify(self);
                        [self.musicViewModel updateMusicList];
                        [self p_endRefreshingWithHotMusic:NO];
                    }];
                } else {
                    [self p_endRefreshingWithHotMusic:NO];
                }
            }
        }];
    }
    
    // 音乐列表
    [self.fadingContainerView addSubview:self.collectionView];
    ACCMasMaker(self.collectionView, {
        make.edges.equalTo(self.fadingContainerView);
    });

    [self setupUserCollectedMusicCollectionView];
}

- (void)setupUserCollectedMusicCollectionView {
    // 收藏音乐列表
    [self.userCollectedMusicCollectionView registerClass:AWEMusicLoadingAnimationCell.class
            forCellWithReuseIdentifier:NSStringFromClass(AWEMusicLoadingAnimationCell.class)];
    
    [self.userCollectedMusicCollectionView registerClass:ACCMusicSelectCollectionViewCell.class
            forCellWithReuseIdentifier:NSStringFromClass(ACCMusicSelectCollectionViewCell.class)];
    
    [self.fadingContainerView insertSubview:self.userCollectedMusicCollectionView belowSubview:self.collectionView];
    
    self.userCollectedMusicCollectionView.hidden = YES;
    self.userCollectedMusicCollectionView.delegate = self;
    
    ACCMasMaker(self.userCollectedMusicCollectionView, {
        make.edges.equalTo(self.fadingContainerView);
    });
}

- (void)updateWithMusicList:(NSMutableArray <AWEMusicSelectItem *>*)musicList
               playingMusic:(id<ACCMusicModelProtocol>)playingMusic
{
    if (!self.aniamtionRefTime) {
        self.aniamtionRefTime = CFAbsoluteTimeGetCurrent();
    }
    //set loadingAnimation
    if ([self.stopLoadingTimer isValid]) {
        [self.stopLoadingTimer invalidate];
    }
    
    BOOL discardFirstSelectedMusic = NO;
    BOOL hasDegradeSelectedHotMusic = self.musicViewModel.recommendMusicRequestManager.autoDegradeSelectHotMusic;
    if ([AWEAIMusicRecommendManager sharedInstance].isRequesting && !hasDegradeSelectedHotMusic) {//请求未完成的时候打开
        CGFloat gap = fabs(CFAbsoluteTimeGetCurrent() - self.aniamtionRefTime);
        CGFloat gapTime = 3.0f;
        if (gap < gapTime) {//not fetch data in 3s
            self.loadingAnimation = YES;
            // 智能抽帧推荐音乐第一次选中兜底音乐
            discardFirstSelectedMusic = YES;
            CGFloat duration = gapTime - gap;
            if (duration < 0.5f) {
                duration = 0.5f;
            }
            @weakify(self);
            self.stopLoadingTimer = [NSTimer acc_scheduledTimerWithTimeInterval:duration block:^(NSTimer * _Nonnull timer) {
                @strongify(self);
                self.loadingAnimation = NO;
                if (!self.hidden) {
                    acc_dispatch_main_async_safe(^{
                        self.collectionView.scrollEnabled = YES;
                        [self.collectionView reloadData];
                        if (!self.loadingAnimation) {
                            [((UICollectionView<ACCMusicCollectionViewProtocol> *)self.collectionView) stopFirstLoadingAnimation];
                        }
                        // 音乐列表刷新，且音乐列表有歌曲则可以使用配乐
                        if (discardFirstSelectedMusic && [self.musicList count]) {
                            self.recommendMusicDisabel = NO;
                        } else {
                            self.recommendMusicDisabel = YES;
                        }
                        AWEVideoPublishMusicSelectTopTabItemData *item = self.topTabView.items.firstObject;
                        if (item.selected) { // 选中状态下则更新外部可用状态
                            self.musicViewModel.musicPanelViewModel.bgmMusicDisable = self.recommendMusicDisabel;
                        }
                    
                        // 拉起面板如果未选中歌曲则自动默认选中音乐列表第一首，智能配乐未刷新(超时三秒情况下)
                        if (discardFirstSelectedMusic && [self autoSelectedRecommendMusic]) {
                            [self.collectionView layoutIfNeeded];
                            self.musicViewModel.musicPanelViewModel.showPanelAutoSelectedMusic = NO;
                            [self selectVisibleMusicItem];
                        }
                    });
                }
            } repeats:NO];
        } else {
            self.loadingAnimation = NO;//max 3s loading
        }
    } else {
        if (musicList.count > 0) {
            self.loadingAnimation = NO;
        } else {
            self.loadingAnimation = YES;
        }
    }
    
    //set data source
    self.musicList = [musicList mutableCopy];

    if(!playingMusic) {
        self.selectedIndexPath = nil;
    }
    
    if (self.selectedIndexPath || !self.collectionView.hidden) { // 有选中的推荐音乐或推荐列表未隐藏
        [self deselectPreviousCellsWithCurrClickedCollectionView:_collectionView];
    }
    
    //update ui
    acc_dispatch_main_async_safe(^{
        self.collectionView.scrollEnabled = self.loadingAnimation ? NO:YES;
        if (!self.loadingAnimation) {
            [((UICollectionView<ACCMusicCollectionViewProtocol> *)self.collectionView) stopFirstLoadingAnimation];
        }
      
        [self.collectionView reloadData];
        
        //  选中当前推荐音乐列表下标音乐
        if ([musicList count]) {
            __block NSInteger currentMusicIndex = NSNotFound;
            [musicList enumerateObjectsUsingBlock:^(AWEMusicSelectItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.musicModel isEqual:playingMusic]) {
                    currentMusicIndex = idx;
                    *stop = YES;
                }
            }];
            
            if (currentMusicIndex != NSNotFound) {
                self.selectedIndexPath = [NSIndexPath indexPathForRow:currentMusicIndex inSection:0];
                self.previousSelectedIndexPath = self.selectedIndexPath;
                [self.collectionView layoutIfNeeded];
                [self selectMusic:[musicList acc_objectAtIndex:currentMusicIndex] error:nil];
            }
        }
      
        // 音乐列表刷新，且音乐列表有歌曲则可以使用配乐
        if (!discardFirstSelectedMusic && [self.musicList count]) {
            self.recommendMusicDisabel = NO;
        } else {
            self.recommendMusicDisabel = YES;
        }
        AWEVideoPublishMusicSelectTopTabItemData *item = self.topTabView.items.firstObject;
        if (item.selected) { // 选中状态下则更新外部可用状态
            self.musicViewModel.musicPanelViewModel.bgmMusicDisable = self.recommendMusicDisabel;
        }
        // 拉起面板如果未选中歌曲则自动默认选中音乐列表第一首，且等待智能配乐刷新(超时三秒情况下)
        if (!discardFirstSelectedMusic && [self autoSelectedRecommendMusic]) {
            [self.collectionView layoutIfNeeded];
            self.musicViewModel.musicPanelViewModel.showPanelAutoSelectedMusic = NO;
            [self selectVisibleMusicItem];
        }
        
        // 重置打开面板时，滚动到当前选中的cell
        if (self.selectedIndexPath && self.selectedIndexPath.row < [self.musicList count] && self.musicViewModel.musicPanelViewModel.showPanelScrollToSelectItem && !self.loadingAnimation) {
            [self.collectionView layoutIfNeeded];
            
            // 判定当前cell是否在可见区域内
            NSArray<NSIndexPath *> *indexPathsForVisibleItems = [self.collectionView indexPathsForVisibleItems];
            __block BOOL isVisibleCell = NO;
            NSIndexPath *selectedIndexPath = self.selectedIndexPath;
            [indexPathsForVisibleItems enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (selectedIndexPath.row == obj.row) {
                    isVisibleCell = YES;
                    *stop = YES;
                }
            }];
            if (!isVisibleCell) {
                [self.collectionView scrollToItemAtIndexPath:self.selectedIndexPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
            }
        }
        self.musicViewModel.musicPanelViewModel.showPanelScrollToSelectItem = NO;
    });
    //track
    self.publishModel.repoMusic.musicTrackModel.musicRecType = @([AWEAIMusicRecommendManager sharedInstance].musicFetchType);
    if (self.loadingAnimation) {
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        [attributes setValue:@"video_edit_page" forKeyPath:@"enter_from"];
        attributes[@"shoot_way"] = self.publishModel.repoTrack.referString;
        attributes[@"content_source"] = self.publishModel.repoTrack.referExtra[@"content_source"];
        attributes[@"content_type"] = self.publishModel.repoTrack.referExtra[@"content_type"];
        [ACCTracker() trackEvent:@"music_loading" params:attributes needStagingFlag:NO];
    }
}

- (void)updateActionButtonState
{
    [self updateActionButtonsWithMusic:self.selectedMusic];
}

- (NSInteger)findMusicItem:(AWEMusicSelectItem *)musicItem inList:(NSArray<AWEMusicSelectItem *> *)musicList
{
    if (musicItem ==  nil) {
        return NSNotFound;
    }
    __block NSInteger itemIndex = NSNotFound;
    [musicList enumerateObjectsUsingBlock:^(AWEMusicSelectItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([item.musicModel isEqual:musicItem.musicModel]) {
            itemIndex = idx;
            *stop = YES;
        }
    }];
    return itemIndex;
}

- (void)updateSelectedIndex {
    NSIndexPath *previousIndexPath = self.selectedIndexPath;
    NSInteger selectedIndexInRecommend = [self findMusicItem:self.selectedMusic inList:self.musicList];
    self.selectedIndexPath = selectedIndexInRecommend != NSNotFound ? [NSIndexPath indexPathForRow:selectedIndexInRecommend inSection:0] : nil;
    if (previousIndexPath && previousIndexPath.row < self.musicList.count && self.selectedIndexPath) {
        AWEMusicSelectItem *previousItem = self.musicList[previousIndexPath.row];
        AWEMusicSelectItem *currentItem = self.musicList[self.selectedIndexPath.row];
        // 音乐推荐去重兜底，以当前选中的音乐为下标
        if ([previousItem.musicModel.musicID isEqualToString:currentItem.musicModel.musicID]) {
            if (self.selectedIndexPath.row != previousIndexPath.row && previousItem != currentItem) {
                self.selectedIndexPath = previousIndexPath;
            }
        }
    }

    NSInteger selectedIndexInFavorite = [self findMusicItem:self.selectedMusic inList:self.userCollectedMusicList];
    self.selectedUserCollectedMusicIndexPath = selectedIndexInFavorite != NSNotFound ? [NSIndexPath indexPathForRow:selectedIndexInFavorite inSection:0] : nil;
}

#pragma mark - setter/getter

- (void)setSelectedMusic:(AWEMusicSelectItem *)selectedMusic {
    _selectedMusic = selectedMusic;
    [self updateSelectedIndex];
    if (_selectedMusic) {
        [self updateActionButtonsWithMusic:_selectedMusic];
    }
}

- (UICollectionView *)collectionView
{
    if (_collectionView == nil) {
        
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        
        CGSize collectionSize = [ACCMusicSelectView adaptionMusicCollectionViewSize];
        // 动画预加载动画
        CGRect frame = CGRectMake(0, 56, collectionSize.width, collectionSize.height);
        CGRect loadAnimationFrame = CGRectMake(0, 0, collectionSize.width, collectionSize.height);
        _collectionView = [[ACCMusicSelectCollectionView alloc] initWithFrame:frame collectionViewLayout:flowLayout];
        ((UICollectionView<ACCMusicCollectionViewProtocol> *)_collectionView).firstLoadingAnimationFrame = loadAnimationFrame;
        if (self.musicViewModel.recommendMusicRequestManager.hotMusicFirstLoading) {
            [((UICollectionView<ACCMusicCollectionViewProtocol> *)self.collectionView) startFirstLoadingAnimation];
        } else {
            [((UICollectionView<ACCMusicCollectionViewProtocol> *)self.collectionView) stopLoadingMoreAnimating];
        }
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.contentInset = UIEdgeInsetsMake(7.5, 0, 0, 0);
        _collectionView.contentOffset = CGPointMake(0, -7.5);
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.showsVerticalScrollIndicator = NO;
    }
    return _collectionView;
}

- (void)p_endRefreshingWithHotMusic:(BOOL)isHotMusic {
    [_collectionView.acc_infiniteScrollingView stopAnimating];
    if (isHotMusic) {
        if (self.musicViewModel.recommendMusicRequestManager.hotMusicHasMore) {
            [_collectionView.mj_footer endRefreshing];
        } else {
            [_collectionView.mj_footer endRefreshingWithNoMoreData];
        }
    } else {
        if (self.musicViewModel.recommendMusicRequestManager.aiMusicHasMore) {
            [_collectionView.mj_footer endRefreshing];
        } else {
            [_collectionView.mj_footer endRefreshingWithNoMoreData];
        }
    }
}

- (UICollectionView<ACCMusicCollectionViewProtocol> *)userCollectedMusicCollectionView {
    if (_userCollectedMusicCollectionView == nil) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
        CGSize collectionSize = [ACCMusicSelectView adaptionMusicCollectionViewSize];
        // 动画预加载动画
        CGRect frame = CGRectMake(0, 56, collectionSize.width, collectionSize.height);
        CGRect loadAnimationFrame = CGRectMake(0, 0, collectionSize.width, collectionSize.height);
        
        _userCollectedMusicCollectionView = [[ACCMusicSelectCollectionView alloc] initWithFrame:frame collectionViewLayout:flowLayout];
        _userCollectedMusicCollectionView.backgroundColor = [UIColor clearColor];
        _userCollectedMusicCollectionView.delegate = self;
        _userCollectedMusicCollectionView.dataSource = self;
        _userCollectedMusicCollectionView.contentInset = UIEdgeInsetsMake(7.5, 0, 0, 0);
        _userCollectedMusicCollectionView.contentOffset = CGPointMake(0, -7.5);
        _userCollectedMusicCollectionView.showsHorizontalScrollIndicator = NO;
        _userCollectedMusicCollectionView.showsVerticalScrollIndicator = NO;
        _userCollectedMusicCollectionView.firstLoadingAnimationFrame = loadAnimationFrame;
        [_userCollectedMusicCollectionView startFirstLoadingAnimation];
        @weakify(self);
        [_userCollectedMusicCollectionView setRetryBlock:^{
            @strongify(self);
            if (self.userCollectedMusicDelegate &&
                [self.userCollectedMusicDelegate respondsToSelector:@selector(retryFetchFirstPage)]) {
                [self.userCollectedMusicDelegate retryFetchFirstPage];
            }
        }];
    }
    return _userCollectedMusicCollectionView;
}

- (AWEVideoPublishMusicSelectTopTabView *)topTabView {
    if (!_topTabView) {
        CGFloat underlineSpace = 12.5f;
        CGFloat titleTopOffset = 19.5;
        CGFloat buttonLeftOffset = 16;
        NSMutableArray *mItems = [[NSMutableArray alloc] init];
        NSString *recommendTitle = ACCPersonalRecommendGetWords(@"edit_music_panel_header");
        AWEVideoPublishMusicSelectTopTabItemData *recommendItem = [[AWEVideoPublishMusicSelectTopTabItemData alloc] initWithTitle:recommendTitle isLightStyle:NO];
        recommendItem.underlineSpace = underlineSpace;
        recommendItem.titleTopOffset = titleTopOffset;
        recommendItem.buttonLeftOffset = buttonLeftOffset;
        // 新音乐面板
        @weakify(self);
        recommendItem.selectedBlock = ^{
            @strongify(self);
            ACCBLOCK_INVOKE(self.didSelectTabHandler, 0);
            self.userCollectedMusicCollectionView.hidden = YES;
            self.collectionView.hidden = NO;
            [self.collectionView reloadData];
            
            self.musicViewModel.musicPanelViewModel.bgmMusicDisable = self.recommendMusicDisabel;
            self.currentTopTabStr = @"recommend";
            [ACCTracker() trackEvent:@"enter_music_tab" params:@{
                                                                                @"enter_from" : @"video_edit_page",
                                                                                @"creation_id" : self.publishModel.repoContext.createId ? : @"",
                                                                                @"shoot_way" : self.publishModel.repoTrack.referString ? : @"",
                                                                                @"content_source" : @(self.publishModel.repoContext.videoSource),
                                                                                @"content_type" : self.publishModel.repoTrack.referExtra[@"content_type"] ? : @"",
                                                                                @"tab_name": @"recommend"
                                                                                }];
        };
        [mItems addObject:recommendItem];

        AWEVideoPublishMusicSelectTopTabItemData *collectionItem = [[AWEVideoPublishMusicSelectTopTabItemData alloc] initWithTitle:ACCLocalizedString(@"profile_favourite", @"profile_favourite") isLightStyle:NO];
        collectionItem.underlineSpace = underlineSpace;
        collectionItem.titleTopOffset = titleTopOffset;
        collectionItem.buttonLeftOffset = buttonLeftOffset;
        collectionItem.selectedBlock = ^{
            @strongify(self);
            ACCBLOCK_INVOKE(self.didSelectTabHandler, 1);
            self.userCollectedMusicCollectionView.hidden = NO;
            self.collectionView.hidden = YES;
            [self updateUserCollectedMusicListIfNeeded];
            
            self.musicViewModel.musicPanelViewModel.bgmMusicDisable = self.userCollectionMusicDisable;
            
            //  用户收藏列表自动加载第一首歌曲
            if ([self autoSelectedCollectionMusic]) {
                [self.userCollectedMusicCollectionView layoutIfNeeded];
                self.musicViewModel.musicPanelViewModel.showPanelAutoSelectedMusic = NO;
                [self selectVisibleMusicItemWithCollectionView:self.userCollectedMusicCollectionView];
            }
            
            self.currentTopTabStr = @"recommend_favorite";
            [ACCTracker() trackEvent:@"enter_music_tab" params:@{
                                                                                @"enter_from" : @"video_edit_page",
                                                                                @"creation_id" : self.publishModel.repoContext.createId ? : @"",
                                                                                @"shoot_way" : self.publishModel.repoTrack.referString ? : @"",
                                                                                @"content_source" : @(self.publishModel.repoContext.videoSource),
                                                                                @"content_type" : self.publishModel.repoTrack.referExtra[@"content_type"] ? : @"",
                                                                                @"tab_name": @"favorite"
                                                                                }];
        };
        
        /// 限制仅在登录态展示配乐面板上的收藏按钮
        if ([IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin] && !self.musicViewModel.isCommerceLimitPanel) {
            [mItems addObject:collectionItem];
        }

        if (mItems.count == 1) {
            recommendItem.selected = YES;
        }
        _topTabView = [[AWEVideoPublishMusicSelectTopTabView alloc] initWithItems:mItems];
    }
    return _topTabView;
}

- (void)resetToFirstTabItem {
    [self.topTabView setItemClicked:self.topTabView.items.firstObject];
    self.collectionView.hidden = NO;
    self.userCollectedMusicCollectionView.hidden = YES;
    // 进入重置推荐音乐就算点击了面板
    [ACCTracker() trackEvent:@"enter_music_tab" params:@{
        @"enter_from" : @"video_edit_page",
        @"creation_id" : self.publishModel.repoContext.createId ? : @"",
        @"shoot_way" : self.publishModel.repoTrack.referString ? : @"",
        @"content_source" : @(self.publishModel.repoContext.videoSource),
        @"content_type" : self.publishModel.repoTrack.referExtra[@"content_type"] ? : @"",
        @"tab_name": @"recommend"
    }];
}

- (UISelectionFeedbackGenerator *)selectionFeedback {
    if (!_selectionFeedback) {
        _selectionFeedback = [[UISelectionFeedbackGenerator alloc] init];
    }
    return _selectionFeedback;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == _collectionView) {
        CGFloat height = kNewCollectionViewHeight;
        if (self.loadingAnimation) {
            return CGSizeMake(self.collectionView.acc_width - (54+30), height);
        }
        return CGSizeMake(ACC_SCREEN_WIDTH, height);
    } else if (_userCollectedMusicCollectionView) {
        CGFloat height = kNewCollectionViewHeight;
        return CGSizeMake(ACC_SCREEN_WIDTH, height);
    }
    return CGSizeZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
        return CGSizeZero;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView == _collectionView) {
        // 加载动画中
        if (self.loadingAnimation) {
            return 0;
        }
        
        return self.musicList.count;
    } else if (collectionView == _userCollectedMusicCollectionView) {
        if ([self.userCollectedMusicDelegate respondsToSelector:@selector(isProcessingFetchingData)] &&
            [self.userCollectedMusicDelegate isProcessingFetchingData] &&
            self.userCollectedMusicList.count == 0) {
            return 0;
        }
        
        return self.userCollectedMusicList.count;
    }
    return 0;
}

#pragma mark - UICollectionViewDelegate

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (collectionView == _collectionView) {
        
        NSString *reuseString = NSStringFromClass(ACCMusicSelectCollectionViewCell.class);
        ACCMusicSelectCollectionViewCell *cell = (ACCMusicSelectCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:reuseString forIndexPath:indexPath];
        cell.useBigLoadingIcon = YES;
        cell.delegate = self;
        
        if (indexPath.row < [self.musicList count]) {
            // config model
            id<ACCMusicModelProtocol> model = self.musicList[indexPath.row].musicModel;
            [cell setMusicThumbnailURLList:model.thumbURL.URLList];
            AWEPhotoMovieMusicStatus status = self.musicList[indexPath.row].status;
            [cell setDownloadStatus:status]; // 下载状态
            [cell updateMusicName:model.musicName author:model.authorName isPGC:model.isPGC matchedPGCTitle:[model awe_matchedPGCMusicInfoStringWithPrefix]];
            [cell setDuration:model.shootDuration.doubleValue ?: model.duration.doubleValue show:YES];
            AWEMusicSelectItem *musicItem = self.musicList[indexPath.row];
            [cell setIsRecommended:musicItem.isRecommended];
            
            // config cell status
            if ([indexPath isEqual:self.selectedIndexPath] && status == AWEPhotoMovieMusicStatusDownloaded) {
                // 同步cell的可操作状态
                [cell setIsCurrent:YES animated:NO completion:nil needForceUpdate:YES];
            } else {
                [cell setIsCurrent:NO animated:NO];
            }
        }
        return cell;
        
    } else if (collectionView == _userCollectedMusicCollectionView) {
        /// 当前一直在拉取首页的数据
        if ([self.userCollectedMusicDelegate respondsToSelector:@selector(currCursor)] &&
            self.userCollectedMusicDelegate.currCursor.unsignedIntegerValue == 0 &&
            [self.userCollectedMusicDelegate respondsToSelector:@selector(isProcessingFetchingData)] &&
            self.userCollectedMusicDelegate.isProcessingFetchingData) {
            AWEMusicLoadingAnimationCell *cell = (AWEMusicLoadingAnimationCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(AWEMusicLoadingAnimationCell.class) forIndexPath:indexPath];
            [cell startAnimating];
            return cell;
        }
        NSString *reuseString = NSStringFromClass(ACCMusicSelectCollectionViewCell.class);
        ACCMusicSelectCollectionViewCell *cell = (ACCMusicSelectCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:reuseString forIndexPath:indexPath];
        cell.useBigLoadingIcon = YES;
        cell.delegate = self;
        
        if (indexPath.row < self.userCollectedMusicList.count) {
            id<ACCMusicModelProtocol> model = self.userCollectedMusicList[indexPath.row].musicModel;
            [cell setMusicThumbnailURLList:model.thumbURL.URLList placeholder:nil];
            AWEPhotoMovieMusicStatus status = self.userCollectedMusicList[indexPath.row].status;
            [cell setDownloadStatus:status];
            [cell updateMusicName:model.musicName author:model.authorName isPGC:model.isPGC matchedPGCTitle:[model awe_matchedPGCMusicInfoStringWithPrefix]];
            [cell setDuration:model.shootDuration.doubleValue show:YES];
            if ([indexPath isEqual:self.selectedUserCollectedMusicIndexPath] && status == AWEPhotoMovieMusicStatusDownloaded) {
                [cell setIsCurrent:YES animated:NO completion:nil needForceUpdate:YES];
            } else {
                [cell setIsCurrent:NO animated:NO];
            }
        }
        return cell;
    }
    return [UICollectionViewCell new];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.musicViewModel.musicPanelViewModel.showPanelAutoSelectedMusic = NO; // 用户进入面板选择过音乐后则不进行自动选择
    if (collectionView == _collectionView) {
        if (self.loadingAnimation) {
            return;
        }
        if (indexPath.row >= [self.musicList count]) {
            return;
        }
        
        AWEPhotoMovieMusicStatus status = self.musicList[indexPath.row].status;
        id<ACCMusicModelProtocol> music = self.musicList[indexPath.row].musicModel;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ACCMusicSelectionViewDidShowDidChangeSelection object:self userInfo:@{ACCNotificationCurrentMusicIDKey : music.musicID ?: @""}];

        BOOL shouldTrack = NO;

        switch (status) {
            case AWEPhotoMovieMusicStatusNotDownload: {
                ACCMusicSelectCollectionViewCell *cell = [self _cellAtIndexPath:indexPath collectionView:collectionView];
                if (![self.selectedIndexPath isEqual:indexPath]) {
                    shouldTrack = YES;
                    [self p_startDownloadingMusic:music atIndexPath:indexPath collectionView:collectionView];
                } else { //deselect
                    // self.canDeselectMusic 用来判断是否允许取消选中音乐
                    // 某些情况下，不允许取消选中音乐，比如mv影集的音乐动效
                    if (self.canDeselectMusic) {
                        [self selectMusic:nil error:nil];
                        [cell setIsCurrent:NO animated:YES];
                        self.selectedIndexPath = nil;
                        self.previousSelectedIndexPath = nil;
                    }
                    ACCBLOCK_INVOKE(self.deselectMusicBlock);
                }
            }
                break;
            case AWEPhotoMovieMusicStatusDownloading:
                break;
            case AWEPhotoMovieMusicStatusDownloaded: {
                if (![self.selectedIndexPath isEqual:indexPath]) {//select music
                    [self p_selectMusicItem:music atIndexPath:indexPath collectionView:collectionView];
                    shouldTrack = YES;
                } else { //deselect
                    // self.canDeselectMusic 用来判断是否允许取消选中音乐
                    // 某些情况下，不允许取消选中音乐，比如mv影集的音乐动效
                    if (self.canDeselectMusic) {
                        ACCMusicSelectCollectionViewCell *cell = [self _cellAtIndexPath:indexPath collectionView:collectionView];
                        [self selectMusic:nil error:nil];

                        NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.publishModel.repoTrack.referExtra];
                        referExtra[@"enter_method"] = @"inverse_select";
                        referExtra[@"music_id"] = self.publishModel.repoMusic.music.musicID ?: @"";
                        [ACCTracker() trackEvent:@"unselect_music" params:referExtra needStagingFlag:NO];

                        [cell setIsCurrent:NO animated:YES];
                        self.selectedIndexPath = nil;
                        self.previousSelectedIndexPath = nil;
                    } else {
                        ACCBLOCK_INVOKE(self.deselectMusicBlock);
                    }
                }
            }
                break;
        }

        if (shouldTrack) {
            self.publishModel.repoMusic.musicSelectedFrom = @"edit_page_recommend";
            
            if (!self.musicID || (self.musicID && ![music.musicID isEqualToString:self.musicID])) {
                self.publishModel.repoMusic.musicTrackModel.musicShowRank = @(indexPath.row + 1).stringValue;
                self.publishModel.repoMusic.musicTrackModel.selectedMusicID = music.musicID;
            }

            if (!music.musicSelectedFrom && !music.awe_selectPageName) {
                music.musicSelectedFrom = @"recommend";
                music.awe_selectPageName = @"edit_page";
            }

            NSMutableDictionary *attributes = [self.publishModel.repoTrack.referExtra mutableCopy];
            [attributes setValue:music.musicID forKeyPath:@"music_id"];
            [attributes setValue:[NSString stringWithFormat:@"%d", (int)(indexPath.row + 1)] forKeyPath:@"music_show_rank"];
            [attributes setValue:[NSString stringWithFormat:@"%d", (int)[AWEAIMusicRecommendManager sharedInstance].musicFetchType] forKeyPath:@"music_rec_type"];
            [attributes setValue:@"recommend" forKey:@"tab_name"];
            [ACCTracker() trackEvent:@"select_music" params:attributes needStagingFlag:NO];
        }
    } else if (collectionView == _userCollectedMusicCollectionView) {
//        if (self.loadingAnimation) {
//            return;
//        }
        if (indexPath.row >= [self.userCollectedMusicList count]) {
            return;
        }

        AWEPhotoMovieMusicStatus status = self.userCollectedMusicList[indexPath.row].status;
        id<ACCMusicModelProtocol> music = self.userCollectedMusicList[indexPath.row].musicModel;

        BOOL shouldTrack = NO;
        switch (status) {
            case AWEPhotoMovieMusicStatusNotDownload: {
                ACCMusicSelectCollectionViewCell *cell = [self _cellAtIndexPath:indexPath collectionView:collectionView];
                if (![self.selectedUserCollectedMusicIndexPath isEqual:indexPath]) {
                    shouldTrack = YES;
                    [self p_startDownloadingMusic:music atIndexPath:indexPath collectionView:collectionView];
                } else { //deselect
                    if (AWEVideoTypePhotoToVideo == self.publishModel.repoContext.videoType && !ACCConfigBool(kConfigBool_enable_lightning_pic_to_video_optimize)) {
                        [ACCToast() show:ACCLocalizedString(@"creation_singlepic_cancelmusic", @"Cannot cancel a music under a single picture")];
                    } else {
                        [self selectMusic:nil error:nil];
                        [cell setIsCurrent:NO animated:YES];
                        self.selectedUserCollectedMusicIndexPath = nil;
                        self.previousSelectedUserCollectedMusicIndexPath = nil;
                    }
                }
            }
                break;
            case AWEPhotoMovieMusicStatusDownloading:
                break;
            case AWEPhotoMovieMusicStatusDownloaded: {
                ACCMusicSelectCollectionViewCell *cell = [self _cellAtIndexPath:indexPath collectionView:collectionView];
                if (![self.selectedUserCollectedMusicIndexPath isEqual:indexPath]) {//select music
                    [self p_selectMusicItem:music atIndexPath:indexPath collectionView:collectionView];
                    shouldTrack = YES;
                } else { //deselect
                    if (AWEVideoTypePhotoToVideo == self.publishModel.repoContext.videoType && !ACCConfigBool(kConfigBool_enable_lightning_pic_to_video_optimize)) {
                        [ACCToast() show:ACCLocalizedString(@"creation_singlepic_cancelmusic", @"Cannot cancel a music under a single picture")];
                    } else if (self.canDeselectMusic) {
                        [self selectMusic:nil error:nil];
                        [cell setIsCurrent:NO animated:YES];
                        self.selectedUserCollectedMusicIndexPath = nil;
                        self.previousSelectedUserCollectedMusicIndexPath = nil;
                    }
                }
            }
                break;
        }
        
        self.publishModel.repoMusic.musicSelectedFrom = @"edit_page_recommend_favourite";
        if (shouldTrack) {
            if (!self.musicID || (self.musicID && ![music.musicID isEqualToString:self.musicID])) {
                self.publishModel.repoMusic.musicTrackModel.musicShowRank = @(indexPath.row + 1).stringValue;
                self.publishModel.repoMusic.musicTrackModel.selectedMusicID = music.musicID;
            }

            if (!music.musicSelectedFrom && !music.awe_selectPageName) {
                music.musicSelectedFrom = @"recommend_favourite";
                music.awe_selectPageName = @"edit_page";
            }
            
            NSMutableDictionary *attributes = [self.publishModel.repoTrack.referExtra mutableCopy];
            [attributes setValue:music.musicID forKeyPath:@"music_id"];
            [attributes setValue:[NSString stringWithFormat:@"%d", (int)(indexPath.row + 1)] forKeyPath:@"music_show_rank"];
            [attributes setValue:[NSString stringWithFormat:@"%d", (int)[AWEAIMusicRecommendManager sharedInstance].musicFetchType] forKeyPath:@"music_rec_type"];
            [attributes setValue:@"favorite" forKey:@"tab_name"];
            [ACCTracker() trackEvent:@"select_music" params:attributes needStagingFlag:NO];
        }
    }
    self.previousActivedCollectionView = collectionView;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *musicID;
    if (collectionView == _collectionView) {
        if (self.loadingAnimation) {
            return;
        }

        if (indexPath.row >= [self.musicList count]) {
            return;
        }

        ACCMusicSelectCollectionViewCell *musicCell = (ACCMusicSelectCollectionViewCell *)cell;
        AWEPhotoMovieMusicStatus status = self.musicList[indexPath.row].status;
        [musicCell setDownloadStatus:status];
        if ([indexPath isEqual:self.selectedIndexPath]) {
            [musicCell setIsCurrent:YES animated:NO];
        } else {
            [musicCell setIsCurrent:NO animated:NO];
        }

        musicID = self.musicList[indexPath.row].musicModel.musicID;
    } else if (collectionView == _userCollectedMusicCollectionView) {
//        if (self.loadingAnimation) {
//            return;
//        }
        if (indexPath.row >= [self.userCollectedMusicList count]) {
            return;
        }

        ACCMusicSelectCollectionViewCell *musicCell = (ACCMusicSelectCollectionViewCell *)cell;
        AWEPhotoMovieMusicStatus status = self.userCollectedMusicList[indexPath.row].status;
        [musicCell setDownloadStatus:status];
        if ([indexPath isEqual:self.selectedUserCollectedMusicIndexPath]) {
            [musicCell setIsCurrent:YES animated:NO];
        } else {
            [musicCell setIsCurrent:NO animated:NO];
        }
        musicID = self.userCollectedMusicList[indexPath.row].musicModel.musicID;
    }
    if (![self.trackingMusicIDs containsObject:musicID] && musicID.length > 0 && !collectionView.hidden) {
        NSMutableDictionary *attributes = [self.publishModel.repoTrack.referExtra mutableCopy];
        attributes[@"music_id"] = musicID ?: @"";
        attributes[@"music_rec_type"] = [NSString stringWithFormat:@"%d", (int)[AWEAIMusicRecommendManager sharedInstance].musicFetchType];
        attributes[@"tab_name"] = collectionView == _collectionView ? @"recommend" : @"favorite";
        [self.trackingMusicIDs addObject:musicID];
        
        [self p_track_music_show_withParams:attributes];
    }
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // 响应既定的selector && 还拥有更多数据 && 并且没用正在处理的网络请求
    if (scrollView == _userCollectedMusicCollectionView &&
        self.userCollectedMusicDelegate &&
        [self.userCollectedMusicDelegate respondsToSelector:@selector(hasMore)] &&
        [self.userCollectedMusicDelegate hasMore] &&
        [self.userCollectedMusicDelegate respondsToSelector:@selector(fetchNextPage:)] &&
        [self.userCollectedMusicDelegate respondsToSelector:@selector(isProcessingFetchingData)] &&
        ![self.userCollectedMusicDelegate isProcessingFetchingData]) {
        
        CGFloat y = scrollView.contentOffset.y;
        // 如果滑到了右边最后一个，并且有更多的内容，那么展示loading并且获取新数据
        if (y + 100 >= scrollView.contentSize.height - scrollView.frame.size.height) {
            self.isFetchingMoreUserCollectedMusics = YES;
            [self updateUserCollectedMusicCollectionInset];
            [self.userCollectedMusicCollectionView startLoadingMoreAnimating];
            @weakify(self);
            [self.userCollectedMusicDelegate fetchNextPage:^(BOOL success) {
                @strongify(self);
                self.isFetchingMoreUserCollectedMusics = NO;
                [self updateUserCollectedMusicCollectionInset];
                [self.userCollectedMusicCollectionView stopLoadingMoreAnimating];
            }];
        } else {
            self.isFetchingMoreUserCollectedMusics = NO;
        }
    }
}

- (void)setIsFetchingMoreUserCollectedMusics:(BOOL)isFetchingMoreUserCollectedMusics {
    _isFetchingMoreUserCollectedMusics = isFetchingMoreUserCollectedMusics;
}

- (void)updateUserCollectedMusicCollectionInset {
    UIEdgeInsets ori = self.userCollectedMusicCollectionView.contentInset;
    [UIView animateWithDuration:0.2 animations:^{
        if (self.isFetchingMoreUserCollectedMusics) {
            self.userCollectedMusicCollectionView.contentInset = UIEdgeInsetsMake(ori.top, ori.left, kUserCollectedCollectionViewInsetRightFetching, ori.right);
        } else {
            self.userCollectedMusicCollectionView.contentInset = UIEdgeInsetsMake(ori.top, ori.left, kUserCollectedCollectionViewInsetRightNone, ori.right);
        }
    }];
}


#pragma mark - private methods

+ (CGSize)adaptionMusicCollectionViewSize {
    CGFloat scaleWidth = ACC_SCREEN_WIDTH;
    CGFloat scaleHeight = 303 * scaleWidth / 375;
    return CGSizeMake(scaleWidth, scaleHeight);
}

- (void)p_startDownloadingMusic:(id<ACCMusicModelProtocol>)model
                   atIndexPath:(NSIndexPath *)indexPath
                collectionView:(UICollectionView *)collectionView {
    if (model.isDownloading) {
        return;
    }
    model.isDownloading = YES;
    
    AWEMusicSelectItem *item = nil;
    if (collectionView == _collectionView) {
        self.previousSelectedIndexPath = indexPath;
        item = self.musicList[indexPath.row];
    } else if (collectionView == _userCollectedMusicCollectionView) {
        self.previousSelectedUserCollectedMusicIndexPath = indexPath;
        item = self.userCollectedMusicList[indexPath.row];
    }
    item.status = AWEPhotoMovieMusicStatusDownloading;
    [self _updateMusicDownloadStatus:AWEPhotoMovieMusicStatusDownloading
                  forCellAtIndexPath:indexPath
                      collectionView:collectionView];

    //是异步请求，要注意数据源的变动，搜 updateWithMusicList:playingMusic: 的调用
    @weakify(self);
    [ACCVideoMusic() fetchLocalURLForMusic:model lyricURL:model.lyricUrl extraTrack:@{@"enter_from" : @"video_edit_page"} withProgress:nil completion:^(NSURL *localMusicURL, NSURL *localLyricURL, NSError *error) {
        model.isDownloading = NO;
        if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
            return;
        }
        
        @strongify(self);
        acc_dispatch_main_async_safe(^{
            if (collectionView == self.collectionView && indexPath.row < self.musicList.count) {
                AWEMusicSelectItem *updatedItem = self.musicList[indexPath.row];
                if (error) {
                    [ACCToast() showError:ACCLocalizedCurrentString(@"load_failed")];
                    AWELogToolError2(@"music", AWELogToolTagMusic, @"fetchLocalURLForMusic failed, error:%@", error);
                    updatedItem.status = AWEPhotoMovieMusicStatusNotDownload;
                    [self _updateMusicDownloadStatus:AWEPhotoMovieMusicStatusNotDownload forCellAtIndexPath:indexPath collectionView:collectionView];
                } else {
                    updatedItem.localLyricURL = localLyricURL;
                    updatedItem.startTime = model.previewStartTime;
                    model.loaclAssetUrl = localMusicURL;
                    updatedItem.status = AWEPhotoMovieMusicStatusDownloaded;
                    [self _updateMusicDownloadStatus:AWEPhotoMovieMusicStatusDownloaded forCellAtIndexPath:indexPath collectionView:collectionView];
                    if ([self.previousSelectedIndexPath isEqual:indexPath]) {
                        [self p_selectMusicItem:model atIndexPath:indexPath collectionView:collectionView];
                    }
                }
            } else if (collectionView == self.userCollectedMusicCollectionView && indexPath.row < self.userCollectedMusicList.count) {
                AWEMusicSelectItem *updatedItem = self.userCollectedMusicList[indexPath.row];
                if (error) {
                    [ACCToast() showError:ACCLocalizedCurrentString(@"load_failed")];
                    AWELogToolError2(@"music", AWELogToolTagMusic, @"fetchLocalURLForMusic failed, error:%@", error);
                    updatedItem.status = AWEPhotoMovieMusicStatusNotDownload;
                    [self _updateMusicDownloadStatus:AWEPhotoMovieMusicStatusNotDownload forCellAtIndexPath:indexPath collectionView:collectionView];
                } else {
                    updatedItem.localLyricURL = localLyricURL;
                    updatedItem.startTime = model.previewStartTime;
                    model.loaclAssetUrl = localMusicURL;
                    updatedItem.status = AWEPhotoMovieMusicStatusDownloaded;
                    [self _updateMusicDownloadStatus:AWEPhotoMovieMusicStatusDownloaded forCellAtIndexPath:indexPath collectionView:collectionView];
                    if ([self.previousSelectedUserCollectedMusicIndexPath isEqual:indexPath]) {
                        [self p_selectMusicItem:model atIndexPath:indexPath collectionView:collectionView];
                    }
                }
            }
        });
    }];
}

- (void)p_selectMusicItem:(id<ACCMusicModelProtocol>)model
             atIndexPath:(NSIndexPath *)indexPath
          collectionView:(UICollectionView *)collectionView {
    if (self.musicSelectionInProgress || self.mvChangeMusicInProgress) {
        return;
    }
    [self generateLightImpact];
    UICollectionView *previousCollectionView = self.previousActivedCollectionView;
    self.musicSelectionInProgress = YES;
    if (collectionView == _collectionView) {
        [self deselectPreviousCellsWithCurrClickedCollectionView:collectionView];
        self.previousSelectedIndexPath = indexPath;
        NSIndexPath *fromIndexPath = self.previousActivedCollectionView == _collectionView ? self.selectedIndexPath : self.selectedUserCollectedMusicIndexPath;
        @weakify(self);
        acc_dispatch_main_async_safe(^{
            @strongify(self);
            [self _updateSelectedIndicatorFromIndexPath:fromIndexPath
                                            toIndexPath:indexPath
                                     fromCollectionView:previousCollectionView
                                       toCollectionView:collectionView
                                             completion:^(BOOL finished) {
                                                 @strongify(self);
                                                 if (indexPath.row < [self.musicList count]) {
                                                     HTSAudioRange range = {0};
                                                     self.publishModel.repoMusic.audioRange = range;
                                                     self.selectedIndexPath = indexPath;
                                                     [self selectMusic:self.musicList[indexPath.row] error:nil];
                                                 }
                                                 self.musicSelectionInProgress = NO;
                                             }];
        });
    } else if (collectionView == _userCollectedMusicCollectionView) {
        [self deselectPreviousCellsWithCurrClickedCollectionView:collectionView];
        self.previousSelectedUserCollectedMusicIndexPath = indexPath;
        @weakify(self);
        acc_dispatch_main_async_safe(^{
            @strongify(self);
            NSIndexPath *fromIndexPath = self.previousActivedCollectionView == self.collectionView ? self.selectedIndexPath : self.selectedUserCollectedMusicIndexPath;
            [self _updateSelectedIndicatorFromIndexPath:fromIndexPath
                                            toIndexPath:indexPath
                                     fromCollectionView:previousCollectionView
                                       toCollectionView:collectionView
                                             completion:^(BOOL finished) {
                                                 @strongify(self);
                                                 if (indexPath.row < [self.userCollectedMusicList count]) {
                                                     HTSAudioRange range = {0};
                                                     self.publishModel.repoMusic.audioRange = range;
                                                     self.selectedUserCollectedMusicIndexPath = indexPath;
                                                     [self selectMusic:self.userCollectedMusicList[indexPath.row] error:nil];
                                                 }
                                                 self.musicSelectionInProgress = NO;
                                             }];
        });
    }
    if (!self.hasReportSelectMusic) {
        self.hasReportSelectMusic = YES;
        NSDictionary *params = @{
                                 @"enter_from" : @"video_edit_page",
                                 @"creation_id" : self.publishModel.repoContext.createId ? : @"",
                                 @"shoot_way" : self.publishModel.repoTrack.referString ? : @"",
                                 @"content_source" : @(self.publishModel.repoContext.videoSource),
                                 @"content_type" : self.publishModel.repoTrack.referExtra[@"content_type"] ? : @"",
                                 @"tab_name": collectionView == _collectionView ? @"recommend" : @"favorite",
                                 @"music_id": self.publishModel.repoMusic.music.musicID ? : @""
                                 };
        [self p_track_music_show_withParams:params];
    }
}

- (void)deselectPreviousCellsWithCurrClickedCollectionView:(UICollectionView *)collectionView {
    ACCMusicSelectCollectionViewCell *cell;
    if (self.selectedUserCollectedMusicIndexPath && self.selectedUserCollectedMusicIndexPath.row < [self.userCollectedMusicList count]) {
        cell = [self _cellAtIndexPath:self.selectedUserCollectedMusicIndexPath collectionView:self.userCollectedMusicCollectionView];
    }
    ACCMusicSelectCollectionViewCell *cell1;
    if (self.selectedIndexPath && self.selectedIndexPath.row < [self.musicList count]) {
        cell1 = [self _cellAtIndexPath:self.selectedIndexPath collectionView:self.collectionView];
    }

    // 判断下selector响应，因为有可能cell是AWEMusicLoadingAnimationCell
    if ([cell respondsToSelector:@selector(setIsCurrent:animated:)]) {
        [cell setIsCurrent:NO animated:YES];
    }
    if ([cell1 respondsToSelector:@selector(setIsCurrent:animated:)]) {
        [cell1 setIsCurrent:NO animated:YES];
    }
    if (self.selectedIndexPath && self.selectedIndexPath.row < [self.musicList count]) {
        [self.collectionView deselectItemAtIndexPath:self.selectedIndexPath animated:NO];
    }
    if (self.selectedUserCollectedMusicIndexPath && self.selectedUserCollectedMusicIndexPath.row < [self.userCollectedMusicList count]) {
        [self.userCollectedMusicCollectionView deselectItemAtIndexPath:self.selectedUserCollectedMusicIndexPath animated:NO];
    }
    if (collectionView == _collectionView) {
        self.selectedUserCollectedMusicIndexPath = nil;
        self.previousSelectedUserCollectedMusicIndexPath = nil;
    } else if (collectionView == _userCollectedMusicCollectionView) {
        self.selectedIndexPath = nil;
        self.previousSelectedIndexPath = nil;
    }
}

- (ACCMusicSelectCollectionViewCell *)_cellAtIndexPath:(NSIndexPath *)indexPath
                                             collectionView:(UICollectionView *)collectionView {
    return (ACCMusicSelectCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
}

- (void)_updateSelectedIndicatorFromIndexPath:(NSIndexPath *)previousIndexPath
                                  toIndexPath:(NSIndexPath *)currentIndexPath
                               fromCollectionView:(UICollectionView *)fromCollectionView
                               toCollectionView:(UICollectionView *)toCollectionView
                                   completion:(void (^)(BOOL))completion
{
    if (![previousIndexPath isEqual:currentIndexPath] || fromCollectionView != toCollectionView) {
        ACCMusicSelectCollectionViewCell *oldCell = [self _cellAtIndexPath:previousIndexPath collectionView:fromCollectionView];
        ACCMusicSelectCollectionViewCell *newCell = [self _cellAtIndexPath:currentIndexPath collectionView:toCollectionView];
        if (oldCell) {
            @weakify(newCell);
            [oldCell setIsCurrent:NO animated:YES completion:^(BOOL finished) {
                @strongify(newCell);
                if (newCell) {
                    [newCell setIsCurrent:YES animated:YES completion:completion needForceUpdate:NO];
                } else {
                    ACCBLOCK_INVOKE(completion, YES);
                }
            }];
        } else {
            if (newCell) {
                [newCell setIsCurrent:YES animated:YES completion:completion needForceUpdate:NO];
            } else {
                ACCBLOCK_INVOKE(completion, YES);
            }
        }
    } else {
        ACCBLOCK_INVOKE(completion, YES);
    }
}

- (void)selectMusic:(AWEMusicSelectItem *)musicItem error:(NSError *)error
{
    [self selectMusic:musicItem error:error autoPlay:YES];
}

- (void)selectMusic:(AWEMusicSelectItem *)musicItem error:(NSError *)error autoPlay:(BOOL)autoPlay
{
    if (musicItem) {
        self.musicViewModel.musicPanelViewModel.showPanelAutoSelectedMusic = NO; // 外部带入的音乐也需要禁用自动加载歌曲
        self.selectedMusic = musicItem;
        ACCBLOCK_INVOKE(self.didSelectMusicHandler, musicItem.musicModel, nil, error, YES);
    } else {
        AWEMusicSelectItem *cancelMusicItem = self.selectedMusic;
        self.selectedMusic = nil;
        [self updateActionButtonsWithMusic:nil]; // 此时已经清空selectedIndexPath和selectedUserCollectedMusicIndexPath
        ACCBLOCK_INVOKE(self.didSelectMusicHandler, nil, cancelMusicItem.musicModel, error, autoPlay);
        [self deselectPreviousCellsWithCurrClickedCollectionView:_collectionView];
        [self deselectPreviousCellsWithCurrClickedCollectionView:_userCollectedMusicCollectionView];
    }
}

- (void)deselectMusic {
    [self deselectPreviousCellsWithCurrClickedCollectionView:self.collectionView];
    [self deselectPreviousCellsWithCurrClickedCollectionView:self.userCollectedMusicCollectionView];
    [self selectMusic:nil error:nil];
}

- (void)synOperationWithSelectedMusicCell:(ACCMusicSelectCollectionViewCell *)musicCell {
    [self synClipButtonStatusWithCell:musicCell];
    [self synLyricStickerStatusWithCell:musicCell];
    [self synFavoriteButtonStatusWithCell:musicCell];
}

- (void)synLyricStickerStatus {
    if (self.selectedIndexPath != nil && self.selectedIndexPath.row < [self.musicList count]) {
        ACCMusicSelectCollectionViewCell *cell = [self _cellAtIndexPath:self.selectedIndexPath collectionView:self.collectionView];
        [cell setIsCurrent:YES animated:NO];
        [self synLyricStickerStatusWithCell:cell];
    }
    
    if (self.selectedUserCollectedMusicIndexPath != nil && self.selectedUserCollectedMusicIndexPath.row <  [self.userCollectedMusicList count]) {
        ACCMusicSelectCollectionViewCell *cell = [self _cellAtIndexPath:self.selectedUserCollectedMusicIndexPath collectionView:self.userCollectedMusicCollectionView];
        [cell setIsCurrent:YES animated:NO];
        [self synLyricStickerStatusWithCell:cell];
    }
}

- (void)synLyricStickerStatusWithCell:(ACCMusicSelectCollectionViewCell *)musicCell {
    [musicCell updateLyricStickerButtonStatus:self.lyricStickerButton];
}

- (void)synClipButtonStatus {
    if (self.selectedIndexPath != nil && self.selectedIndexPath.row < [self.musicList count]) {
        ACCMusicSelectCollectionViewCell *cell = [self _cellAtIndexPath:self.selectedIndexPath collectionView:self.collectionView];
        [cell setIsCurrent:YES animated:NO];
        [self synClipButtonStatusWithCell:cell];
    }
    
    if (self.selectedUserCollectedMusicIndexPath != nil && self.selectedUserCollectedMusicIndexPath.row <  [self.userCollectedMusicList count]) {
        ACCMusicSelectCollectionViewCell *cell = [self _cellAtIndexPath:self.selectedUserCollectedMusicIndexPath collectionView:self.userCollectedMusicCollectionView];
        [cell setIsCurrent:YES animated:NO];
        [self synClipButtonStatusWithCell:cell];
    }
}

- (void)synClipButtonStatusWithCell:(ACCMusicSelectCollectionViewCell *)musicCell {
    [musicCell  updateClipButtonStatus:self.clipButton];
}

- (void)synFavoriteButtonStatus {
    if (self.selectedIndexPath != nil && self.selectedIndexPath.row < [self.musicList count]) {
        ACCMusicSelectCollectionViewCell *cell = [self _cellAtIndexPath:self.selectedIndexPath collectionView:self.collectionView];
        [cell setIsCurrent:YES animated:NO];
        [self synFavoriteButtonStatusWithCell:cell];
    }
    
    if (self.selectedUserCollectedMusicIndexPath != nil && self.selectedUserCollectedMusicIndexPath.row <  [self.userCollectedMusicList count]) {
        ACCMusicSelectCollectionViewCell *cell = [self _cellAtIndexPath:self.selectedUserCollectedMusicIndexPath collectionView:self.userCollectedMusicCollectionView];
        [cell setIsCurrent:YES animated:NO];
        [self synFavoriteButtonStatusWithCell:cell];
    }
}

- (void)synFavoriteButtonStatusWithCell:(ACCMusicSelectCollectionViewCell *)musicCell {
    [musicCell updateFavoriteButtonStatus:self.favoriteButton];
}

- (void)generateLightImpact {
    if (@available(iOS 10.0, *)) {
        [self.selectionFeedback prepare];
        [self.selectionFeedback selectionChanged];
    }
}

#pragma mark -  AI/Hot music

- (BOOL)selectVisibleMusicItemWithCollectionView:(UICollectionView *)collectionView {
    if (self.userCollectedMusicCollectionView == collectionView) {
        // 收藏列表
        if (self.selectedUserCollectedMusicIndexPath || self.previousSelectedUserCollectedMusicIndexPath) {
            return NO;
        }
        NSArray<NSIndexPath *> *indexPathsForVisibleItems = [self.userCollectedMusicCollectionView indexPathsForVisibleItems];
        __block NSIndexPath *firstVisibleIndex = indexPathsForVisibleItems.firstObject;
        [indexPathsForVisibleItems enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.row < firstVisibleIndex.row) {
                firstVisibleIndex = obj;
            }
        }];
        if (indexPathsForVisibleItems.count > 0 && firstVisibleIndex.row < [self.musicList count]) {
            [self collectionView:self.userCollectedMusicCollectionView didSelectItemAtIndexPath:firstVisibleIndex];
        }
    } else if (self.collectionView == collectionView) {
        // 音乐列表
        if (self.selectedIndexPath || self.previousSelectedIndexPath) {
            return NO;
        }
        NSArray<NSIndexPath *> *indexPathsForVisibleItems = [self.collectionView indexPathsForVisibleItems];
        __block NSIndexPath *firstVisibleIndex = indexPathsForVisibleItems.firstObject;
        [indexPathsForVisibleItems enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.row < firstVisibleIndex.row) {
                firstVisibleIndex = obj;
            }
        }];
        if (indexPathsForVisibleItems.count > 0 && firstVisibleIndex.row < [self.musicList count]) {
            [self collectionView:self.collectionView didSelectItemAtIndexPath:firstVisibleIndex];
        }
    }
    return NO;
}

- (BOOL)selectVisibleMusicItem {
    AWEVideoPublishMusicSelectTopTabItemData *item = self.topTabView.items.firstObject;
    if (item.selected) {
        return [self selectVisibleMusicItemWithCollectionView:self.collectionView];
    } else {
        AWEVideoPublishMusicSelectTopTabItemData *userCollectionItem = self.topTabView.items.count > 1 ? self.topTabView.items[1] : nil;
        if (userCollectionItem.selected) {
            return [self selectVisibleMusicItemWithCollectionView:self.userCollectedMusicCollectionView];
        } else {
            return NO;
        }
    }
}

- (BOOL)autoSelectedCollectionMusic {
    AWEVideoPublishMusicSelectTopTabItemData *item = self.topTabView.items.count > 1 ? self.topTabView.items[1] : nil;
    if (self.musicViewModel.musicPanelViewModel.isShowing && [ACCMusicPanelViewModel autoSelectedMusic] && self.musicViewModel.musicPanelViewModel.showPanelAutoSelectedMusic && !self.selectedUserCollectedMusicIndexPath && !self.previousSelectedUserCollectedMusicIndexPath && !self.selectedIndexPath && !self.previousSelectedIndexPath && [self.userCollectedMusicList count] && item.selected) {
        return YES;
    } else {
        return NO;
    }
}

- (void)trackFirstDismissPanelMusicType {
    if ([self.musicList count] > 0 && self.topTabView.items.firstObject.selected) { // 音乐列表刷新完成且有音乐数据 & 当前推荐tab选中
        if (!self.musicViewModel.musicPanelViewModel.trackFirstDismissMusicType) {
            self.musicViewModel.musicPanelViewModel.trackFirstDismissMusicType = YES;
            NSString *musicRecType = @"default";
            if (![self.musicViewModel.recommendMusicRequestManager usedDefaultMusicList]) {
                if ([self.musicViewModel.recommendMusicRequestManager usedNewClipForMultiUploadVideosFetchHotMusic] || [self.musicViewModel.recommendMusicRequestManager useHotMusic]) {
                    musicRecType = @"hot_music";
                } else {
                    musicRecType = @"recommend_music";
                }
            }
            NSDictionary *params = @{
                @"music_rec_type": musicRecType,
                @"enter_from" : @"video_edit_page",
                @"duration" : @(self.musicViewModel.showMusicDurationTime),
                @"creation_id" : self.publishModel.repoContext.createId ?: @"" };
            [ACCTracker() trackEvent:@"music_recommend_leave" params:params needStagingFlag:NO];
        }
    }
}

- (BOOL)autoSelectedRecommendMusic {
    // 前置判断条件  1.面板正在展现 / 音乐列表刷新完成且有音乐数据 / 当前推荐tab选中
    if (self.musicViewModel.musicPanelViewModel.isShowing && [self.musicList count] > 0 && self.topTabView.items.firstObject.selected) {
        // 进行面板展现音乐的类型埋点
        if (!self.musicViewModel.musicPanelViewModel.trackFirstShowMusicType) {
            self.musicViewModel.musicPanelViewModel.trackFirstShowMusicType = YES;
            NSString *musicRecType = @"default";
            if (![self.musicViewModel.recommendMusicRequestManager usedDefaultMusicList]) {
                if ([self.musicViewModel.recommendMusicRequestManager usedNewClipForMultiUploadVideosFetchHotMusic] || [self.musicViewModel.recommendMusicRequestManager useHotMusic]) {
                    musicRecType = @"hot_music";
                } else {
                    musicRecType = @"recommend_music";
                }
            }
            NSInteger duration = (NSInteger)((CFAbsoluteTimeGetCurrent() - self.musicViewModel.showMusicPanelTime)*1000);
            self.musicViewModel.showMusicDurationTime = duration;
            NSDictionary *params = @{
                @"music_rec_type": musicRecType,
                @"enter_from" : @"video_edit_page",
                @"duration" : @(duration),
                @"creation_id" : self.publishModel.repoContext.createId ?: @"" };
            [ACCTracker() trackEvent:@"music_recommend_from" params:params needStagingFlag:NO];
        }
    } else {
        return NO;
    }
    
    // 后置判断条件 2.支持打开面板自动选歌 / 首次打开面板有能力自动选歌 / 未选中任何歌曲
    if ([ACCMusicPanelViewModel autoSelectedMusic] && self.musicViewModel.musicPanelViewModel.showPanelAutoSelectedMusic && !self.selectedUserCollectedMusicIndexPath && !self.previousSelectedUserCollectedMusicIndexPath && !self.selectedIndexPath && !self.previousSelectedIndexPath) {
        if ([self.musicViewModel.recommendMusicRequestManager usedDefaultMusicList]) { // 自动选择音乐不适用兜底音乐
            self.musicViewModel.musicPanelViewModel.showPanelAutoSelectedMusic = NO;
            return NO;
        } else {
            return YES;
        }
    } else {
        return NO;
    }
}

#pragma mark - user collection music

- (void)updateUserCollectionViewState {
    if (!_userCollectedMusicList) {
        [((UICollectionView<ACCMusicCollectionViewProtocol> *)self.userCollectedMusicCollectionView) showRetryButton];
    } else {
        [((UICollectionView<ACCMusicCollectionViewProtocol> *)self.userCollectedMusicCollectionView) hideRetryButton];
        if (self.userCollectedMusicList.count == 0) {
            ((UICollectionView<ACCMusicCollectionViewProtocol> *)self.userCollectedMusicCollectionView).emptyCollectionLabel.hidden = NO;
        } else if (self.userCollectedMusicList && self.userCollectedMusicList.count != 0){
            ((UICollectionView<ACCMusicCollectionViewProtocol> *)self.userCollectedMusicCollectionView).emptyCollectionLabel.hidden = YES;
        }
    }
}

- (void)updateUserCollectedMusicListIfNeeded
{
    NSMutableArray *musicList = [NSMutableArray array];
    [self.userCollectedMusicList enumerateObjectsUsingBlock:^(AWEMusicSelectItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.musicModel.isFavorite) {
            // 添加喜欢的音乐列表
            [musicList acc_addObject:obj];
        }
    }];
    if (musicList.count != self.userCollectedMusicList.count) {
        [self updateWithUserCollectedMusicList:musicList];
    } else {
        [self.userCollectedMusicCollectionView reloadData];
    }
}

- (void)updateWithUserCollectedMusicList:(NSMutableArray <AWEMusicSelectItem *> *)userCollectedMusicList {
    [self.userCollectedMusicCollectionView stopFirstLoadingAnimation];
    NSMutableArray <AWEMusicSelectItem *> *old = _userCollectedMusicList;
    NSMutableArray <AWEMusicSelectItem *> *new = userCollectedMusicList;
    BOOL needReload = YES;
    if (new.count >= old.count && old.count > 0) {
        needReload = NO;
        NSInteger count = old.count;
        for (NSInteger i=0; i < count; i++) {
            if (![old[i].musicModel.musicID isEqualToString:new[i].musicModel.musicID]) {
                needReload = YES;
                break;
            }
        }
    }
    if (!needReload && new.count > old.count) {
        @weakify(self);
        NSInteger diff = new.count - old.count;
        [self.userCollectedMusicCollectionView performBatchUpdates:^{
            @strongify(self);
            NSMutableArray<NSIndexPath *> *idps = [[NSMutableArray alloc] initWithCapacity:diff];
            for (int i = 0; i< diff; i++) {
                [idps addObject:[NSIndexPath indexPathForRow:old.count + i inSection:0]];
            }
            self.userCollectedMusicList = new;
            [self updateSelectedIndex];
            [self.userCollectedMusicCollectionView insertItemsAtIndexPaths:idps];
        } completion:NULL];
    } else if (needReload) {
        _userCollectedMusicList = new;
        [self updateSelectedIndex];
        [self.userCollectedMusicCollectionView reloadData];
    }
    //  控制toolbar的checkbox用户收藏音乐状态
    if ([self.userCollectedMusicList count]) {
        self.userCollectionMusicDisable = NO;
    } else {
        self.userCollectionMusicDisable = YES;
    }
    AWEVideoPublishMusicSelectTopTabItemData *item = self.topTabView.items.count > 1 ? self.topTabView.items[1] : nil;
    if (item.selected) {
        self.musicViewModel.musicPanelViewModel.bgmMusicDisable = self.userCollectionMusicDisable;
    }
    
    //  用户收藏列表自动加载第一首歌曲
    if ([self autoSelectedCollectionMusic]) {
        [self.userCollectedMusicCollectionView layoutIfNeeded];
        self.musicViewModel.musicPanelViewModel.showPanelAutoSelectedMusic = NO;
        [self selectVisibleMusicItemWithCollectionView:self.userCollectedMusicCollectionView];
    }
    [self updateUserCollectionViewState];
}

#pragma mark - ACCMusicSelectCollectionViewCellDelegate

- (void)updateCellActionStatus:(ACCMusicSelectCollectionViewCell *)musicCell {
    // 更新可操作状态
    [self synOperationWithSelectedMusicCell:musicCell];
}

- (void)cellFavoriteButtonTapped:(UIButton *)sender {
    [self toggleFavorite:sender];
}

- (void)cellClipMusicButtonTapped:(UIButton *)sender {
    [self clipMusic:sender];
}

- (void)cellToggleLyricStickerTapped:(UIButton *)sender {
    [self toggleLyricSticker:sender];
}

#pragma mark - Event Handling

- (void)musicDiscoverButtonTapped:(UIButton *)sender {
    self.musicViewModel.musicPanelViewModel.showPanelAutoSelectedMusic = NO;
    ACCBLOCK_INVOKE(self.enterMusicLibraryHandler);
}

- (void)toggleLyricSticker:(UIButton *)sender
{
    sender.selected = !sender.selected;
    self.lyricStickerButton.selected = !self.lyricStickerButton.selected;
    
    if(sender.selected){
        sender.enabled = NO;
        ACCBLOCK_INVOKE(self.willAddLyricStickerHandler, self.selectedMusic.musicModel);//添加歌词贴纸
        NSDictionary *params = @{
                                        @"category_name": self.currentTopTabStr ? : @"recommend",
                                        @"enter_from" : @"video_edit_page",
                                        @"shoot_way" : self.publishModel.repoTrack.referString ? : @"",
                                        @"creation_id" : self.publishModel.repoContext.createId ? : @"",
                                        @"content_source" : @(self.publishModel.repoContext.videoSource),
                                        @"shoot_entrance" : self.publishModel.repoTrack.referString ? : @"",
                                        @"prop_id": self.publishModel.repoSticker.currentLyricStickerID ? : @"",
                                        @"content_type" : self.publishModel.repoTrack.referExtra[@"content_type"] ? : @""
                                        };
        if (self.publishModel.repoContext.recordSourceFrom == AWERecordSourceFromUnknown) {
            [ACCTracker() trackEvent:@"prop_click" params:params];
        }
    }
    else{
        ACCBLOCK_INVOKE(self.willRemoveLyricStickerHandler);//移除歌词贴纸
        NSDictionary *params = @{
                                        @"category_name": self.currentTopTabStr ? : @"recommend",
                                        @"enter_from" : @"video_edit_page",
                                        @"shoot_way" : self.publishModel.repoTrack.referString ? : @"",
                                        @"creation_id" : self.publishModel.repoContext.createId ? : @"",
                                        @"content_source" : @(self.publishModel.repoContext.videoSource),
                                        @"shoot_entrance" : self.publishModel.repoTrack.referString ? : @"",
                                        @"prop_id": self.publishModel.repoSticker.currentLyricStickerID ? : @"",
                                        @"content_type" : self.publishModel.repoTrack.referExtra[@"content_type"] ? : @""
                                        };
        [ACCTracker() trackEvent:@"prop_delete" params:params];
    }
}

- (void)clipMusic:(id)sender
{
    if (self.clipButtonClickHandler != nil) {
        self.clipButtonClickHandler();
    }
}

- (void)toggleFavorite:(UIButton *)sender
{
    sender.selected = !sender.selected;
    self.favoriteButton.selected = !self.favoriteButton.selected;
    
    BOOL selectedMusicIsNotInFavoriteTab = self.selectedMusic != nil && self.selectedUserCollectedMusicIndexPath == nil;
    if (!self.collectionView.hidden || selectedMusicIsNotInFavoriteTab) { // favorite action on recommend list
        NSMutableArray<AWEMusicSelectItem *> *collected = self.userCollectedMusicList.mutableCopy;
        NSInteger index = [self findMusicItem:self.selectedMusic inList:collected];
        if (sender.isSelected) {
            if (index != NSNotFound) {
                collected[index].musicModel = self.selectedMusic.musicModel;
            } else {
                [collected insertObject:self.selectedMusic atIndex:0];
            }
        } else {
            if (index != NSNotFound) {
                collected[index].musicModel = self.selectedMusic.musicModel;
            }
        }
        [self updateWithUserCollectedMusicList:collected];
    }
    ACCBLOCK_INVOKE(self.favoriteButtonClickHandler, self.selectedMusic.musicModel, sender.isSelected);
}

- (void)_updateMusicDownloadStatus:(AWEPhotoMovieMusicStatus)status
                forCellAtIndexPath:(NSIndexPath *)indexPath
                    collectionView:(UICollectionView *)collectionView
{
    if (collectionView == _collectionView && indexPath.row >= self.musicList.count) {
        return;
    } else if (collectionView == _userCollectedMusicCollectionView && indexPath.row >= self.userCollectedMusicList.count) {
        return;
    }

    ACCMusicSelectCollectionViewCell *cell = [self _cellAtIndexPath:indexPath collectionView:collectionView];
    [cell setDownloadStatus:status];
}

- (void)updateCurrentPlayMusicClipRange:(HTSAudioRange)range
{
    self.selectedMusic.startTime = range.location + self.selectedMusic.musicModel.previewStartTime;
}

- (void)updateActionButtonsWithMusic:(AWEMusicSelectItem *)musicItem
{
    [self updateActionButtonsWithMusic:musicItem needUpdateCurrentCell:YES];
}

- (void)updateActionButtonsWithMusic:(AWEMusicSelectItem *)musicItem needUpdateCurrentCell:(BOOL)update
{
    [self updateLyricStickerButton:musicItem];
    [self updateClipButton:musicItem];
    [self updateFavoriteButton:musicItem];
    if (update) {
        [self synLyricStickerStatus];
        [self synClipButtonStatus];
        [self synFavoriteButtonStatus];
    }
}

- (void)resetFirstAnimation
{
    [((UICollectionView<ACCMusicCollectionViewProtocol> *)self.collectionView) startFirstLoadingAnimation];
    self.aniamtionRefTime = 0;
}

// 歌词状态
- (void)resetLyricStickerButtonStatus
{
    self.lyricStickerButton.enabled = YES;
    self.lyricStickerButton.selected = NO;
    [self synLyricStickerStatus];
}

- (void)updateLyricStickerButton:(AWEMusicSelectItem *)musicItem
{
    if (self.disableAddLyric) {
        _lyricStickerButton.hidden = YES;
        [self synLyricStickerStatus];
        return;
    }
    
    if (musicItem == nil || [musicItem isKindOfClass:NSNull.class] ||
        self.publishModel.repoContext.videoType == AWEVideoTypeReplaceMusicVideo || self.publishModel.repoContext.videoType == AWEVideoTypeNewYearWish) {
        _lyricStickerButton.hidden = YES;
    } else if (musicItem.musicModel.isLocalScannedMedia){
        _lyricStickerButton.hidden = YES;
    } else {
        if(ACC_isEmptyString(musicItem.musicModel.lyricUrl)){
            _lyricStickerButton.hidden = YES;//检查是否存在歌词资源
        }else{
            _lyricStickerButton.hidden = NO;
            ACCBLOCK_INVOKE(self.queryLyricStickerHandler, self.lyricStickerButton);//是否已添加歌词贴纸
        }
    }
    [self synLyricStickerStatus];
}

- (void)enableLyricStickerButton
{
    self.lyricStickerButton.enabled = YES;
    self.lyricStickerButton.selected = YES;
    [self synLyricStickerStatus];
}

- (void)unenableLyricStickerButton
{
    self.lyricStickerButton.enabled = NO;
    [self synLyricStickerStatus];
}

//  裁减状态
- (void)updateClipButton:(AWEMusicSelectItem *)musicItem
{
    if (self.disableCutMusic) {
        self.clipButton.hidden = YES;
        [self synClipButtonStatus];
        return;
    }
    
    if (musicItem == nil || [musicItem isKindOfClass:NSNull.class]) {
        self.clipButton.hidden = YES;
    } else {
        self.clipButton.hidden = NO;
        BOOL isUsingMVMusic = self.publishModel.repoContext.isMVVideo && [musicItem.musicModel.musicID isEqualToString:self.publishModel.repoMV.templateMusicId ?: @""];
        BOOL isMusicLongerThanVideo = musicItem.musicModel.shootDuration.doubleValue > [self.publishModel.repoVideoInfo.video totalVideoDuration] + 0.6;
        if (ACCConfigEnum(kConfigInt_manually_music_loop_mode, ACCMusicLoopMode) != ACCMusicLoopModeOff && !self.publishModel.repoUploadInfo.isAIVideoClipMode) {
            isMusicLongerThanVideo = YES;
        }
        if (self.publishModel.repoVideoInfo.shouldAccommodateVideoDurationToMusicDuration) {
            ACCSinglePhotoOptimizationABTesting canvasPhotoABSettings = [IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) singlePhotoOptimizationABTesting];
            isMusicLongerThanVideo = musicItem.musicModel.shootDuration.doubleValue > canvasPhotoABSettings.maximumVideoDuration;
        }
        self.clipButton.enabled = !isUsingMVMusic && isMusicLongerThanVideo;
    }
    [self synClipButtonStatus];
}

// 收藏状态
- (void)updateFavoriteButton:(AWEMusicSelectItem *)musicItem
{
    if (musicItem == nil || [musicItem isKindOfClass:NSNull.class]) {
        _favoriteButton.hidden = YES;
    } else if(musicItem.musicModel.isLocalScannedMedia){
        _favoriteButton.hidden = YES;
    } else {
        _favoriteButton.hidden = NO;
        BOOL isLogin = [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin];
        BOOL isFavorite = musicItem.musicModel.isFavorite;
        _favoriteButton.selected = isLogin && isFavorite;
    }
    [self synFavoriteButtonStatus];
}

#pragma mark - track methods

- (void)p_track_music_show_withParams:(NSDictionary *)params
{
    [ACCTracker() trackEvent:@"music_show" params:params needStagingFlag:NO];
    
    NSString *music_id = [params acc_stringValueForKey:@"music_id"]?:@"";
    if ([music_id length]) {
        __block BOOL isCollectMusic = NO;
        [self.userCollectedMusicList enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(AWEMusicSelectItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.musicModel.musicID && [obj.musicModel.musicID isEqualToString:music_id]) {
                isCollectMusic = YES;
                *stop = YES;
            }
        }];
        
        if (!isCollectMusic) {
            [[AWEAIMusicRecommendManager sharedInstance] jarvisTrackWithEvent:@"jarvis_item_show"
                                                                       params:@{@"item_id" : music_id}
                                                                 publishModel:self.publishModel];
        }
    }
}

- (void)willDismissView
{
    [self.musicList enumerateObjectsUsingBlock:^(AWEMusicSelectItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.musicModel.isDownloading = NO;
    }];
}

@end
