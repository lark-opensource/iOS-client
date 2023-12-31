//
//  ACCMVTemplatesDetailTableViewController.m
//  CameraClient
//
//  Created by long.chen on 2020/3/4.
//

#import "ACCMVTemplatesDetailTableViewController.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "ACCZoomContextProviderProtocol.h"
#import "ACCMVTemplateDetailTableViewCell.h"
#import "ACCViewControllerProtocol.h"
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCLoadMoreFooter.h>
#import "ACCUserProfileProtocol.h"
#import <CreativeKit/ACCFontProtocol.h>
#import "ACCMVTemplateVideoPlayViewController.h"
#import "ACCVideoPreloadProtocol.h"
#import <ByteDanceKit/BTDNetworkUtilities.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "ACCSwipeUpGuideViewController.h"
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import "ACCMVPageStyleABHelper.h"
#import "ACCConfigKeyDefines.h"
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCMVTemplateModelProtocol.h>
#import <CreationKitArch/ACCRepoContextModel.h>

static NSString * const kMVTemplateVideoProloadGrop = @"kMVTemplateVideoProloadGrop";
static NSString * const kMVTemplateDetailSwipeUpGuide = @"kMVTemplateDetailSwipeUpGuide";

@interface ACCMVTemplatesDetailTableViewController () <UITableViewDataSource, UITableViewDelegate, ACCZoomContextInnerProviderProtocol, ACCSlidePushContextProviderProtocol>

@property (nonatomic, strong) ACCAnimatedButton *backButton;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) ACCAnimatedButton *pickResourceButton;

@property (nonatomic, strong) id<ACCMVTemplatesDataControllerProtocol> dataController;
@property (nonatomic, assign) NSUInteger initialIndex;
@property (nonatomic, assign) NSUInteger displayingIndex;

@property (nonatomic, assign) BOOL isAppearing;

@property (nonatomic, strong) ACCSwipeUpGuideViewController *guideViewController;

@end

@implementation ACCMVTemplatesDetailTableViewController

- (void)dealloc
{
    [IESAutoInline(ACCBaseServiceProvider(), ACCVideoPreloadProtocol) cancelGroup:kMVTemplateVideoProloadGrop];
}

- (instancetype)initWithDataController:(id<ACCMVTemplatesDataControllerProtocol>)dataController initialIndex:(NSUInteger)initialIndex
{
    if (self = [super init]) {
        self.hidesBottomBarWhenPushed = YES;
        _dataController = dataController;
        _initialIndex = initialIndex;
        _displayingIndex = NSNotFound;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(p_appWillResignActive:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(p_appDidBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(p_videoDownloadFinished:)
                                                     name:ACCMVTemplateDidFinishVideoDataDownloadNotification
                                                   object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    
    [self.tableView reloadData];
    if (self.dataController.dataSource.count > self.initialIndex) {
        [self.tableView setContentOffset:CGPointMake(0, self.initialIndex * [self p_cellHeight]) animated:NO];
    }
    if (!self.dataController.hasMore) {
        [self.tableView.mj_footer endRefreshingWithNoMoreData];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.isAppearing = NO;
    [self pause];
    self.navigationController.delegate = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.view.accessibilityViewIsModal = YES;
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.backButton);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.isAppearing = YES;
    [self playIfActive];
    self.navigationController.delegate = self.initialNavigaitonDelegate;
    
    if ([self shouldShowSwipeUpGuide]) {
        [self.guideViewController showSwipeUpGuideOnTableView:self.tableView];
        [self storeSwipeUpGuideState];
    }
}

- (BOOL)prefersStatusBarHidden
{
    if ([UIDevice acc_isIPhoneX] && ACCViewFrameOptimizeContains(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize), ACCViewFrameOptimizeHideStatusBar)) {
        return YES;
    }
    return [super prefersStatusBarHidden];
}

- (void)p_setupUI
{
    [ACCViewControllerService() viewController:self setPrefersNavigationBarHidden:YES];
    self.view.backgroundColor = UIColor.blackColor;
    
    self.tableView.frame = CGRectMake(0, 0, self.view.acc_width, self.view.acc_height - ([UIDevice acc_isIPhoneX] ? 86 : 0));
    [self.view addSubview:self.tableView];
    
    @weakify(self);
    ACCLoadMoreFooter *footer = [ACCLoadMoreFooter footerWithRefreshingBlock:^{
        @strongify(self);
        [self p_loadmore];
    }];
    [footer setLoadingViewBackgroundColor:UIColor.clearColor];
    self.tableView.mj_footer = footer;
    
    self.backButton.frame = CGRectMake(6, ACC_NAVIGATION_BAR_OFFSET + 24, 44, 40);
    [self.view addSubview:self.backButton];
    
    if ([UIDevice acc_isIPhoneX]) {
        self.pickResourceButton.frame = CGRectMake(16, self.view.acc_height - 86, self.view.acc_width - 32, 44);
        [self.view addSubview:self.pickResourceButton];
    }
}

- (void)playIfActive
{
    if (self.p_isActive) {
        [self play];
    }
}

- (void)play
{
    ACCMVTemplateDetailTableViewCell *cell = self.tableView.visibleCells.firstObject;
    [cell play];
}

- (void)pause
{
    ACCMVTemplateDetailTableViewCell *cell = self.tableView.visibleCells.firstObject;
    [cell pause];
}

#pragma mark - SwipeUp Guide
- (ACCSwipeUpGuideViewController *)guideViewController
{
    if (!_guideViewController) {
        _guideViewController = [[ACCSwipeUpGuideViewController alloc] init];
    }
    return _guideViewController;
}

- (BOOL)shouldShowSwipeUpGuide
{
    BOOL justHasOneModel = self.dataController.dataSource.count <= 1 && NO == self.dataController.hasMore;
    return ![ACCCache() boolForKey:kMVTemplateDetailSwipeUpGuide] && !justHasOneModel;
}

- (void)storeSwipeUpGuideState
{
    [ACCCache() setBool:YES forKey:kMVTemplateDetailSwipeUpGuide];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataController.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ACCMVTemplateDetailTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[ACCMVTemplateDetailTableViewCell cellidentifier] forIndexPath:indexPath];
    cell.parentVC = self;
    cell.indexPath = indexPath;
    cell.viewController.didPickTemplateBlock = self.didPickTemplateBlock;
    cell.viewController.publishModel = self.publishModel;
    if (indexPath.row < self.dataController.dataSource.count) {
        [cell updateWithTemplateModel:self.dataController.dataSource[indexPath.row]];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(nonnull UITableViewCell *)cell forRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    if (self.dataController.dataSource.count - indexPath.row < 5) {
        [self p_loadmore];
    }
    
    if (indexPath.row < self.dataController.dataSource.count) {
        id<ACCMVTemplateModelProtocol> templateModel = self.dataController.dataSource[indexPath.row];
        if (self.displayingIndex != NSNotFound && self.displayingIndex != indexPath.row) {
            [ACCTracker() trackEvent:@"slide_change_mv"
                     params:@{
                         @"mv_id" : @(templateModel.templateID),
                         @"enter_from" : @"mv_card",
                         @"shoot_way" : self.publishModel.repoTrack.referString ?: @"",
                         @"creation_id" : self.publishModel.repoContext.createId ?: @"",
                         @"content_type" : templateModel.accTemplateType == ACCMVTemplateTypeClassic ? @"mv" : @"jianying_mv",
                         @"direction" : indexPath.row > self.displayingIndex ? @"up" : @"down",
                         @"mv_recommend" : @"1",
                     }
            needStagingFlag:NO];
        }
        
        [ACCTracker() trackEvent:@"mv_show"
                           params:@{
                               @"mv_id" : @(templateModel.templateID),
                               @"enter_from" : @"mv_card",
                               @"shoot_way" : self.publishModel.repoTrack.referString ?: @"",
                               @"creation_id" : self.publishModel.repoContext.createId ?: @"",
                               @"content_type" : templateModel.accTemplateType == ACCMVTemplateTypeClassic ? @"mv" : @"jianying_mv",
                               @"mv_recommend" : @"1",
                               @"impr_position" : @(indexPath.item + 1)
                           }
                  needStagingFlag:NO];
        
        if ([UIDevice acc_isIPhoneX]) { // update pick button text
            [self.pickResourceButton setTitle:[ACCMVPageStyleABHelper acc_cutsameSelectHintText] forState:UIControlStateNormal];
        }
    }
    self.displayingIndex = indexPath.row;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:ACCMVTemplateDetailTableViewCell.class]) {
        [(ACCMVTemplateDetailTableViewCell *)cell reset];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self p_cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self playIfActive];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self playIfActive];
}

#pragma mark - ACCZoomContextInnerProviderProtocol

- (NSInteger)acc_zoomTransitionItemOffset
{
    return [self p_currentIndex] - self.initialIndex;
}

#pragma mark - ACCSlidePushContextProviderProtocol

- (UIViewController *)slidePushTargetViewController
{
#if DEBUG
    if ([self p_currentIndex] < 0 || [self p_currentIndex] >= self.dataController.dataSource.count) {
        return nil;
    }
    id<ACCMVTemplateModelProtocol> templateModel = self.dataController.dataSource[[self p_currentIndex]];
    if (!ACC_isEmptyString(templateModel.author.userID)) {
        [ACCTracker() track:@"enter_personal_detail"
                      params:@{
                          @"enter_from" : @"mv_card",
                          @"enter_method" : @"slide_left",
                          @"to_user_id" : templateModel.author.userID,
                          @"creation_id" : self.publishModel.repoContext.createId ?: @"",
                      }];
        
        return [IESAutoInline(ACCBaseServiceProvider(), ACCUserProfileProtocol) userProfileVCForUserID:templateModel.author.userID];
    }
#endif
    return nil;
}

#pragma mark - Actions

- (void)p_backButtonPressed:(UIButton *)button
{
    ACCBLOCK_INVOKE(self.cancelBlock);
    if ([self isBeingPresentedModally]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (BOOL)isBeingPresentedModally
{
    if (self.navigationController && self.navigationController.presentingViewController) {
        return ([self.navigationController.viewControllers indexOfObject:self] == 0);
    } else {
        return ([self presentingViewController] != nil);
    }
}

- (void)p_handlePickResourceButtonClicked:(UIButton *)button
{
    [button acc_disableUserInteractionWithTimeInterval:1];
    if ([self p_currentIndex] < 0 || [self p_currentIndex] >= self.dataController.dataSource.count) {
        return;
    }
    id<ACCMVTemplateModelProtocol> templateModel = self.dataController.dataSource[[self p_currentIndex]];
    ACCBLOCK_INVOKE(self.didPickTemplateBlock, templateModel);
    
    NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.publishModel.repoTrack.referExtra];
    [referExtra addEntriesFromDictionary:@{
        @"content_type" : templateModel.accTemplateType == ACCMVTemplateTypeClassic ? @"mv" : @"jianying_mv",
        @"content_source" : @"upload",
        @"enter_from" : @"mv_card",
        @"mv_id" : @(templateModel.templateID),
        @"mv_name" : templateModel.title ?: @"",
        @"impr_position" : @([self p_currentIndex] + 1),
        @"mv_recommend" : @"1",
    }];
    [ACCTracker() trackEvent:@"select_mv"
                       params:referExtra
              needStagingFlag:NO];
}

#pragma mark - Notifications

- (void)p_appWillResignActive:(NSNotification *)notification
{
    [self pause];
}

- (void)p_appDidBecomeActive:(NSNotification *)notification
{
    [self playIfActive];
}

- (void)p_videoDownloadFinished:(NSNotification *)notification
{
    NSUInteger templateID = [[notification.userInfo objectForKey:ACCMVTemplateDidFinishVideoDataDownloadIDKey] integerValue];
    NSArray<ACCMVTemplateDetailTableViewCell *> *visibleCells = self.tableView.visibleCells;
    __block NSUInteger currentIdx = NSNotFound;
    [visibleCells enumerateObjectsUsingBlock:^(ACCMVTemplateDetailTableViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.templateModel.templateID == templateID) {
            currentIdx = idx;
            *stop = YES;
        }
    }];
    if (currentIdx != NSNotFound) {
        [self p_doVideoPrefetch:currentIdx];
    }
}

#pragma mark - Utility

- (void)p_loadmore
{
    if (!self.dataController.hasMore) {
        return;
    }
    @weakify(self);
    [self.dataController loadMoreContentDataWithCompletion:^(NSError * error, NSArray<id<ACCMVTemplateModelProtocol>> *templateModels, BOOL hasMore) {
        @strongify(self);
        if (!error && templateModels.count) {
            ACCBLOCK_INVOKE(self.dataChangedBlock);
            NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
            NSInteger originDataCount = [self.tableView numberOfRowsInSection:0];
            for (NSInteger i = originDataCount; i < self.dataController.dataSource.count; ++i) {
                [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
            if (indexPaths.count) {
                [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
            }
        }
        if (!hasMore) {
            [self.tableView.mj_footer endRefreshingWithNoMoreData];
        } else {
            [self.tableView.mj_footer endRefreshing];
        }
    }];
}

- (NSUInteger)p_currentIndex
{
    return self.tableView.contentOffset.y / [self p_cellHeight];
}

- (CGFloat)p_cellHeight
{
    return self.tableView.acc_height;
}

- (BOOL)p_isActive
{
    return [UIApplication sharedApplication].applicationState == UIApplicationStateActive && self.isAppearing;
}

- (void)p_doVideoPrefetch:(NSUInteger)currentIndex
{
    if (!BTDNetworkConnected()) {
        return;
    }
    NSInteger prevIndex = currentIndex - 1;
    if (prevIndex < self.dataController.dataSource.count) {
        id<ACCMVTemplateModelProtocol> template = self.dataController.dataSource[prevIndex];
        [self p_preloadWithTemplate:template];
    }
    
    NSInteger preloadCount = 3;
    if (!BTDNetworkWifiConnected()) {
        preloadCount = 1;
    }
    for (NSInteger i = 1; i <= preloadCount; i++) {
        NSUInteger nextIndex = currentIndex + i;
        if (nextIndex < self.dataController.dataSource.count) {
            id<ACCMVTemplateModelProtocol> template = self.dataController.dataSource[nextIndex];
            [self p_preloadWithTemplate:template];
        }
    }
}

- (void)p_preloadWithTemplate:(id<ACCMVTemplateModelProtocol>)template
{
    id<ACCURLModelProtocol> urlModel = template.video.playURL;
    if (urlModel) {
        [IESAutoInline(ACCBaseServiceProvider(), ACCVideoPreloadProtocol) preloadVideo:urlModel.URI
                                andVideoURL:urlModel.URLList.firstObject
                                      group:kMVTemplateVideoProloadGrop
                                     fileCs:urlModel.fileCs
                                     urlKey:urlModel.URLKey];
    }
}

#pragma mark - Getters

- (ACCAnimatedButton *)backButton
{
    if (!_backButton) {
        _backButton = [ACCAnimatedButton new];
        UIImage *image = ACCResourceImage(@"ic_titlebar_back_white");
        [_backButton setImage:image forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(p_backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        _backButton.isAccessibilityElement = YES;
        _backButton.accessibilityLabel = @"返回";
    }
    return _backButton;
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = UIColor.blackColor;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.pagingEnabled = YES; 
        _tableView.separatorColor = UIColor.clearColor;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 150000
        if (@available(iOS 15.0, *)) {
            _tableView.prefetchingEnabled = NO;
        }
#endif
        if ([_tableView respondsToSelector:@selector(contentInsetAdjustmentBehavior)]) {
            if (@available(iOS 11.0, *)) {
                _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            }
        }
        [_tableView registerClass:ACCMVTemplateDetailTableViewCell.class forCellReuseIdentifier:ACCMVTemplateDetailTableViewCell.cellidentifier];
    }
    return _tableView;
}

- (ACCAnimatedButton *)pickResourceButton
{
    if (!_pickResourceButton) {
        _pickResourceButton = [[ACCAnimatedButton alloc] initWithFrame:CGRectZero type:ACCAnimatedButtonTypeAlpha];
        _pickResourceButton.backgroundColor = ACCResourceColor(ACCColorPrimary);
        _pickResourceButton.titleLabel.font = [ACCFont() acc_systemFontOfSize:15 weight:ACCFontWeightMedium];
        _pickResourceButton.titleLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
        _pickResourceButton.layer.masksToBounds = YES;
        _pickResourceButton.layer.cornerRadius = 2;
        [_pickResourceButton setTitle:[ACCMVPageStyleABHelper acc_cutsameSelectHintText] forState:UIControlStateNormal];
        [_pickResourceButton setImage:ACCResourceImage(@"icon_video_upload_multiple_selected") forState:UIControlStateNormal];
        [_pickResourceButton setImageEdgeInsets:UIEdgeInsetsMake(0, -4, 0, 4)];
        [_pickResourceButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 4, 0, -4)];
        [_pickResourceButton addTarget:self action:@selector(p_handlePickResourceButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _pickResourceButton;
}

@end
