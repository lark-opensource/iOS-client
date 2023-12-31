//
//  CAKAlbumViewController.m
//  CameraClient
//
//  Created by lixingdong on 2020/6/16.
//

#import <Masonry/Masonry.h>
#import <CreativeKit/ACCMacros.h>
#import <ReactiveObjC/ReactiveObjC.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeAlbumKit/UIImage+AlbumKit.h>
#import <KVOController/KVOController.h>
#import <AVFoundation/AVPlayer.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>

#import "CAKAlbumViewController.h"
#import "CAKAlbumViewModel.h"
#import "CAKAlbumListViewController.h"
#import "CAKAlbumViewControllerNavigationView.h"
#import "CAKAlbumSlidingViewController.h"
#import "CAKAlbumSlidingTabBarView.h"
#import "CAKAlbumSlidingScrollView.h"
#import "CAKAlbumRequestAccessView.h"
#import "CAKAlbumDenyAccessView.h"
#import "CAKAlbumSelectedAssetsView.h"
#import "CAKAlbumSwitchBottomView.h"
#import "CAKAlbumCategorylistCell.h"
#import "CAKAlbumGoSettingStrip.h"
#import "CAKLanguageManager.h"
#import "UIColor+AlbumKit.h"
#import "CAKToastProtocol.h"
#import "CAKLanguageManager.h"
#import "CAKLoadingProtocol.h"

const static NSUInteger kAlbumTitleTabHight = 40;
const static CGFloat    kAlbumFullBottomOffset = 1.0f;
static NSString * const kACCRecordSupportSinglePhotoUpload = @"acc.record.support_single_photo_upload";

@interface CAKAlbumViewController () <CAKAlbumListViewControllerDelegate, CAKAlbumSlidingViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, PHPhotoLibraryChangeObserver>

@property (nonatomic, strong, readwrite) CAKAlbumViewModel *viewModel;

@property (nonatomic, strong) UIView *viewWrapper;
@property (nonatomic, strong) UIView *albumTopLine;
@property (nonatomic, strong) UITableView *albumListTableView;
@property (nonatomic, strong) CAKAlbumSlidingTabBarView *slidingTabView;
@property (nonatomic, strong) CAKAlbumSlidingViewController *slidingViewController;

// photo library permission request
@property (nonatomic, strong) CAKAlbumGoSettingStrip *goSettingStrip;
@property (nonatomic, strong) UIView<CAKAlbumRequestAccessViewProtocol> *requestAccessView;
@property (nonatomic, strong) UIView<CAKAlbumRequestAccessViewProtocol> *denyAccessView;


// photos and videos mixed
@property (nonatomic, strong) UIView<CAKSelectedAssetsViewProtocol> *selectedAssetsView;
@property (nonatomic, strong, readwrite) UIView<CAKAlbumBottomViewProtocol> *selectedAssetsBottomView;

@property (nonatomic, assign) CGFloat statusBarHeightDelta;

@property (nonatomic, assign) BOOL hasCheckedAndReload;

@property (nonatomic, weak) UICollectionViewCell *selectedCell;
@property (nonatomic, assign) NSInteger selectedCellIndex;

@property (nonatomic, strong) PHFetchResult *fetchResult;


//new
@property (nonatomic, strong) UIView<CAKAlbumNavigationViewProtocol> *customNavigationView;

@property (nonatomic, assign) BOOL hasRegisterPhotoChangeObserver;

@end

@implementation CAKAlbumViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.viewModel = [[CAKAlbumViewModel alloc] init];
    [self.viewModel setPrefetchData:self.prefetchData];
    self.viewModel.fetchIcloudStartBlock = ^{
        [CAKToastShow() showToast:CAKLocalizedString(@"creation_icloud_download", @"Syncing from iCloud...")];
    };
    self.viewModel.fetchIcloudErrorBlock = ^(NSDictionary * _Nonnull info) {
        if (!info) {
            [CAKToastShow() showToast:CAKLocalizedString(@"creation_icloud_fail", @"Couldn't sync some items from iCloud")];
            return;
        }
        
        id errorObject = [info objectForKey:PHImageErrorKey];
        if (!errorObject || ![errorObject isKindOfClass:[NSError class]]) {
            [CAKToastShow() showToast:CAKLocalizedString(@"creation_icloud_fail", @"Couldn't sync some items from iCloud")];
            return;
        }
        
        NSError *error = errorObject;
        if (kICloudDiskSpaceLowErrorCode == error.code) {
            [CAKToastShow() showToast:CAKLocalizedString(@"error_param", @"An error occurred")];
        } else {
            [CAKToastShow() showToast:CAKLocalizedString(@"creation_icloud_fail", @"Couldn't sync some items from iCloud")];
        }
    };
    [self p_setupUIConfig];
    [self p_setupUI];
    [self bindViewModel];
    [self addPhotoLibraryChangeObserver];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_enterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    self.view.backgroundColor = CAKResourceColor(ACCUIColorConstBGContainer);
    // fetch album category list
    if (!([CAKPhotoManager isiOS14PhotoNotDetermined] && self.viewModel.listViewConfig.enableiOS14AlbumAuthorizationGuide)) {
        [self prefetchAlbumList];
    }
    if ([self.delegate respondsToSelector:@selector(albumViewControllerDidLoad:)]) {
        [self.delegate albumViewControllerDidLoad:self];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([self.delegate respondsToSelector:@selector(albumViewControllerDidAppear:)]) {
        [self.delegate albumViewControllerDidAppear:self];
    }
}

- (void)bindViewModel
{
    @weakify(self);
    [self.KVOController observe:self.viewModel.albumDataModel keyPath:@"mixedSelectAssetsModels" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        if (self.viewModel.enableSelectedAssetsView) {
            self.selectedAssetsView.assetModelArray = self.viewModel.currentSelectAssetModels;
            [self.selectedAssetsView reloadSelectView];
            if ([self.selectedAssetsView respondsToSelector:@selector(currentSelectViewHighlightIndex)]) {
                [self.viewModel updateCurrentInsertIndex:[self.selectedAssetsView currentSelectViewHighlightIndex]];
            }
            if ([self.selectedAssetsView respondsToSelector:@selector(currentNilIndexArray)]) {
                [self.viewModel updateNilIndexArray:[self.selectedAssetsView currentNilIndexArray]];
            }
            if (self.viewModel.hasSelectedAssets) {
                [self showSelectedAssetsViewIfNeed];
                [self showSelectedAssetsBottomViewIfNeed];
            } else {
                [self hideSelectedAssetsViewIfNeed];
                [self hideSelectedAssetsBottomViewIfNeed];
            }
        }
    }];
    
    [self.KVOController observe:self.viewModel.albumDataModel keyPath:@"videoSelectAssetsModels" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        if (!self.viewModel.listViewConfig.enableMixedUpload) {
            self.selectedAssetsView.assetModelArray = self.viewModel.albumDataModel.videoSelectAssetsModels;
            [self.selectedAssetsView reloadSelectView];
            
            if (self.viewModel.hasSelectedAssets) {
                [self showSelectedAssetsViewIfNeed];
                [self showSelectedAssetsBottomViewIfNeed];
            } else {
                [self hideSelectedAssetsViewIfNeed];
                [self hideSelectedAssetsBottomViewIfNeed];
            }
        }
        [self updateTitleForButton:self.selectedAssetsBottomView.nextButton];
    }];
    
    [self.KVOController observe:self.viewModel.albumDataModel keyPath:@"photoSelectAssetsModels" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        if (!self.viewModel.listViewConfig.enableMixedUpload) {
            self.selectedAssetsView.assetModelArray = self.viewModel.albumDataModel.photoSelectAssetsModels;
            [self.selectedAssetsView reloadSelectView];
            
            if (self.viewModel.hasSelectedAssets) {
                [self showSelectedAssetsViewIfNeed];
                [self showSelectedAssetsBottomViewIfNeed];
            } else {
                [self hideSelectedAssetsViewIfNeed];
                [self hideSelectedAssetsBottomViewIfNeed];
            }
        }
        [self updateTitleForButton:self.selectedAssetsBottomView.nextButton];
    }];
    
    [self.KVOController observe:self.viewModel.albumDataModel keyPath:@"allAlbumModels" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        [self.albumListTableView reloadData];
    }];
    
    [self.KVOController observe:self.viewModel.listViewConfig keyPath:@keypath(self.viewModel.listViewConfig, shouldShowiOS14GoSettingStrip) options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        BOOL shouldShow = [change acc_boolValueForKey:NSKeyValueChangeNewKey];
        if (shouldShow && ![CAKAlbumGoSettingStrip closedByUser]) {
            self.goSettingStrip.hidden = NO;
            self.slidingViewController.view.frame = [self listViewControllerFrame];
            if ([self.delegate respondsToSelector:@selector(albumViewController:didShowRequestAccessHintView:)]) {
                [self.delegate albumViewController:self didShowRequestAccessHintView:self.goSettingStrip];
            }
        } else {
            self.goSettingStrip.hidden = YES;
            self.slidingViewController.view.frame = [self listViewControllerFrame];
        }
    }];

    [self.KVOController observe:self.viewModel keyPath:@keypath(self.viewModel, initialSelectedAssetsSynchronized) options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        BOOL finishedSynchronization = [change acc_boolValueForKey:NSKeyValueChangeNewKey];
        if (finishedSynchronization) {
            CAKAlbumListViewController *listVC = [self currentAlubmListViewController];
            [listVC reloadVisibleCell];
        }
    }];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    PHAuthorizationStatus authorizationStatus = [PHPhotoLibrary authorizationStatus];
    if (authorizationStatus == PHAuthorizationStatusAuthorized && self.hasRegisterPhotoChangeObserver) {
        [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    }
    
    if ([self.delegate respondsToSelector:@selector(albumViewControllerDealloc:)]) {
        [self.delegate albumViewControllerDealloc:self];
    }
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    acc_dispatch_main_async_safe(^{
        [self prefetchAlbumList];
    });
}

- (void)addPhotoLibraryChangeObserver
{
    if (!self.hasRegisterPhotoChangeObserver) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            PHAuthorizationStatus authorizationStatus = [PHPhotoLibrary authorizationStatus];
            if (authorizationStatus == PHAuthorizationStatusAuthorized) {
                [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
                self.hasRegisterPhotoChangeObserver = YES;
            }
        });
    }
}

- (UIViewController<CAKAlbumListViewControllerProtocol> *)currentAlbumListViewController
{
    UIViewController<CAKAlbumListViewControllerProtocol> *vc = [self.slidingViewController.currentViewControllers acc_objectAtIndex:self.slidingViewController.selectedIndex];
    return vc;
}

#pragma mark - Layout

- (BOOL)p_shouldShowSelectedAssetsViewWithListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC
{
    if (!self.viewModel.enableSelectedAssetsView) {
        return NO;
    }
    if (!listVC.tabConfig.enableMultiSelect) {
        return NO;
    }
    BOOL shouldHideSelectedViewWhenNotSelect = self.viewModel.selectedAssetsViewConfig.shouldHideSelectedAssetsViewWhenNotSelect;
    BOOL currentTabEnableSelectedViewShow = listVC.enableSelectedAssetsViewShow;
    
    if (!currentTabEnableSelectedViewShow) {
        return NO;
    }
    
    if (shouldHideSelectedViewWhenNotSelect) {
        return self.viewModel.hasSelectedAssets;
    }
    
    return YES;
}

- (BOOL)p_shouldShowBottomViewWithListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC
{
    if (!self.viewModel.enableBottomView) {
        return NO;
    }
    if (!listVC.tabConfig.enableMultiSelect && !self.viewModel.bottomViewConfig.enableSwitchMultiSelect) {
        return NO;
    }

    BOOL shouldHideBottomViewWhenNotSelect = self.viewModel.bottomViewConfig.shouldHideBottomViewWhenNotSelect;
    BOOL currentTabEnableBottomViewShow = listVC.enableBottomViewShow;
    if (!currentTabEnableBottomViewShow) {
        return NO;
    }
    if (shouldHideBottomViewWhenNotSelect) {
        return self.viewModel.hasSelectedAssets;
    }
    
    return YES;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    /*
    When the status bar is hidden due to certain scenes (Another fullscreen style modal presented VC dismiss), cornerBarNaviController.view.frame.origin.y Was incorrectly set to Zero. The problem that caused the view and the system status bar to overlap
    */
    if (self.navigationController.view.frame.origin.y < ACC_STATUS_BAR_HEIGHT) {
        CGRect frame = self.navigationController.view.frame;
        CGFloat delta = ACC_STATUS_BAR_HEIGHT - frame.origin.y;
        frame.origin.y += delta;
        frame.size.height -= delta;
        self.navigationController.view.frame = frame;
    }
    self.viewWrapper.frame = CGRectMake(0, [self p_albumNavHeight], ACC_SCREEN_WIDTH, self.view.acc_height - [self p_albumNavHeight]);
    self.slidingViewController.view.frame = [self listViewControllerFrame];
    self.selectedAssetsBottomView.frame = CGRectMake(0, self.viewWrapper.acc_height - [self p_selectedAssetsBottomViewHeight] - self.statusBarHeightDelta, self.view.bounds.size.width, [self p_selectedAssetsBottomViewHeight]);
    if (self.viewModel.hasSelectedAssets) {
        self.selectedAssetsView.frame = CGRectMake(0, self.viewWrapper.acc_height - [self p_selectedAssetsViewHeight] - [self p_selectedAssetsBottomViewHeight] - self.statusBarHeightDelta, self.view.acc_width, [self p_selectedAssetsViewHeight]);
    } else {
        self.selectedAssetsView.frame = CGRectMake(0, self.viewWrapper.acc_height - [self p_selectedAssetsBottomViewHeight] - self.statusBarHeightDelta, self.view.bounds.size.width, [self p_selectedAssetsViewHeight]);
    }
    
    if ([self p_shouldShowSelectedAssetsViewWithListVC:self.viewModel.currentSelectedListVC]) {
        [self showSelectedAssetsView];
        self.selectedAssetsView.hidden = NO;
    } else {
        self.selectedAssetsView.hidden = YES;
    }
    
    if ([self p_shouldShowBottomViewWithListVC:self.viewModel.currentSelectedListVC]) {
        self.selectedAssetsBottomView.hidden = NO;
    } else {
        self.selectedAssetsBottomView.hidden = YES;
    }

    if (_requestAccessView) {
        [self.requestAccessView.superview bringSubviewToFront:self.requestAccessView];
    }
}

#pragma mark - UI config
- (UIView<CAKAlbumNavigationViewProtocol> *)navigationView
{
    if (self.customNavigationView != nil) {
        return self.customNavigationView;
    }
    return self.defaultNavigationView;
}


- (CGFloat)p_albumNavHeight {
    if (self.viewModel.enableNavigationView) {
        return self.viewModel.navigationViewHeight;
    }
    return 0;
}

- (CGFloat)p_selectedAssetsBottomViewHeight {
    if (self.viewModel.enableBottomView) {
        return self.viewModel.bottomViewHeight + ACC_IPHONE_X_BOTTOM_OFFSET;
    }
    return 0;
}

- (CGFloat)p_selectedAssetsViewHeight {
    if (self.viewModel.enableSelectedAssetsView) {
        return self.viewModel.selectedAssetsViewHeight;
    }
    return 0;
}

- (CGFloat)p_horizontalInset {
    return self.viewModel.listViewConfig.horizontalInset;
}

#pragma mark - UI
- (void)p_setupUIConfig
{
    [self p_setupListViewControllerConfig];
    [self p_setupNavigationViewConfig];
    [self p_setupSelectedAssetsViewConfig];
    [self p_setupBottomViewConfig];
}

- (void)p_setupUI
{
    [self setupSlidingViewController];
    [self p_setupNavigationView];
    [self p_setupViewWrapper];
    [self setupGoSettingStrip];
    
    [self showSlidingTabViewRedDotIfNeeded];
    [self setupRequestAccessView];
}

- (void)p_setupNavigationViewConfig
{
    if ([self.dataSource respondsToSelector:@selector(albumViewControllerHiddenForHeader:)]) {
        self.viewModel.enableNavigationView = ![self.dataSource albumViewControllerHiddenForHeader:self];
    }
    
    if (!self.viewModel.enableNavigationView) {
        return;
    }
    
    if ([self.dataSource respondsToSelector:@selector(albumViewControllerHeightForHeader:)]) {
        self.viewModel.navigationViewHeight = [self.dataSource albumViewControllerHeightForHeader:self];
    }
    if ([self.dataSource respondsToSelector:@selector(albumViewControllerConfigForHeader:)]) {
        self.viewModel.navigationViewConfig = [self.dataSource albumViewControllerConfigForHeader:self];
    }
}

- (void)p_setupSelectedAssetsViewConfig
{
    if ([self.dataSource respondsToSelector:@selector(albumViewControllerHiddenForSelectedAssetsView:)]) {
        self.viewModel.enableSelectedAssetsView = ![self.dataSource albumViewControllerHiddenForSelectedAssetsView:self];
    }
    
    if ([self.dataSource respondsToSelector:@selector(albumViewControllerHeightForSelectedAssetsView:)]) {
        self.viewModel.selectedAssetsViewHeight = [self.dataSource albumViewControllerHeightForSelectedAssetsView:self];
    }
    
    if ([self.dataSource respondsToSelector:@selector(albumViewControllerConfigForSelectedAssetsView:)]) {
        self.viewModel.selectedAssetsViewConfig = [self.dataSource albumViewControllerConfigForSelectedAssetsView:self];
    }
}

- (void)p_setupBottomViewConfig
{
    //footer
    if ([self.dataSource respondsToSelector:@selector(albumViewControllerHiddenForFooter:)]) {
        self.viewModel.enableBottomView = ![self.dataSource albumViewControllerHiddenForFooter:self];
    }
    
    if (!self.viewModel.enableBottomView) {
        return;
    }
    
    if ([self.dataSource respondsToSelector:@selector(albumViewControllerHeightForFooter:)]) {
        self.viewModel.bottomViewHeight = [self.dataSource albumViewControllerHeightForFooter:self];
    }
    
    if ([self.dataSource respondsToSelector:@selector(albumViewControllerConfigForFooter:)]) {
        self.viewModel.bottomViewConfig = [self.dataSource albumViewControllerConfigForFooter:self];
    }
}

- (void)p_setupNavigationView {
    if (!self.viewModel.enableNavigationView) {
        return;
    }
    
    if ([self.dataSource respondsToSelector:@selector(albumViewControllerViewForHeader:)]) {
        self.customNavigationView = [self.dataSource albumViewControllerViewForHeader:self];
        [self.customNavigationView.closeButton addTarget:self action:@selector(cancelBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if (self.customNavigationView != nil) {
        self.customNavigationView.frame = CGRectMake(0, 0, self.view.acc_width, [self p_albumNavHeight]);
        [self.view addSubview:self.customNavigationView];
    } else {
        [self.view addSubview:self.defaultNavigationView];
        self.defaultNavigationView.closeButton.hidden = self.viewModel.navigationViewConfig.hiddenCancelButton;
        if (self.viewModel.cameraRoolCollection) {
            self.defaultNavigationView.selectAlbumButton.leftLabel.text = self.viewModel.cameraRoolCollection.localizedTitle;
        } else {
            self.defaultNavigationView.selectAlbumButton.leftLabel.text = self.viewModel.navigationViewConfig.titleText;
        }

        if (self.viewModel.navigationViewConfig.enableBlackStyle) {
            [self p_setupBlackStyleNavView];
        }
    }
    
}

- (void)p_setupListViewControllerConfig
{
    //list
    if ([self.dataSource respondsToSelector:@selector(listViewConfigForAlbumViewController:)]) {
        self.viewModel.listViewConfig = [self.dataSource listViewConfigForAlbumViewController:self];
    }
    
    if ([self.dataSource respondsToSelector:@selector(albumListViewControllersDataSource:)]) {
        NSMutableArray<UIViewController<CAKAlbumListViewControllerProtocol> *> *mutableArray = [self.viewModel.tabsInfo mutableCopy];
        [mutableArray addObjectsFromArray:[self.dataSource albumListViewControllersDataSource:self]];
        self.viewModel.tabsInfo = mutableArray.copy;
    }
    
    [self.viewModel.tabsInfo enumerateObjectsUsingBlock:^(UIViewController<CAKAlbumListViewControllerProtocol> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.vcDelegate = self;
    }];
    
    @weakify(self);
    self.viewModel.fetchIcloudCompletion = ^(NSTimeInterval duration, NSInteger size) {
        @strongify(self);
        if ([self.delegate respondsToSelector:@selector(albumViewController:didFinishFetchICloudWithDuration:size:)]) {
            [self.delegate albumViewController:self didFinishFetchICloudWithDuration:duration size:size];
        }
    };
}

- (void)p_setupBlackStyleNavView
{
    [self.defaultNavigationView setBackgroundColor:[UIColor blackColor]];
    [self.defaultNavigationView.selectAlbumButton.leftLabel setTextColor:[UIColor whiteColor]];
    [self.defaultNavigationView.selectAlbumButton.rightImageView setTintColor:[UIColor whiteColor]];
    [self.defaultNavigationView.selectAlbumButton.rightImageView setImage:CAKResourceImage(@"medium_reward_album_down")];
}

- (void)prefetchAlbumList
{
    @weakify(self);
    [self.viewModel prefetchAlbumListWithCompletion:^{
        @strongify(self);
        [self.albumListTableView reloadData];
    }];
}

- (void)setupSlidingViewController
{
    self.viewWrapper = [[UIView alloc] initWithFrame:CGRectMake(0, [self p_albumNavHeight], ACC_SCREEN_WIDTH, self.view.acc_height - [self p_albumNavHeight])];
    self.viewWrapper.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.viewWrapper];
    
    self.slidingTabView.frame = CGRectMake(0, 0, self.view.acc_width, kAlbumTitleTabHight);
    [self.viewWrapper addSubview:self.slidingTabView];

    self.slidingViewController.view.frame = [self listViewControllerFrame];
    [self.viewWrapper addSubview:self.slidingViewController.view];
    [self addChildViewController:self.slidingViewController];
    [self.slidingViewController didMoveToParentViewController:self];
    [self.slidingViewController reloadViewControllers];
    self.slidingViewController.selectedIndex = self.viewModel.defaultSelectedIndex;
}

- (void)setupGoSettingStrip
{
    
    // goSettingStrip
    CGFloat goSettingStripOffsetY = [self shouldShowAlbumTabView] ? 48 : 0;
    self.goSettingStrip = [[CAKAlbumGoSettingStrip alloc] initWithFrame:CGRectMake(0, goSettingStripOffsetY, self.view.acc_width, 40)];
    [self.viewWrapper addSubview:self.goSettingStrip];
    UITapGestureRecognizer *labelTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goSettingStripLabelClicked)];
    [self.goSettingStrip.label addGestureRecognizer:labelTapGesture];
    [self.goSettingStrip.closeButton addTarget:self action:@selector(goSettingStripCloseButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    // whether show goSettingStrip or not is controlled by ACCAlbumConfigViewModel.shouldShowGoSettingStrip
    self.goSettingStrip.hidden = YES;
}

- (void)p_setupViewWrapper
{
    [self p_setupSelectedAssetsView];
    [self p_setupBottomView];
    [self p_setupBottomViewForPreviewPage];

    if ([self p_shouldShowSelectedAssetsViewWithListVC:self.viewModel.currentSelectedListVC]) {
        [self showSelectedAssetsView];
        if (self.selectedAssetsView) {
            [self.selectedAssetsView.superview bringSubviewToFront:self.selectedAssetsView];
        }
    }
}

- (void)p_setupSelectedAssetsView
{
    if (!self.viewModel.enableSelectedAssetsView) {
        return;
    }
    
    if ([self.dataSource respondsToSelector:@selector(albumViewControllerViewForSelectedAssets:)]) {
        self.selectedAssetsView = [self.dataSource albumViewControllerViewForSelectedAssets:self];
    }
    
    if (!self.selectedAssetsView) {
        self.selectedAssetsView = [[CAKAlbumSelectedAssetsView alloc] init];
        if ([self.selectedAssetsView respondsToSelector:@selector(enableDrageToMoveAssets:)]) {
            [self.selectedAssetsView enableDrageToMoveAssets:self.viewModel.selectedAssetsViewConfig.enableDragToMoveForSelectedAssetsView];
        }
    }

    if ([self.selectedAssetsView respondsToSelector:@selector(setShouldAdjustPreviewPage:)]) {
        self.selectedAssetsView.shouldAdjustPreviewPage = self.viewModel.selectedAssetsViewConfig.enableSelectedAssetsViewForPreviewPage;
    }
    
    if ([self.dataSource respondsToSelector:@selector(albumViewControllerViewForSelectedAssetsInPreviewPage:)]) {
        self.viewModel.customAssetsViewForPreviewPage = [self.dataSource albumViewControllerViewForSelectedAssetsInPreviewPage:self];
    }
    
    if ([self.selectedAssetsView respondsToSelector:@selector(setSourceType:)]) {
        self.selectedAssetsView.sourceType = CAKAlbumEventSourceTypeAlbumPage;
    }
    
    self.selectedAssetsView.frame = CGRectMake(0, self.view.acc_height - [self p_selectedAssetsBottomViewHeight], self.view.bounds.size.width, [self p_selectedAssetsViewHeight]);
    self.selectedAssetsView.backgroundColor = CAKResourceColor(ACCUIColorConstBGContainer2);
    self.selectedAssetsView.assetModelArray = self.viewModel.currentSelectAssetModels;
    if ([self.selectedAssetsView respondsToSelector:@selector(updateCheckMaterialRepeatSelect:)]) {
        [self.selectedAssetsView updateCheckMaterialRepeatSelect:self.viewModel.listViewConfig.enableAssetsRepeatedSelect];
    }
    @weakify(self);
    if ([self.selectedAssetsView respondsToSelector:@selector(setChangeOrderBlock:)]) {
        self.selectedAssetsView.changeOrderBlock = ^(CAKAlbumAssetModel * _Nonnull assetModel) {
            @strongify(self);
            [self handleChangeOrder];
            if ([self.delegate respondsToSelector:@selector(albumViewController:selectedAssetsViewDidChangeOrderWithAsset:sourceType:)]) {
                [self.delegate albumViewController:self selectedAssetsViewDidChangeOrderWithAsset:assetModel sourceType:CAKAlbumEventSourceTypeAlbumPage];
            }
        };
    }
    self.selectedAssetsView.deleteAssetModelBlock = ^(CAKAlbumAssetModel * _Nonnull assetModel) {
        @strongify(self);
        [self.viewModel didUnselectedAsset:assetModel];
        [self hideSelectedAssetsViewIfNeed];
        [self hideSelectedAssetsBottomViewIfNeed];
        CAKAlbumListViewController *listVC = [self currentAlubmListViewController];
        [listVC reloadVisibleCell];
        [self updateTitleForButton:self.selectedAssetsBottomView.nextButton];
        if ([self.delegate respondsToSelector:@selector(albumViewController:selectedAssetsViewDidDeleteAsset:sourceType:)]) {
            [self.delegate albumViewController:self selectedAssetsViewDidDeleteAsset:assetModel sourceType:CAKAlbumEventSourceTypeAlbumPage];
        }
    };
    
    if ([self.selectedAssetsView respondsToSelector:@selector(setTouchAssetModelBlock:)]) {
        self.selectedAssetsView.touchAssetModelBlock = ^(CAKAlbumAssetModel * _Nonnull assetModel) {
            @strongify(self);
            
            if ([self previewAndMultiSelectTypeWithCurrentListVC] == CAKAlbumPreviewAndMultiSelectTypeEnableMultiSelectDisablePreview) {
                return;
            }
            if ([self.delegate respondsToSelector:@selector(albumViewController:selectedAssetsViewDidClickAsset:sourceType:)]) {
                [self.delegate albumViewController:self selectedAssetsViewDidClickAsset:assetModel sourceType:CAKAlbumEventSourceTypeAlbumPage];
            }
            
            if (CAKAlbumAssetModelMediaTypePhoto == assetModel.mediaType) {
                PHAsset *phAsset = assetModel.phAsset;
                [CAKPhotoManager getUIImageWithPHAsset:phAsset networkAccessAllowed:NO progressHandler:^(CGFloat progress, NSError * _Nonnull error, BOOL * _Nonnull stop, NSDictionary * _Nonnull info) {
                    
                } completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                    @strongify(self)
                    if ([[info objectForKey:PHImageResultIsInCloudKey] boolValue]) {
                        NSTimeInterval icloudFetchStart = CFAbsoluteTimeGetCurrent();
                        [CAKPhotoManager getOriginalPhotoDataFromICloudWithAsset:assetModel.phAsset progressHandler:^(CGFloat progress, NSError * _Nonnull error, BOOL * _Nonnull stop, NSDictionary * _Nonnull info) {
                            
                        } completion:^(NSData *data, NSDictionary *info) {
                            if (data) {
                                @strongify(self);
                                NSTimeInterval duration = (NSInteger)((CFAbsoluteTimeGetCurrent() - icloudFetchStart) * 1000);
                                if ([self.delegate respondsToSelector:@selector(albumViewController:didFinishFetchICloudWithDuration:size:)]) {
                                    [self.delegate albumViewController:self didFinishFetchICloudWithDuration:duration size:[data length]];
                                }
                            }
                        }];
                        [CAKToastShow() showToast:CAKLocalizedString(@"creation_icloud_download", @"Syncing from iCloud...")];
                    } else {
                        if (!isDegraded && photo) {
                            [self p_previewWithAsset:assetModel isFromBottomView:YES resourceType:AWEGetResourceTypeImageAndVideo];
                        }
                    }
                }];
            } else if (CAKAlbumAssetModelMediaTypeVideo == assetModel.mediaType) {
                [self p_previewWithAsset:assetModel isFromBottomView:YES resourceType:AWEGetResourceTypeImageAndVideo];
            }
        };
    }
    UIView *seperatorLineView = [[UIView alloc] init];
    seperatorLineView.backgroundColor = CAKResourceColor(ACCColorLineReverse2);
    [self.selectedAssetsView addSubview:seperatorLineView];
    ACCMasMaker(seperatorLineView, {
        make.top.leading.trailing.equalTo(self.selectedAssetsView);
        make.height.equalTo(@(0.5));
    });
    [self.viewWrapper addSubview:self.selectedAssetsView];
    
    if (![self p_shouldShowSelectedAssetsViewWithListVC:self.viewModel.currentSelectedListVC]) {
        self.selectedAssetsView.hidden = YES;
    }
}

- (void)p_switchMultiSelect:(BOOL)selected
{
    // clear selected assets
    [self.viewModel clearSelectedAssetsArray];
    [self.selectedAssetsView reloadSelectView];
    [self hideSelectedAssetsViewIfNeed];
    [self updateTitleForButton:self.selectedAssetsBottomView.nextButton];

    // currentViewControllers 含有 NSNull，无法使用 vc.tabConfig
    NSArray<CAKAlbumListTabConfig *> *tabConfigs = @[
        self.viewModel.listViewConfig.mixedAssetsTabConfig,
        self.viewModel.listViewConfig.photoAssetsTabConfig,
        self.viewModel.listViewConfig.videoAssetsTabConfig,
    ];
    [tabConfigs enumerateObjectsUsingBlock:^(CAKAlbumListTabConfig *obj, NSUInteger idx, BOOL *stop) {
        obj.enableMultiSelect = selected;
        obj.enablePreview = selected;
    }];

    [self.slidingViewController.currentViewControllers enumerateObjectsUsingBlock:^(UIViewController<CAKAlbumListViewControllerProtocol> *obj, NSUInteger idx, BOOL *stop) {
        if ([obj respondsToSelector:@selector(updateAssetsMultiSelectMode)]) {
            [obj updateAssetsMultiSelectMode];
        }
    }];

    if ([self.delegate respondsToSelector:@selector(albumViewController:didSwitchMultiSelect:)]) {
        [self.delegate albumViewController:self didSwitchMultiSelect:selected];
    }
}

- (void)p_setupBottomView
{
    if (!self.viewModel.enableBottomView) {
        return;
    }
    
    if ([self.dataSource respondsToSelector:@selector(albumViewControllerViewForFooter:)]) {
        self.selectedAssetsBottomView = [self.dataSource albumViewControllerViewForFooter:self];
    }
    
    if (!self.selectedAssetsBottomView) {
        if (self.viewModel.bottomViewConfig.enableSwitchMultiSelect) {
            @weakify(self);
            self.selectedAssetsBottomView = [[CAKAlbumSwitchBottomView alloc] initWithSwitchBlock:^(BOOL selected) {
                @strongify(self);
                [self p_switchMultiSelect:selected];
            } multiSelect:self.viewModel.currentSelectedListVC.tabConfig.enableMultiSelect];
        } else {
            self.selectedAssetsBottomView = [[CAKAlbumSelectedAssetsBottomView alloc] init];
        }
    }
    
    [self.selectedAssetsBottomView.nextButton addTarget:self
                                                 action:@selector(nextButtonClicked:)
                                       forControlEvents:UIControlEventTouchUpInside];
    
    self.selectedAssetsBottomView.frame = CGRectMake(0, self.viewWrapper.acc_height - [self p_selectedAssetsBottomViewHeight] - self.statusBarHeightDelta, self.view.bounds.size.width, [self p_selectedAssetsBottomViewHeight]);
    self.selectedAssetsBottomView.backgroundColor = CAKResourceColor(ACCUIColorConstBGContainer2);
    [self.viewWrapper addSubview:self.selectedAssetsBottomView];
    
    [self updateTitleForButton:self.selectedAssetsBottomView.nextButton];
    
    NSString *title = [self p_defaultBottomTitleLabelText];
    if (self.viewModel.bottomViewConfig.titleLabelText.length > 0) {
        title = self.viewModel.bottomViewConfig.titleLabelText;
    }
    self.selectedAssetsBottomView.titleLabel.text = title;
    
    if (![self p_shouldShowBottomViewWithListVC:self.viewModel.currentSelectedListVC]) {
        self.selectedAssetsBottomView.hidden = YES;
    }
}

- (void)p_setupBottomViewForPreviewPage
{
    if ([self.dataSource respondsToSelector:@selector(albumViewControllerShouldShowBottomViewForPreviewPage:)]) {
        self.viewModel.enableBottomViewForPreviewPage = [self.dataSource albumViewControllerShouldShowBottomViewForPreviewPage:self];
    }
    
    if ([self.dataSource respondsToSelector:@selector(albumViewControllerHeightForPreviewFooter:)]) {
        self.viewModel.previewBottomViewHeight = [self.dataSource albumViewControllerHeightForPreviewFooter:self];
    }
    
    if ([self.dataSource respondsToSelector:@selector(albumViewControllerViewForBottomInPreviewPage:)]) {
        self.viewModel.customBottomViewForPreviewPage = [self.dataSource albumViewControllerViewForBottomInPreviewPage:self];
    }
}

- (void)setupDenyAccessView
{
    if ([self.dataSource respondsToSelector:@selector(albumViewControllerViewForiOS14DenyAccessView:)]) {
        self.denyAccessView = [self.dataSource albumViewControllerViewForiOS14DenyAccessView:self];
    }
    if (!self.denyAccessView) {
        self.denyAccessView = [[CAKAlbumDenyAccessView alloc] init];
    }
    self.denyAccessView.frame = CGRectMake(0, self.slidingTabView.acc_height, ACC_SCREEN_WIDTH, self.viewWrapper.acc_height - kAlbumTitleTabHight);
    
    [self.viewWrapper addSubview:self.denyAccessView];
    [self.viewWrapper bringSubviewToFront:self.denyAccessView];
    
    [self.denyAccessView.startSettingButton addTarget:self action:@selector(clickGoToSettingsButton:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupRequestAccessView
{
    if ([self.dataSource respondsToSelector:@selector(albumViewControllerViewForiOS14RequestAccessView:)]) {
        self.requestAccessView = [self.dataSource albumViewControllerViewForiOS14RequestAccessView:self];
    }
    
    if (!self.requestAccessView) {
        self.requestAccessView = [[CAKAlbumRequestAccessView alloc] init];
        
    }
    self.requestAccessView.frame = CGRectMake(0, self.slidingTabView.acc_height, ACC_SCREEN_WIDTH, self.viewWrapper.acc_height - kAlbumTitleTabHight);
    [self.requestAccessView.startSettingButton addTarget:self action:@selector(clickStartSettingsButton:) forControlEvents:UIControlEventTouchUpInside];
    
    if ([CAKPhotoManager isiOS14PhotoNotDetermined] && self.viewModel.listViewConfig.enableiOS14AlbumAuthorizationGuide) {
        [self.viewWrapper addSubview:self.requestAccessView];
        [self.viewWrapper bringSubviewToFront:self.requestAccessView];
    }
    
    if ([CAKPhotoManager authorizationStatus] == AWEAuthorizationStatusDenied && self.viewModel.listViewConfig.enableAlbumAuthorizationDenyAccessGuide) {
        [self setupDenyAccessView];
        [self.viewWrapper addSubview:self.denyAccessView];
        [self.viewWrapper bringSubviewToFront:self.denyAccessView];
    }
}

- (void)updateTitleForButton:(UIButton *)button
{
    [self updateTitleForButton:button fromPreview:NO];
}

- (void)updateTitleForButton:(UIButton *)button fromPreview:(BOOL)fromPreview
{
    if ([self.delegate respondsToSelector:@selector(albumViewController:updateBottomNextButtonWithButton:fromPreview:)]) {
        [self.delegate albumViewController:self updateBottomNextButtonWithButton:button fromPreview:fromPreview];
        return;
    }
    
    BOOL buttonEnable = NO;
    NSString *buttonTitle = @"";
    NSInteger totalSelectedAssetCount = self.viewModel.currentSelectAssetModels.count;
    
    buttonTitle = CAKLocalizedString(@"common_next", @"Next");
    if (totalSelectedAssetCount > 1) {
        buttonTitle = [NSString stringWithFormat:CAKLocalizedString(@"com_mig_next_zd_07oymg", @"Next (%zd)"), totalSelectedAssetCount];
    }
    buttonEnable = totalSelectedAssetCount >= self.viewModel.listViewConfig.minAssetsSelectionCount;
    
    [button setTitle:buttonTitle forState:UIControlStateNormal];
    [button setEnabled:buttonEnable];
    
    UIColor *buttonBgColor = buttonEnable ? CAKResourceColor(ACCUIColorConstPrimary) : CAKResourceColor(ACCColorBGInverse3);
    button.backgroundColor = buttonBgColor;
    
    CGSize sizeFits = [button sizeThatFits:CGSizeMake(MAXFLOAT, MAXFLOAT)];
    [UIView animateWithDuration:0.35f animations:^{
        ACCMasUpdate(button, {
            make.width.equalTo(@(sizeFits.width + 24));
        });
    }];
}

- (void)showSlidingTabViewRedDotIfNeeded
{
    @weakify(self);
    [self.viewModel doActionForAllListVC:^(UIViewController<CAKAlbumListViewControllerProtocol> * _Nonnull listVC, NSInteger index) {
        @strongify(self);
        [self p_updateSlidingTabViewRedDotWithListVC:listVC index:index];
    }];
}

- (void)p_updateSlidingTabViewRedDotWithListVC:(UIViewController *)viewController index:(NSInteger)index
{
    @weakify(self);
    if ([viewController conformsToProtocol:@protocol(CAKAlbumListViewControllerProtocol)] &&
        [viewController respondsToSelector:@selector(albumListShowTabDotIfNeed:)]) {
        [((UIViewController<CAKAlbumListViewControllerProtocol> *)viewController) albumListShowTabDotIfNeed:^(BOOL showDot, UIColor * _Nonnull color) {
             acc_dispatch_main_async_safe(^{
                 @strongify(self);
                 [self.slidingTabView showButtonDot:showDot index:index color:color];
             });
        }];
    }
}

- (void)handleChangeOrder
{
    self.selectedAssetsView.assetModelArray = self.viewModel.currentSelectAssetModels;
    [self.selectedAssetsView reloadSelectView];
    UIViewController *vc = [self currentAlbumListViewController];
    if ([vc isKindOfClass:[CAKAlbumListViewController class]]) {
        [((CAKAlbumListViewController *)vc) reloadVisibleCell];
    }
}

#pragma mark - Bottom SelectedAssetsView
- (void)showSelectedAssetsViewIfNeed
{
    if (![self p_shouldShowSelectedAssetsViewWithListVC:self.viewModel.currentSelectedListVC]) {
        return;
    }
    
    self.selectedAssetsView.hidden = NO;
    [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionLayoutSubviews animations:^{
        [self showSelectedAssetsView];
    } completion:nil];
}

- (void)hideSelectedAssetsViewIfNeed
{    
    if ([self p_shouldShowSelectedAssetsViewWithListVC:self.viewModel.currentSelectedListVC]) {
        return;
    }
    
    self.selectedAssetsView.hidden = YES;
    [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionLayoutSubviews animations:^{
        self.slidingViewController.view.frame = [self listViewControllerFrame];
        self.selectedAssetsView.frame = CGRectMake(0, self.viewWrapper.acc_height - [self p_selectedAssetsBottomViewHeight] - self.statusBarHeightDelta, self.view.bounds.size.width, [self p_selectedAssetsViewHeight]);
    } completion:nil];
}

- (void)showSelectedAssetsBottomViewIfNeed
{
    if (![self p_shouldShowBottomViewWithListVC:self.viewModel.currentSelectedListVC]) {
        return;
    }
    self.selectedAssetsBottomView.hidden = NO;
}

- (void)hideSelectedAssetsBottomViewIfNeed
{
    if ([self p_shouldShowBottomViewWithListVC:self.viewModel.currentSelectedListVC]) {
        return;
    }
    self.selectedAssetsBottomView.hidden = YES;
}

- (void)showSelectedAssetsView
{
    self.selectedAssetsView.frame = CGRectMake(0, self.viewWrapper.acc_height - [self p_selectedAssetsViewHeight] - [self p_selectedAssetsBottomViewHeight] - self.statusBarHeightDelta, self.view.acc_width, [self p_selectedAssetsViewHeight]);
    self.slidingViewController.view.frame = [self listViewControllerFrame];
}

- (CAKAlbumListViewController *)currentAlubmListViewController
{
    CAKAlbumListViewController *listViewController;
    UIViewController *viewController = [self.slidingViewController controllerAtIndex:self.slidingViewController.selectedIndex];
    if ([viewController isKindOfClass:[CAKAlbumListViewController class]]) {
        listViewController = (CAKAlbumListViewController *)viewController;
    }
    
    return listViewController;
}

#pragma mark - CAKAlbumSlidingViewControllerDelegate

- (NSInteger)numberOfControllers:(CAKAlbumSlidingViewController *)slidingController
{
    return self.viewModel.tabsInfo.count;
}

- (UIViewController *)slidingViewController:(CAKAlbumSlidingViewController *)slidingViewController viewControllerAtIndex:(NSInteger)index
{
    if (index >= 0 && index < self.viewModel.tabsInfo.count) {
        UIViewController<CAKAlbumListViewControllerProtocol> *listVC = [self.viewModel.tabsInfo acc_objectAtIndex:index];
        
        return listVC;
    }

    return nil;
}

- (void)slidingViewController:(CAKAlbumSlidingViewController *)slidingViewController didSelectIndex:(NSInteger)index
{
    UIViewController<CAKAlbumListViewControllerProtocol> *currentListVC = [self.slidingViewController.currentViewControllers acc_objectAtIndex:index];
    [self.viewModel updateCurrentSelectedIndex:index];
    if ([self.delegate respondsToSelector:@selector(albumViewController:didSelectTabListViewController:index:)]) {
        [self.delegate albumViewController:self didSelectTabListViewController:currentListVC index:index];
    }
}

- (void)slidingViewController:(CAKAlbumSlidingViewController *)slidingViewController willTransitionToViewController:(UIViewController *)pendingViewController
{
    UIViewController<CAKAlbumListViewControllerProtocol> *listVC;
    if ([pendingViewController conformsToProtocol:@protocol(CAKAlbumListViewControllerProtocol)]) {
        listVC = (UIViewController<CAKAlbumListViewControllerProtocol> *)pendingViewController;
    }
    if (listVC) {
        [self p_listViewControllerWillAppear:listVC];
    }
}

- (void)slidingViewController:(CAKAlbumSlidingViewController *)slidingViewController didFinishTransitionToIndex:(NSUInteger)index
{
    [self.viewModel updateCurrentSelectedIndex:index];
    UIViewController<CAKAlbumListViewControllerProtocol> *listVC;
    UIViewController *currentListVC = [self.slidingViewController.currentViewControllers acc_objectAtIndex:index];
    if ([currentListVC conformsToProtocol:@protocol(CAKAlbumListViewControllerProtocol)]) {
        listVC = (UIViewController<CAKAlbumListViewControllerProtocol> *)currentListVC;
    }
    if (listVC) {
        [self p_listViewControllerDidAppear:listVC];
    }
}

- (void)p_listViewControllerWillAppear:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC
{
    BOOL statusHasChanged = NO;
    if (![self p_shouldShowSelectedAssetsViewWithListVC:listVC] && !self.selectedAssetsView.isHidden) {
        self.selectedAssetsView.hidden = YES;
        statusHasChanged = YES;
    }
    
    if (![self p_shouldShowBottomViewWithListVC:listVC] && !self.selectedAssetsBottomView.isHidden) {
        self.selectedAssetsBottomView.hidden = YES;
        statusHasChanged = YES;
    }
    if (statusHasChanged) {
        self.slidingViewController.view.frame = [self listViewControllerFrameWithListViewController:listVC];
    }
}

- (void)p_listViewControllerDidAppear:(UIViewController<CAKAlbumListViewControllerProtocol> *)listViewController
{
    BOOL selectedAssetsViewAnimation = NO;
    BOOL selectedBottomViewAnimation = NO;
    if ([self p_shouldShowSelectedAssetsViewWithListVC:listViewController] && self.selectedAssetsView.hidden) {
        self.selectedAssetsView.alpha = 0.0;
        self.selectedAssetsView.hidden = NO;
        selectedAssetsViewAnimation = YES;
    }
    
    if ([self p_shouldShowBottomViewWithListVC:listViewController] && self.selectedAssetsBottomView.hidden) {
        self.selectedAssetsBottomView.alpha = 0.0;
        self.selectedAssetsBottomView.hidden = NO;
        selectedBottomViewAnimation = YES;
    }
    
    if (selectedAssetsViewAnimation || selectedBottomViewAnimation) {
        self.slidingViewController.view.frame = [self listViewControllerFrame];
        [UIView animateWithDuration:0.25 animations:^{
            self.selectedAssetsView.alpha = 1.0;
            self.selectedAssetsBottomView.alpha = 1.0;
        }];
    }
    self.slidingViewController.view.frame = [self listViewControllerFrame];
}

#pragma mark - CAKAlbumListViewControllerDelegate
- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC previewControllerSelectedAssetsViewDidClickAsset:(CAKAlbumAssetModel *)assetModel
{
    if ([self.delegate respondsToSelector:@selector(albumViewController:selectedAssetsViewDidClickAsset:sourceType:)]) {
        [self.delegate albumViewController:self selectedAssetsViewDidClickAsset:assetModel sourceType:CAKAlbumEventSourceTypePreviewPage];
    }
}

- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC previewControllerSelectedAssetsViewDidDeleteAsset:(CAKAlbumAssetModel *)assetModel
{
    if ([self.delegate respondsToSelector:@selector(albumViewController:selectedAssetsViewDidDeleteAsset:sourceType:)]) {
        [self.delegate albumViewController:self selectedAssetsViewDidDeleteAsset:assetModel sourceType:CAKAlbumEventSourceTypePreviewPage];
    }
}

- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC previewControllerDidLoadForAlbumAsset:(CAKAlbumAssetModel *)assetModel bottomView:(CAKAlbumPreviewPageBottomView *)bottomView
{
    if ([self.delegate respondsToSelector:@selector(albumViewController:previewControllerDidLoadForAlbumAsset:bottomView:)]) {
        [self.delegate albumViewController:self previewControllerDidLoadForAlbumAsset:assetModel bottomView:bottomView];
    }
}

- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC previewControllerScrollViewDidEndDeceleratingWithAlbumAsset:(CAKAlbumAssetModel *)asset
{
    if ([self.delegate respondsToSelector:@selector(albumViewController:previewControllerScrollViewDidEndDeceleratingWithAlbumAsset:)]) {
        [self.delegate albumViewController:self previewControllerScrollViewDidEndDeceleratingWithAlbumAsset:asset];
    }
}

- (void)albumListVCDidLoad:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC
{
    if ([self.delegate respondsToSelector:@selector(albumListViewControllerDidLoad:)]) {
        UIViewController<CAKAlbumListViewControllerProtocol> *listViewController = (UIViewController<CAKAlbumListViewControllerProtocol> *)listVC;
        [self.delegate albumListViewControllerDidLoad:listViewController];
    }
}

- (void)albumListVCWillAppear:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC
{
    if ([self.delegate respondsToSelector:@selector(albumListViewControllerWillAppear:)]) {
        UIViewController<CAKAlbumListViewControllerProtocol> *listViewController = (UIViewController<CAKAlbumListViewControllerProtocol> *)listVC;
        [self.delegate albumListViewControllerWillAppear:listViewController];
    }
}

- (void)albumListVCDidAppear:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC
{
    @weakify(self);
    [self.viewModel doActionForAllListVC:^(UIViewController<CAKAlbumListViewControllerProtocol> * _Nonnull listViewController, NSInteger index) {
        if (listViewController == listVC) {
            @strongify(self);
            NSInteger index = [self.viewModel.tabsInfo indexOfObject:listViewController];
            [self p_updateSlidingTabViewRedDotWithListVC:listViewController index:index];
        }
    }];
}

- (void)albumListVCWillDisappear:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC
{
    if ([self.delegate respondsToSelector:@selector(albumListViewControllerWillDisappear:)]) {
        UIViewController<CAKAlbumListViewControllerProtocol> *listViewController = (UIViewController<CAKAlbumListViewControllerProtocol> *)listVC;
        [self.delegate albumListViewControllerWillDisappear:listViewController];
    }
}

- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC didConfigCellForAsset:(CAKAlbumAssetModel *)assetModel
{
    if ([self.delegate respondsToSelector:@selector(albumViewController:didShowAlbumAssetCell:listViewController:)]) {
        [self.delegate albumViewController:self didShowAlbumAssetCell:assetModel listViewController:listVC];
    }
}

- (BOOL)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC shouldSelectAsset:(CAKAlbumAssetModel *)assetModel
{
    if ([self.delegate respondsToSelector:@selector(albumViewController:shouldSelectAlbumAsset:)]) {
        return [self.delegate albumViewController:self shouldSelectAlbumAsset:assetModel];
    }
    
    NSString *format = CAKLocalizedString(@"creation_upload_limit",@"Select up to %d items");
    if (self.viewModel.currentSelectedAssetsCount >= self.viewModel.listViewConfig.maxAssetsSelectionCount) {
        [CAKToastShow() showToast:[NSString stringWithFormat:format, self.viewModel.listViewConfig.maxAssetsSelectionCount]];
        return NO;
    }
    
    if (assetModel.mediaType == CAKAlbumAssetModelMediaTypePhoto && ![self p_validAssetModelForPhoto:assetModel]) {
        return NO;
    }
    
    if (assetModel.mediaType == CAKAlbumAssetModelMediaTypeVideo && ![self p_validAssetModelForVideo:assetModel]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)p_validAssetModelForPhoto:(CAKAlbumAssetModel *)assetModel
{
    CGFloat scale = (CGFloat)assetModel.phAsset.pixelWidth / (CGFloat)assetModel.phAsset.pixelHeight;
    if (scale >= 2.2 || scale <= 1.0 / 2.2) {
        [CAKToastShow() showToast:@"share_img_from_sys_size_error"];
        return NO;
    }
    
    return YES;
}

- (BOOL)p_validAssetModelForVideo:(CAKAlbumAssetModel *)assetModel
{
    PHAsset *phAsset = assetModel.phAsset;
    CGFloat duration = phAsset.duration;

    if (duration < self.viewModel.listViewConfig.videoSelectableMinSeconds) {
        NSString *minTimeTipDes = [NSString stringWithFormat:CAKLocalizedString(@"com_mig_cannot_select_video_shorter_than_0f_s", @"Cannot select video shorter than %.0f s"), self.viewModel.listViewConfig.videoSelectableMinSeconds];
        [CAKToastShow() showToast:minTimeTipDes];
        return NO;
    }
    
    if (duration > self.viewModel.listViewConfig.videoSelectableMaxSeconds) {
        [CAKToastShow() showToast:CAKLocalizedString(@"com_mig_video_is_too_long_try_another_one", @"Video is too long. Try another one.")];
        return NO;
    }
    
    return YES;
}

- (void)p_scrollAssetToVisible:(CAKAlbumAssetModel *)assetModel listVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC
{
    if ([listVC respondsToSelector:@selector(scrollAssetToVisible:)]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:listVC]; // 去除重复调用
        [listVC performSelector:@selector(scrollAssetToVisible:) withObject:assetModel afterDelay:0.26]; // 等 0.25 秒 frame 的动画之后，才能滚动
    }
}

- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC didSelectedAsset:(CAKAlbumAssetModel *)assetModel isFromPreview:(BOOL)isFromPreview
{
    CAKAlbumEventSourceType sourceType = isFromPreview ? CAKAlbumEventSourceTypePreviewPage : CAKAlbumEventSourceTypeAlbumPage;
    if ([self.delegate respondsToSelector:@selector(albumViewController:didSelectAlbumAsset:sourceType:)]) {
        [self.delegate albumViewController:self didSelectAlbumAsset:assetModel sourceType:sourceType];
    }
    [self updateTitleForButton:self.selectedAssetsBottomView.nextButton];

    [self p_scrollAssetToVisible:assetModel listVC:listVC];

    if (self.viewModel.hasSelectedAssets) {
        [self showSelectedAssetsViewIfNeed];
        [self showSelectedAssetsBottomViewIfNeed];
    } else {
        [self hideSelectedAssetsViewIfNeed];
        [self hideSelectedAssetsBottomViewIfNeed];
    }
}

- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC didDeselectAsset:(CAKAlbumAssetModel *)assetModel isFromPreview:(BOOL)isFromPreview
{
    CAKAlbumEventSourceType sourceType = isFromPreview ? CAKAlbumEventSourceTypePreviewPage : CAKAlbumEventSourceTypeAlbumPage;
    if ([self.delegate respondsToSelector:@selector(albumViewController:didDeselectAlbumAsset:sourceType:)]) {
        [self.delegate albumViewController:self didDeselectAlbumAsset:assetModel sourceType:sourceType];
    }
    [self updateTitleForButton:self.selectedAssetsBottomView.nextButton];

    [self p_scrollAssetToVisible:assetModel listVC:listVC];

    if (self.viewModel.hasSelectedAssets) {
        [self showSelectedAssetsViewIfNeed];
        [self showSelectedAssetsBottomViewIfNeed];
    } else {
        [self hideSelectedAssetsViewIfNeed];
        [self hideSelectedAssetsBottomViewIfNeed];
    }
}

- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC didClickedCell:(CAKAlbumAssetModel *)assetModel
{
    if (![listVC conformsToProtocol:@protocol(CAKAlbumListViewControllerProtocol)]) {
        return;
    }
    
    if (!assetModel) {
        return;
    }
    
    if ([self previewAndMultiSelectTypeWithCurrentListVC] == CAKAlbumPreviewAndMultiSelectTypeEnableMultiSelectDisablePreview) {
        return;
    }
    
    if ([self previewAndMultiSelectTypeWithCurrentListVC] == CAKAlbumPreviewAndMultiSelectTypeBothDisabled) {
        //not preview
        BOOL needFetch = NO;
        if ([self.dataSource respondsToSelector:@selector(albumViewControllerNeedFetchAlbumAssetsWhenClickNext:)]) {
            needFetch = [self.dataSource albumViewControllerNeedFetchAlbumAssetsWhenClickNext:self];
        }
        if (needFetch) {
            UIView<CAKTextLoadingViewProtocol> *loadingView = [CAKLoading() showLoadingOnView:self.view title:@"" animated:YES];
            [self.viewModel handleSelectedAssets:@[assetModel] completion:^(NSMutableArray<CAKAlbumAssetModel *> * _Nonnull assetArray) {
                [loadingView dismiss];
                if ([self.delegate respondsToSelector:@selector(albumViewController:didClickAlbumAssetCell:)]) {
                    [self.delegate albumViewController:self didClickAlbumAssetCell:assetArray.firstObject];
                }
            }];
        } else {
            if ([self.delegate respondsToSelector:@selector(albumViewController:didClickAlbumAssetCell:)]) {
                [self.delegate albumViewController:self didClickAlbumAssetCell:assetModel];
            }
        }
    }
}

- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC didFinishFetchIcloudWithFetchDuration:(NSTimeInterval)duration size:(NSInteger)size
{
    if ([self.delegate respondsToSelector:@selector(albumViewController:didFinishFetchICloudWithDuration:size:)]) {
        [self.delegate albumViewController:self didFinishFetchICloudWithDuration:duration size:size];
    }
}

- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC previewControllerDidClickNextButton:(UIButton *)btn
{
    [self nextButtonClicked:CAKAlbumEventSourceTypePreviewPage];
}

- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC previewControllerUpdateNextButtonTitle:(UIButton *)btn
{
    [self updateTitleForButton:btn fromPreview:YES];
}

- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC previewControllerSelectedAssetsViewDidChangeOrderWithAsset:(CAKAlbumAssetModel *)assetModel
{
    [self handleChangeOrder];
    if ([self.delegate respondsToSelector:@selector(albumViewController:selectedAssetsViewDidChangeOrderWithAsset:sourceType:)]) {
        [self.delegate albumViewController:self selectedAssetsViewDidChangeOrderWithAsset:assetModel sourceType:CAKAlbumEventSourceTypePreviewPage];
    }
}

- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC previewControllerWillBeginSetupPlayer:(AVPlayer *)player status:(NSInteger)status
{
    if ([self.delegate respondsToSelector:@selector(albumViewController:previewControllerWillBeginSetupPlayer:status:)]) {
        [self.delegate albumViewController:self previewControllerWillBeginSetupPlayer:player status:status];
    }
}

- (void)albumListVC:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC previewControllerDidEndZoomingWithIsZoomIn:(BOOL)isZoomIn asset:(nonnull CAKAlbumAssetModel *)asset
{
    if ([self.delegate respondsToSelector:@selector(albumViewController:previewControllerDidEndZoomingWithIsZoomIn:albumAsset:)]) {
        [self.delegate albumViewController:self previewControllerDidEndZoomingWithIsZoomIn:isZoomIn albumAsset:asset];
    }
}

- (void)albumListVCScrollSelectAssetViewToNext:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC
{
    if ([self.selectedAssetsView respondsToSelector:@selector(scrollToNextSelectCell)]) {
        [self.selectedAssetsView scrollToNextSelectCell];
    }
}

- (void)albumListVCUpdateEmptyCellForSelectedAssetView:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC
{
    if ([self.selectedAssetsView respondsToSelector:@selector(updateSelectViewOrderWithNilArray:)]) {
        [self.selectedAssetsView updateSelectViewOrderWithNilArray:self.viewModel.currentNilIndexArray];
    }
}

- (void)albumListVCEndPreview:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC
{
    if ([self.delegate respondsToSelector:@selector(albumViewControllerEndPreview:)]) {
        [self.delegate albumViewControllerEndPreview:self];
    }
}

- (void)albumListVCNeedShowAuthoritionDenyView:(UIViewController<CAKAlbumListViewControllerProtocol> *)listVC
{
    if ([CAKPhotoManager authorizationStatus] == AWEAuthorizationStatusDenied) {
        [self setupRequestAccessView];
        [self.viewWrapper layoutIfNeeded];
    }
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 88.0f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.viewModel.albumDataModel.allAlbumModels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CAKAlbumCategorylistCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CAKAlbumCategorylistCell"];
    if (indexPath.row < self.viewModel.albumDataModel.allAlbumModels.count) {
        CAKAlbumModel *albumModel = [self.viewModel.albumDataModel.allAlbumModels acc_objectAtIndex:indexPath.row];
        [cell configCellWithAlbumModel:albumModel];
        
        if (self.viewModel.listViewConfig.enableBlackStyle) {
            [cell configBlackBackgroundStyle];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CAKAlbumModel *albumModel = [self.viewModel.albumDataModel.allAlbumModels acc_objectAtIndex:indexPath.row];
    if (albumModel.localIdentifier) {
        [self.viewModel reloadAssetsDataWithAlbumCategory:albumModel completion:^{
        }];
    } else {
        [self.viewModel reloadAssetsDataWithAlbumCategory:nil completion:^{
        }];
    }
    
    [self didAlbumChanged:albumModel];
    [self dismissAlbumMenuViewAnimated:YES];
    if ([self.delegate respondsToSelector:@selector(albumViewController:didSelectAlbumModel:)]) {
        [self.delegate albumViewController:self didSelectAlbumModel:albumModel];
    }
}

#pragma mark - Notification

- (void)p_enterForeground:(NSNotification *)noti
{
    if ([CAKPhotoManager isiOS14PhotoNotDetermined] && self.viewModel.listViewConfig.enableiOS14AlbumAuthorizationGuide) {
        return;
    }
    acc_dispatch_main_async_safe(^{
        if ([self.delegate respondsToSelector:@selector(albumViewControllerPhotoLibraryDidChange:)]) {
            [self.delegate albumViewControllerPhotoLibraryDidChange:self];
        }
        [self prefetchAlbumList];
    });
}


#pragma mark - Preview

- (void)p_previewWithAsset:(CAKAlbumAssetModel *)model isFromBottomView:(BOOL)isFromBottomView resourceType:(AWEGetResourceType)resourceType
{
    UIViewController *viewController = [self currentAlbumListViewController];
    if ([viewController isKindOfClass:[CAKAlbumListViewController class]]) {
        [((CAKAlbumListViewController *)viewController) didSelectedToPreview:model coverImage:model.coverImage fromBottomView:isFromBottomView];
    }
}

#pragma mark - Action
#pragma mark -  goSettingStrip
- (void)goSettingStripCloseButtonClicked:(id)sender
{
    [CAKAlbumGoSettingStrip setClosedByUser];
    self.viewModel.listViewConfig.shouldShowiOS14GoSettingStrip = NO;
}

- (void)goSettingStripLabelClicked
{
    if ([self.delegate respondsToSelector:@selector(albumViewController:didClickRequestAccessHintViewStartSetting:)]) {
        [self.delegate albumViewController:self didClickRequestAccessHintViewStartSetting:self.goSettingStrip];
    }
    acc_dispatch_main_async_safe(^{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    });
}

#pragma mark - Button Action

- (void)clickGoToSettingsButton:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(albumViewController:didClickDenyAccessStartSettingButton:)]) {
        [self.delegate albumViewController:self didClickDenyAccessStartSettingButton:self.denyAccessView];
    }
    acc_dispatch_main_async_safe(^{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    });
}

- (void)clickStartSettingsButton:(id)sender
{
#ifdef __IPHONE_14_0 //xcode12
    if (@available(iOS 14.0, *)) {
        if ([CAKPhotoManager isiOS14PhotoNotDetermined]) {
            if ([self.delegate respondsToSelector:@selector(albumViewController:didClickRequestAccessStartSettingButton:currentStatus:)]) {
                [self.delegate albumViewController:self didClickRequestAccessStartSettingButton:self.requestAccessView currentStatus:PHAuthorizationStatusNotDetermined];
            }
            
            [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite handler:^(PHAuthorizationStatus status) {
                acc_dispatch_main_async_safe(^{
                    if ([self.delegate respondsToSelector:@selector(albumViewController:didRequestAlbumAuthorizationWithStatus:)]) {
                        [self.delegate albumViewController:self didRequestAlbumAuthorizationWithStatus:status];
                    }
                    switch (status) {
                        case PHAuthorizationStatusLimited: {
                            [self p_handleAuthWithShowGoSettingStrip:YES];
                            break;
                        }
                        case PHAuthorizationStatusAuthorized: {
                            [self p_handleAuthWithShowGoSettingStrip:NO];
                            break;
                        }
                        case PHAuthorizationStatusNotDetermined:
                        case PHAuthorizationStatusRestricted: {
                            break;
                        }
                        case PHAuthorizationStatusDenied: {
                            [self.requestAccessView removeFromSuperview];
                            [self setupDenyAccessView];
                            [self.viewWrapper layoutIfNeeded];
                            self.viewModel.hasRequestAuthorizationForAccessLevel = NO;
                            break;
                        }
                        default:
                          break;
                    }
                });
            }];
        } else if ([CAKPhotoManager isiOS14PhotoLimited]) {
            /** When we request for photo library access authorization (with a callback handler), the system will show a toast with three options. If the user chooses `select photos` (`选择照片` in CN), a PHPicker will be presented for photo selection.
             * The user may select any (or none) photos on PHPicker and perform three actions afterwards:
             * 1. Click complete button (on the top right corner).
             * 2. Click cancel button (on the top left corner).
             * 3. Directly swipe down to dismiss the PHPicker.
             * For action 3, our callback will not be executed, even though the user did grant us with Limited Photo Access permission, and we are handling this situation here.
             */
            if ([self.delegate respondsToSelector:@selector(albumViewController:didClickRequestAccessStartSettingButton:currentStatus:)]) {
                [self.delegate albumViewController:self didClickRequestAccessStartSettingButton:self.requestAccessView currentStatus:PHAuthorizationStatusLimited];
            }
            [self p_handleAuthWithShowGoSettingStrip:YES];
        }
    }
#endif
}

- (void)p_handleAuthWithShowGoSettingStrip:(BOOL)needShow
{
    [self addPhotoLibraryChangeObserver];
    [self.requestAccessView removeFromSuperview];
    [self prefetchAlbumList];
    if ([self.currentAlbumListViewController respondsToSelector:@selector(requestAuthorizationCompleted)]) {
        [self.currentAlbumListViewController requestAuthorizationCompleted];
    }
    
    [self.viewWrapper layoutIfNeeded];
    self.viewModel.hasRequestAuthorizationForAccessLevel = YES;
    self.viewModel.listViewConfig.shouldShowiOS14GoSettingStrip = needShow;
}


#pragma mark - Cancel Button

- (void)cancelBtnClicked:(UIButton *)button
{
    if ([self.delegate respondsToSelector:@selector(albumViewControllerDidClickCancelButton:)]) {
        [self.delegate albumViewControllerDidClickCancelButton:self];
    }

    if ([[self.navigationController viewControllers] firstObject] == self || !self.navigationController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Next Button
- (void)nextButtonClicked:(CAKAlbumEventSourceType)sourceType
{
    CAKAlbumEventSourceType source = CAKAlbumEventSourceTypeAlbumPage;
    if (sourceType == CAKAlbumEventSourceTypePreviewPage) {
        source = CAKAlbumEventSourceTypePreviewPage;
    }
    BOOL needFetch = NO;
    if ([self.dataSource respondsToSelector:@selector(albumViewControllerNeedFetchAlbumAssetsWhenClickNext:)]) {
        needFetch = [self.dataSource albumViewControllerNeedFetchAlbumAssetsWhenClickNext:self];
    }
    if (needFetch) {
        UIView<CAKTextLoadingViewProtocol> *loadingView = [CAKLoading() showLoadingOnView:self.view title:@"" animated:YES];
        [self.viewModel handleSelectedAssets:self.viewModel.currentSelectAssetModels completion:^(NSMutableArray<CAKAlbumAssetModel *> * _Nonnull assetArray) {
            [loadingView dismiss];
            if ([self.delegate respondsToSelector:@selector(albumViewController:didClickNextButtonWithSourceType:fetchedAlbumAssets:)]) {
                [self.delegate albumViewController:self didClickNextButtonWithSourceType:source fetchedAlbumAssets:assetArray];
            }
        }];
    } else {
        if ([self.delegate respondsToSelector:@selector(albumViewController:didClickNextButtonWithSourceType:fetchedAlbumAssets:)]) {
            [self.delegate albumViewController:self didClickNextButtonWithSourceType:source fetchedAlbumAssets:self.viewModel.currentSelectAssetModels];
        }
    }
    
}

#pragma mark - Album List TableView

- (BOOL)isAlbumMenuViewVisible
{
    return nil != self.albumListTableView;
}

- (void)showAlbumMenuViewOnView:(UIView *)view frame:(CGRect)frame animated:(BOOL)animated animationWillBeginBlock:(void(^)(BOOL success))beginBlock
{
    if (self.albumListTableView) {
        ACCBLOCK_INVOKE(beginBlock, NO);
        return;
    }
    self.albumListTableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    [self.albumListTableView registerClass:[CAKAlbumCategorylistCell class] forCellReuseIdentifier:@"CAKAlbumCategorylistCell"];
    self.albumListTableView.delegate = self;
    self.albumListTableView.dataSource = self;
    self.albumListTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.albumListTableView.tableFooterView = [UIView new];
    self.albumListTableView.contentInset = UIEdgeInsetsMake(8, 0, 0, 0);
    
    if (self.viewModel.listViewConfig.enableBlackStyle) {
        self.albumListTableView.backgroundColor = [UIColor blackColor];
    } else {
        self.albumListTableView.backgroundColor = CAKResourceColor(ACCUIColorConstBGContainer);
    }
    
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, frame.origin.y, ACC_SCREEN_WIDTH, 1.0 / ACC_SCREEN_SCALE)];
    line.backgroundColor = CAKResourceColor(ACCUIColorLineSecondary2);
    self.albumTopLine = line;
    
    view.accessibilityElements = @[self.defaultNavigationView, self.albumListTableView]; // tricky
    
    [view addSubview:self.albumListTableView];
    [view addSubview:line];
    if (beginBlock) {
        beginBlock(YES);
    }
    self.albumListTableView.transform = CGAffineTransformMakeTranslation(0, -self.view.bounds.size.height);
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self.defaultNavigationView.selectAlbumButton);
    [UIView animateWithDuration:0.25f animations:^{
        self.albumListTableView.transform = CGAffineTransformIdentity;
        self.defaultNavigationView.closeButton.alpha = 0.0f;
    }];
}

- (void)dismissAlbumMenuViewAnimated:(BOOL)animated
{
    if (self.albumListTableView) {
        [UIView animateWithDuration:0.25f animations:^{
            self.albumListTableView.transform = CGAffineTransformMakeTranslation(0, -self.view.bounds.size.height);
            self.defaultNavigationView.closeButton.alpha = 1.0f;
        } completion:^(BOOL finished) {
            self.albumListTableView.superview.accessibilityElements = nil;
            [self.albumListTableView removeFromSuperview];
            self.albumListTableView = nil;
        }];
    }
    if (self.albumTopLine) {
        [self.albumTopLine removeFromSuperview];
    }
}

- (void)didAlbumChanged:(CAKAlbumModel *)albumModel
{
    if (albumModel) {
        //do alp_disableLocalizations
        self.defaultNavigationView.selectAlbumButton.leftLabel.text = albumModel.name;
    } else {
        //do alp_disableLocalizations
        self.defaultNavigationView.selectAlbumButton.leftLabel.text = @"im_all_photos";
    }
    self.defaultNavigationView.selectAlbumButton.rightImageView.layer.transform = CATransform3DIdentity;
}

#pragma mark - Utils

- (CAKAlbumPreviewAndMultiSelectType)previewAndMultiSelectTypeWithCurrentListVC
{
    CAKAlbumListViewController *currentListVC;
    if ([self.viewModel.currentSelectedListVC isKindOfClass:CAKAlbumListViewController.class]) {
        currentListVC = (CAKAlbumListViewController *)self.viewModel.currentSelectedListVC;
    }
    return [self.viewModel previewAndMultiSelectTypeWithListViewController:currentListVC];
}

- (CGFloat)albumSlidingOffsetY
{
    CGFloat offsetY = 0;
    if (self.viewModel.listViewConfig.shouldShowiOS14GoSettingStrip && ![CAKAlbumGoSettingStrip closedByUser]) {
        offsetY +=  40;
    }
    if (![self shouldShowAlbumTabView]) {
        self.slidingTabView.hidden = YES;
        return offsetY;
    }
    
    return offsetY + 48;
}

- (CGRect)listViewControllerFrame {
    return [self listViewControllerFrameWithListViewController:nil];
}

- (CGRect)listViewControllerFrameWithListViewController:(UIViewController<CAKAlbumListViewControllerProtocol> *)listViewController
{
    UIViewController<CAKAlbumListViewControllerProtocol> *listVC = listViewController;
    if (!listVC) {
        listVC = [self.viewModel.tabsInfo acc_objectAtIndex:self.viewModel.currentSelectedIndex];
    }

    CGFloat offset = -kAlbumFullBottomOffset;
    if ([self p_shouldShowBottomViewWithListVC:listVC]) {
        offset += [self p_selectedAssetsBottomViewHeight];
    }
    
    if ([self p_shouldShowSelectedAssetsViewWithListVC:listVC]) {
        offset += [self p_selectedAssetsViewHeight];
    }
    
    CGFloat height = self.viewWrapper.acc_height - [self albumSlidingOffsetY] - self.statusBarHeightDelta - offset;
    CGFloat horizontalInset = [self p_horizontalInset];
    return CGRectMake(horizontalInset, [self albumSlidingOffsetY], ACC_SCREEN_WIDTH - 2*horizontalInset, height);
}

- (BOOL)shouldShowAlbumTabView
{
    if (!self.viewModel.listViewConfig.enableTabView || self.viewModel.tabsInfo.count == 1) {
        return NO;
    }
    return YES;
}

- (NSString *)p_defaultBottomTitleLabelText
{
    NSString *title = CAKLocalizedString(@"creation_upload_docktoast", @"You can select both videos and photos");
    if (self.viewModel.currentResourceType == AWEGetResourceTypeImage) {
        title = CAKLocalizedString(@"creation_upload_docktoast_image", @"You can select photos");
    } else if (self.viewModel.currentResourceType == AWEGetResourceTypeVideo) {
        title = CAKLocalizedString(@"creation_upload_docktoast_video", @"You can select videos");
    }
    return title;
}

#pragma mark -CAKSwipeInteractionControllerDelegate
- (void)didCompleteTransitionWithPanProgress:(CGFloat)progress
{
    if ([self.delegate respondsToSelector:@selector(albumViewController:didDismissWithPanProgress:)]) {
        [self.delegate albumViewController:self didDismissWithPanProgress:progress];
    }
}

#pragma mark - Getter
- (NSArray<CAKAlbumAssetModel *> *)selectedAlbumAssets
{
    return self.viewModel.currentSelectAssetModels;
}

- (NSArray<CAKAlbumAssetModel *> *)selectedPhotoAssets
{
    return self.viewModel.albumDataModel.photoSelectAssetsModels;
}

- (NSArray<CAKAlbumAssetModel *> *)selectedVideoAssets
{
    return self.viewModel.albumDataModel.videoSelectAssetsModels;
}

- (UIViewController<CAKAlbumListViewControllerProtocol> *)currentListViewController
{
    return [self.viewModel.tabsInfo acc_objectAtIndex:self.viewModel.currentSelectedIndex];
}

- (CAKAlbumSlidingViewController *)slidingViewController
{
    if (!_slidingViewController) {
        _slidingViewController = [[CAKAlbumSlidingViewController alloc] init];
        _slidingViewController.automaticallyAdjustsScrollViewInsets = NO;
        _slidingViewController.slideEnabled = YES;
        _slidingViewController.delegate = self;
        _slidingViewController.tabbarView = self.slidingTabView;
    }
    return _slidingViewController;
}

- (CAKAlbumSlidingTabBarView *)slidingTabView
{
    if (!_slidingTabView) {
        NSArray *titlesArray = self.viewModel.titles;

        _slidingTabView = [[CAKAlbumSlidingTabBarView alloc] initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, 40) buttonStyle:CAKAlbumSlidingTabButtonStyleText dataArray:titlesArray.copy selectedDataArray:titlesArray.copy];
        _slidingTabView.shouldShowTopLine = NO;
        _slidingTabView.backgroundColor = CAKResourceColor(ACCUIColorConstBGContainer);
        [_slidingTabView configureButtonTextColor:CAKResourceColor(ACCUIColorConstTextTertiary) selectedTextColor:CAKResourceColor(ACCUIColorConstTextPrimary)];
        _slidingTabView.selectionLineColor = CAKResourceColor(ACCColorTextReverse);
        _slidingTabView.enableSwitchAnimation = YES;
        _slidingTabView.selectionLineSize = CGSizeMake(32, 2);
        _slidingTabView.shouldShowSelectionLine = YES;
    }
    return _slidingTabView;
}

- (CAKAlbumViewControllerNavigationView *)defaultNavigationView {
    if (!_defaultNavigationView) {
        _defaultNavigationView = [[CAKAlbumViewControllerNavigationView alloc] init];
        _defaultNavigationView.frame = CGRectMake(0, 0, self.view.acc_width, [self p_albumNavHeight]);
        [_defaultNavigationView.selectAlbumButton addTarget:self action:@selector(selectAlbumBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [_defaultNavigationView.closeButton addTarget:self action:@selector(cancelBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _defaultNavigationView;
}

- (BOOL)enablePreview
{
    return self.currentListViewController.tabConfig.enablePreview;
}

- (BOOL)enableMultiSelect
{
    return self.currentListViewController.tabConfig.enableMultiSelect;
}

#pragma mark - Button Action

- (void)selectAlbumBtnClicked:(UIButton *)button
{
    if ([self isAlbumMenuViewVisible]) {
        [self dismissAlbumMenuViewAnimated:YES];
        [UIView animateWithDuration:0.4f animations:^{
            self.defaultNavigationView.selectAlbumButton.rightImageView.layer.transform = CATransform3DIdentity;
        } ];
    } else {
        CGRect rect = CGRectMake(0, [self p_albumNavHeight], self.view.acc_width, self.view.acc_height - [self p_albumNavHeight]);
        __weak typeof(self) weakSelf = self;
        [self showAlbumMenuViewOnView:self.view frame:rect animated:YES animationWillBeginBlock:^(BOOL success) {
            if (!success) {
                return;
            }
            [weakSelf.view bringSubviewToFront:weakSelf.defaultNavigationView];
        }];
        [UIView animateWithDuration:0.4f animations:^{
            self.defaultNavigationView.selectAlbumButton.rightImageView.layer.transform = CATransform3DMakeRotation(M_PI, 0, 0, 1);
        } ];
    }
}

@end
