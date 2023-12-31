//
//  AWEASSSelectMusicViewController.m
//  AWEStudio
//
//  Created by 旭旭 on 2018/8/31.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWEASSSelectMusicViewController.h"

#import "ACCASSMusicBannerView.h"
#import "AWEASSMusicNavView.h"
#import "ACCMusicCollectionFeedModel.h"
#import "ACCMusicCollectionTableViewCell.h"
#import "AWESingleMusicTableViewCell.h"
#import "AWESingleMusicView.h"
#import "ACCVideoMusicCategoryModel.h"
#import "ACCVideoMusicProtocol.h"
#import "ACCASSSearchMusicVCProtocol.h"
#import "ACCMusicCommonSearchBarProtocol.h"
#import "AWEMusicCollectionData.h"
#import "ACCMusicCollectionFeedManager.h"
#import "ACCASMusicCategoryCollectionTableViewCell.h"
#import "ACCASSCurrentSelectedView.h"
#import "ACCMusicSearchSugViewControllerProtocol.h"
#import "ACCASSelectMusicChallengeTableViewCell.h"
#import "AWEASSTwoLineLabelWithIconTableViewCell.h"
#import "ACCASCommonBindMusicSectionHeaderView.h"
#import "ACCCommerceMusicServiceProtocol.h"
#import <CreationKitInfra/ACCConfigManager.h>
#import "ACCConfigKeyDefines.h"
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>

//support local audio
#import "ACCMusicSelectTabView.h"
#import "ACCMusicExportAudioSection.h"
#import "ACCLocalAudioAuthSection.h"
#import "ACCLocalAudioManageSection.h"
#import "ACCSingleLocalMusicTableViewCell.h"
#import "ACCLocalAudioAuthFooterSection.h"
#import "ACCLocalAudioDataController.h"
#import "ACCLocalAudioEmptySection.h"
#import "ACCSelectAlbumAssetsProtocol.h"
#import "ACCLocalAudioUtils.h"
#import "ACCMusicSimpleAlertView.h"
#import "ACCMusicTextEditAlertView.h"
#import <CreativeAlbumKit/CAKAlbumPreviewAndSelectController.h>

#import <CameraClient/UIScrollView+ACCInfiniteScrolling.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitInfra/ACCModuleService.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CameraClient/AWEAudioClipFeatureManager.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitInfra/ACCLoadMoreFooter.h>
#import <CreationKitInfra/ACCAlertProtocol.h>
#import <CreationKitInfra/ACCResponder.h>
#import <CameraClient/ACCViewControllerProtocol.h>
#import <CameraClient/UIScrollView+ACCInfiniteScrolling.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCRouterProtocol.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCMemoryTrackProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMacros.h>

#import <HTSServiceKit/HTSMessageCenter.h>
#import <Masonry/View+MASAdditions.h>
#import <MediaPlayer/MediaPlayer.h>
#import <CreativeKit/ACCENVProtocol.h>

static const CGFloat kHeaderTopMargin = 8;
static const CGFloat kHeaderBannerLeft = 16;
static const CGFloat kHeaderMidMargin = 8;
static const CGFloat kHeaderTabHeight = 44;

@interface AWEASSSelectMusicViewController () <UITableViewDelegate, UITableViewDataSource, ACCPropRecommendMusicProtocol>

@property (nonatomic, strong) AWEASSMusicNavView *navView;
@property (nonatomic, copy) id<ACCMusicCommonSearchBarProtocol> searchBar;
@property (nonatomic, strong) ACCASSCurrentSelectedView *currentSelectedMusicView;
@property (nonatomic, strong) ACCASSMusicBannerView *bannerView; // banner collection
@property (nonatomic, strong) UIView<ACCSelectMusicTabProtocol> *musicTabView; // switch tab
@property (nonatomic, strong) UIView<ACCLoadingViewProtocol> *useMusicLoadingView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *tableHeaderView;
@property (nonatomic, strong) UIView<ACCLoadingViewProtocol> *feedLoadingView;

// Book keeping for table view cell.
@property (nonatomic, assign) ACCAVPlayerPlayStatus cellPlayStatus;
@property (nonatomic, strong) id<ACCAudioPlayerProtocol> audioPlayer;
@property (nonatomic, strong) id<ACCMusicModelProtocol> playingMusic;
@property (nonatomic, strong) NSIndexPath *playingMusicIndexPath;
@property (nonatomic, assign) BOOL isEditingLocalState;
@property (nonatomic, assign) NSInteger collectionPlayingMusicRow;
@property (nonatomic, copy) ACCVideoMusicCategoryModel *collectionPlayingCategory;
@property (nonatomic, assign) BOOL musicSearchClose;

// Book keeping for nested collection view.
@property (nonatomic, strong) NSMutableDictionary<NSIndexPath *, NSNumber *> *contentOffsetDictionary;
@property (nonatomic, strong) NSMutableDictionary<NSIndexPath *, NSNumber *> *playingStatusDictionary;
@property (nonatomic, strong) NSMutableDictionary<NSIndexPath *, NSNumber *> *playingRowDictionary;

@property (nonatomic, strong) ACCMusicCollectionFeedManager *feedManager;
@property (nonatomic, strong) NSMutableArray<NSArray<AWEMusicCollectionData *> *> *dataList;

@property (nonatomic, strong) id<ACCTransitionViewControllerProtocol> transitionDelegate;
@property (nonatomic, strong) UIViewController<ACCASSSearchMusicVCProtocol> *searchVC;
@property (nonatomic, assign) BOOL hideBanner;

@property (nonatomic, strong) AWEAudioClipFeatureManager *clipManager;
@property (nonatomic, assign) BOOL fromSelectedMusicClip;

// audio export
@property (nonatomic, strong) ACCLocalAudioDataController *localAudioDataController;

// track
@property (nonatomic, assign) CFTimeInterval startClickStreamingPlay; // 点击开始试听

@end

// TODO(liyansong):增加下划线的修复
@implementation AWEASSSelectMusicViewController

static BOOL _hasInstance;

@synthesize repository = _repository;
@synthesize cancelMusicCompletion = _cancelMusicCompletion;
@synthesize willCloseBlock = _willCloseBlock;
@synthesize challenge = _challenge;
@synthesize pickCompletion = _pickCompletion;
@synthesize previousPage = _previousPage;
@synthesize propBindMusicIdArray = _propBindMusicIdArray;
@synthesize propId = _propId;
@synthesize sameStickerMusic = _sameStickerMusic;
@synthesize selectedMusic = _selectedMusic;
@synthesize shouldHideCellMoreButton = _shouldHideCellMoreButton;
@synthesize shouldHideCancelButton = _shouldHideCancelButton;
@synthesize mvMusic = _mvMusic;
@synthesize uploadRecommendMusic = _uploadRecommendMusic;
@synthesize needDisableDeselectMusic = _needDisableDeselectMusic;
@synthesize recordServerMode = _recordServerMode;
@synthesize videoDuration = _videoDuration;
@synthesize sceneType = _sceneType;
@synthesize allowUsingVideoDurationAsMaxMusicDuration = _allowUsingVideoDurationAsMaxMusicDuration;
@synthesize useSuggestClipRange = _useSuggestClipRange;
@synthesize enableMusicLoop = _enableMusicLoop;
@synthesize audioRange = _audioRange;
@synthesize exsitingVideoDuration = _exsitingVideoDuration;
@synthesize enableClipBlock = _enableClipBlock;
@synthesize didClipWithRange = _didClipWithRange;
@synthesize didSuggestClipRangeChange = _didSuggestClipRangeChange;
@synthesize setForbidSimultaneousScrollViewPanGesture = _setForbidSimultaneousScrollViewPanGesture;
@synthesize clipTrackInfo = _clipTrackInfo;
@synthesize isFixDurationMode = _isFixDurationMode;
@synthesize fixDuration = _fixDuration;
@synthesize shouldHideSelectedMusicViewDeleteActionBtn = _shouldHideSelectedMusicViewDeleteActionBtn;
@synthesize shouldHideSelectedMusicViewClipActionBtn = _shouldHideSelectedMusicViewClipActionBtn;
@synthesize disableCutMusic = _disableCutMusic;

@synthesize recordMode = _recordMode;

@synthesize shouldAccommodateVideoDurationToMusicDuration;
@synthesize maximumMusicDurationToAccommodate;

#pragma mark - life

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [ACCMemoryTrack() startSceneWithViewController:self info:nil];
        _isEditingLocalState = NO;
        _musicSearchClose = ACCConfigBool(kConfigBool_acc_music_select_reverse);
        _feedManager = [[ACCMusicCollectionFeedManager alloc] init];
        _dataList = [NSMutableArray array];
        _audioPlayer = IESAutoInline(ACCBaseServiceProvider(), ACCAudioPlayerProtocol);
        _audioPlayer.delegate = self;
        _collectionPlayingMusicRow = NSNotFound;
        _contentOffsetDictionary = [NSMutableDictionary dictionary];
        _playingStatusDictionary = [NSMutableDictionary dictionary];
        _playingRowDictionary = [NSMutableDictionary dictionary];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAppWillResignActiveNotification) name:UIApplicationWillResignActiveNotification object:nil];
        @weakify(self);
        _feedManager.bannerFetchCompletion = ^(NSArray<id<ACCBannerModelProtocol>> *banners, NSError *error) {
            @strongify(self);
            if (banners.count > 0) {
                self.bannerView.bannerList = [banners copy];
            } else {
                [self hideTableHeaderBannerView];
            }
            if (error != nil) {
                AWELogToolError(AWELogToolTagMusic, @"AWEASSSelectMusicViewController, banner Fetch Completion error : %@", error);
            }
        };
        
        _localAudioDataController = [[ACCLocalAudioDataController alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    AWEASSSelectMusicViewController.hasInstance = YES;
    
    if (ACCConfigBool(kConfigBool_enable_music_selected_page_network_optims)) {
        [self p_refreshDataWithAnimation:NO];
        [self p_setupUI];
    } else {
        [self p_setupUI];
        [self p_refreshDataWithAnimation:NO];
    }
    [self.feedManager fetchDataWithType:ACCSelectMusicTabTypeCollect pickCompletion:nil completion:nil];
    [self configForCallBack];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ([self.navView isShortStyle]) {
        [self p_updateLayout];
    }
    [self.bannerView startCarousel];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.isMovingToParentViewController || self.isBeingPresented) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ACCMusicViewControllerDidShow object:self];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [ACCMemoryTrack() finishSceneWithViewController:self info:nil];
    [super viewWillDisappear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    // 修复在此界面以 fullscreen style modal present 第三方登录绑定手机号的视图(AWEAccountPhoneNumberViewController)时，当
    // AWEAccountPhoneNumberViewController dismiss 掉自己后，此界面的 AWECornerBarNaviController 的 view 的 frame.origin.y
    // 被不正确的置为 0，导致视图和系统状态栏重叠的问题。暂时想不到更好的办法，如有请 @kazec.liu。
    if (self.navigationController.view.frame.origin.y < ACC_STATUS_BAR_HEIGHT && ![[ACCResponder topViewController] isKindOfClass:NSClassFromString(@"AWEAwemeDetailTableViewController")]) {
        CGRect frame = self.navigationController.view.frame;
        CGFloat delta = ACC_STATUS_BAR_HEIGHT - frame.origin.y;
        frame.origin.y += delta;
        frame.size.height -= delta;
        self.navigationController.view.frame = frame;
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self pause];
    [self p_stopCurrentSelectedViewIfNeeded];
    [self.bannerView stopCarousel];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    AWEASSSelectMusicViewController.hasInstance = NO;
}

#pragma mark - Private

- (void)solveColseGestureWith:(UIPanGestureRecognizer *)panGesture {
    for (UIGestureRecognizer *ges in self.view.gestureRecognizers) {
        if ([ges isKindOfClass:[UIPanGestureRecognizer class]]) {//滑动banner的时候不触发下拉关闭手势
            [ges requireGestureRecognizerToFail:panGesture];
            break;
        }
    }
}

#pragma mark search

- (void)p_enterSearch
{
    if (self.musicSearchClose) {
        return;
    }
    
    if (!self.searchVC.view.superview) {
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        params[@"enter_from"] = @"change_music_page";
        params[@"creation_id"] = self.createId ?: @"";
        [ACCTracker() trackEvent:@"enter_search" params:[params copy]];
        [self addChildViewController:self.searchVC];
        [self.searchVC didMoveToParentViewController:self];
        [self.view addSubview:self.searchVC.view];
        CGFloat w = self.view.bounds.size.width;
        CGFloat h = self.view.bounds.size.height;
        CGFloat top = CGRectGetMaxY(self.searchBar.targetSearchBar.frame);
        self.searchVC.view.frame = CGRectMake(0, top, w, h - top);
        [self.searchVC enterSearch];
        [self pause];
        [self p_stopCurrentSelectedViewIfNeeded];
    }
    [self.searchVC pausePlayer];
}

- (void)p_exitSearch
{
    [self.searchBar.targetSearchBar resignFirstResponder];
    [self.searchBar animatedShowCancelButton:NO];
    self.searchBar.text = nil;
    [self.searchVC.view removeFromSuperview];
    [self.searchVC willMoveToParentViewController:nil];
    [self.searchVC removeFromParentViewController];
    [self p_clearSearch];
}

- (void)p_startSearch:(NSString *)enterFrom
{
    [self.searchBar.targetSearchBar resignFirstResponder];
    [self.searchBar animatedShowCancelButton:YES];
    [self pause];
    [self p_stopCurrentSelectedViewIfNeeded];
    NSString *keyword = self.searchBar.text;
    if (!keyword.length) {
        [self p_clearSearch];
        return;
    }
    [self.searchVC searchWithKeyword:keyword enterFrom:enterFrom];
}

- (void)p_clearSearch
{
    [self.searchVC clear];
}

- (void)p_changeSearchWord:(NSString *)keyword
{
    [self.searchVC changeSearchWord:keyword];
}

- (void)p_refreshDataWithAnimation:(BOOL)animate
{
    self.playingMusicIndexPath = nil;
    self.collectionPlayingMusicRow = NSNotFound;
    self.collectionPlayingCategory = nil;
    ACCSelectMusicTabType currentSelectedIndex = [self.musicTabView selectedTabType];
    self.feedManager.recordModel = self.recordServerMode;
    self.feedManager.videoDuration = self.videoDuration;
    self.feedManager.propBindMusicIdArray = self.propBindMusicIdArray;
    self.feedManager.isCommerceMusic = (self.challenge.isCommerce && (self.challenge.connectMusics.count > 0));
    @weakify(self);
    CFTimeInterval startTime = CACurrentMediaTime();

    let pickCompletion = ^(NSArray<AWEMusicCollectionData *> *list, NSError *error) {
        @strongify(self);
        if (ACCConfigBool(kConfigBool_enable_music_selected_page_network_optims)) {
            NSInteger duration = (CACurrentMediaTime() - startTime) * 1000;
            [ACCTracker() trackEvent:@"tool_performance_api"
                              params:@{
                                  @"api_type":@"music_select_page",
                                  @"duration":@(duration),
                                  @"status":@(error ? 1 : 0),
                                  @"error_domain":error.domain?:@"",
                                  @"error_code":@(error.code),
                              }];
            [self updateDataList];
            [self reloadTableView];
            self.feedLoadingView = [ACCLoading() showLoadingOnView:self.tableView.mj_footer];
        }
    };

    let completionBlock = ^(NSArray<AWEMusicCollectionData *> *list, NSError *error) {
        @strongify(self);
        if ([self.musicTabView selectedTabType] != currentSelectedIndex) {
            return;
        }
        if (error) {
            if ([self respondsToSelector:@selector(configEmptyPageState:)]) {
                [self configEmptyPageState:ACCUIKitViewControllerStateError];
            }
            //这里可能会覆盖searchMusicViewController的占位
            return;
        } else {
            if (self.dataList.count == 0) {
                if ([self respondsToSelector:@selector(configEmptyPageState:)]) {
                    [self configEmptyPageState:ACCUIKitViewControllerStateEmpty];
                }
            }
            if ([self respondsToSelector:@selector(configEmptyPageState:)]) {
                [self configEmptyPageState:ACCUIKitViewControllerStateNormal];
            }
            [self addSelectedMusicViewIfNeeded];
        }
        [self updateDataList];
        [self p_endRefreshingWithAnimation:animate];
        if (error || !list.count) {
            AWELogToolError(AWELogToolTagRecord, @"%s fetch %@ music feed failed: %@", __PRETTY_FUNCTION__, [self.musicTabView selectedTabType] ? @"collection" : @"discover", error);
        }
        if (!ACCConfigBool(kConfigBool_enable_music_selected_page_network_optims)) {
            NSInteger duration = (CACurrentMediaTime() - startTime) * 1000;
            [ACCTracker() trackEvent:@"tool_performance_api"
                              params:@{
                                  @"api_type":@"music_select_page",
                                  @"duration":@(duration),
                                  @"status":@(error ? 1 : 0),
                                  @"error_domain":error.domain?:@"",
                                  @"error_code":@(error.code),
                              }];
        }
    };

    [self.feedManager fetchDataWithType:[self.musicTabView selectedTabType]
                         pickCompletion:pickCompletion
                             completion:completionBlock];
}

- (void)trackSelectMusicViewShowTime
{
    NSTimeInterval duration = [ACCMonitor() timeIntervalForKey:@"show_select_music_view"];
    if (duration > 1) {
        NSMutableDictionary *params = @{@"totaltime":@(duration),
                                        @"type":@"show_select_music"}.mutableCopy;
        // saf test add metric
        if ([IESAutoInline(ACCBaseServiceProvider(), ACCENVProtocol) currentEnv] == ACCENVSaf) {
            NSMutableDictionary *metricExtra = @{}.mutableCopy;
            UInt64 end_time = (UInt64)([[NSDate date] timeIntervalSince1970] * 1000);
            UInt64 start_time = end_time - (UInt64)(duration);
            [metricExtra addEntriesFromDictionary:@{@"metric_name": @"totaltime", @"start_time": @(start_time), @"end_time": @(end_time)}];
            params[@"metric_extra"] = @[metricExtra];
        }
        
        [ACCTracker() trackEvent:@"tool_performance_operation_cost_time" params:params.copy];
        [ACCMonitor() cancelTimingForKey:@"show_select_music_view"];
    }
}

- (void)p_loadMoreData
{
    ACCSelectMusicTabType lastTimeTabIndex = [self.musicTabView selectedTabType];
    [self.feedManager loadMoreWithType:lastTimeTabIndex completion:^(NSArray<AWEMusicCollectionData *> *list, NSError *error) {
        if (lastTimeTabIndex != [self.musicTabView selectedTabType]) {
            return;
        }
        if (error) {
            if ([self respondsToSelector:@selector(configEmptyPageState:)]) {
                [self configEmptyPageState:ACCUIKitViewControllerStateError];
            }
        } else {
            if ([self respondsToSelector:@selector(configEmptyPageState:)]) {
                [self configEmptyPageState:ACCUIKitViewControllerStateNormal];
            }
        }
        [self updateDataList];
        if (self.dataList.count == 0) {
            if ([self respondsToSelector:@selector(configEmptyPageState:)]) {
                [self configEmptyPageState:ACCUIKitViewControllerStateEmpty];
            }
        }
        [self p_endRefreshingWithAnimation:NO];
        if (error || !list.count) {
            AWELogToolError(AWELogToolTagRecord, @"%s load %@ music feed failed: %@", __PRETTY_FUNCTION__, [self.musicTabView selectedTabType] ? @"collection" : @"discover", error);
        }
    }];
}

- (void)safeAddObjectToDataList:(NSArray *)list
{
    if (!list) {
        return;
    }
    [self.dataList acc_addObject:[list copy]];
}

- (void)p_endRefreshingWithAnimation:(BOOL)animate
{
    [self reloadTableView];
    self.musicTabView.userInteractionEnabled = YES;
    [self.tableView.acc_infiniteScrollingView stopAnimating];
    if ([self.musicTabView selectedTabType] == ACCSelectMusicTabTypeHot) {
        if (self.feedManager.hasMoreDiscover) {
            [self.tableView.mj_footer endRefreshing];
        } else {
            [self.tableView.mj_footer endRefreshingWithNoMoreData];
        }
    } else if ([self.musicTabView selectedTabType] == ACCSelectMusicTabTypeCollect){
        if (self.feedManager.hasMoreFavourite) {
            [self.tableView.mj_footer endRefreshing];
        } else {
            [self.tableView.mj_footer endRefreshingWithNoMoreData];
        }
    }
    [self.feedLoadingView dismiss];
}

- (void)updateDataList
{
    NSArray *toAddArray;
    if ([self.musicTabView selectedTabType] == ACCSelectMusicTabTypeHot) {
        toAddArray = [self.feedManager.discoverList copy];
        self.tableView.mj_footer.hidden = NO;
    } else if ([self.musicTabView selectedTabType] == ACCSelectMusicTabTypeCollect){
        toAddArray = [self.feedManager.favouriteList copy];
        if (toAddArray.count == 0) {
            toAddArray = @[[[AWEMusicCollectionData alloc] initWithType:AWEMusicCollectionDataTypeFavEmpty]];
            self.tableView.mj_footer.hidden = YES;
        } else {
            self.tableView.mj_footer.hidden = NO;
        }
    } else if ([self.musicTabView selectedTabType] == ACCSelectMusicTabTypeLocal){
        self.tableView.mj_footer.hidden = YES;
    }
    [self.dataList removeAllObjects];
    
    if ([self.musicTabView selectedTabType] == ACCSelectMusicTabTypeHot) {
        [self p_prepareSelectMusicHotData];
    } else if ([self.musicTabView selectedTabType] == ACCSelectMusicTabTypeLocal){
        [self p_prepareSelectMusicLocalData];
    }
    [self safeAddObjectToDataList:toAddArray];
}

- (void)p_prepareSelectMusicHotData
{
    // mv影集音乐
    if (self.mvMusic) {
         AWEMusicCollectionData *data = [[AWEMusicCollectionData alloc] initWithMusicModel:(id<ACCMusicModelProtocol>)self.mvMusic
                                                                                  withType:AWEMusicCollectionDataTypeMV];
        [self.dataList acc_addObject:@[data]];
    } else if (self.challenge) {
        NSArray<id<ACCMusicModelProtocol>> *challengeArray = (NSArray<id<ACCMusicModelProtocol>> *)[ACCCommerceMusicService() connectMusicsOfCMCChallenge:self.challenge];
        NSMutableArray<AWEMusicCollectionData *> *challengeList = [[NSMutableArray alloc] init];
        for (id<ACCMusicModelProtocol> music in challengeArray) {
            [challengeList addObject:[[AWEMusicCollectionData alloc] initWithMusicModel:music withType:AWEMusicCollectionDataTypeChallenage]];
        }
        [self.dataList acc_addObject:challengeList];
    } else if (self.sameStickerMusic) {
        AWEMusicCollectionData *data = [[AWEMusicCollectionData alloc] initWithMusicModel:(id<ACCMusicModelProtocol>)self.sameStickerMusic
                                                                                 withType:AWEMusicCollectionDataTypeSameStickerMusic];
        [self.dataList acc_addObject:@[data]];
    } else if (!self.sameStickerMusic && !self.challenge && self.feedManager.propBindMusicList.count) {
        [self.dataList acc_addObject:self.feedManager.propBindMusicList];
    } else if (self.uploadRecommendMusic) {
        AWEMusicCollectionData *data = [[AWEMusicCollectionData alloc] initWithMusicModel:(id<ACCMusicModelProtocol>)self.uploadRecommendMusic
                                                                                 withType:AWEMusicCollectionDataTypeUploadRecommend];
        [self.dataList acc_addObject:@[data]];
    }
}

#pragma mark - local audio methods

- (void)p_prepareSelectMusicLocalData
{
    [self.dataList removeAllObjects];
    NSMutableArray<AWEMusicCollectionData *> *audioListArray = [NSMutableArray arrayWithArray:[self.localAudioDataController getCurrentLocalAudioFileSortedList]];
    BOOL hasAudioList = audioListArray.count > 0;
    
    AWEMusicCollectionData *exportAudioSection = [[AWEMusicCollectionData alloc] initWithType:AWEMusicCollectionDataTypeExportAudioSection];
    [self.dataList acc_addObject:@[exportAudioSection]];//提取视频中的音频功能section
    
    if (@available(iOS 9.3, *)) {
        MPMediaLibraryAuthorizationStatus authStatus = [MPMediaLibrary authorizationStatus];
        if (authStatus != MPMediaLibraryAuthorizationStatusAuthorized) {
            if (hasAudioList) {
                AWEMusicCollectionData *localAudioManageSection = [[AWEMusicCollectionData alloc] initWithType:AWEMusicCollectionDataTypeAudioManageSection];
                [self.dataList acc_addObject:@[localAudioManageSection]];//管理音频列表section
                [self.dataList acc_addObject:audioListArray];
                
                AWEMusicCollectionData *localAudioAuthFooterSection = [[AWEMusicCollectionData alloc] initWithType:AWEMusicCollectionDataTypeLocalAudioFooterAuthSection];
                [self.dataList acc_addObject:@[localAudioAuthFooterSection]];//footer提示开启权限section
            } else {
                AWEMusicCollectionData *localAudioAuthSection = [[AWEMusicCollectionData alloc] initWithType:AWEMusicCollectionDataTypeLocalAudioAuthSection];
                [self.dataList acc_addObject:@[localAudioAuthSection]];//权限section
            }
        } else {
            if (hasAudioList) {
                AWEMusicCollectionData *localAudioManageSection = [[AWEMusicCollectionData alloc] initWithType:AWEMusicCollectionDataTypeAudioManageSection];
                [self.dataList acc_addObject:@[localAudioManageSection]];//管理音频列表section
                [self.dataList acc_addObject:audioListArray];
            } else {
                AWEMusicCollectionData *emptyTipSection = [[AWEMusicCollectionData alloc] initWithType:AWEMusicCollectionDataTypeLocalAudioEmptySection];
                [self.dataList acc_addObject:@[emptyTipSection]];
            }
        }
    } else {
        if (hasAudioList) {
            AWEMusicCollectionData *localAudioManageSection = [[AWEMusicCollectionData alloc] initWithType:AWEMusicCollectionDataTypeAudioManageSection];
            [self.dataList acc_addObject:@[localAudioManageSection]];//管理音频列表section
            [self.dataList acc_addObject:audioListArray];
        } else {
            AWEMusicCollectionData *emptyTipSection = [[AWEMusicCollectionData alloc] initWithType:AWEMusicCollectionDataTypeLocalAudioEmptySection];
            [self.dataList acc_addObject:@[emptyTipSection]];
        }
    }
}

- (void)requestLocalAudioAuth
{
    if (@available(iOS 9.3, *)) {
        MPMediaLibraryAuthorizationStatus authStatus = [MPMediaLibrary authorizationStatus];
        if (authStatus == MPMediaLibraryAuthorizationStatusNotDetermined) {
            [ACCTracker() trackEvent:@"local_music_authority_show" params:[self p_localAudioBasicTrackInfo]];
            [MPMediaLibrary requestAuthorization:^(MPMediaLibraryAuthorizationStatus status) {
                NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[self p_localAudioBasicTrackInfo]];
                if (status == MPMediaLibraryAuthorizationStatusAuthorized) {
                    params[@"click_type"] = @"authorized";
                } else {
                    params[@"click_type"] = @"denied";
                }
                [ACCTracker() trackEvent:@"click_local_music_authority" params:params];
                [self p_prepareSelectMusicLocalData];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                });
            }];
        } else {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }
    }
}

- (void)localListEditClick
{
    [ACCTracker() trackEvent:@"click_local_music_manage" params:[self p_localAudioBasicTrackInfo]];
    self.isEditingLocalState = !self.isEditingLocalState;
    [self p_prepareSelectMusicLocalData];
    [self.tableView reloadData];
}

- (void)p_dismissAlbumViewController
{
    [self.navigationController popToViewController:self animated:YES];
    [self p_prepareSelectMusicLocalData];
    [self.tableView reloadData];
    UIViewController *topVC = [ACCResponder topViewController];
    if ([topVC isKindOfClass:CAKAlbumPreviewAndSelectController.class]) {
        [topVC dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)p_handleExportAudio:(AWEAssetModel *)assetModel
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[self p_localAudioBasicTrackInfo]];
    params[@"video_duration"] = @(assetModel.duration) ?: @"";
    [ACCTracker() trackEvent:@"extract_video_music" params:params];
    @weakify(self);
    [self.localAudioDataController exportLocalAudioWithAssetModel:assetModel completion:^(AWEMusicCollectionData * _Nullable collectionData, NSError * _Nullable error) {
        @strongify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || !collectionData) {
                [ACCToast() show:@"提取失败，请稍后重试"];
            }
            [self p_dismissAlbumViewController];
        });
    }];
}

- (NSDictionary *)p_localAudioBasicTrackInfo
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"shoot_way"] = self.repository.repoTrack.referString ?: @"";
    params[@"enter_from"] = @"change_music_page";
    params[@"creation_id"] = self.repository.repoContext.createId ? : @"";
    return [params copy];
}

#pragma mark

- (void)pause
{
    [self.audioPlayer pause];
    self.playingMusic = nil;
    if (self.playingMusicIndexPath) {
        if (self.collectionPlayingMusicRow != NSNotFound) {
            NSNumber *status = self.playingStatusDictionary[self.playingMusicIndexPath];
            if (status.integerValue == ACCAVPlayerPlayStatusPlaying ||
                status.integerValue == ACCAVPlayerPlayStatusLoading) {
                [self p_makeCurrentPlayingCellPause];
            }
            // 当音乐暂停时，清掉collectionview的相关信息
            self.playingStatusDictionary[self.playingMusicIndexPath] = nil;
            self.playingRowDictionary[self.playingMusicIndexPath] = nil;
        } else {
            [self p_makeCurrentPlayingCellPause];
        }
    }
    self.collectionPlayingMusicRow = NSNotFound;
    self.playingMusicIndexPath = nil;
}

- (void)didPickAudio:(id<ACCMusicModelProtocol>)music fromClip:(BOOL)fromClip error:(NSError *)error
{
    if (!fromClip) {
        ACCBLOCK_INVOKE(self.didSuggestClipRangeChange, NO);
    }
    if (!music.musicSelectedFrom) {
        music.musicSelectedFrom = @"list";//埋点统计
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ACCMusicViewControllerDidChangeSelection object:self userInfo:@{ACCNotificationCurrentMusicIDKey : music.musicID ?: @""}];
    
    if (!self.pickCompletion) {
        return;
    }
    if (error) {
        [ACCToast() showError:@"download_fail"];
        self.pickCompletion(nil, error);
        return;
    }
    if (music.isLocalScannedMedia && music.loaclAssetUrl) {
        //本地提取路径的音频直接使用，不需要网络下载，没有musicId
        ACCBLOCK_INVOKE(self.pickCompletion,music,nil);
        return;
    }
    
    __block NSError *groupError = nil;
    __block NSURL *assetUrl = nil;
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    
    self.tableView.userInteractionEnabled = NO;
    [ACCVideoMusic() fetchLocalURLForMusic:music
                              withProgress:^(float progress) {}
                                completion:^(NSURL *localURL, NSError *error) {
                                    if (error != nil) {
                                        AWELogToolError(AWELogToolTagMusic, @"fetchLocalURLForMusic error : %@", error);
                                    }
                                    assetUrl = localURL;
                                    groupError = groupError ?: error;
                                    dispatch_group_leave(group);
                                }];
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        self.tableView.userInteractionEnabled = YES;
        music.loaclAssetUrl = assetUrl;
        
        if (self.pickCompletion) {
            self.pickCompletion(music, groupError);
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self p_exitSearch];
        });
    });
}

- (void)cancelBtnClicked:(UIButton *)sender
{
    ACCBLOCK_INVOKE(self.willCloseBlock);
    if ([[self.navigationController viewControllers] firstObject] == self || !self.navigationController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (NSString *)p_getCategoryName:(NSString *)categoryName
{
    // many place is using "top_tabs_recomend", so I don't directly change it to "recommend"
    if (categoryName && [categoryName isEqualToString:@"top_tabs_recomend"]) {
        return @"recommend";
    }
    return categoryName;
}

#pragma mark - public

- (UIEdgeInsets)emptyPageEdgeInsets
{
    return UIEdgeInsetsMake(CGRectGetMaxY(self.searchBar.targetSearchBar.frame), 0, 0, 0);;
}

- (UIView *)emptyPageBelowView
{
    return self.searchVC.view;;
}

- (void)emptyPagePrimaryButtonTapped
{
    [self p_refreshDataWithAnimation:NO];
}

+ (BOOL)hasInstance
{
    return _hasInstance;
}

+ (void)setHasInstance:(BOOL)hasInstance
{
    _hasInstance = hasInstance;
}

#pragma mark - UI

- (void)p_setupUI
{
    [ACCViewControllerService() viewController:self setPrefersNavigationBarHidden:YES];
    self.view.backgroundColor = ACCResourceColor(ACCColorConstBGContainer);
    
    [self.view addSubview:self.navView];
    [self.view addSubview:self.searchBar.targetSearchBar];
    [self.view addSubview:self.tableView];
    
    [self reloadTableHeaderView];

    @weakify(self);
    ACCLoadMoreFooter *footer = [ACCLoadMoreFooter footerWithRefreshingBlock:^{
        @strongify(self);
        if ([self.musicTabView selectedTabType] == ACCSelectMusicTabTypeHot) {
            if (self.feedManager.hasMoreDiscover) {
                [self p_loadMoreData];
            } else {
                [self p_endRefreshingWithAnimation:NO];
            }
        } else if ([self.musicTabView selectedTabType] == ACCSelectMusicTabTypeCollect){
            if (self.feedManager.hasMoreFavourite) {
                [self p_loadMoreData];
            } else {
                [self p_endRefreshingWithAnimation:NO];
            }
        }
    }];
    footer.showNoMoreDataText = YES;
    footer.automaticallyHidden = NO;
    [footer setLoadingViewBackgroundColor:ACCResourceColor(ACCUIColorConstBGContainer)];
    [footer setLoadMoreLabelTextColor:ACCResourceColor(ACCUIColorConstTextTertiary)];
    self.tableView.mj_footer = footer;

    [self.tableView acc_addInfiniteScrollingWithActionHandler:^{
        @strongify(self);
        if ([self.musicTabView selectedTabType] == ACCSelectMusicTabTypeHot) {
            if (self.feedManager.hasMoreDiscover) {
                [self p_loadMoreData];
            }
        } else if ([self.musicTabView selectedTabType] == ACCSelectMusicTabTypeCollect){
            if (self.feedManager.hasMoreFavourite) {
                [self p_loadMoreData];
            }
        }
    }];
    self.tableView.showsVerticalScrollIndicator = NO;

    [self p_updateLayout];
}

- (void)p_updateLayout
{
    CGFloat navViewHeight = [self.navView recommendHeight];
    ACCMasReMaker(self.navView, {
        make.leading.equalTo(@0);
        make.trailing.equalTo(self.view.mas_trailing);
        make.top.equalTo(self.view);
        make.height.equalTo(@(navViewHeight));
    });
    
    if (!self.musicSearchClose) {
        self.searchBar.targetSearchBar.hidden = NO;
        ACCMasReMaker(self.searchBar.targetSearchBar, {
            make.leading.equalTo(@16);
            make.height.equalTo(@48);
            make.top.equalTo(self.navView.mas_bottom);
            make.trailing.equalTo(self.view.mas_trailing);
        });

        ACCMasReMaker(self.tableView, {
            make.top.equalTo(self.searchBar.targetSearchBar.mas_bottom);
            make.leading.trailing.equalTo(self.view);
            make.bottom.equalTo(self.view.mas_bottom);
        });
    } else {
        self.searchBar.targetSearchBar.hidden = YES;
        ACCMasReMaker(self.tableView, {
            make.top.equalTo(self.navView.mas_bottom);
            make.leading.trailing.equalTo(self.view);
            make.bottom.equalTo(self.view.mas_bottom);
        });
    }
    
    [self.navView updateLayout];
}

- (void)hideTableHeaderBannerView
{
    self.hideBanner = YES;
    self.bannerView.hidden = YES;
    self.musicTabView.frame = CGRectMake(kHeaderBannerLeft, 0, ACC_SCREEN_WIDTH - 2 * kHeaderBannerLeft, kHeaderTabHeight);
    [self reloadTableView];
}

- (void)reloadTableView
{
    [self.tableView reloadData];
    [self reloadTableHeaderView];
}

- (void)reloadTableHeaderView
{
    self.tableHeaderView.frame = CGRectMake(0, 0, self.view.bounds.size.width, [self tableHeaderViewHeight]);
    self.tableView.tableHeaderView = self.tableHeaderView;
}

- (void)setSelectedMusic:(id<ACCMusicModelProtocol>)selectedMusic
{
    _selectedMusic = selectedMusic;
}

- (void)addSelectedMusicViewIfNeeded
{
    if (self.selectedMusic && !ACC_isEmptyString(self.selectedMusic.musicName) && self.currentSelectedMusicView.hidden) {
        self.currentSelectedMusicView.hidden = NO;
        if (self.searchVC.view.superview == self.view) {
            [self.view insertSubview:self.currentSelectedMusicView belowSubview:self.searchVC.view];
        } else {
            [self.view addSubview:self.currentSelectedMusicView];
        }
        [self.currentSelectedMusicView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view);
            make.leading.equalTo(self.view).offset(16);
            make.height.equalTo(@64);
            make.bottom.equalTo(self.view).offset(-16 - ACC_IPHONE_X_BOTTOM_OFFSET);
        }];
        @weakify(self);
        self.currentSelectedMusicView.enableClipBlock = ^BOOL(id<ACCMusicModelProtocol> _Nonnull music) {
            @strongify(self);
            return ACCBLOCK_INVOKE(self.enableClipBlock, music);
        };
        self.currentSelectedMusicView.didClickClipButton = ^(id<ACCMusicModelProtocol> _Nonnull music) {
            @strongify(self);
            if (!music.loaclAssetUrl) {
                music.loaclAssetUrl = music.originLocalAssetUrl;
            }
            if (!music.loaclAssetUrl) {
                return;
            }
            self.fromSelectedMusicClip = YES;
            
            NSMutableDictionary *trackInfo = self.clipTrackInfo.mutableCopy;
            if (self.sceneType == ACCMusicEnterScenceTypeRecorder) {
                trackInfo[@"music_edited_from"] = @"shoot_selected_music";
            } else if (self.sceneType == ACCMusicEnterScenceTypeEditor) {
                trackInfo[@"music_edited_from"] = @"edit_selected_music";
            } else if (self.sceneType == ACCMusicEnterScenceTypeAIClip) {
                trackInfo[@"music_edited_from"] = @"sync_selected_music";
            }
            self.clipManager.audioClipCommonTrackDic = trackInfo;
            
            [self pause];
            [self p_stopCurrentSelectedViewIfNeeded];
            self.clipManager.useSuggestInitial = self.useSuggestClipRange;
            [self.clipManager addAudioCLipViewForViewController:[ACCResponder topViewController]];
            [self.clipManager configPlayerWithMusic:music];
            AVAsset *asset = [AVURLAsset assetWithURL:music.loaclAssetUrl ?: [NSURL URLWithString:@""]];
            [self.clipManager updateAudioBarWithURL:music.loaclAssetUrl
                                      totalDuration:music.auditionDuration.floatValue ?: CMTimeGetSeconds(asset.duration)
                                      startLocation:self.audioRange.location
                         exsitingVideoTotalDuration:self.exsitingVideoDuration
                                    enableMusicLoop:self.enableMusicLoop];
            [self.clipManager showMusicClipView];
            ACCBLOCK_INVOKE(self.setForbidSimultaneousScrollViewPanGesture, YES);
            
            trackInfo[@"can_music_loop"] = [self.clipManager shouldShowMusicLoopComponent] ? @"1" : @"0";
            [ACCTracker() trackEvent:@"edit_music" params:[trackInfo copy]];
        };
        
        self.currentSelectedMusicView.didClickDeleteButton = ^(id<ACCMusicModelProtocol> _Nonnull music) {
            @strongify(self);
            if (self.needDisableDeselectMusic) {
                [ACCToast() show:ACCLocalizedString(@"creation_singlepic_cancelmusic", @"Cannot cancel a music under a single picture")];
            } else if (self.sceneType == ACCMusicEnterScenceTypeAIClip) {
                [ACCToast() show:ACCLocalizedString(@"sync_page_music_cancel", @"卡点作品不支持取消配乐")];
            } else if (self.shouldHideCancelButton) {
                [ACCToast() show:ACCLocalizedString(@"slomo_cannot_cancel_music", @"无法取消使用音乐")];
            } else {
                self.currentSelectedMusicView.hidden = YES;
                self.selectedMusic = nil;
                ACCBLOCK_INVOKE(self.cancelMusicCompletion, music);
            }
        };
        self.currentSelectedMusicView.didStartPlayMusic = ^{
            @strongify(self);
            [self pause];
        };
        
        if (self.needDisableDeselectMusic || self.sceneType == ACCMusicEnterScenceTypeAIClip || self.shouldHideCancelButton) {
            [self.currentSelectedMusicView updateCancelButtonToDistouchableColor];
        }
        if (self.shouldHideSelectedMusicViewDeleteActionBtn) {
            [self.currentSelectedMusicView hideDeleteActionBtn];
        }
        if (self.shouldHideSelectedMusicViewClipActionBtn) {
            [self.currentSelectedMusicView hideClipActionBtn];
        }
    }
}

- (void)p_makeCurrentPlayingCellPause
{
    if (!self.playingMusicIndexPath) {
        return;
    }

    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.playingMusicIndexPath];
    if ([cell isKindOfClass:[ACCMusicCollectionTableViewCell class]]) {
        [(ACCMusicCollectionTableViewCell *)cell configWithPlayerStatus:ACCAVPlayerPlayStatusPause forRow:self.collectionPlayingMusicRow];
    } else if ([cell conformsToProtocol:@protocol(AWEASMusicCellProtocol)]) {
        [[(UITableViewCell<AWEASMusicCellProtocol> *)cell musicView] configWithPlayerStatus:ACCAVPlayerPlayStatusPause];
    } else if ([cell isKindOfClass:[ACCSingleLocalMusicTableViewCell class]]){
        [(ACCSingleLocalMusicTableViewCell *)cell configWithPlayerStatus:ACCAVPlayerPlayStatusPause];
    }
}

#pragma mark - view

- (AWEASSMusicNavView *)navView
{
    if (!_navView) {
        _navView = [[AWEASSMusicNavView alloc] init];
        [_navView.leftCancelButton addTarget:self
                                      action:@selector(cancelBtnClicked:)
                            forControlEvents:UIControlEventTouchUpInside];
    }
    return _navView;
}

- (id<ACCMusicCommonSearchBarProtocol>)searchBar
{
    if (!_searchBar) {
        _searchBar = [IESAutoInline(ACCBaseServiceProvider(), ACCMusicSearchSugVCBuilderProtocol) createStudioSearchBar];
        NSDictionary *attributes = @{
                                     NSForegroundColorAttributeName : ACCResourceColor(ACCUIColorConstTextTertiary),
                                     NSFontAttributeName : [ACCFont() systemFontOfSize:15]
                                     };
        NSAttributedString *placeHolderString = [[NSAttributedString alloc] initWithString:ACCLocalizedString(@"com_mig_search_jro1zs", @"搜索歌曲名称") attributes:attributes];
        _searchBar.attributedPlaceHolder = placeHolderString;
        _searchBar.textColor = ACCResourceColor(ACCUIColorConstTextPrimary);
        _searchBar.type = ACCMusicCommonSearchBarTypeRightButtonAuto;
        _searchBar.searchFiledBackgroundColor = ACCResourceColor(ACCUIColorConstBGInput);
        _searchBar.targetSearchBar.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainer);
        _searchBar.lensImage =  ACCResourceImage(@"ic_searshbar_search_black");
        _searchBar.textField.returnKeyType = UIReturnKeySearch;
        _searchBar.clearImage = ACCResourceImage(@"ic_search_bar_clear_black");
        @weakify(self);
        _searchBar.searchBarTextChangeBlock = ^(NSString *barText, NSString *searchText) {
            @strongify(self);
            if (!searchText.length) {
                [self p_clearSearch];
            } else {
                NSString *text = [barText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                text = [text stringByReplacingOccurrencesOfString:@"\u2006" withString:@""];
                [self p_changeSearchWord:text];
            }
        };
        _searchBar.textFieldBeginEditingBlock = ^{
            @strongify(self);
            [self p_enterSearch];
            [self.searchVC searchBeginEditing];
        };
        _searchBar.textFieldDidEndEditingBlock = ^{
            @strongify(self);
            [self.searchVC searchEndEditing];
        };
        _searchBar.textFieldShouldReturnBlock = ^{
            @strongify(self);
            NSString *text = self.searchBar.text;
            if (text.length && ![text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length) {
                self.searchBar.text = @"";
                return;
            }
            [self.searchVC textFieldClickReturn:self.searchBar.text];
            [self p_startSearch:@"normal_search"];
        };
        _searchBar.rightButtonClickedBlock = ^{
            @strongify(self);
            [self p_exitSearch];
        };
    }
    return _searchBar;
}

- (ACCASSCurrentSelectedView *)currentSelectedMusicView
{
    if (!_currentSelectedMusicView) {
        _currentSelectedMusicView = [[ACCASSCurrentSelectedView alloc] initWithMusic:(id<ACCMusicModelProtocol>)self.selectedMusic];
        _currentSelectedMusicView.audioRange = self.audioRange;
        _currentSelectedMusicView.hidden = YES;
    }
    return _currentSelectedMusicView;
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.backgroundColor = self.view.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainer);
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [_tableView registerClass:AWEASSTwoLineLabelWithIconTableViewCell.class forCellReuseIdentifier:NSStringFromClass([AWEASSTwoLineLabelWithIconTableViewCell class])];
        [_tableView registerClass:[ACCASCommonBindMusicSectionHeaderView class] forHeaderFooterViewReuseIdentifier:[ACCASCommonBindMusicSectionHeaderView identifier]];
        if ([_tableView respondsToSelector:@selector(contentInsetAdjustmentBehavior)]) {
            if (@available(iOS 11.0, *)) {
                _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            }
        }
        _tableView.showsVerticalScrollIndicator = NO;
    }
    return _tableView;
}

- (UIView *)tableHeaderView
{
    if (!_tableHeaderView) {
        _tableHeaderView = [[UIView alloc] init];
        [_tableHeaderView addSubview:self.bannerView];
        [_tableHeaderView addSubview:self.musicTabView];
    }
    return _tableHeaderView;
}

- (ACCASSMusicBannerView *)bannerView
{
    if (!_bannerView) {
        _bannerView = [[ACCASSMusicBannerView alloc] initWithFrame:CGRectMake(kHeaderBannerLeft, kHeaderTopMargin, ACC_SCREEN_WIDTH - 2 * kHeaderBannerLeft, [self bannerHeight])];
        _bannerView.transitionDelegate = self.transitionDelegate;
        _bannerView.bannerList = (NSArray<id<ACCBannerModelProtocol>> *)[self.feedManager placeholderBannerList];
        _bannerView.shouldHideCellMoreButton = self.shouldHideCellMoreButton;
        _bannerView.recordMode = self.recordServerMode;
        _bannerView.videoDuration = self.videoDuration;
        for (UIGestureRecognizer *ges in self.view.gestureRecognizers) {
            if ([ges isKindOfClass:[UIPanGestureRecognizer class]]) {//滑动banner的时候不触发下拉关闭手势
                [ges requireGestureRecognizerToFail:_bannerView.collectionView.panGestureRecognizer];
                break;
            }
        }
        @weakify(self);
        _bannerView.completion = ^(id<ACCMusicModelProtocol> audio, NSError *error) {
            @strongify(self);
            audio.musicSelectedFrom = @"banner";//埋点统计
            [self didPickAudio:audio fromClip:NO error:error];
        };
        _bannerView.enableClipBlock = ^BOOL(id<ACCMusicModelProtocol> audio) {
            @strongify(self);
            return ACCBLOCK_INVOKE(self.enableClipBlock, audio);
        };
        _bannerView.willClipBlock = ^(id<ACCMusicModelProtocol> audio, NSError *error) {
            @strongify(self);
            if (audio && !error) {
                [self p_showMusicClipViewWithMusic:audio];
            } else {
                AWELogToolError(AWELogToolTagMusic, @"select music vc | banner willClipBlock | fetch music failed: %@", error);
            }
        };
    }
    return _bannerView;
}

- (id<ACCASSSearchMusicVCProtocol>)searchVC
{
    if (!_searchVC) {
        _searchVC = [IESAutoInline(ACCBaseServiceProvider(), ACCASSSearchMusicVCBuilderProtocol) createSearchMusicVC];
        _searchVC.shouldHideCellMoreButton = self.shouldHideCellMoreButton;
        _searchVC.creationId = self.createId;
        _searchVC.searchBar = self.searchBar;
        _searchVC.previousPage = self.previousPage;
        _searchVC.disableCutMusic = self.disableCutMusic;
        _searchVC.shootDuration = self.videoDuration;
        _searchVC.recordMode = self.recordMode;
        _searchVC.repository = self.repository;
        @weakify(self);
        //浮层关闭手势冲突解决
        _searchVC.solveCloseGesture = ^(UIPanGestureRecognizer *panGesture) {
            @strongify(self);
            [self solveColseGestureWith:panGesture];
        };
        _searchVC.didSelectSugQuery = ^(NSString *query) {
            @strongify(self);
            self.searchBar.text = query;
            [self p_startSearch:@"search_sug"];
        };
        _searchVC.didSelectComplementQuery = ^(NSString *query) {
            @strongify(self);
            self.searchBar.text = query;
        };
        _searchVC.completion = ^(id<ACCMusicModelProtocol>audio, NSError *error) {
            @strongify(self);
            audio.musicSelectedFrom = @"search";//埋点统计
            [self didPickAudio:audio fromClip:NO error:error];
        };
        _searchVC.enableClipBlock = ^BOOL(id<ACCMusicModelProtocol> audio) {
            @strongify(self);
            return ACCBLOCK_INVOKE(self.enableClipBlock, audio);
        };
        _searchVC.willClipBlock = ^(id<ACCMusicModelProtocol> audio, NSError *error) {
            @strongify(self);
            if (audio && !error) {
                [self p_showMusicClipViewWithMusic:audio];
                self.clipManager.usedForMusicSearch = YES;
            } else {
                AWELogToolError(AWELogToolTagMusic, @"select music vc | search vc willClipBlock | fetch music failed: %@", error);
            }
        };
        _searchVC.didSelectHistoryQuery = ^(NSString *query) {
            @strongify(self);
            self.searchBar.text = query;
            [self p_startSearch:@"search_history"];
        };
        _searchVC.dismissKeyboard = ^{
            @strongify(self);
            [self.searchBar.targetSearchBar resignFirstResponder];
        };
        _searchVC.updatePublishModelCategoryIdBlock = self.updatePublishModelCategoryIdBlock;
    }
    return _searchVC;
}

- (UIView<ACCSelectMusicTabProtocol> *)musicTabView
{
    if (!_musicTabView) {
        CGRect musicTabRect = CGRectMake(kHeaderBannerLeft, [self tableHeaderViewHeight] - kHeaderTabHeight, ACC_SCREEN_WIDTH - 2 * kHeaderBannerLeft, kHeaderTabHeight);
        _musicTabView = [[ACCMusicSelectTabView alloc] initWithFrame:musicTabRect];
        // 第一次tab打点
        [ACCTracker() trackEvent:@"enter_music_tab"
                           params:@{
                               @"tab_name" : @"popular_song",
                           }];
        @weakify(self);
        _musicTabView.tabShouldSelect = ^BOOL(ACCSelectMusicTabType selectedIndex) {
            @strongify(self);
            if (selectedIndex == ACCSelectMusicTabTypeCollect) {
                //点击收藏时需要校验登录
                if ([IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin]) {
                    return YES;
                } else {
                    [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) requireLogin:^(BOOL success) {
                        if (success) {
                            @strongify(self);
                            [self.musicTabView forceSwitchSelectedType:ACCSelectMusicTabTypeCollect];
                        }
                    } withTrackerInformation:@{
                        @"enter_from" : @"change_music_page",
                        @"enter_method" : @"click_my_music"
                    }];
                    return NO;
                }
            } else {
                return YES;
            }
        };
        _musicTabView.tabCompletion = ^(ACCSelectMusicTabType selectedIndex) {
            @strongify(self);
            NSMutableDictionary *params = [NSMutableDictionary dictionary];
            if (self.sceneType == ACCMusicEnterScenceTypeRecorder) {
                params[@"previous_page"] = self.previousPage ?: @"";
            } else if (self.sceneType == ACCMusicEnterScenceTypeEditor) {
                params[@"previous_page"] = self.previousPage ?: @"";
            }
            
            if (selectedIndex == ACCSelectMusicTabTypeHot) {
                params[@"tab_name"] = @"popular_song";
            } else if (selectedIndex == ACCSelectMusicTabTypeCollect){
                params[@"tab_name"] = @"favourite_song";
            } else if (selectedIndex == ACCSelectMusicTabTypeLocal){
                params[@"tab_name"] = @"tab_local";
            }
            [ACCTracker() trackEvent:@"enter_music_tab"
                               params:[params copy]];
            [self pause];
            [self updateDataList];
            [UIView transitionWithView:self.tableView
                              duration:0.3f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^(void) {
                                [self reloadTableView];
                            } completion:nil];
            [self p_refreshDataWithAnimation:NO];
            if (selectedIndex != ACCSelectMusicTabTypeHot) {
                [self.musicTabView showBottomLineView:YES];
            } else {
                [self.musicTabView showBottomLineView:NO];
            }
        };
    }
    return _musicTabView;
}

- (CGFloat)tableHeaderViewHeight
{
    if (!self.hideBanner) {
        return kHeaderTopMargin + [self bannerHeight] + kHeaderMidMargin + kHeaderTabHeight;
    }

    return kHeaderTabHeight;
}

- (CGFloat)bannerHeight
{
    CGFloat bannerWidth = ACC_SCREEN_WIDTH - kHeaderBannerLeft * 2;
    CGFloat bannerHeight = 90.0 / 343.0 * bannerWidth;

    return bannerHeight;
}

- (id<ACCTransitionViewControllerProtocol>)transitionDelegate
{
    if (!_transitionDelegate) {
        _transitionDelegate = [IESAutoInline(ACCBaseServiceProvider(), ACCSelectMusicViewControllerBuilderProtocol) createTransitionDelegate];
    }
    return _transitionDelegate;
}

- (AWEAudioClipFeatureManager *)clipManager
{
    if (!_clipManager) {
        _clipManager = [[AWEAudioClipFeatureManager alloc] init];
        _clipManager.lightStyle = YES;
        _clipManager.isFixDurationMode = self.isFixDurationMode;
        _clipManager.fixDuration = self.fixDuration;
        _clipManager.userInnerPlayer = YES;
        _clipManager.allowUsingVideoDurationAsMaxMusicDuration = self.allowUsingVideoDurationAsMaxMusicDuration;
        _clipManager.sceneType = self.sceneType;
        __block BOOL useSuggestClipRange = self.useSuggestClipRange;
        @weakify(self);
        _clipManager.audioClipDoneBlock = ^(HTSAudioRange range, AWEAudioClipRangeChangeType changeType, BOOL enableMusicLoop, NSInteger repeatCount) {
            @strongify(self);
            NSString *musicEditedFrom = @"";
            if (self.sceneType == ACCMusicEnterScenceTypeRecorder) {
                musicEditedFrom = self.fromSelectedMusicClip ? @"shoot_selected_music" : @"shoot_change_music";
            } else if (self.sceneType == ACCMusicEnterScenceTypeEditor) {
                musicEditedFrom = self.fromSelectedMusicClip ? @"edit_selected_music" : @"edit_change_music";
            } else if (self.sceneType == ACCMusicEnterScenceTypeAIClip) {
                musicEditedFrom = self.fromSelectedMusicClip ? @"sync_selected_music" : @"sync_change_music";
            }
            ACCBLOCK_INVOKE(self.didClipWithRange, range, musicEditedFrom, enableMusicLoop, repeatCount);
            // 16.3.0 lynx音乐搜索结果调起剪辑面板上报埋点
            if (self->_clipManager.usedForMusicSearch && [self.searchVC respondsToSelector:@selector(lynxMusicSearchClipConfirmed)]) {
                    [self.searchVC lynxMusicSearchClipConfirmed];
            }
            
            [self didPickAudio:(id<ACCMusicModelProtocol>)self->_clipManager.music fromClip:YES error:nil];
            ACCBLOCK_INVOKE(self.didSuggestClipRangeChange, useSuggestClipRange);
            ACCBLOCK_INVOKE(self.setForbidSimultaneousScrollViewPanGesture, NO);
        };
        _clipManager.audioClipCancelBlock = ^(HTSAudioRange range, AWEAudioClipRangeChangeType changeType) {
            @strongify(self);
            // 16.3.0 lynx音乐搜索结果调起剪辑面板上报埋点
            if (self->_clipManager.usedForMusicSearch && [self.searchVC respondsToSelector:@selector(lynxMusicSearchClipCanceled)]) {
                    [self.searchVC lynxMusicSearchClipCanceled];
            }
            
            ACCBLOCK_INVOKE(self.setForbidSimultaneousScrollViewPanGesture, NO);
        };
        _clipManager.suggestSelectedChangeBlock = ^(BOOL selected) {
            useSuggestClipRange = selected;
        };
    }
    return _clipManager;
}

#pragma mark - AWEAVPlayerWrapperDelegate

- (void)configDelegateViewWithStatus:(ACCAVPlayerPlayStatus)status
{
    if (!self.playingMusic) {
        return;
    }

    /// 基于playurl/local播放
    if (self.playingMusic.localURL && ![self.playingMusic.localURL isEqual:self.audioPlayer.playingURL]) {
        return;
    }
    /// 基于musicmodel播放 新增逻辑
    if (self.audioPlayer.playingMusic && ![self.playingMusic.musicID isEqual:self.audioPlayer.playingMusic.musicID] && !self.playingMusic.isLocalScannedMedia) {
        return;
    }
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.playingMusicIndexPath];
    if (self.playingMusicIndexPath) {
        AWEMusicCollectionData *data = [self getFirstDataOfSection:self.playingMusicIndexPath.section];
        BOOL isFavouriteCell = [cell isKindOfClass:[AWESingleMusicTableViewCell class]];
        BOOL isChallengeCell = (data.type == AWEMusicCollectionDataTypeChallenage);
        BOOL isSameSticker = (data.type == AWEMusicCollectionDataTypeSameStickerMusic);
        BOOL isProp = (data.type == AWEMusicCollectionDataTypeProp);
        BOOL isMV = (data.type == AWEMusicCollectionDataTypeMV);
        BOOL isUploadRecommend = (data.type == AWEMusicCollectionDataTypeUploadRecommend);
        BOOL isLocalAudioCell = (data.type == AWEMusicCollectionDataTypeLocalMusicListSection);
        BOOL isCollectionCell = [cell isKindOfClass:[ACCMusicCollectionTableViewCell class]];
    
        if (isCollectionCell && self.collectionPlayingMusicRow != NSNotFound) {
            ACCMusicCollectionTableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.playingMusicIndexPath];
            [cell configWithPlayerStatus:status forRow:self.collectionPlayingMusicRow];
            if (status == ACCAVPlayerPlayStatusPlaying) {
                // 更新status到playing
                self.playingStatusDictionary[self.playingMusicIndexPath] = @(ACCAVPlayerPlayStatusPlaying);
                NSMutableDictionary *params = [NSMutableDictionary dictionary];
                params[@"enter_from"] = @"change_music_page";
                params[@"music_id"] = self.playingMusic.musicID ?: @"";
                params[@"category_name"] = [self p_getCategoryName:self.collectionPlayingCategory.name] ?: @"";
                params[@"category_id"] = self.collectionPlayingCategory.idStr ?: @"";
                params[@"previous_page"] = self.previousPage ?: @"";
                params[@"order"] = @(self.collectionPlayingMusicRow);
                [ACCTracker() trackEvent:@"play_music"
                                   params:[params copy]];
                //  耗时统计
                NSInteger duration = (CACurrentMediaTime() - self.startClickStreamingPlay) * 1000;
                [ACCTracker() trackEvent:@"download_play_succeed"
                                  params:@{@"time" : @(duration)}];
            }
        } else {
            NSDictionary *params;
            if (isFavouriteCell) {
                [[(AWESingleMusicTableViewCell *)cell musicView] configWithPlayerStatus:status];
                params = @{ @"enter_from" : @"change_music_page",
                            @"music_id" : self.playingMusic.musicID ?: @"",
                            @"category_name" : @"favorite_song",
                            @"previous_page" : self.previousPage ?: @"",
                            @"order" : @(self.playingMusicIndexPath.row)};
            } else if (isChallengeCell) {
                [[(ACCASSelectMusicChallengeTableViewCell *)cell musicView] configWithPlayerStatus:status];
                params = @{ @"enter_from" : @"change_music_page",
                            @"music_id" : self.playingMusic.musicID ?: @"",
                            @"category_name" : @"challenge",
                            @"previous_page" : self.previousPage ?: @"",
                            @"tag_id": self.challenge.itemID ?: @"",
                            @"order" : @(self.playingMusicIndexPath.row)};
            } else if (isSameSticker) {
                params = @{ @"enter_from" : @"change_music_page",
                            @"music_id" : self.playingMusic.musicID ?: @"",
                            @"previous_page" : self.previousPage ?: @"",
                            @"order" : @(self.playingMusicIndexPath.row)};
                [[(ACCASSelectMusicChallengeTableViewCell *)cell musicView] configWithPlayerStatus:status];
            } else if (isProp) {
                [[(ACCASSelectMusicChallengeTableViewCell *)cell musicView] configWithPlayerStatus:status];
                params = @{ @"enter_from" : @"change_music_page",
                            @"music_id" : self.playingMusic.musicID ?: @"",
                            @"category_name" : @"challenge",
                            @"previous_page" : self.previousPage ?: @"",
                            @"prop_id": self.propId ?: @"",
                            @"order" : @(self.playingMusicIndexPath.row)};
            } else if (isMV) {
                [[(ACCASSelectMusicChallengeTableViewCell *)cell musicView] configWithPlayerStatus:status];
                params = @{ @"enter_from" : @"change_music_page",
                            @"music_id" : self.playingMusic.musicID ?: @"",
                            @"category_name" : @"mv",
                            @"previous_page" : self.previousPage ?: @"",
                            @"order" : @(self.playingMusicIndexPath.row)};
            } else if (isUploadRecommend) {
                [[(ACCASSelectMusicChallengeTableViewCell *)cell musicView] configWithPlayerStatus:status];
                params = @{ @"enter_from" : @"change_music_page",
                            @"music_id" : self.playingMusic.musicID ?: @"",
                            @"category_name" : @"upload", 
                            @"previous_page" : self.previousPage ?: @"",
                            @"order" : @(self.playingMusicIndexPath.row)};
            } else if (isLocalAudioCell) {
                [(ACCSingleLocalMusicTableViewCell *)cell configWithPlayerStatus:status];
                params = @{ @"enter_from" : @"change_music_page",
                            @"music_id" : @"",
                            @"category_name" : @"local",
                            @"previous_page" : self.previousPage ?: @"",
                            @"order" : @(self.playingMusicIndexPath.row)};
            }
            
            if (status == ACCAVPlayerPlayStatusPlaying) {
                [ACCTracker() trackEvent:@"play_music"
                                  params:params ?:@{}
                                       ];
            }
        }
    }

    if (status == ACCAVPlayerPlayStatusFail) {
        [ACCToast() showNetWeak];
    }
    
    if (status == ACCAVPlayerPlayStatusLoading) {
        [self p_stopCurrentSelectedViewIfNeeded];
    }
    if ((status == ACCAVPlayerPlayStatusPause && [UIApplication sharedApplication].applicationState != UIApplicationStateActive) ||
        status == ACCAVPlayerPlayStatusReachEnd ||
        status == ACCAVPlayerPlayStatusFail) {
        if (self.collectionPlayingMusicRow != NSNotFound) {
            // 暂停音频
            if (self.playingMusicIndexPath) {
                // 当音乐暂停时，清掉collectionview的相关信息
                self.playingStatusDictionary[self.playingMusicIndexPath] = nil;
                self.playingRowDictionary[self.playingMusicIndexPath] = nil;
                [self p_makeCurrentPlayingCellPause];
            }
        }
        self.playingMusic = nil;
        self.collectionPlayingMusicRow = NSNotFound;
        self.playingMusicIndexPath = nil;
        self.collectionPlayingCategory = nil;
    }
    self.cellPlayStatus = status;
}

- (void)handleAppWillResignActiveNotification
{
    if (!self.audioPlayer.canBackgroundPlay) {
        if (self.collectionPlayingMusicRow != NSNotFound) {
            if (self.playingMusicIndexPath) {
                self.playingStatusDictionary[self.playingMusicIndexPath] = nil;
                self.playingRowDictionary[self.playingMusicIndexPath] = nil;
                [self p_makeCurrentPlayingCellPause];
            }
        }
        self.playingMusic = nil;
        self.collectionPlayingMusicRow = NSNotFound;
        self.playingMusicIndexPath = nil;
        self.collectionPlayingCategory = nil;
    }
}

#pragma mark - tableview delegate datasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section < self.dataList.count && indexPath.row < self.dataList[indexPath.section].count) {
        [self trackSelectMusicViewShowTime];
        AWEMusicCollectionData *data = self.dataList[indexPath.section][indexPath.row];
        switch (data.type) {
            case AWEMusicCollectionDataTypeMusicCollection:
            case AWEMusicCollectionDataTypeMusicArray:
            {
                NSString *identifier = NSStringFromClass([ACCMusicCollectionTableViewCell class]);
                ACCMusicCollectionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
                if (!cell) {
                    cell = [[ACCMusicCollectionTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
                    @weakify(self);
                    cell.completion = ^(id<ACCMusicModelProtocol> audio, NSError *error) {
                        @strongify(self);
                        [self didPickAudio:audio fromClip:NO error:error];
                    };
                    cell.enableClipBlock = ^BOOL(id<ACCMusicModelProtocol> audio) {
                        @strongify(self);
                        return ACCBLOCK_INVOKE(self.enableClipBlock, audio);
                    };
                    cell.willClipBlock = ^(id<ACCMusicModelProtocol> audio, NSError *error) {
                        @strongify(self);
                        if (audio && !error) {
                            [self p_showMusicClipViewWithMusic:audio];
                        } else {
                            AWELogToolError(AWELogToolTagMusic, @"select music vc | ACCMusicCollectionTableViewCell willClipBlock | fetch music failed: %@", error);
                        }
                    };
                    cell.selectMusicBlock = ^(ACCMusicCollectionTableViewCell *cell, NSInteger row, id<ACCMusicModelProtocol>music) {
                        @strongify(self);
                        if ([music isOffLine]) {
                            [ACCToast() show:music.offlineDesc];
                            return;
                        }
                        [self.audioPlayer pause];
                        NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
                        if (!self.playingMusic) {
                            self.playingMusicIndexPath = cellIndexPath;
                            self.collectionPlayingMusicRow = row;
                            if (data.type == AWEMusicCollectionDataTypeMusicCollection) {
                                self.collectionPlayingCategory = data.collectionFeed.category;
                            } else {
                                self.collectionPlayingCategory = [[ACCVideoMusicCategoryModel alloc] init];
                                self.collectionPlayingCategory.name = @"top_tabs_recomend";
                            }
                            self.playingMusic = music;
                            if (cellIndexPath) {
                                self.playingStatusDictionary[cellIndexPath] = @(ACCAVPlayerPlayStatusLoading);
                                self.playingRowDictionary[cellIndexPath] = @(row);
                            }
                            [cell configWithPlayerStatus:ACCAVPlayerPlayStatusLoading forRow:row];
                        } else if ([self.playingMusic isEqual:music]) { // 相同音乐
                            self.playingMusic = nil;
                            self.playingMusicIndexPath = nil;
                            self.collectionPlayingMusicRow = NSNotFound;
                            self.collectionPlayingCategory = nil;
                            if (cellIndexPath) {
                                self.playingStatusDictionary[cellIndexPath] = nil;
                                self.playingRowDictionary[cellIndexPath] = nil;
                            }
                            [cell configWithPlayerStatus:ACCAVPlayerPlayStatusPause forRow:row];
                        } else {
                            [self p_makeCurrentPlayingCellPause];
                            if (self.collectionPlayingMusicRow != NSNotFound) {
                                if (self.playingMusicIndexPath) {
                                    self.playingStatusDictionary[self.playingMusicIndexPath] = nil;
                                    self.playingRowDictionary[self.playingMusicIndexPath] = nil;
                                }
                            }
                            if (cellIndexPath) {
                                self.playingStatusDictionary[cellIndexPath] = @(ACCAVPlayerPlayStatusLoading);
                                self.playingRowDictionary[cellIndexPath] = @(row);
                            }
                            [cell configWithPlayerStatus:ACCAVPlayerPlayStatusLoading forRow:row];
                            self.playingMusicIndexPath = cellIndexPath;
                            self.collectionPlayingMusicRow = row;
                            if (data.type == AWEMusicCollectionDataTypeMusicCollection) {
                                self.collectionPlayingCategory = data.collectionFeed.category;
                            } else {
                                self.collectionPlayingCategory = [[ACCVideoMusicCategoryModel alloc] init];
                                self.collectionPlayingCategory.name = @"top_tabs_recomend";
                            }
                            self.playingMusic = music;
                        }

                        if (self.playingMusic) {
                            //到达试听时长停止播放
                            self.startClickStreamingPlay = CACurrentMediaTime();
                            @weakify(self);
                            [self.audioPlayer updateServiceWithMusicModel:self.playingMusic audioPlayerPlayingBlock:^{
                                @strongify(self);
                                acc_dispatch_main_async_safe(^{
                                    [self p_makeCurrentPlayingCellPause];
                                    if (self.collectionPlayingMusicRow != NSNotFound) {
                                        if (self.playingMusicIndexPath) {
                                            self.playingStatusDictionary[self.playingMusicIndexPath] = nil;
                                            self.playingRowDictionary[self.playingMusicIndexPath] = nil;
                                        }
                                    }
                                });
                                [self.audioPlayer pause];
                                self.playingMusic = nil;
                                self.playingMusicIndexPath = nil;
                                self.collectionPlayingMusicRow = NSNotFound;
                                self.collectionPlayingCategory = nil;
                            }];
                            [self.audioPlayer play];
                        }
                    };
                    cell.confirmAudioBlock = ^(id<ACCMusicModelProtocol>audio, NSError *error, NSString *categoryId, NSString *categoryName, NSInteger row) {
                        @strongify(self);
                        if ([audio isOffLine]) {
                            [ACCToast() show:audio.offlineDesc];
                            return;
                        }
                        audio.categoryId = categoryId;
                        [self.audioPlayer pause];
                        self.playingMusic = nil;
                        self.playingMusicIndexPath = nil;
                        self.collectionPlayingMusicRow = NSNotFound;
                        self.collectionPlayingCategory = nil;
                        [self didPickAudio:audio fromClip:NO error:error];
                        NSMutableDictionary *params = [NSMutableDictionary dictionary];
                        params[@"enter_from"] = @"change_music_page";
                        params[@"music_id"] = audio.musicID ?: @"";
                        params[@"category_Id"] = categoryId ?: @"";
                        params[@"category_name"] = categoryName ?: @"";
                        params[@"previous_page"] = self.previousPage ?: @"";
                        params[@"order"] = @(row);
                        [ACCTracker() trackEvent:@"add_music"
                                           params:[params copy]];
                    };
                    cell.moreButtonClicked = ^(id<ACCMusicModelProtocol>music, NSString *categoryId, NSString *categoryName) {
                        @strongify(self);
                        [self enterMusicDetailViewController:music categoryId:categoryId categoryName:categoryName];
                    };
                    cell.tapWhileLoadingBlock = ^{
                        [ACCToast() show:ACCLocalizedString(@"com_mig_loading_24vqw0", @"正在加载中...")];
                    };
                    @weakify(cell);
                    cell.favMusicBlock = ^(id<ACCMusicModelProtocol>audio, NSString *categoryId, NSString *categoryName, NSInteger row) {
                        @strongify(self);
                        @strongify(cell);
                        if ([audio isOffLine]) {
                            [ACCToast() show:audio.offlineDesc];
                            return;
                        }
                        if (![IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin]) {
                            [ACCTracker() trackEvent:@"login_notify"
                                                              label:@"click_favorite_music"
                                                              value:nil
                                                              extra:nil
                                                         attributes:nil];
                        }
                        [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) requireLogin:^(BOOL success) {
                            if (success) {
                                NSDictionary *params = @{
                                                         @"enter_from" : @"change_music_page",
                                                         @"music_id" : audio.musicID ?: @"",
                                                         @"category_Id" : categoryId ?: @"",
                                                         @"category_name" : categoryName ?: @"",
                                                         @"previous_page" : self.previousPage ?: @"",
                                                         @"order" : @(row)
                                                         };
                                [self p_collectionBtnClickedWithAudio:audio tableViewCell:cell withDict:params needRefreshTable:NO];
                            } else {
                                // TODO(liyansong): check error case
                            }
                        } withTrackerInformation:@{@"enter_from" : @"favorite_song", @"enter_method" : @"click_favorite_music"}];
                    };
                }
                cell.previousPage = self.previousPage;
                cell.showMore = NO;
                cell.disableCutMusic = self.disableCutMusic;
                if (!self.disableCutMusic) {
                    cell.showClipButton = YES;
                }
                cell.isCommerce = NO;
                cell.recordMode = self.recordServerMode;
                cell.videoDuration = self.videoDuration;
                [cell configWithMusicCollectionData:data showTopLine:!((indexPath.section - 1 >= 0) && [self getFirstDataOfSection:indexPath.section - 1])];
                for (UIGestureRecognizer *ges in self.view.gestureRecognizers) {
                    if ([ges isKindOfClass:[UIPanGestureRecognizer class]]) { // 滑动cell的时候不触发下拉关闭手势
                        [ges requireGestureRecognizerToFail:cell.musicCollectionView.panGestureRecognizer];
                        break;
                    }
                }
                return cell;
            }
                break;
            case AWEMusicCollectionDataTypeCategory:
            {
                NSString *identifier = [ACCASMusicCategoryCollectionTableViewCell identifier];
                ACCASMusicCategoryCollectionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
                if (!cell) {
                    cell = [[ACCASMusicCategoryCollectionTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
                    @weakify(self);
                    cell.completion = ^(id<ACCMusicModelProtocol>audio, NSError *error) {
                        @strongify(self);
                        [self didPickAudio:audio fromClip:NO error:error];
                    };
                    cell.enableClipBlock = ^BOOL(id<ACCMusicModelProtocol> audio) {
                        @strongify(self);
                        return ACCBLOCK_INVOKE(self.enableClipBlock, audio);
                    };
                    cell.willClipBlock = ^(id<ACCMusicModelProtocol> audio, NSError *error) {
                        @strongify(self);
                        if (audio && !error) {
                            [self p_showMusicClipViewWithMusic:audio];
                        } else {
                            AWELogToolError(AWELogToolTagMusic, @"select music vc | ACCASMusicCategoryCollectionTableViewCell willClipBlock | fetch music failed: %@", error);
                        }
                    };
                }
                cell.shouldHideCellMoreButton = self.shouldHideCellMoreButton;
                cell.previousPage = self.previousPage;
                cell.isCommerce = NO;
                cell.recordMode = self.recordServerMode;
                cell.videoDuration = self.videoDuration;
                cell.disableCutMusic = self.disableCutMusic;
                [cell configWithMusicCategoryModelArray:data.categoryList];
                return cell;
            }
                break;
            case AWEMusicCollectionDataTypeChallenage:
            case AWEMusicCollectionDataTypeSameStickerMusic:
            case AWEMusicCollectionDataTypeMV:
            case AWEMusicCollectionDataTypeUploadRecommend:
            case AWEMusicCollectionDataTypeProp:
            {
                NSString *identifier = [ACCASSelectMusicChallengeTableViewCell identifier];
                ACCASSelectMusicChallengeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
                if (!cell) {
                    cell = [[ACCASSelectMusicChallengeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
                    @weakify(self);
                    @weakify(cell);
                    cell.confirmBlock = ^(id<ACCMusicModelProtocol> _Nullable audio, NSError * _Nullable error) {
                        @strongify(self);
                        @strongify(cell);
                        if ([audio isOffLine]) {
                            [ACCToast() show:audio.offlineDesc];
                            return;
                        }
                        NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
                        audio.categoryId = nil;
                        [self.audioPlayer pause];
                        self.playingMusic = nil;
                        self.playingMusicIndexPath = nil;
                        self.collectionPlayingMusicRow = NSNotFound;
                        self.collectionPlayingCategory = nil;
                        ACCBLOCK_INVOKE(self.updatePublishModelCategoryIdBlock, nil);
                        if (data.type == AWEMusicCollectionDataTypeChallenage) {
                            audio.musicSelectedFrom = @"prop_rec";//埋点统计
                        } else if (data.type == AWEMusicCollectionDataTypeProp) {
                            audio.musicSelectedFrom = @"challenge_rec";
                        }
                        [self didPickAudio:audio fromClip:NO error:error];
                        NSMutableDictionary *trackParams = [@{
                                                              @"enter_from" : @"change_music_page",
                                                              @"music_id" : audio.musicID ?: @"",
                                                              @"previous_page" : self.previousPage ?: @"",
                                                              @"order" : @(cellIndexPath.row)
                                                              } mutableCopy];
                        if (data.type == AWEMusicCollectionDataTypeChallenage) {
                            [trackParams setValue:@"challenge" forKey:@"category_name"];
                            [trackParams setValue:self.challenge.itemID forKey:@"tag_id"];
                        } else if (data.type == AWEMusicCollectionDataTypeProp) {
                            [trackParams setValue:@"prop" forKey:@"category_name"];
                            [trackParams setValue:self.propId forKey:@"prop_id"];
                        }

                        [ACCTracker() trackEvent:@"add_music"
                                           params:trackParams];
                    };
                    cell.enableClipBlock = ^BOOL(id<ACCMusicModelProtocol> _Nonnull music) {
                        @strongify(self);
                        return ACCBLOCK_INVOKE(self.enableClipBlock, music);
                    };
                    cell.clipBlock = ^(id<ACCMusicModelProtocol> _Nullable audio, NSError * _Nullable error) {
                        @strongify(self);
                        if (audio && !error) {
                            [self p_showMusicClipViewWithMusic:audio];
                        } else {
                            AWELogToolError(AWELogToolTagMusic, @"select music vc | ACCASSelectMusicChallengeTableViewCell clipBlock | fetch music failed: %@", error);
                        }
                    };
                    cell.moreButtonClicked = ^(id<ACCMusicModelProtocol> _Nonnull music) {
                        NSString *name = @"";
                        if (data.type == AWEMusicCollectionDataTypeChallenage) {
                            name = @"challenge";
                        } else if (data.type == AWEMusicCollectionDataTypeProp) {
                            name = @"prop";
                        }
                        @strongify(self);
                        [self enterMusicDetailViewController:music  categoryId:nil categoryName:name];
                    };
                    cell.favouriteBlock = ^(id<ACCMusicModelProtocol>audio) {
                        @strongify(self);
                        @strongify(cell);
                        if ([audio isOffLine]) {
                            [ACCToast() show:audio.offlineDesc];
                            return;
                        }
                        if (![IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin]) {
                            [ACCTracker() trackEvent:@"login_notify"
                                                              label:@"click_favorite_music"
                                                              value:nil
                                                              extra:nil
                                                         attributes:nil];
                        }
                        [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) requireLogin:^(BOOL success) {
                            if (success) {
                                NSMutableDictionary *trackParams = [@{
                                                       @"enter_from" : @"change_music_page",
                                                       @"music_id" : audio.musicID ?: @"",
                                                       @"previous_page" : self.previousPage ?: @"",
                                                       } mutableCopy];
                                if (data.type == AWEMusicCollectionDataTypeChallenage) {
                                    [trackParams setValue:@"challenge" forKey:@"category_name"];
                                    [trackParams setValue:self.challenge.itemID forKey:@"tag_id"];
                                } else if (data.type == AWEMusicCollectionDataTypeProp) {
                                    [trackParams setValue:@"prop" forKey:@"category_name"];
                                    [trackParams setValue:self.propId forKey:@"prop_id"];
                                }
                                [self p_collectionBtnClickedWithAudio:audio tableViewCell:cell withDict:trackParams needRefreshTable:NO];
                            } else {
                                // TODO(liyansong): check error case
                            }
                        } withTrackerInformation:@{@"enter_from" : @"favorite_song", @"enter_method" : @"click_favorite_music"}];
                    };
                    cell.tapWhileLoadingBlock = ^{
                        [ACCToast() show:ACCLocalizedString(@"com_mig_loading_24vqw0", @"正在加载中...")];
                    };
                }
                cell.showMore = NO;
                if (!self.disableCutMusic) {
                    cell.showClipButton = YES;
                }
                [cell configWithChallengeMusic:data.music isLastOne:(self.dataList[indexPath.section].count == indexPath.row + 1)];
                return cell;
            }
                break;
            case AWEMusicCollectionDataTypeMusic:
            {
                NSString *identifier = NSStringFromClass([AWESingleMusicTableViewCell class]);
                AWESingleMusicTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
                if (!cell) {
                    cell = [[AWESingleMusicTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
                    @weakify(self);
                    @weakify(cell);
                    cell.confirmBlock = ^(id<ACCMusicModelProtocol> audio, NSError *error) {
                        @strongify(self);
                        @strongify(cell);
                        if ([audio isOffLine]) {
                            [ACCToast() show:audio.offlineDesc];
                            return;
                        }
                        NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
                        audio.categoryId = nil;
                        [self.audioPlayer pause];
                        self.playingMusic = nil;
                        self.playingMusicIndexPath = nil;
                        self.collectionPlayingMusicRow = NSNotFound;
                        self.collectionPlayingCategory = nil;
                        ACCBLOCK_INVOKE(self.updatePublishModelCategoryIdBlock, nil);
                        audio.musicSelectedFrom = @"favourite";//埋点统计
                        [self didPickAudio:audio fromClip:NO error:error];
                        NSMutableDictionary *params = [NSMutableDictionary dictionary];
                        params[@"enter_from"] = @"change_music_page";
                        params[@"music_id"] = audio.musicID ?: @"";
                        params[@"category_name"] = @"favourite_song";
                        params[@"previous_page"] = self.previousPage ?: @"favourite_song";
                        params[@"order"] = @(cellIndexPath.row);
                        [ACCTracker() trackEvent:@"add_music"
                                           params:[params copy]];
                    };
                    cell.enableClipBlock = ^BOOL(id<ACCMusicModelProtocol> _Nonnull music) {
                        @strongify(self);
                        return ACCBLOCK_INVOKE(self.enableClipBlock, music);
                    };
                    cell.clipBlock = ^(id<ACCMusicModelProtocol> _Nullable audio, NSError * _Nullable error) {
                        @strongify(self);
                        if (audio && !error) {
                            [self p_showMusicClipViewWithMusic:audio];
                        } else {
                            AWELogToolError(AWELogToolTagMusic, @"select music vc | AWESingleMusicTableViewCell clipBlock | fetch music failed: %@", error);
                        }
                    };
                    cell.moreButtonClicked = ^(id<ACCMusicModelProtocol> _Nonnull music) {
                        @strongify(self);
                        [self enterMusicDetailViewController:music categoryId:nil categoryName:@"favourite_song"];
                    };
                    cell.favouriteBlock = ^(id<ACCMusicModelProtocol>audio) {
                        @strongify(self);
                        @strongify(cell);
                        if ([audio isOffLine]) {
                            [ACCToast() show:audio.offlineDesc];
                            return;
                        }
                        if (![IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin]) {
                            [ACCTracker() trackEvent:@"login_notify"
                                                              label:@"click_favorite_music"
                                                              value:nil
                                                              extra:nil
                                                         attributes:nil];
                        }
                        [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) requireLogin:^(BOOL success) {
                            @strongify(self);
                            if (success) {
                                // 已经收藏的列表不需要再收藏
                                NSDictionary *params = @{
                                                         @"enter_from" : @"change_music_page",
                                                         @"music_id" : audio.musicID ?: @"",
                                                         };
                                [self p_collectionBtnClickedWithAudio:audio tableViewCell:cell withDict:params needRefreshTable:NO];
                            } else {
                                // TODO(liyansong): check error case
                            }
                        } withTrackerInformation:@{@"enter_from" : @"favorite_song", @"enter_method" : @"click_favorite_music"}];
                    };
                    cell.tapWhileLoadingBlock = ^{
                        [ACCToast() show:ACCLocalizedString(@"com_mig_loading_24vqw0", @"正在加载中...")];
                    };
                }
                cell.musicView.showLyricLabel = NO;
                cell.showMore = NO;
                cell.needShowPGCMusicInfo = YES;
                if (!self.disableCutMusic) {
                    cell.showClipButton = YES;
                }
                [cell.musicView configWithMusicModel:data.music];
                if ([self.musicTabView selectedTabType] == ACCSelectMusicTabTypeCollect && indexPath.row == 0) {
                    cell.showExtraTopPadding = YES;
                } else {
                    cell.showExtraTopPadding = NO;
                }
                return cell;
            }
                break;
            case AWEMusicCollectionDataTypeFavEmpty:
            {
                NSString *identifier = NSStringFromClass([AWEASSTwoLineLabelWithIconTableViewCell class]);
                AWEASSTwoLineLabelWithIconTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
                cell.titleLabel.text = ACCLocalizedString(@"com_mig_favorite_sounds", @"你收藏的声音");
                cell.subtitleLabel.text = ACCLocalizedString(@"com_mig_add_sounds_to_favorites_so_you_can_easily_find_them_later", @"找不到那个声音啦？！记得收藏声音，这样可以在这里看到和使用他们");
                return cell;
            }
                break;
            case AWEMusicCollectionDataTypeEmptyPlaceholder:
                break;
            case AWEMusicCollectionDataTypeSearchEmpty:
            case AWEMusicCollectionDataTypeDynamic:
            case AWEMusicCollectionDataTypeRecommendVideo:
                break;
            case AWEMusicCollectionDataTypeExportAudioSection:
            {
                NSString *identifier = NSStringFromClass([ACCMusicExportAudioSection class]);
                ACCMusicExportAudioSection *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
                if (!cell) {
                    cell = [[ACCMusicExportAudioSection alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
                    @weakify(self);
                    cell.clickAction = ^{
                        @strongify(self);
                        //弹起提取资源的相册
                        [ACCTracker() trackEvent:@"click_extract_video_music_button" params:@{
                            @"shoot_way" : self.repository.repoTrack.referString ?: @"",
                            @"enter_from" : @"change_music_page",
                            @"creation_id" : self.repository.repoContext.createId ? : @""
                        }];
                        ACCAlbumInputData *albumInput = [[ACCAlbumInputData alloc] init];
                        albumInput.vcType = ACCAlbumVCTypeLocalAudioExport;
                        albumInput.selectAssetsCompletion = ^(NSArray<AWEAssetModel *> * _Nullable assets) {
                            @strongify(self);
                            [self p_handleExportAudio:assets.firstObject];
                        };

                        CAKAlbumViewController *viewController = [IESAutoInline(ACCBaseServiceProvider(), ACCSelectAlbumAssetsProtocol) albumViewControllerWithInputData:albumInput];
                        [self.navigationController pushViewController:viewController animated:YES];
                    };
                }
                return cell;
            }
                break;
            case AWEMusicCollectionDataTypeLocalAudioAuthSection:
            {
                NSString *identifier = NSStringFromClass([ACCLocalAudioAuthSection class]);
                ACCLocalAudioAuthSection *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
                if (!cell) {
                    @weakify(self);
                    cell = [[ACCLocalAudioAuthSection alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
                    cell.clickAction = ^{
                        @strongify(self);
                        [self requestLocalAudioAuth];
                    };
                }
                return cell;
            }
                break;
            case AWEMusicCollectionDataTypeLocalAudioEmptySection:{
                NSString *identifier = NSStringFromClass([ACCLocalAudioEmptySection class]);
                ACCLocalAudioEmptySection *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
                if (!cell) {
                    cell = [[ACCLocalAudioEmptySection alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
                }
                return cell;
            }
                break;
            case AWEMusicCollectionDataTypeAudioManageSection:{
                NSString *identifier = NSStringFromClass([ACCLocalAudioManageSection class]);
                ACCLocalAudioManageSection *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
                if (!cell) {
                    cell = [[ACCLocalAudioManageSection alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
                    @weakify(self);
                    cell.clickAction = ^{
                        @strongify(self);
                        [self localListEditClick];
                    };
                }
                return cell;
            }
                break;
            case AWEMusicCollectionDataTypeLocalMusicListSection:
            {
                NSString *identifier = NSStringFromClass([ACCSingleLocalMusicTableViewCell class]);
                ACCSingleLocalMusicTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
                if (!cell) {
                    //初始化的时候 给musicModel和isEditing
                    cell = [[ACCSingleLocalMusicTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                                   reuseIdentifier:identifier];
                    @weakify(self);
                    cell.confirmAction = ^(id<ACCMusicModelProtocol>  _Nullable audio) {
                        @strongify(self);
                        [self.audioPlayer pause];
                        self.playingMusic = nil;
                        self.playingMusicIndexPath = nil;
                        
                        audio.musicSelectedFrom = @"local";
                        [self didPickAudio:audio fromClip:NO error:nil];
                    };
                    cell.disableClipButton = self.disableCutMusic;
                    cell.clipAction = ^(id<ACCMusicModelProtocol> audio) {
                        @strongify(self);
                        if (audio) {
                            [self p_showMusicClipViewWithMusic:audio];
                        }
                    };
                    cell.renameAction = ^(id<ACCMusicModelProtocol> audio) {
                        @strongify(self);
                        [self pause];
                        NSMutableDictionary *trackParam = [NSMutableDictionary dictionaryWithDictionary:[self p_localAudioBasicTrackInfo]];
                        trackParam[@"manage_type"] = @"change_name";
                        [ACCTracker() trackEvent:@"click_music_manage" params:trackParam];
                        [ACCMusicTextEditAlertView showAlertOnView:self.view
                                                         withTitle:@"修改命名"
                                                confirmButtonTitle:@"确定"
                                                 cancelButtonTitle:@"取消"
                                                      confirmBlock:^BOOL(NSString * _Nonnull content) {
                            if (ACC_isEmptyString(content)) {
                                [ACCToast() show:@"修改音频名称失败"];
                                return NO;
                            } else if ([ACCLocalAudioUtils isContainIncorrectChar:content]){
                                [ACCToast() show:@"仅允许使用中文、英文、数字和英文下划线"];
                                return NO;
                                //敏感词还要判断一下
                            } else {
                                [self.localAudioDataController renameSingleLocalAudioWithAudio:audio newName:content];
                                [self p_prepareSelectMusicLocalData];
                                [self.tableView reloadData];
                            }
                            return YES;
                        } cancelBlock:nil];
                        
                    };
                    cell.deleteAction = ^(id<ACCMusicModelProtocol> audio){
                        @strongify(self);
                        [self pause];
                        NSMutableDictionary *trackParam = [NSMutableDictionary dictionaryWithDictionary:[self p_localAudioBasicTrackInfo]];
                        trackParam[@"manage_type"] = @"delete";
                        [ACCTracker() trackEvent:@"click_music_manage" params:trackParam];
                        [ACCMusicSimpleAlertView showAlertOnView:self.view
                                                       withTitle:@"确认删除该音频?"
                                              confirmButtonTitle:@"删除"
                                               cancelButtonTitle:@"取消"
                                                    confirmBlock:^{
                            @strongify(self);
                            [self.localAudioDataController deleteSingleLocalAudio:audio];
                            [self p_prepareSelectMusicLocalData];
                            [self.tableView reloadData];
                        }
                                                     cancelBlock:nil];
                    };
                }
                [cell bindMusicModel:data.music];
                return cell;
            }
                break;
            case AWEMusicCollectionDataTypeLocalAudioFooterAuthSection:{
                NSString *identifier = NSStringFromClass([ACCLocalAudioAuthFooterSection class]);
                ACCLocalAudioAuthFooterSection *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
                if (!cell) {
                    cell = [[ACCLocalAudioAuthFooterSection alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
                    @weakify(self);
                    cell.clickAction = ^{
                        @strongify(self);
                        [self requestLocalAudioAuth];
                    };
                }
                return cell;
            }
                break;
        }
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([self.musicTabView selectedTabType] == ACCSelectMusicTabTypeCollect ||
        [self.musicTabView selectedTabType] == ACCSelectMusicTabTypeLocal) {
        return nil;
    }
    AWEMusicCollectionData *data = [self getFirstDataOfSection:section];
    ACCASCommonBindMusicSectionHeaderView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[ACCASCommonBindMusicSectionHeaderView identifier]];
    if (data.type == AWEMusicCollectionDataTypeSameStickerMusic) {
        [view configWithTitle:ACCLocalizedCurrentString(@"origin_video_music") rightContent:nil cellWidth:self.tableView.bounds.size.width];
        return view;
    } else if (data.type == AWEMusicCollectionDataTypeChallenage) {
        if (self.challenge.isCommerce) {
            NSMutableArray<NSString *> *musicIDs = @[].mutableCopy;
            for (id<ACCMusicModelProtocol>music in [ACCCommerceMusicService() connectMusicsOfCMCChallenge:self.challenge]) {
                if (music.musicID) {
                    [musicIDs acc_addObject:music.musicID];
                }
            }
            [ACCMonitor() trackService:@"music_recommendations_monitor"
                            attributes:@{
                                @"shoot_way" : @"challenge",
                                @"challenge_id" : self.challenge.itemID ?: @"",
                                @"music_ids" :  musicIDs,
                            }];
        } 
        [view configWithTitle:ACCLocalizedCurrentString(@"sound_recommend_hashtag") rightContent:[NSString stringWithFormat:@" #%@ ", self.challenge.challengeName] cellWidth:self.tableView.bounds.size.width];
        return view;
    } else if (data.type == AWEMusicCollectionDataTypeProp) {
        [view configWithTitle:ACCLocalizedCurrentString(@"sound_recommend_prop") rightContent:nil cellWidth:self.tableView.bounds.size.width];
        return view;
    } else if (data.type == AWEMusicCollectionDataTypeMV) {
        [view configWithTitle:ACCLocalizedCurrentString(@"sound_recommend_mv") rightContent:nil cellWidth:self.tableView.bounds.size.width];
        return view;
    } else if (data.type == AWEMusicCollectionDataTypeUploadRecommend) {
        [view configWithTitle:ACCLocalizedCurrentString(@"sound_recommend_upload") rightContent:nil cellWidth:self.tableView.bounds.size.width];
        return view;
    } else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    AWEMusicCollectionData *data = [self getFirstDataOfSection:section];
    if (data.type == AWEMusicCollectionDataTypeSameStickerMusic ||
        data.type == AWEMusicCollectionDataTypeChallenage ||
        data.type == AWEMusicCollectionDataTypeProp ||
        data.type == AWEMusicCollectionDataTypeMV ||
        data.type == AWEMusicCollectionDataTypeUploadRecommend
        ) {
        return [ACCASCommonBindMusicSectionHeaderView recommendHeight];
    } else {
        return 0.001;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.dataList.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.001;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataList[section].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0.f;
    if (indexPath.section < self.dataList.count && indexPath.row < self.dataList[indexPath.section].count) {
        AWEMusicCollectionData *data = self.dataList[indexPath.section][indexPath.row];
        switch (data.type) {
            case AWEMusicCollectionDataTypeCategory:
            {
                if (!ACC_isEmptyArray(data.categoryList)) {
                    height = [ACCASMusicCategoryCollectionTableViewCell recommendedHeight:data.categoryList.count];
                } else {
                    height = [ACCASMusicCategoryCollectionTableViewCell recommendedHeight:0];
                }
            }
                break;
            case AWEMusicCollectionDataTypeMusicArray:
            case AWEMusicCollectionDataTypeMusicCollection:
                // 理论上这个height应该是274， 但是如果出现了pixel miss alignment会造成这个cell出现flow layout不能放下三行cell
                // 导致竖排只展示两行cell的情况，这个非常影响UI，所以增加 1 point来预防这种情况的发生
                height = 84 * 3 + 46 + 10;
                if ([ACCFont() acc_bigFontModeOn]) {
                    //长辈模式下 图片文本等size被放大 超出布局frame 显示不全第三行
                    height += 30;
                }
                break;
            case AWEMusicCollectionDataTypeMusic: {
                CGFloat musciViewHeight = [AWESingleMusicTableViewCell heightWithMusic:data.music baseHeight:84.f];
                height = ([self.musicTabView selectedTabType] == ACCSelectMusicTabTypeCollect && indexPath.row == 0) ? musciViewHeight + 12 : musciViewHeight;
                break;
            }

            case AWEMusicCollectionDataTypeChallenage:
            case AWEMusicCollectionDataTypeSameStickerMusic:
            case AWEMusicCollectionDataTypeUploadRecommend:
            case AWEMusicCollectionDataTypeProp:
            {
                height = [ACCASSelectMusicChallengeTableViewCell recommendedHeight];
                if (indexPath.row == self.dataList[indexPath.section].count - 1) {
                    height += 4;
                }
            }
                break;
            case AWEMusicCollectionDataTypeMV:
            {
                height = [ACCASSelectMusicChallengeTableViewCell recommendedHeight];
            }
                break;
            case AWEMusicCollectionDataTypeFavEmpty:
                height = 340;
                break;
            case AWEMusicCollectionDataTypeEmptyPlaceholder:
                break;
            case AWEMusicCollectionDataTypeSearchEmpty:
                break;
            case AWEMusicCollectionDataTypeDynamic:
                break;
            case AWEMusicCollectionDataTypeRecommendVideo:
                break;
            case AWEMusicCollectionDataTypeExportAudioSection:
                height = [ACCMusicExportAudioSection sectionHeight];
                break;
            case AWEMusicCollectionDataTypeLocalAudioAuthSection:
                height = [ACCLocalAudioAuthSection sectionHeight];
                break;
            case AWEMusicCollectionDataTypeLocalAudioEmptySection:
                height = [ACCLocalAudioEmptySection sectionHeight];
                break;
            case AWEMusicCollectionDataTypeAudioManageSection:
                height = [ACCLocalAudioManageSection sectionHeight];
                break;
            case AWEMusicCollectionDataTypeLocalMusicListSection:
                height = [ACCSingleLocalMusicTableViewCell sectionHeight];
                break;
            case AWEMusicCollectionDataTypeLocalAudioFooterAuthSection:
                height = [ACCLocalAudioAuthFooterSection sectionHeight];
                break;
        }
    }
    return height;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
        didEndDisplayingCell:(UITableViewCell *)cell
           forRowAtIndexPath:(NSIndexPath *)unsafeIndexPath {
    if (unsafeIndexPath.section < self.dataList.count && unsafeIndexPath.row < self.dataList[unsafeIndexPath.section].count) {
        AWEMusicCollectionData *data = self.dataList[unsafeIndexPath.section][unsafeIndexPath.row];
        switch (data.type) {
            case AWEMusicCollectionDataTypeMusicArray:
            case AWEMusicCollectionDataTypeMusicCollection:
            {
                if ([cell isKindOfClass:[ACCMusicCollectionTableViewCell class]]) {
                    ACCMusicCollectionTableViewCell *disappearCell = (ACCMusicCollectionTableViewCell *)cell;
                    CGFloat contentOffsetX = disappearCell.musicCollectionView.contentOffset.x;
                    unsafeIndexPath = [NSIndexPath indexPathForRow:unsafeIndexPath.row inSection:unsafeIndexPath.section];
                    self.contentOffsetDictionary[unsafeIndexPath] = @(contentOffsetX);
                }
            }
                break;
            default:
                break;
        }
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < self.dataList.count && indexPath.row < self.dataList[indexPath.section].count) {
        AWEMusicCollectionData *data = self.dataList[indexPath.section][indexPath.row];
        switch (data.type) {
            case AWEMusicCollectionDataTypeMusicArray:
            case AWEMusicCollectionDataTypeMusicCollection:
            {
                indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
                if (![cell isKindOfClass:[ACCMusicCollectionTableViewCell class]]) {
                    return;
                }
                ACCMusicCollectionTableViewCell *appearCell = (ACCMusicCollectionTableViewCell *)cell;
                if (self.contentOffsetDictionary[indexPath]) {
                    NSNumber *contentOffsetX = self.contentOffsetDictionary[indexPath];
                    appearCell.musicCollectionView.contentOffset = CGPointMake(contentOffsetX.floatValue, 0);
                } else {
                    appearCell.musicCollectionView.contentOffset = CGPointMake(-appearCell.initialContentOffsetX, 0);
                }
                if (self.playingStatusDictionary[indexPath]) {
                    NSNumber *status = self.playingStatusDictionary[indexPath];
                    NSNumber *row = self.playingRowDictionary[indexPath];
                    [appearCell configWithPlayerStatus:status.integerValue forRow:row.integerValue];
                } else {
                    [appearCell configWithPlayerStatus:ACCAVPlayerPlayStatusPause forRow:NSNotFound];
                }
            }
                break;
            case AWEMusicCollectionDataTypeMusic:
            {
                if (![cell isKindOfClass:[AWESingleMusicTableViewCell class]]) {
                    return;
                }
                AWESingleMusicTableViewCell *appearCell = (AWESingleMusicTableViewCell *)cell;
                if ([indexPath isEqual:self.playingMusicIndexPath]) {
                    [appearCell.musicView configWithPlayerStatus:self.cellPlayStatus animated:NO];
                } else {
                    [appearCell.musicView configWithPlayerStatus:ACCAVPlayerPlayStatusPause animated:NO];
                }
                NSMutableDictionary *params = [NSMutableDictionary dictionary];
                params[@"music_id"] = data.music.musicID ?: @"";
                params[@"enter_from"] = @"change_music_page";
                params[@"category_name"] = @"favorite_song";
                params[@"previous_page"] = self.previousPage ?: @"";
                params[@"order"] = @(indexPath.row);
                params[@"ugc_to_pgc_meta"] = ACC_isEmptyString(data.music.matchedPGCMixedAuthor) ? @0 : @1;
                [ACCTracker() trackEvent:@"show_music"
                                   params:[params copy]];
            }
                break;
            case AWEMusicCollectionDataTypeChallenage:
            case AWEMusicCollectionDataTypeSameStickerMusic:
            case AWEMusicCollectionDataTypeProp:
            {
                if (![cell isKindOfClass:[ACCASSelectMusicChallengeTableViewCell class]]) {
                    return;
                }
                ACCASSelectMusicChallengeTableViewCell *appearCell = (ACCASSelectMusicChallengeTableViewCell *)cell;
                if ([indexPath isEqual:self.playingMusicIndexPath]) {
                    [appearCell.musicView configWithPlayerStatus:self.cellPlayStatus animated:NO];
                } else {
                    [appearCell.musicView configWithPlayerStatus:ACCAVPlayerPlayStatusPause animated:NO];
                }
                NSMutableDictionary *trackParams = [@{
                                                     @"music_id" : data.music.musicID ?: @"",
                                                     @"enter_from" : @"change_music_page",
                                                     @"previous_page" : self.previousPage ?: @"",
                                                     @"order" : @(indexPath.row)
                                                     } mutableCopy];
                if (data.type == AWEMusicCollectionDataTypeChallenage) {
                    [trackParams setValue:@"challenge" forKey:@"category_name"];
                    [trackParams setValue:self.challenge.itemID forKey:@"tag_id"];
                } else if (data.type == AWEMusicCollectionDataTypeProp) {
                    [trackParams setValue:@"prop" forKey:@"category_name"];
                    [trackParams setValue:self.propId forKey:@"prop_id"];
                }
                trackParams[@"ugc_to_pgc_meta"] = ACC_isEmptyString(data.music.matchedPGCMixedAuthor) ? @0 : @1;
                [ACCTracker() trackEvent:@"show_music"
                                   params:[trackParams copy]];
            }
                break;
            case AWEMusicCollectionDataTypeAudioManageSection:{
                ACCLocalAudioManageSection *manageCell = (ACCLocalAudioManageSection *)cell;
                [manageCell configWithEditStatus:self.isEditingLocalState];
            }
                break;
            case AWEMusicCollectionDataTypeLocalMusicListSection:{
                if (![cell isKindOfClass:[ACCSingleLocalMusicTableViewCell class]]) {
                    return;
                }
                ACCSingleLocalMusicTableViewCell *appearCell = (ACCSingleLocalMusicTableViewCell *)cell;
                if ([indexPath isEqual:self.playingMusicIndexPath]) {
                    [appearCell configWithPlayerStatus:self.cellPlayStatus animated:NO];
                } else {
                    [appearCell configWithPlayerStatus:ACCAVPlayerPlayStatusPause animated:NO];
                }
                [appearCell configWithEditStatus:self.isEditingLocalState];

                NSMutableDictionary *params = [NSMutableDictionary dictionary];
                params[@"music_id"] = data.music.musicID ?: @"";
                params[@"enter_from"] = @"change_music_page";
                params[@"category_name"] = @"app_local";
                params[@"previous_page"] = self.previousPage ?: @"";
                params[@"order"] = @(indexPath.row);
                params[@"ugc_to_pgc_meta"] = ACC_isEmptyString(data.music.matchedPGCMixedAuthor) ? @0 : @1;
                [ACCTracker() trackEvent:@"show_music"
                                   params:[params copy]];
            }
            default:
                break;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section < self.dataList.count && indexPath.row < self.dataList[indexPath.section].count) {
        AWEMusicCollectionData *data = self.dataList[indexPath.section][indexPath.row];
        switch (data.type) {
            case AWEMusicCollectionDataTypeChallenage:
            case AWEMusicCollectionDataTypeSameStickerMusic:
            case AWEMusicCollectionDataTypeMV:
            case AWEMusicCollectionDataTypeUploadRecommend:
            case AWEMusicCollectionDataTypeProp: {
                [self.audioPlayer pause];
                ACCASSelectMusicChallengeTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                if (!self.playingMusic) {
                    self.playingMusicIndexPath = indexPath;
                    self.cellPlayStatus = ACCAVPlayerPlayStatusLoading;
                    self.playingMusic = data.music;
                    [cell.musicView configWithPlayerStatus:ACCAVPlayerPlayStatusLoading];
                    
                    
                } else if ([self.playingMusic isEqual:data.music]) { //选择相同音乐
                    self.playingMusic = nil;
                    self.playingMusicIndexPath = nil;
                    self.cellPlayStatus = ACCAVPlayerPlayStatusPause;
                    [cell.musicView configWithPlayerStatus:ACCAVPlayerPlayStatusPause];
                } else {//切换音乐
                    UITableViewCell *lastPlayingCell = [tableView cellForRowAtIndexPath:self.playingMusicIndexPath];
                    if ([lastPlayingCell isKindOfClass:[AWESingleMusicTableViewCell class]]) {
                        [[(AWESingleMusicTableViewCell *)lastPlayingCell musicView] configWithPlayerStatus:ACCAVPlayerPlayStatusPause];
                    } else if ([lastPlayingCell isKindOfClass:[ACCMusicCollectionTableViewCell class]]){
                        if (self.collectionPlayingMusicRow != NSNotFound) {
                            ACCMusicCollectionTableViewCell *lastCell = [self.tableView cellForRowAtIndexPath:self.playingMusicIndexPath];
                            if (self.playingMusicIndexPath) {
                                self.playingStatusDictionary[self.playingMusicIndexPath] = nil;
                                self.playingRowDictionary[self.playingMusicIndexPath] = nil;
                            }
                            [lastCell configWithPlayerStatus:ACCAVPlayerPlayStatusPause
                                                      forRow:self.collectionPlayingMusicRow];
                            self.collectionPlayingMusicRow = NSNotFound;
                        }
                    } else if ([lastPlayingCell isKindOfClass:[ACCASSelectMusicChallengeTableViewCell class]]) {
                        [[(ACCASSelectMusicChallengeTableViewCell *)lastPlayingCell musicView] configWithPlayerStatus:ACCAVPlayerPlayStatusPause];
                    } else if (!lastPlayingCell) {
                        // 有可能cell不在屏幕了，这个时候注意要清空collectionPlayingMusicRow，否则在audiostatus的delegate回调
                        // 会因为这个没有清空造成cell类型不能响应正确的方法的问题，造成crash
                        if (self.collectionPlayingMusicRow != NSNotFound) {
                            self.collectionPlayingMusicRow = NSNotFound;
                            if (self.playingMusicIndexPath) {
                                self.playingStatusDictionary[self.playingMusicIndexPath] = nil;
                                self.playingRowDictionary[self.playingMusicIndexPath] = nil;
                            }
                        }
                    }
                    [cell.musicView configWithPlayerStatus:ACCAVPlayerPlayStatusLoading];
                    self.playingMusicIndexPath = indexPath;
                    self.cellPlayStatus = ACCAVPlayerPlayStatusLoading;
                    self.playingMusic = data.music;
                }
                
                if (self.playingMusic) {
                    //到达试听时长停止播放
                    @weakify(self);
                    [self.audioPlayer updateServiceWithMusicModel:self.playingMusic audioPlayerPlayingBlock:^{
                        @strongify(self);
                        UITableViewCell *lastPlayingCell = [tableView cellForRowAtIndexPath:self.playingMusicIndexPath];
                        
                        if ([lastPlayingCell isKindOfClass:[AWESingleMusicTableViewCell class]]) {
                            acc_dispatch_main_async_safe(^{
                                [[(AWESingleMusicTableViewCell *)lastPlayingCell musicView] configWithPlayerStatus:ACCAVPlayerPlayStatusPause];
                            });
                        } else if ([lastPlayingCell isKindOfClass:[ACCMusicCollectionTableViewCell class]]){
                            if (self.collectionPlayingMusicRow != NSNotFound) {
                                ACCMusicCollectionTableViewCell *lastCell =
                                [self.tableView cellForRowAtIndexPath:self.playingMusicIndexPath];
                                if (self.playingMusicIndexPath) {
                                    self.playingStatusDictionary[self.playingMusicIndexPath] = nil;
                                    self.playingRowDictionary[self.playingMusicIndexPath] = nil;
                                }
                                acc_dispatch_main_async_safe(^{
                                    [lastCell configWithPlayerStatus:ACCAVPlayerPlayStatusPause
                                                              forRow:self.collectionPlayingMusicRow];
                                });
                                self.collectionPlayingMusicRow = NSNotFound;
                            }
                        } else if ([lastPlayingCell isKindOfClass:[ACCASSelectMusicChallengeTableViewCell class]]) {
                            acc_dispatch_main_async_safe(^{
                                [[(ACCASSelectMusicChallengeTableViewCell *)lastPlayingCell musicView] configWithPlayerStatus:ACCAVPlayerPlayStatusPause];
                            });
                        } else if (!lastPlayingCell) {
                            // 有可能cell不在屏幕了，这个时候注意要清空collectionPlayingMusicRow，否则在audiostatus的delegate回调
                            // 会因为这个没有清空造成cell类型不能响应正确的方法的问题，造成crash
                            if (self.collectionPlayingMusicRow != NSNotFound) {
                                self.collectionPlayingMusicRow = NSNotFound;
                                if (self.playingMusicIndexPath) {
                                    self.playingStatusDictionary[self.playingMusicIndexPath] = nil;
                                    self.playingRowDictionary[self.playingMusicIndexPath] = nil;
                                }
                            }
                        }
                        [self.audioPlayer pause];
                        self.playingMusic = nil;
                        self.playingMusicIndexPath = nil;
                        self.collectionPlayingMusicRow = NSNotFound;
                        self.cellPlayStatus = ACCAVPlayerPlayStatusPause;
                    }];
                    [self.audioPlayer play];
                }
            }
                break;
            case AWEMusicCollectionDataTypeMusic: {
                if ([data.music isOffLine]) {
                    [ACCToast() show:data.music.offlineDesc];
                    return;                    
                }
                [self.audioPlayer pause];
                AWESingleMusicTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                if (!self.playingMusic) {
                    self.playingMusicIndexPath = indexPath;
                    self.cellPlayStatus = ACCAVPlayerPlayStatusLoading;
                    self.playingMusic = data.music;
                    [cell.musicView configWithPlayerStatus:ACCAVPlayerPlayStatusLoading];
                } else if ([self.playingMusic isEqual:data.music]) {
                    self.playingMusic = nil;
                    self.playingMusicIndexPath = nil;
                    self.cellPlayStatus = ACCAVPlayerPlayStatusPause;
                    [cell.musicView configWithPlayerStatus:ACCAVPlayerPlayStatusPause];
                } else {
                    [self p_makeCurrentPlayingCellPause];
                    [cell.musicView configWithPlayerStatus:ACCAVPlayerPlayStatusLoading];
                    self.playingMusicIndexPath = indexPath;
                    self.cellPlayStatus = ACCAVPlayerPlayStatusLoading;
                    self.playingMusic = data.music;
                }
                
                if (self.playingMusic) {
                    @weakify(self);
                    [self.audioPlayer updateServiceWithMusicModel:self.playingMusic audioPlayerPlayingBlock:^{
                        @strongify(self);
                        acc_dispatch_main_async_safe(^{
                            [self p_makeCurrentPlayingCellPause];
                        });
                        [self.audioPlayer pause];
                        self.playingMusic = nil;
                        self.playingMusicIndexPath = nil;
                        self.cellPlayStatus = ACCAVPlayerPlayStatusPause;
                    }];
                    [self.audioPlayer play];
                }
            }
                break;
            case AWEMusicCollectionDataTypeLocalMusicListSection:{
                [self.audioPlayer pause];
                ACCSingleLocalMusicTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                if (!self.playingMusic) {
                    //现在没有播放的歌
                    self.playingMusicIndexPath = indexPath;
                    self.cellPlayStatus = ACCAVPlayerPlayStatusLoading;
                    self.playingMusic = data.music;
                    [cell configWithPlayerStatus:ACCAVPlayerPlayStatusLoading];
                } else if ([self.playingMusic isEqual:data.music]) {
                    //点击现在正在播的歌
                    self.playingMusic = nil;
                    self.playingMusicIndexPath = nil;
                    self.cellPlayStatus = ACCAVPlayerPlayStatusPause;
                    [cell configWithPlayerStatus:ACCAVPlayerPlayStatusPause];
                } else{
                    //切换旧播当前播的歌曲
                    [self p_makeCurrentPlayingCellPause];
                    [cell configWithPlayerStatus:ACCAVPlayerPlayStatusLoading];
                    self.playingMusicIndexPath = indexPath;
                    self.cellPlayStatus = ACCAVPlayerPlayStatusLoading;
                    self.playingMusic = data.music;
                }
                if (self.playingMusic) {
                    @weakify(self);
                    [self.audioPlayer updateServiceWithMusicModel:self.playingMusic audioPlayerPlayingBlock:^{
                        @strongify(self);
                        acc_dispatch_main_async_safe(^{
                            [self p_makeCurrentPlayingCellPause];
                        });
                        [self.audioPlayer pause];
                        self.playingMusic = nil;
                        self.playingMusicIndexPath = nil;
                        self.cellPlayStatus = ACCAVPlayerPlayStatusPause;
                    }];
                    [self.audioPlayer play];
                }
            }
            default:
                break;
        }
    }
}
                                                                              
#pragma mark - helper

- (CGFloat)footerInset
{
    //这里设置60是因为infinite的inset为60，保持跟原来一致
    return 60;
}

- (BOOL)loadMoreHasMore
{
    if ([self.musicTabView selectedTabType] == ACCSelectMusicTabTypeHot) {
        return self.feedManager.hasMoreDiscover;
    } else if ([self.musicTabView selectedTabType] == ACCSelectMusicTabTypeCollect){
        return self.feedManager.hasMoreFavourite;
    }
    return NO;
}

- (void)enterMusicDetailViewController:(id<ACCMusicModelProtocol>)music categoryId:(NSString *)categoryId categoryName:(NSString *)categoryName
{
    if ([music isOffLine]) {
        [ACCToast() show:music.offlineDesc];
        [ACCTracker() trackEvent:@"enter_music_detail_failed"
                           params:@{
                               @"enter_from" : @"change_music_page",
                               @"music_id" : music.musicID,
                               @"category_name" : categoryName,
                               @"category_Id" : categoryId ?: @"",
                               @"enter_method" : @"click_button"
                           }
                  needStagingFlag:YES];
        return;
    }
    NSString *processID = [[NSUUID UUID] UUIDString];
    UIViewController *musicViewController = [ACCRouter() viewControllerForURLString:[NSString stringWithFormat:@"aweme://music/detail/%@?process_id=%@", music.musicID,processID]];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:musicViewController];
    nav.modalPresentationStyle = UIModalPresentationCustom;
    nav.modalPresentationCapturesStatusBarAppearance = YES;
    nav.transitioningDelegate = self.transitionDelegate.targetTransitionDelegate;
    UIViewController *topViewController = [ACCResponder topViewController];
    [self.transitionDelegate wireToViewController:nav.topViewController];
    if (topViewController.navigationController) {
        [self.transitionDelegate setToFrame:topViewController.navigationController.view.frame];
        [topViewController.navigationController presentViewController:nav animated:YES completion:nil];
    } else {
        [self.transitionDelegate setToFrame:topViewController.view.frame];
        [topViewController presentViewController:nav animated:YES completion:nil];
    }
    [ACCTracker() trackEvent:@"enter_music_detail"
                       params:@{
                           @"enter_from" : @"change_music_page",
                           @"music_id" : music.musicID,
                           @"category_name" : categoryName,
                           @"category_Id" : categoryId ?: @"",
                           @"enter_method" : @"click_button",
                           @"process_id" : processID,
                       }
              needStagingFlag:YES];
}

- (void)p_collectionBtnClickedWithAudio:(id<ACCMusicModelProtocol>)audio
                          tableViewCell:(UITableViewCell *)cell
                               withDict:(NSDictionary *)dict
                       needRefreshTable:(BOOL)needRefreshTable {
    if (!audio) {
        return;
    }
    audio.collectStat = @(1 - audio.collectStat.integerValue);
    AWEStudioMusicCollectionType type = audio.collectStat.integerValue ? AWEStudioMusicCollectionTypeCollection : AWEStudioMusicCollectionTypeCancelCollection;
    if (dict) {
        NSString *collectEvent = @"favourite_song";
        if (type == AWEStudioMusicCollectionTypeCancelCollection) {
            collectEvent = @"cancel_favourite_song";
        }
        [ACCTracker() trackEvent:collectEvent params:[NSMutableDictionary dictionaryWithDictionary:dict]];
    }
    [ACCVideoMusic() requestCollectingMusicWithID:audio.musicID collect:audio.collectStat.integerValue completion:^(BOOL success, NSString * _Nullable message, NSError * _Nullable error) {
        if (success) {
            SAFECALL_MESSAGE(ACCMusicCollectMessage, @selector(didToggleMusicCollectStateWithMusicId:collect:sender:), didToggleMusicCollectStateWithMusicId:audio.musicID collect:type == AWEStudioMusicCollectionTypeCollection sender:self);
            if (message.length) {
                [ACCToast() show:message];
            } else {
                NSString *hintNamed = (type == AWEStudioMusicCollectionTypeCancelCollection ? ACCLocalizedString(@"com_mig_remove_from_favorites_d5lhe7", @"取消收藏") : @"added_to_favorite");
                [ACCToast() show:hintNamed];
            }
            if (needRefreshTable) {
                [self p_refreshDataWithAnimation:YES];
            }
        } else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                audio.collectStat = @(1 - audio.collectStat.integerValue);
                NSString *hintNamed = (type == AWEStudioMusicCollectionTypeCancelCollection ? ACCLocalizedString(@"com_mig_couldnt_connect_to_the_internet_try_again_later", @"网络不给力，取消收藏失败") : ACCLocalizedString(@"com_mig_couldnt_connect_to_the_internet_try_again_later_w6cpxj", @"网络不给力，收藏音乐失败"));
                [ACCToast() show:hintNamed];
            });
            if (error) {
                AWELogToolError(AWELogToolTagMusic, @"%s %@", __PRETTY_FUNCTION__, error);
            }
        }
    }];
}

- (AWEMusicCollectionData *)getFirstDataOfSection:(NSInteger)section
{
    if (!self.dataList.count) return nil;
    NSArray *arr = self.dataList[section];
    if (![arr isKindOfClass:[NSArray class]]) return nil;
    if (!arr.count) return nil;
    if (![arr[0] isKindOfClass:AWEMusicCollectionData.class]) return nil;
    return arr[0];
}

- (void)p_stopCurrentSelectedViewIfNeeded
{
    if (self.selectedMusic) {
        [self.currentSelectedMusicView stop];
    }
}

#pragma mark - Status Bar

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden
{
    return ![UIDevice acc_isIPhoneX];
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationSlide;
}

- (void)configForCallBack
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleForUseMusicOnVideo:) name:@"AWEUseThisMusicOnVideoNotification" object:nil];
}

- (void)handleForUseMusicOnVideo:(NSNotification *)notification
{
    self.useMusicLoadingView = [ACCLoading() showLoadingAndDisableUserInteractionOnView:[UIApplication sharedApplication].keyWindow];
    id<ACCMusicModelProtocol> applyMusic = [notification object];
    if ([applyMusic isOffLine]) {
        [ACCToast() show:applyMusic.offlineDesc];
        return;
    }
    @weakify(self);
    [ACCVideoMusic() fetchLocalURLForMusic:applyMusic
                              withProgress:nil
                                completion:^(NSURL *localURL, NSError *error) {
        @strongify(self);
        [self.useMusicLoadingView removeFromSuperview];
        if (error) {
            [ACCToast() showNetWeak];
        } else {
            [self p_handleForUseMusicOnVideo:applyMusic withError:error];
        }
    }];
}

- (void)p_handleForUseMusicOnVideo:(id<ACCMusicModelProtocol>)audio withError:(NSError *)error
{
    if ([audio isOffLine]) {
        [ACCToast() show:audio.offlineDesc];
        return;
    }
    [self.audioPlayer pause];
    self.playingMusic = nil;
    self.playingMusicIndexPath = nil;
    self.collectionPlayingMusicRow = NSNotFound;
    self.collectionPlayingCategory = nil;
    [self didPickAudio:audio fromClip:NO error:error];
}

#pragma mark - Music Clip

- (void)p_showMusicClipViewWithMusic:(id<ACCMusicModelProtocol>)musicModel
{
    if (!musicModel.loaclAssetUrl) {
        musicModel.loaclAssetUrl = musicModel.originLocalAssetUrl;
    }
    if (!musicModel.loaclAssetUrl) {
        return;
    }
    self.clipManager.audioClipCommonTrackDic = self.clipTrackInfo;
    self.fromSelectedMusicClip = NO;
    [self pause];
    self.clipManager.useSuggestInitial = NO;
    self.clipManager.usedForMusicSearch = NO;
    [self.clipManager addAudioCLipViewForViewController:[ACCResponder topViewController]];
    [self.clipManager configPlayerWithMusic:musicModel];
    self.clipManager.shouldAccommodateVideoDurationToMusicDuration = self.shouldAccommodateVideoDurationToMusicDuration;
    self.clipManager.maximumMusicDurationToAccommodate = self.maximumMusicDurationToAccommodate;
    AVAsset *asset = [AVURLAsset assetWithURL:musicModel.loaclAssetUrl ?: [NSURL URLWithString:@""]];
    [self.clipManager updateAudioBarWithURL:musicModel.loaclAssetUrl
                              totalDuration:musicModel.auditionDuration.floatValue ?: CMTimeGetSeconds(asset.duration)
                              startLocation:0
                 exsitingVideoTotalDuration:self.exsitingVideoDuration
                            enableMusicLoop:self.enableMusicLoop];
    [self.clipManager showMusicClipView];
    ACCBLOCK_INVOKE(self.setForbidSimultaneousScrollViewPanGesture, YES);
    
    NSMutableDictionary *trackInfo = [self.clipTrackInfo mutableCopy];
    trackInfo[@"can_music_loop"] = [self.clipManager shouldShowMusicLoopComponent] ? @"1" : @"0";
    [ACCTracker() trackEvent:@"edit_music" params:[trackInfo copy]];
}

@end
