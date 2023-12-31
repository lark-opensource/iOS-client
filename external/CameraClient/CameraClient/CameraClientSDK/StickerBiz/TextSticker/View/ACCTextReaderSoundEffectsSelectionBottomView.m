//
//  ACCTextReaderSoundEffectsSelectionBottomView.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/2/9.
//

#import "ACCTextReaderSoundEffectsSelectionBottomView.h"

#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>

#import "ACCButton.h"
#import "ACCTextReaderSoundEffectsSelectionBottomCollectionView.h"
#import "ACCTextReaderSoundEffectsSelectionBottomBar.h"
#import "ACCConfigKeyDefines.h"

CGFloat const kACCTextReaderSoundEffectsSelectionBottomViewHeight = 208.0f;
CGFloat const kACCTextReaderSoundEffectsSelectionBottomViewWithBottomBarHeight = 226.0f;

@interface ACCTextReaderSoundEffectsSelectionBottomView ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *finishButton;
@property (nonatomic, strong) ACCTextReaderSoundEffectsSelectionBottomBar *cancelSaveBtnBar;
@property (nonatomic, strong) ACCTextReaderSoundEffectsSelectionBottomCollectionView *collectionView;
@property (nonatomic, strong) UIView *loadingViewContainerView;
@property (nonatomic, strong) UIView<ACCTextLoadingViewProtcol> *loadingView;
@property (nonatomic, assign, getter=isUsingOwnAudioPlayer) BOOL usingOwnAudioPlayer;
@property (nonatomic, assign) ACCTextReaderSoundEffectsSelectionBottomViewType viewType;

@end

@implementation ACCTextReaderSoundEffectsSelectionBottomView

- (instancetype)initWithFrame:(CGRect)frame
                         type:(ACCTextReaderSoundEffectsSelectionBottomViewType)type
        isUsingOwnAudioPlayer:(BOOL)isUsingOwnAudioPlayer
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUsingOwnAudioPlayer:isUsingOwnAudioPlayer];
        self.viewType = type;
    }
    return self;
}

#pragma mark - Public Methods

- (void)setupUI
{
    if (self.viewType == ACCTextReaderSoundEffectsSelectionBottomViewTypeNormal) {
        [self p_setupUIWithoutBottomBar];
    } else if (self.viewType == ACCTextReaderSoundEffectsSelectionBottomViewTypeBottomBar) {
        [self p_setupUIWithBottomBar];
    }
}

- (void)didTapFinishButton:(nullable id)sender
{
    if (!self.loadingViewContainerView.isHidden) {
        return;
    }
    [self.collectionView prepareForClosing];
    ACCBLOCK_INVOKE(self.didTapFinishCallback,
                    self.collectionView.selectedAudioFilePath,
                    self.collectionView.selectedAudioSpeakerID,
                    self.collectionView.selectedAudioSpeakerName);
}

#pragma mark - Private Methods

- (void)p_showLoadingView
{
    self.loadingViewContainerView.hidden = NO;
    self.loadingView = [ACCLoading() showTextLoadingOnView:self.loadingViewContainerView
                                                     title:@"音色加载中"
                                                  animated:YES];
    self.collectionView.hidden = YES;
}

- (void)p_hideLoadingView
{
    [self.loadingView dismiss];
    self.loadingViewContainerView.hidden = YES;
    self.collectionView.hidden = NO;
}

- (void)p_setupUIWithBottomBar
{
    self.backgroundColor = ACCResourceColor(ACCColorBGCreation2);
    
    /* corner radius */
    if (@available(iOS 11.0, *)) {
        self.layer.cornerRadius = 10;
        self.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    } else {
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                                byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                                                      cornerRadii:CGSizeMake(10, 10)].CGPath;
        self.layer.mask = shapeLayer;
    }
    
    [self addSubview:self.titleLabel];
    [self addSubview:self.collectionView];
    [self addSubview:self.loadingViewContainerView];
    [self addSubview:self.cancelSaveBtnBar];
    
    ACCMasMaker(self.titleLabel, {
        make.top.mas_equalTo(self).offset(17.5);
        make.leading.mas_equalTo(self).offset(16);
        make.height.mas_equalTo(@17);
    });
    
    ACCMasMaker(self.collectionView, {
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(16);
        make.leading.mas_equalTo(self);
        make.bottom.equalTo(self.cancelSaveBtnBar.mas_top);
        make.trailing.mas_equalTo(self);
    });
    
    ACCMasMaker(self.loadingViewContainerView, {
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(8);
        make.leading.mas_equalTo(self);
        make.bottom.equalTo(self.cancelSaveBtnBar.mas_top);
        make.trailing.mas_equalTo(self);
    });
    
    ACCMasMaker(self.cancelSaveBtnBar, {
        make.leading.trailing.equalTo(self);
        if (@available(iOS 11.0, *)) {
            make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom);
        } else {
            make.bottom.equalTo(self);
        }
        make.height.equalTo(@(kACCTextReaderSoundEffectsSelectionBottomBarHeight));
    });
    
    [self p_setupUIOptimization];
}

- (void)p_setupUIWithoutBottomBar
{
    self.backgroundColor = ACCResourceColor(ACCColorBGCreation2);
    
    /* corner radius */
    if (@available(iOS 11.0, *)) {
        self.layer.cornerRadius = 10;
        self.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    } else {
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(10, 10)].CGPath;
        self.layer.mask = shapeLayer;
    }
    
    [self addSubview:self.titleLabel];
    [self addSubview:self.finishButton];
    [self addSubview:self.collectionView];
    [self addSubview:self.loadingViewContainerView];
    
    ACCMasMaker(self.titleLabel, {
        make.top.mas_equalTo(self).offset(17.5);
        make.leading.mas_equalTo(self).offset(16);
        make.height.mas_equalTo(@17);
    });
    
    ACCMasMaker(self.finishButton, {
        make.centerY.mas_equalTo(self.titleLabel);
        make.trailing.mas_equalTo(self).offset(-16);
        make.height.mas_equalTo(@28);
    });
    
    ACCMasMaker(self.collectionView, {
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(16);
        make.leading.mas_equalTo(self);
        if (@available(iOS 11.0, *)) {
            make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-8);
        } else {
            make.bottom.equalTo(self).offset(-8);
        }
        make.trailing.mas_equalTo(self);
    });
    
    ACCMasMaker(self.loadingViewContainerView, {
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(8);
        make.leading.mas_equalTo(self);
        if (@available(iOS 11.0, *)) {
            make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-8);
        } else {
            make.bottom.equalTo(self).offset(-8);
        }
        make.trailing.mas_equalTo(self);
    });
}

#pragma mark - Getters and Setters

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        [_titleLabel setText:@"选择文本朗读音色"];
        [_titleLabel setTextColor:ACCResourceColor(ACCUIColorConstTextInverse)];
        [_titleLabel setFont:[ACCFont() acc_systemFontOfSize:13.0 weight:ACCFontWeightMedium]];
    }
    return _titleLabel;
}

- (UIButton *)finishButton
{
    if (!_finishButton) {
        _finishButton = [ACCButton buttonWithSelectedAlpha:0.5];
        [_finishButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [_finishButton setTitle:@"完成" forState:UIControlStateNormal];
        UIImage *image = [UIImage acc_imageWithName:@"ic_camera_save"];
        [_finishButton setImage:image forState:UIControlStateNormal];
        [_finishButton setImage:image forState:UIControlStateHighlighted];
        [_finishButton setTitleColor:ACCResourceColor(ACCUIColorConstTextInverse) forState:UIControlStateNormal];
        [_finishButton setBackgroundColor:ACCResourceColor(ACCColorConstBGContainer5)];
        _finishButton.titleLabel.font = [ACCFont() acc_boldSystemFontOfSize:13];
        _finishButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _finishButton.contentEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4);
        _finishButton.imageEdgeInsets = UIEdgeInsetsMake(2, 0, 2, 4);
        _finishButton.titleEdgeInsets = UIEdgeInsetsMake(4, 0, 4, 0);
        _finishButton.layer.cornerRadius = 2;
        [_finishButton addTarget:self action:@selector(didTapFinishButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _finishButton;
}

- (ACCTextReaderSoundEffectsSelectionBottomCollectionView *)collectionView
{
    if (!_collectionView) {
        _collectionView = [[ACCTextReaderSoundEffectsSelectionBottomCollectionView alloc] init];
        [_collectionView setUsingOwnAudioPlayer:self.isUsingOwnAudioPlayer];
        @weakify(self);
        _collectionView.getTextReaderModelBlock = ^AWETextStickerReadModel * _Nonnull {
            @strongify(self);
            return ACCBLOCK_INVOKE(self.getTextReaderModelBlock);
        };
        _collectionView.didSelectSoundEffectCallback = ^(NSString * _Nonnull audioFilePath, NSString * _Nonnull audioSpeakerID) {
            @strongify(self);
            ACCBLOCK_INVOKE(self.didSelectSoundEffectCallback, audioFilePath, audioSpeakerID);
        };
        _collectionView.showLoadingView = ^{
            @strongify(self);
            [self p_showLoadingView];
        };
        _collectionView.hideLoadingView = ^{
            @strongify(self);
            [self p_hideLoadingView];
        };
    }
    return _collectionView;
}

- (UIView *)loadingViewContainerView
{
    if (!_loadingViewContainerView) {
        _loadingViewContainerView = [[UIView alloc] init];
    }
    return _loadingViewContainerView;
}

- (ACCTextReaderSoundEffectsSelectionBottomBar *)cancelSaveBtnBar
{
    if (!_cancelSaveBtnBar) {
        _cancelSaveBtnBar = [[ACCTextReaderSoundEffectsSelectionBottomBar alloc] init];
        @weakify(self);
        _cancelSaveBtnBar.didTapCancelButtonBlock = ^{
            @strongify(self);
            ACCBLOCK_INVOKE(self.didTapCancelCallback);
        };
        _cancelSaveBtnBar.didTapSaveButtonBlock = ^{
            @strongify(self);
            ACCBLOCK_INVOKE(self.didTapFinishCallback,
                            self.collectionView.selectedAudioFilePath,
                            self.collectionView.selectedAudioSpeakerID,
                            self.collectionView.selectedAudioSpeakerName);
        };
    }
    return _cancelSaveBtnBar;
}

- (UIView *)cancelSaveBtnBarView
{
    return self.cancelSaveBtnBar;
}

#pragma mark - UI Optimization

/// Adjust UI according to AB
- (void)p_setupUIOptimization
{
    if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypeDisabled) {
        [self p_setupUIOptimizationPlayBtn:NO];
        [self p_setupUIOptimizationSaveCancelBtn:NO];
    } else if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypeSaveCancelBtn) {
        [self p_setupUIOptimizationPlayBtn:NO];
        [self p_setupUIOptimizationSaveCancelBtn:YES];
        [self p_setupUIOptimizationReplaceIconWithText:YES];
    } else if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypePlayBtn) {
        [self p_setupUIOptimizationPlayBtn:YES];
        [self p_setupUIOptimizationSaveCancelBtn:YES];
        [self p_setupUIOptimizationReplaceIconWithText:YES];
    } else if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypeReplaceIconWithText) {
        [self p_setupUIOptimizationPlayBtn:YES];
        [self p_setupUIOptimizationSaveCancelBtn:YES];
        [self p_setupUIOptimizationReplaceIconWithText:NO];
    }
}

- (void)p_setupUIOptimizationSaveCancelBtn:(BOOL)shouldOptimized
{
    if (shouldOptimized) {
        self.cancelSaveBtnBar.lineView.hidden = YES;
        self.cancelSaveBtnBar.titleLbl.hidden = YES;
        
        ACCMasReMaker(self.cancelSaveBtnBar, {
            make.top.leading.trailing.equalTo(self);
            make.height.equalTo(@(kACCTextReaderSoundEffectsSelectionBottomBarHeight));
        });
        
        ACCMasReMaker(self.titleLabel, {
            make.top.mas_equalTo(self.cancelSaveBtnBar.mas_bottom);
            make.leading.mas_equalTo(self).offset(16);
            make.height.mas_equalTo(@52);
        });
        
        ACCMasReMaker(self.collectionView, {
            make.top.mas_equalTo(self.titleLabel.mas_bottom);
            make.leading.mas_equalTo(self);
            if (@available(iOS 11.0, *)) {
                make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom);
            } else {
                make.bottom.equalTo(self);
            }
            make.trailing.mas_equalTo(self);
        });
        
        ACCMasReMaker(self.loadingViewContainerView, {
            make.top.leading.bottom.trailing.mas_equalTo(self.collectionView);
        });
    }
}

- (void)p_setupUIOptimizationPlayBtn:(BOOL)shouldOptimized
{
    if (shouldOptimized) {
        
    } else {
        
    }
}

- (void)p_setupUIOptimizationReplaceIconWithText:(BOOL)shouldUseText
{
    if (shouldUseText) {
        [self.cancelSaveBtnBar.cancelBtn setImage:nil forState:UIControlStateNormal];
        [self.cancelSaveBtnBar.cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        self.cancelSaveBtnBar.cancelBtn.titleLabel.font = [ACCFont() acc_systemFontOfSize:17];
        [self.cancelSaveBtnBar.cancelBtn.titleLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        ACCMasReMaker(self.cancelSaveBtnBar.cancelBtn, {
            make.height.mas_equalTo(@24);
            make.top.mas_equalTo(@14);
            make.left.mas_equalTo(@16);
        });
        
        [self.cancelSaveBtnBar.saveBtn setImage:nil forState:UIControlStateNormal];
        [self.cancelSaveBtnBar.saveBtn setTitle:@"保存" forState:UIControlStateNormal];
        self.cancelSaveBtnBar.saveBtn.titleLabel.font = [ACCFont() acc_systemFontOfSize:17];
        [self.cancelSaveBtnBar.saveBtn.titleLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        ACCMasReMaker(self.cancelSaveBtnBar.saveBtn, {
            make.height.mas_equalTo(@24);
            make.top.mas_equalTo(@14);
            make.trailing.mas_equalTo(@-16);
        });
    } else {
        [self.cancelSaveBtnBar.cancelBtn setImage:ACCResourceImage(@"icon_edit_bar_cancel") forState:UIControlStateNormal];
        [self.cancelSaveBtnBar.saveBtn setImage:ACCResourceImage(@"icon_edit_bar_done") forState:UIControlStateNormal];
    }
}

@end
