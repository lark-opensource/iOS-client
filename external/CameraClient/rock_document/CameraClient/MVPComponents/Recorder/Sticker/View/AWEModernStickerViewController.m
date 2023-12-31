//
//  AWEModernStickerViewController.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/4/13.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWERepoPropModel.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/ACCRACWrapper.h>
#import "AWEModernStickerViewController.h"
#import "AWEAggregatedEffectView.h"
#import <CreativeKit/CALayer+AWEStudioAddtions.h>
#import "AWEModernStickerTitleCollectionViewCell.h"
#import "AWEModernStickerContentCollectionViewCell.h"
#import "AWEModernStickerCollectionViewCell.h"
#import "AWEStickerDataManager+AWEConvenience.h"
#import "AWEModernStickerCollectionViewCoordinator.h"
#import "ACCCollectionButton.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import "AWEMattingView.h"
#import <CreationKitInfra/ACCDeviceAuth.h>
#import "AWEOriginStickerUserView.h"
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/UIView+AWEStudioAdditions.h>
#import "AWEStickerCommerceEnterView.h"
#import "AWEAlbumPhotoCollector.h"
#import "AWERecordDefaultCameraPositionUtils.h"
#import "AWEEffectHintViewProtocol.h"
#import "ACCAlbumInputData.h"
#import "ACCFriendsServiceProtocol.h"
#import "AWEStickerMusicManager+Local.h"

#import "ACCGradientView.h"
#import <CreationKitArch/AWEStickerMusicManager.h>
#import "AWEVideoRecordOutputParameter.h"
#import <CreationKitInfra/UILabel+ACCAdditions.h>

#import <CreationKitArch/ACCUserServiceProtocol.h>
#import "ACCCommerceServiceProtocol.h"
#import <CameraClient/ACCTransitioningDelegateProtocol.h>
#import <CameraClient/ACCTrackerUtility.h>
#import <CameraClient/ACCMusicNetServiceProtocol.h>

#import "AWEVideoBGStickerManager.h"
#import <CreationKitArch/AWEDraftUtils.h>
#import "AWEEffectPlatformManager+Download.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <ByteDanceKit/BTDNetworkUtilities.h>
#import <ByteDanceKit/BTDMacros.h>
#import <CreationKitInfra/ACCResponder.h>
#import <CreationKitArch/ACCRecorderToolBarDefines.h>

#import "ACCClipVideoProtocol.h"
#import <CameraClient/ACCViewControllerProtocol.h>
#import <CreationKitArch/ACCStickerNetServiceProtocol.h>
#import <HTSServiceKit/HTSMessageCenter.h>

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCRouterProtocol.h>

#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import "AWEDouPlusEffectHintView.h"

#import <CreativeAlbumKit/CAKAlbumViewController.h>
#import <CreativeAlbumKit/CAKPhotoManager.h>
#import <CreativeAlbumKit/CAKModalTransitionDelegate.h>
#import "AWERepoContextModel.h"
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import "AWERepoVideoInfoModel.h"
#import <CreationKitInfra/ACCConfigManager.h>
#import "ACCConfigKeyDefines.h"
#import <CameraClient/IESEffectModel+DStickerAddditions.h>

#if __has_feature(modules)
@import Photos;
#else
#import <Photos/Photos.h>
#endif

#define IPHONE_X_EXTRA_PADDING  ([UIDevice acc_isIPhoneX] ? 30 : 0)
#define kAWEStickerPanelPadding 6

static NSString * const kHotCategoryKey = @"hot";

ACCContextId(ACCRecordStickerPanelContext)

static CGFloat acc_stickerTabViewHeight = 44; // 道具栏顶部tab栏高度
static CGFloat acc_stickerMattingViewHeight = 65; // 人脸view高度
static CGFloat acc_newLayoutStickerMattingViewHeight = 80.f;
static CGFloat const acc_favoriteButtonLowBottomGap = -70;
static CGFloat acc_newLayoutFavoriteButtonLowBottomGap = -85;
static CGFloat acc_favoriteButtonHighBottomGap = 2;

static NSString *acc_categoryEffectCollectionIdentifier = @"acc_categoryEffectCollectionIdentifier";
static NSString *acc_collectedEffectCollectionIdentifier = @"acc_collectedEffectCollectionIdentifier";

typedef NS_OPTIONS(NSUInteger, AWEModernStickerTrayViewOption) {
    AWEModernStickerTrayViewOptionMatting = 1 << 0,
    AWEModernStickerTrayViewOptionAggregated = 1 << 1,
    AWEModernStickerTrayViewOptionMoji = 1 << 2
};

typedef NS_ENUM(NSInteger, AWEFilterNumber){
    AWEFilterNumberNoFilter = 1,
    AWEFilterNumberPannelFilter,
    AWEFilterNumberPannelAndAlbumFilter,
    AWEFilterNumberAlbumFilter,
};

@interface AWEModernStickerViewController () <UICollectionViewDataSource,
                                              UICollectionViewDelegate,
                                              AWEMattingViewProtocol,
                                              AWEAggregatedEffectViewDelegate,
                                              ACCUserServiceMessage,
                                              AWEModernStickerCollectionViewCoordinatorDelegate,
                                              ACCSelectAlbumAssetsDelegate,
                                              UICollectionViewDelegateFlowLayout>

// views
@property (nonatomic, strong) UIView *stickerBackgroundView;
@property (nonatomic, strong) UIView *stickerTabContainerView;
@property (nonatomic, strong) UIButton *clearStickerApplyBtton;
@property (nonatomic, strong) AWEMattingView *mattingView;
@property (nonatomic, copy) NSArray<AWEAssetModel *> *multiAssetsPixaloopSelectedAssetArray;
@property (nonatomic, copy) NSArray<NSString *> *multiAssetsPixaloopSelectedKeyArray;
@property (nonatomic, strong) AWEAggregatedEffectView *aggregatedEffectView;

@property (nonatomic, assign) BOOL needRestoreSubViewHiddenStates;//道具搜索进入的时候既不能取消现有的选择，也不能显示子道具等views
@property (nonatomic, assign) CGFloat mattingViewAlpha;
@property (nonatomic, assign) CGFloat aggregatedEffectViewAlpha;
@property (nonatomic, assign) BOOL hasSelectedWhenSearching;

@property (nonatomic, strong) AWEModernStickerSwitchTabView *switchTabView;
@property (nonatomic, strong) UIView *sepLine;
@property (nonatomic, strong) AWEModernStickerContentCollectionView *stickerContentCollectionView;
@property (nonatomic, strong) UIView *favoriteView;
@property (nonatomic, strong) ACCStickerShowcaseEntranceView *stickerShowcaseEntranceView;
@property (nonatomic, strong) AWEOriginStickerUserView *originStickerUserView;
@property (nonatomic, strong) AWEStickerCommerceEnterView *commerceEnterView;
@property (nonatomic, strong) UIView<AWEEffectHintViewProtocol> *hotEffectHintView;
@property (nonatomic, strong) ACCCollectionButton *favoriteButton;
@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) UIView *errorView;
@property (nonatomic, strong) UIView *favoriteBubble;
@property (nonatomic, assign, readwrite) BOOL hasShownBefore;
@property (nonatomic, strong) UIButton *cameraButton; // 摄像头按钮
@property (nonatomic, strong) AWECameraContainerToolButtonWrapView *cameraButtonWrapView;

@property (nonatomic, strong) UIButton *storyCameraButton; // Story摄像头按钮

// utils
@property (nonatomic, strong) AWEStickerDataManager *dataManager;
@property (nonatomic, strong) AWEModernStickerCollectionViewCoordinator *coordinator;

// logic
@property (nonatomic, strong) IESEffectModel *selectedEffectModel;
@property (nonatomic, strong) IESEffectModel *selectedChildEffectModel;
@property (nonatomic, assign) NSInteger lastLoadingIndex;

// 当前选中道具在道具面板上的位置，indexPath.section 表示分类位置，indexPath.item 表示在当前分类中的位置
// Indicate the position in the sticker panel. indexPath.section is the category position, indexPath.item is the position in the category.
@property (nonatomic, strong, nullable) NSIndexPath *selectedEffectIndexPath;

@property (nonatomic, strong) IESEffectModel *waitingEffect;

@property (nonatomic, assign) BOOL isDismissingChildEffectPanel;
@property (nonatomic, copy) void(^childPanelRestoreBlock)(void);

@property (nonatomic, strong) NSMutableSet *hasShowedStickerSet;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<ACCUserModelProtocol>> *cachedUserNameDict;
@property (nonatomic, strong) NSMutableDictionary *cachedCommerceStickerDict;
@property (nonatomic, assign) BOOL fetchCategoryDataCompleted; // tab分页数据是否加载完成

@property (nonatomic, assign) NSInteger lastSelectedTabIndex;//区分selectedTabIndex变动，用于切换tab后做一次清空prop_show上报记录操作
@property (nonatomic, strong) NSIndexPath *currentContentCellIndexPath;

@property (nonatomic, strong) UIView<ACCTextLoadingViewProtcol> *uiLoadingView;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSIndexPath *> *effectIndexPathBindingMap; // 数据源太复杂了，记一下effect和idx的对应关系，cell UI复用要用

@property (nonatomic, strong) CAKModalTransitionDelegate *transitionDelegate;

/** 新版effect Tab UI 增加部分 */
/// 将dataMgr返回的Categories中所有的effect按照顺序拼接起来 // TODO: @田光前 这里要考虑带着道具进来的插入情况
@property (nonatomic, strong) NSArray<IESEffectModel *> *totalEffectModels;
/// 由于新版的Tab UI改为横向单行滑动，并且每个Category之间需要连续，添加一个"·"来间隔
@property (nonatomic, strong) NSArray<NSNumber *> *separatorsIndexs;
/// 用来记录每个分类最后一个元素后面的分割线所在的offsetX，用来用户滑动sticker list时底部switch Tab联动
@property (nonatomic, strong) NSArray<NSNumber *> *categorySeparatorOffsetXsArray;
@property (nonatomic, strong) ACCGradientView *gradientView;
@property (nonatomic, assign) BOOL shouldIgnoreSwitchTabViewScrollEvent;

@property (nonatomic, strong) id<UIViewControllerTransitioningDelegate> clipTransitionDelegate;
@property (nonatomic, weak) UIViewController *selectAlbumAssetVC;

@property (nonatomic, strong) id<ACCVideoConfigProtocol> videoConfig;
@property (nonatomic, assign) AWEModernStickerTrayViewOption displayingTrayView;
@property (nonatomic, copy) NSString *dismissTrackStr;

@property (nonatomic, strong) id<ACCSelectAlbumAssetsProtocol> albumImpl;
@property (nonatomic, copy) NSString *lastTrackedCommerceEnterPropID;

@end

@implementation AWEModernStickerViewController
IESAutoInject(ACCBaseServiceProvider(), videoConfig, ACCVideoConfigProtocol)
IESAutoInject(ACCBaseServiceProvider(), albumImpl, ACCSelectAlbumAssetsProtocol)

#pragma mark - left circle

- (instancetype)initWithDataManager:(AWEStickerDataManager *)dataManager
{
    self = [super init];
    if (self) {
        _dataManager = dataManager;
        _hasShowedStickerSet = [NSMutableSet set];
        _effectIndexPathBindingMap = [NSMutableDictionary dictionary];
    }
    return self;
}

- (instancetype)init
{
    return [self initWithDataManager:[[AWEStickerDataManager alloc] initWithPanelType:AWEStickerPanelTypeRecord]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupUI];
    [self p_refreshDataManager];
    self.automaticallyAdjustsScrollViewInsets = NO;
    REGISTER_MESSAGE(ACCUserServiceMessage, self);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.view.accessibilityViewIsModal = YES;
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.clearStickerApplyBtton);

    ACCBLOCK_INVOKE(self.willAppearBlock, animated);
    if ([self.selectedEffectModel isVideoBGPixaloopSticker]) {
        if (self.videoBGStickerManager.currentSelectedMattingAssetModel == nil) {
           [self.mattingView unSelectCurrentCell];
        } else {
           [self.mattingView updateSelectedPhotoWithAssetLocalIdentifier:self.videoBGStickerManager.currentSelectedMattingAssetModel.asset.localIdentifier];
        }
    } else if ([self.selectedEffectModel isPixaloopSticker]) {
        if (self.propSelection.asset == nil) {
            [self.mattingView unSelectCurrentCell];
        } else {
            [self.mattingView updateSelectedPhotoWithAssetLocalIdentifier:self.propSelection.asset.localIdentifier];
        }
    } else {
        [self p_hiddenMattingView];
    }
    if (self.selectedEffectModel.childrenEffects.count == 0 && [self bindEffectsForSelectedEffect].count == 0) {
         [self p_hiddenAggregatedEffectViewWithCompletionBlock:nil];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    ACCBLOCK_INVOKE(self.didAppearBlock, animated);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    ACCBLOCK_INVOKE(self.willDisappearBlock, animated);
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    ACCBLOCK_INVOKE(self.didDisappearBlock, animated);
}

- (void)dealloc
{
    UNREGISTER_MESSAGE(ACCUserServiceMessage, self);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self.dataManager.stickerCategories enumerateObjectsUsingBlock:^(IESCategoryModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.aweStickers makeObjectsPerformSelector:@selector(setAcc_iconImage:) withObject:nil];
    }];

    [self.cachedUserNameDict removeAllObjects];
    [self.cachedCommerceStickerDict removeAllObjects];
}

#pragma mark - ACCUserServiceMessage

- (void)didFinishLogin
{
    //这里把aweStickers置为nil后，从effects里重新获取待解锁贴纸
    for (IESCategoryModel *category in self.dataManager.stickerCategories) {
        category.aweStickers = nil;
    }
    @weakify(self);
    AWELogToolDebug(AWELogToolTagNone, @"bengin download collection ctickers after finish login");
    [self.dataManager downloadCollectionStickersWithCompletion:^(BOOL downloadSuccess) {
        @strongify(self);
        UIView<ACCProcessViewProtcol> *loadingView = [ACCLoading() showProcessOnView:self.view title: ACCLocalizedCurrentString(@"com_mig_loading_67jy7g") animated:YES];
        AWELogToolDebug(AWELogToolTagNone, @"download collection ctickers after finish login|downloadSuccess=%d", downloadSuccess);
        if (downloadSuccess) {
            [self.stickerContentCollectionView reloadData];
        }
        [loadingView dismissWithAnimated:YES];
    }];
}

#pragma mark - Public

- (void)updateCollectionView
{
    [self reloadStickerContentCollectionViewIfNeeded];
}

- (void)refreshStickerViews
{
    [self p_refreshStickerViews];
}

- (void)updateSwapCameraButtonWithBlock:(void (^)(UIButton *, AWECameraContainerToolButtonWrapView *))updateBlock
{
    ACCBLOCK_INVOKE(updateBlock, self.cameraButton, self.cameraButtonWrapView);
}

#pragma mark - view

- (void)setupUI
{
    // 全屏大小
    self.view.backgroundColor = [UIColor clearColor];

    UIView *clearView = [[UIView alloc] init];

    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_onClearBackgroundPress:)];
    [clearView addGestureRecognizer:tapRecognizer];
    [clearView setExclusiveTouch:YES];

    // Accessibility
    clearView.isAccessibilityElement = YES;
    clearView.accessibilityLabel = ACCLocalizedCurrentString(@"com_mig_turn_off_effects");
    clearView.accessibilityTraits = UIAccessibilityTraitButton;
    [self.view addSubview:clearView];

    [clearView mas_makeConstraints:^(MASConstraintMaker *maker) {
        CGFloat grayViewHeight = [self stickerPannelGrayBackAreagroundHeight];
        maker.bottom.equalTo(self.view.mas_bottom).offset(-grayViewHeight);
        maker.top.equalTo(self.view.mas_top);
        maker.left.equalTo(self.view.mas_left);
        maker.width.equalTo(self.view.mas_width);
    }];

    [self.view addSubview:self.stickerBackgroundView];
    [self.stickerBackgroundView setExclusiveTouch:YES];
    ACCMasMaker(self.stickerBackgroundView, {
        make.top.equalTo(clearView.mas_bottom);
        make.left.right.bottom.equalTo(self.view);
    });

    // 标注: 1.8.5-AR球星抠脸-选择人脸列表_加载
    [self.view addSubview:self.mattingView];
    ACCMasMaker(self.mattingView, {
        make.left.equalTo(self.view).offset(7.5);
        make.right.equalTo(self.view).offset(-7.5);
        make.bottom.equalTo(self.stickerBackgroundView.mas_top);
        make.height.equalTo(@(acc_stickerMattingViewHeight));
    });

    [self.view addSubview:self.aggregatedEffectView];
    ACCMasMaker(self.aggregatedEffectView, {
        make.left.equalTo(self.view).offset(7.5);
        make.right.lessThanOrEqualTo(self.view).offset(-7.5).priority(MASLayoutPriorityRequired);
        make.bottom.equalTo(self.stickerBackgroundView.mas_top);
        make.height.equalTo(@(acc_newLayoutStickerMattingViewHeight));
    });

    [self.view addSubview:self.favoriteView];

    ACCMasMaker(self.favoriteView, {
        make.bottom.equalTo(self.stickerBackgroundView.mas_top).offset(2);
        if ([self enableNewFavoritesTitle]) {
            make.width.equalTo(@([self getFavoriteButtonBackgroundWidth] + 18));
            make.height.equalTo(@54);
        } else {
            make.width.height.equalTo(@54);
        }
        make.left.equalTo(self.view).offset(0);
    });

    [self.view addSubview:self.stickerShowcaseEntranceView];
    ACCMasMaker(self.stickerShowcaseEntranceView, {
        make.centerY.equalTo(self.favoriteView).offset(-1);
        make.left.equalTo(self.favoriteView.mas_right).offset(-6);
    });

    if (self.dataManager.panelType != AWEStickerPanelTypeLive) {
        if (self.isStoryMode) {
            [self.view addSubview:self.storyCameraButton];
            CGFloat topPadding = [UIDevice acc_isIPhoneX] ? 18 : 12;
            ACCMasMaker(self.storyCameraButton, {
                make.top.equalTo(@(topPadding + ACC_NAVIGATION_BAR_OFFSET));
                make.right.equalTo(self.view).offset(-10);
                make.width.equalTo(@(44));
                make.height.equalTo(@(44));
            });
        } else {
            [self.view addSubview:self.cameraButtonWrapView];
            [self.cameraButton setExclusiveTouch:YES];
            CGFloat rightSpacing = 2;
            CGFloat featureViewHeight = 48;
            CGFloat featureViewWidth = [UIDevice acc_screenWidthCategory] == ACCScreenWidthCategoryiPhone5 ? 48.0 : 52;
            CGFloat buttonSpacing = [UIDevice acc_screenWidthCategory] == ACCScreenWidthCategoryiPhone5 ? 2.0 : 14.0;
            CGFloat buttonHeightWithSpacing = featureViewHeight + buttonSpacing;

            CGRect tempFrame = CGRectMake(6, 20, featureViewWidth, featureViewHeight);
            if ([UIDevice acc_isIPhoneX]) {
                if (@available(iOS 11.0, *)) {
                    tempFrame = CGRectMake(6, ACC_STATUS_BAR_NORMAL_HEIGHT + 20, featureViewWidth, featureViewHeight);
                }
            }

            CGFloat topOffset = tempFrame.origin.y + 6.0;//6 is back button's image's edge
            CGFloat shift = [UIDevice acc_screenWidthCategory] == ACCScreenWidthCategoryiPhone5 ? 3 : 0;
            self.cameraButtonWrapView.frame = CGRectMake(ACC_SCREEN_WIDTH - rightSpacing - featureViewWidth + shift, topOffset, self.cameraButtonWrapView.acc_width, buttonHeightWithSpacing);
        }
    }

    UIView *cameraView = self.isStoryMode ? self.storyCameraButton : self.cameraButtonWrapView;
    [self.view addSubview:self.originStickerUserView];
    ACCMasMaker(self.originStickerUserView, {
        make.left.equalTo(@16);
        make.height.equalTo(@20);
        make.right.lessThanOrEqualTo(self.view).offset(-105);
        make.top.equalTo(cameraView).offset(10);
    });

    [self.view addSubview:self.hotEffectHintView];
    ACCMasMaker(self.hotEffectHintView, {
        make.leading.equalTo(@16);
        make.height.equalTo(@20);
        make.trailing.lessThanOrEqualTo(self.view).offset(-105);
        make.top.equalTo(cameraView).offset(10);
    });

    [self.view addSubview:self.commerceEnterView];
    [self.commerceEnterView.enterButton addTarget:self action:@selector(clickCommerceEnterButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    ACCMasMaker(self.commerceEnterView, {
        make.left.equalTo(@8);
        make.top.equalTo(cameraView).offset(5);
        make.height.equalTo(@30);
    });

    self.coordinator.stickerSwitchTabView = self.switchTabView;
    self.coordinator.contentCollectionView = self.stickerContentCollectionView;
}

- (NSInteger)getFavoriteButtonBackgroundWidth
{
    NSString *title = self.favoriteButton.titleLabel.text;
    UIFont *font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightSemibold];
    NSStringDrawingOptions opts = NSStringDrawingUsesLineFragmentOrigin |
    NSStringDrawingUsesFontLeading;
    NSDictionary *attributes = @{NSFontAttributeName: font};
    CGSize textSize = [title boundingRectWithSize:CGSizeMake(MAXFLOAT, 21)
                                          options:opts
                                       attributes:attributes
                                          context:nil].size;
    // 按钮图片与标题间隔2，图片加左右间隔44
    return textSize.width + 46;
}

- (UIView *)bottomContraintNeighborView
{
    return self.stickerBackgroundView;
}

- (void)updateFavoriteView
{
    CGFloat lowGap = acc_favoriteButtonLowBottomGap;
    if (self.displayingTrayView & AWEModernStickerTrayViewOptionAggregated) {
        lowGap = acc_newLayoutFavoriteButtonLowBottomGap;
    }
    CGFloat offset = self.displayingTrayView > 0 ? lowGap: acc_favoriteButtonHighBottomGap;
    [self updateButtonViewConstraintsWithOffset:offset];
}

- (void)updateButtonViewConstraintsWithOffset:(CGFloat)offset
{
    ACCMasUpdate(self.favoriteView, {
        make.bottom.equalTo([self bottomContraintNeighborView].mas_top).offset(offset);
    });
}

- (void)updateFavoriteViewAndLayerConstraintsAnimated:(BOOL)animated
{
    if (!self.favoriteView.superview) {
        return;
    }
    NSInteger favoriteButtonBackgroundWidth = [self getFavoriteButtonBackgroundWidth];
    ACCMasUpdate(self.favoriteView, {
        make.width.equalTo(@(favoriteButtonBackgroundWidth + 18));
    });

    // 将收藏文案和按钮居中
    NSInteger shift = (self.favoriteButton.acc_width - 4 - (self.favoriteButton.titleLabel.acc_width + self.favoriteButton.imageView.acc_width)) / 2;
    _favoriteButton.imageEdgeInsets = UIEdgeInsetsMake(-1, shift, 1, 0);
    _favoriteButton.titleEdgeInsets = UIEdgeInsetsMake(-1, shift, 1, 0);

    [self.favoriteView.superview layoutIfNeeded];

    for (CALayer *layer in self.favoriteView.layer.sublayers) {
        if ([layer.name isEqualToString:@"cornerButtonLayer"]) {
            CGRect frame = layer.frame;
            frame.size.width = favoriteButtonBackgroundWidth;
            if (!animated) {
                [CATransaction begin];
                [CATransaction setDisableActions:YES];
                layer.frame = frame;
                [CATransaction commit];
            } else {
                layer.frame = frame;
            }
        }
    }
}

- (CGFloat)stickerPannelGrayBackAreagroundHeight
{
    if ([UIDevice acc_isIPad]) {
        return 320;
    }
    return 264 + ACC_IPHONE_X_BOTTOM_OFFSET;
}

#pragma mark - actions

- (void)saveSubViewsHiddenStateIfNeeded
{
    self.needRestoreSubViewHiddenStates = ACC_FLOAT_EQUAL_TO(self.aggregatedEffectView.alpha, 1.0f) ||
                                           ACC_FLOAT_EQUAL_TO(self.mattingView.alpha, 1.0f);
    if (self.needRestoreSubViewHiddenStates) {
        self.aggregatedEffectViewAlpha = self.aggregatedEffectView.alpha;
        self.mattingViewAlpha = self.mattingView.alpha;
        self.aggregatedEffectView.alpha = 0;
        self.mattingView.alpha = 0;
        [self updateButtonViewConstraintsWithOffset:acc_favoriteButtonHighBottomGap];
    }
}

- (void)restoreSubViewsHiddenStateIfNeeded
{
    if (self.needRestoreSubViewHiddenStates) {
        self.aggregatedEffectView.alpha = self.aggregatedEffectViewAlpha;
        self.mattingView.alpha = self.mattingViewAlpha;
        self.needRestoreSubViewHiddenStates = NO;
        [self updateButtonViewConstraintsWithOffset:acc_favoriteButtonLowBottomGap];
    }
}

- (void)p_clearStickerApplyButtonClicked:(UIButton *)button
{
    NSString *errorToast = nil;
    if ([self.actionDelegate respondsToSelector:@selector(modernStickerViewControllerShouldApplyEffect:errorToast:)] &&
        ![self.actionDelegate modernStickerViewControllerShouldApplyEffect:nil errorToast:&errorToast]) {
        if (!ACC_isEmptyString(errorToast)) {
            [ACCToast() showError:errorToast];
        }
        return;
    }

    self.originStickerUserView.hidden = YES;
    self.hotEffectHintView.hidden = YES;
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.trackingInfoDictionary];
    [params setValue:@"none" forKey:@"tab_name"];
    params[@"enter_from"] = @"video_shoot_page";
    if (self.needTrackEvent) {
        [ACCTracker() trackEvent:@"click_prop_tab" params:params needStagingFlag:NO];
    }

    [self stickerClearAllEffect];
}

- (void)p_onClearBackgroundPress:(UITapGestureRecognizer *)g
{
    [self p_dismissWithTrackKey:@"clickClearBackground"];
}

- (void)p_onFavoriteBtnClicked:(ACCCollectionButton *)btn
{
    NSMutableDictionary *trackerInfo = [self.trackingInfoDictionary mutableCopy];
    trackerInfo[@"enter_method"] = @"click_favorite_prop";

    @weakify(self);
    [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) requireLogin:^(BOOL success) {
        @strongify(self);
        if (success) {
            [self p_onFavoriteBtnClicked_IMP:btn];
        }
    } withTrackerInformation:trackerInfo];
}

- (void)p_onFavoriteBtnClicked_IMP:(ACCCollectionButton *)btn
{
    // 无论是聚合类还是单个贴纸都用selectedEffectModel
    IESEffectModel *effectModel = self.selectedEffectModel;
    if (!effectModel.effectIdentifier) {
        return;
    }

    NSString *AWEStickerFavoriteButtonFirstClickKey = @"AWEStickerFavoriteButtonFirstClickKey";
    if (![ACCCache() boolForKey:AWEStickerFavoriteButtonFirstClickKey]) {
        [ACCCache() setBool:YES forKey:AWEStickerFavoriteButtonFirstClickKey];
        if (!self.favoriteButton.selected) {
            [self.switchTabView animateFavoriteOnIndex:0 showYellowDot:YES];
        }
    } else if (!self.favoriteButton.selected) {
        [self.switchTabView animateFavoriteOnIndex:0 showYellowDot:NO];
    }

    @weakify(self);

    BOOL currentFavoriteStatus = [self p_getFavoriteStatusForSticker:effectModel];

    [EffectPlatform changeEffectsFavoriteWithEffectIDs:@[effectModel.effectIdentifier] panel:self.dataManager.panelName addToFavorite:!currentFavoriteStatus completion:^(BOOL success, NSError * _Nullable error) {
        @strongify(self);
        if (error) {
            AWELogToolError(AWELogToolTagEdit, @"[initWithStickerModel] -- error:%@", error);
        }
        if (success && effectModel) {
            if (!currentFavoriteStatus) {
                [self.dataManager addFavoriteEffect:effectModel];
                NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.trackingInfoDictionary];
                [params setValue:@"click_main_panel" forKey:@"enter_method"];
                [params setValue:effectModel.effectIdentifier ?: @"" forKey:@"prop_id"];
                params[@"enter_from"] = @"video_shoot_page";
                [ACCTracker() trackEvent:@"prop_save" params:[params copy] needStagingFlag:NO];
            } else {
                [self.dataManager removeFavoriteEffect:effectModel];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AWEFavoriteActionNotification" object:nil userInfo:@{@"type":@(5),@"itemID":effectModel.effectIdentifier?:@"",@"action":@(currentFavoriteStatus)}];  //5：道具收藏列表
            AWEModernStickerContentCollectionViewCell *contentCell = (AWEModernStickerContentCollectionViewCell *)[self.stickerContentCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

            [contentCell.collectionView reloadData];
            NSString *emptyLabel = self.dataManager.collectionEffects.count == 0 ? ACCLocalizedCurrentString(@"com_mig_you_can_now_add_stickers_to_favorites_to_use_or_find_them_later") : nil;
            [contentCell configWithEmptyString:emptyLabel];
        } else {
            IESEffectModel *currentEffectModel = self.selectedEffectModel;
            if ([currentEffectModel.effectIdentifier isEqualToString:effectModel.effectIdentifier] && !self.favoriteButton.hidden) {
                [self.favoriteButton.layer removeAllAnimations];
                self.favoriteButton.selected = currentFavoriteStatus;
            }
        }
    }];
    [btn beginTouchAnimation];
    if ([self enableNewFavoritesTitle]) {
        [self updateFavoriteViewAndLayerConstraintsAnimated:YES];
    }
}

- (void)clickCommerceEnterButtonAction:(id)sender
{
    [ACCTracker() trackEvent:@"click_transform_link"
                                     params:@{@"shoot_way": self.dataManager.referString ?: @"",
                                              @"carrier_type": @"prop_panel",
                                              @"prop_id": self.commerceEnterView.effectModel.effectIdentifier ?: @""}
                            needStagingFlag:NO];

    [IESAutoInline(ACCBaseServiceProvider(), ACCCommerceServiceProtocol) runTasksWithContext:^(ACCAdTaskContext * _Nonnull context) {
        context.openURL = self.commerceEnterView.effectModel.commerceOpenURL;
        context.webURL = self.commerceEnterView.effectModel.commerceWebURL;
    } runTasks:@[@(ACCAdTaskTypeInAppOpenURL),@(ACCAdTaskTypeOpenOtherApp),@(ACCAdTaskTypeLandingPage)]];
}

#pragma mark - update

- (void)p_refreshStickerViews
{
    NSInteger shouldSelectIndex = 0;
    if (self.dataManager.stickerCategories.count > 0 && (!self.isStoryMode)) {
        shouldSelectIndex = 1;
    }
    if (self.inputSelectCategoryIndex && self.dataManager.stickerCategories.count > 0) {
        // 外部传入加上初始值
        shouldSelectIndex += self.inputSelectCategoryIndex.integerValue;
    }
    @weakify(self);
    [self.switchTabView refreshWithStickerCategories:self.dataManager.stickerCategories completion:^(BOOL finished) {
        @strongify(self);
        [self.switchTabView selectItemAtIndex:shouldSelectIndex animated:NO];
        ACCBLOCK_INVOKE(self.stickerViewDidRefreshCategories);
        if (self.dataManager.downloadingEffects.count <= 0) {
            [CATransaction begin];
            [CATransaction setCompletionBlock:^{
                @strongify(self);
                [self p_tryApplyFirstEffectWithTabIndex:shouldSelectIndex];
            }];
            [self.stickerContentCollectionView reloadData];
            [self.stickerContentCollectionView setNeedsLayout];
            [self.stickerContentCollectionView layoutIfNeeded];
            [CATransaction commit];
        }
        [self.coordinator scrollContentCollectionViewToItemWithoutAnimation:[NSIndexPath indexPathForRow:shouldSelectIndex inSection:0]];
    }];
}

- (void)p_tryApplyFirstEffectWithTabIndex:(NSInteger)tabIndex
{
    if (self.effectToApply) {
        AWEModernStickerContentCollectionViewCell *cell = (AWEModernStickerContentCollectionViewCell *) [self.stickerContentCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:tabIndex inSection:0]];
        if (cell.collectionView) {
            IESEffectModel *firstModel = [self p_effectModelForIndexPath:[NSIndexPath indexPathForItem:0 inSection:tabIndex]];
            if ([firstModel isEqual:self.effectToApply]) {
                [self collectionView:cell.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            }
        }
    }
}

- (void)p_refreshDataManager
{
    self.stickerTabContainerView.userInteractionEnabled = NO;
    self.stickerContentCollectionView.hidden = YES;
    self.loadingView.hidden = NO;
    self.errorView.hidden = YES;

    // 同步下tabview的和贴纸面板的数据
    [self p_refreshStickerViews];

    @weakify(self);
    void (^completion)(BOOL downloadSuccess) = ^(BOOL downloadSuccess) {
        @strongify(self);
        NSInteger categoriesCount = self.dataManager.responseModel.categories.count;
        if ([self enablePagingStickers]) {
            categoriesCount = self.dataManager.responseModelNew.categories.count;
        }
        if (downloadSuccess && categoriesCount == 0) {
            self.loadingView.hidden = YES;
            self.errorView.hidden = NO;
            [ACCToast() showError: ACCLocalizedCurrentString(@"com_mig_failed_to_download_the_face_filter_please_try_again_later")];
            [self trackStickerPanelLoadPerformanceWithStatus:1];

            return;
        }
        if (downloadSuccess) {
            self.loadingView.hidden = YES;
            self.stickerContentCollectionView.hidden = NO;
            self.stickerTabContainerView.userInteractionEnabled = YES;
            self.fetchCategoryDataCompleted = NO;
            [self p_refreshStickerViews];
        } else {
            self.loadingView.hidden = YES;
            self.errorView.hidden = NO;
            if (!BTDNetworkConnected()) {
                [ACCToast() show:ACCLocalizedCurrentString(@"com_mig_no_network_connection_nwnoxz")];
            }

            [self trackStickerPanelLoadPerformanceWithStatus:1];
        }
    };

    if ([self enablePagingStickers]) {
        NSString *cateKey = self.inputSelectCategoryIndex != nil ? [self.dataManager.stickerCategories acc_objectAtIndex:self.inputSelectCategoryIndex.integerValue].categoryKey : @"";
        [self.dataManager fetchCategoriesForRecordStickerWithCompletion:completion loadEffectsForCategoryKey:cateKey];
    } else {
        [self.dataManager downloadRecordStickerWithCompletion:completion];
    }

    if (self.dataManager.panelType == AWEStickerPanelTypeStory) {
        // story不需要下载收藏列表
        return;
    }

    AWELogToolDebug(AWELogToolTagNone, @"begin download collection stickers on p_refreshDataManager");
    [self.dataManager downloadCollectionStickersWithCompletion:^(BOOL downloadSuccess) {
        AWELogToolDebug(AWELogToolTagNone, @"download collection stickers on p_refreshDataManager|downloadSuccess=%d", downloadSuccess);
        @strongify(self)
        if (downloadSuccess) {
            // 收藏状态是否点亮，由“当前选中道具”是否在“我的收藏列表”中决定
            // 加载我的收藏列表成功后，根据当前选中的道具更新收藏状态icon
            [self p_updateFavoriteButtonWithSticker:self.selectedEffectModel manually:NO];

            AWEModernStickerContentCollectionViewCell *cell = (AWEModernStickerContentCollectionViewCell *)[self.stickerContentCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            AWELogToolDebug(AWELogToolTagNone, @"download collection stickers on p_refreshDataManager|cell=%@|collectionView=%@", cell, cell.collectionView);
            if (cell) {
                [cell.collectionView reloadData];
            }
        }
    }];
}

- (void)p_mattingViewStartingFaceDetect
{
    [self.mattingView resumeFaceDetect];
}

- (void)p_updateFavoriteButtonWithSticker:(IESEffectModel *)model manually:(BOOL)manually
{
    self.favoriteView.hidden = self.isStoryMode || model == nil || model.forbidFavorite;
    self.stickerShowcaseEntranceView.hidden = self.favoriteView.isHidden || ![IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) isStickerShowcaseEntranceEnabled];
    NSString *createID = @"";
    if ([self.actionDelegate respondsToSelector:@selector(providedPublishModel)]) {
        createID = [self.actionDelegate providedPublishModel].repoContext.createId;
    }
    [self.stickerShowcaseEntranceView updateWithSticker:model creationID:createID];
    if (manually) {
        NSString *AWEStickerFavoriteBubbleShowKey = @"AWEStickerFavoriteBubbleShowKey";
        if (![ACCCache() boolForKey:AWEStickerFavoriteBubbleShowKey] && model && ![self enableNewFavoritesTitle]) {
            self.favoriteBubble = [ACCBubble() showBubble: ACCLocalizedCurrentString(@"com_mig_you_can_now_add_stickers_to_favorites_to_use_or_find_them_later_vic8ce")
                     forView:self.favoriteView
                inDirection:ACCBubbleDirectionUp bgStyle:ACCBubbleBGStyleDefault];
            [ACCCache() setBool:YES forKey:AWEStickerFavoriteBubbleShowKey];
        }
    }
    [self.favoriteButton.layer removeAllAnimations];
    if (model) {
        self.favoriteButton.selected = [self p_getFavoriteStatusForSticker:model];
    }
    self.favoriteButton.hidden = NO;
    if ([self enableNewFavoritesTitle]) {
        [self updateFavoriteViewAndLayerConstraintsAnimated:NO];
    }
}

- (void)stickerWillApplyAction
{
    [self p_hiddenMattingView];
}

- (void)sticker:(IESEffectModel *)sticker isCancel:(BOOL)isCancel appliedSuccess:(BOOL)success
{
    if (!ACC_isEmptyString(self.actionDelegate.providedPublishModel.repoProp.liveDuetPostureImagesFolderPath)) {
        return;
    }

    // pixaloop
    if ([sticker isPixaloopSticker]) {
        NSDictionary *pixaloopSDKExtra = [sticker pixaloopSDKExtra];
        NSString *plStr = @"pl";
        NSInteger albumFilterNumber = [pixaloopSDKExtra acc_albumFilterNumber:plStr];
        NSString *pixaloopImgK = [pixaloopSDKExtra acc_pixaloopImgK:plStr];
        if (!ACC_isEmptyString(pixaloopImgK) && !ACC_isEmptyString(sticker.effectIdentifier)) {
            NSArray<NSString *> *pixaloopAlg = [pixaloopSDKExtra acc_pixaloopAlg:plStr];
            if (albumFilterNumber == AWEFilterNumberNoFilter || albumFilterNumber == AWEFilterNumberAlbumFilter) {
                pixaloopAlg = @[];
            }
            NSString *pixaloopRelation = [pixaloopSDKExtra acc_pixaloopRelation:plStr];
            [self showMattingViewWithPixaloopAlg:pixaloopAlg pixaloopRelation:pixaloopRelation pixaloopImgK:pixaloopImgK pixaloopSDKExtra:pixaloopSDKExtra success:success sticker:sticker];
        }
        return;
    }

    if ([sticker isVideoBGPixaloopSticker]) {
        if (self.videoBGStickerManager.currentCameraMode.modeId != ACCRecordModeLive) {
            NSDictionary *pixaloopSDKExtra = [sticker pixaloopSDKExtra];
            NSString *pixaloopImgK = [pixaloopSDKExtra acc_pixaloopImgK:@"vl"];
            if (!ACC_isEmptyString(pixaloopImgK) && !ACC_isEmptyString(sticker.effectIdentifier) && !isCancel && sticker.downloaded) {
               NSArray<NSString *> *pixaloopAlg = [pixaloopSDKExtra acc_pixaloopAlg:@"vl"];
               //NSString *pixaloopRelation = [pixaloopSDKExtra pixaloopRelation:@"vl"];
               NSString *pixaloopResourcePath = [pixaloopSDKExtra acc_pixaloopResourcePath:@"vl"];
               [self showMattingViewWithVideoBGPixaloop:pixaloopAlg pixaloopResourcePath:pixaloopResourcePath pixaloopImgK:pixaloopImgK success:success sticker:sticker];
               self.videoBGStickerManager.defaultVideoAssetUrl = [NSURL fileURLWithPath: [sticker.filePath stringByAppendingString:pixaloopResourcePath]];
               self.videoBGStickerManager.pixaloopVKey = pixaloopImgK;
               self.videoBGStickerManager.isMultiScanBgVideoType = [sticker isTypeMultiScanBgVideo];
               [self.videoBGStickerManager applyVideoBGToCamera:self.videoBGStickerManager.currentApplyVideoBGUrl];
               [self.actionDelegate stickerHintViewShowWithEffect:sticker];
            }
        }
        return;
    }

    // Reset photo collector
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.actionDelegate stickerHintViewShowWithEffect:sticker];
        self.mattingView.photoCollector = nil;
    });
}

- (BOOL)isDirectShoot
{
    if ([self.actionDelegate respondsToSelector:@selector(providedPublishModel)]) {
        return [self.actionDelegate.providedPublishModel.repoTrack.referString isEqualToString:@"direct_shoot"];
    }
    return NO;
}

- (void)showMattingViewWithVideoBGPixaloop:(NSArray<NSString *> *)pixaloopAlg
pixaloopResourcePath:(NSString *)pixaloopResourcePath
    pixaloopImgK:(NSString *)pixaloopImgK
         success:(BOOL)success
         sticker:(IESEffectModel *)sticker
{
    if (pixaloopAlg == nil || pixaloopImgK == nil) {
        return;
    }
    if (success && [ACCDeviceAuth isiOS14PhotoNotDetermined]) {
        acc_dispatch_main_async_safe(^{
            [self p_presentImagePickerViewController];
        });
    } else {
        [ACCDeviceAuth requestPhotoLibraryPermission:^(BOOL permissionSuccess) {
           if (!permissionSuccess) {
               return ;
           }
           dispatch_async(dispatch_get_main_queue(), ^{
               //NSString *const identifier = [@"video_bg" stringByAppendingString:sticker.effectIdentifier];
               self.mattingView.photoCollector = [[AWEAlbumVideoCollector alloc] initWithIdentifier:@"video_bg" pixaloopVKey:pixaloopImgK pixaloopResourcePath: pixaloopResourcePath];
               self.mattingView.photoCollector.maxDetectCount = 100;
               self.mattingView.showPixaloopPlusButton = YES;
               if (success) {
                   [self p_showMattingViewWithProp:sticker];
               } else {
                   [self p_hiddenMattingView];
               }
           });
        }];
    }
}

- (void)showMattingViewWithPixaloopAlg:(NSArray<NSString *> *)pixaloopAlg
                      pixaloopRelation:(NSString *)pixaloopRelation
                          pixaloopImgK:(NSString *)pixaloopImgK
                      pixaloopSDKExtra:(nonnull NSDictionary *)pixaloopSDKExtra
                               success:(BOOL)success
                               sticker:(IESEffectModel *)sticker
{
    [self.actionDelegate stickerHintViewShowWithEffect:sticker];
    if ([sticker isMultiAssetsPixaloopProp]) {
        if (self.multiAssetsPixaloopSelectedAssetArray.count > 0) {
            acc_dispatch_main_async_safe(^{
                [self p_multiAssetsPixaloopDidChooseAssetModelArray:self.multiAssetsPixaloopSelectedAssetArray];
            });
        }
    }
    // pixaloop类型贴纸处理
    if (pixaloopAlg == nil || pixaloopImgK == nil) {
        return;
    }
    if (success && [ACCDeviceAuth isiOS14PhotoNotDetermined]) {
        acc_dispatch_main_async_safe(^{
            [self p_presentImagePickerViewController];
        });
    } else {
        @weakify(self);
        [ACCDeviceAuth requestPhotoLibraryPermission:^(BOOL permissionSuccess) {
            @strongify(self);
            if (!permissionSuccess) {
                return ;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *const identifier = [@"pixaloop" stringByAppendingString:sticker.effectIdentifier];
                self.mattingView.photoCollector = [[AWEAlbumPixaloopPhotoCollector alloc] initWithIdentifier:identifier
                                                                                                 pixaloopAlg:pixaloopAlg
                                                                                            pixaloopRelation:pixaloopRelation
                                                                                                pixaloopImgK:pixaloopImgK
                                                                                            pixaloopSDKExtra:pixaloopSDKExtra];
                [self.mattingView addPhotoLibraryChangeObserver];
                self.mattingView.showPixaloopPlusButton = YES;
                if (success) {
                    [self p_showMattingViewWithProp:sticker];
                } else {
                    [self p_hiddenMattingView];
                }
            });
        }];
    }

}

- (void)stickerClearAllEffect
{
    ACCBLOCK_INVOKE(self.cancelStickerMusicBlock,self.selectedEffectModel);
    [self p_hiddenMattingView];
    [self p_clearSeletedCells];
    [self p_setSelectedEffectModelWithEffect:nil];
}

- (void)setSelectedSticker:(IESEffectModel *)model selectedChildSticker:(IESEffectModel *)childModel
{
    self.selectedEffectModel = model;
    self.selectedChildEffectModel = childModel;
    self.lastClickedEffectModel = childModel;
    [self updateOriginStickerUserViewAndCommerceEnterViewWithEffect:model];
    [self p_updateHotEffectHintWithEffect:model];
    [self reloadStickerContentCollectionViewIfNeeded];
    [self.aggregatedEffectView updateSelectEffectWithEffect:self.selectedChildEffectModel];
    [self p_updateFavoriteButtonWithSticker:model manually:NO];
}

- (void)setSelectedSticker:(IESEffectModel *)model selectedComposerEffect:(id<AWEComposerEffectProtocol>)composerEffect
{
    self.selectedEffectModel = model;
    self.lastClickedEffectModel = model;
    if (self.isShowing) {
        [self updateOriginStickerUserViewAndCommerceEnterViewWithEffect:model];
        [self p_updateHotEffectHintWithEffect:model];
        [self reloadStickerContentCollectionViewIfNeeded];
    }
    [self p_updateFavoriteButtonWithSticker:model manually:NO];
}

- (void)switchCameraToFront:(BOOL)isFront
{
    [UIView animateWithDuration:0.3 animations:^{
        self.cameraButton.transform = CGAffineTransformRotate(self.cameraButton.transform, M_PI);
    }];
}

- (void)reloadStickerContentCollectionViewIfNeeded
{
    [self.stickerContentCollectionView reloadData];
}

#pragma mark - UICollectionViewDataSource

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    return [UICollectionReusableView new];
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    AWEModernStickerCollectionViewTag tag = collectionView.tag / 1000;
    switch (tag) {
        case AWEModernStickerCollectionViewTagTitle: {
            // Categories Tab
            NSAssert(NO, @"data source should implement by AWEModernStickerSwitchTabView!!!");
            return [[UICollectionViewCell alloc] init];
            break;
        }
        case AWEModernStickerCollectionViewTagContent: {
            // content部分
            return [self p_collectionView:collectionView getContentCellForIndexPath:indexPath];
            break;
        }
        case AWEModernStickerCollectionViewTagSticker: {
            // sticker部分，单独的effect item
            return [self p_collectionView:collectionView getStickerCellForIndexPath:indexPath];
            break;
        }
        default:{
            NSAssert(NO, @"should not reach defalut case");
            break;
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[AWEModernStickerCollectionViewCell class]]) {
        AWEModernStickerCollectionViewCell *effectCell = (AWEModernStickerCollectionViewCell *)cell;
        [self p_trackStickerShowWithNewEffect:effectCell.effect atIndexPath:indexPath];
    }
}

- (AWEModernStickerContentCollectionViewCell *)p_collectionView:(UICollectionView *)collectionView getContentCellForIndexPath:(NSIndexPath *)indexPath
{
    // 道具栏具体道具容器
    AWEModernStickerContentCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[AWEModernStickerContentCollectionViewCell identifier] forIndexPath:indexPath];
    // 将`cell`内部的`collectionView`的`delegate`与`dataSource`都转交给`self`，由self进行处理
    if (indexPath.row == 0) {
        NSString *emptyLabel = self.dataManager.collectionEffects.count == 0 ? ACCLocalizedCurrentString(@"com_mig_you_can_now_add_stickers_to_favorites_to_use_or_find_them_later") : nil;
        [cell configWithEmptyString:emptyLabel];
    } else {
        [cell configWithEmptyString:nil];
    }
    [cell setCollectionViewDataSource:self delegate:self section:AWEModernStickerCollectionViewTagSticker * 1000 + indexPath.row];
    _currentContentCellIndexPath = indexPath;
    return cell;
}

- (NSMutableDictionary *)createChildEffectsContainerTrackingInfoDict {
    NSMutableDictionary *trackingInfoDict =
    [NSMutableDictionary dictionaryWithDictionary:self.trackingInfoDictionary];
    trackingInfoDict[@"parent_pop_id"] = self.selectedEffectModel.effectIdentifier ?: @"";
    trackingInfoDict[@"tab_name"] = self.switchTabView.selectedCategoryName;
    return trackingInfoDict;
}

- (AWEModernStickerCollectionViewCell *)p_collectionView:(UICollectionView *)collectionView getStickerCellForIndexPath:(NSIndexPath *)indexPath
{
    AWEModernStickerCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[AWEModernStickerCollectionViewCell identifier] forIndexPath:indexPath];
    NSInteger section = collectionView.tag % 1000;
    IESEffectModel *effectModel = nil;
    if (section == 0 && !self.isStoryMode) {
        effectModel = [self.dataManager.collectionEffects objectAtIndex:indexPath.item];
    } else {
        IESCategoryModel *specificCategoryModel = [self.dataManager.stickerCategories objectAtIndex:self.isStoryMode ? section : section - 1];
        effectModel = [specificCategoryModel.aweStickers objectAtIndex:indexPath.item];
    }
    cell.isInPropPanel = YES;
    IESEffectModel *potentialChildModel = [self.dataManager firstChildEffectForEffect:effectModel];

    [cell configWithEffectModel:effectModel childEffectModel:potentialChildModel];

    if (effectModel) {
        self.effectIndexPathBindingMap[effectModel.effectIdentifier] = indexPath;
        // 是否开启下载
        if ([self.dataManager.downloadingEffects containsObject:effectModel.effectIdentifier] || [AWEEffectPlatformManager sharedManager].downloadingEffectsDict[effectModel.md5]) {
            // downloadingEffects正在下载 || 下载管理器判定当前正在下载
            [self p_handleEffectDownloadWithCell:cell collectionView:collectionView indexPath:indexPath];
        }
    }

    if (self.selectedEffectModel) {
        BOOL isSelectedEffectModel = [self.selectedEffectModel.effectIdentifier isEqualToString:cell.effect.effectIdentifier];
        if (isSelectedEffectModel) {
            ((AWEModernStickerCollectionViewCell *)cell).isStickerSelected = YES;
            ((AWEModernStickerCollectionViewCell *)cell).selectedIndicatorView.alpha = 1.0;
            [((AWEModernStickerCollectionViewCell *)cell) startPropNameScrollingAnimation];
            // 如果这个时候还存在选择的子特效，则需要展示子特效面板
            if (self.selectedChildEffectModel) {

                NSArray<IESEffectModel *> *currentChildrenEffects = self.selectedEffectModel.childrenEffects;

                if (currentChildrenEffects.count) {
                    //更新集合特效列表
                    NSMutableDictionary * trackingInfoDict = [self createChildEffectsContainerTrackingInfoDict];
                    self.aggregatedEffectView.trackingInfoDictionary = [trackingInfoDict copy];

                    [self.aggregatedEffectView updateAggregatedEffectArrayWith:currentChildrenEffects];
                    [self.aggregatedEffectView updateSelectEffectWithEffect:self.selectedChildEffectModel];
                    [self p_showAggregatedEffectView];
                } else {
                    [self p_hiddenAggregatedEffectViewWithCompletionBlock:nil];
                }
            }
            [cell configWithEffectModel:self.selectedEffectModel childEffectModel:self.selectedChildEffectModel];
        } else {
            ((AWEModernStickerCollectionViewCell *)cell).isStickerSelected = NO;
            ((AWEModernStickerCollectionViewCell *)cell).selectedIndicatorView.alpha = 0.0;
        }
    } else {
        BOOL isSameEffectModel = [self.dataManager.selectedEffect.effectIdentifier isEqualToString:cell.effect.effectIdentifier];
        if (isSameEffectModel) {
            [cell configWithEffectModel:self.dataManager.selectedEffect childEffectModel:self.dataManager.selectedChildEffect];
        }
        ((AWEModernStickerCollectionViewCell *)cell).isStickerSelected = NO;
        ((AWEModernStickerCollectionViewCell *)cell).selectedIndicatorView.alpha = 0.0;
    }

    return cell;
}

- (void)p_trackStickerShowWithNewEffect:(IESEffectModel *)effect atIndexPath:(NSIndexPath *)indexPath
{
    [self trackStickerPanelLoadPerformanceWithStatus:0];

    if (self.lastSelectedTabIndex != [self selectedTabIndex]) {
        // 第一个发现selectedTabIndex变动的，清空所有已上报记录
        self.lastSelectedTabIndex = [self selectedTabIndex];
        [self.hasShowedStickerSet removeAllObjects];
        [self.effectIndexPathBindingMap removeAllObjects];
    }
    if (self.coordinator.contentCollectionViewIsScrolling) {
        // 贴纸面板在左右滑动，说明在切换tab
        [self.hasShowedStickerSet addObject:effect.effectIdentifier];
        self.effectIndexPathBindingMap[effect.effectIdentifier] = indexPath;
        [self p_trackStickerShow:effect index:indexPath.item designatedTabName:[self p_currentTabNameIfStickerContentCollectionViewIsScrolling]];
    } else {
        if (effect.effectIdentifier) {
            self.effectIndexPathBindingMap[effect.effectIdentifier] = indexPath;
            if (![self.hasShowedStickerSet containsObject:effect.effectIdentifier]) {
                [self.hasShowedStickerSet addObject:effect.effectIdentifier];
                [self p_trackStickerShow:effect index:indexPath.item designatedTabName:self.switchTabView.selectedCategoryName];
            }
        }
    }
}


- (NSString *)p_currentTabNameIfStickerContentCollectionViewIsScrolling {
    // Note: self.switchTabView.selectedIndex 在滑动动画过程中被延迟设置是不准的，这里取当前面板的indexPath
    NSInteger towardsIndex = self.currentContentCellIndexPath.item;
    NSString *tabName = self.switchTabView.selectedCategoryName;
    if (towardsIndex == 0 && !self.isStoryMode) {
        tabName =  ACCLocalizedCurrentString(AWEModernStickerSwitchTabViewTabNameCollection);
    } else {
        towardsIndex -= !self.isStoryMode ? 1 : 0;
        if (towardsIndex >= 0 && towardsIndex < (NSInteger)self.dataManager.stickerCategories.count) {
            tabName = self.dataManager.stickerCategories[towardsIndex].categoryName;
        }
    }
    return tabName;
}

- (void)p_trackStickerShow:(IESEffectModel *)effect index:(NSInteger)index designatedTabName:(NSString *)designatedTabName {
    if (!self.needTrackEvent) {
        return;
    }
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    if (self.dataManager.panelType != AWEStickerPanelTypeLive) {
        attributes[@"is_photo"] = self.isPhotoMode ? @1 : @0;
    }
    attributes[@"position"] = self.dataManager.panelType == AWEStickerPanelTypeLive ? @"live_set" : @"shoot_page";
    [ACCTracker() trackEvent:@"prop"
                                      label:@"show"
                                      value:effect.effectIdentifier ?: @""
                                      extra:nil
                                 attributes:attributes];
    AWEVideoPublishViewModel *publishModel = [self.actionDelegate providedPublishModel];
    if (publishModel.repoContext.recordSourceFrom != AWERecordSourceFromUnknown) {
        return;
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.trackingInfoDictionary];
    [params setValue:@"click_main_panel" forKey:@"enter_method"];
    [params setValue:effect.effectIdentifier ?: @"" forKey:@"prop_id"];
    [params setValue:effect.gradeKey ?: @"" forKey:@"prop_index"];
    [params setValue:@"" forKey:@"parent_pop_id"];
    if (!ACC_isEmptyString(designatedTabName)) {
       params[@"tab_name"] = designatedTabName;
    }
    params[@"order"] = @(index).stringValue;
    params[@"impr_position"] = @(index + 1).stringValue;
    params[@"prop_rec_id"] = ACC_isEmptyString(effect.recId) ? @"0": effect.recId;
    NSString *localPropId = [self localPropId];
    if (!ACC_isEmptyString(localPropId)) {
        params[@"from_prop_id"] = localPropId;
    }
    NSString *musicId = [self musicId];
    if (!ACC_isEmptyString(musicId)) {
        params[@"music_id"] = musicId;
    }
    [params addEntriesFromDictionary:publishModel.repoTrack.referExtra];
    [ACCTracker() trackEvent:@"prop_show" params:params needStagingFlag:NO];
}

- (void)p_trackVisibleStickersShowAtSection:(NSInteger)section {
    // 上报可见贴纸prop_show
    AWEModernStickerContentCollectionViewCell *targetContentCell;
    for (NSIndexPath *contentIndexPath in self.stickerContentCollectionView.indexPathsForVisibleItems) {
        if (contentIndexPath.item == section) {
            targetContentCell = (AWEModernStickerContentCollectionViewCell *)[self.stickerContentCollectionView cellForItemAtIndexPath:contentIndexPath];
            break;
        }
    }
    if (targetContentCell) {
        UICollectionView *contentCollectionView = targetContentCell.collectionView;
        for (NSIndexPath *indexPath in contentCollectionView.indexPathsForVisibleItems) {
            AWEModernStickerCollectionViewCell *stickerCell = (AWEModernStickerCollectionViewCell *)[contentCollectionView cellForItemAtIndexPath:indexPath];
            if (stickerCell) {
                [self.hasShowedStickerSet removeObject:stickerCell.effect.effectIdentifier];
                [self.hasShowedStickerSet addObject:stickerCell.effect.effectIdentifier];
                [self p_trackStickerShow:stickerCell.effect index:indexPath.item designatedTabName:self.switchTabView.selectedCategoryName];
            }
        }
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    AWEModernStickerCollectionViewTag tag = collectionView.tag / 1000;
    switch (tag) {
        case AWEModernStickerCollectionViewTagTitle: {
            return self.isStoryMode ? self.dataManager.stickerCategories.count : self.dataManager.stickerCategories.count + 1;
            break;
        }
        case AWEModernStickerCollectionViewTagContent: {
            return self.isStoryMode ? self.dataManager.stickerCategories.count : self.dataManager.stickerCategories.count + 1;
            break;
        }
        case AWEModernStickerCollectionViewTagSticker: {
            NSInteger specificSection = collectionView.tag % 1000;
            if (!self.isStoryMode && specificSection == 0) {
                return self.dataManager.collectionEffects.count;
            }
            NSInteger index = self.isStoryMode ? specificSection : specificSection - 1;
            IESCategoryModel *category = [self.dataManager.stickerCategories objectAtIndex:index];
            return category.aweStickers.count;
            break;
        }
        default:{
            NSAssert(NO, @"should not reach defalut case");
            break;
        }
    }
    return 0;
}

#pragma mark - UICollectionViewDelegate

/**
 仅处理每个`contentCell`中的`collectionView`的点击事件，因为`titleCollectionView`与`contentCollectionView`的`delegate`已经设置为`self.coodinator`

 @param collectionView `contentCell`中的`collectionView`
 @param indexPath 每个`contentCell`中的`collectionView`内部的`indexPath`，`section`总为0，如果要取得cell对应的data，要将`section`设置为collectionView的对应的真正的`section`
 */
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // 记录最后一次点击的effectModel，只有最后一次点击的cell在下载完成后自动应用贴纸
    AWEModernStickerCollectionViewCell *cell = (AWEModernStickerCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [self updateIconImageIfNeededForCell:cell atIndexPath:indexPath];
    NSString *errorToast = nil;

    if ([self.actionDelegate respondsToSelector:@selector(modernStickerViewControllerShouldApplyEffect:errorToast:)] &&
        ![self.actionDelegate modernStickerViewControllerShouldApplyEffect:([self isClickedCurrentApplyedEffect:cell.effect] ? nil : cell.effect) errorToast:&errorToast]) {
        if (!ACC_isEmptyString(errorToast)) {
            [ACCToast() showError:errorToast];
        }
        return;
    }

    self.lastClickedEffectModel = cell.effect;

    [[NSNotificationCenter defaultCenter] postNotificationName:ACCStickerViewControllerDidChangeSelection object:self userInfo:@{ACCNotificationCurrentStickerIDKey : cell.effect.effectIdentifier ?: @""}];

    if (cell.effect.effectType == IESEffectModelEffectTypeSchema) {
        if (cell.effect.schema.length) {
            [ACCRouter() transferToURLStringWithFormat:@"%@", cell.effect.schema];
        }
        return;
    }

    [self userDidTapEffect:cell.effect];
    [self updateOriginStickerUserViewAndCommerceEnterViewWithEffect:cell.effect];
    [self p_updateHotEffectHintWithEffect:cell.effect];
    [self p_handleEffectDownloadWithCell:cell collectionView:collectionView indexPath:indexPath];
}

- (void)updateIconImageIfNeededForCell:(AWEModernStickerCollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if (ACCConfigBool(kConfigBool_enable_sticker_dynamic_icon)) {
        IESEffectModel *effect = cell.effect;
        if (ACC_isEmptyArray(effect.dynamicIconURLs)) {
            return;
        }

        NSString *key = [NSString stringWithFormat:@"dynamic_icon_%@", effect.effectIdentifier];
        BOOL isDynamicIconEverClicked = [ACCCache() boolForKey:key];
        if (!isDynamicIconEverClicked) {
            [ACCCache() setBool:YES forKey:key];
            [cell updateStickerIconImage];
            [self.stickerContentCollectionView reloadData];
        }
    }
}

- (void)updateOriginStickerUserViewAndCommerceEnterViewWithEffect:(IESEffectModel *)effect
{
    if (effect == nil) {
        [self configCommerceEnteStickerWithEffectModel:nil];
        [self p_processCommerceStickerWithEffect:nil];
        [self p_configOriginStickerUserViewWithEffectModel:nil];
        return;
    }

    self.originStickerUserView.hidden = YES;
    self.commerceEnterView.hidden = YES;

    // if it has a commerce entrance, show info on commerceEnterView (highest priority)
    if ([effect hasCommerceEnter]) {
        [self configCommerceEnteStickerWithEffectModel:effect];
    } else if (effect.isCommerce) {
        // if has no commerce entrance, yet is a commerce prop, show info on originStickerUserView
        [self p_processCommerceStickerWithEffect:effect];
    } else {
        [self p_configOriginStickerUserViewWithEffectModel:effect];
    }
}

- (void)p_updateHotEffectHintWithEffect:(IESEffectModel *)effect
{
    self.hotEffectHintView.hidden = YES;
    if ((effect.isCommerce || effect.source == IESEffectModelEffectSourceOriginal) && ![effect hasCommerceEnter]) {
        return;
    }

    NSData *data = [effect.extra dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return;
    }

    NSError *error;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    AWELogToolError2(@"OldStickerPanel", AWELogToolTagRecord, @"error: %@",error);
    if (![jsonDict acc_boolValueForKey:@"dou_plus_effect"]) {
        return;
    }

    self.hotEffectHintView.hidden = NO;
    [self.hotEffectHintView showWithImageUrlList:effect.iconDownloadURLs];
}

- (void)p_handleEffectDownloadWithCell:(AWEModernStickerCollectionViewCell *)cell collectionView:(UICollectionView *)collectionView indexPath:(NSIndexPath *)indexPath {
    if (!cell || !cell.effect) {
        NSString *log = [(!cell ? @"empty cell" : @"empty effect") stringByAppendingFormat:@" at indexPath: %@", indexPath];
        AWELogToolInfo(AWELogToolTagRecord, @"%@", log);
        return;
    }
    IESEffectModel *cellEffect = cell.effect;
    IESEffectModel *potentialChildEffect = [self potentialChildEffectOfParentEffect:cellEffect];
    IESEffectModel *needDownloadEffect = potentialChildEffect ?: cell.effect;
    needDownloadEffect.propSelectedFrom = [self currentPropSelectedFrom];
    NSNumber *progress = [AWEEffectPlatformManager sharedManager].downloadingEffectsDict[needDownloadEffect.md5];
    if (progress != nil) {
        // 同步下载进度
        [cell updateDownloadProgress:progress.doubleValue];
    }
    if (![self.dataManager.downloadingEffects containsObject:cellEffect.effectIdentifier]) {
        // 从缓存取的effect.downloadStatus可能是AWEEffectDownloadStatusDownloading，这里要重新置为未下载，否则UI有问题
        cellEffect.downloadStatus = AWEEffectDownloadStatusUndownloaded;
    }
    if (needDownloadEffect.downloadStatus == AWEEffectDownloadStatusDownloading) {
        return;
    }


    //判断是否当前是合拍或者抢镜
    BOOL isDuetOrReact = NO;
    if ([self.actionDelegate respondsToSelector:@selector(providedPublishModel)]) {
        AWEVideoPublishViewModel *publishModel = [self.actionDelegate providedPublishModel];
        isDuetOrReact = publishModel.repoDuet.isDuet;
    }
    @weakify(self);
    @weakify(cell);
    @weakify(collectionView);
    @weakify(needDownloadEffect);

    AWEModernStickerCollectionViewCell *(^getActualUpdateCellBlock)(AWEModernStickerCollectionViewCell *) = ^(AWEModernStickerCollectionViewCell *originCell){
        @strongify(self);
        @strongify(collectionView);
        AWEModernStickerCollectionViewCell *updateCell;
        NSString *effectID = cellEffect.effectIdentifier;
        if (!self || !collectionView || ACC_isEmptyString(effectID)) {
            return updateCell;
        }
        // 判断下载的model跟cell当前的model是否是同一个
        BOOL originCellEffectIsNeedDownloadEffect = [originCell.effect.effectIdentifier isEqualToString:effectID];
        if (originCellEffectIsNeedDownloadEffect) {
            updateCell = originCell;
        } else if (self.effectIndexPathBindingMap[effectID]) {
            // 如果不是的话直接根据model去取cell
            NSIndexPath *indexPath = self.effectIndexPathBindingMap[effectID];
            updateCell = (AWEModernStickerCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
            if (![updateCell.effect.effectIdentifier isEqualToString:effectID]) {
                updateCell = nil;
            }
        }
        return updateCell;
    };

    // 优先级 贴纸特效的优先级大于音乐下载的优先级
    if (!needDownloadEffect.downloaded) { // 贴纸对应的资源还没有下载到本地
        if (!ACC_isEmptyString(cellEffect.effectIdentifier) && ![self.dataManager.downloadingEffects containsObject:cellEffect.effectIdentifier]) {
            [self.dataManager.downloadingEffects addObject:cellEffect.effectIdentifier];
        }
        cell.effect.downloadStatus = AWEEffectDownloadStatusDownloading;
        cell.downloadStatus = AWEModernStickerDownloadStatusDownloading;

        AWEEffectPlatformTrackModel *trackModel = [self commonStickerDownloadTrackModel];

        // 下载完成回调
        void (^downloadCompletionBlock)(BOOL,BOOL,id<ACCMusicModelProtocol>,NSURL*,NSError*) = ^(BOOL success,BOOL musicIsForceBind,id<ACCMusicModelProtocol> musicModel,NSURL *musicAssetUrl,NSError *musicError) {
            @strongify(self);
            @strongify(cell);
            @strongify(collectionView);
            @strongify(needDownloadEffect);
            NSString *effectID = cellEffect.effectIdentifier;
            if (!self || !collectionView || !cell || ACC_isEmptyString(effectID)) {
                return;
            }
            AWEModernStickerCollectionViewCell *selectCell = ACCBLOCK_INVOKE(getActualUpdateCellBlock, cell);
            NSIndexPath *selectIndexPath = self.effectIndexPathBindingMap[effectID];
                [self p_handleSelectedEffectDownLoadSuccess:success
                 WithCollectionView:collectionView
                               cell:selectCell
                          indexPath:selectIndexPath
                 needDownloadEffect:needDownloadEffect
                         cellEffect:cellEffect
                   musicIsForceBind:musicIsForceBind
                forceBindMusicModel:musicModel
                forceBindMusicAsset:musicAssetUrl
                         musicError:musicError];
        };

        // 下载道具
        void (^downloadEffectBlock) (void) = ^{
            @strongify(self);
            @strongify(needDownloadEffect);
            dispatch_group_t group = dispatch_group_create();
            dispatch_group_enter(group);
            __block BOOL downloadSuccess = NO;
            __block NSError *downloadError = nil;
            CFTimeInterval startTime = CACurrentMediaTime();
            [[AWEEffectPlatformManager sharedManager] downloadEffect:needDownloadEffect trackModel:[self commonStickerDownloadTrackModel] progress:^(CGFloat progress) {
                @strongify(cell);
                AWEModernStickerCollectionViewCell *updateCell = ACCBLOCK_INVOKE(getActualUpdateCellBlock, cell);
                if (updateCell) {
                    [updateCell updateDownloadProgress:progress];
                }
            } completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
                downloadSuccess = !error && filePath;
                if (error) {
                    downloadError = error;
                }
                [self trackDownloadPerformanceWithEffect:needDownloadEffect startTime:startTime success:downloadSuccess error:error];
                dispatch_group_leave(group);
            }];
            if ([needDownloadEffect isTypeAR] && group) {
                dispatch_group_enter(group);
                [EffectPlatform downloadRequirements:@[@"faceDetect"] completion:^(BOOL success, NSError * _Nonnull error) {
                    downloadSuccess = downloadSuccess && success && !error;
                    if (error) {
                        downloadError = error;
                    }
                    dispatch_group_leave(group);
                }];
            }
            dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                ACCBLOCK_INVOKE(downloadCompletionBlock, downloadSuccess, NO, nil,nil,nil);
                if (!downloadSuccess) {
                    [self didFailedDownloadEffect:needDownloadEffect withError:downloadError];
                }
            });
         };

        // 是否是音乐强绑定
        if (needDownloadEffect.musicIDs && !ACC_isEmptyString(needDownloadEffect.musicIDs.firstObject) && !isDuetOrReact) {
            BOOL musicIsForceBind = [AWEStickerMusicManager musicIsForceBindStickerWithExtra:needDownloadEffect.extra];
            if (musicIsForceBind) {
                // 1.音乐是否存在缓存都重新拉取musicModel和下载特效
                dispatch_group_t group = dispatch_group_create();

                __block NSURL *musicAssetUrl = nil;
                __block id<ACCMusicModelProtocol> musicModel = nil;
                __block BOOL effectDownLoadSuccessed = NO;
                __block CGFloat musicDownloadProgress = 0;
                __block CGFloat effectDownloadProgress = 0;
                __block NSError *musicError;
                __block NSError *downloadError = nil;

                dispatch_group_enter(group);

                [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) requestMusicItemWithID:needDownloadEffect.musicIDs.firstObject completion:^(id<ACCMusicModelProtocol> model, NSError *error) {
                    if (model && !error && !model.isOffLine) {
                        // 持久化musicModel
                        [AWEStickerMusicManager insertMusicModelToCache:model];
                        [ACCVideoMusic() fetchLocalURLForMusic:model
                                                     withProgress:^(float progress) {
                            @strongify(cell);
                            AWEModernStickerCollectionViewCell *updateCell = ACCBLOCK_INVOKE(getActualUpdateCellBlock, cell);
                            if (updateCell) {
                                musicDownloadProgress = progress;
                                [updateCell updateDownloadProgress:(progress + effectDownloadProgress)/2];
                            }
                        } completion:^(NSURL *localURL, NSError *error) {
                            musicError = error;
                            if (localURL && !error) {
                                musicModel = model;
                                musicAssetUrl = localURL;
                            }
                            if (error) {
                                downloadError = error;
                            }
                            dispatch_group_leave(group);
                        }];
                    } else {
                        AWEModernStickerCollectionViewCell *updateCell = ACCBLOCK_INVOKE(getActualUpdateCellBlock, cell);
                        if (updateCell) {
                            musicDownloadProgress = 1;
                            musicError = error;
                        }
                        if (error) {
                            downloadError = error;
                        }
                        dispatch_group_leave(group);
                    }

                    if (error) {
                        AWELogToolError(AWELogToolTagMusic, @"requestMusicItemWithID: %@", error);
                    }
                }];

                CFTimeInterval startTime = CACurrentMediaTime();
                dispatch_group_enter(group);
                [[AWEEffectPlatformManager sharedManager] downloadEffect:needDownloadEffect trackModel:trackModel progress:^(CGFloat progress) {
                    @strongify(cell);
                    AWEModernStickerCollectionViewCell *updateCell = ACCBLOCK_INVOKE(getActualUpdateCellBlock, cell);
                    if (updateCell) {
                        effectDownloadProgress = progress;
                        [updateCell updateDownloadProgress:(progress + musicDownloadProgress)/2];
                    }
                } completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
                    if (!error && filePath) { // 下载成功
                        effectDownLoadSuccessed = YES;
                    }
                    if (error) {
                        downloadError = error;
                    }

                    [self trackDownloadPerformanceWithEffect:needDownloadEffect startTime:startTime success:effectDownLoadSuccessed error:error];
                    dispatch_group_leave(group);
                }];
                [self downloadARAlgorithmModel:needDownloadEffect dispatchGroup:group];

                dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                    ACCBLOCK_INVOKE(downloadCompletionBlock, effectDownLoadSuccessed, musicIsForceBind, musicModel, musicAssetUrl, musicError);

                    if (!effectDownLoadSuccessed) {
                        [self didFailedDownloadEffect:needDownloadEffect withError:downloadError];
                    }
                });
            } else {
                // 非道具音乐强绑定
                ACCBLOCK_INVOKE(downloadEffectBlock);
            }
        } else {
            ACCBLOCK_INVOKE(downloadEffectBlock);
        }

    } else { // 贴纸已经下载到本地了
        // 音乐ID为空，音乐强绑定，贴纸反选，下载过该道具的音乐是否失败，合拍抢镜不适用
        if (![self.selectedEffectModel.effectIdentifier isEqualToString:cell.effect.effectIdentifier] && [AWEStickerMusicManager musicIsForceBindStickerWithExtra:needDownloadEffect.extra] && needDownloadEffect.musicIDs && !ACC_isEmptyString(needDownloadEffect.musicIDs.firstObject) &&  ![AWEStickerMusicManager getForceBindMusicDownloadFailed:needDownloadEffect.effectIdentifier] && !isDuetOrReact) {
            // cell状态设置为未下载状态，进度0
            cell.downloadStatus = AWEModernStickerDownloadStatusDownloading;
            BOOL cellEffectIsNeedDownloadEffect = [cell.effect.effectIdentifier isEqualToString:cellEffect.effectIdentifier];
            if (cellEffectIsNeedDownloadEffect) {
                [cell updateDownloadProgress:0];
            }

            __block NSURL *musicAssetUrl = nil;
            __block id<ACCMusicModelProtocol> musicModel = nil;
            __block NSError *musicError;

            dispatch_group_t group = dispatch_group_create();
            dispatch_group_enter(group);

            // 检查音乐是否下架，并且读取音乐缓存，依赖音乐模型的最终状态
            [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) requestMusicItemWithID:needDownloadEffect.musicIDs.firstObject completion:^(id<ACCMusicModelProtocol> model, NSError *error) {
                musicModel = model;
                if (model && !error && ![model isOffLine]) { // 音乐未下架
                    BOOL hasMusicCache = NO;
                    id<ACCMusicModelProtocol> cacheMusicModel = [AWEStickerMusicManager fetchtMusicModelFromCache:needDownloadEffect.musicIDs.firstObject];
                    NSURL *cacheMusicAssertUrl = [AWEStickerMusicManager localURLForMusic:cacheMusicModel];
                    if (cacheMusicAssertUrl) {
                        hasMusicCache = YES;
                    }
                    // 有本地音乐缓存
                    if (hasMusicCache) {
                        musicModel = cacheMusicModel;
                        musicAssetUrl = cacheMusicAssertUrl;
                        dispatch_group_leave(group);
                    } else { // 没有本地音乐缓存
                        [AWEStickerMusicManager insertMusicModelToCache:model];
                        [ACCVideoMusic() fetchLocalURLForMusic:model
                                                     withProgress:^(float progress) {
                            @strongify(cell);
                            AWEModernStickerCollectionViewCell *updateCell = ACCBLOCK_INVOKE(getActualUpdateCellBlock, cell);
                            if (updateCell) {
                                [updateCell updateDownloadProgress:progress];
                            }
                        } completion:^(NSURL *localURL, NSError *error) {
                            musicError = error;
                            if (localURL && !error) {
                                musicModel = model;
                                musicAssetUrl = localURL;
                            }
                            AWEModernStickerCollectionViewCell *updateCell = ACCBLOCK_INVOKE(getActualUpdateCellBlock, cell);
                            if (updateCell) {
                                [updateCell updateDownloadProgress:1];
                            }
                            dispatch_group_leave(group);
                        }];
                    }
                } else { // 音乐下架，或者拉取音乐模型失败
                    [AWEStickerMusicManager insertMusicModelToCache:model];
                    AWEModernStickerCollectionViewCell *updateCell = ACCBLOCK_INVOKE(getActualUpdateCellBlock, cell);
                    if (updateCell) {
                        [updateCell updateDownloadProgress:1];
                        musicError = error;
                    }
                    dispatch_group_leave(group);
                }

                if (error) {
                    AWELogToolError(AWELogToolTagMusic, @"requestMusicItemWithID: %@", error);
                }
            }];
            [self downloadARAlgorithmModel:needDownloadEffect dispatchGroup:group];
            dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                @strongify(self);
                @strongify(cell);
                @strongify(collectionView);
                NSString *effectID = cellEffect.effectIdentifier;
                if (!self || !collectionView || !cell || ACC_isEmptyString(effectID)) {
                    return;
                }
                AWEModernStickerCollectionViewCell *updateCell = ACCBLOCK_INVOKE(getActualUpdateCellBlock, cell);
                if (updateCell) {
                    [updateCell updateDownloadProgress:1];
                    updateCell.downloadStatus = AWEModernStickerDownloadStatusDownloaded;
                }
                NSIndexPath *selectIndexPath = self.effectIndexPathBindingMap[effectID];
                [self p_selectedDownloadedEffectWithCollectionView:collectionView
                                                              cell:updateCell
                                                         indexPath:selectIndexPath
                                                needDownloadEffect:needDownloadEffect
                                                  musicIsForceBind:YES
                                               forceBindMusicModel:musicModel
                                               forceBindMusicAsset:musicAssetUrl
                                                        musicError:musicError];
            });
        } else {
            // 道具已存在，非音乐强绑定道具,或者强绑定音乐的道具本拍摄周期内音乐失败过
            if ([needDownloadEffect isTypeAR]) {
                [EffectPlatform downloadRequirements:@[@"faceDetect"] completion:^(BOOL success, NSError * _Nonnull error) {
                    @strongify(self);
                    @strongify(cell);
                    @strongify(collectionView);
                    NSString *effectID = cellEffect.effectIdentifier;
                    if (!self || !collectionView || !cell || ACC_isEmptyString(effectID)) {
                        return;
                    }
                    AWEModernStickerCollectionViewCell *selectCell = ACCBLOCK_INVOKE(getActualUpdateCellBlock, cell);
                    NSIndexPath *selectIndexPath = self.effectIndexPathBindingMap[effectID];
                    if (success && !error) {
                        [self p_selectedDownloadedEffectWithCollectionView:collectionView
                                                                      cell:selectCell
                                                                 indexPath:selectIndexPath
                                                        needDownloadEffect:needDownloadEffect
                                                          musicIsForceBind:NO
                                                       forceBindMusicModel:nil
                                                       forceBindMusicAsset:nil
                                                                musicError:nil];
                    }
                }];
            } else {
                [self p_selectedDownloadedEffectWithCollectionView:collectionView
                                                              cell:cell
                                                         indexPath:indexPath
                                                needDownloadEffect:needDownloadEffect
                                                  musicIsForceBind:NO
                                               forceBindMusicModel:nil
                                               forceBindMusicAsset:nil
                                                        musicError:nil];
            }
        }
    }

}

- (void)downloadARAlgorithmModel:(IESEffectModel *)needDownloadEffect dispatchGroup:(dispatch_group_t)group {
    if ([needDownloadEffect isTypeAR] && group) {
        dispatch_group_enter(group);
        [EffectPlatform downloadRequirements:@[@"faceDetect"] completion:^(BOOL success, NSError * _Nonnull error) {
            dispatch_group_leave(group);
        }];
    }
}

- (void)p_handleSelectedEffectDownLoadSuccess:(BOOL)success
                           WithCollectionView:(UICollectionView *)collectionView
                                         cell:(AWEModernStickerCollectionViewCell *)cell
                                    indexPath:(NSIndexPath *)indexPath
                           needDownloadEffect:(IESEffectModel *)needDownloadEffect
                                   cellEffect:(IESEffectModel *)cellEffect
                             musicIsForceBind:(BOOL)musicIsForceBind
                          forceBindMusicModel:(id<ACCMusicModelProtocol>)forceBindMusicModel
                          forceBindMusicAsset:(NSURL *)forceBindMusicAsset
                                   musicError:(NSError *)musicError
{
    if (success) { // 下载成功
        needDownloadEffect.downloadStatus = AWEEffectDownloadStatusDownloaded; // 设置model的downloadStatus，我们需要根据这个值来显示cell的状态用的
        cellEffect.downloadStatus = AWEEffectDownloadStatusDownloaded;
        // 判断下载成功的model跟cell当前的model是否是同一个
        BOOL cellEffectIsNeedDownloadEffect = [cell.effect.effectIdentifier isEqualToString:cellEffect.effectIdentifier];
        // 判断下载成功的model跟最后一次点击的model是否是同一个
        BOOL needDownloadEffectIsLastClikedEffect = [cellEffect.effectIdentifier isEqualToString:self.lastClickedEffectModel.effectIdentifier];
        if (cellEffectIsNeedDownloadEffect) { // 下载成功的model 跟 cell当前的model 是同一个
            cell.downloadStatus = AWEModernStickerDownloadStatusDownloaded;
        }

        if (needDownloadEffectIsLastClikedEffect) { // 下载成功的model 跟 最后一次点击的model 是同一个
            if (self.selectedEffectModel) { // 如果当前有应用着的贴纸，就让应用着的贴纸取消选中，然后选中下载成功的贴纸
                [self p_clearSeletedCells];
                if (cellEffectIsNeedDownloadEffect) { // 标记选中
                    [cell makeSelectedWithDelay];
                } else { /* do nothing */ }
            } else { // 如果没有应用着的贴纸，就直接选中下载成功的贴纸
                if (cellEffectIsNeedDownloadEffect) { // 标记选中
                    [cell makeSelected];
                } else { /* do nothing */  }
            }

            [self p_setSelectedEffectModelWithEffect:cellEffect];

            // 音乐道具强绑定
            if (musicIsForceBind && (musicError || [forceBindMusicModel isOffLine])) {
                [AWEStickerMusicManager setForceBindMusicDownloadFailedWithEffectIdentifier:needDownloadEffect.effectIdentifier];
            }
            ACCBLOCK_INVOKE(self.pickStickerMusicBlock,
                            forceBindMusicModel,
                            forceBindMusicAsset,
                            musicError,
                            musicIsForceBind);

            IESEffectModel *effectModel;
            if (cell.effect.childrenEffects.count > 1) {
                effectModel = [self.aggregatedEffectView nextEffectOfSelectedEffect];
            } else {
                NSInteger section = collectionView.tag % 1000;
                effectModel = [self p_effectModelForIndexPath:[NSIndexPath indexPathForItem:indexPath.item + 1 inSection:section]];
            }
            [self p_silentlyDownloadEffect:effectModel];

            [self p_trackCellClickEventWithCell:cell atIndex:indexPath.item];
        }
    } else {
        needDownloadEffect.downloadStatus = AWEEffectDownloadStatusUndownloaded; // 设置model的downloadStatus，我们需要根据这个值来显示cell的状态用的
        cellEffect.downloadStatus = AWEEffectDownloadStatusUndownloaded;
        // 判断下载失败的model跟cell当前的model是否是同一个
        BOOL cellEffectIsNeedDownloadEffect = [cell.effect.effectIdentifier isEqualToString:cellEffect.effectIdentifier];
        if (cellEffectIsNeedDownloadEffect) { // 下载成功的model 跟 cell当前的model 是同一个
            cell.downloadStatus = AWEModernStickerDownloadStatusUndownloaded;
        }
    }

    [self.dataManager updateBindEffectDownloadStatus:AWEEffectDownloadStatusDownloaded effectIdentifier:cellEffect.effectIdentifier];

    // 更新贴纸逻辑
    if ([self.dataManager.downloadingEffects containsObject:cellEffect.effectIdentifier]) {
        [self.dataManager.downloadingEffects removeObject:cellEffect.effectIdentifier];
    }
}

// 选中已下载的道具贴纸
- (void)p_selectedDownloadedEffectWithCollectionView:(UICollectionView *)collectionView
                                                cell:(AWEModernStickerCollectionViewCell *)cell
                                           indexPath:(NSIndexPath *)indexPath
                                  needDownloadEffect:(IESEffectModel *)needDownloadEffect
                                    musicIsForceBind:(BOOL)musicIsForceBind
                                 forceBindMusicModel:(id<ACCMusicModelProtocol>)forceBindMusicModel
                                 forceBindMusicAsset:(NSURL *)forceBindMusicAsset
                                          musicError:(NSError *)musicError
{
    cell.downloadStatus = AWEModernStickerDownloadStatusDownloaded;
    cell.effect.downloadStatus = AWEEffectDownloadStatusDownloaded;

    [self.actionDelegate stickerHintViewRemove];

    NSArray<IESEffectModel *> *currentChildrenEffects = cell.effect.childrenEffects;

    if (self.selectedEffectModel) {
        BOOL isSelectedEffectModel = [self.selectedEffectModel.effectIdentifier isEqualToString:cell.effect.effectIdentifier];
        if (isSelectedEffectModel) {
            // 点击的是当前选中的 cellBtn
            [cell makeUnselected];
            self.originStickerUserView.hidden = YES;
            self.hotEffectHintView.hidden = YES;

            // 反选道具置空选中道具所在位置indexPath，统计使用
            // Reset to nil when deselect the sticker.
            self.selectedEffectIndexPath = nil;
        } else {
            if ([collectionView isKindOfClass:[AWEModernStickerContentInnerCollectionView class]]) {
                [(AWEModernStickerContentInnerCollectionView *)collectionView clearSelectedCellsForSelectedModel:self.selectedEffectModel];
            }
            [self p_clearSeletedCells];
            [cell makeSelectedWithDelay]; // 标记选中
            [self p_trackCellClickEventWithCell:cell atIndex:indexPath.item];
        }
    } else { // 当前没有选中的cellBtn
        [cell makeSelected]; // 标记选中
        [self p_trackCellClickEventWithCell:cell atIndex:indexPath.item];
    }

    BOOL isClickedCurrentApplyedEffect = [self isClickedCurrentApplyedEffect:cell.effect];
    [self p_setSelectedEffectModelWithEffect:isClickedCurrentApplyedEffect ? nil : cell.effect];
                                          isClickedCurrentApplyedEffect ? ACCBLOCK_INVOKE(self.cancelStickerMusicBlock, cell.effect) : ACCBLOCK_INVOKE(self.pickStickerMusicBlock, forceBindMusicModel, forceBindMusicAsset, musicError, musicIsForceBind);
    if (![AWEStickerMusicManager getForceBindMusicDownloadFailed:needDownloadEffect.effectIdentifier] && ![self isClickedCurrentApplyedEffect:cell.effect]) {
        if (musicError || [forceBindMusicModel isOffLine]) {
            [AWEStickerMusicManager setForceBindMusicDownloadFailedWithEffectIdentifier:needDownloadEffect.effectIdentifier];
        }
    }

    IESEffectModel *effectModel;
    if (currentChildrenEffects.count == 0) {
        NSInteger section = collectionView.tag % 1000;
        effectModel = [self p_effectModelForIndexPath:[NSIndexPath indexPathForItem:indexPath.item + 1 inSection:section]];
    } else {
        effectModel = [self.aggregatedEffectView nextEffectOfSelectedEffect];
    }
    [self p_silentlyDownloadEffect:effectModel];
}

- (void)p_trackCellClickEventWithCell:(AWEModernStickerCollectionViewCell *)cell atIndex:(NSInteger)index {
    self.selectedEffectIndexPath = [NSIndexPath indexPathForRow:index inSection:[self selectedTabIndex]];
    if (!self.needTrackEvent) {
        return;
    }
    NSString *positionString = self.dataManager.panelType == AWEStickerPanelTypeLive ? @"live_set" : @"shoot_page";
    [ACCTracker() trackEvent:@"prop"
                                      label:@"click"
                                      value:cell.effect.effectIdentifier ? : @""
                                      extra:nil
                                 attributes:@{@"position" : positionString,
                                              @"is_photo" : self.isPhotoMode ? @1 : @0,
                                              }];
    AWEVideoPublishViewModel *publishModel = [self.actionDelegate providedPublishModel];
    if (publishModel.repoContext.recordSourceFrom != AWERecordSourceFromUnknown) {
        return;
    }
    // V3 打点
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.trackingInfoDictionary];
    [params setValue:@"click_main_panel" forKey:@"enter_method"];
    [params setValue:cell.effect.effectIdentifier ?: @"" forKey:@"prop_id"];
    [params setValue:cell.effect.gradeKey ?: @"" forKey:@"prop_index"];
    [params setValue:[self musicId] forKey:@"music_id"];
    params[@"enter_from"] = @"video_shoot_page";
    params[@"tab_name"] = self.switchTabView.selectedCategoryName;
    params[@"order"] = @(index).stringValue;
    params[@"impr_position"] = @(index + 1).stringValue;
    params[@"prop_tab_order"] = @([self selectedTabIndex]).stringValue;
    params[@"prop_rec_id"] = ACC_isEmptyString(cell.effect.recId) ? @"0": cell.effect.recId;
    params[@"prop_selected_from"] = cell.effect.propSelectedFrom;
    NSString *localPropId = [self localPropId];
    if (!ACC_isEmptyString(localPropId)) {
        params[@"from_prop_id"] = localPropId;
        BOOL isDefaultProp = [cell.effect.effectIdentifier isEqualToString:localPropId];
        params[@"is_default_prop"] = isDefaultProp ? @"1" : @"0";
    }

    AVCaptureDevicePosition cameraPostion = self.actionDelegate.cameraService.cameraControl.currentCameraPosition;
    params[@"camera_direction"] = ACCDevicePositionStringify(cameraPostion);


    NSDictionary *referExtra = publishModel.repoTrack.referExtra;
    params[@"content_type"] = referExtra[@"content_type"];
    params[@"pop_music_id"] = referExtra[@"pop_music_id"];
    [ACCTracker() trackEvent:@"prop_click" params:params needStagingFlag:NO];
}

- (void)setTrackingInfoDictionary:(NSDictionary *)trackingInfoDictionary
{
    _trackingInfoDictionary = [trackingInfoDictionary copy];
}

- (BOOL)p_shouldNotSilentlyDownloadEffect:(IESEffectModel *)effectModel
{
    // 如果是已经下载过了，或者是要跳转H5的贴纸，就不静默下载
    if (effectModel.downloadStatus == AWEEffectDownloadStatusDownloading || effectModel.effectType == IESEffectModelEffectTypeSchema) {
        return YES;
    }
    return NO;
}

- (void)p_silentlyDownloadForcebindMusicWithEffect:(IESEffectModel *)effectModel
{
    if (!effectModel.musicIDs || ACC_isEmptyString(effectModel.musicIDs.firstObject)) {
        return;
    }
    if ([AWEStickerMusicManager musicIsForceBindStickerWithExtra:effectModel.extra]) {
        [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) requestMusicItemWithID:effectModel.musicIDs.firstObject completion:^(id<ACCMusicModelProtocol> model, NSError *error) {
            if (model && !error && ![model isOffLine]) {
                id<ACCMusicModelProtocol> cacheMusicModel = [AWEStickerMusicManager fetchtMusicModelFromCache:effectModel.musicIDs.firstObject];
                NSURL *cacheMusicAssetUrl = [AWEStickerMusicManager localURLForMusic:cacheMusicModel];
                if (!cacheMusicAssetUrl) {
                    [AWEStickerMusicManager insertMusicModelToCache:model];
                    [ACCVideoMusic() fetchLocalURLForMusic:model withProgress:nil completion:nil];
                }
            }
            if (error) {
                AWELogToolError(AWELogToolTagMusic, @"requestMusicItemWithID: %@", error);
            }
        }];
    }
}

- (void)p_silentlyDownloadEffect:(IESEffectModel *)effectModel
{
    IESEffectModel *potentialChildEffect = [self potentialChildEffectOfParentEffect:effectModel];
    IESEffectModel *needDownloadEffect = potentialChildEffect ?: effectModel;
    if ([self p_shouldNotSilentlyDownloadEffect:needDownloadEffect]) {
        return;
    }
    if (BTDNetworkWifiConnected() && needDownloadEffect) {
        if (!needDownloadEffect.downloaded) {
            [[AWEEffectPlatformManager sharedManager] downloadEffect:needDownloadEffect
                                          trackModel:[self commonStickerDownloadTrackModel] downloadQueuePriority:NSOperationQueuePriorityLow downloadQualityOfService:NSQualityOfServiceBackground progress:nil completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
            }];
        }
        [self p_silentlyDownloadForcebindMusicWithEffect:effectModel];
    }
}

#pragma mark - AWEMattingViewProtocol

// tc21 track
- (void)mattingView:(AWEMattingView *)mattingView didSelectSubItem:(AWEAssetModel * _Nullable)asset
{
    if (asset) {
        [self trackPropCustomizedClickWithAWEAssetModel:asset];
    }
}

- (void)trackPropCustomizedClickWithAWEAssetModel:(AWEAssetModel *)asset
{
    if (asset) {
        [ACCTracker() trackEvent:@"prop_customized_click"
                          params:@{
                              @"prop_id" : self.selectedEffectModel.effectIdentifier ?: @"",
                              @"enter_from" : @"video_shoot_page",
                              @"tab_name" : self.switchTabView.selectedCategoryName ?: @"",
                              @"shoot_way": self.dataManager.referString ?: @"",
                              @"creation_id": self.createId ?: @"",
                              @"click_content" : asset.mediaType == AWEAssetModelMediaTypePhoto ? @"photo" : @"video",
                              @"picture_source" : @"upload"
                          }
                 needStagingFlag:NO];
    }
}

- (void)trackPropCustomizedCompletetWithContentCount:(NSUInteger)contentCount isImage:(BOOL)isImage
{
    [ACCTracker() trackEvent:@"prop_customized_complete"
                      params:@{
                          @"prop_id" : self.selectedEffectModel.effectIdentifier ?: @"",
                          @"enter_from" : @"video_shoot_page",
                          @"shoot_way": self.dataManager.referString ?: @"",
                          @"tab_name" :  self.switchTabView.selectedCategoryName ? : @"",
                          @"creation_id": self.createId ?: @"",
                          @"click_content" : isImage ? @"photo" : @"video",
                          @"video_source" : @"upload",
                          @"content_cnt" : @(contentCount),
                      }
             needStagingFlag:NO];
}

- (void)didChooseImage:(UIImage *)image asset:(PHAsset *)asset
{
    if ([self.actionDelegate respondsToSelector:@selector(modernStickerViewControllerDidChangeSelection:)]) {
        ACCPropSelection *selection = [[ACCPropSelection alloc] initWithEffect:self.selectedEffectModel source:ACCPropSelectionSourceClassic];
        selection.asset = asset;
        [self.actionDelegate modernStickerViewControllerDidChangeSelection:selection];
    }
    // pixaloop 选择推荐照片生成预览视频
    if ([self.mattingView.photoCollector.identifier hasPrefix:@"pixaloop"]) {
        if (image) {
            [self p_dismissWithTrackKey:@"ChooseImage"];
            self.pixaLoopImageSourceMark = 1;
            [ACCTracker() trackEvent:@"prop_customized_click"
                                             params:@{
                                                      @"prop_id" : self.selectedEffectModel.effectIdentifier ?: @"",
                                                      @"enter_from" : @"video_shoot_page",
                                                      @"tab_name" : self.switchTabView.selectedCategoryName ?: @"",
                                                      @"shoot_way": self.dataManager.referString ?: @"",
                                                      @"creation_id": self.createId ?: @"",
                                                      @"click_content" : @"photo",
                                                      @"picture_source" : @"upload"
                                                      }
                                    needStagingFlag:NO];
            [self trackPropCustomizedCompletetWithContentCount:1 isImage:YES];
        }

        if ([self.mattingView.photoCollector isKindOfClass:[AWEAlbumPixaloopPhotoCollector class]]) {
            self.dataManager.faceImage = image; // 原始图片，用户抽帧送审
            AWEAlbumPixaloopPhotoCollector *pixaloopCollector = (AWEAlbumPixaloopPhotoCollector *)(self.mattingView.photoCollector);
            [self.actionDelegate.cameraService.effect renderPicImage:image withKey:pixaloopCollector.pixaloopImgK];
        }
        return;
    }

    if (image) {
        [ACCTracker() trackEvent:@"click_prop_pic"
                                         params:@{ @"prop_id" : self.selectedEffectModel.effectIdentifier?:@"" } needStagingFlag:NO];
    }
    [self.delegate didChooseImage:image];
}

- (void)didChooseAssetModel:(AWEAssetModel *)assetModel isAlbumChange:(BOOL)isAlbumChange {
    if (assetModel) {
        [self p_dismissWithTrackKey:@"ChooseAssetModel"];
        if (!assetModel.avAsset) {
           [ACCToast() show:ACCLocalizedString(@"error_param",@"出错了")];
           return;
        }
        @weakify(self);
        UIViewController* vc = [self clipVideoPageVC:assetModel completion:^(ACCEditVideoData* videoData, id<ACCMusicModelProtocol> music, UIImage *coverImage) {
                  @strongify(self);
            if ([videoData.videoAssets.firstObject isKindOfClass:[AVURLAsset class]]) {
                AVURLAsset* urlAsset = (AVURLAsset*)videoData.videoAssets.firstObject;
                [[ACCResponder topViewController] dismissViewControllerAnimated:YES completion:nil];
                self.videoBGStickerManager.currentSelectedMattingAssetModel = assetModel;
                [self.videoBGStickerManager applyVideoBGToCamera:urlAsset.URL];
                [self trackPropCustomizedCompletetWithContentCount:1 isImage:NO];
            };
        }];

        [self.videoBGStickerManager containerViewControllerWillDisAppear];
        [[ACCResponder topViewController] presentViewController:vc animated:YES completion:nil];
        [ACCTracker() trackEvent:@"prop_customized_click"
                                                    params:@{
                                                             @"prop_id" : self.selectedEffectModel.effectIdentifier ?: @"",
                                                             @"enter_from" : @"video_shoot_page",
                                                             @"tab_name" : self.switchTabView.selectedCategoryName ?: @"",
                                                             @"shoot_way": self.dataManager.referString ?: @"",
                                                             @"creation_id": self.createId ?: @"",
                                                             @"click_content" : @"video",
                                                             @"video_source" : @"upload"
                                                             }
                  needStagingFlag:NO];
    } else {
        if (!isAlbumChange) {
            if (!!self.selectedEffectModel && [self.selectedEffectModel isVideoBGPixaloopSticker]) {
               [self.videoBGStickerManager applyVideoBGToCamera:nil];
            } else {
               [self.videoBGStickerManager resetVideoBGCamera];
            }
        }
    }

}

- (void)didChooseAssetModelArray:(NSArray<AWEAssetModel *> *)assetModelArray
{
    // tc track
    if (assetModelArray.count > 0) {
        [self trackPropCustomizedCompletetWithContentCount:assetModelArray.count
                                                   isImage:assetModelArray.firstObject.mediaType == AWEAssetModelMediaTypePhoto];
    }
    acc_dispatch_main_async_safe(^{
        [self p_multiAssetsPixaloopDidChooseAssetModelArray:assetModelArray];
    });
}

- (void)p_multiAssetsPixaloopDidChooseAssetModelArray:(NSArray<AWEAssetModel *> *)assetModelArray
{
    NSArray<AWEAssetModel *> *previousAssetArray = [self.multiAssetsPixaloopSelectedAssetArray copy];
    NSArray<NSString *> *previousKeyArray = [self.multiAssetsPixaloopSelectedKeyArray copy];
    NSAssert(previousKeyArray.count == previousAssetArray.count, @"Previously selected asset and keys are not equal in count, have u carelessly forgot to update both?");
    NSArray<AWEAssetModel *> *newAssetArray = [assetModelArray copy];
    // 1. Clear previously selected image cache.
    if (previousAssetArray.count > 0) {
        NSMutableArray *cancelImageArray = [NSMutableArray arrayWithCapacity:previousAssetArray.count];
        for (NSInteger i = 0; i < previousAssetArray.count; i++) {
            [cancelImageArray addObject:[NSNull null]];
        }
        [self.actionDelegate.cameraService.effect renderPicImages:cancelImageArray withKeys:previousKeyArray];
        self.multiAssetsPixaloopSelectedAssetArray = @[];
        self.multiAssetsPixaloopSelectedKeyArray = @[];
    }
    // 2. Fetch the image data of the selected assets.
    // Nil indicates `mattingView` is reset to initial state, triggerd by either switching to another prop or cancel current prop. In this case, we do not dismiss the entier prop panel.
    if (newAssetArray == nil) {
        return;
    }
    // `count == 0` indicates the user does not select any assets when clicking the finish button on `mattingView` or the next button in `albumVC`, but it's indeed a valid action under the description of PRD(https://bytedance.feishu.cn/docs/doccnRrchpD49iQlUcUdo34msYb). In this case we need to dimiss the prop panel to notify the user that he/she's selection is successfully applied.
    if (newAssetArray.count == 0) {
        [self p_dismissWithTrackKey:@"ChooseImages"];
        return;
    }
    NSDictionary *pixaloopSDKExtra = [self.selectedEffectModel pixaloopSDKExtra];
    NSString *imgK = [pixaloopSDKExtra acc_pixaloopImgK:@"pl"];
    if (ACC_isEmptyString(imgK)) {
        return;
    }
    NSMutableArray *newKeyArray = [NSMutableArray arrayWithCapacity:newAssetArray.count];
    NSMutableArray *newImageArray = [NSMutableArray arrayWithCapacity:newAssetArray.count];
    NSNumber *unfetchedNumber = @0;
    NSNumber *fetchFailedNumber = @1;
    NSNumber *iCloudNumber = @2;
    for (NSInteger i = 0; i < newAssetArray.count; i++) {
        [newKeyArray addObject:[imgK stringByAppendingFormat:@"%@", @(i+1)]];
        [newImageArray addObject:unfetchedNumber]; // Use `0` to indicate the image of this asset has not been fetched.
    }
    UIView<ACCLoadingViewProtocol> *loadingView = [ACCLoading() showLoadingAndDisableUserInteractionOnView:[UIApplication sharedApplication].keyWindow];
    void (^nextStepBlock)(void) = ^ {
        [self p_dismissWithTrackKey:@"ChooseImages"];
        self.dataManager.multiAssetImages = newImageArray;
        if (newImageArray.count > 0) {
            [self.actionDelegate.cameraService.effect renderPicImages:newImageArray withKeys:newKeyArray];
            self.multiAssetsPixaloopSelectedAssetArray = [newAssetArray copy];
            self.multiAssetsPixaloopSelectedKeyArray = [newKeyArray copy];
        }
    };
    const CGSize imageSize = [AWEVideoRecordOutputParameter maximumImportCompositionSize];
    for (NSInteger i = 0; i < newAssetArray.count; i++) {
        AWEAssetModel *assetModel = [newAssetArray acc_objectAtIndex:i];
        [CAKPhotoManager getUIImageWithPHAsset:assetModel.asset imageSize:imageSize networkAccessAllowed:NO progressHandler:^(CGFloat progress, NSError *error, BOOL *stop, NSDictionary *info) {
                if (error != nil) {
                    AWELogToolError(AWELogToolTagRecord, @"multi-assets pixaloop reqeust image failed: %@", error);
                }
            } completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                acc_dispatch_main_async_safe(^{
                    if (isDegraded) {
                        return;
                    }
                    if ([info acc_boolValueForKey:PHImageResultIsInCloudKey]) {
                        [newImageArray replaceObjectAtIndex:i withObject:iCloudNumber];
                    } else if (photo == nil) {
                        [newImageArray replaceObjectAtIndex:i withObject:fetchFailedNumber];
                    } else {
                        [newImageArray replaceObjectAtIndex:i withObject:photo];
                    }

                    for (id item in newImageArray) {
                        if (item == unfetchedNumber) {
                            return;
                        }
                    }
                    [loadingView dismiss];
                    for (id item in newImageArray) {
                        if (item == iCloudNumber || item == fetchFailedNumber) {
                            [ACCToast() show:ACCLocalizedCurrentString(@"com_mig_syncing_the_picture_from_icloud")];
                            return;
                        }
                    }
                    nextStepBlock();
                });
        }];
    }
}


- (void)itemShouldBeSelected:(AWEAssetModel *)assetModel completion:(dispatch_block_t)completion {
    if ([self.selectedEffectModel isVideoBGPixaloopSticker]) {
        [AWEVideoBGStickerManager verifyAssetValid:assetModel completion:completion];
    } else {
        completion();
    }
}

- (void)albumFaceImageDetectEmpty
{
    [self p_hiddenMattingView];
}

- (void)albumPhotosChanged
{
    if ([self.selectedEffectModel isPixaloopSticker] ||
        [self.selectedEffectModel isVideoBGPixaloopSticker]) {
        [self p_showMattingViewWithProp:self.selectedEffectModel];
    }
}

- (void)didPressPlusButton
{
    [self showImagePickerViewController];
    NSMutableDictionary* params = [@{
        @"prop_id" : self.selectedEffectModel.effectIdentifier ?: @"",
        @"enter_from" : @"video_shoot_page",
        @"tab_name" : self.switchTabView.selectedCategoryName ?: @"",
        @"shoot_way": self.dataManager.referString ?: @"",
        @"creation_id": self.createId ?: @"",
        @"click_content" : @"album"
    } mutableCopy];
    if ([self.selectedEffectModel isVideoBGPixaloopSticker]) {
        params[@"video_source"] = @"upload";
    } else {
        params[@"picture_source"] = @"upload";
    }
    [ACCTracker() trackEvent:@"prop_customized_click"
                                     params:params
                            needStagingFlag:NO];
}

- (CAKModalTransitionDelegate *)transitionDelegate
{
    if (!_transitionDelegate) {
        _transitionDelegate = [[CAKModalTransitionDelegate alloc] init];
    }
    return _transitionDelegate;
}

- (void)showImagePickerViewController
{
    [ACCDeviceAuth requestPhotoLibraryPermission:^(BOOL success) {
        if (success) {
            [self p_presentImagePickerViewController];
        } else {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:ACCLocalizedCurrentString(@"tip") message:ACCLocalizedCurrentString( @"com_mig_failed_to_access_photos_please_go_to_the_settings_to_enable_access") preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedString(@"go_to_settings",@"go_to_settings") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                acc_dispatch_main_async_safe(^{
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                });
            }]];
            [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedCurrentString(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
            [ACCAlert() showAlertController:alertController animated:YES];
        }
    }];
}

- (void)p_presentImagePickerViewController
{
   @weakify(self);
    void (^pixaloopBlock)(AWEAssetModel* asset) = ^(AWEAssetModel* asset){
        @strongify(self);
        if (asset) {
            [self p_dismissWithTrackKey:@"ChooseImage"];
            if (self.selectedEffectModel && [self.mattingView.photoCollector isKindOfClass:[AWEAlbumPixaloopPhotoCollector class]]) {
                NSString *plStr = @"pl";
                NSInteger albumFilterNumber = [self.selectedEffectModel.pixaloopSDKExtra acc_albumFilterNumber:plStr];
                if (albumFilterNumber == AWEFilterNumberPannelAndAlbumFilter || albumFilterNumber == AWEFilterNumberAlbumFilter) {
                    BOOL pixaloopSupport = [self p_pixaloopSupportAsset:asset forEffectModel:self.selectedEffectModel];
                    if (!pixaloopSupport) {
                        NSString *hintStr = self.selectedEffectModel.pixaloopExtra.acc_effectAlgorithmHint;
                        if (ACC_isEmptyString(hintStr)) {
                            hintStr = ACCLocalizedCurrentString(@"not_meet_algo_requirement_toast");
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [ACCToast() show:hintStr];
                        });
                        return;
                    }
                }
            }

            [ACCTracker() trackEvent:@"choose_upload_content"
                                            params:@{
                                                     @"content_type" : @"photo",
                                                     @"upload_type" : @"single_content",
                                                     @"upload_by" : @"photo2video",
                                                     @"material_type" : asset.mediaType == AWEAssetModelMediaTypePhoto ? @"photo" : @"video",
                                                     }
                                   needStagingFlag:NO];

            [self.selectAlbumAssetVC dismissViewControllerAnimated:YES completion:nil];
            AWEAlbumPixaloopPhotoCollector *pixaloopCollector = nil;
            if ([self.mattingView.photoCollector isKindOfClass:[AWEAlbumPixaloopPhotoCollector class]]) {
               pixaloopCollector = (AWEAlbumPixaloopPhotoCollector *)self.mattingView.photoCollector;
            }
            NSString *imgK = pixaloopCollector.pixaloopImgK;
            CGSize outputSize = [AWEVideoRecordOutputParameter maximumImportCompositionSize];
            [CAKPhotoManager getUIImageWithPHAsset:asset.asset imageSize:outputSize networkAccessAllowed:NO progressHandler:^(CGFloat progress, NSError *error, BOOL *stop, NSDictionary *info) {
                AWELogToolError(AWELogToolTagImport, @"error: %@",error);
            } completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
               if (isDegraded) return;
               if ([[info objectForKey:PHImageResultIsInCloudKey] boolValue]) {
                   dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                       [ACCToast() show: ACCLocalizedCurrentString(@"creation_icloud_download")];
                   });
                   [CAKPhotoManager getOriginalPhotoDataFromICloudWithAsset:asset.asset progressHandler:^(CGFloat progress, NSError *error, BOOL *stop, NSDictionary *info) {
                       AWELogToolError(AWELogToolTagImport, @"error: %@",error);
                   } completion:nil];
                   return;
               }
               if (photo && imgK.length > 0) {
                   self.dataManager.faceImage = photo; // 原始图片，用户抽帧送审
                   [self.actionDelegate.cameraService.effect renderPicImage:photo withKey:imgK];

                   // 从相册选择照片后，需要更新推荐照片的预览区的选中状态
                   // 如果所选照片在预览区，选中该照片并滑动到该照片处
                   // 如果所选照片不在预览区，取消选中当前选中的照片
                   self.propSelection.asset = asset.asset;
                   [self.mattingView updateSelectedPhotoWithAssetLocalIdentifier:asset.asset.localIdentifier];
               } else {
                   dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                       [ACCToast() showError: ACCLocalizedCurrentString(@"com_mig_couldnt_access_icloud_photos")];
                   });
               }
            }];
        }
    };

    ACCAlbumVCType type;
    if ([self.selectedEffectModel isPixaloopSticker]) {
        // 打开照片选择页
        self.pixaLoopImageSourceMark = 2;
        type = [self.selectedEffectModel isMultiAssetsPixaloopProp] ? ACCAlbumVCTypeForMultiAssetsPixaloop : ACCAlbumVCTypeForPixaloop;
    } else {
        type = ACCAlbumVCTypeForVideoBG;
    }

    CAKAlbumViewController * selectMusicViewController = nil;
    if (type == ACCAlbumVCTypeForVideoBG) {
        ACCAlbumInputData *inputData = [[ACCAlbumInputData alloc] init];
        inputData.vcType = type;
        inputData.shouldStartClipBlock = ^BOOL{
            return NO;
        };
        inputData.selectAssetsCompletion = ^(NSArray<AWEAssetModel *> * _Nullable assets) {
            @strongify(self);
            if (!assets.firstObject.avAsset) {
                [ACCToast() show:ACCLocalizedString(@"error_param",@"出错了")];
                return;
            }
            UIViewController* vc = [self clipVideoPageVC:assets.firstObject completion:^(ACCEditVideoData* videoData, id<ACCMusicModelProtocol> music, UIImage *coverImage) {
                @strongify(self);
                if ([videoData.videoAssets.firstObject isKindOfClass:[AVURLAsset class]]) {
                    AVURLAsset* urlAsset = (AVURLAsset*)(videoData.videoAssets.firstObject);
                    [self.selectAlbumAssetVC.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                    self.videoBGStickerManager.currentSelectedMattingAssetModel = assets.firstObject;
                    [self.videoBGStickerManager applyVideoBGToCamera:urlAsset.URL];
                    [ACCTracker() trackEvent:@"prop_customized_complete"
                                        params:@{
                                            @"prop_id" : self.selectedEffectModel.effectIdentifier ?: @"",
                                            @"enter_from" : @"video_shoot_page",
                                            @"shoot_way": self.dataManager.referString ?: @"",
                                            @"tab_name" :  self.switchTabView.selectedCategoryName ? : @"",
                                            @"creation_id": self.createId ?: @"",
                                            @"click_content" : @"album",
                                            @"video_source" : @"video"
                                        }
                            needStagingFlag:NO];
                }

            }];
            [self.selectAlbumAssetVC presentViewController:vc animated:YES completion:nil];
        };
        selectMusicViewController = [self.albumImpl albumViewControllerWithInputData:inputData];

    } else if (type == ACCAlbumVCTypeForMultiAssetsPixaloop) {
        ACCAlbumInputData *inputData = [[ACCAlbumInputData alloc] init];
        NSDictionary *pixaloopSDKExtra = [[self.selectedEffectModel pixaloopSDKExtra] acc_objectForKey:@"pl" ofClass:[NSDictionary class]];
        inputData.maxAssetsSelectionCount = [pixaloopSDKExtra acc_maxAssetsSelectionCount];
        inputData.minAssetsSelectionCount = [pixaloopSDKExtra acc_minAssetsSelectionCount];
        inputData.initialSelectedAssetModelArray = [self.mattingView.selectedAssetArray copy];
        inputData.enableSyncInitialSelectedAssets = YES;
        inputData.vcType = ACCAlbumVCTypeForMultiAssetsPixaloop;
        @weakify(self);
        inputData.selectAssetsCompletion = ^(NSArray<AWEAssetModel *> * _Nullable assets) {
            @strongify(self);
            // tc21 track
            if (assets.count > 0) {
                [self trackPropCustomizedCompletetWithContentCount:assets.count
                                                           isImage:assets.firstObject.mediaType == AWEAssetModelMediaTypePhoto];
            }
            if (assets == nil) {
                return;
            }
            acc_dispatch_main_async_safe(^{
                [self p_multiAssetsPixaloopDidChooseAssetModelArray:assets];
                [self.selectAlbumAssetVC.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            });
        };
        selectMusicViewController = [self.albumImpl albumViewControllerWithInputData:inputData];
    } else {
        ACCAlbumInputData *inputData = [[ACCAlbumInputData alloc] init];
        inputData.vcType = type;
        inputData.selectPhotoCompletion = ^(AWEAssetModel * _Nullable asset) {
            if (type == ACCAlbumVCTypeForPixaloop) {
                pixaloopBlock(asset);
            }
        };
        selectMusicViewController = [self.albumImpl albumViewControllerWithInputData:inputData];
    }
    self.selectAlbumAssetVC = selectMusicViewController;
    self.albumImpl.delegate = self;
    UINavigationController *navigationController = [ACCViewControllerService() createCornerBarNaviControllerWithRootVC:selectMusicViewController];
    navigationController.navigationBar.translucent = NO;
    navigationController.modalPresentationStyle = UIModalPresentationCustom;
    navigationController.transitioningDelegate = self.transitionDelegate;
    navigationController.modalPresentationCapturesStatusBarAppearance = YES;
    [[self transitionDelegate].swipeInteractionController wireToViewController:navigationController.topViewController];
    [self transitionDelegate].swipeInteractionController.delegate = selectMusicViewController;
    [self.videoBGStickerManager containerViewControllerWillDisAppear];
    [[ACCResponder topViewController] presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - ACCSelectAlbumAssetsDelegate

- (void)albumViewControllerDidSelectOneAsset:(AWEAssetModel * _Nullable)asset
{
    if (asset && ![self.multiAssetsPixaloopSelectedAssetArray containsObject:asset]) {
        ACCLog(@"albumViewControllerDidSelectOneAssets|mediaType=%zi", asset.mediaType);
        [self trackPropCustomizedClickWithAWEAssetModel:asset];
    }
}

- (void)albumViewControllerDidRequestPhotoAuthorization
{
    if ([self.selectedEffectModel isPixaloopSticker]) {
        NSDictionary *pixaloopSDKExtra = [self.selectedEffectModel pixaloopSDKExtra];
        NSString *plStr = @"pl";
        NSInteger albumFilterNumber = [pixaloopSDKExtra acc_albumFilterNumber:plStr];
        NSString *pixaloopImgK = [pixaloopSDKExtra acc_pixaloopImgK:plStr];
        NSString *identifier = [@"pixaloop" stringByAppendingString:self.selectedEffectModel.effectIdentifier];
        NSArray<NSString *> *pixaloopAlg = [pixaloopSDKExtra acc_pixaloopAlg:plStr];
        if (albumFilterNumber == AWEFilterNumberNoFilter || albumFilterNumber == AWEFilterNumberAlbumFilter) {
            pixaloopAlg = @[];
        }
        NSString *pixaloopRelation = [pixaloopSDKExtra acc_pixaloopRelation:plStr];
        if ([ACCDeviceAuth acc_authorizationStatusForPhoto] == PHAuthorizationStatusAuthorized &&
            self.mattingView.photoCollector == nil &&
            [self isDirectShoot]) {
            acc_dispatch_main_async_safe(^{
                self.mattingView.photoCollector = [[AWEAlbumPixaloopPhotoCollector alloc] initWithIdentifier:identifier
                                                                                                 pixaloopAlg:pixaloopAlg
                                                                                            pixaloopRelation:pixaloopRelation
                                                                                                pixaloopImgK:pixaloopImgK
                                                                                            pixaloopSDKExtra:pixaloopSDKExtra];
                self.mattingView.showPixaloopPlusButton = YES;
                [self.mattingView addPhotoLibraryChangeObserver];
                [self p_showMattingViewWithProp:self.selectedEffectModel];
            });
        }
    } else if ([self.selectedEffectModel isVideoBGPixaloopSticker]) {
        NSDictionary *pixaloopSDKExtra = [self.selectedEffectModel pixaloopSDKExtra];
        NSString *pixaloopImgK = [pixaloopSDKExtra acc_pixaloopImgK:@"vl"];
        NSString *pixaloopResourcePath = [pixaloopSDKExtra acc_pixaloopResourcePath:@"vl"];
        if ([ACCDeviceAuth acc_authorizationStatusForPhoto] == PHAuthorizationStatusAuthorized &&
            self.mattingView.photoCollector == nil &&
            [self isDirectShoot]) {
            acc_dispatch_main_async_safe(^{
                self.mattingView.photoCollector = [[AWEAlbumVideoCollector alloc] initWithIdentifier:@"video_bg" pixaloopVKey:pixaloopImgK pixaloopResourcePath: pixaloopResourcePath];
                self.mattingView.photoCollector.maxDetectCount = 100;
                self.mattingView.showPixaloopPlusButton = YES;
                [self p_showMattingViewWithProp:self.selectedEffectModel];
            });
        }
    }
}

- (BOOL)albumViewControllerShouldSelectAsset:(AWEAssetModel *)asset
{
    if (self.selectedEffectModel && [self.mattingView.photoCollector isKindOfClass:[AWEAlbumPixaloopPhotoCollector class]]) {
        NSString *plStr = @"pl";
        NSInteger albumFilterNumber = [self.selectedEffectModel.pixaloopSDKExtra acc_albumFilterNumber:plStr];
        if (albumFilterNumber == AWEFilterNumberPannelAndAlbumFilter || albumFilterNumber == AWEFilterNumberAlbumFilter) {
            BOOL pixaloopSupport = [self p_pixaloopSupportAsset:asset forEffectModel:self.selectedEffectModel];
            if (!pixaloopSupport) {
                NSString *hintStr = self.selectedEffectModel.pixaloopExtra.acc_effectAlgorithmHint;
                if (ACC_isEmptyString(hintStr)) {
                    hintStr = ACCLocalizedCurrentString(@"not_meet_algo_requirement_toast");
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [ACCToast() show:hintStr];
                });
                return NO;
            }
        }
    }
    return YES;
}
- (void)albumViewControllerDidSelectAssets:(NSArray<AWEAssetModel *> *)selectedAssets
{
    if ([self.selectedEffectModel isMultiAssetsPixaloopProp]) {
        [self.mattingView updateSelectedAssetArray:selectedAssets];
    }
}

#pragma mark - AWEModernStickerCollectionViewCoordinatorDelegate

- (AWEVideoPublishViewModel *)modernStickerSwitchTabViewPublishModel
{
    return [self.actionDelegate providedPublishModel];
}

- (BOOL)modernStickerSwitchTabViewWillSeletedAtIndex:(NSInteger)index {
    return NO;
}

- (void)modernStickerSwitchTabViewDidTapToChangeTabAtIndex:(NSInteger)index {
    if ([self.actionDelegate respondsToSelector:@selector(modernStickerViewControllerDidTapToChangeTabAtIndex:)]) {
        [self.actionDelegate modernStickerViewControllerDidTapToChangeTabAtIndex:index];
    }
}

- (void)modernStickerSwitchTabViewDidSelectedAtIndex:(NSInteger)index
{
    if ([self.actionDelegate respondsToSelector:@selector(modernStickerViewControllerDidSelectTabAtIndex:)]) {
        [self.actionDelegate modernStickerViewControllerDidSelectTabAtIndex:index];
    }
    // 获取数据是需要设置为NO，等获取逻辑结束后设置为YES
    self.fetchCategoryDataCompleted = NO;
    [self p_handleEnablePageFetchCaseWhenSelectedSwitchTabAtIndex:index];
}

- (void)animatedSwitchContentCollectionViewIfNeededForSection:(NSUInteger)section currentSection:(NSUInteger)currentSection removeFakeImage:(BOOL)removeFakeImage completion:(void(^)(UIImageView *fakeImageView)) completion {
    if (section == 0 && self.stickerContentCollectionView.contentOffset.x == 0) {
        ACCBLOCK_INVOKE(completion, nil);
        return;
    }
    if (section == 1 && self.stickerContentCollectionView.contentOffset.x == self.stickerContentCollectionView.acc_width) {
        ACCBLOCK_INVOKE(completion, nil);
        return;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:currentSection];
    UICollectionViewCell *targetCell = [self.stickerContentCollectionView cellForItemAtIndexPath:indexPath];
    if (!targetCell) {
        ACCBLOCK_INVOKE(completion, nil);
        return;
    }
    CGRect aimedRect = [self.view convertRect:self.stickerContentCollectionView.frame fromView:self.stickerContentCollectionView.superview];
    UIImage *previousImage = [self getStickerContentCollectionViewCellSnapshotImageWithIndexPath:indexPath];
    UIImageView *fakePreviousImage = [[UIImageView alloc] initWithFrame:aimedRect];
    fakePreviousImage.image = previousImage;
    [self.view addSubview:fakePreviousImage];
    CGFloat x = 0;
    switch (section) {
        case 0:
            x = 0;
            break;
        case 1:
            x = self.stickerContentCollectionView.acc_width;
        default:
            break;
    }
    CGPoint aimedOffset = CGPointMake(x, 0);
    self.stickerContentCollectionView.alpha = 0;
    [self.stickerContentCollectionView setContentOffset:aimedOffset animated:NO];

    @weakify(fakePreviousImage);
    [UIView animateWithDuration:removeFakeImage ? 0.25 : 0 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        @strongify(fakePreviousImage);
        if (removeFakeImage) {
            fakePreviousImage.alpha = 0;
            self.stickerContentCollectionView.alpha = 1;
        } else {
            // 这样保证cell != nil
            self.stickerContentCollectionView.alpha = 0.1;
        }
    } completion:^(BOOL finished) {
        @strongify(fakePreviousImage);
        if (finished && removeFakeImage) {
            [fakePreviousImage removeFromSuperview];
        }
        ACCBLOCK_INVOKE(completion, fakePreviousImage);
    }];
}

- (UIImage *)getStickerContentCollectionViewCellSnapshotImageWithIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *targetCell = [self.stickerContentCollectionView cellForItemAtIndexPath:indexPath];
    if (!targetCell) {
        return nil;
    }
    UIGraphicsBeginImageContextWithOptions(targetCell.frame.size, NO, UIScreen.mainScreen.scale);
    [self.stickerContentCollectionView drawViewHierarchyInRect:targetCell.bounds afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


#pragma mark - AWEAggregatedEffectViewDelegate

- (id<ACCCameraService>)aggregatedEffectViewCameraService
{
    return self.actionDelegate.cameraService;
}

- (BOOL)shouldTrackPropEvent:(AWEAggregatedEffectView *)aggregatedEffectView
{
    return [self.actionDelegate providedPublishModel].repoContext.recordSourceFrom == AWERecordSourceFromUnknown;
}

- (BOOL)aggregatedEffectView:(AWEAggregatedEffectView *)aggregatedEffectView
    shouldBeSelectedWithCell:(AWEModernStickerCollectionViewCell *)stickerCell
{
    switch (stickerCell.effect.effectType) {
        case IESEffectModelEffectTypeNormal: {
            NSString *errorToast = nil;
            if ([self.actionDelegate respondsToSelector:@selector(modernStickerViewControllerShouldApplyEffect:errorToast:)] &&
                ![self.actionDelegate modernStickerViewControllerShouldApplyEffect:stickerCell.effect errorToast:&errorToast]) {
                [ACCToast() showError:errorToast];
                return NO;
            }
        }
            break;
        case IESEffectModelEffectTypeCollection:
            break;
        case IESEffectModelEffectTypeSchema: {
            if (stickerCell.effect.effectType == IESEffectModelEffectTypeSchema) {
                if (stickerCell.effect.schema.length) {
                    [ACCRouter() transferToURLStringWithFormat:@"%@", stickerCell.effect.schema];
                }
                return NO;
            }
        }
            break;
    }

    return YES;
}

- (void)aggregatedEffectView:(AWEAggregatedEffectView *)aggregatedEffectView
         didSelectEffectCell:(AWEModernStickerCollectionViewCell *)stickerCell
{
    [self userDidTapEffect:stickerCell.effect];

    self.lastClickedEffectModel = stickerCell.effect;
    self.selectedChildEffectModel = stickerCell.effect;
    [self updateOriginStickerUserViewAndCommerceEnterViewWithEffect:self.selectedChildEffectModel];
    if (!stickerCell.effect.downloaded) { // 贴纸对应的资源还没有下载到本地
        stickerCell.effect.downloadStatus = AWEEffectDownloadStatusUndownloaded;
        stickerCell.downloadStatus = AWEModernStickerDownloadStatusUndownloaded;
        @weakify(self);
        @weakify(stickerCell);
        stickerCell.downloadStatus = AWEModernStickerDownloadStatusDownloading;

        CFTimeInterval startTime = CACurrentMediaTime();
        [[AWEEffectPlatformManager sharedManager] downloadEffect:stickerCell.effect trackModel:[self commonStickerDownloadTrackModel] progress:^(CGFloat progress) {
            [stickerCell updateDownloadProgress:progress];
        } completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
            @strongify(self);
            @strongify(stickerCell);
            if (!error && filePath) { // 下载成功
                [self.dataManager downloadBindingMusicIfNeeded:stickerCell.effect completion:^(NSError * _Nullable error) {
                    @strongify(self);
                    @strongify(stickerCell);
                    if (error) {
                        stickerCell.downloadStatus = AWEModernStickerDownloadStatusUndownloaded;
                        stickerCell.effect.downloadStatus = AWEEffectDownloadStatusUndownloaded;
                    } else {
                        if ([NSThread isMainThread]) {
                            [self updateCellAfterAggregatedEffectViewSelectEffectCell:stickerCell];
                        } else {
                            dispatch_async(dispatch_get_main_queue(), ^{
                               [self updateCellAfterAggregatedEffectViewSelectEffectCell:stickerCell];
                            });
                        }
                    }
                }];

                [self trackDownloadPerformanceWithEffect:stickerCell.effect startTime:startTime success:YES error:error];
            } else {
                stickerCell.downloadStatus = AWEModernStickerDownloadStatusUndownloaded;
                stickerCell.effect.downloadStatus = AWEEffectDownloadStatusUndownloaded;

                [self didFailedDownloadEffect:stickerCell.effect withError:error];
                [self trackDownloadPerformanceWithEffect:stickerCell.effect startTime:startTime success:NO error:error];
            }
        }];
    } else { // 贴纸已经下载到本地了
        stickerCell.downloadStatus = AWEModernStickerDownloadStatusDownloaded;
        stickerCell.effect.downloadStatus = AWEEffectDownloadStatusDownloaded;

        if ([self.actionDelegate respondsToSelector:@selector(stickerHintViewRemove)]) {
            [self.actionDelegate stickerHintViewRemove];
        }
        if ([self.actionDelegate respondsToSelector:@selector(stickerHintViewShowWithEffect:)]) {
            [self.actionDelegate stickerHintViewShowWithEffect:stickerCell.effect];
        }

        [self applyStickerToDelegateWithEffect:stickerCell.effect];
        IESEffectModel *effectModel = [self.aggregatedEffectView nextEffectOfSelectedEffect];
        [self p_silentlyDownloadEffect:effectModel];
    }
}

- (void)updateCellAfterAggregatedEffectViewSelectEffectCell:(AWEModernStickerCollectionViewCell *)stickerCell {
    stickerCell.downloadStatus = AWEModernStickerDownloadStatusDownloaded;
    stickerCell.effect.downloadStatus = AWEEffectDownloadStatusDownloaded;
    if ([stickerCell.effect.effectIdentifier isEqualToString:self.lastClickedEffectModel.effectIdentifier]) { // 检查当前cell是不是最后一次点击的cell
        if ([self.actionDelegate respondsToSelector:@selector(stickerHintViewShowWithEffect:)]) {
            [self.actionDelegate stickerHintViewShowWithEffect:stickerCell.effect];
        }

        [self applyStickerToDelegateWithEffect:stickerCell.effect];
        IESEffectModel *effectModel = [self.aggregatedEffectView nextEffectOfSelectedEffect];
        [self p_silentlyDownloadEffect:effectModel];
    }
}

- (UIViewController*)clipVideoPageVC:(AWEAssetModel*)asset completion:(void(^)(ACCEditVideoData *videoData ,id<ACCMusicModelProtocol> music, UIImage *coverImage))completion{
    //这里原有逻辑是根据current length mode 来取对应的值，所以这里将调用改为currentVideoMaxSeconds
    //The original logic here is to take the corresponding value according to the current length mode, so the call here is changed to current VideoMax Seconds
    CGFloat maxClipDuration = [self.videoConfig currentVideoMaxSeconds];
    NSString* clipedResultSavePath =  [AWEDraftUtils generatePathFromTaskId: self.videoBGStickerManager.delegate.publishModel.repoDraft.taskID  name:[@"bgVStickerTemp" stringByAppendingFormat:@"_%@.mov",[NSUUID UUID].UUIDString]];

    let clipVideoObj = IESAutoInline(ACCBaseServiceProvider(), ACCClipVideoProtocol);
    UIViewController* clipViewController = [clipVideoObj clipViewController:@[asset] maxClipDuration:maxClipDuration clipedResultSavePath:clipedResultSavePath allowFastImport:NO allowSpeedControl:NO inputData:@{@"publishModel":[self.videoBGStickerManager.delegate.publishModel copy],@"isBGVideoStikerMode":@(YES)} completion:completion];
    clipViewController.modalPresentationStyle = UIModalPresentationCustom;
    clipViewController.modalPresentationCapturesStatusBarAppearance = YES;
    clipViewController.transitioningDelegate = self.clipTransitionDelegate;
    return clipViewController;
}

- (id<UIViewControllerTransitioningDelegate>)clipTransitionDelegate
{
    if (!_clipTransitionDelegate) {
        _clipTransitionDelegate = [IESAutoInline(ACCBaseServiceProvider(), ACCTransitioningDelegateProtocol) modalLikePushTransitionDelegate];
    }
    return _clipTransitionDelegate;
}

#pragma mark - ACCPanelViewProtocol

- (void *)identifier
{
    return ACCRecordStickerPanelContext;
}

- (CGFloat)panelViewHeight
{
    return self.view.acc_height;
}

#pragma mark - private method

- (BOOL)isClickedCurrentApplyedEffect:(IESEffectModel *)effect
{
    return self.selectedEffectModel && [self.selectedEffectModel.effectIdentifier isEqualToString:effect.effectIdentifier];
}

- (BOOL)p_pixaloopSupportAsset:(AWEAssetModel *)assetModel forEffectModel:(IESEffectModel *)model
{
    NSString *plStr = @"pl";
    NSDictionary *pixaloopSDKExtra = model.pixaloopSDKExtra;
    NSArray<NSString *> *pixaloopAlg = [pixaloopSDKExtra acc_pixaloopAlg:plStr];
    NSString *pixaloopRelation = [pixaloopSDKExtra acc_pixaloopRelation:plStr];
    NSString *pixaloopImgK = [pixaloopSDKExtra acc_pixaloopImgK:plStr];
    NSString *const identifier = [@"pixaloop" stringByAppendingString:model.effectIdentifier];
    AWEAlbumPixaloopPhotoCollector *pixaloopCollector = [[AWEAlbumPixaloopPhotoCollector alloc] initWithIdentifier:identifier
                                                                                     pixaloopAlg:pixaloopAlg
                                                                                pixaloopRelation:pixaloopRelation
                                                                                    pixaloopImgK:pixaloopImgK
                                                                                pixaloopSDKExtra:pixaloopSDKExtra];
    return [pixaloopCollector isPixaloopSupportWithAsset:assetModel.asset] >= AWEAlbumPhotoCollectorDetectResultMatch;
}

- (BOOL)enableNewFavoritesTitle {
    NSString *currentLanguage = ACCI18NConfig().currentLanguage;
    return [currentLanguage isEqualToString:@"zh"];;
}

- (IESEffectModel *)potentialChildEffectOfParentEffect:(IESEffectModel *)parentEffect {
    __block IESEffectModel *potentialChildEffect = nil;
    [parentEffect.childrenEffects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.effectType != IESEffectModelEffectTypeSchema) {
            potentialChildEffect = obj;
            *stop = YES;
        }
    }];
    return potentialChildEffect;
}

- (IESEffectModel *)p_effectModelForIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && !self.isStoryMode) {
        if (indexPath.row >= self.dataManager.collectionEffects.count) {
            return nil;
        } else {
            return self.dataManager.collectionEffects[indexPath.row];
        }
    } else {
        IESCategoryModel *categoryModel;
        if (self.isStoryMode) {
            if (indexPath.section >= self.dataManager.stickerCategories.count) {
                return nil;
            }
            categoryModel = self.dataManager.stickerCategories[indexPath.section];
        } else {
            if (indexPath.section > self.dataManager.stickerCategories.count) {
                return nil;
            }
            categoryModel = self.dataManager.stickerCategories[indexPath.section - 1];
        }
        if (indexPath.row > categoryModel.aweStickers.count - 1) {
            return nil;
        }
        IESEffectModel *effectModel = categoryModel.aweStickers[indexPath.row];
        return effectModel;
    }
}

- (void)p_clearSeletedCells
{
    for (AWEModernStickerContentCollectionViewCell *contentCell in [self.stickerContentCollectionView visibleCells]) {
        [contentCell.collectionView clearSelectedCellsForSelectedModel:self.selectedEffectModel];
    }
}

- (BOOL)p_getFavoriteStatusForSticker:(IESEffectModel *)model
{
    BOOL hasFavorite = NO;
    if (!model) {
        self.favoriteButton.selected = hasFavorite;
        return hasFavorite;
    }
    for (IESEffectModel *effectModel in self.dataManager.collectionEffects) {
        if ([model.effectIdentifier isEqualToString:effectModel.effectIdentifier]) {
            hasFavorite = YES;
            break;
        }
    }
    return hasFavorite;
}

- (void)configCommerceEnteStickerWithEffectModel:(IESEffectModel *)effectModel
{
    if (![effectModel hasCommerceEnter]) {
        self.commerceEnterView.hidden = YES;
        return;
    }
    BOOL needToTrack = !self.lastTrackedCommerceEnterPropID || (![effectModel.effectIdentifier isEqualToString:self.lastTrackedCommerceEnterPropID]);
    if (self.isShowing && needToTrack) {
        self.lastTrackedCommerceEnterPropID = effectModel.effectIdentifier;
        [ACCTracker() trackEvent:@"show_transform_link"
                                         params:@{@"shoot_way": self.dataManager.referString ?: @"",
                                                  @"carrier_type": @"prop_panel",
                                                  @"prop_id": effectModel.effectIdentifier ?: @""
                                                  }
                                needStagingFlag:NO];
    }
    self.originStickerUserView.hidden = YES;
    self.hotEffectHintView.hidden = YES;
    [self.commerceEnterView acc_fadeShow];
    [self.commerceEnterView updateStickerDataWithEffectModel:effectModel];
}

- (void)p_processCommerceStickerWithEffect:(IESEffectModel *)effect
{
    NSString *effectID = effect.effectIdentifier;

    if (ACC_isEmptyString(effectID)) {
        return;
    }

    NSDictionary *params = @{
                             @"toast_type": @"prop",
                             @"prop_id": effectID,
                             @"enter_from": @"video_shoot_page"
                             };

    if (self.cachedCommerceStickerDict[effectID]) {
        self.originStickerUserView.hidden = NO;
        id<ACCCommerceStickerDetailModelProtocol> commerce = self.cachedCommerceStickerDict[effectID];
        [ACCTracker() trackEvent:@"show_toast" params:params needStagingFlag:NO];
        [self.originStickerUserView updateWithCommerceModel:commerce];
        return;
    }
    @weakify(self);
    [IESAutoInline(ACCBaseServiceProvider(), ACCStickerNetServiceProtocol) requestStickerWithId:effectID completion:^(id<ACCStudioNewFaceStickerModelProtocol> _Nullable firstStickerModel, NSError * _Nullable error) {
        @strongify(self);
        if (error) {
            AWELogToolError(AWELogToolTagRecord, @"request sticker failed: %@", error);
            return;
        }

        BOOL shouldShowCommerceView = YES;
        if (!firstStickerModel || !firstStickerModel.commerceStickerModel) {
            shouldShowCommerceView = NO;
        }
        id<ACCCommerceStickerDetailModelProtocol> commerce = firstStickerModel.commerceStickerModel;
        if (ACC_isEmptyString(commerce.screenDesc)) {
            shouldShowCommerceView = NO;
        }
        // If the user choosed another prop during this request, we directly return and show nothing.
        if (![effectID isEqualToString:self.lastClickedEffectModel.effectIdentifier]) {
            return;
        }
        if (shouldShowCommerceView) {
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                self.originStickerUserView.hidden = NO;
                self.cachedCommerceStickerDict[effectID] = commerce;
                [ACCTracker() trackEvent:@"show_toast" params:params needStagingFlag:NO];
                [self.originStickerUserView updateWithCommerceModel:commerce];
            });
        } else {
            [self p_configOriginStickerUserViewWithEffectModel:effect];
        }

    }];
}

- (void)p_configOriginStickerUserViewWithEffectModel:(IESEffectModel *)effect
{
    if (effect == nil || effect.source != IESEffectModelEffectSourceOriginal) {
        self.originStickerUserView.hidden = YES;
        return;
    }
    NSString *userId = effect.designerId;
    NSString *secUserId = effect.designerEncryptedId;
    if (userId.length == 0) {
        return;
    }
    id<ACCUserModelProtocol> user = [self.cachedUserNameDict acc_objectForKey:userId];
    if (user) {
        self.originStickerUserView.hidden = NO;
        [self.originStickerUserView updateWithUserModel:user];
    } else {
        @weakify(self);
        [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) getUserProfileWithID:userId secUserID:secUserId completion:^(id<ACCUserModelProtocol> user, NSError *error) {
            @strongify(self);
            if (error) {
                AWELogToolError(AWELogToolTagRecord, @"get user profile failed: %@", error);
                return;
            }
            if (user.userID.length) {
                self.cachedUserNameDict[user.userID] = user;
            }
            NSString *lastDesignerId = self.lastClickedEffectModel.designerId;
            if (lastDesignerId.length > 0 && [user.userID isEqualToString:lastDesignerId]) {
                self.originStickerUserView.hidden = NO;
                [self.originStickerUserView updateWithUserModel:user];
            }
        }];
    }
}

- (void)p_setSelectedEffectModelWithEffect:(IESEffectModel *)effect
{
    NSString *createID = @"";
    if ([self.actionDelegate respondsToSelector:@selector(providedPublishModel)]) {
        createID = [self.actionDelegate providedPublishModel].repoContext.createId;
    }
    [self.stickerShowcaseEntranceView updateWithSticker:effect creationID:createID];
    // 设置选中的effectModel
    if (effect) {
        self.selectedEffectModel = effect;
        self.lastClickedEffectModel = effect;
        BOOL noNeedLoadingAnimation = NO;
        BOOL selectedEffectHasChildrenEffect = NO;
        IESEffectModel *tobeUsedFirstChildEffectModel = nil;
        NSArray<IESEffectModel *> *childrenEffectsOfSelectedEffect = effect.childrenEffects;
        // 判断是否有子贴纸
        selectedEffectHasChildrenEffect = childrenEffectsOfSelectedEffect.count > 0;
        if (selectedEffectHasChildrenEffect) {
            tobeUsedFirstChildEffectModel = [self potentialChildEffectOfParentEffect:effect];
        }

        if (selectedEffectHasChildrenEffect) { // 有子贴纸
            [self p_hiddenMattingView]; // 隐藏 mattingView
            if (!self.selectedChildEffectModel) { // 如果前一个选中的贴纸不是聚合贴纸，展示出 聚合贴纸view
                [self p_showAggregatedEffectView]; // 展示 聚合贴纸view
            } else {
                //如果之前选中的贴纸是聚合贴纸，不用管，直接刷新数据就行
            }
            NSMutableDictionary *trackingInfoDict = [self createChildEffectsContainerTrackingInfoDict];
            self.aggregatedEffectView.trackingInfoDictionary = [trackingInfoDict copy];
            [self.aggregatedEffectView updateAggregatedEffectArrayWith:childrenEffectsOfSelectedEffect];
            [self.aggregatedEffectView updateSelectEffectWithEffect:tobeUsedFirstChildEffectModel];
            [self.actionDelegate stickerHintViewRemove];
            [self.actionDelegate stickerHintViewShowWithEffect:tobeUsedFirstChildEffectModel];
            // 如果之前选中的ChildEffect与现在选中的childeffect相同，我们不需要再loading effect
            noNeedLoadingAnimation = [self.selectedChildEffectModel.effectIdentifier isEqualToString:tobeUsedFirstChildEffectModel.effectIdentifier];
            self.selectedChildEffectModel = tobeUsedFirstChildEffectModel;
            self.lastClickedEffectModel = tobeUsedFirstChildEffectModel;
            if (!noNeedLoadingAnimation) { // 如果选中了聚合类特效并且和之前的选中子特效不一样，则需要让子特效加载loading动画
                [self.aggregatedEffectView setNeedLoadingAnimationForSelectedCell];
            }
            [self updateOriginStickerUserViewAndCommerceEnterViewWithEffect:tobeUsedFirstChildEffectModel];
        } else { // 没有子贴纸
            self.selectedChildEffectModel = nil;
            [self p_hiddenAggregatedEffectViewWithCompletionBlock:nil];
            [self configCommerceEnteStickerWithEffectModel:effect];
        }
        [self p_updateFavoriteButtonWithSticker:self.selectedEffectModel manually:YES];
        if (!noNeedLoadingAnimation) {
            [self applyStickerToDelegateWithEffect:self.selectedEffectModel];
        }
    } else {
        [self.actionDelegate stickerHintViewRemove];
        if ([self.selectedEffectModel isVideoBGPixaloopSticker]) {
            [self.videoBGStickerManager resetVideoBGCamera];
        }
        self.selectedEffectModel = nil;
        // 清理选中道具时将选中道具的indexPath置为nil。
        // Reset to nil when clear the selected sticker.
        self.selectedEffectIndexPath = nil;
        self.lastClickedEffectModel = nil;
        self.dataManager.selectedEffect = nil;
        self.lastTrackedCommerceEnterPropID = nil;
        self.videoBGStickerManager.currentApplyVideoBGUrl = nil;
        self.videoBGStickerManager.currentSelectedMattingAssetModel = nil;
        [self p_updateFavoriteButtonWithSticker:nil manually:YES];
        if ([self.delegate respondsToSelector:@selector(applySticker:completion:)]) {
            [self.delegate applySticker:nil completion:nil];
        }
        [self applyComposerStickerToDelegateWithEffect:nil];
        [self updateOriginStickerUserViewAndCommerceEnterViewWithEffect:nil];
        // 如果没有选中cell，则清除selectedChildEffect.
        self.selectedChildEffectModel = nil;
        [self p_hiddenAggregatedEffectViewWithCompletionBlock:nil];
    }
    self.needRestoreSubViewHiddenStates = NO;
}

- (void)applyStickerToDelegateWithEffect:(IESEffectModel *)effect {
    // 统一添加面板道具来源
    [self p_updateFavoriteButtonWithSticker:self.selectedEffectModel manually:YES];
    IESEffectModel *potentialChildEffect = [self potentialChildEffectOfParentEffect:effect];
    IESEffectModel *toApplySticker = potentialChildEffect ?: effect;
    toApplySticker.propSelectedFrom = effect.propSelectedFrom;

    [self fetchRecommendedMusicListIfNeededWithEffect:toApplySticker];

    [self engineWillApplyEffect:toApplySticker];

        if ([self.actionDelegate respondsToSelector:@selector(providedPublishModel)]) {
            AWEVideoPublishViewModel *publishModel = [self.actionDelegate providedPublishModel];
            NSDictionary *referExtra = publishModel.repoTrack.referExtra;

            NSDictionary *recordTrackInfos = @{
                @"creation_id": referExtra[@"creation_id"] ?: @"",
                @"shoot_way": referExtra[@"shoot_way"] ?: @"",
                @"content_source": referExtra[@"content_source"] ?: @"",
                @"content_type": referExtra[@"content_type"] ?: @"",
                @"enter_from": referExtra[@"enter_from"] ?: @"",
                @"prop_id": toApplySticker.effectIdentifier ?: @""
            };

            [toApplySticker setRecordTrackInfos:recordTrackInfos];
        }

    @weakify(self);
    if ([self.actionDelegate respondsToSelector:@selector(modernStickerViewControllerDidChangeSelection:)]) {
        ACCPropSelection *selection = [[ACCPropSelection alloc] initWithEffect:toApplySticker source:ACCPropSelectionSourceClassic];
        [self.actionDelegate modernStickerViewControllerDidChangeSelection:selection];
    }
    if ([self.delegate respondsToSelector:@selector(applySticker:completion:)]) {
        [self.delegate applySticker:toApplySticker completion:^(BOOL success, NSInteger stickerId, NSString *resourcePath) {
            @strongify(self);
            if (potentialChildEffect) {
                // 如果点击了一个聚合类，Apply成功后停止子面板Cell的loading
                [self.aggregatedEffectView cleanLoadingSelectedCell];
            }
        }];
    }
}

- (void)applyComposerStickerToDelegateWithEffect:(id<AWEComposerEffectProtocol>)effect {
    if ([self.actionDelegate respondsToSelector:@selector(modernStickerViewControllerDidChangeSelection:)]) {
        ACCPropSelection *selection = [[ACCPropSelection alloc] initWithEffect:self.selectedEffectModel composerEffect:effect source:ACCPropSelectionSourceClassic];
        [self.actionDelegate modernStickerViewControllerDidChangeSelection:selection];
    }
    if ([self.delegate respondsToSelector:@selector(applyComposerSticker:extra:)]) {
        [self.delegate applyComposerSticker:effect extra:self.selectedEffectModel.extra];
    }
}

- (void)p_handleEnablePageFetchCaseWhenSelectedSwitchTabAtIndex:(NSInteger)index {
    self.shouldIgnoreSwitchTabViewScrollEvent = NO;
    if (![self.dataManager enablePagingStickers]) {
        self.fetchCategoryDataCompleted = YES;
        return;
    }

    index = self.isStoryMode ? index : index - 1;
    if (index < 0 || index >= self.dataManager.stickerCategories.count) {
        self.fetchCategoryDataCompleted = YES;
        return;
    }

    // 切换到第0个tab（也就是热门tab）时不需要拉取数据，因为数据已经跟着分类tab下发下来了
    IESCategoryModel *category = [self.dataManager.stickerCategories objectAtIndex:index];
    if (0 == index) {
        if (category.effects.count > 0) {
            self.loadingView.hidden = YES;
            self.fetchCategoryDataCompleted = YES;
            return;
        }
    }

    if ([self.dataManager.updatedCategoriesSet containsObject:@(index)]) {
        self.loadingView.hidden = YES;
        self.fetchCategoryDataCompleted = YES;
        return;
    }

    self.lastLoadingIndex = index;
    self.loadingView.hidden = NO;

    @weakify(self);
    [self.dataManager fetchStickersForIndex:index completion:^(BOOL downloadSuccess, NSInteger successIndex) {
        @strongify(self);
        self.fetchCategoryDataCompleted = YES;
        if (successIndex == -1 || successIndex == self.lastLoadingIndex) {
            self.loadingView.hidden = YES;
        }
        if (successIndex == self.lastSelectedTabIndex && !downloadSuccess) {
            [ACCToast() show:ACCLocalizedCurrentString(@"com_mig_there_was_a_problem_with_the_internet_connection_try_again_later_yq455g")];
        }
        if (downloadSuccess) {
            [self reloadStickerContentCollectionViewIfNeeded];
        }
    }];
}

- (void)fetchRecommendedMusicListIfNeededWithEffect:(IESEffectModel *)effectModel
{
    if (!effectModel) {
        return;
    }
    if ([self.actionDelegate respondsToSelector:@selector(providedPublishModel)]) {
        AWEVideoPublishViewModel *publishModel = [self.actionDelegate providedPublishModel];
        if (publishModel.repoVideoInfo.fragmentInfo.count > 0) {
            return; //Ban recommended music bubble if recording start
        }
        if ([self.actionDelegate respondsToSelector:@selector(requestRecommendedMusicListForPropWithEffect:creationID:)]) {
            [self.actionDelegate requestRecommendedMusicListForPropWithEffect:effectModel creationID:publishModel.repoContext.createId];
        }
    }
}


#pragma mark - Matting View

- (void)p_showMattingViewWithProp:(IESEffectModel *)model
{
    self.displayingTrayView |= AWEModernStickerTrayViewOptionMatting;
    if (ACC_FLOAT_EQUAL_TO(self.mattingView.alpha, 1.0f)) {
        return;
    }

    // Make sure self.view is loaded before showing matting view.
    // Otherwise the favoriteView's layout is not right.
    if (![self isViewLoaded]) {
        [self view];
    }

    [ACCBubble() removeBubble:self.favoriteBubble];
    [self updateFavoriteView];
    ACCMasUpdate(self.mattingView, {
        make.bottom.equalTo([self bottomContraintNeighborView].mas_top).offset(-5.f);
    });
    if ([model isMultiAssetsPixaloopProp]) {
        self.mattingView.enableMultiAssetsSelection = YES;
        NSDictionary *pixaloopSDKExtra = [[model pixaloopSDKExtra] acc_dictionaryValueForKey:@"pl"];
        self.mattingView.maxAssetsSelectionCount = [pixaloopSDKExtra acc_maxAssetsSelectionCount];
        self.mattingView.minAssetsSelectionCount = [pixaloopSDKExtra acc_minAssetsSelectionCount];
    }
    [self.view setNeedsUpdateConstraints];
    [self.view updateConstraintsIfNeeded];
    [UIView animateWithDuration:0.15
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.mattingView.alpha = 1.0f;
                         [self.view layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         self.mattingView.alpha = 1.0f;
                     }];

    [self p_mattingViewStartingFaceDetect];
}

- (void)p_hiddenMattingView
{
    self.displayingTrayView &= ~AWEModernStickerTrayViewOptionMatting;
    if (ACC_FLOAT_EQUAL_TO(self.mattingView.alpha, 0.0f)) {
        return;
    }
    [self updateFavoriteView];

    ACCMasUpdate(self.mattingView, {
        make.bottom.equalTo([self bottomContraintNeighborView].mas_top);
    });

    [self.view setNeedsUpdateConstraints];
    [self.view updateConstraintsIfNeeded];
    [UIView animateWithDuration:0.15
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.mattingView.alpha = 0.0f;
                         [self.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         self.mattingView.alpha = 0.0f;
                     }];
    [self.mattingView resetToInitState];
}

#pragma mark - AggregatedEffectView

- (void)p_showAggregatedEffectView
{
    self.displayingTrayView |= AWEModernStickerTrayViewOptionAggregated;
    if (ACC_FLOAT_EQUAL_TO(self.aggregatedEffectView.alpha, 1.0f)) {
        return;
    }

    [ACCBubble() removeBubble:self.favoriteBubble];
    [self updateFavoriteView];
    ACCMasUpdate(self.aggregatedEffectView, {
        make.bottom.equalTo([self bottomContraintNeighborView].mas_top).offset(-7.5);
    });

    [self.view setNeedsUpdateConstraints];
    [self.view updateConstraintsIfNeeded];
    [UIView animateWithDuration:0.15
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.aggregatedEffectView.alpha = 1.0f;
                         [self.view layoutIfNeeded];
                     } completion:nil];
}

- (void)p_hiddenAggregatedEffectViewWithCompletionBlock:(void(^)(void))completion
{
    self.displayingTrayView &= ~AWEModernStickerTrayViewOptionAggregated;
    if (ACC_FLOAT_EQUAL_TO(self.aggregatedEffectView.alpha, 0.0f)) {
        return;
    }

    [self updateFavoriteView];

    ACCMasUpdate(self.aggregatedEffectView, {
        make.bottom.equalTo([self bottomContraintNeighborView].mas_top);
    });

    [self.view setNeedsUpdateConstraints];
    [self.view updateConstraintsIfNeeded];
    [UIView animateWithDuration:0.15
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.aggregatedEffectView.alpha = 0.0f;
                         [self.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         if (completion) {
                             completion();
                         }
                     }];
}

- (NSArray<IESEffectModel *> *)bindEffectsForSelectedEffect {
    NSArray<IESEffectModel *> *bindEffects = [self.dataManager bindEffectsForEffect:self.selectedEffectModel];
    return bindEffects;
}

#pragma mark -

- (void)cameraButtonPressed:(UIButton *)button {
    BOOL shouldSwitchPosition = button.alpha == 1.0;
    if (shouldSwitchPosition) {
        [button acc_counterClockwiseRotate];
        [self.actionDelegate modernStickerViewControllerTappedCameraButton:self.cameraButton];
    } else {
        ACCBLOCK_INVOKE(button.acc_disableBlock);
    }
}

- (void)storyCameraButtonPressed:(UIButton *)button
{
    BOOL shouldSwitchPosition = button.alpha == 1.0;
    if (shouldSwitchPosition) {
        [button acc_counterClockwiseRotate];
        [self.actionDelegate modernStickerViewControllerTappedCameraButton:button];
    } else {
        ACCBLOCK_INVOKE(button.acc_disableBlock);
    }
}

- (AVCaptureDevicePosition)defaultPosition {
    NSNumber *storedKey = [ACCCache() objectForKey:HTSVideoDefaultDevicePostionKey];
    if (storedKey != nil) {
        return [storedKey integerValue];
    } else {
        return AVCaptureDevicePositionFront;
    }
}

#pragma mark - lazy init

- (AWEVideoBGStickerManager*)videoBGStickerManager {
    if (!_videoBGStickerManager) {
        _videoBGStickerManager = [[AWEVideoBGStickerManager alloc] init];
    }
    return _videoBGStickerManager;
}

- (NSMutableDictionary<NSString *, id<ACCUserModelProtocol>> *)cachedUserNameDict
{
    if (!_cachedUserNameDict) {
        _cachedUserNameDict = [@{} mutableCopy];
    }
    return _cachedUserNameDict;
}

- (NSMutableDictionary *)cachedCommerceStickerDict
{
    if (!_cachedCommerceStickerDict) {
        _cachedCommerceStickerDict = [@{} mutableCopy];
    }
    return _cachedCommerceStickerDict;
}

- (UIView *)stickerBackgroundView
{
    if (!_stickerBackgroundView) {
        _stickerBackgroundView = [[UIView alloc] init];
        _stickerBackgroundView.backgroundColor = ACCResourceColor(ACCColorConstBGInverse2);
        CGFloat grayViewHeight = [self stickerPannelGrayBackAreagroundHeight];
        CGRect maskFrame = CGRectMake(0, 0, ACC_SCREEN_WIDTH, grayViewHeight);
        _stickerBackgroundView.layer.mask = [self topRoundCornerShapeLayerWithFrame:maskFrame];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wimplicit-retain-self"
        [_stickerBackgroundView addSubview:self.stickerTabContainerView];
        ACCMasMaker(self.stickerTabContainerView, {
            make.top.left.right.equalTo(_stickerBackgroundView);
            make.height.equalTo(@(acc_stickerTabViewHeight));
        });

        [_stickerBackgroundView addSubview:self.stickerContentCollectionView];
        ACCMasMaker(self.stickerContentCollectionView, {
            make.top.equalTo(_stickerBackgroundView).offset(acc_stickerTabViewHeight);
            make.left.right.equalTo(_stickerBackgroundView);
            make.bottom.equalTo(_stickerBackgroundView).offset(kAWEStickerPanelPadding);
        });
#pragma clang diagnostic pop

        [_stickerBackgroundView addSubview:self.loadingView];
        ACCMasMaker(self.loadingView, {
            make.edges.equalTo(self.stickerContentCollectionView);
        });

        [_stickerBackgroundView addSubview:self.errorView];
        ACCMasMaker(self.errorView, {
            make.edges.equalTo(self.stickerContentCollectionView);
        });
    }
    return _stickerBackgroundView;
}

- (UIView *)stickerTabContainerView
{
    if (!_stickerTabContainerView) {
        _stickerTabContainerView = [[UIView alloc] init];
        _stickerTabContainerView.backgroundColor = ACCResourceColor(ACCColorBGCreation5);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wimplicit-retain-self"
        [_stickerTabContainerView addSubview:self.clearStickerApplyBtton];
        ACCMasMaker(self.clearStickerApplyBtton, {
            make.width.equalTo(@52);
            make.height.equalTo(@(acc_stickerTabViewHeight));
            make.left.centerY.equalTo(_stickerTabContainerView);
        });

        UIView *sepLine = [[UIView alloc] init];
        sepLine.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainerInverse);
        [_stickerTabContainerView addSubview:sepLine];
        ACCMasMaker(sepLine, {
            make.width.equalTo(@(1/[UIScreen mainScreen].scale));
            make.height.equalTo(@(20));
            make.centerY.equalTo(_stickerTabContainerView);
            make.right.equalTo(self.clearStickerApplyBtton);
        });
        self.sepLine = sepLine;

        [_stickerTabContainerView addSubview:self.switchTabView];
        [self.switchTabView mas_makeConstraints:^(MASConstraintMaker *maker) {
            maker.left.equalTo(self.clearStickerApplyBtton.mas_right);
            maker.top.right.bottom.equalTo(_stickerTabContainerView);
        }];
#pragma clang diagnostic pop
    }
    return _stickerTabContainerView;
}

- (UICollectionView *)stickerContentCollectionView
{
    if (!_stickerContentCollectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = CGSizeMake(ACC_SCREEN_WIDTH, [self stickerPannelGrayBackAreagroundHeight] - acc_stickerTabViewHeight);
        flowLayout.minimumInteritemSpacing = 0;
        flowLayout.minimumLineSpacing = 0;
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _stickerContentCollectionView = [[AWEModernStickerContentCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _stickerContentCollectionView.backgroundColor = [UIColor clearColor];
        [_stickerContentCollectionView registerClass:[AWEModernStickerContentCollectionViewCell class] forCellWithReuseIdentifier:[AWEModernStickerContentCollectionViewCell identifier]];
        _stickerContentCollectionView.pagingEnabled = YES;
        _stickerContentCollectionView.showsHorizontalScrollIndicator = NO;
        _stickerContentCollectionView.showsVerticalScrollIndicator = NO;
        _stickerContentCollectionView.tag = AWEModernStickerCollectionViewTagContent * 1000;
        _stickerContentCollectionView.dataSource = self;
    }
    return _stickerContentCollectionView;
}

- (UIButton *)clearStickerApplyBtton
{
    if (!_clearStickerApplyBtton) {
        _clearStickerApplyBtton = [[UIButton alloc] init];
        [_clearStickerApplyBtton setImage:ACCResourceImage(@"iconStickerClear") forState:UIControlStateNormal];
        [_clearStickerApplyBtton addTarget:self action:@selector(p_clearStickerApplyButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        _clearStickerApplyBtton.accessibilityLabel = ACCLocalizedCurrentString(@"com_mig_clear_stickers");
    }
    return _clearStickerApplyBtton;
}

- (AWEModernStickerCollectionViewCoordinator *)coordinator {
    if (!_coordinator) {
        _coordinator = [[AWEModernStickerCollectionViewCoordinator alloc] init];
        _coordinator.delegate = self;
    }
    return _coordinator;
}

- (AWEMattingView *)mattingView {
    if (!_mattingView) {
        _mattingView = [[AWEMattingView alloc] init];
        _mattingView.delegate = self;
        _mattingView.alpha = 0.0;
        _mattingView.backgroundColor = ACCResourceColor(ACCColorConstBGInverse2);
    }
    return _mattingView;
}

- (AWEAggregatedEffectView *)aggregatedEffectView {
    if (!_aggregatedEffectView) {
        _aggregatedEffectView = [[AWEAggregatedEffectView alloc] init];
        _aggregatedEffectView.delegate = self;
        _aggregatedEffectView.alpha = 0.0;
    }
    return _aggregatedEffectView;
}

- (UIView *)roundButtonContianerViewWithButton:(UIButton *)button layerColor:(UIColor *)layerColor
{
    return [self cornerButtonContianerViewWithButton:button layerColor:layerColor layerWidth:36];
}

- (UIView *)cornerButtonContianerViewWithButton:(UIButton *)button layerColor:(UIColor *)layerColor layerWidth:(CGFloat)layerWidth
{
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor clearColor];
    CALayer *layer = [CALayer layer];
    layer.backgroundColor = layerColor.CGColor;
    layer.cornerRadius = 18;
    layer.frame = CGRectMake(8, 8, layerWidth, 36);
    layer.name = @"cornerButtonLayer";
    [view.layer addSublayer:layer];
    [view addSubview:button];
    ACCMasMaker(button, {
        make.center.width.height.equalTo(view);
    });
    return view;
}

- (UIView *)favoriteView {
    if (!_favoriteView) {
        UIColor *layerColor = ACCResourceColor(ACCUIColorConstBGContainer3);
        if ([self enableNewFavoritesTitle]) {
            _favoriteView = [self cornerButtonContianerViewWithButton:self.favoriteButton layerColor:layerColor layerWidth:[self getFavoriteButtonBackgroundWidth]];
        } else {
            _favoriteView = [self roundButtonContianerViewWithButton:self.favoriteButton layerColor:layerColor];
        }
        _favoriteView.hidden = YES;
    }
    return _favoriteView;
}

- (ACCCollectionButton *)favoriteButton
{
    if (!_favoriteButton) {
        _favoriteButton = [ACCCollectionButton buttonWithType:UIButtonTypeCustom];
        _favoriteButton.contentMode = UIViewContentModeCenter;
        [_favoriteButton setImage:ACCResourceImage(@"iconStickerCollectionBefore") forState:UIControlStateNormal];
        [_favoriteButton setImage:ACCResourceImage(@"iconStickerCollectionAfter") forState:UIControlStateSelected];
        _favoriteButton.imageEdgeInsets = UIEdgeInsetsMake(-1, -1, 1, 1);
        [_favoriteButton addTarget:self action:@selector(p_onFavoriteBtnClicked:) forControlEvents:UIControlEventTouchUpInside];

        if ([self enableNewFavoritesTitle]) {
            _favoriteButton.displayMode = ACCCollectionButtonDisplayModeTitleAndImage;
            [_favoriteButton setImage:ACCResourceImage(@"iconStickerCollectionBeforeNew") forState:UIControlStateNormal];
            [_favoriteButton setImage:ACCResourceImage(@"iconStickerCollectionAfterNew") forState:UIControlStateSelected];
            _favoriteButton.titleLabel.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightSemibold];
            [_favoriteButton setTitle:ACCLocalizedString(@"profile_favourite", @"收藏") forState:UIControlStateNormal];
            [_favoriteButton setTitleColor:ACCResourceColor(ACCColorConstTextInverse) forState:UIControlStateNormal];
            [_favoriteButton setTitle:ACCLocalizedString(@"added_to_favorite", @"已收藏") forState:UIControlStateSelected];
            [_favoriteButton setTitleColor:ACCResourceColor(ACCColorConstTextInverse) forState:UIControlStateSelected];
            _favoriteButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            _favoriteButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            _favoriteButton.imageEdgeInsets = UIEdgeInsetsMake(-1, 17, 1, 0);
            _favoriteButton.titleEdgeInsets = UIEdgeInsetsMake(-1, 17, 1, 0);
        }
    }
    return _favoriteButton;
}

- (ACCStickerShowcaseEntranceView *)stickerShowcaseEntranceView
{
    if (!_stickerShowcaseEntranceView) {
        _stickerShowcaseEntranceView = [IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) createStickerShowcaseEntranceView];
        _stickerShowcaseEntranceView.hidden = YES;
    }
    return _stickerShowcaseEntranceView;
}

- (AWEOriginStickerUserView *)originStickerUserView
{
    if (!_originStickerUserView) {
        _originStickerUserView = [[AWEOriginStickerUserView alloc] init];
        _originStickerUserView.hidden = YES;
    }
    return _originStickerUserView;
}

- (UIView<AWEEffectHintViewProtocol> *)hotEffectHintView
{
    if (!_hotEffectHintView) {
        _hotEffectHintView = [[AWEDouPlusEffectHintView alloc] initWithFrame:CGRectZero];
        _hotEffectHintView.hidden = YES;
    }
    return _hotEffectHintView;
}

- (AWEStickerCommerceEnterView *)commerceEnterView
{
    if (!_commerceEnterView) {
        _commerceEnterView = [[AWEStickerCommerceEnterView alloc] init];
        _commerceEnterView.backgroundColor = ACCResourceColor(ACCUIColorConstBGInverse2);
        _commerceEnterView.layer.cornerRadius = 2.0f;
        _commerceEnterView.hidden = YES;
    }
    return _commerceEnterView;
}

- (UIView *)loadingView
{
    if (!_loadingView) {
        _loadingView = [[UIView alloc] init];
        _loadingView.backgroundColor = [UIColor clearColor];

        UILabel *textLabel = [[UILabel alloc] init];
        textLabel.text =  ACCLocalizedString(@"effect_loading_new",@"道具加载中");
        textLabel.font = [ACCFont() systemFontOfSize:15];
        textLabel.textColor = ACCResourceColor(ACCUIColorConstTextTertiary3);

        [_loadingView addSubview:textLabel];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wimplicit-retain-self"
        ACCMasMaker(textLabel, {
            make.centerX.equalTo(_loadingView);
            make.centerY.equalTo(_loadingView);
        });
#pragma clang diagnostic pop

        UIImageView *loadingImageView = [[UIImageView alloc] initWithImage:[ACCResourceImage(@"icon30WhiteSmall") imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        loadingImageView.tintColor = ACCResourceColor(ACCUIColorConstTextInverse3);
        [_loadingView addSubview:loadingImageView];
        ACCMasMaker(loadingImageView, {
            make.width.height.equalTo(@15);
            make.centerY.equalTo(textLabel);
            make.right.equalTo(textLabel.mas_left).offset(-6);
        });
        [loadingImageView.layer acc_addRotateAnimation];
        _loadingView.hidden = YES;
    }
    return _loadingView;
}

- (UIView *)errorView
{
    if (!_errorView) {
        _errorView = [[UIView alloc] init];
        _errorView.backgroundColor = [UIColor clearColor];

        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.text = ACCLocalizedCurrentString(@"error_retry");
        titleLabel.numberOfLines = 0;
        titleLabel.preferredMaxLayoutWidth = UIScreen.mainScreen.bounds.size.width - 2 * 12.f;
        titleLabel.font = [ACCFont() systemFontOfSize:15];
        titleLabel.textColor = ACCResourceColor(ACCUIColorBGContainer7);
        titleLabel.textAlignment = NSTextAlignmentCenter;

        [_errorView addSubview:titleLabel];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wimplicit-retain-self"
        ACCMasMaker(titleLabel, {
            make.centerX.equalTo(_errorView);
            make.centerY.equalTo(_errorView);
        });
#pragma clang diagnostic pop
        _errorView.hidden = YES;
        UITapGestureRecognizer *ges = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_refreshDataManager)];
        [_errorView addGestureRecognizer:ges];
    }
    return _errorView;
}

- (AWEModernStickerSwitchTabView *)switchTabView {
    if (!_switchTabView) {
        _switchTabView = [[AWEModernStickerSwitchTabView alloc] initWithStickerCategories:self.dataManager.stickerCategories];
        _switchTabView.trackingInfoDictionary = self.trackingInfoDictionary;
        _switchTabView.schemaTrackParams = self.schemaTrackParams;
        _switchTabView.panelType = self.dataManager.panelType;
    }
    return _switchTabView;
}

- (UIButton *)cameraButton {
    if (!_cameraButton) {
        _cameraButton = [[UIButton alloc] init];
        _cameraButton.exclusiveTouch = YES;
        _cameraButton.adjustsImageWhenHighlighted = NO;
        [_cameraButton setImage:[self swapCameraButtonImage] forState:UIControlStateNormal];
        [_cameraButton addTarget:self
                          action:@selector(cameraButtonPressed:)
                forControlEvents:UIControlEventTouchUpInside];
        _cameraButton.accessibilityLabel = ACCLocalizedCurrentString(@"reverse");
    }
    return _cameraButton;
}

- (UIImage *)swapCameraButtonImage
{
    return ACCResourceImage(@"ic_camera_filp");
}

- (AWECameraContainerToolButtonWrapView *)cameraButtonWrapView {
    if (!_cameraButtonWrapView) {
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.font = [ACCFont() acc_boldSystemFontOfSize:10];
        label.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
        label.textAlignment = NSTextAlignmentCenter;
        label.text = ACCLocalizedCurrentString(@"reverse");
        label.numberOfLines = 2;
        [label acc_addShadowWithShadowColor:ACCResourceColor(ACCUIColorConstLinePrimary) shadowOffset:CGSizeMake(0, 1) shadowRadius:2];
        label.isAccessibilityElement = NO;
        _cameraButtonWrapView = [[AWECameraContainerToolButtonWrapView alloc] initWithButton:self.cameraButton label:label itemID:ACCRecorderToolBarSwapContext];
        _cameraButtonWrapView.hidden = YES;
    }
    return _cameraButtonWrapView;
}

- (UIButton *)storyCameraButton
{
    if (!_storyCameraButton) {
        _storyCameraButton = [[UIButton alloc] init];
        _storyCameraButton.exclusiveTouch = YES;
        _storyCameraButton.adjustsImageWhenHighlighted = NO;
        UIImage *image = [self swapCameraButtonImage];
        [_storyCameraButton setImage:image forState:UIControlStateNormal];
        [_storyCameraButton addTarget:self
                          action:@selector(storyCameraButtonPressed:)
                forControlEvents:UIControlEventTouchUpInside];
        _storyCameraButton.hidden = YES;
    }
    return _storyCameraButton;
}

- (NSInteger)selectedTabIndex
{
    return self.switchTabView.selectedIndex;
}

- (NSString *)currentPropSelectedFrom
{
    NSString *selectedCategoryName = self.switchTabView.selectedCategoryName;
    if (!ACC_isEmptyString(selectedCategoryName)) {
        return [NSString stringWithFormat:@"prop_panel_%@", self.switchTabView.selectedCategoryName];
    }
    return @"";
}

- (NSString *)localPropId
{
    NSString *localPropId = @"";
    if ([self.actionDelegate respondsToSelector:@selector(providedPublishModel)]) {
        localPropId = [self.actionDelegate providedPublishModel].repoProp.localPropId;
    }
    return !ACC_isEmptyString(localPropId) ? localPropId : @"";
}

- (NSString *)musicId
{
    NSString *musicId = @"";
    if ([self.actionDelegate respondsToSelector:@selector(providedPublishModel)]) {
        musicId = [self.actionDelegate providedPublishModel].repoMusic.music.musicID;
    }
    return !ACC_isEmptyString(musicId) ? musicId : @"";
}

- (NSIndexPath * _Nullable)selectedPropIndexPath
{
    return self.selectedEffectIndexPath;
}

#pragma mark - setter

- (void)setIsPhotoMode:(BOOL)isPhotoMode
{
    _isPhotoMode = isPhotoMode;
    self.switchTabView.isPhotoMode = isPhotoMode;
}

- (void)setIsStoryMode:(BOOL)isStoryMode
{
    _isStoryMode = isStoryMode;
    self.switchTabView.isStoryMode = isStoryMode;
}

#pragma mark - Show

- (void)showOnViewController:(UIViewController *)controller
{
    [self prepareForShow];
    [self p_showOnViewController:controller animated:YES duration:0.25];
}

- (void)prepareForShow
{
    [self.hasShowedStickerSet removeAllObjects];
    BOOL selectedEffectDownloaded = self.dataManager.selectedEffect.downloaded;
    // Treat collection sticker as downloaded sticker.
    if (self.dataManager.selectedEffect && self.dataManager.selectedEffect.childrenEffects.count > 0) {
        selectedEffectDownloaded = YES;
    }
    BOOL needRefresh = NO;
    if (self.dataManager.selectedEffect && selectedEffectDownloaded) {
        self.selectedEffectModel = self.dataManager.selectedEffect;
        self.lastClickedEffectModel = self.selectedEffectModel;
        [self p_updateFavoriteButtonWithSticker:self.selectedEffectModel manually:NO];
        self.dataManager.selectedEffect = nil;
        needRefresh = YES;
    }
    if (self.dataManager.selectedChildEffect && self.dataManager.selectedChildEffect.downloaded) {
        // 清掉childEffect
        self.selectedChildEffectModel = self.dataManager.selectedChildEffect;
        self.lastClickedEffectModel = self.selectedChildEffectModel;
        self.dataManager.selectedChildEffect = nil;
        needRefresh = YES;
    }
    if (needRefresh) {
        [self refreshStickerViews];
    }

    // 只有以前没有弹起过面板的时候，才可能会上报Tab打点
    if (self.switchTabView.hasSelectItem && !self.hasShownBefore) {
        [self.switchTabView trackSelectedStatusWithIndexPath:self.switchTabView.selectedIndex];
    }

    if (self.hasShownBefore) {
        /*如果道具面板曾经展现过，则此次展现会使用上次展现的结果，不打点。
        同时，因为打点结束以单个特效Cell的出现为计时截止时间，如果此处不取消，当此次展现过程中用户滑动了列表会出现预期外的打点*/
        [ACCMonitor() cancelTimingForKey:@"sticker_panel_loading_duration"];
    }
}

- (void)performDidShowAction
{
    // 让新增加的Camera按钮显示
    self.cameraButtonWrapView.hidden = self.isKaraokeAudioMode;
    self.storyCameraButton.hidden = NO;
    self.cameraButton.selected = [self defaultPosition] == AVCaptureDevicePositionFront;
    [self.actionDelegate modernStickerViewControllerDidShow];
    [self updateOriginStickerUserViewAndCommerceEnterViewWithEffect:self.selectedChildEffectModel ?: self.selectedEffectModel];
    [self p_updateHotEffectHintWithEffect:self.selectedEffectModel];
    if (self.hasShownBefore) {
        [self p_trackVisibleStickersShowAtSection:self.selectedTabIndex];
    }
    self.hasShownBefore = YES;
}

- (void)p_showOnViewController:(UIViewController *)controller animated:(BOOL)animated duration:(NSTimeInterval)duration {

    if (!controller) {
        return;
    }

    [controller addChildViewController:self];
    [self p_showOnView:controller.view
            fromOffset:CGPointMake(0,controller.view.bounds.size.height)
              animated:animated
              duration:duration];
    [self didMoveToParentViewController:controller];
}

- (void)p_dismissWithTrackKey:(NSString *)trackKey {
    self.dismissTrackStr = trackKey;
    if (self.externalDismissBlock) {
        ACCBLOCK_INVOKE(self.dismissBlock, self.selectedEffectModel);
        [self p_prepareForDismiss];
        self.externalDismissBlock();
    } else {
        ACCBLOCK_INVOKE(self.dismissBlock, self.selectedEffectModel);
        [self p_dismissWithAnimated:YES duration:0.25];
    }
}

- (void)p_dismissWithAnimated:(BOOL)animated duration:(NSTimeInterval)duration {
    if (!self.view.superview) {
        return;
    }
    [self p_prepareForDismiss];
    @weakify(self);
    dispatch_block_t removeFromParentBlock = ^{
        @strongify(self);
        [self willMoveToParentViewController:nil];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    };
    if (animated) {
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            [self p_moveToOffset:CGPointMake(0, [UIScreen mainScreen].bounds.size.height)];
        } completion:^(BOOL finished) {
            ACCBLOCK_INVOKE(removeFromParentBlock);
        }];
    } else {
        [self p_moveToOffset:CGPointMake(0, [UIScreen mainScreen].bounds.size.height)];
        ACCBLOCK_INVOKE(removeFromParentBlock);
    }
}

- (void)p_prepareForDismiss
{
    self.cameraButtonWrapView.hidden = YES;
    self.storyCameraButton.hidden = YES;
    self.originStickerUserView.hidden = YES;
    self.hotEffectHintView.hidden = YES;
    [self updateOriginStickerUserViewAndCommerceEnterViewWithEffect:nil];
    [self trackStickerPanelLoadPerformanceWithStatus:2];
    if (self.waitingEffect) { //前一个道具还未成功处理，记为取消
        [self userCancelUseEffect:self.waitingEffect];
        self.waitingEffect = nil;
    }
}

- (void)p_showOnView:(UIView *)superview fromOffset:(CGPoint)offset animated:(BOOL)animated duration:(NSTimeInterval)duration {
    if (!superview) {
        return;
    }

    if (self.view.superview) {
        [self.view removeFromSuperview];
    }

    [superview addSubview:self.view];
    [superview bringSubviewToFront:self.view];

    // hasShownBefore会在动画完成前变化，先记录一下
    BOOL hasShownBefore = self.hasShownBefore;
    if (animated) {
        [self p_moveToOffset:offset];
        [UIView animateWithDuration:0.49 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self p_moveToOffset:CGPointZero];
        } completion:^(BOOL finished) {
            if (finished) {
                // 让新增加的Camera按钮显示
                self.cameraButtonWrapView.hidden = self.isKaraokeAudioMode;
                self.storyCameraButton.hidden = NO;
                self.cameraButton.selected = [self defaultPosition] == AVCaptureDevicePositionFront;
                [self.actionDelegate modernStickerViewControllerDidShow];
                [self updateOriginStickerUserViewAndCommerceEnterViewWithEffect:self.selectedEffectModel];
                [self p_updateHotEffectHintWithEffect:self.selectedEffectModel];
                if (hasShownBefore) {
                    [self p_trackVisibleStickersShowAtSection:self.selectedTabIndex];
                }
            }
        }];
    } else {
        [self p_moveToOffset:CGPointZero];
        if (hasShownBefore) [self p_trackVisibleStickersShowAtSection:self.selectedTabIndex];
    }
}

- (void)p_moveToOffset:(CGPoint)offset {
    self.view.frame = CGRectMake(offset.x, offset.y, self.view.frame.size.width, self.view.frame.size.height);
}

#pragma mark - Utils

- (BOOL)enablePagingStickers
{
    // 开启新版effect道具UI之后不能再使用分页的功能
    return (self.dataManager.panelType == AWEStickerPanelTypeRecord || self.dataManager.panelType == AWEStickerPanelTypeStory);
}

#pragma New Effect Tab UI

/**
 *  dataMgr请求过道具数据后更新特效道具数量和分割cell的index
 */
- (void)updateEffectsCountAndSeparatorsIndexs {
    NSUInteger count = 0;
    NSMutableArray<NSNumber *> *indexs = @[].mutableCopy;
    NSMutableArray<IESEffectModel *> *models = @[].mutableCopy;
    for (int i = 0;i<self.dataManager.responseModelNew.categories.count;i++) {
        count += self.dataManager.responseModelNew.categories[i].effects.count;
        [models addObjectsFromArray:self.dataManager.responseModelNew.categories[i].effects];
        if (i != self.dataManager.responseModelNew.categories.count - 1) {
            [indexs addObject:[NSNumber numberWithUnsignedInteger:count-1]];
        }
    }
    self.separatorsIndexs = indexs;
    self.totalEffectModels = models;
}

/**
 *  ---|------|----|----
 */
- (void)updateCategorySeparatorOffsetXsArray {
    NSMutableArray<NSNumber *> *offsetXsArray = @[].mutableCopy;
    [self.separatorsIndexs enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSUInteger stickerCellCnt = obj.unsignedIntegerValue;
        CGFloat x = (stickerCellCnt - 2) * (56.f + 12.f) + (idx + 1) * 12.f;
        [offsetXsArray addObject:[NSNumber numberWithFloat:x]];
    }];
    self.categorySeparatorOffsetXsArray = offsetXsArray;
}

- (AWEEffectPlatformTrackModel *)commonStickerDownloadTrackModel {
    AWEEffectPlatformTrackModel *trackModel = [AWEEffectPlatformTrackModel modernStickerTrackModel];
    trackModel.successStatus = @([self statusCodeForStickerDownload:YES]);
    trackModel.failStatus = @([self statusCodeForStickerDownload:NO]);
    trackModel.startTime = @(CFAbsoluteTimeGetCurrent());
    return trackModel;
}

- (NSInteger)statusCodeForStickerDownload:(BOOL)success
{
    switch (self.dataManager.panelType) {
        case AWEStickerPanelTypeRecord:
            return success ? 0 : 1;
        case AWEStickerPanelTypeLive:
            return success ? 20 : 21;
        case AWEStickerPanelTypeZoom:
            return success ? 30 : 31;
        case AWEStickerPanelTypeStory:
            return success ? 40 : 41;
        case AWEStickerPanelTypeCreatorPreview:
            return success ? 50 : 51;
    }
}

- (void)trackStickerPanelLoadPerformanceWithStatus:(NSInteger)status
{
    //性能打点，道具面板加载耗时
    NSInteger panel_loading_duration = [ACCMonitor() timeIntervalForKey:@"sticker_panel_loading_duration"];

    if (panel_loading_duration <= 0) {
        return;
    }

    if (status == 0 && !self.loadingView.hidden) {
        return;
    }

    [ACCMonitor() cancelTimingForKey:@"sticker_panel_loading_duration"];

    NSMutableDictionary *params = @{@"duration":@(panel_loading_duration),
                                    @"status":@(status)}.mutableCopy;
    if ([self.actionDelegate respondsToSelector:@selector(providedPublishModel)]) {
        [params addEntriesFromDictionary:[self.actionDelegate providedPublishModel].repoTrack.commonTrackInfoDic?:@{}];
    }
    if (status == 2) {
        [params addEntriesFromDictionary:@{@"dismiss":self.dismissTrackStr?:@""}];
    }
    [ACCTracker() trackEvent:@"tool_performance_enter_prop_tab"
                       params:params.copy
              needStagingFlag:NO];
}

- (void)userCancelUseEffect:(IESEffectModel *)effect
{
    NSInteger duration = [ACCMonitor() timeIntervalForKey:@"sticker_loading_duration_user_view"];

    if (duration > 0) {
        [ACCMonitor() cancelTimingForKey:@"sticker_loading_duration_user_view"];

        NSMutableDictionary *params = @{@"resource_type":@"effect",
                                        @"resource_id":effect.effectIdentifier?:@"",
                                        @"duration":@(duration),
                                        @"status":@(2),
                                        @"hit_cache":@(0)}.mutableCopy;
        if ([self.actionDelegate respondsToSelector:@selector(providedPublishModel)]) {
            [params addEntriesFromDictionary:[self.actionDelegate providedPublishModel].repoTrack.commonTrackInfoDic?:@{}];
        }
        [ACCTracker() trackEvent:@"tool_performance_resource_download_user_view"
                           params:params.copy
                  needStagingFlag:NO];
    }
}

- (void)userDidTapEffect:(IESEffectModel *)effect
{
    if ([self.waitingEffect.effectIdentifier isEqual:effect.effectIdentifier]) {
        return;
    }

    if (self.waitingEffect) { //前一个道具还未成功处理，记为取消
        [self userCancelUseEffect:self.waitingEffect];
    }

    if (effect.downloaded) {
        NSMutableDictionary *params = @{@"resource_type":@"effect",
                                        @"resource_id":effect.effectIdentifier?:@"",
                                        @"duration":@(0),
                                        @"status":@(0),
                                        @"hit_cache":@(1)}.mutableCopy;
        if ([self.actionDelegate respondsToSelector:@selector(providedPublishModel)]) {
            [params addEntriesFromDictionary:[self.actionDelegate providedPublishModel].repoTrack.commonTrackInfoDic?:@{}];
        }
        [ACCTracker() trackEvent:@"tool_performance_resource_download_user_view"
                 params:params.copy
        needStagingFlag:NO];
    } else {
        self.waitingEffect = effect;
        [ACCMonitor() startTimingForKey:@"sticker_loading_duration_user_view"];
    }
}

- (void)engineWillApplyEffect:(IESEffectModel *)effect
{
    if (!self.waitingEffect) {
        return;
    }
    self.waitingEffect = nil;

    NSInteger duration = [ACCMonitor() timeIntervalForKey:@"sticker_loading_duration_user_view"];

    if (duration > 0) {
        [ACCMonitor() cancelTimingForKey:@"sticker_loading_duration_user_view"];

        NSMutableDictionary *params = @{@"resource_type":@"effect",
                                        @"resource_id":effect.effectIdentifier?:@"",
                                        @"duration":@(duration),
                                        @"status":@(0),
                                        @"hit_cache":@(0)}.mutableCopy;
        if ([self.actionDelegate respondsToSelector:@selector(providedPublishModel)]) {
            [params addEntriesFromDictionary:[self.actionDelegate providedPublishModel].repoTrack.commonTrackInfoDic?:@{}];
        }
        [ACCTracker() trackEvent:@"tool_performance_resource_download_user_view"
                           params:params
                  needStagingFlag:NO];
    }
}

- (void)didFailedDownloadEffect:(IESEffectModel *)effect withError:(NSError *)error
{
    if (!self.waitingEffect) {
        return;
    }
    self.waitingEffect = nil;

    NSInteger duration = [ACCMonitor() timeIntervalForKey:@"sticker_loading_duration_user_view"];

    if (duration > 0) {
        [ACCMonitor() cancelTimingForKey:@"sticker_loading_duration_user_view"];

        NSMutableDictionary *params = @{@"resource_type":@"effect",
                                        @"resource_id":effect.effectIdentifier?:@"",
                                        @"duration":@(duration),
                                        @"status":@(1),
                                        @"hit_cache":@(0),
                                        @"error_domain":error.domain?:@"",
                                        @"error_code":@(error.code)}.mutableCopy;

        if ([self.actionDelegate respondsToSelector:@selector(providedPublishModel)]) {
            [params addEntriesFromDictionary:[self.actionDelegate providedPublishModel].repoTrack.commonTrackInfoDic?:@{}];
        }
        [ACCTracker() trackEvent:@"tool_performance_resource_download_user_view"
                           params:params.copy
                  needStagingFlag:NO];
    }
}

- (void)trackDownloadPerformanceWithEffect:(IESEffectModel *)effect startTime:(CFTimeInterval)startTime success:(BOOL)success error:(NSError *)error
{
    AWEVideoPublishViewModel *publishModel = nil;
    if ([self.actionDelegate respondsToSelector:@selector(providedPublishModel)]) {
           publishModel = [self.actionDelegate providedPublishModel];
    }

    NSInteger duration = (CACurrentMediaTime() - startTime) * 1000;
    NSMutableDictionary *params = @{@"resource_type":@"effect",
                                    @"resource_id":effect.effectIdentifier?:@"",
                                    @"duration":@(duration),
                                    @"status":@(success?0:1),
                                    @"error_domain":error.domain?:@"",
                                    @"error_code":@(error.code),
                                    @"shoot_way":publishModel.repoTrack.referString?:@""}.mutableCopy;
    if (publishModel) {
        [params addEntriesFromDictionary:publishModel.repoTrack.commonTrackInfoDic?:@{}];
    }
    [ACCTracker() trackEvent:@"tool_performance_resource_download"
                       params:params.copy
                     needStagingFlag:NO];
}

- (CAShapeLayer *)topRoundCornerShapeLayerWithFrame:(CGRect)frame
{
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    CGFloat maskRadius = 8;
    shapeLayer.path = [UIBezierPath bezierPathWithRoundedRect:frame
                                            byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                                                  cornerRadii:CGSizeMake(maskRadius, maskRadius)].CGPath;
    return shapeLayer;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    AWEModernStickerCollectionViewTag tag = collectionView.tag / 1000;
    if (tag != AWEModernStickerCollectionViewTagSticker) {
        return CGSizeZero;
    }
    __block BOOL matched = NO;
    [self.separatorsIndexs enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.unsignedIntegerValue == section) {
            matched = YES;
            *stop = YES;
        }
    }];
    if (matched) {
        return CGSizeMake(12.5, 56);
    } else {
        return CGSizeZero;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeZero;
}

- (nullable AWEModernStickerCollectionViewCell *)cellForEffect:(NSString *)effectID
{
    for (AWEModernStickerContentCollectionViewCell *cell in self.stickerContentCollectionView.visibleCells) {
        if ([cell isKindOfClass:[AWEModernStickerContentCollectionViewCell class]]) {
            AWEModernStickerCollectionViewCell *innerCell = (AWEModernStickerCollectionViewCell *)[cell.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            if ([innerCell isKindOfClass:[AWEModernStickerCollectionViewCell class]]) {
                if ([innerCell.effect.effectIdentifier isEqualToString:effectID]) {
                    return innerCell;
                }
            }
        }
    }
    return nil;
}

@end
