//
//  ACCRecorderTextModePreviewViewController.m
//  CameraClient-Pods-Aweme
//
//  Created by Yangguocheng on 2020/9/20.
//

#import "ACCRecorderTextModePreviewViewController.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <Masonry/View+MASAdditions.h>
#import "ACCRecorderTextModeGradientView.h"
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CameraClient/AWEXScreenAdaptManager.h>
#import <CreativeKit/ACCMacros.h>
#import "ACCRecordTextModeColorManager.h"
#import <CreativeKitSticker/ACCStickerContainerView.h>
#import "ACCTextStickerEditView.h"
#import "ACCTextStickerConfig.h"
#import <CreationKitArch/AWEInteractionStickerLocationModel+ACCSticker.h>
#import <CreativeKit/UIFont+ACC.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "ACCRecordTextModeColorManager.h"
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitInfra/ACCAlertProtocol.h>
#import "ACCRecorderTextModeStickerContainerConfig.h"
#import "ACCRecordModeBackgroundModelProtocol.h"
#import <BDWebImage/UIImageView+BDWebImage.h>
#import "AWEStoryColorChooseView.h"
#import "AWEStoryFontChooseView.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "ACCTextStickerRecommendDataHelper.h"
#import <CreativeKit/ACCAccessibilityProtocol.h>
#import "ACCMultiStyleAlertProtocol.h"


@interface ACCRecorderTextModePreviewViewController () <ACCStickerContainerDelegate>

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) ACCAnimatedButton *switchColorButton;
@property (nonatomic, strong) ACCAnimatedButton *enterLibButton;
@property (nonatomic, strong) ACCRecorderTextModeGradientView *switchColorGradientView;
@property (nonatomic, strong) ACCRecorderTextModeGradientView *backgroundView;
@property (nonatomic, strong) ACCStickerContainerView *stickerContainerView;
@property (nonatomic, strong) ACCTextStickerEditView *textStickerEditView;
@property (nonatomic, weak) ACCTextStickerView *stickerView;
@property (nonatomic, strong) UILabel *textFunctionHintLabel;
@property (nonatomic, strong) ACCAnimatedButton *nextButton;
@property (nonatomic, strong) ACCAnimatedButton *closeButton;
/// 返回挽留弹窗
@property (nonatomic, strong) NSObject<ACCMultiStyleAlertProtocol> *backAlert;

@property (nonatomic, strong) AWEStoryTextImageModel *inputTextModel;
@property (nonatomic, strong) ACCRecordTextModeColorManager *colorManager;
@property (nonatomic, strong) NSObject<ACCRecorderBackgroundSwitcherProtocol> *backgroundManager;
@property (nonatomic, strong) UILabel *switchColorLabel;

@end

@implementation ACCRecorderTextModePreviewViewController

- (instancetype)initWithTextModel:(AWEStoryTextImageModel *)textModel colorManager:(nonnull ACCRecordTextModeColorManager *)colorManager
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _inputTextModel = textModel;
        _colorManager = colorManager;
    }
    return self;
}

- (instancetype)initWithTextModel:(AWEStoryTextImageModel *)textModel backgroundManager:(nonnull NSObject<ACCRecorderBackgroundSwitcherProtocol> *)backgroundManager
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _inputTextModel = textModel;
        _backgroundManager = backgroundManager;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.contentView = [[UIView alloc] init];
    self.contentView.backgroundColor = [UIColor blackColor];

    if (!ACCConfigBool(kConfigBool_studio_in_camera_corner_rounded_to_right)) {
        self.contentView.layer.cornerRadius = [AWEXScreenAdaptManager needAdaptScreen] ? 12.0 : 0.0;
    }
    self.contentView.clipsToBounds = YES;

    [self.view addSubview:self.contentView];
    ACCMasMaker(self.contentView, {
        make.leading.trailing.mas_equalTo(self.view);
        if ([AWEXScreenAdaptManager needAdaptScreen] && ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize) & ACCViewFrameOptimizeFullDisplay) {
            make.top.mas_equalTo(@(ACC_STATUS_BAR_NORMAL_HEIGHT));
            make.bottom.equalTo(@(-54 - ACC_IPHONE_X_BOTTOM_OFFSET));
        } else {
            make.top.mas_equalTo(@([AWEXScreenAdaptManager standPlayerFrame].origin.y));
            make.height.equalTo(@([AWEXScreenAdaptManager standPlayerFrame].size.height));
        }
    });

    ACCRecorderTextModeGradientView *backgroundView = [[ACCRecorderTextModeGradientView alloc] init];
    backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView addSubview:backgroundView];
    CGFloat screenScale = ACC_SCREEN_HEIGHT / ACC_SCREEN_WIDTH;
    ACCMasMaker(backgroundView, {
        if ([AWEXScreenAdaptManager needAdaptScreen]) {
            make.top.equalTo(self.view.mas_top).offset([AWEXScreenAdaptManager standPlayerFrame].origin.y);
            make.leading.equalTo(self.view.mas_leading);
            make.trailing.equalTo(self.view.mas_trailing);
            make.height.equalTo(@([AWEXScreenAdaptManager standPlayerFrame].size.height));
        } else {
            if (screenScale > 16.0 / 9.0) {
                make.height.equalTo(self.view.mas_height);
                make.width.equalTo(backgroundView.mas_height).multipliedBy(9.0 / 16.0);
            } else {
                make.width.equalTo(self.view.mas_width);
                make.height.equalTo(backgroundView.mas_width).multipliedBy(16.0 / 9.0);
            }
            make.centerX.equalTo(self.view.mas_centerX);
            make.centerY.equalTo(self.view.mas_centerY);
        }
    });
    _backgroundView = backgroundView;

    [self setupStickerContainer];
    
    CGFloat height = 28;
    ACCAnimatedButton *switchColorButton = [[ACCAnimatedButton alloc] init];
    switchColorButton.accessibilityLabel = @"更换背景";
    switchColorButton.accessibilityTraits = UIAccessibilityTraitButton;
    switchColorButton.alpha = 1.0;
    [switchColorButton addTarget:self action:@selector(refreshColor) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:switchColorButton];
    if (ACCConfigBool(kConfigBool_text_mode_add_backgrounds)) {
        UIImageView *switchImage = [[UIImageView alloc] initWithImage:[UIImage acc_imageWithName:@"ic_textmode_switch_color"]];
        [switchColorButton addSubview:switchImage];
        ACCMasMaker(switchColorButton, {
            make.right.equalTo(@-10);
            make.top.equalTo(@26);
            make.size.mas_equalTo(CGSizeMake(36, 56));
        });
        ACCMasMaker(switchImage, {
            make.top.equalTo(switchColorButton);
            make.centerX.equalTo(switchColorButton);
            make.size.mas_equalTo(CGSizeMake(36, 36));
        })
    } else {
        switchColorButton.layer.borderColor = ACCResourceColor(ACCUIColorBGContainer6).CGColor;
        switchColorButton.layer.borderWidth = 2.0;
        switchColorButton.layer.cornerRadius = height / 2.f;
        switchColorButton.layer.masksToBounds = YES;
        ACCMasMaker(switchColorButton, {
            make.right.equalTo(@-14);
            make.top.equalTo(@30);
            make.size.mas_equalTo(CGSizeMake(height, height));
        });
    }
    _switchColorButton = switchColorButton;
    
    if (ACCConfigBool(kConfigBool_text_mode_add_backgrounds)) {
        UILabel *switchColorLabel = [self createListLabel];
        switchColorLabel.text = @"换背景";
        [self.switchColorButton addSubview:switchColorLabel];
        ACCMasMaker(switchColorLabel, {
            make.centerX.equalTo(switchColorButton);
            make.bottom.equalTo(switchColorButton.mas_bottom).offset(-6);
        });
        self.switchColorLabel = switchColorLabel;
    }
    
    if (ACCConfigBool(kConfigBool_studio_textmode_lib)) {
        ACCAnimatedButton *enterLibButton = [[ACCAnimatedButton alloc] init];
        enterLibButton.alpha = 1.0;
        [enterLibButton addTarget:self action:@selector(enterTextLibMode) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:enterLibButton];
        
        UIImageView *enterLibImage = [[UIImageView alloc] initWithImage:[UIImage acc_imageWithName:@"text_lib_icon_grey"]];
        [enterLibButton addSubview:enterLibImage];
        ACCMasMaker(enterLibButton, {
            make.right.equalTo(@-10);
            make.top.equalTo(switchColorButton.mas_bottom).offset(6);
            make.size.mas_equalTo(CGSizeMake(36, 56));
        });
        ACCMasMaker(enterLibImage, {
            make.top.centerX.equalTo(enterLibButton);
            make.size.mas_equalTo(CGSizeMake(36, 36));
        });
        
        UILabel *enterLibLabel = [self createListLabel];
        enterLibLabel.text = @"文案库";
        [enterLibButton addSubview:enterLibLabel];
        ACCMasMaker(enterLibLabel, {
            make.centerX.equalTo(enterLibButton);
            make.bottom.equalTo(enterLibButton.mas_bottom).offset(-6);
        });
        
        enterLibButton.isAccessibilityElement = YES;
        enterLibButton.accessibilityLabel = @"文案库";
        self.enterLibButton = enterLibButton;
    }

    ACCRecorderTextModeGradientView *switchColorGradientView = [[ACCRecorderTextModeGradientView alloc] init];
    switchColorGradientView.userInteractionEnabled = NO;
    [switchColorButton insertSubview:switchColorGradientView atIndex:0];
    ACCMasMaker(switchColorGradientView, {
        make.top.left.right.bottom.mas_equalTo(switchColorButton);
    });
    _switchColorGradientView = switchColorGradientView;
    
    if (ACCConfigBool(kConfigBool_text_mode_add_backgrounds)) {
        id<ACCRecordModeBackgroundModelProtocol> background = self.backgroundManager.currentBackground;
        if (background.isColorBackground) {
            [backgroundView bd_cancelImageLoad];
            backgroundView.image = nil;
            backgroundView.colors = background.CGColors;
        } else {
            backgroundView.colors = nil;
            [backgroundView bd_setImageWithURLs:background.backgroundImage.URLList placeholder:nil options:BDImageRequestDefaultPriority transformer:nil progress:nil completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                if (error) {
                    ACCLog(@"bd_setImageWithURLs Failed, urls=%@, error: %@", background.backgroundImage.URLList, error);
                }
            }];
        }
        self.textFunctionHintLabel.textColor = background.hintColor.color;
    } else {
        backgroundView.colors = self.colorManager.currentModel.bgColors;
        switchColorGradientView.colors = self.colorManager.currentModel.bgColors;
    }
    
    [self setupTextSticker];
    
    ACCAnimatedButton *nextButton = [[ACCAnimatedButton alloc] init];
    nextButton.accessibilityLabel = @"进入编辑页";
    nextButton.alpha = ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab) ? 1 : 0;
    [nextButton setImage:[UIImage acc_imageWithName:@"ic_text_mode_next"] forState:UIControlStateNormal];
    [nextButton addTarget:self action:@selector(didClickNextButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:nextButton];

    CGFloat shiftToTop = 14;
    if ([AWEXScreenAdaptManager needAdaptScreen] && !(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize) & ACCViewFrameOptimizeFullDisplay)) {
        shiftToTop = -12;
    }
    CGFloat kSizeDiff = (96 - [self.layoutGuide recordButtonHeight]) / 2.f;
    ACCMasMaker(nextButton, {
        make.centerX.equalTo(self.contentView);
        make.bottom.mas_equalTo(@(kSizeDiff + [self.layoutGuide recordButtonBottomOffset] + ([UIDevice acc_isIPhoneX] ? shiftToTop : 0)));
    });
    _nextButton = nextButton;
    
    ACCAnimatedButton *closeButton = [[ACCAnimatedButton alloc] init];
    closeButton.accessibilityLabel = @"关闭";
    [closeButton setImage:[UIImage acc_imageWithName:@"ic_titlebar_close_white"] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(didClickCloseButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:closeButton];
    ACCMasMaker(closeButton, {
        make.left.equalTo(@6);
        if ([UIDevice acc_isIPhoneX]) {
            if (@available(iOS 11.0, *)) {
                make.top.equalTo(self.view).offset(ACC_STATUS_BAR_NORMAL_HEIGHT + 20);
            } else {
                make.top.equalTo(@20);
            }
        } else {
            make.top.equalTo(@20);
        }
        make.size.mas_equalTo(CGSizeMake(44, 44));
    });
    _closeButton = closeButton;
    
    if (self.inputTextModel) {
        ACCTextStickerView *stickerView = [self addTextWithTextInfo:self.inputTextModel locationModel:nil];
        self.stickerView = stickerView;
        self.textFunctionHintLabel.alpha = 0;
        nextButton.alpha = 1;
    }
    
    [ACCTextStickerRecommendDataHelper requestLibList:self.publishModel completion:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.textFunctionHintLabel);
}


- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    ACCBLOCK_INVOKE(self.textViewDidApear);
}

- (UILabel *)createListLabel
{
    UILabel *createListLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    createListLabel.textColor = UIColor.whiteColor;
    createListLabel.font = [UIFont systemFontOfSize:10];
    createListLabel.textAlignment = NSTextAlignmentCenter;
    createListLabel.layer.shadowOpacity = 1;
    createListLabel.layer.shadowOffset = CGSizeMake(0, 1);
    createListLabel.layer.shadowRadius = 2;
    createListLabel.layer.shadowColor = ACCResourceColor(ACCColorTextReverse4).CGColor;
    return createListLabel;
}

- (void)setupStickerContainer
{
    CGRect playerFrame = [AWEXScreenAdaptManager standPlayerFrame];
    if ([AWEXScreenAdaptManager needAdaptScreen] && ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize) & ACCViewFrameOptimizeFullDisplay) {
        playerFrame.origin.y = ACC_STATUS_BAR_NORMAL_HEIGHT;
        playerFrame.size.height = ACC_SCREEN_HEIGHT - ACC_STATUS_BAR_NORMAL_HEIGHT -54 - ACC_IPHONE_X_BOTTOM_OFFSET;
    }

    ACCRecorderTextModeStickerContainerConfig *config = [[ACCRecorderTextModeStickerContainerConfig alloc] init];
    config.stickerHierarchyComparator = ^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return NSOrderedSame;
    };
    config.ignoreMaskRadiusForXScreen = [AWEXScreenAdaptManager needAdaptScreen] && ACCViewFrameOptimizeContains(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize), ACCViewFrameOptimizeFullDisplay);

    ACCStickerContainerView *stickerContainerView = [[ACCStickerContainerView alloc] initWithFrame:playerFrame config:config];
    stickerContainerView.delegate = self;
    [stickerContainerView configWithPlayerFrame:playerFrame allowMask:NO];
    stickerContainerView.shouldHandleGesture = YES;
    self.stickerContainerView = stickerContainerView;
    [self.contentView addSubview:stickerContainerView];
    ACCMasMaker(stickerContainerView, {
        make.edges.mas_equalTo(self.contentView);
    });

    UILabel *textFunctionHintLabel = [[UILabel alloc] init];
    textFunctionHintLabel.font = [UIFont acc_pingFangSemibold:32];
    if (ACCConfigBool(kConfigBool_text_mode_add_backgrounds)) {
        textFunctionHintLabel.textColor = self.backgroundManager.currentBackground.hintColor.color;
    } else {
        textFunctionHintLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
    }
    textFunctionHintLabel.text = ACCLocalizedString(@"tap_to_input", @"tap_to_input");
    textFunctionHintLabel.isAccessibilityElement = YES;
    textFunctionHintLabel.accessibilityLabel = @"轻触即可输入,编辑框";
    [self.contentView addSubview:textFunctionHintLabel];
    ACCMasMaker(textFunctionHintLabel, {
        make.centerX.centerY.equalTo(self.contentView);
    });
    _textFunctionHintLabel = textFunctionHintLabel;
}

- (void)didClickCloseButton:(id)sender
{
    if (self.stickerView.textView.text.length > 0) {
        // 命中样式实验，则显示对应样式
        if ([self p_showBackAlertIfNeeded]) {
            return;
        }
        // 系统样式为当前线上样式
        [self p_showSystemBackAlert];
    } else {
        [self p_exit];
    }
}

- (void)didClickNextButton
{
    if (ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab)) {
        if (self.stickerView == nil || self.stickerView.textView.text.length == 0) {
            AWEStoryTextImageModel *textInfo = [self newTextInfo];
            ACCTextStickerView *stickerView = [self addTextWithTextInfo:textInfo locationModel:nil];
            self.stickerView = stickerView;
            [self editTextStickerView:self.stickerView];
            NSString *enterMethod = @"click_next_button";
            ACCBLOCK_INVOKE(self.onBeginEdit, enterMethod);
        } else {
            ACCBLOCK_INVOKE(self.goNext);
        }
    } else {
        ACCBLOCK_INVOKE(self.goNext);
    }
}

- (void)setupTextSticker
{
    @weakify(self);
    // 一期先兼容安卓 他们不支持在拍摄页mention和hashtag的功能，实际上iOS是天然支持的 反而要手动禁掉
    // 文字朗读 本身之前也没在拍摄页文字入口支持
    ACCTextStickerEditAbilityOptions options = ACCTextStickerEditAbilityOptionsNone;
    
    _textStickerEditView = [[ACCTextStickerEditView alloc] initWithOptions:options];
    _textStickerEditView.frame = CGRectMake(0, ACC_NAVIGATION_BAR_OFFSET, ACC_SCREEN_WIDTH, ACC_SCREEN_HEIGHT - ACC_STATUS_BAR_NORMAL_HEIGHT);
    _textStickerEditView.publishViewModel = self.publishModel;
    _textStickerEditView.fromTextMode = YES;
    self.textStickerEditView.onEditFinishedBlock = ^(ACCTextStickerView * _Nonnull textStickerView, BOOL fromSaveButton) {
        @strongify(self);
        [self.textStickerEditView removeFromSuperview];
        if (self.textDidChangeCallback) {
            self.textDidChangeCallback((textStickerView.textView.text.length == 0)? nil : textStickerView.textModel);
        }
        if (textStickerView.textView.text.length > 0) {
            ACCBLOCK_INVOKE(self.goNext);
        }
    };
    self.textStickerEditView.finishEditAnimationBlock = ^(ACCTextStickerView * _Nonnull textStickerView) {
        @strongify(self);
        self.switchColorButton.alpha = 1;
        self.switchColorLabel.alpha = 1;
        self.enterLibButton.alpha = 1;
        self.closeButton.alpha = 1;
        if (textStickerView.textView.text.length == 0) {
            self.textFunctionHintLabel.alpha = 1;
            [self.stickerContainerView removeStickerView:textStickerView];
            if (!ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab)) {
                self.nextButton.alpha = 0;
            }
        } else {
            self.textFunctionHintLabel.alpha = 0;
            self.nextButton.alpha = 1;
        }
    };
    self.textStickerEditView.didSelectedColorBlock = ^(AWEStoryColor *selectColor, NSIndexPath *indexPath) {
        @strongify(self);
        [self.stickerLogger logTextStickerDidSelectColor:selectColor.colorString];
    };
    self.textStickerEditView.didChangeStyleBlock = ^(AWEStoryTextStyle style) {
        @strongify(self);
        [self.stickerLogger logTextStickerDidChangeTextStyle:style];
    };
    self.textStickerEditView.didSelectedFontBlock = ^(AWEStoryFontModel *model, NSIndexPath *indexPath) {
        @strongify(self);
        [self.stickerLogger logTextStickerDidSelectFont:model.title];
    };
    self.textStickerEditView.didChangeAlignmentBlock = ^(AWEStoryTextAlignmentStyle style) {
        @strongify(self);
        [self.stickerLogger logTextStickerDidChangeAlignment:style];
    };
    
    self.textStickerEditView.didSelectedToolbarColorItemBlock = ^(BOOL willShowColorPannel) {
        @strongify(self);
        [self.stickerLogger logTextStickerDidSelectedToolbarColorItem:@{@"to_status": willShowColorPannel?@"color":@"font"}];
    };
    
    self.textStickerEditView.triggeredSocialEntraceBlock = ^(BOOL isFromToolbar, BOOL isMention) {
        @strongify(self);
        [self.stickerLogger logTextStickerViewDidTriggeredSocialEntraceWithEntraceName:isFromToolbar?@"button":@"input" isMention:isMention];
    };
    
    self.textStickerEditView.stickerTotalMentionBindCountProvider = ^NSInteger {
        @strongify(self);
        return [ACCTextStickerExtraModel numberOfValidExtrasInList:self.inputTextModel.extraInfos forType:ACCTextStickerExtraTypeMention];
    };
    
    self.textStickerEditView.stickerTotalHashtagBindCountProvider = ^NSInteger {
        @strongify(self);
        return [ACCTextStickerExtraModel numberOfValidExtrasInList:self.inputTextModel.extraInfos forType:ACCTextStickerExtraTypeHashtag];
    };
}

- (__kindof ACCTextStickerView *)addTextWithTextInfo:(AWEStoryTextImageModel *)textModel locationModel:(AWEInteractionStickerLocationModel *)locationModel
{
    if (!textModel) {
        return nil;
    }

    ACCTextStickerView *textStickerView = [[ACCTextStickerView alloc] initWithTextInfo:textModel options:ACCTextStickerViewAbilityOptionsNone];
    ACCTextStickerConfig *config = [[ACCTextStickerConfig alloc] init];
    config.needBubble = NO;
    config.showSelectedHint = NO;
    config.supportGesture = ^BOOL(ACCStickerGestureType gestureType, id _Nullable contextId, UIGestureRecognizer *gestureRecognizer) {
        if (ACCStickerGestureTypeTap == gestureType) {
            return YES;
        }
        return NO;
    };
    return [self configStickerView:textStickerView withConfig:config locationModel:locationModel];
}

- (ACCTextStickerView *)configStickerView:(ACCTextStickerView *)textStickerView
                               withConfig:(ACCTextStickerConfig *)config
                            locationModel:(AWEInteractionStickerLocationModel *)locationModel {
    @weakify(self);
    config.onceTapCallback = ^(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UITapGestureRecognizer * _Nonnull gesture) {
        @strongify(self);
        [self editTextStickerView:textStickerView];
        NSString *enterMethod = @"click_screen";
        ACCBLOCK_INVOKE(self.onBeginEdit, enterMethod);
    };
    config.secondTapCallback = ^(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UITapGestureRecognizer * _Nonnull gesture) {
        @strongify(self);
        [self editTextStickerView:textStickerView];
        NSString *enterMethod = @"click_screen";
        ACCBLOCK_INVOKE(self.onBeginEdit, enterMethod);
    };
    config.typeId = @"text";
    config.hierarchyId = @"text";
    config.timeRangeModel.pts = [NSDecimalNumber decimalNumberWithString:@"-1"];
    if (locationModel) {
        config.timeRangeModel.startTime = locationModel.startTime;
        config.timeRangeModel.endTime = locationModel.endTime;
    } else {
        locationModel = [AWEInteractionStickerLocationModel new];
    }
    config.geometryModel = [locationModel geometryModel];
    [self.stickerContainerView addStickerView:textStickerView config:config].stickerGeometry.preferredRatio = NO;
    return textStickerView;
}

- (void)editTextStickerView:(ACCTextStickerView *)stickerView
{
    [self editTextStickerView:stickerView inputMode:ACCTextStickerEditEnterInputModeKeyword];
}

- (void)editTextStickerView:(ACCTextStickerView *)stickerView inputMode:(ACCTextStickerEditEnterInputMode)inputMode
{
    self.switchColorButton.alpha = 0;
    self.switchColorLabel.alpha = 0;
    self.enterLibButton.alpha = 0;
    self.textFunctionHintLabel.alpha = 0;
    self.closeButton.alpha = 0;
    [self.view addSubview:self.textStickerEditView];
    [self.textStickerEditView startEditStickerView:stickerView inputMode:inputMode];
}

- (void)refreshColor
{
    [ACCAccessibility() postAccessibilityNotification:UIAccessibilityPageScrolledNotification argument:@"已更换背景"];
    if (ACCConfigBool(kConfigBool_text_mode_add_backgrounds)) {
        [self.backgroundManager switchToNext];
        if (self.backgroundManager.currentBackground.isColorBackground) {
            [self.backgroundView bd_cancelImageLoad];
            self.backgroundView.image = nil;
            self.backgroundView.colors = self.backgroundManager.currentBackground.CGColors;
        } else {
            [self.backgroundView bd_cancelImageLoad];
            [self.backgroundView bd_setImageWithURLs:self.backgroundManager.currentBackground.backgroundImage.URLList placeholder:self.backgroundView.image options:BDImageRequestHighPriority transformer:nil progress:nil completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                if (error) {
                    ACCLog(@"bd_setImageWithURLs Failed, urls=%@, error: %@", self.backgroundManager.currentBackground.backgroundImage.URLList, error);
                }
            }];
        }
        self.textFunctionHintLabel.textColor = self.backgroundManager.currentBackground.hintColor.color;
        ACCBLOCK_INVOKE(self.onChangeColor, self.backgroundManager.currentBackground.colorString);
    } else {
        [self.colorManager switchToNext];
        self.backgroundView.colors = self.colorManager.currentModel.bgColors;
        self.switchColorGradientView.colors = self.colorManager.currentModel.bgColors;
        self.textFunctionHintLabel.textColor = self.colorManager.currentModel.fontColor;
        ACCBLOCK_INVOKE(self.onChangeColor, self.colorManager.currentModel.colorsString);
    }
}

- (void)enterTextLibMode
{
    if (self.stickerView == nil) {
        AWEStoryTextImageModel *textInfo = [self newTextInfo];
        ACCTextStickerView *stickerView = [self addTextWithTextInfo:textInfo locationModel:nil];
        self.stickerView = stickerView;
    }
    [self editTextStickerView:self.stickerView inputMode:ACCTextStickerEditEnterInputModeTextLib];
    NSString *enterMethod = @"click_textlib";
    ACCBLOCK_INVOKE(self.onBeginEdit, enterMethod);
}

#pragma mark - ACCStickerContainerDelegate

- (void)stickerContainer:(ACCStickerContainerView *)stickerContainer gestureStarted:(nonnull UIGestureRecognizer *)gesture onView:(nonnull UIView *)targetView
{
    
}

- (void)stickerContainer:(ACCStickerContainerView *)stickerContainer gestureEnded:(nonnull UIGestureRecognizer *)gesture onView:(nonnull UIView *)targetView
{
    
}

- (BOOL)stickerContainerTapBlank:(ACCStickerContainerView *)stickerContainer gesture:(nonnull UIGestureRecognizer *)gesture
{
    CGPoint point = [gesture locationInView:stickerContainer];
    if (point.y < self.switchColorButton.acc_bottom + 50 || point.y > self.nextButton.acc_top - 50) {
        return NO;
    }
    if (self.stickerView == nil) {
        AWEStoryTextImageModel *textInfo = [self newTextInfo];
        ACCTextStickerView *stickerView = [self addTextWithTextInfo:textInfo locationModel:nil];
        self.stickerView = stickerView;
    }
    [self editTextStickerView:self.stickerView];
    NSString *enterMethod = @"click_screen";
    ACCBLOCK_INVOKE(self.onBeginEdit, enterMethod);
    return YES;
}

- (AWEStoryTextImageModel *)newTextInfo
{
    AWEStoryTextImageModel *textInfo = [AWEStoryTextImageModel new];
    NSInteger colorIndex = [[AWEStoryColorChooseView storyColors] indexOfObject:self.backgroundManager.currentBackground.fontColor] ?: 0;
    textInfo.colorIndex = [NSIndexPath indexPathForRow:colorIndex inSection:0];
    textInfo.fontColor = [[AWEStoryColorChooseView storyColors] acc_objectAtIndex:colorIndex];
    NSInteger fontIndex = [[AWEStoryFontChooseView stickerFonts] indexOfObject:self.backgroundManager.currentBackground.font] ?: 0;
    textInfo.fontIndex = [NSIndexPath indexPathForRow:fontIndex inSection:0];
    textInfo.fontModel = [[AWEStoryFontChooseView stickerFonts] acc_objectAtIndex:fontIndex];
    return textInfo;
}

- (UIImage *)generateBackgroundImage
{
    ACCRecorderTextModeGradientView *backgroundView = [[ACCRecorderTextModeGradientView alloc] init];
    if (ACCConfigBool(kConfigBool_enable_1080p_photo_to_video)) {
        backgroundView.frame = CGRectMake(0, 0, 1080, 1920);
    } else {
        backgroundView.frame = CGRectMake(0, 0, 720, 1280);
    }
    UIImage *image;
    if (ACCConfigBool(kConfigBool_text_mode_add_backgrounds)) {
        if (self.backgroundManager.currentBackground.isColorBackground) {
            backgroundView.colors = self.backgroundManager.currentBackground.CGColors;
        } else {
            backgroundView.contentMode = UIViewContentModeScaleAspectFill;
            [backgroundView setImage:self.backgroundView.image];
        }
        image = [backgroundView acc_imageWithViewOnScreenScale];
    } else {
        backgroundView.colors = self.colorManager.currentModel.bgColors;
        image = [backgroundView acc_imageWithViewOnScreenScale];
    }
    return image;
}

#pragma mark - Private Methods

#pragma mark 挽留弹窗
/// 是否显示挽留弹窗 （可变样式）
- (BOOL)p_showBackAlertIfNeeded
{
    if (!ACCMultiStyleAlertParamsProtocol(ACCConfigInt(kConfigInt_creative_edit_record_beg_for_stay_prompt_style))) {
        return NO;
    }
    [self.backAlert show];
    return YES;
}
- (void)p_showSystemBackAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSString *exitTitle = ACCLocalizedString(@"av_exit_recording", @"退出");
    NSString *retypeTitle = ACCLocalizedString(@"retype",@"重新输入");
    NSString *cancelTitle = ACCLocalizedCurrentString(@"cancel");
    
    @weakify(self);
    [alertController addAction:[UIAlertAction actionWithTitle:exitTitle style:UIAlertActionStyleDestructive  handler:^(UIAlertAction * _Nonnull action) {
        @strongify(self);
        [self p_exit];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:retypeTitle  style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        @strongify(self);
        [self p_retype];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:nil]];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [ACCAlert() showAlertController:alertController fromView:self.closeButton];
    } else {
        [ACCAlert() showAlertController:alertController animated:YES];
    }
}

/// 重新输入
- (void)p_retype
{
    self.textFunctionHintLabel.alpha = 1;
    [self.stickerContainerView removeStickerView:self.stickerView];
    if (self.textDidChangeCallback) {
        self.textDidChangeCallback(nil);
    }
}

/// 退出
- (void)p_exit
{
    if (self.close) {
        self.close();
    }
}

#pragma mark - Getter & Setter
/// 挽留弹窗
- (NSObject<ACCMultiStyleAlertProtocol> *)backAlert
{
    if (!_backAlert) {
        _backAlert = ACCMultiStyleAlert();
        Protocol *paramsProtocol = ACCMultiStyleAlertParamsProtocol(ACCConfigInt(kConfigInt_creative_edit_record_beg_for_stay_prompt_style));
        // 线上默认是Sheet
        if (!paramsProtocol) paramsProtocol = @protocol(ACCMultiStyleAlertSheetParamsProtocol);
        @weakify(self);
        _backAlert = [_backAlert initWithParamsProtocol:paramsProtocol configBlock:^(id<ACCMultiStyleAlertBaseParamsProtocol>  _Nonnull params) {
            @strongify(self);
            // 每次显示需实时更新数据
            params.reconfigBeforeShow = YES;
            
            //  Popover弹窗差异点
            ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(params, ACCMultiStyleAlertPopoverParamsProtocol, ^{
                params.alignmentMode = UIControlContentHorizontalAlignmentLeft;
                params.sourceView = self.closeButton;
                params.sourceRect = self.closeButton.bounds;
                params.fixedContentWidth = 160;
            });
            
            //  Alert差异点
            ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(params, ACCMultiStyleAlertNormalParamsProtocol, ^{
                params.title = @"是否移除当前内容？";
                params.isButtonAlignedVertically = YES;
            });
            
            // 退出相机
            [params addAction:^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
                @strongify(self);
                ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(action, ACCMultiStyleAlertPopoverActionProtocol, ^{
                    action.image = ACCResourceImage(@"ic_actionlist_block_red");
                });
                action.title = @"退出相机";
                action.actionStyle = ACCMultiStyleAlertActionStyleHightlight;
                action.eventBlock = ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
                    @strongify(self);
                    [self p_exit];
                };
            }];
            // 重新输入
            [params addAction:^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
                @strongify(self);
                ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(action, ACCMultiStyleAlertPopoverActionProtocol, ^{
                    action.image = ACCResourceImage(@"ic_actionlist_retry");
                });
                action.title =  ACCLocalizedString(@"retype",@"重新输入");
                action.eventBlock = ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
                    @strongify(self);
                    [self p_retype];
                };
            }];
            // 取消
            BOOL isSheet = [params conformsToProtocol:@protocol(ACCMultiStyleAlertSheetParamsProtocol)];
            BOOL isAlert = [params conformsToProtocol:@protocol(ACCMultiStyleAlertNormalParamsProtocol)];
            if (isSheet || isAlert) {
                [params addAction:^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
                    action.title = @"取消";
                    action.eventBlock = ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
                        @strongify(self);
                        [self.backAlert dismiss];
                    };
                }];
            }
        }];
    }
    return _backAlert;
}



@end
