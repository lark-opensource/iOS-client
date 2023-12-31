//
//  ACCDuetLayoutViewController.m
//  CameraClient-Pods-Aweme
//
//  Created by 李辉 on 2020/2/14.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCDuetLayoutViewController.h"

#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>
#import "AWEVoiceChangerCell.h"
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CreationKitArch/ACCRecorderToolBarDefines.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreationKitInfra/UILabel+ACCAdditions.h>
#import "ACCDuetLayoutModel.h"

#import <CreationKitInfra/ACCLogProtocol.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitArch/AWECameraContainerToolButtonWrapView.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/UIView+AWEStudioAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <Masonry/View+MASAdditions.h>

static CGFloat kDeutLayoutPanelViehHeight = 252;
static CGFloat kDeutLayoutPanelViewSwitchButtonHeight = 44;
@interface ACCDuetLayoutViewController () <UIGestureRecognizerDelegate, UICollectionViewDelegate ,UICollectionViewDataSource>

@property (nonatomic, strong, nullable) UIButton *backButton;
@property (nonatomic, strong) UIView *contentContainerView;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *loadingView;

@property (nonatomic, strong) UIView *netErrorRetryContainerView;
@property (nonatomic, strong) UILabel *netErrorTipsLabel;
@property (nonatomic, strong) UIButton *netErrorRetryButton;


@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIButton *switchButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, assign) BOOL hasSelected;

@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) NSIndexPath *previousSelectedIndexPath;

// 翻转摄像头
@property (nonatomic, strong) UIButton *cameraButton;
@property (nonatomic, strong) AWECameraContainerToolButtonWrapView *cameraButtonWrapView;


@end

@implementation ACCDuetLayoutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (void)reloadData {
    [self hideNetErrorView];
    [self.collectionView reloadData];
}

- (void)forceSelectFirstLayoutIfNeeded
{
    if ([self duetLayoutModels].count > 0 && !self.hasSelected) {
        [self resetSelectedIndex];
    }
}

#pragma mark -
- (void)resetSelectedIndex
{
    self.selectedIndexPath = [NSIndexPath indexPathForRow:self.firstTimeSelectedIndex inSection:0];
    self.previousSelectedIndexPath = nil;
    [self.collectionView reloadData];
    if ([self.delegate respondsToSelector:@selector(duetLayoutController:didSelectDuetLayoutAtIndex:)]) {
        [self.delegate duetLayoutController:self didSelectDuetLayoutAtIndex:self.firstTimeSelectedIndex];
    }
}

#pragma mark - setup UI

- (void)setupUI
{
    ACCMasMaker(self.view, {
        make.width.equalTo(@([UIScreen mainScreen].bounds.size.width));
        make.height.equalTo(@([UIScreen mainScreen].bounds.size.height));
    });
    UITapGestureRecognizer *tapGes = [self.view acc_addSingleTapRecognizerWithTarget:self action:@selector(backviewTaped:)];
    tapGes.delegate = self;
    
    [self.view addSubview:self.backButton];
    ACCMasMaker(self.backButton, {
        make.top.equalTo(self.view);
        make.leading.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-(kDeutLayoutPanelViehHeight + ACC_IPHONE_X_BOTTOM_OFFSET));
        make.trailing.equalTo(self.view);
    });
    
    [self.view addSubview:self.contentContainerView];
    ACCMasMaker(self.contentContainerView, {
        make.height.equalTo(@(kDeutLayoutPanelViehHeight + ACC_IPHONE_X_BOTTOM_OFFSET));
        make.left.equalTo(self.view);
        make.width.equalTo(@(ACC_SCREEN_WIDTH));
        make.bottom.equalTo(self.view.mas_bottom);
    });
    
    [self.contentContainerView addSubview:self.switchButton];
    ACCMasMaker(self.switchButton, {
        make.width.equalTo(@86);
        make.height.equalTo(@28);
        make.right.equalTo(@-16);
        make.top.equalTo(self.contentContainerView.mas_top);
    });
    
    [self.contentContainerView addSubview:self.backgroundView];
    ACCMasMaker(self.backgroundView, {
        make.top.equalTo(self.contentContainerView.mas_top).offset(kDeutLayoutPanelViewSwitchButtonHeight);
        make.left.equalTo(self.contentContainerView);
        make.right.equalTo(self.contentContainerView);
        make.bottom.equalTo(self.contentContainerView);
    });
    
    [self.backgroundView addSubview:self.titleLabel];
    ACCMasMaker(self.titleLabel, {
        make.left.equalTo(self.backgroundView);
        make.right.equalTo(self.backgroundView);
        make.top.equalTo(self.backgroundView.mas_top).offset(11);
        make.height.equalTo(@18);
    });
    
    [self.backgroundView addSubview:self.collectionView];
    ACCMasMaker(self.collectionView, {
        make.left.equalTo(self.backgroundView).offset(20);
        make.right.equalTo(self.backgroundView).offset(-20);
        make.centerY.equalTo(self.backgroundView).offset(10 - ACC_IPHONE_X_BOTTOM_OFFSET / 2);
        make.height.equalTo(@90);
    });
    
    [self.backgroundView addSubview:self.netErrorRetryContainerView];
    ACCMasMaker(self.netErrorRetryContainerView, {
        make.left.right.bottom.equalTo(self.backgroundView);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(26);
    });
    
    [self.netErrorRetryContainerView addSubview:self.netErrorTipsLabel];
    ACCMasMaker(self.netErrorTipsLabel, {
        make.left.top.right.equalTo(self.netErrorRetryContainerView);
        make.height.equalTo(@17);
    });
    
    [self.netErrorRetryContainerView addSubview:self.netErrorRetryButton];
    ACCMasMaker(self.netErrorRetryButton, {
        make.top.equalTo(self.netErrorTipsLabel.mas_bottom).offset(16);
        make.centerX.equalTo(@(self.titleLabel.acc_width / 2));
        make.width.equalTo(@231);
        make.height.equalTo(@44);
    });

    [self setupCameraButton];
}

- (void)setupCameraButton
{
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

    CGFloat topOffset = tempFrame.origin.y + 6.0; //6 is back button's image's edge
    CGFloat shift = [UIDevice acc_screenWidthCategory] == ACCScreenWidthCategoryiPhone5 ? 3 : 0;
    self.cameraButtonWrapView.frame = CGRectMake(ACC_SCREEN_WIDTH - rightSpacing - featureViewWidth + shift, topOffset, self.cameraButtonWrapView.acc_width, buttonHeightWithSpacing);
}

- (void)showNetErrorView
{
    [self p_hiddenLoadingView];
    self.netErrorRetryContainerView.hidden = NO;
    self.collectionView.hidden = YES;
}

- (void)hideNetErrorView
{
    [self p_hiddenLoadingView];
    self.netErrorRetryContainerView.hidden = YES;
    self.collectionView.hidden = NO;
}

- (void)enableSwappedCameraButton:(BOOL)enabled
{
    if (enabled) {
        self.cameraButtonWrapView.alpha = 1.0;
        self.cameraButton.acc_disableBlock = nil;
    } else {
        self.cameraButtonWrapView.alpha = 0.5;
        self.cameraButton.acc_disableBlock = ^{
            [ACCToast() show: ACCLocalizedString(@"record_artext_disable_front_camera", @"AR类道具仅支持后置摄像头")];
        };
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (touch.view == self.view) {
        return YES;
    }
    return NO;
}

#pragma mark - actions

- (void)backviewTaped:(UIGestureRecognizer *)tapGesture
{
    [self p_dismiss];
}

- (void)didTapBackButton:(UIButton *)button
{
    [self p_dismiss];
}

#pragma mark - public
- (void)showOnView:(UIView *)containerView
{
    if (!containerView) {
        return;
    }
    [self reloadData];
    [self p_showOnView:containerView fromOffset:CGPointMake(0, containerView.acc_height) animated:YES duration:0.25];
}

#pragma mark - UICollectionViewDelegate ,UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self duetLayoutModels].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AWEVoiceChangerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([AWEVoiceChangerCell class]) forIndexPath:indexPath];
    cell.currentEffect = [self duetLayoutModelAtIndex:indexPath.row].effect;
    cell.needChangeSelectedTitleColor = YES;
    [cell setIsCurrent:([self.selectedIndexPath isEqual:indexPath]) animated:NO];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.hasSelected = YES;
    if ((indexPath.row >= [[self duetLayoutModels] count])) {
        return;
    }
    
    AWEVoiceChangerCell *voiceCell = (AWEVoiceChangerCell *)[collectionView cellForItemAtIndexPath:indexPath];

    if (self.selectedIndexPath == indexPath) {
        if (voiceCell.isCurrent) {
            return;
        }
    }
    
    self.previousSelectedIndexPath = indexPath;
    IESEffectModel *model = voiceCell.currentEffect;

    if (model.downloadStatus == AWEEffectDownloadStatusDownloading) {
        [self p_clearSeletedCellExcept:voiceCell];
        [voiceCell setIsCurrent:NO animated:NO];
        return;
    }
    if (!model.downloaded || model.downloadStatus == AWEEffectDownloadStatusUndownloaded) {//未下载&不是内置
        model.downloadStatus = AWEEffectDownloadStatusDownloading;
        [self p_clearSeletedCellExcept:voiceCell];
        [voiceCell setIsCurrent:NO animated:NO];
        [self p_selectAndDownloadEffectAtIndexPath:indexPath];
    } else {//已下载
        self.selectedIndexPath = indexPath;
        [self p_selectWithCell:voiceCell model:model indexPath:indexPath];
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[self.delegate duetCommonTrackDic]];
    ACCDuetLayoutModel *duetLayoutModel = [[self.delegate duetLayoutModels] objectAtIndex:indexPath.row];
    params[@"to_status"] = duetLayoutModel.trackModel.name ? duetLayoutModel.trackModel.name : @"";
    [ACCTracker() trackEvent:@"select_duet_layout" params:params needStagingFlag:NO];
}

#pragma mark - private
-(void)p_selectAndDownloadEffectAtIndexPath:(NSIndexPath *)indexPath
{
    AWEVoiceChangerCell *voiceCell = (AWEVoiceChangerCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    IESEffectModel *model = voiceCell.currentEffect;
    
    [voiceCell showLoadingAnimation:YES];
    @weakify(self);
    @weakify(voiceCell);
    [EffectPlatform downloadEffect:model downloadQueuePriority:NSOperationQueuePriorityHigh downloadQualityOfService:NSQualityOfServiceUtility progress:^(CGFloat progress) {
        AWELogToolDebug(AWELogToolTagEdit, @"process is %.2f",progress);
    } completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
        @strongify(self);
        @strongify(voiceCell);
        if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
            return;
        }
        
        if (!error && filePath) {//下载成功
            model.downloadStatus = AWEEffectDownloadStatusDownloaded;
            if (self.previousSelectedIndexPath == indexPath) {
                self.selectedIndexPath = indexPath;
                acc_dispatch_main_async_safe(^{
                    [self p_selectWithCell:voiceCell model:model indexPath:indexPath];
                });
            }
        } else {//下载失败
            model.downloadStatus = AWEEffectDownloadStatusUndownloaded;
            
            acc_dispatch_main_async_safe(^{
                [ACCToast() show:ACCLocalizedCurrentString(@"load_failed")];
            });
        }
        
        acc_dispatch_main_async_safe(^{
            [voiceCell showLoadingAnimation:NO];
        });
    }];
}

- (void)p_selectWithCell:(AWEVoiceChangerCell *)voiceCell model:(IESEffectModel *)model indexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(duetLayoutController:didSelectDuetLayoutAtIndex:)]) {
        [self.delegate duetLayoutController:self didSelectDuetLayoutAtIndex:indexPath.row];
    }
    [self p_clearSeletedCellExcept:voiceCell];
    [voiceCell setIsCurrent:YES animated:NO];
}

- (void)p_clearSeletedCellExcept:(AWEVoiceChangerCell *)cell
{
    for (AWEVoiceChangerCell *voiceCell in [self.collectionView visibleCells]) {
        if (voiceCell != cell) {
            [voiceCell setIsCurrent:NO animated:NO];
        }
    }
}

- (void)p_updateSwitchButton
{
    ACCDuetLayoutModel *model = [self duetLayoutModelAtIndex:self.currentSelectedIndex];
    if (!model || !model.enable) {
        self.switchButton.hidden = YES;
        return;
    }
    NSString *imageName = nil;
    NSString *title = nil;
    if (model.switchType == ACCDuetLayoutSwitchTypeLeftRight) {
        imageName = @"duet_layout_switch_left_right";
        title = ACCLocalizedString(@"duet_switch_left_right", @"Switch");
    } else if (model.switchType == ACCDuetLayoutSwitchTypeTopBottom) {
        imageName = @"duet_layout_switch_up_down";
        title = ACCLocalizedString(@"duet_switch_top_bottom", @"Switch");
    }
    if (!imageName) {
        self.switchButton.hidden = YES;
        return;
    }
    [self.switchButton setImage:ACCResourceImage(imageName) forState:UIControlStateNormal];
    [self.switchButton setTitle:title forState:UIControlStateNormal];
    self.switchButton.hidden = NO;
}

- (void)p_showLoadingView
{
    [self.loadingView removeFromSuperview];
    self.loadingView = nil;
    self.loadingView = [ACCLoading() showLoadingOnView:self.backgroundView];
}

- (void)p_hiddenLoadingView
{
    if (self.loadingView) {
        [self.loadingView removeFromSuperview];
        self.loadingView = nil;
    }
}

- (void)p_shouldShowCameraButton:(BOOL)shown
{
    self.cameraButtonWrapView.hidden = !shown;
}

- (void)p_dismiss
{
    [self p_dismissWithAnimated:YES duration:0.25];
    [self p_shouldShowCameraButton:NO];
}

- (void)p_dismissWithAnimated:(BOOL)animated duration:(NSTimeInterval)duration
{
    if (!self.view.superview) {
        return;
    }
    
    if (animated) {
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            ACCMasUpdate(self.view, {
                make.top.equalTo(@([UIScreen mainScreen].bounds.size.height));
                make.left.equalTo(@0);
            });

            [self p_shouldShowCameraButton:NO];
            [self.view.superview setNeedsLayout];
            [self.view.superview layoutIfNeeded];
        } completion:^(BOOL finished) {
            [self.view removeFromSuperview];
            if (self.dissmissBlock) {
                self.dissmissBlock();
            }
        }];
    } else {
        ACCMasUpdate(self.view, {
            make.top.equalTo(@([UIScreen mainScreen].bounds.size.height));
            make.left.equalTo(@0);
        });
        [self p_shouldShowCameraButton:NO];
        [self.view.superview setNeedsLayout];
        [self.view.superview layoutIfNeeded];
        [self.view removeFromSuperview];
        if (self.dissmissBlock) {
            self.dissmissBlock();
        }
    }
}

- (void)p_showOnView:(UIView *)superview fromOffset:(CGPoint)offset animated:(BOOL)animated duration:(NSTimeInterval)duration
{
    if (!superview) {
        return;
    }
    
    if (self.view.superview) {
        [self.view removeFromSuperview];
    }
    
    [superview addSubview:self.view];
    [superview bringSubviewToFront:self.view];
    
    if (animated) {
        [self p_moveToOffset:offset];
        [UIView animateWithDuration:duration animations:^{
            [self p_moveToOffset:CGPointZero];
        } completion:^(BOOL finished) {
            [self p_shouldShowCameraButton:YES];
        }];
    } else {
        [self p_moveToOffset:CGPointZero];
        [self p_shouldShowCameraButton:YES];
    }
}

- (void)p_moveToOffset:(CGPoint)offset
{
    ACCMasUpdate(self.view, {
        make.top.equalTo(@(offset.y));
        make.left.equalTo(@(offset.x));
    });
    [self.view.superview setNeedsLayout];
    [self.view.superview layoutIfNeeded];
}

- (NSArray *)duetLayoutModels
{
    return self.delegate ? [self.delegate duetLayoutModels] : nil;
}

- (ACCDuetLayoutModel *)duetLayoutModelAtIndex:(NSInteger)index
{
    NSArray *models = [self duetLayoutModels];
    return index < models.count ? [models objectAtIndex:index] : nil;
}

#pragma mark - actions
- (void)didTapOnSwitchButton:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(duetLayoutController:didSwitchDuetLayoutAtIndex:)]) {
        [self.delegate duetLayoutController:self didSwitchDuetLayoutAtIndex:self.currentSelectedIndex];
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[self.delegate duetCommonTrackDic]];
    ACCDuetLayoutModel *model = [self duetLayoutModelAtIndex:self.selectedIndexPath.row];
    
    NSString *shootAt = nil;
    NSInteger index = model.toggled ? 1 : 0;
    if (index < model.trackModel.shootAtList.count) {
        shootAt = [model.trackModel.shootAtList objectAtIndex:index];
    }
    params[@"shoot_at"] = shootAt ?: @"";
    [ACCTracker() trackEvent:@"switch_duet_layout" params:params needStagingFlag:NO];
}

- (void)didTapOnRetryButton:(UIButton *)sender
{
    self.netErrorRetryContainerView.hidden = YES;
    if ([self.delegate respondsToSelector:@selector(duetLayoutController:didTapOnRetryButton:)]) {
        [self.delegate duetLayoutController:self didTapOnRetryButton:sender];
    }
    [self p_showLoadingView];
}

- (void)cameraButtonPressed:(UIButton *)button
{
    BOOL shouldSwitchPosition = button.alpha == 1.0;
    if (shouldSwitchPosition) {
        [button acc_counterClockwiseRotate];
        if ([self.delegate respondsToSelector:@selector(duetLayoutController:didTapOnSwappedCameraButton:)]) {
            [self.delegate duetLayoutController:self didTapOnSwappedCameraButton:button];
        }
    } else {
        ACCBLOCK_INVOKE(button.acc_disableBlock);
    }
}

#pragma mark - setters
- (UIButton *)backButton
{
    if (!_backButton) {
        _backButton = [[UIButton alloc] init];
        [_backButton addTarget:self action:@selector(didTapBackButton:) forControlEvents:UIControlEventTouchUpInside];
        _backButton.isAccessibilityElement = YES;
        _backButton.accessibilityLabel = @"返回";
    }
    return _backButton;
}

- (UIView *)contentContainerView
{
    if (!_contentContainerView) {
        _contentContainerView = [[UIView alloc] initWithFrame:CGRectZero];
        _contentContainerView.backgroundColor = [UIColor clearColor];
    }
    return _contentContainerView;
}

-(UIView *)backgroundView
{
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] init];
        _backgroundView.backgroundColor = ACCResourceColor(ACCColorBGCreation2);
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, ACC_SCREEN_WIDTH, kDeutLayoutPanelViehHeight - kDeutLayoutPanelViewSwitchButtonHeight + ACC_IPHONE_X_BOTTOM_OFFSET) byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(12, 12)];
        maskLayer.path = [path CGPath];
        _backgroundView.layer.mask = maskLayer;
        [_backgroundView acc_addBlurEffect];
    }
    return _backgroundView;
}

- (UIView *)netErrorRetryContainerView
{
    if (!_netErrorRetryContainerView) {
        _netErrorRetryContainerView = [[UIView alloc] init];
        _netErrorRetryContainerView.backgroundColor = [UIColor clearColor];
        _netErrorRetryContainerView.hidden = YES;
    }
    return _netErrorRetryContainerView;
}

- (UILabel *)netErrorTipsLabel
{
    if (!_netErrorTipsLabel) {
        _netErrorTipsLabel = [[UILabel alloc] init];
        _netErrorTipsLabel.text = ACCLocalizedString(@"emoji_network_error", @"网络加载失败，请稍后重试");
        _netErrorTipsLabel.font = [UIFont systemFontOfSize:14];
        _netErrorTipsLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse3);
        _netErrorTipsLabel.backgroundColor = [UIColor clearColor];
        _netErrorTipsLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _netErrorTipsLabel;
}

- (UIButton *)netErrorRetryButton
{
    if (!_netErrorRetryButton) {
        _netErrorRetryButton = [[UIButton alloc] init];
        [_netErrorRetryButton addTarget:self action:@selector(didTapOnRetryButton:) forControlEvents:UIControlEventTouchUpInside];
        [_netErrorRetryButton.titleLabel setFont:[ACCFont() systemFontOfSize:15.0 weight:ACCFontWeightRegular]];
        [_netErrorRetryButton setTitle:ACCLocalizedString(@"publish_retry", @"Retry") forState:UIControlStateNormal];
        [_netErrorRetryButton setTitleColor:ACCResourceColor(ACCUIColorConstTextInverse2) forState:UIControlStateNormal];
        _netErrorRetryButton.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainerInverse);
    }
    return _netErrorRetryButton;
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize =  CGSizeMake(60, 90);
        layout.minimumInteritemSpacing = 8;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.allowsMultipleSelection = NO;
        _collectionView.clipsToBounds = NO;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.clipsToBounds = YES;
        _collectionView.backgroundColor = [UIColor clearColor];
        [_collectionView registerClass:[AWEVoiceChangerCell class] forCellWithReuseIdentifier:NSStringFromClass([AWEVoiceChangerCell class])];
    }
    return _collectionView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = ACCLocalizedString(@"duet_layout_entrance", @"Layout");
        _titleLabel.font = [UIFont systemFontOfSize:15];
        _titleLabel.font = [ACCFont() systemFontOfSize:15.0 weight:ACCFontWeightRegular];
        _titleLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UIButton *)switchButton
{
    if (!_switchButton) {
        _switchButton = [[UIButton alloc] init];
        [_switchButton addTarget:self action:@selector(didTapOnSwitchButton:) forControlEvents:UIControlEventTouchUpInside];
        [_switchButton.titleLabel setFont:[ACCFont() systemFontOfSize:13.0 weight:ACCFontWeightRegular]];
        [_switchButton setTitleColor:ACCResourceColor(ACCUIColorConstTextInverse2) forState:UIControlStateNormal];
        _switchButton.layer.borderColor = ACCResourceColor(ACCColorConstLineInverse).CGColor;
        _switchButton.layer.cornerRadius = 2;
        _switchButton.layer.borderWidth = 0.5;
        _switchButton.backgroundColor = ACCResourceColor(ACCColorConstBGInverse2);
        [_switchButton setImageEdgeInsets:UIEdgeInsetsMake(0, -2, 0, 2)];
        _switchButton.hidden = YES;
    }
    return _switchButton;
}

- (UIButton *)cameraButton
{
    if (!_cameraButton) {
        _cameraButton = [[UIButton alloc] init];
        _cameraButton.exclusiveTouch = YES;
        _cameraButton.adjustsImageWhenHighlighted = NO;
        [_cameraButton setImage:ACCResourceImage(@"ic_camera_filp") forState:UIControlStateNormal];
        [_cameraButton addTarget:self action:@selector(cameraButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        _cameraButton.accessibilityLabel = ACCLocalizedCurrentString(@"reverse");
    }
    return _cameraButton;
}

- (AWECameraContainerToolButtonWrapView *)cameraButtonWrapView
{
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

-(void)setSelectedIndexPath:(NSIndexPath *)selectedIndexPath
{
    _selectedIndexPath = selectedIndexPath;
    [self p_updateSwitchButton];
}

-(NSInteger)currentSelectedIndex
{
    return self.selectedIndexPath.row;
}

@end
