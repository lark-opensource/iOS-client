//
//  ACCOneKeyMvEntranceViewController.m
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/10/9.
//

#import "ACCOneKeyMvEntranceViewController.h"
#import <Masonry/View+MASAdditions.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import "ACCAlbumInputData.h"
#import <CreativeAlbumKit/CAKAlbumViewController.h>
#import <IESInject/IESInjectDefines.h>
#import <CreativeKit/ACCServiceLocator.h>
#import "ACCSelectAlbumAssetsProtocol.h"
#import "ACCViewControllerProtocol.h"
#import <CameraClient/AWERepoMVModel.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CameraClient/AWERepoTrackModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "ACCMvTemplateSupportOneKeyMvConfig.h"
#import <CreationKitInfra/ACCDeviceAuth.h>
#import <CreationKitInfra/ACCAlertProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>

@interface ACCOneKeyMvEntranceViewController ()

@property (nonatomic, strong) ACCOneKeyMvEntranceView *oneKeyMvEntranceView;
@property (nonatomic, strong) ACCSlidingTabbarView *slidingTabView;
@property (nonatomic, strong) ACCWaterfallViewController *currentContentVc;
@property (nonatomic, strong) id<ACCWaterfallTabContentProviderProtocol> contentProvider;
@property (nonatomic, strong) RACDisposable *contentOffsetDisposable;
@property (nonatomic, strong) UIButton *oneKeyMvEntranceButton;
@property (nonatomic, assign) ACCOneKeyMvEntranceBannerStatus bannerStatus;
@property (nonatomic, assign) NSInteger currentSelectedIndex;
@property (nonatomic, assign) BOOL canHandle;   // 处理切换分类后，banner展示且当前分类vc的contentoffset.y大于-80的情况
@property (nonatomic, assign) BOOL isUp;        // 滑动方向 YES-向上拖动 NO-向下拖动
@property (nonatomic, assign) CGFloat oneKeyMvButtonFinalY;

@end

static CGFloat bannerViewHeight = 80.f;

@implementation ACCOneKeyMvEntranceViewController

# pragma mark - lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareView];
}

# pragma mark - init

+ (instancetype)slidingTabView:(nullable ACCSlidingTabbarView *)slidingTabView
               contentProvider:(id<ACCWaterfallTabContentProviderProtocol>)contentProvider
{
    return [[ACCOneKeyMvEntranceViewController alloc] initWithSlidingTabView:slidingTabView contentProvider:contentProvider];
}

- (instancetype)initWithSlidingTabView:(nullable ACCSlidingTabbarView *)slidingTabView
                       contentProvider:(id<ACCWaterfallTabContentProviderProtocol>)contentProvider
{
    if (self = [super init]) {
        self.slidingTabView = slidingTabView;
        self.contentProvider = contentProvider;
        self.canHandle = NO;
        self.bannerStatus = ACCOneKeyMvEntranceBannerShow;
        [self addObserver];
    }
    return self;
}

# pragma mark - public

- (void)setupUpdateContentOffsetBlock:(nullable ACCWaterfallViewController *)vc
{
    CGFloat entranceHeight = [ACCMvTemplateSupportOneKeyMvConfig oneKeyViewHeight];
    @weakify(self);
    vc.updateContentOffsetBlock = ^(UICollectionView * _Nonnull collectionView) {
        @strongify(self);
        if (self.bannerStatus == ACCOneKeyMvEntranceBannerHiden) {
            CGPoint contentOffset = collectionView.contentOffset;
            if (ACC_FLOAT_LESS_THAN(contentOffset.y, ACC_FLOAT_ZERO)) {
                contentOffset.y = 0;
            } else if (ACC_FLOAT_LESS_THAN(entranceHeight, contentOffset.y)) {
                contentOffset.y += entranceHeight;
            }
            collectionView.contentOffset = contentOffset;
        }
    };
}

- (void)registerOneKeyButton:(UIButton *)button finalY:(CGFloat)finalY
{
    self.oneKeyMvEntranceButton = button;
    self.oneKeyMvButtonFinalY = finalY;
    
    [self.oneKeyMvEntranceButton addTarget:self action:@selector(handleButtonClicked) forControlEvents:UIControlEventTouchUpInside];
}

# pragma mark - ACCWaterfallContentScrollDelegate

- (void)waterfallScrollViewDidScroll:(UIScrollView *)scrollView viewController:(ACCWaterfallViewController *)vc
{
    CGPoint translatedPoint = [scrollView.panGestureRecognizer translationInView:scrollView];
    if(translatedPoint.y < 0) {
        [self updateScrollDirection:YES];
    }
    if(translatedPoint.y > 0) {
        [self updateScrollDirection:NO];
    }
}

- (void)waterfallScrollViewDidEndDecelerating:(UIScrollView *)scrollView
                               viewController:(ACCWaterfallViewController *)vc
{
    [self updateOneKeyMvViewSoftly:scrollView.contentOffset.y];
}

- (void)waterfallScrollViewDidEndDragging:(UIScrollView *)scrollView
                           willDecelerate:(BOOL)decelerate
                           viewController:(ACCWaterfallViewController *)vc
{
    if (!decelerate) {
        [self updateOneKeyMvViewSoftly:scrollView.contentOffset.y];
    }
}

# pragma mark - private

- (void)updateOneKeyMvViewSoftly:(CGFloat)y
{
    y += bannerViewHeight;
    
    if (ACC_FLOAT_LESS_THAN(y, bannerViewHeight / 2) ||
            ACC_FLOAT_EQUAL_TO(y, bannerViewHeight / 2)) {
        // y <= 40 展开
        [self updateOneKeyMvViewPosition:0 animated:YES];
    } else if (ACC_FLOAT_LESS_THAN(y, bannerViewHeight) &&
               ACC_FLOAT_LESS_THAN(bannerViewHeight / 2, y)) {
        // y < 80 && y > 40 收起
        [self updateOneKeyMvViewPosition:-bannerViewHeight animated:YES];
    }
}

- (void)updateScrollDirection:(BOOL)isUp
{
    self.isUp = isUp;
}

- (void)prepareView
{
    self.view.backgroundColor = ACCResourceColor(ACCColorBGCreation);
    [self.view addSubview:self.oneKeyMvEntranceView];
    [self.view addSubview:self.slidingTabView];
    
    ACCMasMaker(self.oneKeyMvEntranceView, {
        make.top.mas_equalTo(self.view);
        make.height.mas_equalTo(self.oneKeyMvEntranceView.frame.size.height);
        make.width.mas_equalTo(self.view.frame.size.width - 16);
        make.centerX.mas_equalTo(self.view);
    });

    ACCMasMaker(self.slidingTabView, {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.oneKeyMvEntranceView.mas_bottom);
        make.height.mas_equalTo(self.slidingTabView.frame.size.height);
    });
}

- (void)addObserver
{
    @weakify(self);
    [[[RACObserve(self, bannerStatus) takeUntil:[self rac_willDeallocSignal]] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        NSInteger status = [x integerValue];
        NSArray<UIViewController *> * viewControllers = self.contentProvider.slidingViewControllers;
        [viewControllers enumerateObjectsUsingBlock:^(UIViewController * _Nonnull vc, NSUInteger idx, BOOL * _Nonnull stop) {
            ACCWaterfallViewController *waterfallvc = (ACCWaterfallViewController *) vc;
            CGPoint contentOffset = waterfallvc.collectionView.contentOffset;
            if (idx != self.currentSelectedIndex) {
                if (status == ACCOneKeyMvEntranceBannerHiden && contentOffset.y < 0) {
                    contentOffset.y = 0;
                }
                if (status == ACCOneKeyMvEntranceBannerShow && contentOffset.y == 0) {
                    contentOffset.y = -bannerViewHeight;
                }
            }
            waterfallvc.collectionView.contentOffset = contentOffset;
        }];
    }];
    
    [[[RACObserve(self.slidingTabView, selectedIndex) takeUntil:[self rac_willDeallocSignal]] deliverOnMainThread] subscribeNext:^(id _Nullable x) {
        @strongify(self);
        ACCWaterfallViewController *vc = (ACCWaterfallViewController *) self.contentProvider.slidingViewControllers[[x integerValue]];
        vc.delegate = self;
        [self handleIfChangeIndex:[x integerValue] vc:vc];
        self.contentOffsetDisposable = [[[RACObserve(vc.collectionView, contentOffset) takeUntil:[self rac_willDeallocSignal]] deliverOnMainThread] subscribeNext:^(id _Nullable offset) {
            @strongify(self);
            [self handleEntranceViewByContentOffset:[offset CGPointValue]
                                                             selectedIndex:[x integerValue]
                                                                        vc:vc];
            
        }];
    }];
}

- (void)handleEntranceViewByContentOffset:(CGPoint)contentOffset
                            selectedIndex:(NSInteger)index
                                       vc:(ACCWaterfallViewController *)vc
{
    self.currentContentVc = vc;
    CGFloat y = contentOffset.y + bannerViewHeight;
    
    BOOL bannerShow = self.bannerStatus == ACCOneKeyMvEntranceBannerShow;
    if (self.canHandle && self.isUp) {
        // 切换了tab，并且banner为展开状态，做下滑操作时，banner收起
        CGRect originFrame = self.view.frame;
        self.bannerStatus = ACCOneKeyMvEntranceBannerScrolling;
        originFrame.origin.y = -bannerViewHeight;
        [self updateOneKeyMvButtonStatus:-bannerViewHeight animated:YES];
        [UIView animateWithDuration:0.3 animations:^{
            self.view.frame = originFrame;
        } completion:^(BOOL finished) {
            [self updateOneKeyEntranceBannerStatus:-bannerViewHeight];
            self.canHandle = NO;
        }];
    }
    if (ACC_FLOAT_LESS_THAN(ACC_FLOAT_ZERO, y) && bannerShow && !self.isUp) {
        // y > 0, 并且banner展开，做上滑操作时，banner维持原状
        if (!UIAccessibilityIsVoiceOverRunning()) {
            // 非无障碍模式
            return;
        }
    }
    if ((ACC_FLOAT_EQUAL_ZERO(y) || ACC_FLOAT_LESS_THAN(y, ACC_FLOAT_ZERO)) && self.canHandle) {
        // y <= 0, 由下面逻辑接管
        self.canHandle = NO;
    }
    
    if (ACC_FLOAT_EQUAL_ZERO(y) || ACC_FLOAT_LESS_THAN(y, ACC_FLOAT_ZERO)) {
        // y == 0 || y < 0，展开状态
        [self updateOneKeyMvViewPosition:0 animated:NO];
    } else if (ACC_FLOAT_LESS_THAN(bannerViewHeight, y) || ACC_FLOAT_EQUAL_TO(y, bannerViewHeight)) {
        // y > 80 || y == 80，吸顶状态
        [self updateOneKeyMvViewPosition:-bannerViewHeight animated:NO];
    } else if (ACC_FLOAT_LESS_THAN(ACC_FLOAT_ZERO, y) && ACC_FLOAT_LESS_THAN(y, bannerViewHeight)) {
        // y > 0 && y < 80 ，中间状态
        [self updateOneKeyMvViewPosition:-y animated:NO];
    }
}

- (void)updateOneKeyMvViewPosition:(CGFloat)y animated:(BOOL)animated
{
    if (self.bannerStatus == ACCOneKeyMvEntranceBannerScrolling) {
        return;
    }
    UIView *oneKeyView = self.view;
    if (ACC_FLOAT_EQUAL_TO(oneKeyView.frame.origin.y, y)) {
        return ;
    }
    [self updateOneKeyMvButtonStatus:y animated:animated];
    if (animated) {
        self.bannerStatus = ACCOneKeyMvEntranceBannerScrolling;
        [UIView animateWithDuration:0.3 animations:^{
            oneKeyView.frame = CGRectMake(oneKeyView.acc_origin.x, y, oneKeyView.acc_size.width, oneKeyView.acc_size.height);
            CGPoint contentOffset = self.currentContentVc.collectionView.contentOffset;
            contentOffset.y = (ACC_FLOAT_EQUAL_ZERO(y) ? -bannerViewHeight : 0);
            self.currentContentVc.collectionView.contentOffset = contentOffset;
        } completion:^(BOOL finished) {
            [self updateOneKeyEntranceBannerStatus:y];
        }];
    } else {
        oneKeyView.frame = CGRectMake(oneKeyView.acc_origin.x, y, oneKeyView.acc_size.width, oneKeyView.acc_size.height);
        [self updateOneKeyEntranceBannerStatus:y];
    }
}

- (void)updateOneKeyMvButtonStatus:(CGFloat)y animated:(BOOL)animated
{
    UIButton *btn = self.oneKeyMvEntranceButton;
    if (ACC_FLOAT_LESS_THAN(ACC_FLOAT_ZERO, y) || ACC_FLOAT_EQUAL_ZERO(y)) {
        btn.alpha = 0;
        return ;
    }
    y = -y;
    CGFloat originY = [ACCMvTemplateSupportOneKeyMvConfig oneKeyBtnOriginY];
    CGFloat changeRange = originY - self.oneKeyMvButtonFinalY;
    
    CGRect originFrame = self.oneKeyMvEntranceButton.frame;
    if (ACC_FLOAT_LESS_THAN(bannerViewHeight, y)) {
        btn.alpha = 1;
        btn.frame = CGRectMake(btn.acc_origin.x, originY, btn.acc_size.width, btn.acc_size.height);
        return ;
    }
    
    CGFloat ratio = y / bannerViewHeight;
    CGFloat offsetY = changeRange * ratio;

    CGRect targetFrame = CGRectMake(originFrame.origin.x, originY - offsetY, originFrame.size.width, originFrame.size.height);
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            self.oneKeyMvEntranceButton.frame = targetFrame;
            self.oneKeyMvEntranceButton.alpha = ratio;
        }];
    } else {
        self.oneKeyMvEntranceButton.alpha = ratio;
        self.oneKeyMvEntranceButton.frame = targetFrame;
    }
}

- (void)updateOneKeyEntranceBannerStatus:(CGFloat)y
{
    if (ACC_FLOAT_EQUAL_ZERO(y)) {
        self.bannerStatus = ACCOneKeyMvEntranceBannerShow;
    } else if (ACC_FLOAT_EQUAL_TO(y, -bannerViewHeight)) {
        self.bannerStatus = ACCOneKeyMvEntranceBannerHiden;
    }
}

- (void)handleIfChangeIndex:(NSInteger)index vc:(ACCWaterfallViewController *)vc
{
    if (index != self.currentSelectedIndex) {
        [self.contentOffsetDisposable dispose];
        self.currentSelectedIndex = index;
        BOOL bannerShow = self.bannerStatus == ACCOneKeyMvEntranceBannerShow;
        if (ACC_FLOAT_LESS_THAN(-bannerViewHeight, vc.collectionView.contentOffset.y) && bannerShow) {
            self.canHandle = YES;
        }
    }
}

- (void)handleButtonClicked
{
    [self jumpToAlbumPage:@"top_icon"];
}

- (void)jumpToAlbumPage:(NSString *)enterMethod
{

    [ACCDeviceAuth requestPhotoLibraryPermission:^(BOOL success) {
        if (success) {
            AWEVideoPublishViewModel *publishModel = self.contentProvider.publishModel;
            publishModel.repoMV.oneKeyMVEnterfrom = enterMethod;
            // 添加trackModel
            ACCAlbumInputData *inputData = [[ACCAlbumInputData alloc] init];
            inputData.originUploadPublishModel = publishModel;
            inputData.vcType = ACCAlbumVCTypeForOneKeyMv;
            
            CAKAlbumViewController *selectAlbumViewController = [IESAutoInline(ACCBaseServiceProvider(), ACCSelectAlbumAssetsProtocol) albumViewControllerWithInputData:inputData];
                        
            UINavigationController *navigationController = [ACCViewControllerService() createCornerBarNaviControllerWithRootVC:selectAlbumViewController];
            navigationController.navigationBar.translucent = NO;
            navigationController.modalPresentationStyle = UIModalPresentationCustom;
            
            [self presentViewController:navigationController animated:YES completion:^{
                NSMutableDictionary *params = [NSMutableDictionary dictionary];
                params[@"shoot_way"] = publishModel.repoTrack.referString ? : @"";
                params[@"creation_id"] = publishModel.repoContext.createId ?: @"";
                params[@"enter_method"] = enterMethod ?: @"";
                [ACCTracker() trackEvent:@"click_ai_upload_entrance" params:[params copy]];
            }];
        } else {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message: @"相册权限被禁用，请到设置中授予抖音允许访问相册权限" preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                });
            }]];
            [alertController addAction:[UIAlertAction actionWithTitle: @"取消" style:UIAlertActionStyleCancel handler:nil]];
            [ACCAlert() showAlertController:alertController animated:YES];
        }
    }];
}

#pragma mark - getter

- (ACCOneKeyMvEntranceView *)oneKeyMvEntranceView
{
    if (!_oneKeyMvEntranceView) {
        _oneKeyMvEntranceView = [[ACCOneKeyMvEntranceView alloc] init];
        self.oneKeyMvEntranceView.delegate = self;
    }
    return _oneKeyMvEntranceView;
}

@end
