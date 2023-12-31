//
//  CAKAlbumPreviewAndSelectController.m
//  CameraClient
//
//  Created by lixingdong on 2020/7/17.
//

#import <KVOController/KVOController.h>
#import <ReactiveObjC/ReactiveObjC.h>
#import <Masonry/Masonry.h>
#import <CreativeKit/ACCAccessibilityProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIFont+ACCAdditions.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/ACCResponder.h>

#import "CAKAlbumPreviewAndSelectController.h"
#import "CAKAlbumPhotoPreviewAndSelectCell.h"
#import "CAKAlbumVideoPreviewAndSelectCell.h"
#import "CAKSelectedAssetsViewProtocol.h"
#import "CAKAlbumSelectedAssetsView.h"
#import "CAKAlbumPreviewPageBottomView.h"
#import "CAKAlbumZoomTransition.h"
#import "CAKGradientView.h"
#import "CAKLoadingProtocol.h"
#import "CAKToastProtocol.h"
#import "CAKLanguageManager.h"
#import "UIImage+AlbumKit.h"
#import "UIImage+CAKUIKit.h"
#import "UIColor+AlbumKit.h"


static CGFloat kAlbumSelectedAssetsBottomViewHeight() { return 52.0f + ACC_IPHONE_X_BOTTOM_OFFSET;}

@interface CAKAlbumPreviewAndSelectController () <UICollectionViewDelegate, UICollectionViewDataSource, CAKAlbumZoomTransitionInnerContextProvider>

@property (nonatomic, strong) NSValue *videoSize;
@property (nonatomic, strong) AVPlayer *avPlayer;
@property (nonatomic, strong) AVPlayerLayer *avPlayerLayer;

@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, assign, readwrite) NSInteger currentIndex;
@property (nonatomic, strong, readwrite) CAKAlbumAssetModel *currentAssetModel;
@property (nonatomic, strong, readwrite) CAKAlbumAssetModel *exitAssetModel;

@property (nonatomic, assign) BOOL isDragging;
@property (nonatomic, assign) BOOL showLeftToast;
@property (nonatomic, assign) BOOL showRightToast;
@property (nonatomic, assign) BOOL fromBottomView;
@property (nonatomic, assign) BOOL isShowingPurePreview;

@property (nonatomic, assign) AWEGetResourceType resourceType;

@property (nonatomic, strong) UIView<CAKTextLoadingViewProtocol> *loadingView;

@property (nonatomic, strong) UIView *selectPhotoView;
@property (nonatomic, strong) UIVisualEffectView *topMaskView;
@property (nonatomic, strong) UIVisualEffectView *bottomMaskView;
@property (nonatomic, strong) CAKGradientView *topMaskGradientView;
@property (nonatomic, strong) UIImageView *unCheckImageView;
@property (nonatomic, strong) UILabel *numberLabel;
@property (nonatomic, strong) UIImageView *numberBackGroundImageView;
@property (nonatomic, strong) UILabel *selectHintLabel;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UIView<CAKSelectedAssetsViewProtocol> *selectedAssetsView;
@property (nonatomic, strong) UIVisualEffectView *selectedAssetsViewMaskView;
@property (nonatomic, strong) UIView *seperatorLineView;
@property (nonatomic, assign) CGFloat currentScale;
@property (nonatomic, strong) UILabel *repeatSelectHintLabel;
@property (nonatomic, strong) CAKAlbumPreviewPageBottomView *bottomView;
@property (nonatomic, strong) UIView<CAKAlbumPreviewPageBottomViewProtocol> *customBottomView;

@property (nonatomic, assign) BOOL selectPhotoUserInteractive;

//monitor
@property (nonatomic, assign) BOOL couldTrack;
@property (nonatomic, assign) BOOL errorOccur;

@property (nonatomic, weak) CAKAlbumViewModel *viewModel;

@property (nonatomic, strong) CAKAlbumAssetDataModel *assetDataModel;

@end

@implementation CAKAlbumPreviewAndSelectController

- (instancetype)initWithViewModel:(CAKAlbumViewModel *)viewModel anchorAssetModel:(CAKAlbumAssetModel *)anchorAssetModel
{
    self = [super init];
    if (self) {
        [self setupWithViewModel:viewModel anchorAssetModel:anchorAssetModel fromBottomView:NO];
    }
    
    return self;
}

- (instancetype)initWithViewModel:(CAKAlbumViewModel *)viewModel anchorAssetModel:(CAKAlbumAssetModel *)anchorAssetModel fromBottomView:(BOOL)fromBottomView
{
    self = [super init];
    if (self) {
        self.fromBottomView = fromBottomView;
        [self setupWithViewModel:viewModel anchorAssetModel:anchorAssetModel fromBottomView:fromBottomView];
    }
    
    return self;
}

- (void)setupWithViewModel:(CAKAlbumViewModel *)viewModel anchorAssetModel:(CAKAlbumAssetModel *)anchorAssetModel fromBottomView:(BOOL)fromBottomView
{
    self.assetsSelectedIconStyle = viewModel.listViewConfig.assetsSelectedIconStyle;
    if (fromBottomView) {
        self.originDataSource = [viewModel.currentSelectAssetModels mutableCopy];
    }

    self.selectedAssetModelArray = viewModel.currentSelectAssetModels;
    self.currentAssetModel = anchorAssetModel;
    if (viewModel.listViewConfig.enableAssetsRepeatedSelect && self.fromBottomView) {
        self.currentIndex = anchorAssetModel.cellIndexPath.item;
    } else if (!self.fromBottomView) {
        self.assetDataModel = [viewModel currentAssetDataModel];
        [self.assetDataModel configDataWithPreviewFilterBlock:^BOOL(PHAsset *asset) {
            return YES;
        }];
        self.currentIndex = [self.assetDataModel previewIndexOfObject:self.currentAssetModel];
        if (self.currentIndex == NSNotFound) {
            self.currentIndex = 0;
        }
        if ([self.assetDataModel removePreviewInvalidAssetForPostion:self.currentIndex]) {
            self.currentIndex = [self.assetDataModel previewIndexOfObject:self.currentAssetModel];
        }
    } else {
        self.currentIndex = [self.originDataSource indexOfObject:self.currentAssetModel];
    }
    if (self.currentIndex == NSNotFound) {
        self.currentIndex = 0;
    }
    self.viewModel = viewModel;
    self.resourceType = viewModel.currentResourceType;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.collectionView];
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(back:)];
    if (self.viewModel.selectedAssetsViewConfig.enableSelectedAssetsViewForPreviewPage) {
        [self setupTopMaskView];
        [self setupBottomMaskView];
        [self setupSelectedAssetsViewMaskView];
        [self setupSelectedViewForPreviewPage];
        [self setupSeperatorLineView];
        [self setupNextButton];
        [self setupSelectPhotoView];
        tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didClickPreviewView)];
    } else if (self.viewModel.enableBottomViewForPreviewPage) {
        [self setupTopMaskView];
        [self setupCustomBottomView];
        tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didClickPreviewView)];
    } else {
        [self setupSelectPhotoView];
        [self setupTopMaskGradientView];
    }
    [self.collectionView addGestureRecognizer:tapGes];
    self.backButton = [[UIButton alloc] init];
    if ([ACCAccessibility() respondsToSelector:@selector(enableAccessibility:traits:label:)]) {
        [ACCAccessibility() enableAccessibility:self.backButton
                                         traits:UIAccessibilityTraitButton
                                          label:CAKLocalizedString(@"back_confirm", @"Return")];
    }
    [self.view addSubview:self.backButton];
    ACCMasMaker(self.backButton, {
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(15);
        } else {
            make.top.equalTo(self.view).offset(16);
        }
        make.left.equalTo(self.view).offset(16);
        make.width.equalTo(@(24));
        make.height.equalTo(@(24));
    });
    [self.backButton setImage:CAKResourceImage(@"ic_titlebar_back_white") forState:UIControlStateNormal];
    [self.backButton addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];

    [self p_previewCollectionViewScrollToCurrentModelIndex];
    self.videoSize = @(CGSizeMake(self.currentAssetModel.phAsset.pixelWidth, self.currentAssetModel.phAsset.pixelHeight));
   
    //send message to gallerybasevc
    [self willChangeValueForKey:@"currentAssetModel"];
    [self didChangeValueForKey:@"currentAssetModel"];
    
    [self updatePhotoSelected:self.currentAssetModel greyMode:self.greyMode];
    [self dealWithPhotoChange];
    if ([self.delegate respondsToSelector:@selector(previewControllerDidLoad:forAlbumAsset:bottomView:)]) {
        [self.delegate previewControllerDidLoad:self forAlbumAsset:self.currentAssetModel bottomView:self.bottomView];
    }
    
    [self bindViewModel];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    ACCBLOCK_INVOKE(self.willDismissBlock, self.currentAssetModel);
    
    [self.avPlayer pause];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self selectAssetCollectionViewScrollToCurrentModelIndex];
    if (self.currentAssetModel.mediaType == CAKAlbumAssetModelMediaTypeVideo) {
         [self setUpPlayer:self.currentAssetModel];
    }
    [self playAfterCheck];
}

- (void)bindViewModel
{
    @weakify(self);
    [self.KVOController observe:self.viewModel.albumDataModel keyPath:@"photoSelectAssetsModels" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        
        if (self.resourceType == AWEGetResourceTypeImage && self.resourceType == self.viewModel.currentResourceType) {
            switch (self.viewModel.listViewConfig.selectionLimitType) {
                case CAKAlbumSelectionLimitTypeTotal: {
                    [self reloadSelectedStateWithGrayMode:self.viewModel.hasSelectedMaxCount];
                    break;
                }
                case CAKAlbumSelectionLimitTypeSeparate: {
                    [self reloadSelectedStateWithGrayMode:self.viewModel.hasPhotoSelectedMaxCount withMediaType:CAKAlbumAssetModelMediaTypePhoto];
                    break;
                }
                default:
                    NSAssert(NO, @"You have unhandled case");
                    break;
            }
        }
        [self updateTitleForButton:self.bottomView.nextButton];
    }];

    [self.KVOController observe:self.viewModel.albumDataModel keyPath:@"videoSelectAssetsModels" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        if (self.resourceType == AWEGetResourceTypeVideo && self.resourceType == self.viewModel.currentResourceType) {
            switch (self.viewModel.listViewConfig.selectionLimitType) {
                case CAKAlbumSelectionLimitTypeTotal: {
                    [self reloadSelectedStateWithGrayMode:self.viewModel.hasSelectedMaxCount];
                    break;
                }
                case CAKAlbumSelectionLimitTypeSeparate: {
                    [self reloadSelectedStateWithGrayMode:self.viewModel.hasVideoSelectedMaxCount withMediaType:CAKAlbumAssetModelMediaTypeVideo];
                    break;
                }
                default:
                    NSAssert(NO, @"You have unhandled case");
                    break;
            }
        }
        [self updateTitleForButton:self.bottomView.nextButton];
    }];

    [self.KVOController observe:self.viewModel.albumDataModel keyPath:@"mixedSelectAssetsModels" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        if (self.resourceType == AWEGetResourceTypeImageAndVideo && self.resourceType == self.viewModel.currentResourceType) {
            switch (self.viewModel.listViewConfig.selectionLimitType) {
                case CAKAlbumSelectionLimitTypeTotal: {
                    [self reloadSelectedStateWithGrayMode:self.viewModel.hasSelectedMaxCount];
                    break;
                }
                case CAKAlbumSelectionLimitTypeSeparate: {
                    [self reloadSelectedStateWithGrayMode:self.viewModel.hasVideoSelectedMaxCount withMediaType:CAKAlbumAssetModelMediaTypePhoto];
                    [self reloadSelectedStateWithGrayMode:self.viewModel.hasPhotoSelectedMaxCount withMediaType:CAKAlbumAssetModelMediaTypeVideo];
                    break;
                }
                default:
                    NSAssert(NO, @"You have unhandled case");
                    break;
            }
        }
        if ([self p_enableSelectedAssetsView]) {
            self.isShowingPurePreview = !self.viewModel.hasSelectedAssets && [self p_shouldHideSelectedViewWhenNotSelect];
            self.selectedAssetsView.assetModelArray = self.viewModel.currentSelectAssetModels;
            [self.selectedAssetsView reloadSelectView];
            [self updateSelectedAssetsViewHidden];
            [self updateTopAndBottomViewHidden];
            [self updateSelectedCellStatus];
            [self selectAssetCollectionViewScrollToCurrentModelIndex];
        }
        if (self.viewModel.enableBottomViewForPreviewPage) {
            [self updateCustomBottomViewIfNeed];
        }
        [self updateTitleForButton:self.bottomView.nextButton];
    }];
}

- (void)setCurrentAssetModel:(CAKAlbumAssetModel *)currentAssetModel
{
    _currentAssetModel = currentAssetModel;
    if (self.viewModel.selectedAssetsViewConfig.enableSelectedAssetsViewForPreviewPage) {
        [self updateSelectedCellStatus];
        [self selectAssetCollectionViewScrollToCurrentModelIndex];
    }
}

- (void)setupTopMaskGradientView
{
    self.topMaskGradientView = [[CAKGradientView alloc] init];
    self.topMaskGradientView.gradientLayer.startPoint = CGPointMake(0, 0);
    self.topMaskGradientView.gradientLayer.endPoint = CGPointMake(0, 1);
    self.topMaskGradientView.gradientLayer.locations = @[@0, @1];
    self.topMaskGradientView.gradientLayer.colors = @[(__bridge id)CAKResourceColor(ACCUIColorSDSecondary).CGColor,(__bridge id)[UIColor clearColor].CGColor];
    [self.view insertSubview:self.topMaskGradientView belowSubview:self.selectPhotoView];
    ACCMasMaker(self.topMaskGradientView, {
        make.leading.top.trailing.mas_equalTo(self.view);
        make.height.mas_equalTo(@(120));
    });
}

- (void)setupTopMaskView
{
    self.topMaskView = [[UIVisualEffectView alloc] initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, 100)];
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    self.topMaskView.effect = blur;
    self.topMaskView.backgroundColor = [CAKResourceColor(ACCColorBGCreation2) colorWithAlphaComponent:0.85];
    self.topMaskView.alpha = 0;
    [self.view addSubview:self.topMaskView];
}

- (void)setupCustomBottomView
{
    self.topMaskView.alpha = 1;
    self.selectPhotoUserInteractive = YES;
    
    self.customBottomView = self.viewModel.customBottomViewForPreviewPage;
    self.bottomMaskView = self.customBottomView.effectView;
    self.selectHintLabel = self.customBottomView.selectHintLabel;
    self.bottomMaskView.alpha = 1;
    self.selectPhotoView = self.customBottomView.selectPhotoButton;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectPhotoButtonClick:)];
    [self.selectPhotoView addGestureRecognizer:tapGesture];
    self.nextButton = self.customBottomView.nextButton;
    [self.customBottomView.nextButton addTarget:self action:@selector(goToNextPage:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.customBottomView];
    ACCMasMaker(self.customBottomView, {
        make.left.mas_equalTo(self.view.mas_left);
        make.bottom.mas_equalTo(self.view.mas_bottom);
        make.width.mas_equalTo(self.view.mas_width);
        make.height.mas_equalTo(@(self.viewModel.previewBottomViewHeight));
    });
    
    [self updateCustomBottomViewIfNeed];
}

- (void)setupBottomMaskView
{
    self.bottomMaskView = [[UIVisualEffectView alloc] init];
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    self.bottomMaskView.effect = blur;
    self.bottomMaskView.backgroundColor = [CAKResourceColor(ACCColorBGCreation2) colorWithAlphaComponent:0.85];
    self.bottomMaskView.alpha = 0;
    [self.view addSubview:self.bottomMaskView];
    ACCMasMaker(self.bottomMaskView, {
        make.leading.bottom.trailing.mas_equalTo(self.view);
        make.height.mas_equalTo(@(kAlbumSelectedAssetsBottomViewHeight()));
    });
}

- (void)setupSelectedViewForPreviewPage
{
    self.selectedAssetsView = self.viewModel.customAssetsViewForPreviewPage;
    if (!self.selectedAssetsView) {
        self.selectedAssetsView = [[CAKAlbumSelectedAssetsView alloc] init];
        if ([self.selectedAssetsView respondsToSelector:@selector(enableDrageToMoveAssets:)]) {
            [self.selectedAssetsView enableDrageToMoveAssets:self.viewModel.selectedAssetsViewConfig.enableDragToMoveForSelectedAssetsView];
        }
    }
    
    if ([self.selectedAssetsView respondsToSelector:@selector(setShouldAdjustPreviewPage:)]) {
        self.selectedAssetsView.shouldAdjustPreviewPage = [self p_enableSelectedAssetsView];
    }
    
    if ([self.selectedAssetsView respondsToSelector:@selector(updateCheckMaterialRepeatSelect:)]) {
        [self.selectedAssetsView updateCheckMaterialRepeatSelect:self.viewModel.listViewConfig.enableAssetsRepeatedSelect];
    }
    if ([self.selectedAssetsView respondsToSelector:@selector(updateSelectViewFromBottomView:)]) {
        [self.selectedAssetsView updateSelectViewFromBottomView:self.fromBottomView];
    }

    if ([self.selectedAssetsView respondsToSelector:@selector(setSourceType:)]) {
        self.selectedAssetsView.sourceType = CAKAlbumEventSourceTypePreviewPage;
    }

    self.selectedAssetsView.backgroundColor = [UIColor clearColor];
    self.selectedAssetsView.assetModelArray = self.viewModel.currentSelectAssetModels;
    [self.selectedAssetsView reloadSelectView];
    if ([self.selectedAssetsView respondsToSelector:@selector(updateSelectViewOrderWithNilArray:)]) {
        [self.selectedAssetsView updateSelectViewOrderWithNilArray:self.viewModel.currentNilIndexArray];
    }
    
    if ([self shouldAdjustDockForRepeatSelect]) {
        //支持重复选素材，进入预览页更新dock栏当前选中框
        [self p_updateSelectViewHighlightIndex:self.currentIndex];
    }
    
    [self configDeleteAssetBlockForSelectedAssetView];
    [self configChangeOrderBlockForSelectedAssetView];
    [self configTouchAssetBlockForSelectedAssetView];

    [self.view addSubview:self.selectedAssetsView];
    ACCMasMaker(self.selectedAssetsView, {
        make.edges.equalTo(self.selectedAssetsViewMaskView);
    });
}

- (void)configDeleteAssetBlockForSelectedAssetView
{
    @weakify(self);
    self.selectedAssetsView.deleteAssetModelBlock = ^(CAKAlbumAssetModel * _Nonnull assetModel) {
        @strongify(self);
        [self.viewModel didUnselectedAsset:assetModel];
        [self updatePhotoSelected:self.currentAssetModel greyMode:self.greyMode];
        [self updateSelectedCellStatus];
        if ([self.delegate respondsToSelector:@selector(previewController:selectedAssetsViewdidDeleteAsset:)]) {
            [self.delegate previewController:self selectedAssetsViewdidDeleteAsset:assetModel];
        }
        
        //支持重复选素材，从dock栏删除素材同步预览数据源并更新当前选中框
        if ([self shouldAdjustDockForRepeatSelect]) {
            if (self.viewModel.currentSelectAssetModels.count > 0) {
                self.originDataSource = [self.viewModel.currentSelectAssetModels mutableCopy];
                [self.collectionView reloadData];
            } else {
            //全部删除，保留最后一张预览素材
                return;
            }
            
            if (assetModel.cellIndexPath.item < self.currentIndex) {
                //删除素材在当前选中素材之前
                self.currentIndex--;
            } else if (assetModel.cellIndexPath.item == self.currentIndex) {
                //删除素材是当前选中素材
                if (self.currentIndex >= self.originDataSource.count) {
                    self.currentIndex = self.originDataSource.count - 1; //删除素材是最后一个
                }
                if (self.currentIndex >= 0 && self.currentIndex < self.originDataSource.count) {
                    self.currentAssetModel = [self.originDataSource acc_objectAtIndex:self.currentIndex];
                }
            }
            [self p_updateSelectViewHighlightIndex:self.currentIndex];
            [self p_previewCollectionViewScrollToCurrentModelIndex];
            if (self.currentAssetModel.mediaType == CAKAlbumAssetModelMediaTypeVideo) {
                 [self setUpPlayer:self.currentAssetModel];
            }
        }
    };
}

- (void)configChangeOrderBlockForSelectedAssetView
{
    @weakify(self);
    if ([self.selectedAssetsView respondsToSelector:@selector(setChangeOrderBlock:)]) {
        self.selectedAssetsView.changeOrderBlock = ^(CAKAlbumAssetModel * _Nonnull assetModel) {
            @strongify(self);
            self.selectedAssetsView.assetModelArray = self.viewModel.currentSelectAssetModels;
            //支持重复选素材，从dock交换素材顺序同步预览数据源并更新当前选中框
            if ([self shouldAdjustDockForRepeatSelect] && !self.viewModel.listViewConfig.addAssetInOrder) {
                self.originDataSource = [self.viewModel.currentSelectAssetModels mutableCopy];
                self.currentIndex = [self p_currentSelectViewHighlightIndex];
                [self p_previewCollectionViewScrollToCurrentModelIndex];
                
            }
            [self.selectedAssetsView reloadSelectView];
            if ([self.selectedAssetsView.assetModelArray containsObject:self.currentAssetModel]) {
                self.currentAssetModel.selectedNum = @([self.selectedAssetsView.assetModelArray indexOfObject:self.currentAssetModel] + 1);
            } else {
                self.currentAssetModel.selectedNum = nil;
            }
            [self updatePhotoSelected:self.currentAssetModel greyMode:self.greyMode];
            [self updateSelectedCellStatus];
            if ([self.delegate respondsToSelector:@selector(previewController:selectedAssetsViewDidChangeOrderWithDraggingAsset:)]) {
                [self.delegate previewController:self selectedAssetsViewDidChangeOrderWithDraggingAsset:assetModel];
            }
        };
    }
}

- (void)configTouchAssetBlockForSelectedAssetView
{
    @weakify(self);
    if ([self.selectedAssetsView respondsToSelector:@selector(setTouchAssetModelBlock:)]) {
        self.selectedAssetsView.touchAssetModelBlock = ^(CAKAlbumAssetModel * _Nonnull assetModel) {
            @strongify(self);
            // 如果点击的 model 不在 dataSource 中
            if (![self containsAssetModel:assetModel]) {
                [CAKToastShow() showError:[self getToastTextWithAssetModel:assetModel]];
                return;
            }
            [self.avPlayer pause];
            if ([self shouldAdjustDockForRepeatSelect]) {
                self.currentIndex = assetModel.cellIndexPath.item;
                [self p_updateSelectViewHighlightIndex:self.currentIndex];
                [self p_scrollSelectCollectionViewToCurrentForRepeatSelect];
            } else if (!self.fromBottomView) {
                self.currentIndex = [self.assetDataModel previewIndexOfObject:assetModel];
            } else {
                self.currentIndex = [self.originDataSource indexOfObject:assetModel];
            }
            [self p_previewCollectionViewScrollToCurrentModelIndex];
            [self.collectionView layoutIfNeeded];
            self.currentAssetModel = assetModel;
            if (self.currentAssetModel.mediaType == CAKAlbumAssetModelMediaTypeVideo) {
                 [self setUpPlayer:self.currentAssetModel];
            }
            if ([self.delegate respondsToSelector:@selector(previewController:selectedAssetsViewDidClickAsset:)]) {
                [self.delegate previewController:self selectedAssetsViewDidClickAsset:assetModel];
            }
        };
    }
}

- (void)setupSelectedAssetsViewMaskView
{
    self.selectedAssetsViewMaskView = [[UIVisualEffectView alloc] init];
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    self.selectedAssetsViewMaskView.effect = blur;
    self.selectedAssetsViewMaskView.backgroundColor = [CAKResourceColor(ACCColorBGCreation2) colorWithAlphaComponent:0.85];
    self.selectedAssetsViewMaskView.alpha = 0;
    [self.view addSubview:self.selectedAssetsViewMaskView];
    ACCMasMaker(self.selectedAssetsViewMaskView, {
        make.bottom.equalTo(self.bottomMaskView.mas_top);
        make.leading.trailing.mas_equalTo(self.view);
        make.height.mas_equalTo(@(self.viewModel.selectedAssetsViewHeight));
    });
}

- (void)updateSelectedAssetsViewHidden
{
    CGFloat viewAlpha = (self.viewModel.hasSelectedAssets || ![self p_shouldHideSelectedViewWhenNotSelect]) ? 1 : 0;
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.selectedAssetsView.alpha = viewAlpha;
        self.selectedAssetsViewMaskView.alpha = viewAlpha;
    } completion:nil];
}

- (void)updateTopAndBottomViewHidden
{
    CGFloat viewAlpha = (self.viewModel.hasSelectedAssets || ![self p_shouldHideSelectedViewWhenNotSelect]) ? 1 : 0;
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.topMaskView.alpha = viewAlpha;
        self.bottomMaskView.alpha = viewAlpha;
        self.seperatorLineView.alpha = viewAlpha;
    } completion:nil];
}

- (void)setupSeperatorLineView
{
    self.seperatorLineView = [[UIView alloc] init];
    self.seperatorLineView.backgroundColor = CAKResourceColor(ACCColorConstLineInverse2);
    self.seperatorLineView.alpha = 0;
    [self.bottomMaskView.contentView addSubview:self.seperatorLineView];

    ACCMasMaker(self.seperatorLineView, {
        make.leading.trailing.top.equalTo(@(0));
        make.height.equalTo(@(0.5f));
    });
}

- (void)didClickPreviewView
{
    if (self.isShowingPurePreview) {
        [self showWidgets];
    } else {
        [self hideWidgetsWithIsZooming:NO];
    }
}

- (void)showWidgets
{
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.nextButton.alpha = 1;
        self.selectPhotoView.alpha = 1;
        self.selectHintLabel.alpha = 1;
        self.backButton.alpha = 1;
        self.topMaskView.alpha = 1;
        self.bottomMaskView.alpha = 1;
        self.seperatorLineView.alpha = 1;
        if (self.viewModel.hasSelectedAssets || ![self p_shouldHideSelectedViewWhenNotSelect]) {
            self.selectedAssetsView.alpha = 1;
            self.selectedAssetsViewMaskView.alpha = 1;
        }
    } completion:nil];
    self.isShowingPurePreview = NO;
}

- (void)hideWidgetsWithIsZooming:(BOOL)isZooming
{
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.topMaskView.alpha = 0;
        self.bottomMaskView.alpha = 0;
        self.seperatorLineView.alpha = 0;
        self.selectedAssetsView.alpha = 0;
        self.selectedAssetsViewMaskView.alpha = 0;
        if (isZooming) {
            self.nextButton.alpha = 0;
            self.selectPhotoView.alpha = 0;
            self.selectHintLabel.alpha = 0;
            self.backButton.alpha = 0;
        }
    } completion:nil];
    self.isShowingPurePreview = YES;
}

- (void)setupSelectPhotoView
{
    BOOL shouldAdjustPreviewPage = [self p_enableSelectedAssetsView];
    self.selectPhotoUserInteractive = YES;
    if (shouldAdjustPreviewPage) {
        [self.view addSubview:self.bottomView];
        ACCMasMaker(self.bottomView, {
            make.leading.bottom.trailing.equalTo(self.view);
            make.height.equalTo(@(kAlbumSelectedAssetsBottomViewHeight()));
        });
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectPhotoButtonClick:)];
        [self.bottomView.selectPhotoView addGestureRecognizer:tapGesture];
        return;
    }
    
    UIView *selectPhotoView = [[UIView alloc] init];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectPhotoButtonClick:)];
    [selectPhotoView addGestureRecognizer:tapGesture];
    [self.view addSubview:selectPhotoView];
    ACCMasMaker(selectPhotoView, {
        make.width.equalTo(@(80));
        make.height.equalTo(@(40));
        make.right.equalTo(self.view.mas_right);
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        } else {
            make.top.equalTo(self.view.mas_top);
        }
    });
    _selectPhotoView = selectPhotoView;

    CGFloat checkImageHeight = 22;
    NSString *resourceStr = @"";
    if (self.viewModel.listViewConfig.enableAssetsRepeatedSelect) {
        resourceStr = @"icon_album_pressed_repeat_select";
    } else {
        resourceStr = @"icon_album_unselect";
    }
    _unCheckImageView = [[UIImageView alloc] initWithImage:CAKResourceImage(resourceStr)];
    [_selectPhotoView addSubview:_unCheckImageView];
    ACCMasMaker(_unCheckImageView, {
        make.right.equalTo(_selectPhotoView.mas_right).offset(-16);
        make.top.equalTo(_selectPhotoView.mas_top).offset(16);
        make.width.height.equalTo(@(checkImageHeight));
    });

    if (self.assetsSelectedIconStyle == CAKAlbumAssetsSelectedIconStyleCheckMark) {
        _numberBackGroundImageView = [[UIImageView alloc] initWithImage:CAKResourceImage(@"icon_album_selected_checkmark")];
    } else {
        UIColor *cornerImageColor = CAKResourceColor(ACCColorPrimary);
        UIColor *numberLabelTextColor = CAKResourceColor(ACCColorConstTextInverse);
        CGFloat numberLabelFontSize = 12;
        UIImage *cornerImage = [UIImage cak_imageWithSize:CGSizeMake(checkImageHeight, checkImageHeight) cornerRadius:checkImageHeight * 0.5 borderWidth:1.5 borderColor:[UIColor whiteColor] backgroundColor:cornerImageColor];
        _numberBackGroundImageView = [[UIImageView alloc] initWithImage:cornerImage];
        _numberLabel = [[UILabel alloc] init];
//        _numberLabel.accrtl_viewType = ACCRTLViewTypeNormal;
        _numberLabel.font = [UIFont acc_systemFontOfSize:numberLabelFontSize];
        _numberLabel.textColor = numberLabelTextColor;
        _numberLabel.textAlignment = NSTextAlignmentCenter;
        [_numberBackGroundImageView addSubview:_numberLabel];
        ACCMasMaker(_numberLabel, {
            make.edges.equalTo(_numberBackGroundImageView);
        });
    }

    [_selectPhotoView addSubview:_numberBackGroundImageView];
    ACCMasMaker(_numberBackGroundImageView, {
        make.left.right.top.bottom.equalTo(self.unCheckImageView);
    });

    _selectHintLabel = [[UILabel alloc] init];
    _selectHintLabel.font = [UIFont acc_systemFontOfSize:15];
    _selectHintLabel.textColor = CAKResourceColor(ACCUIColorIconPrimary);
    [_selectPhotoView addSubview:_selectHintLabel];

    ACCMasMaker(_selectHintLabel, {
        make.top.equalTo(self.unCheckImageView.mas_top);
        make.bottom.equalTo(self.unCheckImageView.mas_bottom);
        make.right.equalTo(self.unCheckImageView.mas_left).offset(-12);
        make.width.lessThanOrEqualTo(@(200));
    });
    
    _repeatSelectHintLabel = [[UILabel alloc] init];
    _repeatSelectHintLabel.font = [UIFont acc_systemFontOfSize:17];;
    _repeatSelectHintLabel.textColor = CAKResourceColor(ACCColorTextPrimary);
    [self.view addSubview:_repeatSelectHintLabel];
    
    if (!shouldAdjustPreviewPage && self.viewModel.listViewConfig.enableAssetsRepeatedSelect) {
        ACCMasMaker(_repeatSelectHintLabel, {
            make.top.equalTo(self.unCheckImageView.mas_top);
            make.centerX.equalTo(self.view.mas_centerX);
        });
    }
}

- (void)setupNextButton
{
    if ([self p_enableSelectedAssetsView]) {
        [self.bottomView.nextButton addTarget:self action:@selector(goToNextPage:) forControlEvents:UIControlEventTouchUpInside];
        [self updateTitleForButton:self.bottomView.nextButton];
        return;
    }
    self.nextButton = [[UIButton alloc] init];
    self.nextButton.backgroundColor = CAKResourceColor(ACCColorPrimary);
    [self.nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.nextButton setTitleColor:CAKResourceColor(ACCColorConstTextInverse) forState:UIControlStateDisabled];
    [self.nextButton setTitle:CAKLocalizedString(@"common_next", @"next") forState:UIControlStateNormal];
    self.nextButton.titleLabel.font = [UIFont acc_systemFontOfSize:14.0f weight:ACCFontWeightMedium];
    self.nextButton.titleEdgeInsets = UIEdgeInsetsMake(0, 12, 0, 12);
    self.nextButton.layer.cornerRadius = 2.0f;
    self.nextButton.clipsToBounds = YES;
    [self.nextButton addTarget:self action:@selector(goToNextPage:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.nextButton];

    CGSize sizeFits = [_nextButton sizeThatFits:CGSizeMake(MAXFLOAT, MAXFLOAT)];
    ACCMasMaker(self.nextButton, {
        make.top.equalTo(self.bottomMaskView.mas_top).offset(8);
        make.right.equalTo(self.view).offset(-16);
        make.width.equalTo(@(sizeFits.width + 24));
        make.height.equalTo(@(36.0f));
    });
    [self updateTitleForButton:self.nextButton];
}

- (void)updateSelectedCellStatus
{
    // repeat select needn't update
    if ([self shouldAdjustDockForRepeatSelect]) {
        return;
    }
    
    for (CAKAlbumAssetModel *model in self.selectedAssetsView.assetModelArray) {
        if ([model isEqualToAssetModel:self.currentAssetModel identity:NO]) {
            model.isShowingInPreview = YES;
        } else {
            model.isShowingInPreview = NO;
        }
    }
    [self.selectedAssetsView.collectionView reloadData];
}

- (void)updateCustomBottomViewIfNeed
{
    if ([self.customBottomView respondsToSelector:@selector(updateSelectPhotoStatus:)]) {
        [self.customBottomView updateSelectPhotoStatus:self.currentAssetModel.selectedNum ? YES : NO];
    }
    
    if ([self.customBottomView respondsToSelector:@selector(updateNextButtonStatus:)]) {
        [self.customBottomView updateNextButtonStatus:self.viewModel.currentSelectedAssetsCount > 0];
    }
}

- (BOOL)autoSelectCurrentAsset
{
    if (self.viewModel.listViewConfig.previewNextNeverDisabled && !self.viewModel.hasSelectedAssets) {
        // 遮挡 selectedAssetsView、各种 maskView、选中按钮的 UI 变化
        UIView *snapshot = [self.view snapshotViewAfterScreenUpdates:NO];
        [[self.view superview] addSubview:snapshot];
        [self selectPhotoButtonClick:nil];
        if (self.viewModel.hasSelectedAssets) {
            // 返回的时候保持未选中的状态
            @weakify(self);
            [[[self rac_signalForSelector:@selector(viewWillAppear:)] take:1] subscribeNext:^(RACTuple * _Nullable x) {
                @strongify(self);
                [self selectPhotoButtonClick:nil];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [snapshot removeFromSuperview];
                });
            }];
        } else {
            [snapshot removeFromSuperview];
            return NO; // 无法继续
        }
    }
    return YES; // 可继续
}

- (void)goToNextPage:(UIButton *)btn
{
    if (![self autoSelectCurrentAsset]) {
        return;
    }

    // delegate层级：CAKAlbumListViewController<CAKAlbumPreviewAndSelectControllerDelegate>
    // -> CAKAlbumViewController<CAKAlbumListViewControllerDelegate>
    // 最终处理逻辑在 CAKAlbumViewController 中
    if ([self.delegate respondsToSelector:@selector(previewController:didClickNextButton:)]) {
        if (self.viewModel.listViewConfig.shouldDismissPreviewPageWhenNext) {
            if ([[self.navigationController viewControllers] firstObject] == self || !self.navigationController) {
                [self dismissViewControllerAnimated:YES completion:nil];
            } else {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
        [self.delegate previewController:self didClickNextButton:btn];
    }
}

- (void)updateTitleForButton:(UIButton *)btn
{
    if ([self.delegate respondsToSelector:@selector(previewController:updateNextButtonTitle:)]) {
        [self.delegate previewController:self updateNextButtonTitle:btn];
    }
}

- (void)selectAssetCollectionViewScrollToCurrentModelIndex
{
    // repeat select needn't update
    if ([self shouldAdjustDockForRepeatSelect]) {
        return;
    }
    
    if ([self.selectedAssetsView.assetModelArray containsObject:self.currentAssetModel]) {
        NSUInteger currentPreviewingIndex = [self.selectedAssetsView.assetModelArray indexOfObject:self.currentAssetModel];
        [self.selectedAssetsView.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:currentPreviewingIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
    }
}

- (void)p_previewCollectionViewScrollToCurrentModelIndex
{
    if (self.currentIndex < [self originDataSourceCount] && self.currentIndex >= 0) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    }
}

#pragma mark - material repeat select

- (void)p_updateRepeatSelected:(CAKAlbumAssetModel *)assetModel greyMode:(BOOL)greyMode
{
    if (![self p_enableSelectedAssetsView]) {
        self.repeatSelectHintLabel.text = [NSString stringWithFormat: CAKLocalizedString(@"creation_mv_upload_selected_num",@"已选择%d个素材d"), (int)self.viewModel.currentSelectAssetModels.count];
        self.selectHintLabel.hidden = YES;
    } else {
        self.selectHintLabel.hidden = NO;
        self.bottomView.selectHintLabel.hidden = NO;
    }
    NSTimeInterval duration = assetModel.phAsset.duration;
    BOOL reachTotalLimit = self.viewModel.listViewConfig.selectionLimitType == CAKAlbumSelectionLimitTypeTotal && self.viewModel.hasSelectedMaxCount;
    
    BOOL reachSeparateLimit = NO;
    if (assetModel.mediaType == CAKAlbumAssetModelMediaTypeVideo) {
        reachSeparateLimit = self.viewModel.listViewConfig.selectionLimitType == CAKAlbumSelectionLimitTypeSeparate &&  self.viewModel.hasVideoSelectedMaxCount;
    }
    if (assetModel.mediaType == CAKAlbumAssetModelMediaTypePhoto) {
        reachSeparateLimit = self.viewModel.listViewConfig.selectionLimitType == CAKAlbumSelectionLimitTypeSeparate && self.viewModel.hasPhotoSelectedMaxCount;
    }
    
    if (greyMode || (assetModel.mediaType == CAKAlbumAssetModelMediaTypeVideo && duration < 1) || (reachTotalLimit || reachSeparateLimit)) {
        self.unCheckImageView.alpha = 0.34;
        self.selectHintLabel.textColor = CAKResourceColor(ACCUIColorConstTextInverse4);
        self.bottomView.unCheckImageView.alpha = 0.34;
        self.bottomView.selectHintLabel.textColor = CAKResourceColor(ACCUIColorConstTextInverse4);
    } else {
        self.unCheckImageView.alpha = 1;
        self.selectHintLabel.textColor = CAKResourceColor(ACCUIColorConstTextInverse2);
        self.bottomView.unCheckImageView.alpha = 1;
        self.bottomView.selectHintLabel.textColor = CAKResourceColor(ACCUIColorConstTextInverse2);
    }
    self.selectHintLabel.text = CAKLocalizedString(@"full_screen_select", @"Select");
    self.numberBackGroundImageView.hidden = YES;
    self.bottomView.selectHintLabel.text = CAKLocalizedString(@"full_screen_select", @"Select");
    self.bottomView.numberBackGroundImageView.hidden = YES;
}

- (void)p_doRepeatSelectAnimationIfNeed
{
    if (!self.viewModel.listViewConfig.enableAssetsRepeatedSelect) {
        return;
    }
    
    self.unCheckImageView.transform = CGAffineTransformIdentity;
    self.bottomView.unCheckImageView.transform = CGAffineTransformIdentity;
    [UIView animateWithDuration:0.3 animations:^{
        self.unCheckImageView.transform = CGAffineTransformMakeScale(1.1, 1.1);
        self.bottomView.unCheckImageView.transform = CGAffineTransformMakeScale(1.1, 1.1);
    } completion:^(BOOL finished) {
        self.unCheckImageView.transform = CGAffineTransformIdentity;
        self.bottomView.unCheckImageView.transform = CGAffineTransformIdentity;
    }];
}

- (void)p_scrollSelectCollectionViewToCurrentForRepeatSelect
{
    if (![self shouldAdjustDockForRepeatSelect]) {
        return;
    }
    
    NSInteger toIndex = [self p_currentIndexSelectCollectionViewWillScrollTo];
    if (toIndex < [self p_numberOfItemsInSelectCollectionView] && toIndex >= 0) {
        [self.selectedAssetsView.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:toIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
    }
}

- (NSInteger)p_currentIndexSelectCollectionViewWillScrollTo
{
    __block NSInteger toIndex = self.currentIndex;
    if (self.viewModel.listViewConfig.addAssetInOrder && [self.selectedAssetsView respondsToSelector:@selector(currentNilIndexArray)]) {
        // 实际滚动位置需考虑包含的空格子数
        NSMutableArray<NSNumber *> *nilIndexArray = [self.selectedAssetsView currentNilIndexArray];
        [nilIndexArray enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj intValue] <= toIndex) {
                toIndex++;
            } else {
                *stop = YES;
            }
        }];
    }
    
    return toIndex;
}

- (NSInteger)p_numberOfItemsInSelectCollectionView
{
    NSInteger maxCount = self.selectedAssetsView.assetModelArray.count;
    if (self.viewModel.listViewConfig.addAssetInOrder && [self.selectedAssetsView respondsToSelector:@selector(currentNilIndexArray)]) {
        maxCount += [self.selectedAssetsView currentNilIndexArray].count;
    }

    return maxCount;
}

- (void)p_updateSelectViewHighlightIndex:(NSInteger)highlightIndex
{
    if ([self.selectedAssetsView respondsToSelector:@selector(updateSelectViewHighlightIndex:)]) {
        [self.selectedAssetsView updateSelectViewHighlightIndex:highlightIndex];
    }
}

- (NSInteger)p_currentSelectViewHighlightIndex
{
    if ([self.selectedAssetsView respondsToSelector:@selector(currentSelectViewHighlightIndex)]) {
        return [self.selectedAssetsView currentSelectViewHighlightIndex];
    }
    return NSNotFound;
}

- (BOOL)p_checkCurrentIndexValid
{
    return self.currentIndex < [self originDataSourceCount] && self.currentIndex >= 0;
}

- (BOOL)shouldAdjustDockForRepeatSelect
{
    return self.viewModel.listViewConfig.enableAssetsRepeatedSelect && [self p_enableSelectedAssetsView] && self.fromBottomView;
}

#pragma mark - avplayer control

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    self.isDragging = YES;
    self.selectPhotoUserInteractive = NO;
    self.showLeftToast = NO;
    self.showRightToast = NO;
    [self.avPlayer pause];
}

- (void)dealWithPhotoChange{
    @weakify(self);
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
        object:nil
         queue:[NSOperationQueue mainQueue]
    usingBlock:^(NSNotification * _Nonnull note) {
        @strongify(self);
        if ([self originDataSourceCount] == 0) {
            [self back:nil];
            return ;
        } else {
            if (![self containsAssetModel:self.currentAssetModel]){
                [self.collectionView reloadData];
                if (self.currentIndex < [self originDataSourceCount] && self.currentIndex >= 0) {
                   
                } else {
                    self.currentIndex = [self originDataSourceCount] - 1;
                }
                self.currentAssetModel = [self assetModelForIndex:self.currentIndex];
                [self.collectionView setContentOffset:CGPointMake(self.currentIndex * self.collectionView.bounds.size.width, 0)];
                if (self.currentAssetModel.mediaType == CAKAlbumAssetModelMediaTypeVideo) {
                    [self setUpPlayer:self.currentAssetModel];
                }
            
                [self updatePhotoSelected:self.currentAssetModel greyMode:self.greyMode];
            }
            
        }
    }];
}

- (NSInteger)originDataSourceCount
{
    if (!self.fromBottomView) {
        return [self.assetDataModel previewNumberOfObject];
    } else {
        return self.originDataSource.count;
    }
}

- (CAKAlbumAssetModel *)assetModelForIndex:(NSInteger)index
{
    CAKAlbumAssetModel *assetModel;
    if (!self.fromBottomView) {
        assetModel = [self.assetDataModel previewObjectIndex:index];
    } else {
        assetModel = self.originDataSource[index];
    }
    return assetModel;
}

- (BOOL)containsAssetModel:(CAKAlbumAssetModel *)object
{
    if (!object) {
        return NO;
    }
    if (!self.fromBottomView) {
        return [self.assetDataModel previewContainsObject:object];
    } else {
        return [self.originDataSource containsObject:object];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self.loadingView dismiss];
    if (self.isDragging) {
        if (scrollView.contentOffset.x < -50 && self.showLeftToast == NO) {
            NSString *toastStr = @"";
            toastStr = CAKLocalizedString(@"full_screen_firstitem_tips", @"This is the first item");
            self.showLeftToast = YES;
            [CAKToastShow() showToast:toastStr];
        }
        
        if (scrollView.contentOffset.x > scrollView.contentSize.width - scrollView.frame.size.width + 50 && self.showRightToast == NO) {
            NSString *toastStr = @"";
            toastStr = CAKLocalizedString(@"full_screen_lastitem_tips", @"This is the last item");
            self.showRightToast = YES;
            [CAKToastShow() showToast:toastStr];
        }
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{

}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{

}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    NSInteger position =floor((*targetContentOffset).x/scrollView.bounds.size.width);
    if (position < [self originDataSourceCount] && position >= 0) {
        CAKAlbumAssetModel *assetModel = [self assetModelForIndex:position];
        [self updatePhotoSelected:assetModel greyMode:self.greyMode];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.isDragging = NO;
    self.selectPhotoUserInteractive = YES;
    NSInteger scroolIndex = floor(scrollView.contentOffset.x/scrollView.bounds.size.width);
    if (scroolIndex < [self originDataSourceCount] && scroolIndex >= 0) {
        CAKAlbumAssetModel *assetModel = [self assetModelForIndex:scroolIndex];
        BOOL isSameAssetInPreview = NO;
        if (self.viewModel.listViewConfig.enableAssetsRepeatedSelect && self.fromBottomView) {
            isSameAssetInPreview = scroolIndex == self.currentIndex;
        } else {
            isSameAssetInPreview = [self.currentAssetModel isEqual:assetModel];
        }
        if (isSameAssetInPreview) {
            [self playAfterCheck];
            return ;
        }
        self.currentIndex = scroolIndex;
        self.currentAssetModel = assetModel;
        if (assetModel.mediaType == CAKAlbumAssetModelMediaTypeVideo) {
            [self setUpPlayer:assetModel];
        }
        
        if ([self.delegate respondsToSelector:@selector(previewController:scrollViewDidEndDeceleratingWithAlbumAsset:)]) {
            [self.delegate previewController:self scrollViewDidEndDeceleratingWithAlbumAsset:assetModel];
        }
    }
    if (!self.fromBottomView) {
        if ([self.assetDataModel removePreviewInvalidAssetForPostion:self.currentIndex]) {
            self.currentIndex = [self.assetDataModel previewIndexOfObject:self.currentAssetModel];
            [self p_previewCollectionViewScrollToCurrentModelIndex];
            [self.collectionView layoutIfNeeded];
        }
    }
    if ([self shouldAdjustDockForRepeatSelect]) {
        [self p_updateSelectViewHighlightIndex:self.currentIndex];
        [self p_scrollSelectCollectionViewToCurrentForRepeatSelect];
    }
    if (self.viewModel.enableBottomViewForPreviewPage) {
        [self updateCustomBottomViewIfNeed];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removePlayer];
}

- (void)runLoopTheMovie:(NSNotification *)notification
{
    [self.avPlayer seekToTime:kCMTimeZero];
    [self playAfterCheck];
}

- (void)removePlayer
{
    if (_avPlayer) {
        [self.KVOController unobserve:self.avPlayerLayer keyPath:@"readyForDisplay"];
        [self.KVOController unobserve:self.avPlayer keyPath:@"status"];
        [_avPlayerLayer removeFromSuperlayer];
        _avPlayerLayer = nil;
        _avPlayer = nil;
    }
}

- (void)setUpPlayer:(CAKAlbumAssetModel *)assetModel
{
    [self trackMonitor];
    [self removePlayer];
    [self performSelector:@selector(showLoading) withObject:nil afterDelay:0.5];
    [self selectAsset:assetModel progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        if (error) {
            AWELogToolInfo(AWELogToolTagImport, @"upload: preview fetch video with error : %@", error);
        }
    } completion:^(AVAsset *videoAsset, NSError *error) {
        if (error) {
            AWELogToolInfo(AWELogToolTagImport, @"upload: preview fetch video with error : %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.loadingView dismiss];
                [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showLoading) object:nil];
                if (error.userInfo) {
                    NSString *errorMsg = [error.userInfo acc_objectForKey:@"NSLocalizedDescription"];
                    if (errorMsg) {
                        [CAKToastShow() showToast:errorMsg];
                    }
                }
            });
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([[videoAsset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
                AVAssetTrack *firstTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo][0];
                CGSize dimensions = CGSizeApplyAffineTransform(firstTrack.naturalSize, firstTrack.preferredTransform);
                self.videoSize = @(CGSizeMake(fabs(dimensions.width), fabs(dimensions.height)));

            }
            [self removePlayer];
            self.avPlayer = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithAsset:videoAsset]];
            self.avPlayer.currentItem.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmSpectral;
            self.avPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];

            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(runLoopTheMovie:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayer.currentItem];

            @weakify(self);
            [self.KVOController observe:self.avPlayerLayer
                                keyPath:@"readyForDisplay"
                                options:0
                                  block:^(typeof(self) _Nullable observer, id object, NSDictionary *change) {
                                      @strongify(self);
                                      if (self.avPlayerLayer.readyForDisplay) {
                                          self.couldTrack = YES;
                                          [self.loadingView dismiss];
                                          [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showLoading) object:nil];
                                          [self playAfterCheck];
                                          NSArray *visibleCell = [self.collectionView visibleCells];
                                          if ([visibleCell count] > 0) {
                                              CAKAlbumPreviewAndSelectCell *cell = (CAKAlbumPreviewAndSelectCell *)visibleCell.firstObject;
                                              if ([cell isKindOfClass:[CAKAlbumPreviewAndSelectCell class]]) {
                                                  [cell setPlayerLayer:self.avPlayerLayer withPlayerFrame:[self playerFrame]];
                                                  [cell removeCoverImageView];
                                              }
                                          }
                                          
                                      }
                                  }];
            
            [self.avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 60) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
                @strongify(self);
                NSArray *visibleCell = [self.collectionView visibleCells];
                if ([visibleCell count] > 0) {
                    CAKAlbumPreviewAndSelectCell *cell = (CAKAlbumPreviewAndSelectCell *)visibleCell.firstObject;
                    if ([cell isKindOfClass:[CAKAlbumPreviewAndSelectCell class]]) {
                        [cell removeCoverImageView];
                    }
                }
            }];
            
            
            [self.KVOController observe:self.avPlayer
                                keyPath:@"status"
                                options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                                  block:^(typeof(self) _Nullable observer, id object, NSDictionary *change) {
                                      @strongify(self);
                                      AVPlayerStatus status = [[change objectForKey:@"new"] intValue];
                                      if (status == AVPlayerStatusFailed) {
                                          self.errorOccur = YES;
                                      }
                                  }];
            [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                              object:nil
                                                               queue:[NSOperationQueue mainQueue]
                                                          usingBlock:^(NSNotification * _Nonnull note) {
                                                              @strongify(self);
                                                              [self playAfterCheck];
                                                          }];
            [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification
                                                              object:nil
                                                               queue:[NSOperationQueue mainQueue]
                                                          usingBlock:^(NSNotification * _Nonnull note) {
                                                              @strongify(self);
                                                              [self.avPlayer pause];
                                                          }];
        });
    }];
}

- (void)trackMonitor{
    if (self.couldTrack && self.avPlayer.currentItem) {
        NSInteger status = self.errorOccur ? 1 : 0;
        if ([self.delegate respondsToSelector:@selector(albumListVC:previewControllerWillBeginSetupPlayer:status:)]) {
            [self.delegate previewController:self willBeginSetupPlayer:self.avPlayer status:status];
        }
    }
    self.couldTrack = NO;
    self.errorOccur = NO;
}

- (void)showLoading{
    self.loadingView = [CAKLoading() showLoadingOnView:self.view title:@"" animated:YES];
    [self.loadingView allowUserInteraction:YES];
    [self.loadingView startAnimating];
}

- (UICollectionView *)collectionView {
    if (_collectionView == nil) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = self.view.bounds.size;
        flowLayout.minimumLineSpacing = 0;
        flowLayout.minimumInteritemSpacing = 0;
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flowLayout];
        [_collectionView registerClass:[self getClassFromType:CAKAlbumAssetModelMediaTypeVideo] forCellWithReuseIdentifier:NSStringFromClass([self getClassFromType:CAKAlbumAssetModelMediaTypeVideo])];
        [_collectionView registerClass:[self getClassFromType:CAKAlbumAssetModelMediaTypePhoto] forCellWithReuseIdentifier:NSStringFromClass([self getClassFromType:CAKAlbumAssetModelMediaTypePhoto])];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.pagingEnabled = YES;
        _collectionView.alwaysBounceHorizontal = YES;
    }
    return _collectionView;
}

#pragma mark - CAKAlbumPreviewAndSelectCellDelegate

- (void)updatePhotoSelected:(CAKAlbumAssetModel *)assetModel greyMode:(BOOL)greyMode
{
    NSNumber *number = assetModel.selectedNum;
    UIColor *hintColor = CAKResourceColor(ACCUIColorConstTextInverse2);
    if (self.viewModel.listViewConfig.enableAssetsRepeatedSelect) {
        [self p_updateRepeatSelected:assetModel greyMode:greyMode];
        return;
    }
    if (number) {
        //check
        self.unCheckImageView.hidden = YES;
        self.numberBackGroundImageView.hidden = NO;
        self.numberLabel.text = [NSString stringWithFormat:@"%@", @([number integerValue])];
        self.selectHintLabel.text = CAKLocalizedString(@"full_screen_selected", @"Selected");
        self.selectHintLabel.textColor = hintColor;
        self.unCheckImageView.alpha = 1;
        
        //bottom view
        self.bottomView.unCheckImageView.hidden = YES;
        self.bottomView.numberBackGroundImageView.hidden = NO;
        self.bottomView.numberLabel.text = [NSString stringWithFormat:@"%@", @([number integerValue])];
        self.bottomView.selectHintLabel.text = CAKLocalizedString(@"full_screen_selected", @"Selected");
        self.bottomView.selectHintLabel.textColor = hintColor;
        self.bottomView.unCheckImageView.alpha = 1;
    } else {
        NSTimeInterval duration = assetModel.phAsset.duration;
        BOOL reachTotalLimit = self.viewModel.listViewConfig.selectionLimitType == CAKAlbumSelectionLimitTypeTotal && self.viewModel.hasSelectedMaxCount;
        BOOL reachSeparateLimit = self.viewModel.listViewConfig.selectionLimitType == CAKAlbumSelectionLimitTypeSeparate && ((assetModel.mediaType == CAKAlbumAssetModelMediaTypeVideo && self.viewModel.hasVideoSelectedMaxCount) || (assetModel.mediaType == CAKAlbumAssetModelMediaTypePhoto && self.viewModel.hasPhotoSelectedMaxCount));
        if (greyMode || (assetModel.mediaType == CAKAlbumAssetModelMediaTypeVideo && duration < 1) || (reachTotalLimit || reachSeparateLimit)) {
            self.unCheckImageView.alpha = 0.34;
            self.selectHintLabel.textColor = CAKResourceColor(ACCUIColorConstTextInverse4);
            
            self.bottomView.unCheckImageView.alpha = 0.34;
            self.bottomView.selectHintLabel.textColor = CAKResourceColor(ACCUIColorConstTextInverse4);
        } else {
            self.unCheckImageView.alpha = 1;
            self.selectHintLabel.textColor = hintColor;
            
            self.bottomView.unCheckImageView.alpha = 1;
            self.bottomView.selectHintLabel.textColor = hintColor;
        }
        //check
        self.unCheckImageView.hidden = NO;
        
        self.numberBackGroundImageView.hidden = YES;
        self.numberLabel.text = nil;
        self.selectHintLabel.text = CAKLocalizedString(@"full_screen_select", @"Selected");
        
        //bottom view
        self.bottomView.unCheckImageView.hidden = NO;
        self.bottomView.numberBackGroundImageView.hidden = YES;
        self.bottomView.numberLabel.text = nil;
        self.bottomView.selectHintLabel.text = CAKLocalizedString(@"full_screen_select", @"Selected");
    }
    if ([ACCAccessibility() respondsToSelector:@selector(enableAccessibility:traits:label:)]) {
        [ACCAccessibility() enableAccessibility:self.selectPhotoView
                                         traits:UIAccessibilityTraitButton
                                          label:[NSString stringWithFormat:@"%@ %@",self.selectHintLabel.text,self.numberLabel.text]];
        [ACCAccessibility() enableAccessibility:self.bottomView.selectPhotoView
                                         traits:UIAccessibilityTraitButton
                                          label:[NSString stringWithFormat:@"%@ %@",self.bottomView.selectHintLabel.text,self.bottomView.numberLabel.text]];
    }
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self originDataSourceCount];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    CAKAlbumPreviewAndSelectCell *previewCell = (CAKAlbumPreviewAndSelectCell *)cell;
    if (indexPath.row < [self originDataSourceCount]) {
        CAKAlbumAssetModel *assetModel = [self assetModelForIndex:indexPath.row];
        self.videoSize = @(CGSizeMake(assetModel.phAsset.pixelWidth, assetModel.phAsset.pixelHeight));
        [previewCell configCellWithAsset:assetModel withPlayFrame:[self playerFrame] greyMode:self.greyMode];
        @weakify(self);
        previewCell.fetchIcloudCompletion = ^(NSTimeInterval duration, NSInteger size) {
            @strongify(self);
            if ([self.delegate respondsToSelector:@selector(previewController:didFinishFetchIcloudWithFetchDuration:size:)]) {
                [self.delegate previewController:self didFinishFetchIcloudWithFetchDuration:duration size:size];
            }
        };
        previewCell.scrollViewDidZoomBlock = ^(CGFloat zoomScale) {
            @strongify(self);
            [self hideWidgetsWithIsZooming:YES];
        };
        previewCell.scrollViewDidEndZoomBlock = ^(CGFloat zoomScale, BOOL isZoomIn) {
            @strongify(self);
            [self showWidgets];
            if ([self.delegate respondsToSelector:@selector(previewController:viewDidEndZoomingWithZoomIn:asset:)]) {
                [self.delegate previewController:self viewDidEndZoomingWithZoomIn:isZoomIn asset:self.currentAssetModel];
            }
        };
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger position = collectionView.contentOffset.x/collectionView.bounds.size.width;
    if (position < [self originDataSourceCount] && position >= 0) {
        CAKAlbumAssetModel *assetModel = [self assetModelForIndex:position];
        [self updatePhotoSelected:assetModel greyMode:self.greyMode];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < [self originDataSourceCount]) {
        CAKAlbumAssetModel *assetModel = [self assetModelForIndex:indexPath.row];
        CAKAlbumPreviewAndSelectCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([self getClassFromType:assetModel.mediaType]) forIndexPath:indexPath];
        for (CAKAlbumAssetModel *seletedAssetModel in self.selectedAssetModelArray) {
            if ([assetModel isEqual:seletedAssetModel]) {
                assetModel.selectedNum = seletedAssetModel.selectedNum;
            }
        }
        return cell;
    } else {
        return [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([CAKAlbumPhotoPreviewAndSelectCell class]) forIndexPath:indexPath];
    }
    
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)back:(id)sender
{
    if (self.viewModel.listViewConfig.addAssetInOrder && [self p_enableSelectedAssetsView]) {
        if ([self.selectedAssetsView respondsToSelector:@selector(currentNilIndexArray)]) {
            [self.viewModel updateNilIndexArray:[self.selectedAssetsView currentNilIndexArray]];
        }
    }
    self.exitAssetModel = self.currentAssetModel;
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - CAKAlbumZoomTransitionInnerContextProvider

- (CAKAlbumTransitionTriggerDirection)zoomTransitionAllowedTriggerDirection
{
    return CAKAlbumTransitionTriggerDirectionDown;
}

- (UIView *)zoomTransitionEndView
{
    //set exitAssetModel when exit;
    self.exitAssetModel = self.currentAssetModel;
    CAKAlbumPreviewAndSelectCell *cell = [self.collectionView visibleCells].firstObject;
    if ([cell isKindOfClass:[CAKAlbumPreviewAndSelectCell class]]) {
        if (cell.assetModel.mediaType == CAKAlbumAssetModelMediaTypeVideo) {
            CAKAlbumVideoPreviewAndSelectCell *previewCell = (CAKAlbumVideoPreviewAndSelectCell *)cell;
            if ([previewCell isKindOfClass:[CAKAlbumVideoPreviewAndSelectCell class]]) {
                if (previewCell.playerView) {
                    return previewCell.playerView;
                } else {
                    return previewCell.coverImageView;
                }

            }
        } else if (cell.assetModel.mediaType == CAKAlbumAssetModelMediaTypePhoto) {
            CAKAlbumPhotoPreviewAndSelectCell *previewCell = (CAKAlbumPhotoPreviewAndSelectCell *)cell;
            if ([previewCell isKindOfClass:[CAKAlbumPhotoPreviewAndSelectCell class]]) {
                return previewCell.imageView;
            }
        } else {
            return self.view;
        }
    }
    return self.view;
}

- (NSInteger)zoomTransitionItemOffset
{
    return self.viewModel.resourceType == AWEGetResourceTypeImageAndVideo ? self.currentAssetModel.allCellIndex : self.currentAssetModel.categoriedCellIndex;
}

#pragma mark - util
- (CGRect)playerFrame
{
    CGRect playerFrame = self.view.bounds;
    NSValue * sizeOfVideoValue = self.videoSize;
    if (sizeOfVideoValue) {
        CGSize sizeOfVideo = [sizeOfVideoValue CGSizeValue];
        CGSize sizeOfScreen = [UIScreen mainScreen].bounds.size;
        
        CGFloat videoScale = 9.0 / 16.0;
        if (sizeOfVideo.width > 1.0 && sizeOfVideo.height > 1.0) {
            videoScale = sizeOfVideo.width / sizeOfVideo.height;
        }
        CGFloat screenScale = sizeOfScreen.width / sizeOfScreen.height;
        
        CGFloat playerWidth = 0;
        CGFloat playerHeight = 0;
        CGFloat playerX = 0;
        CGFloat playerY = 0;
        
        if ([UIDevice acc_isIPhoneX]) {
            if (videoScale > 9.0 / 16.0) {//两边不裁剪
                if (CGSizeEqualToSize(sizeOfVideo, CGSizeZero) || sizeOfVideo.height == NAN || sizeOfVideo.width == NAN) {
                    playerFrame = CGRectMake(0, 0, 0, 0);
                } else {
                    playerFrame = AVMakeRectWithAspectRatioInsideRect(sizeOfVideo, self.view.bounds);
                }
            } else if (videoScale > screenScale) {//按高度
                playerHeight = self.view.acc_height;
                playerWidth = playerHeight * videoScale;
                playerY = 0;
                playerX = - (playerWidth - self.view.acc_width) * 0.5;
                playerFrame = CGRectMake(playerX, playerY, playerWidth, playerHeight);
            } else {//按宽度
                playerWidth = self.view.acc_width;
                playerHeight = playerWidth / videoScale;
                playerX = 0;
                playerY = - (playerHeight - self.view.acc_height) * 0.5;
                playerFrame = CGRectMake(playerX, playerY, playerWidth, playerHeight);
            }
        } else {
            //不是iphoneX全使用fit方式
            if (CGSizeEqualToSize(sizeOfVideo, CGSizeZero) || sizeOfVideo.height == NAN || sizeOfVideo.width == NAN) {
                playerFrame = CGRectMake(0, 0, 0, 0);
            } else {
                playerFrame = AVMakeRectWithAspectRatioInsideRect(sizeOfVideo, self.view.bounds);
            }
        }
    }
    
    return playerFrame;
}

- (void)reloadSelectedStateWithGrayMode:(BOOL)greyMode withMediaType:(CAKAlbumAssetModelMediaType)mediaType {
    NSArray *visibleCells = [self.collectionView visibleCells];

    for (CAKAlbumPreviewAndSelectCell *cell in visibleCells) {
        if ([cell isKindOfClass:[CAKAlbumPreviewAndSelectCell class]] && cell.assetModel.mediaType == mediaType) {
            [self updatePhotoSelected:cell.assetModel greyMode:greyMode];
        }
    }
}

- (void)reloadSelectedStateWithGrayMode:(BOOL)greyMode {
    NSInteger position = self.collectionView.contentOffset.x / self.collectionView.bounds.size.width;
    if (position < [self originDataSourceCount] && position >= 0) {
        CAKAlbumAssetModel *assetModel = [self assetModelForIndex:position];
        [self updatePhotoSelected:assetModel greyMode:self.greyMode];
    }
}

- (void)selectAsset:(CAKAlbumAssetModel *)assetModel progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler completion:(void (^) (AVAsset *, NSError *))completion
{
    NSParameterAssert(completion);
    PHVideoRequestOptions *options = nil;
    if (@available(iOS 14.0, *)) {
        options = [[PHVideoRequestOptions alloc] init];
        options.version = PHVideoRequestOptionsVersionCurrent;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    }
    
    PHAsset *sourceAsset = assetModel.phAsset;
    [CAKPhotoManager getAVAssetWithPHAsset:sourceAsset options:options completion:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        BOOL isICloud = [info[PHImageResultIsInCloudKey] boolValue];
        NSError *error = [NSError errorWithDomain:@"com.aweme.gallery"
                                             code:3
                                         userInfo:@{NSLocalizedDescriptionKey:CAKLocalizedString(@"creation_icloud_fail", @"Couldn't sync some items from iCloud")}];
        if (isICloud && !asset) {
            PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
            if (@available(iOS 14.0, *)) {
                options.version = PHImageRequestOptionsVersionCurrent;
            }
            options.networkAccessAllowed = YES;
            //progress
            options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (progressHandler) {
                        progressHandler(progress, error, stop, info);
                    }
                });
            };
            if (@available(iOS 14.0, *)) {
                options.version = PHVideoRequestOptionsVersionCurrent;
                options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [CAKToastShow() showToast:CAKLocalizedString(@"creation_icloud_download", @"Syncing from iCloud...")];
            });
            [CAKPhotoManager getAVAssetWithPHAsset:sourceAsset options:options completion:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                if (asset) {
                    completion(asset, nil);
                } else {
                    completion(nil, error);
                }
            }];
        } else {
            if (asset) {
                completion(asset, nil);
            } else {
                completion(nil, error);
            }
        }
    }];
}


- (void)playAfterCheck{
    if (self.isDragging == NO && self.currentIndex < [self originDataSourceCount] && self.currentIndex >=0 && [self assetModelForIndex:self.currentIndex].mediaType == CAKAlbumAssetModelMediaTypeVideo && [ACCResponder topViewController] == self) {
        [self.avPlayer play];
    }
}

- (void)selectPhotoButtonClick:(id)sender{
    if (self.selectPhotoUserInteractive == NO) {
        return;
    }
    
    if (self.viewModel.listViewConfig.enableAssetsRepeatedSelect && self.viewModel.hasSelectedMaxCount) {
        // 重复选素材，已达最大素材，弹toast提示
        ACCBLOCK_INVOKE(self.didClickedTopRightIcon, self.currentAssetModel, NO);
        return;
    }
    
    if (self.viewModel.listViewConfig.enableAssetsRepeatedSelect && self.viewModel.listViewConfig.addAssetInOrder) {
        NSInteger originHighlightIndex = [self p_currentSelectViewHighlightIndex];
        [self.viewModel updateCurrentInsertIndex:originHighlightIndex];
        self.currentIndex = originHighlightIndex;
    }
    
    [self p_doRepeatSelectAnimationIfNeed];
    BOOL willUnselectAsset = self.currentAssetModel.selectedNum && !self.viewModel.listViewConfig.enableAssetsRepeatedSelect;
    ACCBLOCK_INVOKE(self.didClickedTopRightIcon, self.currentAssetModel, willUnselectAsset);
    [self updateSelectedCellStatus];

    if (self.viewModel.listViewConfig.enableAssetsRepeatedSelect) {
        [self p_updateRepeatSelected:self.currentAssetModel greyMode:self.viewModel.hasSelectedMaxCount];
    }
    if (self.viewModel.listViewConfig.enableAssetsRepeatedSelect && self.fromBottomView) {
        self.originDataSource = [self.viewModel.currentSelectAssetModels mutableCopy];
        [self.collectionView reloadData];
    }
    if ([self shouldAdjustDockForRepeatSelect]) {
        if (!self.viewModel.listViewConfig.addAssetInOrder) {
            self.currentIndex = self.originDataSource.count - 1;
            [self p_updateSelectViewHighlightIndex:self.currentIndex];
        }
        [self p_previewCollectionViewScrollToCurrentModelIndex];
        
        if ([self.selectedAssetsView respondsToSelector:@selector(scrollToNextSelectCell)]) {
            [self.selectedAssetsView scrollToNextSelectCell];
        }
        
        if (![self p_checkCurrentIndexValid]) {
            return;
        }
        CAKAlbumAssetModel *assetModel = [self assetModelForIndex:self.currentIndex];
        if (assetModel.mediaType == CAKAlbumAssetModelMediaTypeVideo) {
            [self setUpPlayer:assetModel];
        }
    }
}

//Consider replacing a file likes "factory"
- (Class)getClassFromType:(CAKAlbumAssetModelMediaType)type{
    switch (type) {
        case CAKAlbumAssetModelMediaTypePhoto:
            return [CAKAlbumPhotoPreviewAndSelectCell class];
            break;
        case CAKAlbumAssetModelMediaTypeVideo:
            return [CAKAlbumVideoPreviewAndSelectCell class];
            break;
        default:
            return [CAKAlbumPhotoPreviewAndSelectCell class];
            break;
    }
}

- (NSString *)getToastTextWithAssetModel:(CAKAlbumAssetModel *)assetModel
{
    NSString *toastText = CAKLocalizedString(@"error_param", @"An error occurred");
    if (assetModel.mediaType == CAKAlbumAssetModelMediaTypePhoto) {
        toastText = CAKLocalizedString(@"creation_fullpic_video", @"Video preview only");
    } else if (assetModel.mediaType == CAKAlbumAssetModelMediaTypeVideo) {
        toastText = CAKLocalizedString(@"creation_fullpic_pic", @"Photo preview only");
    }
    return toastText;
}

- (BOOL)p_enableSelectedAssetsView
{
    return self.viewModel.selectedAssetsViewConfig.enableSelectedAssetsViewForPreviewPage;
}

- (BOOL)p_shouldHideSelectedViewWhenNotSelect
{
    return self.viewModel.selectedAssetsViewConfig.shouldHideSelectedAssetsViewWhenNotSelectForPreviewPage;
}

- (CAKAlbumPreviewPageBottomView *)bottomView
{
    if (![self p_enableSelectedAssetsView]) {
        return nil;
    }
    
    if (!_bottomView) {
        _bottomView = [[CAKAlbumPreviewPageBottomView alloc] initWithSelectedIconStyle:self.assetsSelectedIconStyle enableRepeatSelect:self.viewModel.listViewConfig.enableAssetsRepeatedSelect];
    }
    return _bottomView;
}

@end
