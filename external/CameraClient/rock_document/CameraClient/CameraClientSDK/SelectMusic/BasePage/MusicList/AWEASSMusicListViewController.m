//
//  AWEASSMusicListViewController.m
//  AWEStudio
//
//  Created by 李彦松 on 2018/9/11.
//  Copyright © 2018年 bytedance. All rights reserved.
//


#import "AWEASSMusicListViewController.h"
#import "AWEMusicNoLyricTableViewCell.h"
#import "AWEMusicCollectionData.h"
#import "AWESingleMusicTableViewCell.h"
#import "AWESingleKaraokeMusicTableViewCell.h"
#import "ACCVideoMusicProtocol.h"
#import "ACCMusicTransModelProtocol.h"
#import "AWESingleMusicView.h"
#import "ACCSelectMusicViewControllerProtocol.h"
#import "ACCMusicViewBuilderProtocol.h"
#import "ACCSearchServiceProtocol.h"
#import "ACCSingleMusicRecommenVideosTableViewCellProtocol.h"
#import "ACCASSMusicListViewControllerProtocol.h"
#import "ACCVideoMusicProtocol.h"
#import "ACCUserModelProtocolD.h"
#import "ACCMusicModelProtocolD.h"

#import <CreativeKit/ACCProtocolContainer.h>
#import <CameraClient/UIScrollView+ACCInfiniteScrolling.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/ACCResponder.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <CreationKitArch/ACCModelFactoryServiceProtocol.h>
#import <CameraClient/ACCVideoMusicProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CameraClient/ACCVideoMusicProtocol.h>
#import <CameraClient/AWERepoMusicSearchModel.h>

#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitInfra/ACCLoadMoreFooter.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCRouterProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <KVOController/KVOController.h>

#import <Masonry/View+MASAdditions.h>
#import <HTSServiceKit/HTSMessageCenter.h>
#import "ACCRefreshHeader.h"

NSArray<AWEMusicCollectionData *> *music_to_collection_data(NSArray<id<AWEStudioMusicModelProtocol>> * musicList)
{
    NSMutableArray *transformedDataList =
            [NSMutableArray arrayWithCapacity:musicList.count];
    for (id<ACCMusicModelProtocol> music in musicList) {
        AWEMusicCollectionData *data =
                [[AWEMusicCollectionData alloc] initWithMusicModel:music withType:AWEMusicCollectionDataTypeMusic];
        [transformedDataList acc_addObject:data];
    }
    return [transformedDataList copy];
}

@interface AWEASSMusicListViewController () <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, ACCPropRecommendMusicProtocol, ACCSingleMusicRecommenVideosTableViewCellDelegate>

@property (nonatomic, strong) id<ACCAudioPlayerProtocol> audioPlayer;
@property (nonatomic, strong) id<ACCAudioURLPlayerProtocol> URLAudioPlayer;

//视频播放状态保持相关上下文
@property (nonatomic, strong) UIViewController* playerContainer;
@property (nonatomic, assign) NSInteger playingVideoRow;
@property (nonatomic, assign) NSInteger playingVideoColumn;
@property (nonatomic, strong) NSMutableDictionary *videoCellOffsetDict;
@property (nonatomic, assign) BOOL isGotoDetailPage; //解决视频去往内流页同步播放的问题，有点恶心，但是来不及了，先这样吧
@property (nonatomic, strong) UIViewController* lastPlayedContainer;
@property (nonatomic, assign) NSInteger lastPlayedVideoRow;
@property (nonatomic, assign) NSInteger lastPlayedVideoColumn;

@property (nonatomic, strong) UIView<ACCLoadingViewProtocol> *loadingView;
@property (nonatomic, strong) UITableViewCell<ACCSingleMusicRecommenVideosTableViewCellProtocol> *playingVideoCell;
@property (nonatomic, strong) id<ACCMusicModelProtocol> playingMusic;
@property (nonatomic, strong) id<ACCMusicModelProtocol> editingMusic;
@property (nonatomic, assign) NSInteger editingRank;
@property (nonatomic, strong) NSIndexPath *playingMusicIndexPath;
@property (nonatomic, assign) BOOL isDownloadingMusic;

@property (nonatomic, strong) id<ACCTransitionViewControllerProtocol> transitionDelegate;
@property (nonatomic, assign) ACCAVPlayerPlayStatus cellPlayStatus;

@property (nonatomic, assign) CFTimeInterval startTime;
@property (nonatomic, strong) UIView *commerceLicenseHint;

@property (nonatomic, assign) BOOL shouldClearHorizontalContentOffset;

@end

@implementation AWEASSMusicListViewController

@synthesize completion = _completion, enableClipBlock = _enableClipBlock, willClipBlock = _willClipBlock;

- (void)dealloc
{
    [_loadingView dismiss];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _audioPlayer = IESAutoInline(ACCBaseServiceProvider(), ACCAudioPlayerProtocol);
        _audioPlayer.delegate = self;
        _URLAudioPlayer = IESAutoInline(ACCBaseContainer(), ACCAudioURLPlayerProtocol);
        [self observeURLPlayerState];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleAppWillResignActiveNotification)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(collectMusicWithParams:)
                                                     name:[IESAutoInline(ACCBaseServiceProvider(), ACCMusicViewBuilderProtocol) searchLynxCollectMusicNotification]
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(useMusicWithParams:)
                                                     name:[IESAutoInline(ACCBaseServiceProvider(), ACCMusicViewBuilderProtocol) searchLynxShootNotification]
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onReceiveLynxAudioPlayNotification)
                                                     name:[IESAutoInline(ACCBaseServiceProvider(), ACCMusicViewBuilderProtocol) searchLynxAudioPlayNotification]
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(editMusicWithParams:)
                                                     name:[IESAutoInline(ACCBaseServiceProvider(), ACCMusicViewBuilderProtocol) searchLynxEditMusicNotification]
                                                   object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self resetPlayingVideoInfon];
    [self p_setupUI];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lynxAnimationStartWithNotification:) name:@"lynx_view_layout_animation_start" object:nil];
}

// implementation by AWEASSMusicListViewController+AWEStudio
- (void)lynxAnimationStartWithNotification:(NSNotification *)notification {}

- (void)observeURLPlayerState
{
    @weakify(self);
    [self.KVOController observe:self.URLAudioPlayer keyPath:FBKVOKeyPath(_URLAudioPlayer.playerState) options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        NSString *playURL = ACCGetProtocol(self.playingMusic, ACCMusicModelProtocolD).karaoke.originalSoundAudio.playURL.originURLList.firstObject ?: @"";
        if ([self.URLAudioPlayer.currentPlayURL isEqualToString:playURL]) {
            ACCAVPlayerPlayStatus state = [change acc_integerValueForKey:NSKeyValueChangeNewKey];
            if (state == ACCAVPlayerPlayStatusReachEnd) {
                [self pauseAudio];
                return;
            }
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.playingMusicIndexPath];
            if ([cell isKindOfClass:[AWESingleMusicTableViewCell class]]) {
                [[(AWESingleMusicTableViewCell *)cell musicView] configWithPlayerStatus:state];
            }
            self.cellPlayStatus = state;
        }
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.isGotoDetailPage) {
        [self pauseAudio];
    } else {
        [self pause];
    }
    [IESAutoInline(ACCBaseServiceProvider(), ACCMusicViewBuilderProtocol) tableViewCellsTriggerDisappear:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [IESAutoInline(ACCBaseServiceProvider(), ACCMusicViewBuilderProtocol) tableViewCellsTriggerAppear:self.tableView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.isGotoDetailPage) {
        [self pauseVideo];
        self.isGotoDetailPage = NO;
    }
}

- (void)setDataList:(NSArray<AWEMusicCollectionData *> *)dataList {
    _dataList = dataList;
    if (self.tableView.acc_infiniteScrollingView) {
        [self.tableView reloadData];
        return;
    }
    [UIView transitionWithView:self.tableView
                      duration:0.3f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void) {
                        [self.tableView reloadData];
                    } completion:NULL];
}

- (void)setDataListandPartialUpdateRows:(NSArray<AWEMusicCollectionData *> *)dataList {
    NSInteger dataCount = [_dataList count];
    _dataList = dataList;
    NSInteger updatedDataCount = [_dataList count];
    if (self.tableView.acc_infiniteScrollingView) {
        NSMutableArray<NSIndexPath *> *indices = [NSMutableArray array];
        for(NSInteger i = dataCount; i < updatedDataCount; i++) {
            [indices addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        [UIView performWithoutAnimation:^{
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:indices withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView endUpdates];
        }];
        return;
    }
    [UIView transitionWithView:self.tableView
                      duration:0.3f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void) {
                        [self.tableView reloadData];
                    } completion:NULL];
}

#pragma mark - public method

- (void)pause {
    [self pauseAudio];
    [self pauseVideo];
}

- (void)recordContentOffset:(CGPoint)point byIndex:(NSInteger)index {
    NSString *key = [NSString stringWithFormat:@"%ld",(long)index];
    if (point.x == 0) {
        if ([self.videoCellOffsetDict valueForKey:key]) {
            [self.videoCellOffsetDict removeObjectForKey:key];
        }
        return;
    }
    NSNumber *offsetX = [NSNumber numberWithFloat:point.x];
    [self.videoCellOffsetDict setValue:offsetX forKey:key];
}

- (CGPoint)getContentOffsetByIndex:(NSInteger)index {
    NSString *key = [NSString stringWithFormat:@"%ld",(long)index];
    NSNumber *offsetX = [self.videoCellOffsetDict valueForKey:key];
    if (!offsetX) {
        return CGPointZero;
    }
    return CGPointMake([offsetX floatValue], 0.0);
}

- (void)clearContentOffset{
    [self.tableView setContentOffset:CGPointZero animated:NO];
    [self.videoCellOffsetDict removeAllObjects];
    self.shouldClearHorizontalContentOffset = YES;
}


// 16.3.0 lynx音乐搜索结果调起剪辑面板上报埋点
- (void)lynxMusicSearchClipCanceled {
    [self trackCancelClipWithMusic:self.editingMusic rank:self.editingRank];
}

- (void)LynxMusicSearchClipConfirmed {
    [self trackConfirmClipWithMusic:self.editingMusic rank:self.editingRank];
}


    
- (void)configScrollViewHeader:(MJRefreshHeader *)header footer:(MJRefreshFooter *)footer infiniteScrollingAction:(dispatch_block_t)infiniteScrollingAction
{
    self.tableView.mj_header = header;
    self.tableView.mj_footer = footer;
    [self.tableView acc_addInfiniteScrollingWithActionHandler:infiniteScrollingAction];
}

#pragma mark - ACCRefreshableViewControllerProtocol

- (void)beginRefreshing
{
    [self.tableView.mj_header beginRefreshing];
}

- (void)endLoadingAndRefreshingWithMoreData:(BOOL)hasMore
{
    [self.tableView.acc_infiniteScrollingView stopAnimating];
    [self.tableView.mj_header endRefreshing];
    if (hasMore) {
        [self.tableView.mj_footer endRefreshing];
    } else {
        [self.tableView.mj_footer endRefreshingWithNoMoreData];
    }
}

- (void)reloadWithModelArray:(NSArray<id<AWEStudioMusicModelProtocol>> *)modelArray
{
    self.dataList = music_to_collection_data(modelArray);
}

- (void)appendWithModelArray:(NSArray<id<AWEStudioMusicModelProtocol>> *)modelArray
{
    NSMutableArray<AWEMusicCollectionData *> *dataList = [self.dataList mutableCopy];
    [dataList addObjectsFromArray:music_to_collection_data(modelArray)];
    self.dataList = [dataList copy];
}

#pragma mark private

- (void)pauseAudio
{
    if (self.listType == AWEASSMusicListTypeKaraoke) {
        [self.URLAudioPlayer playWithURL:nil startTime:0 playableDuration:0];
        id<ACCMusicModelProtocol> music = self.playingMusic;
        if (!ACCGetProtocol(music, ACCMusicModelProtocolD).karaoke) {
            return;
        }
    } else {
        [self.audioPlayer pause];
    }
    if (self.playingMusicIndexPath) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.playingMusicIndexPath];
        if ([cell isKindOfClass:[AWESingleMusicTableViewCell class]]) {
            acc_dispatch_main_async_safe(^{
                [[(AWESingleMusicTableViewCell *)cell musicView] configWithPlayerStatus:ACCAVPlayerPlayStatusPause];
            });
        }
    }
    self.playingMusic = nil;
    self.playingMusicIndexPath = nil;
    [ACCSearchService() searchHybridAudioPause];
}

- (void)playAudio
{
    if (self.playingMusic == nil) {
        return;
    }
    if (self.listType == AWEASSMusicListTypeKaraoke) {
        id<ACCMusicModelProtocol> music = self.playingMusic;
        if (!music) {
            return;
        }
        id<ACCMusicKaraokeAudioModelProtocol> karaokeAudio = ACCGetProtocol(music, ACCMusicModelProtocolD).karaoke.originalSoundAudio;
        NSString *playURL = karaokeAudio.playURL.originURLList.firstObject;
        ACCLog(@"karaokePlay URL %@ player:%p", playURL, self.URLAudioPlayer);
        if (karaokeAudio == nil || ACC_isEmptyString(playURL)) {
            [ACCToast() show:@"资源加载失败，请重试"];
            [self pauseAudio];
            return;
        }
        NSTimeInterval startTime = karaokeAudio.playURLStart / 1000.0;
        NSTimeInterval playableDuration = ACCGetProtocol(self.playingMusic, ACCMusicModelProtocolD).karaokeAuditionDuration;
        [self.URLAudioPlayer playWithURL:playURL startTime:startTime playableDuration:playableDuration];
        NSMutableDictionary *params = [@{
            @"music_id" : music.musicID ? : @"",
            @"pop_music_id" : ACCGetProtocol(music, ACCMusicModelProtocolD).karaoke.karaokeID ?: @"",
            @"enter_method" : @"click_icon",
            @"music_duration" :  @((NSInteger)ACCGetProtocol(music, ACCMusicModelProtocolD).karaokeShootDuration)
        } mutableCopy];
        params[@"is_audo_play"] = @(0);
        params[@"creation_id"] = self.creationId;
        params[@"shoot_way"] = self.shootWay;
        params[@"enter_from"] = self.enterFrom;
        params[@"category_name"] = self.categoryName;
        [ACCTracker() trackEvent:@"play_pop_music" params:params];
    } else {
        @weakify(self);
        [self.audioPlayer updateServiceWithMusicModel:self.playingMusic audioPlayerPlayingBlock:^{
            @strongify(self);
            [self pauseAudio];
        }];
        [self.audioPlayer play];
    }
}

- (void)toUseMusic:(id<ACCMusicModelProtocol> )audio
             error:(NSError *)error
    collectionData:(AWEMusicCollectionData *)data
              rank:(NSInteger)rank
        trackClick:(BOOL)trackClick
{
    if ([audio isOffLine]) {
        [ACCToast() show:audio.offlineDesc];
        return;
    }
    [self.audioPlayer pause];
    self.isDownloadingMusic = NO;
    self.playingMusic = nil;
    self.playingMusicIndexPath = nil;
    [self didPickAudio:audio error:error];
    ACCBLOCK_INVOKE(self.updatePublishModelCategoryIdBlock, nil);
    if (self.listType == AWEASSMusicListTypeMusicSticker) {
        audio.categoryId = nil;
        NSDictionary *params = @{@"enter_from" : @"lyricsticker_song_search",
                                 @"creation_Id" : self.creationId ? : @"",
                                 @"shoot_way" : self.shootWay ? : @"",
                                 @"search_keyword" : self.keyword ? : @"",
                                 @"music_name" : data.music.musicName ? : @"",
                                 @"music_id" : data.music.musicID ? : @"",
                                 @"after_search" : self.keyword ? @1 : @0,
        };
        [ACCTracker() trackEvent:@"add_lyricsticker_song"
                                         params:params
                               ];
    } else {
        audio.categoryId = self.categoryId;
        NSMutableDictionary *params = [@{
                                         @"enter_from" : [self enterFrom] ?: @"",
                                         @"music_id" : audio.musicID ?: @"",
                                         @"category_name" : [self p_getCategoryName:self.categoryName] ?: @"",
                                         @"category_id" : self.categoryId ?: @"",
                                         @"enter_method" : self.enterMethod ?: @"",
                                         @"previous_page" : self.previousPage ?: @"",
                                         @"order" : @(rank),
                                         @"add_type" : @"video",
                                         } mutableCopy];
        if (self.listType == AWEASSMusicListTypeSearch) {
            params[@"log_pb"] = self.logPb ?: @"";
            params[@"search_keyword"] = self.keyword ?: @"";
            params[@"creation_id"] = self.creationId ?: @"";
            params[@"search_result_id"] = self.repository.repoMusicSearch.searchResultId ?: @"";
            params[@"list_item_id"] = self.repository.repoMusicSearch.listItemId ?: @"";
            params[@"search_id"] = self.repository.repoMusicSearch.searchId ?: @"";
        }
        if (self.isCommerce) {
            params[@"is_commercial"] = @1;
        }
        [ACCTracker() trackEvent:@"add_music"
                           params:[params copy]];
        if (trackClick) {
            [ACCTracker() trackEvent:@"search_result_click" params:[self trackSearchEventParamWithMusicModel:audio buttonType:@"click_add_music" rank:rank]];
        }

    }
}

- (void)confirmUseMusic:(id<ACCMusicModelProtocol>)music
                   rank:(NSInteger)rank
             trackClick:(BOOL)trackClick
{
    if ([music isOffLine]) {
        [ACCToast() show:music.offlineDesc];
        return;
    }
    @weakify(self);
    [self.loadingView removeFromSuperview];
    self.loadingView = [ACCLoading() showLoadingAndDisableUserInteractionOnView:[UIApplication sharedApplication].keyWindow];
    AWEMusicCollectionData *data = nil;
    if (rank > -1 && rank < self.dataList.count) {
        data = self.dataList[rank];
    }
    [ACCVideoMusic() fetchLocalURLForMusic:music
                              withProgress:^(float progress) {}
                                completion:^(NSURL *localURL, NSError *error) {
                                    @strongify(self);
                                    [self.loadingView removeFromSuperview];
                                    if (error) {
                                        [ACCToast() showNetWeak];
                                    } else {
                                        music.loaclAssetUrl = localURL;
                                        [self toUseMusic:music error:error collectionData:data rank:rank trackClick:trackClick];
                                    }
                                }];
}

#pragma mark video

- (void)resetPlayingVideoInfon {
    self.playerContainer = nil;
    self.lastPlayedContainer = nil;
    self.playingVideoRow = -1;
    self.playingVideoColumn = -1;
}

- (void)pauseVideo {
    if (self.playerContainer) {
        if (self.playingVideoRow >= 0 && self.playingVideoRow < self.dataList.count) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.playingVideoRow inSection:0];
            UITableViewCell<ACCSingleMusicRecommenVideosTableViewCellProtocol> *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            if (cell && [cell isKindOfClass:[IESAutoInline(ACCBaseServiceProvider(), ACCASSMusicListViewControllerProtocol) studioSingleMusicRecommendVideosTableCellClass]]) {
                [cell stopVideoPlay];
            }
        }
        [self resetPlayingVideoInfon];
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.lastPlayedVideoRow inSection:0];
    UITableViewCell<ACCSingleMusicRecommenVideosTableViewCellProtocol> *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (cell && [cell isKindOfClass:[IESAutoInline(ACCBaseServiceProvider(), ACCASSMusicListViewControllerProtocol) studioSingleMusicRecommendVideosTableCellClass]]) {
        [cell clearVideoUseMusicButton];
    }
}

- (void)onReceiveLynxAudioPlayNotification {
    [self.audioPlayer pause];
    [self pauseVideo];
}

#pragma mark - Protocols

#pragma mark AWEAVPlayerWrapperDelegate
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
    if (self.audioPlayer.playingMusic && ![self.playingMusic.musicID isEqual:self.audioPlayer.playingMusic.musicID]) {
        return;
    }
    
    if (self.playingMusicIndexPath) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.playingMusicIndexPath];
        if ([cell isKindOfClass:[AWESingleMusicTableViewCell class]]) {
            AWEMusicCollectionData *data = self.dataList[self.playingMusicIndexPath.row];
            [[(AWESingleMusicTableViewCell *)cell musicView] configWithPlayerStatus:status];
            if (status == ACCAVPlayerPlayStatusPlaying) {
                NSMutableDictionary *params = [@{
                                                @"enter_from" : [self enterFrom] ?: @"",
                                                @"music_id" : data.music.musicID ?: @"",
                                                @"category_name" : [self p_getCategoryName:self.categoryName] ?: @"",
                                                @"category_id" : self.categoryId ?: @"",
                                                @"enter_method" : self.enterMethod ?: @"",
                                                @"previous_page" : self.previousPage ?: @"",
                                                @"order" : @(self.playingMusicIndexPath.row),
                                                @"creation_id" : self.creationId ?: @"",
                                                } mutableCopy];
                if (self.listType == AWEASSMusicListTypeSearch) {
                    params[@"log_pb"] = self.logPb ?: @"";
                    params[@"search_keyword"] = self.keyword ?: @"";
                }
                [ACCTracker() trackEvent:@"play_music"
                                                 params:params
                                       ];
                //tag召回埋点
                id<ACCMusicModelProtocol> musicModel = self.playingMusic;
                [ACCTracker() trackEvent:@"search_result_click"
                                  params:[self trackSearchEventParamWithMusicModel:musicModel buttonType:@"click_play_music" rank:self.playingMusicIndexPath.row]
                                       ];
            }
        }
    }
    
    if (status == ACCAVPlayerPlayStatusPlaying) {
        self.startTime = CACurrentMediaTime();
    }
    
    if (status == ACCAVPlayerPlayStatusPause &&  !ACC_FLOAT_EQUAL_ZERO(self.startTime)) {
        NSInteger playTime = (CACurrentMediaTime() - self.startTime) * 1000;
        NSInteger musicDuration = [self.playingMusic.duration floatValue] * 1000;
        self.startTime = 0;
        [ACCTracker() trackEvent:@"music_play_time" params:@{
            @"duration": @(musicDuration),
            @"stay_time": @(playTime),
            @"time": @(musicDuration),
            @"category_name": @"my_fm",
            @"enter_from": @"search_music",
            @"music_id": self.playingMusic.musicID ?: @"",
            @"previous_page": self.previousPage ?: @"",
            @"creation_id": self.creationId ?: @"",
            @"enter_method": self.enterMethod ?: @"",
            @"search_keyword": self.keyword ?: @"",
            @"order": @(self.playingMusicIndexPath.row),
            @"log_pb": self.logPb ?: @{},
        }];
    }
    
    if (status == ACCAVPlayerPlayStatusFail) {
        [ACCToast() showNetWeak];
    }
    
    if ((status == ACCAVPlayerPlayStatusPause && [UIApplication sharedApplication].applicationState != UIApplicationStateActive) ||
        status == ACCAVPlayerPlayStatusReachEnd ||
        status == ACCAVPlayerPlayStatusFail) {
        self.playingMusic = nil;
    }
    self.cellPlayStatus = status;
}

- (void)handleAppWillResignActiveNotification
{
    if (self.cellPlayStatus == ACCAVPlayerPlayStatusPause) {
        self.isDownloadingMusic = NO;
        self.playingMusic = nil;
        self.playingMusicIndexPath = nil;
    }
    [self pause];
}

#pragma mark - ACCSingleMusicRecommenVideosTableViewCellDelegate

- (void)videoHasBeingPlayed:(UIViewController *)playerContainer withRow:(NSInteger)row column:(NSInteger)column {
    self.playerContainer = playerContainer;
    self.playingVideoRow = row;
    self.playingVideoColumn = column;
    self.lastPlayedContainer = playerContainer;
    self.lastPlayedVideoRow = row;
    self.lastPlayedVideoColumn = column;
    [self pauseAudio];
    
    if (!self.isGotoDetailPage) {
        NSMutableDictionary *params = [self getRecommendCardMusicTrackParamsByRow:row column:column];
        params[@"aladdin_button_type"] = @"click_play_video";
        params[@"list_result_type"] = @"video";
        [ACCTracker() trackEvent:@"search_result_click" params:params];
    }
    
}

- (void)videoHasBeingPaused:(UIViewController *)playerContainer withRow:(NSInteger)row column:(NSInteger)column {
    if (self.playerContainer && self.playingVideoRow == row && self.playingVideoColumn == column) {
        [self resetPlayingVideoInfon];
    }
    NSMutableDictionary *params = [self getRecommendCardMusicTrackParamsByRow:row column:column];
    params[@"aladdin_button_type"] = @"click_pause_video";
    params[@"list_result_type"] = @"video";
    [ACCTracker() trackEvent:@"search_result_click" params:params];
}

- (void)videoWillShow:(id<ACCAwemeModelProtocol>)awemeModel withRow:(NSInteger)row column:(NSInteger)column {

    NSMutableDictionary *params = [self getRecommendCardMusicTrackParamsByRow:row column:column];
    params[@"list_result_type"] = @"video";
    params[@"aladdin_rank"] = @(column);
    params[@"list_item_id"] = awemeModel.itemID ?: @"";
    [ACCTracker() trackEvent:@"search_result_show" params:params];
}

- (void)useMusic:(id<ACCMusicModelProtocol>)musicModel
             row:(NSInteger)row
          column:(NSInteger)column
{
    [self confirmUseMusic:musicModel rank:row trackClick:NO];
    NSMutableDictionary *params = [self getRecommendCardMusicTrackParamsByRow:row column:column];
    params[@"aladdin_button_type"] = @"click_add_music";
    params[@"list_result_type"] = @"video";
    [ACCTracker() trackEvent:@"search_result_click" params:params];
    
    // 设置发布页所需的搜索参数
    self.repository.repoMusicSearch.searchMusicId = musicModel.musicID ?: @"";
    self.repository.repoMusicSearch.searchId = params[@"search_id"] ?: @"";
    self.repository.repoMusicSearch.searchResultId = params[@"search_result_id"] ?: @"";
    self.repository.repoMusicSearch.listItemId = params[@"list_item_id"] ?: @"";
    self.repository.repoMusicSearch.tokenType = params[@"token_type"] ?: @"";
}

- (void)gotoDetailPageWithAwemeModel:(id<ACCAwemeModelProtocol>)awemeModel row:(NSInteger)row column:(NSInteger)column {
    self.isGotoDetailPage = YES;
    
    
    NSMutableDictionary *trackParams = [self getRecommendCardSearchTrackParamsWithIndex:row];
    
    //search_result_click
    NSMutableDictionary *clickParams = [NSMutableDictionary dictionaryWithDictionary:trackParams];
    clickParams[@"list_item_id"] = awemeModel.itemID ?: @"";
    clickParams[@"list_result_type"] = @"video";
    clickParams[@"aladdin_rank"] = @(column);
    clickParams[@"aladdin_button_type"] = @"click_video";
    [ACCTracker() trackEvent:@"search_result_click"
                      params:clickParams];
    
    //feed_enter
    NSMutableDictionary *enterParams = [NSMutableDictionary dictionaryWithDictionary:trackParams];
    enterParams[@"list_item_id"] = awemeModel.itemID ?: @"";
    clickParams[@"group_id"] = awemeModel.itemID ?: @"";
    clickParams[@"is_fullscreen"] = @(1);
    [ACCTracker() trackEvent:@"feed_enter"
                      params:clickParams];
    
}

#pragma mark - tableview delegate datasource

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([self.headerDataSource respondsToSelector:@selector(tableView:viewForHeaderInSection:)]) {
        return [self.headerDataSource tableView:tableView viewForHeaderInSection:section];
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([self.headerDataSource respondsToSelector:@selector(tableView:heightForHeaderInSection:)]) {
        return [self.headerDataSource tableView:tableView heightForHeaderInSection:section];
    }
    return 0.001; // @yinshenmeng
}

//常规音乐卡片
- (UITableViewCell *)tableView:(UITableView *)tableView musicCellForRowAtIndexPath:(NSIndexPath *)indexPath collectionData:(AWEMusicCollectionData *)data {
    
    BOOL hasLyric = data.music.lyricUrl && data.music.lyricUrl.length > 0;
    if (self.toShowNoLyricStyle && !hasLyric) {
        AWEMusicNoLyricTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([AWEMusicNoLyricTableViewCell class])];
        [cell configWithMusicModel:data.music];
        return cell;
    }
    AWESingleMusicTableViewCell *cell = nil;
    if (self.listType == AWEASSMusicListTypeKaraoke) {
        cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([AWESingleKaraokeMusicTableViewCell class]) forIndexPath:indexPath];
        cell.confirmBlock = self.completion;
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([AWESingleMusicTableViewCell class]) forIndexPath:indexPath];
        @weakify(self);
        cell.confirmBlock = ^(id<ACCMusicModelProtocol> audio, NSError *error) {
            @strongify(self);
            [self toUseMusic:audio error:error collectionData:data rank:indexPath.row trackClick:YES];
        };
        cell.clipBlock = ^(id<ACCMusicModelProtocol> _Nullable audio, NSError * _Nullable error) {
            @strongify(self);
            if ([audio isOffLine]) {
                [ACCToast() show:audio.offlineDesc];
                return;
            }
            if (error) {
                ACCBLOCK_INVOKE(self.willClipBlock, nil, error);
                return;
            }
            [self.audioPlayer pause];
            self.isDownloadingMusic = NO;
            self.playingMusic = nil;
            self.playingMusicIndexPath = nil;
            ACCBLOCK_INVOKE(self.willClipBlock, audio, nil);
        };
        @weakify(cell);
        cell.favouriteBlock = ^(id<ACCMusicModelProtocol> audio) {
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
            // TODO(liyansong): Track info
            [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) requireLogin:^(BOOL success) {
                if (success) {
                    [self p_collectionBtnClickedWithAudio:audio cell:cell order:indexPath.row];
                } else {
                    // TODO(liyansong): check error case
                }
            } withTrackerInformation:@{@"enter_from" : [self enterFrom], @"enter_method" : self.enterMethod ?: @""}];
        };
        cell.moreButtonClicked = ^(id<ACCMusicModelProtocol> music) {
            @strongify(self);
            [self enterMusicDetailViewController:music];
        };
    }
    cell.showMore = [self shouldShowCellMoreButton];
    if (!self.disableCutMusic) {
        cell.showClipButton = YES;
    }
    cell.musicView.showLyricLabel = self.showLyricLabel;
    cell.enableClipBlock = self.enableClipBlock;
    cell.tapWhileLoadingBlock = ^{
        [ACCToast() show:ACCLocalizedString(@"com_mig_loading_24vqw0", @"正在加载中...")];
    };
    cell.musicView.isSearchMusic = self.isSearchMusic;
    [cell.musicView configWithMusicModel:data.music rank:self.showRank ? indexPath.row : NSNotFound];
    if (self.isDarkMode) {
        [cell.musicView switchToDarkBackgroundMode];
    }
    
    return cell;
}

//动态化卡片
- (UITableViewCell *)tableView:(UITableView *)tableView dynamicCellForRowAtIndexPath:(NSIndexPath *)indexPath collectionData:(AWEMusicCollectionData *)data {
    return [IESAutoInline(ACCBaseServiceProvider(), ACCMusicViewBuilderProtocol) cellForDymaicMusicCollectionCellWithData:data tableView:tableView delegate:self];
}

//视频推荐卡片
- (UITableViewCell *)tableView:(UITableView *)tableView recommendVideosCellForRowAtIndexPath:(NSIndexPath *)indexPath collectionData:(AWEMusicCollectionData *)data {
    if ((!data) || (!data.recommendModel)) {
        return nil;
    }
    self.shouldClearHorizontalContentOffset = NO;
    NSString *identifier = @"AWESingleMusicRecommenVideosTableViewCell";
    UITableViewCell<ACCSingleMusicRecommenVideosTableViewCellProtocol> *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [IESAutoInline(ACCBaseServiceProvider(), ACCASSMusicListViewControllerProtocol) initiaLStudioSingleMusicRecommenVideosTableViewCellWithReuseIdentifier:identifier];
        cell.delegate = (id)self;
        @weakify(self);
        //浮层关闭手势冲突解决
        cell.solveCloseGesture = ^(UIPanGestureRecognizer *panGesture) {
            @strongify(self);
            if (self.solveCloseGesture) {
                self.solveCloseGesture(panGesture);
            }
        };
        
    }
    cell.rank = indexPath.row;
    //logExtra & referString
    [self updateRecommenCellLogEtra:cell withModel:data.recommendModel];
    CGPoint offsetPoint = [self getContentOffsetByIndex:indexPath.row];
    if (self.playerContainer && self.playingVideoRow == indexPath.row) {
        [cell updateWithModel:data.recommendModel playerContainer:self.playerContainer index:self.playingVideoColumn offsetX:offsetPoint.x];
    } else {
        [cell updateWithModel:data.recommendModel offsetX:offsetPoint.x lastPlayedIndex:self.lastPlayedVideoColumn];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.showTopSeparatorLine = (indexPath.row != 0);
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if (indexPath.row < self.dataList.count) {
        AWEMusicCollectionData *data = self.dataList[indexPath.row];
        if (self.listType == AWEASSMusicListTypeKaraoke) {
            cell = [self tableView:tableView musicCellForRowAtIndexPath:indexPath collectionData:data];
        } else {
            switch (data.type) {
                case AWEMusicCollectionDataTypeMusic:
                {
                    cell = [self tableView:tableView musicCellForRowAtIndexPath:indexPath collectionData:data];
                }
                break;
                case AWEMusicCollectionDataTypeDynamic:
                {
                    cell = [self tableView:tableView dynamicCellForRowAtIndexPath:indexPath collectionData:data];
                }
                break;
                case AWEMusicCollectionDataTypeRecommendVideo:
                {
                    cell = [self tableView:tableView recommendVideosCellForRowAtIndexPath:indexPath collectionData:data];
                }
                break;
                default:
                    break;;
            }
        }
    }
    if (!cell) {
        cell = [[UITableViewCell alloc] init];
    }
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (self.isCommerce && self.dataList.count > 0) {
        return self.commerceLicenseHint;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (self.isCommerce && self.dataList.count > 0) {
        return 70;
    }
    return 0.001;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0.f;
    if (indexPath.row < self.dataList.count) {
        AWEMusicCollectionData *data = self.dataList[indexPath.row];
        switch (data.type) {
            case AWEMusicCollectionDataTypeMusic: {
                AWEMusicCollectionData *data = self.dataList[indexPath.row];
                if (self.showLyricLabel && data.music.shortLyric.length > 0) {
                    height = 116;
                } else {
                    height = 84;
                }
                break;
            }
            case AWEMusicCollectionDataTypeDynamic:
            {
                height = [IESAutoInline(ACCBaseServiceProvider(), ACCMusicViewBuilderProtocol) heightForDynamicMusicCollectionCellWithData:data];
            }
                break;
            case AWEMusicCollectionDataTypeRecommendVideo:
            {
                height = [IESAutoInline(ACCBaseServiceProvider(), ACCASSMusicListViewControllerProtocol) singleMusicRecommenVideosTableViewCellHeightWithModel:data.recommendModel isFirst:(indexPath.row == 0)];
            }
                break;
            default:
                break;
        }
    }
    return height;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
        willDisplayCell:(UITableViewCell *)cell
      forRowAtIndexPath:(NSIndexPath *)indexPath {
    AWEMusicCollectionData *data = self.dataList[indexPath.row];
    switch (data.type) {
        case AWEMusicCollectionDataTypeMusic:
        {
            if (![cell isKindOfClass:[AWESingleMusicTableViewCell class]]) {
                return;
            }
            AWESingleMusicTableViewCell *appearCell = (AWESingleMusicTableViewCell *)cell;
            NSMutableDictionary *params = [NSMutableDictionary dictionary];
            params[@"music_id"] = data.music.musicID ?: @"";
            params[@"enter_from"] = [self enterFrom] ?: @"";
            params[@"enter_method"] = self.enterMethod ?: @"";
            params[@"category_name"] = [self p_getCategoryName:self.categoryName] ?: @"";
            params[@"category_id"] = self.categoryId ?: @"";
            params[@"previous_page"] = self.previousPage ?: @"";
            params[@"order"] = @(indexPath.row);
            params[@"creation_id"] = self.creationId ?: @"";
            params[@"search_keyword"] = self.keyword ?: @"";
            params[@"log_pb"] = self.logPb ?: @{};
            params[@"shoot_way"] = self.shootWay;
            if (self.isCommerce) {
                params[@"is_commercial"] = @1;
            }
            [ACCTracker() trackEvent:@"show_music"
                               params:[params copy]];
            
            id<ACCMusicModelProtocol> musicModel = data.music;
            [ACCTracker() trackEvent:@"search_result_show"
                              params:[self trackSearchEventParamWithMusicModel:musicModel buttonType:nil rank:indexPath.row]];

            if (self.listType == AWEASSMusicListTypeKaraoke) {
                params[@"pop_music_id"] = ACCGetProtocol(data.music, ACCMusicModelProtocolD).karaoke.karaokeID;
                params[@"music_duration"] = @((NSInteger)ACCGetProtocol(data.music, ACCMusicModelProtocolD).karaokeShootDuration);
                [ACCTracker() trackEvent:@"show_pop_music" params:params];
            }
            if ([indexPath isEqual:self.playingMusicIndexPath]) {
                [appearCell.musicView configWithPlayerStatus:self.cellPlayStatus animated:NO];
            } else {
                [appearCell.musicView configWithPlayerStatus:ACCAVPlayerPlayStatusPause animated:NO];
            }
        }
            break;
        case AWEMusicCollectionDataTypeDynamic:
        {
            [IESAutoInline(ACCBaseServiceProvider(), ACCMusicViewBuilderProtocol) tableViewCellTriggerShow:cell];
        }
            break;
        case AWEMusicCollectionDataTypeRecommendVideo:
        {
            [self recommendExposureTrackWithIndex: indexPath.row];
        }
        default:
            break;
    }
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(nonnull UITableViewCell *)cell forRowAtIndexPath:(nonnull NSIndexPath *)unsafeIndexPath
{
    [IESAutoInline(ACCBaseServiceProvider(), ACCMusicViewBuilderProtocol) tableViewCellTriggerHide:cell];
    NSInteger index = unsafeIndexPath.row;
    if ([cell isKindOfClass:[IESAutoInline(ACCBaseServiceProvider(), ACCASSMusicListViewControllerProtocol) studioSingleMusicRecommendVideosTableCellClass]]) {
        id<ACCSingleMusicRecommenVideosTableViewCellProtocol> videoCell = (id<ACCSingleMusicRecommenVideosTableViewCellProtocol>)cell;
        if (!self.shouldClearHorizontalContentOffset) {
            [self recordContentOffset:[videoCell getListContentOffset] byIndex:index];
        }
        if (self.playerContainer && self.playingVideoRow == index) {
            [videoCell removePlayerContainer];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ( indexPath.row < self.dataList.count) {
        AWEMusicCollectionData *data = self.dataList[indexPath.row];
        !self.didSelectItem ?: self.didSelectItem(indexPath, data);
        switch (data.type) {
            case AWEMusicCollectionDataTypeMusic: {
                BOOL hasLyric = data.music.lyricUrl && data.music.lyricUrl.length > 0;
                if (self.toShowNoLyricStyle && !hasLyric) {
                    return;
                }
                AWESingleMusicTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                if (!self.playingMusic) {
                    self.playingMusicIndexPath = indexPath;
                    self.playingMusic = data.music;
                    [self pauseVideo];
                    [cell.musicView configWithPlayerStatus:ACCAVPlayerPlayStatusLoading];
                    self.cellPlayStatus = ACCAVPlayerPlayStatusLoading;
                } else if ([self.playingMusic isEqual:data.music]) {//选择相同音乐
                    [self pauseAudio];
                    self.isDownloadingMusic = NO;
                    [cell.musicView configWithPlayerStatus:ACCAVPlayerPlayStatusPause];
                    self.cellPlayStatus = ACCAVPlayerPlayStatusPause;
                    id<ACCMusicModelProtocol> musicModel = data.music;
                    [ACCTracker() trackEvent:@"search_result_click"
                                      params:[self trackSearchEventParamWithMusicModel:musicModel buttonType:@"click_pause_music" rank:indexPath.row]];
                    if (self.listType == AWEASSMusicListTypeKaraoke) {
                        NSMutableDictionary *params = [@{
                            @"music_id" : musicModel.musicID ? : @"",
                            @"pop_music_id" : ACCGetProtocol(musicModel, ACCMusicModelProtocolD).karaoke.karaokeID ?: @"",
                            @"enter_method" : @"click_icon",
                            @"music_duration" :  @((NSInteger)ACCGetProtocol(musicModel, ACCMusicModelProtocolD).karaokeShootDuration)
                        } mutableCopy];
                        params[@"creation_id"] = self.creationId;
                        params[@"shoot_way"] = self.shootWay;
                        params[@"enter_from"] = self.enterFrom;
                        params[@"category_name"] = self.categoryName;
                        [ACCTracker() trackEvent:@"pause_pop_music" params:params];
                    }
                } else {//切换音乐
                    [self pauseAudio];
                    [cell.musicView configWithPlayerStatus:ACCAVPlayerPlayStatusLoading];
                    self.cellPlayStatus = ACCAVPlayerPlayStatusLoading;
                    self.playingMusicIndexPath = indexPath;
                    self.playingMusic = data.music;
                }
                [self playAudio];
            }
                break;
            default:
                break;
        }
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    !self.didEndDragList ?: self.didEndDragList(scrollView);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    ACCBLOCK_INVOKE(self.didScrollBlock, scrollView);
}

#pragma mark - Private

- (void)trackConfirmClipWithMusic:(id<ACCMusicModelProtocol>)audio rank:(NSInteger)rank {
    [ACCTracker() trackEvent:@"search_result_click" params:[self trackSearchEventParamWithMusicModel:audio buttonType:@"click_add_music" rank:rank]];
    NSDictionary *params = @{@"search_id" : self.logPb[@"impr_id"] ?: @"",
                             @"log_pb" : self.logPb ?: @"",
                             @"impr_id" : self.logPb[@"impr_id"] ?: @"",
                             @"enter_from" : [self enterFrom] ? : @"",
                             @"music_id" : audio.musicID ? : @"",
                             @"order" : @(rank),
                             @"creation_id" : self.creationId ? : @"",
    };
    [ACCTracker() trackEvent:@"add_music" params:params];
}

- (void)trackCancelClipWithMusic:(id<ACCMusicModelProtocol>)audio rank:(NSInteger)rank {
    
    [ACCTracker() trackEvent:@"search_result_click" params:[self trackSearchEventParamWithMusicModel:audio buttonType:@"click_cancel_edit" rank:rank]];
}

- (BOOL)shouldShowCellMoreButton {
    return NO;
}

- (void)useMusicWithParams:(NSNotification *)noti
{
    if (![noti.object isKindOfClass:NSDictionary.class]) {
        return;
    }
    if (noti.object[@"music"]) {
        NSError *error;
        id<ACCMusicModelProtocol> musicModel = [MTLJSONAdapter modelOfClass:[IESAutoInline(ACCBaseServiceProvider(), ACCMusicTransModelProtocol) musicModelImplClass]
                                                               fromJSONDictionary:noti.object[@"music"]
                                                                            error:&error];
        if ([musicModel isOffLine]) {
            [ACCToast() show:musicModel.offlineDesc];
            return;
        }
        self.isDownloadingMusic = NO;
        self.playingMusic = nil;
        self.playingMusicIndexPath = nil;
        [self didPickAudio:musicModel error:nil];
        ACCBLOCK_INVOKE(self.updatePublishModelCategoryIdBlock, nil);
        if (error) {
            AWELogToolError(AWELogToolTagDraft, @"%s %@", __PRETTY_FUNCTION__, error);
        }
        
        // 设置发布页所需的搜索参数
        NSString *musicID = musicModel.musicID ?: @"";
        NSString *searchResultId = [noti.object[@"music_extra"] isKindOfClass:NSDictionary.class] ? (noti.object[@"music_extra"][@"search_result_id"] ?: musicID) : musicID;
        NSString *tokenType = [noti.object[@"music_extra"] isKindOfClass:NSDictionary.class] ? (noti.object[@"music_extra"][@"token_type"] ?: @"music") : @"music";
        self.repository.repoMusicSearch.searchMusicId = musicID;
        self.repository.repoMusicSearch.searchId = self.logPb[@"impr_id"] ?: @"";
        self.repository.repoMusicSearch.searchResultId = searchResultId;
        self.repository.repoMusicSearch.listItemId = musicID;
        self.repository.repoMusicSearch.tokenType = tokenType ?: @"";
    }
}

- (void)collectMusicWithParams:(NSNotification *)noti
{
    if (![noti.object isKindOfClass:NSDictionary.class]) {
        return;
    }

    NSString * musicID = noti.object[@"music_id"];
    NSInteger type = [noti.object[@"status"] integerValue];
    
    SAFECALL_MESSAGE(ACCMusicCollectMessage, @selector(didToggleMusicCollectStateWithMusicId:collect:sender:), didToggleMusicCollectStateWithMusicId:musicID collect:type == AWEStudioMusicCollectionTypeCollection sender:self);
}

- (void)editMusicWithParams:(NSNotification *)noti
{
    if (![noti.object isKindOfClass:NSDictionary.class]) {
        return;
    }
    NSNumber *rank = noti.object[@"rank"];
    NSError *error;
    if (noti.object[@"music"]) {
        id<ACCMusicModelProtocol> musicModel = [MTLJSONAdapter modelOfClass:[IESAutoInline(ACCBaseServiceProvider(), ACCMusicTransModelProtocol) musicModelImplClass]
                                                               fromJSONDictionary:noti.object[@"music"]
                                                                    error:&error];
        self.editingRank = [rank integerValue];
        [self.loadingView removeFromSuperview];
        self.loadingView = [ACCLoading() showLoadingAndDisableUserInteractionOnView:[UIApplication sharedApplication].keyWindow];
        [ACCVideoMusic() fetchLocalURLForMusic:musicModel
                                  withProgress:^(float progress) {}
                                    completion:^(NSURL *localURL, NSError *error) {
            [self.loadingView removeFromSuperview];
            if (error) {
                [ACCToast() showNetWeak];
            } else {
                musicModel.loaclAssetUrl = localURL;
                self.editingMusic = musicModel;
                [self editMusicWithAudio:self.editingMusic];
            }
        }];
    }
}

- (void)editMusicWithAudio:(id<ACCMusicModelProtocol> _Nullable)audio
{
    if ([audio isOffLine]) {
        [ACCToast() show:audio.offlineDesc];
        return;
    }
    [self.audioPlayer pause];
    self.isDownloadingMusic = NO;
    self.playingMusic = nil;
    self.playingMusicIndexPath = nil;
    ACCBLOCK_INVOKE(self.willClipBlock, audio, nil);
}

- (void)p_collectionBtnClickedWithAudio:(id<ACCMusicModelProtocol>)audio
                                   cell:(AWESingleMusicTableViewCell *)cell
                                  order:(NSInteger)row
{
    if (!audio) {
        return;
    }
    audio.collectStat = @(1 - audio.collectStat.integerValue);//update will collectStat
    AWEStudioMusicCollectionType actionType = audio.collectStat.integerValue ? AWEStudioMusicCollectionTypeCollection : AWEStudioMusicCollectionTypeCancelCollection;
    
    [self p_trackCollectMusicWithMusic:audio
                                   row:row
                            actionType:actionType];
    [self p_collectMusicWithMusic:audio actionType:actionType];
}

- (void)p_trackCollectMusicWithMusic:(id<ACCMusicModelProtocol>)music
                                 row:(NSInteger)row
                          actionType:(AWEStudioMusicCollectionType)actionType
{
    if (self.listType == AWEASSMusicListTypeMusicSticker) {
        NSDictionary *lyricParams = @{@"enter_from" : @"lyricsticker_song_search",
                                 @"creation_Id" : self.creationId ? : @"",
                                 @"shoot_way" : self.shootWay ? : @"",
                                 @"search_keyword" : self.keyword ? : @"",
                                 @"music_name" : music.musicName ? : @"",
                                 @"music_id" : music.musicID ? : @"",
                                 @"after_search" : self.keyword ? @1 : @0,
        };
        [ACCTracker() trackEvent:@"favorite_lyricsticker_song" params:lyricParams];
    }
    
    NSMutableDictionary *params = [@{@"enter_from" : [self enterFrom] ?: @"",
                                     @"music_id" : music.musicID ?: @"",
                                     @"category_name" : self.categoryName ?: @"",
                                     @"category_id" : self.categoryId ?: @"",
                                     @"enter_method" : self.enterMethod ?: @"",
                                     @"previous_page" : self.previousPage ?: @"",
                                     @"order" : @(row)} mutableCopy];
    if (self.listType == AWEASSMusicListTypeSearch) {
        params[@"log_pb"] = self.logPb ?: @"";
        params[@"search_keyword"] = self.keyword ?: @"";
        params[@"creation_id"] = self.creationId ?: @"";
    }
    if (self.listType == AWEASSMusicListTypeMusicSticker) {
        params[@"enter_from"] = @"change_music_page";
    }
    if (self.isCommerce) {
        params[@"is_commercial"] = @1;
    }
    NSString *collectEvent = @"favourite_song";
    NSString *btnType = @"click_favourite_button";
    if (actionType == AWEStudioMusicCollectionTypeCancelCollection) {
        collectEvent = @"cancel_favourite_song";
        btnType = @"click_cancel_favourite";
    }
    [ACCTracker() trackEvent:collectEvent params:[params copy]];
    [ACCTracker() trackEvent:@"search_result_click"
                      params:[self trackSearchEventParamWithMusicModel:music
                                                            buttonType:btnType
                                                                  rank:row]];
}

- (void)p_collectMusicWithMusic:(id<ACCMusicModelProtocol>)music actionType:(AWEStudioMusicCollectionType)actionType
{
    @weakify(self);
    [ACCVideoMusic() requestCollectingMusicWithID:music.musicID collect:music.collectStat.integerValue completion:^(BOOL success, NSString * _Nullable message, NSError * _Nullable error) {
        @strongify(self);
        if (success) {
            SAFECALL_MESSAGE(ACCMusicCollectMessage, @selector(didToggleMusicCollectStateWithMusicId:collect:sender:), didToggleMusicCollectStateWithMusicId:music.musicID collect:actionType == AWEStudioMusicCollectionTypeCollection sender:self);
            if (message.length) {
                //收藏
                [ACCToast() show:message];
            } else {
                NSString *hintNamed = (actionType == AWEStudioMusicCollectionTypeCancelCollection ? ACCLocalizedString(@"com_mig_remove_from_favorites_d5lhe7", @"取消收藏") : @"added_to_favorite");
                [ACCToast() show:hintNamed];
            }
        } else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                music.collectStat = @(1 - music.collectStat.integerValue);//收藏失败 恢复
                NSString *hintNamed = (actionType == AWEStudioMusicCollectionTypeCancelCollection ? ACCLocalizedString(@"com_mig_couldnt_connect_to_the_internet_try_again_later", @"网络不给力，取消收藏失败") : ACCLocalizedString(@"com_mig_couldnt_connect_to_the_internet_try_again_later_w6cpxj", @"网络不给力，收藏音乐失败"));
                [ACCToast() show:hintNamed];
            });
            if (error) {
                AWELogToolError(AWELogToolTagDraft, @"%s %@", __PRETTY_FUNCTION__, error);
            }
        }
    }];
}

- (void)p_setupUI {
    UIColor *bgColor = ACCResourceColor(ACCUIColorConstBGContainer);
    if (self.listType == AWEASSMusicListTypeKaraoke) {
        bgColor = UIColor.clearColor;
    }
    self.view.backgroundColor = bgColor;
    self.tableView.backgroundColor = bgColor;
    [self.view addSubview:self.tableView];

    ACCMasMaker(self.tableView, {
        make.leading.trailing.top.bottom.equalTo(self.view);
    });

    // setup UI
    @weakify(self);
    self.tableView.mj_header.endRefreshingCompletionBlock = ^{
        @strongify(self);
        [self pauseAudio];
    };
}

- (void)didPickAudio:(id<ACCMusicModelProtocol>)music error:(NSError *)error
{
    self.tableView.userInteractionEnabled = NO;
    
    if (!self.completion) {
        // 目前所有的使用方都有提供 completion & 限制以后的调用方必须有 completion
        return;
    }
    if (error) {
        [ACCToast() showError:@"download_fail"];
        self.completion(nil, error);
        self.tableView.userInteractionEnabled = YES;
        return;
    }
    __block NSError *groupError = nil;
    __block NSURL *assetUrl = nil;
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    
    [ACCVideoMusic() fetchLocalURLForMusic:music
                              withProgress:^(float progress) {}
                                completion:^(NSURL *localURL, NSError *error) {
                                       assetUrl = localURL;
                                       groupError = groupError ?: error;
                                       if (error) {
                                           AWELogToolError(AWELogToolTagMusic, @"%s %@", __PRETTY_FUNCTION__, error);
                                       }
                                       dispatch_group_leave(group);
                                   }];
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        self.tableView.userInteractionEnabled = YES;
        music.loaclAssetUrl = assetUrl;
        
        if (self.completion) {
            self.completion(music, groupError);
        }
    });
}

- (NSString *)enterFrom
{
    switch (self.listType) {
        case AWEASSMusicListTypeCategory:
            return @"change_music_page_detail";
        case AWEASSMusicListTypeSearch:
            return @"search_music";
        case AWEASSMusicListTypeMusicSticker:
            return @"lyricsticker_song_search";
        default:
            return _enterFrom ?: @"";
    }
}

- (NSString *)p_getCategoryName:(NSString *)categoryName {
    if (categoryName && [categoryName isEqualToString:ACCLocalizedCurrentString(@"dmt_av_impl_recommend")]) {
        return @"recommend";
    }
    return categoryName;
}

- (void)updateRecommenCellLogEtra:(id<ACCSingleMusicRecommenVideosTableViewCellProtocol>)cell withModel:(id<ACCSearchMusicRecommendedVideosModelProtocol>)model {
    if (!cell.logExtraDict) {
        cell.logExtraDict = [self getRecommendCardSearchBaseParams];
    }
    cell.logExtraDict[@"search_result_id"] = model.docID ?:@"";
    if (!cell.referString) {
        cell.referString = @"search_music";
    }
}

- (id<ACCAwemeModelProtocol>)getAweModelByRow:(NSInteger)row column:(NSInteger)column {
    if (row < 0 || row >= self.dataList.count) {
        return nil;
    }
    AWEMusicCollectionData *data = self.dataList[row];
    if (data.recommendModel.videoList) {
        NSArray <id<ACCAwemeModelProtocol>> *videoList = data.recommendModel.videoList;
        if (column >= 0 && column < videoList.count) {
            return [videoList acc_objectAtIndex:column];
        }
    }
    return nil;
}

- (NSMutableDictionary *)getRecommendCardMusicTrackParamsByRow:(NSInteger)row column:(NSInteger)column {
    NSMutableDictionary *params = [self getRecommendCardSearchTrackParamsWithIndex:row];
    if (params) {
        id<ACCAwemeModelProtocol> aweModel = [self getAweModelByRow:row column:column];
        if (aweModel) {
            params[@"list_item_id"] = aweModel.itemID ?:@"";
        }
        params[@"list_result_type"] = @"music";
        params[@"aladdin_rank"] = @(column);
        params[@"direction"] = @"horizontal";
        return params;
    }
    return nil;
}

- (NSMutableDictionary *)getRecommendCardSearchBaseParams {
    
    NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithDictionary:    @{
        @"log_pb":self.logPb ?: @"",
        @"impr_id":self.logPb[@"impr_id"]?:@"",
        @"search_id":self.logPb[@"impr_id"]?:@"",
        @"search_keyword":self.keyword?:@"",
        @"enter_from":@"search_music",
        @"direction" : @"horizontal",
    }];
    return dict;
    
}

- (NSMutableDictionary *)getRecommendCardSearchTrackParamsWithIndex:(NSInteger)index {
    if (index < 0 || index >= self.dataList.count) {
        return nil;
    }
    AWEMusicCollectionData *data = self.dataList[index];
    id<ACCSearchMusicRecommendedVideosModelProtocol> model = data.recommendModel;
    NSMutableDictionary * dict = [self getRecommendCardSearchBaseParams];
    dict[@"rank"] = @(index);
    dict[@"search_result_id"] = model.docID ?:@"";
    dict[@"is_aladdin"] = @(1);
    dict[@"token_type"] = @"music_with_video";
    return dict;
}

- (void)recommendExposureTrackWithIndex:(NSInteger)index {
    
    NSMutableDictionary * dict = [self getRecommendCardSearchTrackParamsWithIndex:index];
    if (dict) {
        [ACCTracker() trackEvent:@"search_result_show"
                      params:dict];
    }
    
}

#pragma mark - getter

- (NSMutableDictionary *)videoCellOffsetDict {
    if (!_videoCellOffsetDict) {
        _videoCellOffsetDict = [NSMutableDictionary new];
    }
    return _videoCellOffsetDict;
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.contentInset = UIEdgeInsetsMake(0, 0, 8, 0);
        _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, CGFLOAT_MIN)];
        [_tableView registerClass:[AWESingleMusicTableViewCell class]
           forCellReuseIdentifier:NSStringFromClass([AWESingleMusicTableViewCell class])];
        [_tableView registerClass:[AWESingleKaraokeMusicTableViewCell class] forCellReuseIdentifier:NSStringFromClass([AWESingleKaraokeMusicTableViewCell class])];
        [_tableView registerClass:[AWEMusicNoLyricTableViewCell class] forCellReuseIdentifier:NSStringFromClass([AWEMusicNoLyricTableViewCell class])];
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        if ([_tableView respondsToSelector:@selector(contentInsetAdjustmentBehavior)]) {
            if (@available(iOS 11.0, *)) {
                _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            }
        }
    }
    return _tableView;
}

- (id<ACCTransitionViewControllerProtocol>)transitionDelegate
{
    if (!_transitionDelegate) {
        _transitionDelegate = [IESAutoInline(ACCBaseServiceProvider(), ACCSelectMusicViewControllerBuilderProtocol) createTransitionDelegate];
    }
    return _transitionDelegate;
}

- (UIView *)commerceLicenseHint
{
    if (!_commerceLicenseHint) {
        _commerceLicenseHint = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, 70)];
        UILabel *label = [[UILabel alloc] init];
        label.font = [ACCFont() systemFontOfSize:15];
        label.textColor = ACCResourceColor(ACCUIColorTextTertiary);
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;
        label.preferredMaxLayoutWidth = ACC_SCREEN_WIDTH - 32;
        label.text = @"commercial_music_discover_search_default";
        [_commerceLicenseHint addSubview:label];
        ACCMasMaker(label, {
            make.left.equalTo(_commerceLicenseHint).offset(16);
            make.right.equalTo(_commerceLicenseHint).offset(-16);
            make.centerY.equalTo(_commerceLicenseHint);
        });
    }
    return _commerceLicenseHint;
}

#pragma mark - helper

- (void)enterMusicDetailViewController:(id<ACCMusicModelProtocol>)music
{
    if ([music isOffLine]) {
        [ACCToast() show:music.offlineDesc];
        [ACCTracker() trackEvent:@"enter_music_detail_failed"
                                         params:@{
                                                  @"enter_from" : [self enterFrom],
                                                  @"music_id" : music.musicID ?: @"",
                                                  @"category_name" : self.categoryName ?: @"",
                                                  @"category_id" : self.categoryId ?: @"",
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
                                     @"enter_from" : [self enterFrom],
                                     @"music_id" : music.musicID ?: @"",
                                     @"category_name" : self.categoryName ?: @"",
                                     @"category_id" : self.categoryId ?: @"",
                                     @"enter_method" : @"click_button",
                                     @"process_id" : processID,
                                     }
                                         needStagingFlag:YES];
}

- (NSMutableDictionary *)trackSearchEventParamWithMusicModel:(id<ACCMusicModelProtocol>)model
                                                  buttonType:(NSString *)buttonType
                                                        rank:(NSInteger)rank
{
    NSMutableArray *array = [NSMutableArray array];
    for (id<ACCMusicTagModelProtocol> tag in model.musicTags) {
        NSDictionary *item = @{@"tag_title":tag.tagTitle?:@"",
                               @"tag_title_color":tag.tagTitleColor?:@"",
                               @"tag_color":tag.tagColor?:@"",
                               @"tag_border_color":tag.tagBorderColor?:@"",
                               @"tag_type":tag.tagType?:@"",
                               @"tag_title_light_color":tag.tagTitleLightColor?:@"",
                               @"tag_light_color":tag.tagLightColor?:@"",
                               @"tag_border_light_color":tag.tagBorderLightColor?:@""};
        [array acc_addObject:item];
    }
    NSString *tagString = [array acc_JSONString];
    NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithDictionary:    @{
        @"log_pb":self.logPb ?: @"",
        @"impr_id":self.logPb[@"impr_id"]?:@"",
        @"search_id":self.logPb[@"impr_id"]?:@"",
        @"search_result_id":model.musicID?:@"",
        @"search_keyword":self.keyword?:@"",
        @"rank":@(rank),
        @"enter_from":@"search_music",
        @"is_aladdin":@(0),
        @"token_type":@"music",
        @"music_tag_info":tagString?:@"",
    }];
    if (!ACC_isEmptyString(buttonType)) {
        dict[@"button_type"] = buttonType?:@"";
    }
    return dict;
}

@end
