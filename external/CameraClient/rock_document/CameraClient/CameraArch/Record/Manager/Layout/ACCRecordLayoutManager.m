//
//  ACCRecordLayoutManager.m
//  Pods
//
//  Created by Shen Chen on 2020/3/30.
//

#import "ACCRecordLayoutManager.h"

#import <CameraClient/AWEXScreenAdaptManager.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCLayoutViewTypeDefines.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <Masonry/View+MASAdditions.h>

#pragma mark - UIView Category

@interface UIView (OriginalAlpha)

@property (nonatomic, assign) CGFloat acc_originalAlpha;

@end

@implementation UIView (OriginalAlpha)

- (CGFloat)acc_originalAlpha {
     return [objc_getAssociatedObject(self, @"acc_originalAlpha") floatValue];
}

- (void)setAcc_originalAlpha:(CGFloat)acc_originalAlpha
{
    objc_setAssociatedObject(self, @"acc_originalAlpha", [NSNumber numberWithFloat:acc_originalAlpha], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark - ACCRecordLayoutManager

typedef void(^ACCApplySubviewBlock)(UIView *subview);

@interface ACCRecordLayoutManager()
@property (nonatomic, strong) ACCRecordLayoutGuide *guide;
@property (nonatomic, assign) BOOL isLoaded;
@property (nonatomic, strong) NSMapTable<ACCViewType, UIView *> *subviewsMapTable;
@property (nonatomic, strong) NSMapTable<ACCViewType, ACCApplySubviewBlock> *applySubviewMapTable;

@property (nonatomic, weak) UIView *quickAlbumView;
@property (nonatomic, weak) UIView *uploadVideoButton;
@property (nonatomic, weak) UIView *uploadVideoLabel;
@property (nonatomic, weak) UIView *stickerSwitchButton;
@property (nonatomic, weak) UIView *stickerSwitchLabel;
@property (nonatomic, weak) UIView *recordShowTipButton;
@property (nonatomic, weak) UIView *switchLengthView;
@property (nonatomic, weak) UIView *timeLabel;
@property (nonatomic, weak) UIView *completeButton;
@property (nonatomic, weak) UIView *deleteButton;
@property (nonatomic, weak) UIView *speedControl;
@property (nonatomic, weak) UIView *commerceEnterView;
@property (nonatomic, weak) UIView *exposePropPanelTrayView;
@property (nonatomic, weak) UIView *addFeedMusicView;
@property (nonatomic, weak) UIView *recordButton;
@property (nonatomic, weak) UIView *selectMusicButton;
@property (nonatomic, weak) UIView *closeButton;
@property (nonatomic, weak) UIView *uploadMaskView;
@property (nonatomic, weak) UIView *multiSegPropContainerView;

@end

@implementation ACCRecordLayoutManager

- (instancetype)init
{
    if (self = [super init]) {
        _subviewsMapTable = [NSMapTable strongToWeakObjectsMapTable];
        _applySubviewMapTable = [NSMapTable strongToStrongObjectsMapTable];
        [self configSubviewMapTable];
    }
    return self;
}

- (void)configSubviewMapTable
{
    @weakify(self);
    [self.applySubviewMapTable setObject:^void(UIView *subview) {
        @strongify(self);
        self.recordButtonSwitchView = subview;
    } forKey:ACCViewTypeSwitchMode];

    [self.applySubviewMapTable setObject:^void(UIView *subview) {
        @strongify(self);
        self.uploadVideoButton = subview;
    } forKey:ACCViewTypeUploadVideoButton];
    
    [self.applySubviewMapTable setObject:^void(UIView *subview) {
        @strongify(self);
        self.uploadVideoLabel = subview;
    } forKey:ACCViewTypeUploadVideoLabel];
    
    [self.applySubviewMapTable setObject:^void(UIView *subview) {
        @strongify(self);
        self.stickerSwitchButton = subview;
    } forKey:ACCViewTypeStickerSwitchButton];
    
    [self.applySubviewMapTable setObject:^void(UIView *subview) {
        @strongify(self);
        self.stickerSwitchLabel = subview;
    } forKey:ACCViewTypeStickerSwitchLabel];

    [self.applySubviewMapTable setObject:^void(UIView *subview) {
        @strongify(self);
        self.recordShowTipButton = subview;
    } forKey:ACCViewTypeShowTipButton];
    
    [self.applySubviewMapTable setObject:^void(UIView *subview) {
        @strongify(self);
        self.switchLengthView = subview;
    } forKey:ACCViewTypeSwitchSubmodeView];
    
    [self.applySubviewMapTable setObject:^void(UIView *subview) {
        @strongify(self);
        self.timeLabel = subview;
    } forKey:ACCViewTypeTimeLabel];
    
    [self.applySubviewMapTable setObject:^void(UIView *subview) {
        @strongify(self);
        self.completeButton = subview;
    } forKey:ACCViewTypeCompleteButton];
    
    [self.applySubviewMapTable setObject:^void(UIView *subview) {
        @strongify(self);
        self.deleteButton = subview;
    } forKey:ACCViewTypeDeleteButton];
    
    [self.applySubviewMapTable setObject:^void(UIView *subview) {
        @strongify(self);
        self.speedControl = subview;
    } forKey:ACCViewTypeSpeedControl];
    
    [self.applySubviewMapTable setObject:^void(UIView *subview) {
        @strongify(self);
        self.exposePropPanelTrayView = subview;
    } forKey:ACCViewTypeExposePropPanel];
    
    [self.applySubviewMapTable setObject:^void(UIView *subview) {
        @strongify(self);
        self.commerceEnterView = subview;
    } forKey:ACCViewTypeCommerceEnter];
    
    [self.applySubviewMapTable setObject:^void(UIView *subview) {
        @strongify(self);
        self.addFeedMusicView = subview;
    } forKey:ACCViewTypeAddFeedMusic];
    
    [self.applySubviewMapTable setObject:^void(UIView *subview) {
        @strongify(self);
        self.recordButton = subview;
    } forKey:ACCViewTypeRecordButton];
    
    [self.applySubviewMapTable setObject:^void(UIView *subview) {
        @strongify(self);
        self.selectMusicButton = subview;
    } forKey:ACCViewTypeSelectMusic];
    
    [self.applySubviewMapTable setObject:^void(UIView *subview) {
        @strongify(self);
        self.closeButton = subview;
    } forKey:ACCViewTypeClose];
    
    [self.applySubviewMapTable setObject:^void(UIView *subview) {
        @strongify(self);
        self.quickAlbumView = subview;
    } forKey:ACCViewTypeQuickAlbum];
    
    [self.applySubviewMapTable setObject:^void(UIView *subview) {
        @strongify(self);
        self.uploadMaskView = subview;
    } forKey:ACCViewTypeUploadMask];

    [self.applySubviewMapTable setObject:^void(UIView *subview) {
        @strongify(self);
        self.multiSegPropContainerView = subview;
    } forKey:ACCViewTypeMultiSegProp];
}

#pragma mark - ACCLayoutContainerProtocolD

- (void)addSubview:(UIView *)subview viewType:(ACCViewType)viewType
{
    if (![self.subviewsMapTable objectForKey:viewType]) {
        [self.subviewsMapTable setObject:subview forKey:viewType];
    }
    
    ACCApplySubviewBlock subviewBlock = [self.applySubviewMapTable objectForKey:viewType];
    ACCBLOCK_INVOKE(subviewBlock, subview);
 }

- (void)removeSubviewType:(ACCViewType)viewType
{
    [self.subviewsMapTable removeObjectForKey:viewType];
}

- (UIView *)viewForType:(ACCViewType)viewType
{
    return [self.subviewsMapTable objectForKey:viewType];
}

#pragma mark - Life Cycle

- (void)containerViewControllerDidLoad
{
    
}

- (void)containerViewControllerPostDidLoad
{
    [self layoutRecordButton];
    [self layoutRecordButtonSwitchView];
    [self layoutSwitchLengthView];
    [self layoutTimeLabel];
    [self layoutUploadVideoButton];
    [self layoutUploadVideoLabel];
    [self p_layoutStickerInteractionContainerView];
    [self layoutStickerSwitchButton];
    [self layoutStickerSwitchLabel];
    [self layoutDeleteButton];
    [self layoutCompleteButton];
    [self layoutSpeedControl];
    [self layoutCommerceEnterView];
    [self layoutMultiSegPropView];
    [self layoutCloseButton];
    [self p_layoutStickerInteractionContainerView];
    self.isLoaded = YES;
}

- (void)applicationDidBecomeActive
{
    
}

#pragma mark - Public

- (void)updateCommerceEnterButton
{
    if (self.isLoaded) {
        CGFloat y = [self commerceEnterViewTop];
        ACCMasUpdate(self.commerceEnterView, {
            make.top.equalTo(@(y));
        });
    }
}

- (void)showSpeedControl:(BOOL)show animated:(BOOL)animated
{
    [self updateAddFeedMusicViewLayoutWithShowSpeedControl:show];
    if (animated) {
        if (show) {
            self.speedControl.hidden = NO;
        }
        [UIView animateWithDuration:0.15 animations:^{
            self.speedControl.alpha = show ? 1 : 0;
            [self.interactionView layoutIfNeeded];
            [self layoutSpeedControl];
        }];
    } else {
        if (self.speedControl.hidden && show) {
            self.speedControl.hidden = NO;
        }
        self.speedControl.alpha = show ? 1 : 0;
        [self.interactionView layoutIfNeeded];
        [self layoutSpeedControl];
    }
}

- (void)updateSwitchModeView
{
}

#pragma mark - Getter & Setter

- (id<ACCRecordLayoutGuideProtocol>)guide
{
    if (_guide == nil) {
        ACCRecordLayoutGuide *guide = [[ACCRecordLayoutGuide alloc] init];
        guide.containerView = self.interactionView;
        _guide = guide;
    }
    return _guide;
}

- (void)setRecordButtonSwitchView:(UIView *)recordButtonSwitchView
{
    _recordButtonSwitchView = recordButtonSwitchView;
    if (self.isLoaded) {
        [self layoutRecordButtonSwitchView];
    }
}

- (void)setSwitchLengthView:(UIView *)switchLengthView
{
    _switchLengthView = switchLengthView;
    if (self.isLoaded) {
        [self layoutSwitchLengthView];
    }
}

- (void)setMultiSegPropContainerView:(UIView *)multiSegPropView
{
    _multiSegPropContainerView = multiSegPropView;
    if (self.isLoaded) {
        [self layoutMultiSegPropView];
    }
}

- (void)setTimeLabel:(UILabel *)timeLabel {
    _timeLabel = timeLabel;
    if (self.isLoaded) {
        [self layoutTimeLabel];
    }
}

- (void)setUploadVideoLabel:(UILabel *)uploadVideoLabel
{
    _uploadVideoLabel = uploadVideoLabel;
    if (self.isLoaded) {
        [self layoutUploadVideoLabel];
    }
}

- (void)setUploadVideoButton:(UIButton *)uploadVideoButton
{
    _uploadVideoButton = uploadVideoButton;
    if (self.isLoaded) {
        [self layoutUploadVideoButton];
    }
}

- (void)setStickerSwitchLabel:(UILabel *)stickerSwitchLabel
{
    _stickerSwitchLabel = stickerSwitchLabel;
    if (self.isLoaded) {
        [self layoutStickerSwitchLabel];
    }
}

- (void)setStickerSwitchButton:(UIButton *)stickerSwitchButton
{
    _stickerSwitchButton = stickerSwitchButton;
    if (self.isLoaded) {
        [self layoutStickerSwitchButton];
    }
}

- (void)setStickerContainerView:(UIView *)stickerContainerView
{
    _stickerContainerView = stickerContainerView;
    _stickerContainerView.acc_originalAlpha = 1;
    if (self.isLoaded) {
        [self p_layoutStickerInteractionContainerView];
    }
}

- (void)setDeleteButton:(UIButton *)deleteButton
{
    _deleteButton = deleteButton;
    if (self.isLoaded) {
        [self layoutDeleteButton];
    }
}

- (void)setCompleteButton:(UIButton *)completeButton
{
    _completeButton = completeButton;
    if (self.isLoaded) {
        [self layoutDeleteButton];
    }
}

- (void)setSpeedControl:(UIView *)speedControl
{
    _speedControl = speedControl;
    if (self.isLoaded) {
        [self layoutSpeedControl];
    }
}

- (void)setCommerceEnterView:(UIView *)commerceEnterView
{
    _commerceEnterView = commerceEnterView;
    if (self.isLoaded) {
        [self layoutCommerceEnterView];
    }
}

- (void)setAddFeedMusicView:(UIView *)addFeedMusicView
{
    _addFeedMusicView = addFeedMusicView;
    if (self.isLoaded) {
        [self layoutAddFeedMusicView];
    }
}

- (void)setQuickAlbumView:(UIView *)quickAlbumView
{
    _quickAlbumView = quickAlbumView;
    if (self.isLoaded) {
        [self layoutQuickAlbumView];
    }
}

- (void)setExposePropPanelTrayView:(UIView *)exposePropPanelTrayView
{
    _exposePropPanelTrayView = exposePropPanelTrayView;
    if (self.isLoaded) {
        [UIView animateWithDuration:0.3f animations:^{
            [self layoutSpeedControl];
            [self updateCommerceEnterButton];
        }];
    }
}

- (void)setCloseButton:(UIButton *)closeButton
{
    _closeButton = closeButton;
    if (self.isLoaded) {
        [self layoutCloseButton];
    }
}

#pragma mark - layout views

static const CGFloat kRecordButtonWidth = 80;
static const CGFloat kRecordButtonHeight = kRecordButtonWidth;

- (void)layoutRecordButton
{
    self.recordButton.frame = [self recordButtonFrame];
}

- (CGRect)recordButtonFrame
{
    CGFloat shiftToTop = 14;
    if ([AWEXScreenAdaptManager needAdaptScreen] && !(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize) & ACCViewFrameOptimizeFullDisplay)) {
        shiftToTop = -12;
    }
    return CGRectMake((ACC_SCREEN_WIDTH - kRecordButtonWidth)/2, ACC_SCREEN_HEIGHT + [self.guide recordButtonBottomOffset] - kRecordButtonHeight + ([UIDevice acc_isIPhoneX] ? shiftToTop : 0), kRecordButtonWidth, kRecordButtonHeight);
}

- (void)layoutRecordButtonSwitchView
{
    [self.modeSwitchView addSubview:self.recordButtonSwitchView];
    CGFloat height = [self.guide recordButtonSwitchViewHeight];
    CGFloat width = CGRectGetWidth(self.interactionView.frame);
    CGFloat frameY = CGRectGetMaxY(self.interactionView.frame) + [self.guide recordButtonSwitchViewBottomOffset] - height;
    CGRect frame = CGRectMake(0, frameY, width, height);
    self.recordButtonSwitchView.frame = frame;
}

- (void)layoutTimeLabel
{
    [self.modeSwitchView addSubview:self.timeLabel];
    if (ACCConfigBool(kConfigBool_enable_lightning_style_record_button)) {
        self.timeLabel.acc_centerX = self.modeSwitchView.acc_centerX;
        CGFloat shiftToTop = 14;
        if ([AWEXScreenAdaptManager needAdaptScreen] && !(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize) & ACCViewFrameOptimizeFullDisplay)) {
            shiftToTop = -12;
        }
        CGFloat height = [self.guide recordButtonHeight];
        CGFloat yFrame = ACC_SCREEN_HEIGHT + [self.guide recordButtonBottomOffset] - height + ([UIDevice acc_isIPhoneX] ? shiftToTop : 0);
        self.timeLabel.acc_bottom = yFrame - 35;
    } else {
        self.timeLabel.acc_centerX = self.modeSwitchView.acc_centerX;
        CGFloat topOffset = 28;
        if ([UIDevice acc_isIPhoneX]) {
            if (@available(iOS 11.0, *)) {
                topOffset += ACC_STATUS_BAR_NORMAL_HEIGHT;
            }
        }

        self.timeLabel.acc_top = topOffset;
    }
}

- (void)layoutSwitchLengthView
{
    [self.modeSwitchView addSubview:self.switchLengthView];
    self.switchLengthView.acc_centerX = self.modeSwitchView.acc_centerX;
    self.switchLengthView.acc_bottom = self.recordButton.acc_top - 8;
}

- (void)layoutMultiSegPropView
{
    [self.modeSwitchView addSubview:self.multiSegPropContainerView];
    self.multiSegPropContainerView.acc_centerX = self.modeSwitchView.acc_centerX;
    self.multiSegPropContainerView.acc_bottom = self.recordButton.acc_top - 34;
}

- (void)layoutUploadVideoButton
{
    [self.interactionView addSubview:self.uploadVideoButton];
    CGFloat h = [self.guide sideButtonHeight];
    CGFloat w = [self.guide sideButtonWidth];
    CGFloat y = [self.guide recordButtonCenterY] - 0.5 * h;
    CGFloat x = [self.guide containerWidth] - [self.guide sideButtonCenterXOffset] - 0.5 * w;
    self.uploadVideoButton.frame = CGRectMake(x, y, w, h);
    if ([self.uploadVideoButton isKindOfClass:[UIButton class]]) {
        ((UIButton *)self.uploadVideoButton).acc_hitTestEdgeInsets = [self.guide hitTestEdgeInsets];
    }
}

- (void)relayoutUploadVideoLabelForPortrait
{
    self.uploadVideoLabel.acc_top = self.uploadVideoButton.acc_bottom + [self.guide sideButtonLabelSpace];
    self.uploadVideoLabel.acc_centerX = self.uploadVideoButton.acc_centerX;
}

- (void)relayoutUploadVideoLabelForLandscapeLeft
{
    self.uploadVideoLabel.acc_right = self.uploadVideoButton.acc_left - [self.guide sideButtonLabelSpace];
    self.uploadVideoLabel.acc_centerY = self.uploadVideoButton.acc_centerY;
}

- (void)layoutUploadVideoLabel
{
    if (ACCConfigBool(kConfigBool_show_title_in_video_camera)) {
        [self.interactionView insertSubview:self.uploadVideoLabel belowSubview:self.uploadVideoButton];
        [self.uploadVideoLabel sizeToFit];
        [self relayoutUploadVideoLabelForPortrait];
    }
}

- (void)layoutStickerSwitchButton
{
    [self.interactionView addSubview:self.stickerSwitchButton];
    CGFloat h = [self.guide sideCircleButtonHeight];
    CGFloat w = [self.guide sideCircleButtonWidth];
    CGFloat y = [self.guide recordButtonCenterY] - 0.5 * h;
    CGFloat x = [self.guide sideButtonCenterXOffset] - 0.5 * w;
    self.stickerSwitchButton.frame = CGRectMake(x, y, w, h);
    if ([self.stickerSwitchButton isKindOfClass:[UIButton class]]) {
        ((UIButton *)self.stickerSwitchButton).acc_hitTestEdgeInsets = [self.guide hitTestEdgeInsets];
    }
}

/// stickerContainerView should be placed as low as possible, it should be just above the preview view
- (void)p_layoutStickerInteractionContainerView
{
    if (!self.stickerContainerView) {
        return;
    }
    [self.interactionView insertSubview:self.stickerContainerView
                           belowSubview:self.recordButton];
}

- (void)relayoutStickerSwitchLabelForPortrait
{
    self.stickerSwitchLabel.acc_top = self.stickerSwitchButton.acc_bottom + [self.guide sideButtonLabelSpace];
    self.stickerSwitchLabel.acc_centerX = self.stickerSwitchButton.acc_centerX;
}

- (void)relayoutStickerSwitchLabelForLandscapeLeft
{
    self.stickerSwitchLabel.acc_right = self.stickerSwitchButton.acc_left - [self.guide sideButtonLabelSpace];
    self.stickerSwitchLabel.acc_centerY = self.stickerSwitchButton.acc_centerY;
}

- (void)layoutStickerSwitchLabel
{
    if (ACCConfigBool(kConfigBool_show_title_in_video_camera)) {
        [self.interactionView insertSubview:self.stickerSwitchLabel belowSubview:self.stickerSwitchButton];
        [self.stickerSwitchLabel sizeToFit];
        [self relayoutStickerSwitchLabelForPortrait];
    }
}

- (void)layoutDeleteButton
{
    [self.interactionView addSubview:self.deleteButton];

    CGFloat space = [self.guide recordFlowControlEvenSpace];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        space = 51.5;
    }
    CGFloat h = [self.guide deleteButtonHeight];
    CGFloat w = [self.guide deleteButtonWidth];
    CGFloat x = 0.5 * [self.guide containerWidth] + 0.5 * [self.guide recordButtonWidth] + space;
    CGFloat y = [self.guide recordButtonCenterY] - 0.5 * h;
    self.deleteButton.frame = CGRectMake(x, y, w, h);
}

- (void)layoutCompleteButton
{
    [self.interactionView addSubview:self.completeButton];

    CGFloat space = [self.guide recordFlowControlEvenSpace];
    CGFloat w = [self.guide completeButtonWidth];
    CGFloat h = [self.guide completeButtonHeight];
    CGFloat x = [self.guide containerWidth] - space - w;
    CGFloat y = [self.guide recordButtonCenterY] - 0.5 * h;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        x = 0.5 * [self.guide containerWidth] + 0.5 * [self.guide recordButtonWidth] + [self.guide deleteButtonWidth] + 51.5 + 41.5;
    }
    self.completeButton.frame = CGRectMake(x, y, w, h);
    self.completeButton.layer.cornerRadius = 0.5 * w;
}

- (void)layoutSpeedControl
{
    if (self.speedControl.superview != self.interactionView) {
        [self.interactionView addSubview:self.speedControl];
    }
    CGFloat w = [self.guide containerWidth] - 2 * [self.guide speedControlMargin];
    CGFloat h = [self.guide speedControlHeight];
    CGFloat x = [self.guide speedControlMargin];
    CGFloat y = [self.guide speedControlTop];
    if (self.exposePropPanelTrayView) {
        y -= 16 + self.exposePropPanelTrayView.acc_height;
    }
    self.speedControl.frame = CGRectMake(x, y, w, h);
    [self.speedControl setNeedsLayout];
    [self.speedControl layoutIfNeeded];
}

- (CGFloat)commerceEnterViewTop
{
    CGFloat h = self.guide.commerceEnterViewHeight;
    CGFloat y = self.guide.recordButtonCenterY - 0.5 * self.guide.recordButtonHeight - self.guide.commerceEnterViewBottomSpace - h;
    if (ACCConfigBool(kConfigBool_enable_story_tab_in_recorder)) {
        y -= 57 - 25; // new distance - old distance with top of recordButton
    }
    
    if (self.exposePropPanelTrayView) {
        y -= 16 + self.exposePropPanelTrayView.acc_height;
    }
    return y;
}

- (void)layoutCommerceEnterView
{
    [self.interactionView addSubview:self.commerceEnterView];
    CGFloat h = self.guide.commerceEnterViewHeight;
    CGFloat y = [self commerceEnterViewTop];
    
    ACCMasMaker(self.commerceEnterView, {
        make.centerX.equalTo(self.interactionView.mas_centerX);
        make.height.equalTo(@(h));
        make.top.equalTo(@(y));
    });
}

- (void)layoutAddFeedMusicView
{
    if (!self.addFeedMusicView) {
        return;
    }
    BOOL showSpeedControl = (self.speedControl.hidden == NO && self.speedControl.alpha == 1);
    CGFloat offset = [self addFeedMusicTopOffsetWithShowSpeedControl:showSpeedControl];
    ACCMasMaker(self.addFeedMusicView, {
        make.centerX.equalTo(self.interactionView);
        make.bottom.equalTo(self.recordButton.mas_top).offset(offset);
    });
}

- (void)layoutQuickAlbumView
{
    if (!self.quickAlbumView) {
        return;
    }
    [self.interactionView insertSubview:self.quickAlbumView belowSubview:self.recordButton];

    CGFloat w = [self.guide containerWidth];
    CGFloat h = 110;
    CGFloat x = 0;
    CGFloat y = [self.guide recordButtonCenterY] - [self.guide recordButtonHeight] * 0.5;
    self.quickAlbumView.frame = CGRectMake(x, y - h, w, h);
}

- (void)layoutCloseButton
{
    self.closeButton.acc_left = self.guide.containerView.acc_left + 6;
    self.closeButton.acc_top = self.guide.containerView.acc_top + 20;
    if ([UIDevice acc_isIPhoneX]) {
        if (@available(iOS 11.0, *)) {
            self.closeButton.acc_top = ACC_STATUS_BAR_NORMAL_HEIGHT + kYValueOfRecordAndEditPageUIAdjustment;
        }
    }
    if ([self.closeButton isKindOfClass:[UIButton class]]) {
        ((UIButton *)self.closeButton).acc_hitTestEdgeInsets = [self.guide hitTestEdgeInsets];
    }
}

- (void)updateAddFeedMusicViewLayoutWithShowSpeedControl:(BOOL)showSpeedControl
{
    if (!self.addFeedMusicView) {
        return;
    }
    CGFloat offset = [self addFeedMusicTopOffsetWithShowSpeedControl:showSpeedControl];
    ACCMasUpdate(self.addFeedMusicView, {
        make.bottom.equalTo(self.recordButton.mas_top).offset(offset);
    });
}

- (CGFloat)addFeedMusicTopOffsetWithShowSpeedControl:(BOOL)showSpeedControl
{
    CGFloat offset = -15;
    if (showSpeedControl) {
        offset = self.speedControl.acc_top - self.recordButton.acc_top + offset;
    }
    return offset;
}

@end
