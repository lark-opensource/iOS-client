//
//  AWEVideoEffectChooseSimplifiedViewController.m
//  Indexer
//
//  Created by Daniel on 2021/11/5.
//

#import "AWEVideoEffectChooseSimplifiedViewController.h"
#import "AWEVideoEffectSimplifiedPanelCollectionView.h"
#import "AWEVideoEffectChooseSimplifiedViewModel.h"
#import "AWESpecialEffectSimplifiedTrackHelper.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>

ACCContextId(AWEVideoEffectChooseSimplifiedViewControllerContext)

static CGFloat const kClearEffectsButtonXOffset = 18.f;
static CGFloat const kClearEffectsButtonYOffset = 10.f;
static CGFloat const kClearEffectsButtonWidthHeight = 18.f;
static CGFloat const kCollectionViewYOffset = 78.f;

@interface AWEVideoEffectChooseSimplifiedViewController ()
<
AWEVideoEffectSimplifiedPanelCollectionViewDelegation
>

@property (nonatomic, strong, nullable) UIView *bgView;
@property (nonatomic, strong, nullable) UILabel *titleLabel;
@property (nonatomic, strong, nullable) UIButton *clearEffectsButton;
@property (nonatomic, strong, nullable) AWEVideoEffectSimplifiedPanelCollectionView *collectionView;
@property (nonatomic, strong, nullable) AWEVideoEffectChooseSimplifiedViewModel *viewModel;
@property (nonatomic, assign) NSInteger indexToBeSelected;

@end

@implementation AWEVideoEffectChooseSimplifiedViewController

- (instancetype)initWithModel:(AWEVideoPublishViewModel *)publishModel editService:(id<ACCEditServiceProtocol>)editService
{
    self = [super init];
    if (self) {
        self.viewModel = [[AWEVideoEffectChooseSimplifiedViewModel alloc] initWithModel:publishModel editService:editService];
        self.indexToBeSelected = NSNotFound;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    AWELogToolInfo2(@"special_effects_panel_simplified", AWELogToolTagEdit, @"AWEVideoEffectChooseSimplifiedViewController viewDidLoad");
    [self p_setupUI];
    
    [self.viewModel updateCellModelsWithCachedEffects];
    [self.collectionView updateData]; // 需要在viewDidAppear里p_scrollToSelectedEffect
    
    @weakify(self);
    AWELogToolInfo2(@"special_effects_panel_simplified", AWELogToolTagEdit, @"AWEVideoEffectChooseSimplifiedViewController getEffectsInPanel started");
    [self.viewModel getEffectsInPanel:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            [self.collectionView updateData];
            [self p_scrollToSelectedEffect:NO];
            [self p_preloadEffects];
            AWELogToolInfo2(@"special_effects_panel_simplified", AWELogToolTagEdit, @"AWEVideoEffectChooseSimplifiedViewController getEffectsInPanel finished");
        });
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self p_scrollToSelectedEffect:NO];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    self.bgView.frame = self.view.bounds;
    self.clearEffectsButton.frame = CGRectMake(kClearEffectsButtonXOffset, kClearEffectsButtonYOffset, kClearEffectsButtonWidthHeight, kClearEffectsButtonWidthHeight);
    self.titleLabel.center = CGPointMake(self.view.bounds.size.width / 2.f, self.clearEffectsButton.center.y);
    CGFloat offsetY = 4.f; // make collectionView a bit higher than its cell's height
    self.collectionView.frame = CGRectMake(0, kCollectionViewYOffset - offsetY, self.view.frame.size.width, [AWEVideoEffectSimplifiedPanelCollectionView calculateCollectionViewHeight] + offsetY * 2);
}

#pragma mark - Private Methods

- (void)p_setupUI
{
    [self.view addSubview:self.bgView];
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.clearEffectsButton];
    [self.view addSubview:self.collectionView];
}

- (void)p_didTapClearEffectsButton:(nullable UIButton *)button
{
    [self p_removeEffects];
    [AWESpecialEffectSimplifiedTrackHelper trackClearEffects];
}

- (void)p_scrollToSelectedEffect:(BOOL)animated
{
    BOOL isNotFound = self.viewModel.selectedIndex == NSNotFound;
    BOOL isOutOfBounds = self.viewModel.selectedIndex >= [self.collectionView numberOfItemsInSection:0];
    if (isNotFound || isOutOfBounds) {
        return;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.viewModel.selectedIndex inSection:0];
    [self.collectionView selectItemAtIndexPath:indexPath animated:animated scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    [self p_updateClearableState:YES];
}

- (void)p_updateClearableState:(BOOL)couldClearEffects
{
    if (couldClearEffects) {
        [self.clearEffectsButton setEnabled:YES];
    } else {
        [self.clearEffectsButton setEnabled:NO];
    }
}

- (void)downloadEffectAtIndex:(NSInteger)index
{
    if (index == NSNotFound || index >= self.viewModel.cellModels.count) {
        return;
    }
    AWEVideoEffectChooseSimplifiedCellModel *cellModel = self.viewModel.cellModels[index];
    cellModel.downloadStatus = AWEEffectDownloadStatusDownloading;
    [self.collectionView updateCellAtIndex:index];
    @weakify(self);
    [self.viewModel downloadEffectAtIndex:index completion:^(BOOL success) {
        @strongify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView updateCellAtIndex:index];
            if (index == self.indexToBeSelected) {
                self.indexToBeSelected = NSNotFound;
                [self p_applyEffectAtIndex:index];
            }
        });
    }];
}

- (void)p_applyEffectAtIndex:(NSInteger)index
{
    if (index == NSNotFound || index >= self.viewModel.cellModels.count) {
        return;
    }
    AWEVideoEffectChooseSimplifiedCellModel *cellModel = self.viewModel.cellModels[index];
    IESEffectModel *effectModel = cellModel.effectModel;
    self.viewModel.selectedIndex = index;
    cellModel.downloadStatus = AWEEffectDownloadStatusDownloaded;
    [self.collectionView updateCellAtIndex:index];
    [self p_updateClearableState:YES];
    [self.viewModel applyEffectWholeRange:effectModel.effectIdentifier];
    AWELogToolInfo2(@"special_effects_simplified_panel", AWELogToolTagEdit, @"applyEffectWholeRange:%@", effectModel.effectIdentifier ?: @"");
}

- (void)p_removeEffects
{
    [UIView animateWithDuration:0.1 animations:^{
        self.clearEffectsButton.layer.transform = CATransform3DMakeScale(1.1f, 1.1f, 1.1f);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            self.clearEffectsButton.layer.transform = CATransform3DIdentity;
        }];
    }];
    [self.viewModel removeAllEffects];
    self.viewModel.selectedIndex = NSNotFound;
    [self p_updateClearableState:NO];
    [self.collectionView deselectAllItemsAnimated:NO];
}

- (void)p_preloadEffects
{
    NSInteger countToDownload = MAX([self.collectionView numberOfItemsPerPage], 0);
    countToDownload = MIN(countToDownload, self.viewModel.cellModels.count);
    for (NSInteger i = 0; i < countToDownload; i += 1) {
        [self downloadEffectAtIndex:i];
    }
}

#pragma mark - Getters and Setters

- (UIButton *)clearEffectsButton
{
    if (!_clearEffectsButton) {
        _clearEffectsButton = [[UIButton alloc] init];
        _clearEffectsButton.frame = CGRectMake(0, 0, 18.f, 18.f);
        _clearEffectsButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-5, -5, -5, -5);
        [[_clearEffectsButton imageView] setContentMode: UIViewContentModeScaleAspectFit];
        [_clearEffectsButton setImage:ACCResourceImage(@"iconStickerClearSelected") forState:UIControlStateNormal];
        _clearEffectsButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
        _clearEffectsButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
        _clearEffectsButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_clearEffectsButton addTarget:self action:@selector(p_didTapClearEffectsButton:) forControlEvents:UIControlEventTouchUpInside];
        [_clearEffectsButton setEnabled:NO];
        _clearEffectsButton.accessibilityLabel = @"清除特效";
        _clearEffectsButton.accessibilityTraits = UIAccessibilityTraitButton;
    }
    return _clearEffectsButton;
}

- (AWEVideoEffectSimplifiedPanelCollectionView *)collectionView
{
    if (!_collectionView) {
        _collectionView = [[AWEVideoEffectSimplifiedPanelCollectionView alloc] initWithViewModel:self.viewModel];
        _collectionView.viewDelegation = self;
    }
    return _collectionView;
}

- (UIView *)bgView
{
    if (_bgView == nil) {
        _bgView = [[UIView alloc] init];
        _bgView.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainer3);
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, ACC_SCREEN_WIDTH, [self panelViewHeight])
                                                   byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                                                         cornerRadii:CGSizeMake(12, 12)];
        CAShapeLayer *layer = [CAShapeLayer layer];
        layer.path = path.CGPath;
        _bgView.layer.mask = layer;
        [_bgView acc_addBlurEffect];
    }
    return _bgView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
        _titleLabel.font = [ACCFont() acc_systemFontOfSize:15.f
                                                    weight:ACCFontWeightMedium];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = @"特效";
        [_titleLabel sizeToFit];
    }
    return _titleLabel;
}

#pragma mark - ACCPanelViewProtocol Methods

- (void *)identifier
{
    return AWEVideoEffectChooseSimplifiedViewControllerContext;
}

- (CGFloat)panelViewHeight
{
    CGFloat bottomOffset = ACC_IPHONE_X_BOTTOM_OFFSET;
    bottomOffset = bottomOffset == 0 ? 12.f : bottomOffset;
    return kCollectionViewYOffset + [AWEVideoEffectSimplifiedPanelCollectionView calculateCollectionViewHeight] + 52.f + bottomOffset;
}

#pragma mark - AWEVideoEffectSimplifiedPanelCollectionViewDelegation

- (void)didTapCellAtIndex:(NSInteger)index
{
    if (index == NSNotFound || index >= self.viewModel.cellModels.count) {
        return;
    }
    AWEVideoEffectChooseSimplifiedCellModel *cellModel = self.viewModel.cellModels[index];
    IESEffectModel *effectModel = cellModel.effectModel;
    BOOL shouldUploadTrackInfo = YES;
    if (self.viewModel.selectedIndex == index) { // 再次点击已选中的特效，则取消特效
        self.indexToBeSelected = NSNotFound;
        [self p_removeEffects];
        shouldUploadTrackInfo = NO;
    } else if (effectModel.downloaded) { // 已下载，则应用特效
        self.indexToBeSelected = NSNotFound;
        [self p_applyEffectAtIndex:index];
    } else if (cellModel.downloadStatus != AWEEffectDownloadStatusDownloading) { // 未下载 & 非下载中，则下载特效并标记成下载完成后选中
        self.indexToBeSelected = index;
        [self downloadEffectAtIndex:index];
    } else if (cellModel.downloadStatus == AWEEffectDownloadStatusDownloading) { // 下载中，则标记成下载完成后选中
        self.indexToBeSelected = index;
    }
    
    if (shouldUploadTrackInfo) {
        [AWESpecialEffectSimplifiedTrackHelper trackClickEffect:self.viewModel.publishModel effectModel:effectModel];
    }
}

@end
