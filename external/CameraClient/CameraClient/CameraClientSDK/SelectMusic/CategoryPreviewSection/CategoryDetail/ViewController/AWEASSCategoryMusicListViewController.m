//
//  AWEASSCategoryMusicListViewController.m
//  AWEStudio
//
//  Created by 李彦松 on 2018/9/12.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWEASSCategoryMusicListViewController.h"
#import "AWEASSMusicListViewController.h"
#import "ACCCategoryMusicListManager.h"
#import "AWEMusicCollectionData.h"
#import "ACCCommerceMusicServiceProtocol.h"
#import "AWEASSMusicNavView.h"

#import <CreationKitInfra/ACCLoadMoreFooter.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CameraClient/ACCRefreshHeader.h>
#import <CameraClient/UIScrollView+ACCInfiniteScrolling.h>
#import <CreationKitInfra/ACCModuleService.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>

#import <Masonry/Masonry.h>


@interface AWEASSCategoryMusicListViewController ()

@property (nonatomic, strong) AWEASSMusicListViewController *listVC;

@property (nonatomic, copy) NSString *cid;
@property (nonatomic, copy) NSString *categoryName;
@property (nonatomic, strong) ACCCategoryMusicListManager *musicManager;
@property (nonatomic, assign) BOOL isEliteVersion;
@property (nonatomic, assign) UIStatusBarStyle savedStatusBarStyle;
@property (nonatomic, assign) BOOL shouldShowUploadMusicButton;
@property (nonatomic, copy) NSString *enterMethod;
@property (nonatomic, copy) NSString *previousPage;
@property (nonatomic, assign) BOOL shouldHideCellMoreButton;
@property (nonatomic, assign) BOOL shouldShowRank;
@property (nonatomic, strong) AWEASSMusicNavView *navView;
@property (nonatomic, assign) BOOL isCommerce;
@property (nonatomic, assign) ACCServerRecordMode recordMode;
@property (nonatomic, assign) NSTimeInterval videoDuration;
@property (nonatomic, assign) BOOL disableCutMusic;

@end

@implementation AWEASSCategoryMusicListViewController

@synthesize completion = _completion, enableClipBlock = _enableClipBlock, willClipBlock = _willClipBlock;

- (instancetype)initWithCategoryId:(NSString *)cid
{
    self = [super init];
    if (self) {
        _cid = [cid copy];
    }
    return self;
}

- (BOOL)configWithRouterParamDict:(NSDictionary<NSString *, NSString *> *)paramDict
{
    //直接跳转到原创音乐歌单，显示上传音乐
    self.cid = [paramDict acc_objectForKey:@"cid"];
    if ([self.cid isEqualToString:@"music_hot_list"]) {
        // TODO(liyansong): Find a better way.
        self.cid = nil;
    }
    self.hidesBottomBarWhenPushed = YES;
    self.categoryName = [paramDict acc_objectForKey:@"name"];
    self.enterMethod = [paramDict acc_objectForKey:@"enterMethod"];
    self.previousPage = [paramDict acc_objectForKey:@"previousPage"];
    self.shouldHideCellMoreButton = [paramDict acc_boolValueForKey:@"hideMore"];
    self.shouldShowRank = [paramDict acc_boolValueForKey:@"is_hot"];
    self.isCommerce = [paramDict acc_boolValueForKey:@"is_commerce"];
    self.recordMode = [paramDict acc_integerValueForKey:@"record_mode"];
    self.videoDuration = [paramDict acc_doubleValueForKey:@"video_duration"];
    self.disableCutMusic = [paramDict acc_boolValueForKey:@"disable_cut_music"];
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.savedStatusBarStyle = UIStatusBarStyleLightContent;
    [self p_setupUI];
    [self p_refreshData];
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Private
#pragma mark load data

- (void)p_refreshData {
    @weakify(self);
    [self.musicManager refresh:^(NSArray *list, NSError *error) {
        @strongify(self);
        if (!error) {
            [self transformAndSetListData];
            [self.listVC.tableView.mj_header endRefreshing];
            [self p_endRefreshing];
            if (ACC_isEmptyString(self.navView.titleLabel.text)) {
                self.navView.titleLabel.text = [self.musicManager getMusicListTitle];
            }
        } else {
            AWELogToolError(AWELogToolTagDraft, @"%s %@", __PRETTY_FUNCTION__, error);
        }
    }];
}

- (void)p_loadMoreData {
    @weakify(self);
    [self.musicManager loadMore:^(NSArray *list, NSError *error) {
        @strongify(self);
        [self transformAndSetListData];
        if (ACC_isEmptyString(self.navView.titleLabel.text)) {
            self.navView.titleLabel.text = [self.musicManager getMusicListTitle];
        }
        [self p_endRefreshing];
        if (error) {
            AWELogToolError(AWELogToolTagDraft, @"%s %@", __PRETTY_FUNCTION__, error);
        }
    }];
}

- (void)p_endRefreshing {
    [self.listVC.tableView.acc_infiniteScrollingView stopAnimating];
    if (self.musicManager.hasMore) {
        [self.listVC.tableView.mj_footer endRefreshing];
    } else {
        [self.listVC.tableView.mj_footer endRefreshingWithNoMoreData];
    }
}

- (void)transformAndSetListData {
    NSMutableArray *transformedDataList =
            [NSMutableArray arrayWithCapacity:self.musicManager.dataList.count];
    for (id<ACCMusicModelProtocol> music in self.musicManager.dataList) {
        AWEMusicCollectionData *data =
                [[AWEMusicCollectionData alloc] initWithMusicModel:music withType:AWEMusicCollectionDataTypeMusic];
        [transformedDataList acc_addObject:data];
    }
    self.listVC.dataList = [transformedDataList copy];
}

- (CGFloat)footerInset
{
    //这里设置68是因为infinite的inset为60，tableview初始化时设置了8，加起来是68m。保持跟原来一致
    return 68;
}

#pragma mark UI

- (void)p_setupUI {
    self.title = self.categoryName;
    self.view.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainer);
    [self addChildViewController:self.listVC];
    [self.listVC didMoveToParentViewController:self];
    [self.view addSubview:self.listVC.view];
    [self.view addSubview:self.navView];
    
    CGFloat navViewHeight = [self.navView recommendHeight];
    ACCMasMaker(self.navView, {
        make.leading.equalTo(@0);
        make.trailing.equalTo(self.view.mas_trailing);
        make.top.equalTo(self.view);
        make.height.equalTo(@(navViewHeight));
    });

    UIView *adView = [ACCCommerceMusicService() loadMusicListAdView:self.cid categoryName:self.categoryName];
    if (adView) {
        [self.view addSubview:adView];
        ACCMasMaker(adView, {
            make.top.equalTo(self.navView.mas_bottom);
            make.height.equalTo(@(36));
            make.left.right.equalTo(self.view);
        });
    }
    
    ACCMasMaker(self.listVC.view, {
        if (adView) {
            make.top.equalTo(adView.mas_bottom);
        } else {
            make.top.equalTo(self.navView.mas_bottom);
        }
        make.left.right.bottom.equalTo(self.view);
    });
    
    @weakify(self);
    ACCRefreshHeader *header = [ACCRefreshHeader headerWithRefreshingBlock:^{
        @strongify(self);
        [self p_refreshData];
    }];
    [header setLoadingViewBackgroundColor:UIColor.clearColor];
    self.listVC.tableView.mj_header = header;
    
    ACCLoadMoreFooter *footer = [ACCLoadMoreFooter footerWithRefreshingBlock:^{
        @strongify(self);
        if (self.musicManager.hasMore) {
            [self p_loadMoreData];
        } else {
            [self p_endRefreshing];
        }
    }];
    if (!self.isEliteVersion) {
        [footer setLoadMoreLabelTextColor:ACCResourceColor(ACCUIColorConstTextTertiary2)];
    }
    
    footer.showNoMoreDataText = YES;
    self.listVC.tableView.mj_footer = footer;
    [self.listVC.tableView acc_addInfiniteScrollingWithActionHandler:^{
        @strongify(self);
        if (self.musicManager.hasMore) {
            [self p_loadMoreData];
        }
    }];
    self.listVC.tableView.showsVerticalScrollIndicator = NO;
}

- (AWEASSMusicNavView *)navView
{
    if (!_navView) {
        _navView = [[AWEASSMusicNavView alloc] init];
        _navView.leftButtonIsBack = YES;
        _navView.titleLabel.textColor = ACCResourceColor(ACCUIColorConstTextPrimary);
        _navView.titleLabel.text = self.title;
        [_navView.leftCancelButton addTarget:self
                                      action:@selector(cancelBtnClicked:)
                            forControlEvents:UIControlEventTouchUpInside];
    }
    return _navView;
}

- (void)cancelBtnClicked:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - getter & setter

- (AWEASSMusicListViewController *)listVC {
    if (!_listVC) {
        _listVC = [[AWEASSMusicListViewController alloc] init];
        _listVC.listType = AWEASSMusicListTypeCategory;
        _listVC.enterMethod = self.enterMethod;
        _listVC.completion = self.completion;
        _listVC.enableClipBlock = self.enableClipBlock;
        _listVC.willClipBlock = self.willClipBlock;
        _listVC.previousPage = self.previousPage;
        _listVC.categoryName = self.categoryName;
        _listVC.categoryId = self.cid;
        _listVC.shouldHideCellMoreButton = self.shouldHideCellMoreButton;
        _listVC.showRank = self.shouldShowRank;
        _listVC.disableCutMusic = self.disableCutMusic;
    }
    return _listVC;
}

- (ACCCategoryMusicListManager *)musicManager {
    if (!_musicManager) {
        _musicManager = [[ACCCategoryMusicListManager alloc] initWithCategoryId:self.cid isCommerce:self.isCommerce];
        _musicManager.recordModel = self.recordMode;
        _musicManager.videoDuration = self.videoDuration;
    }
    return _musicManager;
}

- (void)setCompletion:(HTSVideoAudioCompletion)completion
{
    _listVC.completion = completion;
    _completion = completion;
}

@end
