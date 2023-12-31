//
//  ACCVideoEditStickerSinglePannelVCViewController.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/8/18.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCVideoEditStickerSinglePannelVC.h"
#import <CameraClient/ACCSlidingViewController.h>
#import <CameraClient/ACCSlidingTabbarView.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "AWESingleStickerDownloader.h"
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>
#import "ACCStickerPannelDataManager.h"
#import "ACCStickerSinglePannelCollectionViewController.h"
#import "ACCStickerPannelDataManager.h"
#import <CreationKitInfra/ACCToastProtocol.h>

static const CGFloat kAWEVideoEditStickerSwitchTabViewHeight = 52;

@interface ACCVideoEditStickerSinglePannelVC () <ACCSlidingViewControllerDelegate, AWEVideoEditStickerCollectionVCDelegate>

@property (nonatomic, strong) ACCSlidingViewController *slidingViewController;
@property (nonatomic, strong) ACCSlidingTabbarView *slidingTabbarView;

@property (nonatomic, copy) NSArray<NSString *> *titles;
@property (nonatomic, strong) NSMutableArray<UIViewController *> *tabControllers;

@property (nonatomic, strong) ACCStickerPannelDataManager *dataManager;
@property (nonatomic, strong) AWESingleStickerDownloader *stickerDownloader;

@property (nonatomic, strong) UIView *errorView;

@end

@implementation ACCVideoEditStickerSinglePannelVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.topOffset = self.uiConfig.pannelTopOffset > 0 ? self.uiConfig.pannelTopOffset : self.topOffset;
    
    [self.view addSubview:self.slidingTabbarView];
    ACCMasMaker(self.slidingTabbarView, {
        make.top.equalTo(self.view.mas_top);
        make.left.right.equalTo(self.view);
        make.height.equalTo(@(kAWEVideoEditStickerSwitchTabViewHeight));
    });
    
    UIFont *normalFont = [self.uiConfig slidingTabbarViewButtonTextNormalFont];
    UIFont *selectedFont = [self.uiConfig slidingTabbarViewButtonTextSelectFont];
    [_slidingTabbarView configureButtonTextFont:normalFont selectedFont:selectedFont];
    [self.slidingTabbarView configureButtonTextColor:ACCResourceColor(ACCUIColorConstTextInverse3) selectedTextColor:ACCResourceColor(ACCUIColorConstTextInverse)];
    self.slidingTabbarView.selectionLineColor = ACCResourceColor(ACCUIColorConstTextInverse);
    self.slidingTabbarView.shouldShowBottomLine = NO;
    self.slidingTabbarView.topBottomLineColor = ACCUIColorFromRGBA(0xFFFFFF, .12);
    CGFloat seperatorViewHeight = 0.5;
    if ([UIScreen mainScreen].scale > 0) {
        seperatorViewHeight = 1.0f/[UIScreen mainScreen].scale;
    }
    UIView *seperatorView = [[UIView alloc] init];
    seperatorView.backgroundColor = ACCUIColorFromRGBA(0xFFFFFF, .12);
    [self.slidingTabbarView addSubview:seperatorView];
    ACCMasMaker(seperatorView, {
        make.leading.trailing.equalTo(@(0));
        make.bottom.equalTo(self.slidingTabbarView.mas_bottom);
        make.height.equalTo(@(seperatorViewHeight));
    });
    
    [self.view addSubview:self.errorView];
    ACCMasMaker(self.errorView, {
        make.edges.equalTo(self.view);
    });
    
    [self fetchData];
}

- (void)fetchData {
    @weakify(self)
    self.errorView.hidden = YES;
    [self.dataManager fetchPanelCategories:^(BOOL downloadSuccess, NSArray<IESCategoryModel *> * _Nonnull stickerCategories) {
        @strongify(self)
        if (downloadSuccess) {
            [self setupSlidingVCWithCategories:stickerCategories];
        } else {
            self.errorView.hidden = NO;
        }
    }];
}

- (void)setupSlidingVCWithCategories:(NSArray<IESCategoryModel *> *)stickerCategories {
    self.titles = [stickerCategories acc_mapObjectsUsingBlock:^id _Nonnull(IESCategoryModel *  _Nonnull item, NSUInteger idex) {
        return item.categoryName;
    }];
    for (IESCategoryModel *category in stickerCategories) {
        ACCStickerSinglePannelCollectionViewController *stickerVC = [ACCStickerSinglePannelCollectionViewController new];
        stickerVC.category = category;
        stickerVC.uiConfig = self.uiConfig;
        stickerVC.logger = self.logger;
        stickerVC.dataManager = self.dataManager;
        stickerVC.delegate = self;
        [self.tabControllers addObject:stickerVC];
    }
    
    [self.slidingViewController setTabbarView:self.slidingTabbarView];
    [self addChildViewController:self.slidingViewController];
    [self.slidingViewController didMoveToParentViewController:self];
    [self.view addSubview:self.slidingViewController.view];
    ACCMasMaker(self.slidingViewController.view, {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.slidingTabbarView.mas_bottom);
    });
    
    [self.slidingTabbarView resetDataArray:self.titles selectedDataArray:self.titles];
    [self.slidingViewController reloadViewControllers];
    self.slidingViewController.selectedIndex = 0;
}

- (ACCStickerPannelDataManager *)dataManager {
    if (!_dataManager) {
        _dataManager = [ACCStickerPannelDataManager new];
        _dataManager.pageCount = self.pageItemCount;
        _dataManager.pannelName = self.pannelName;
        _dataManager.logger = self.logger;
    }
    return _dataManager;
}

- (UIView *)errorView
{
    if (!_errorView) {
        _errorView = [[UIView alloc] init];
        _errorView.backgroundColor = [UIColor clearColor];

        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.text = ACCLocalizedCurrentString(@"error_retry");
        titleLabel.font = [ACCFont() systemFontOfSize:15];
        titleLabel.textColor = ACCResourceColor(ACCUIColorConstIconInverse3);
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.numberOfLines = 0;
        [_errorView addSubview:titleLabel];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wimplicit-retain-self"
        ACCMasMaker(titleLabel, {
            make.center.equalTo(_errorView);
            make.left.equalTo(@32);
            make.right.equalTo(@-32);
        });
#pragma clang diagnostic pop
        _errorView.hidden = YES;
        UITapGestureRecognizer *ges = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fetchData)];
        [_errorView addGestureRecognizer:ges];
    }
    return _errorView;
}

#pragma mark - AWEVideoEditStickerCollectionVCDelegate

- (void)stickerCollectionViewController:(AWEVideoEditStickerCollectionViewController *)stickerCollectionVC
                       didSelectSticker:(IESEffectModel *)sticker
                                atIndex:(NSInteger)index
                                categoryName:(NSString *)categoryName
                                     tabName:(NSString *)tabName
                  downloadProgressBlock:(void(^)(CGFloat))downloadProgressBlock
                        downloadedBlock:(void(^)(void))downloadedBlock {
    @weakify(self);
    [self.delegate stickerPannelVC:self didSelectSticker:sticker downloadTrigger:^{
        void(^compeletion)(AWESingleStickerDownloadInfo * _Nonnull downloadInfo) = ^(AWESingleStickerDownloadInfo * _Nonnull downloadInfo) {
            @strongify(self);
            ACCBLOCK_INVOKE(downloadedBlock);
            [self.logger logStickerDownloadFinished:downloadInfo];
            if (downloadInfo.result.failed) {
                [ACCToast() showError:ACCLocalizedCurrentString(@"com_mig_stickers_are_not_available")];
            } else {
                [self.delegate stickerPannelVC:self didSelectSticker:sticker downloadTrigger:nil];
            }
        };
        @strongify(self);
        AWESingleStickerDownloadParameter *download = [AWESingleStickerDownloadParameter new];
        download.sticker = sticker;
        download.downloadProgressBlock = downloadProgressBlock;
        download.compeletion = compeletion;
        [self.stickerDownloader downloadSticker:download];
    }];
}

- (AWESingleStickerDownloader *)stickerDownloader {
    if (!_stickerDownloader) {
        _stickerDownloader = [AWESingleStickerDownloader new];
    }
    return _stickerDownloader;
}

#pragma mark - getter & setter

- (ACCSlidingTabbarView *)slidingTabbarView
{
    if (!_slidingTabbarView) {
        _slidingTabbarView = [[ACCSlidingTabbarView alloc] initWithFrame:CGRectMake(0, 0, self.view.acc_width, kAWEVideoEditStickerSwitchTabViewHeight) buttonStyle:ACCSlidingTabButtonStyleText dataArray:nil selectedDataArray:nil];
        _slidingTabbarView.selectedIndex = 0;
        _slidingTabbarView.shouldShowBottomLine = YES;
        _slidingTabbarView.shouldShowTopLine = NO;
        [_slidingTabbarView configureButtonTextColor:ACCResourceColor(ACCUIColorConstTextInverse3) selectedTextColor:ACCResourceColor(ACCUIColorConstTextInverse)];
        UIFont *normalFont = [self.uiConfig slidingTabbarViewButtonTextNormalFont];
        UIFont *selectedFont = [self.uiConfig slidingTabbarViewButtonTextSelectFont];
        [_slidingTabbarView configureButtonTextFont:normalFont hasShadow:YES];
        [_slidingTabbarView configureButtonTextFont:normalFont selectedFont:selectedFont];
        _slidingTabbarView.selectionLineColor = [UIColor clearColor];
        _slidingTabbarView.topBottomLineColor = ACCUIColorFromRGBA(0xFFFFFF, .12);
    }
    return _slidingTabbarView;
}

- (ACCSlidingViewController *)slidingViewController
{
    if (!_slidingViewController) {
        _slidingViewController = [[ACCSlidingViewController alloc] init];
        _slidingViewController.slideEnabled = YES;
        _slidingViewController.delegate = self;
    }
    return _slidingViewController;
}

- (NSMutableArray<UIViewController *> *)tabControllers {
    if (!_tabControllers) {
        _tabControllers = @[].mutableCopy;
    }
    return _tabControllers;
}

- (ACCStickerPannelUIConfig *)uiConfig {
    if (!_uiConfig) {
        _uiConfig = [ACCStickerPannelUIConfig new];
    }
    return _uiConfig;
}

#pragma mark - ACCSlidingViewControllerDelegate

- (NSInteger)numberOfControllers:(ACCSlidingViewController *)slidingController
{
    return self.tabControllers.count;
}

- (UIViewController *)slidingViewController:(ACCSlidingViewController *)slidingViewController viewControllerAtIndex:(NSInteger)index
{
    if (index >= self.tabControllers.count) {
        return [[UIViewController alloc] init];
    }
    return self.tabControllers[index];
}

- (void)slidingViewController:(ACCSlidingViewController *)slidingViewController didSelectIndex:(NSInteger)index
{
    [self.logger logSlidingDidSelectIndex:index title:[self.titles objectAtIndex:index]];
}

@end
