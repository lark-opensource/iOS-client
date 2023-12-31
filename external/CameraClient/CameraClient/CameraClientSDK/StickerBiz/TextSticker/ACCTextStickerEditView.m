//
//  ACCTextStickerEditView.m
//  CameraClient
//
//  Created by Yangguocheng on 2020/7/15.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCCacheProtocol.h>

#import "ACCTextStickerEditView.h"
#import <CreationKitArch/AWEEditGradientView.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <Masonry/Masonry.h>
#import "ACCCameraClient.h"
#import <CreativeKit/ACCAnimatedButton.h>

#import <CreationKitArch/ACCCustomFontProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import "ACCSocialStickerEditToolbar.h"
#import "ACCTextStickerEditWrapedToobarContainer.h"
#import "ACCTextReaderSoundEffectsSelectionView.h"
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CameraClient/ACCConfigKeyDefines.h>

#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import "AWEModernTextToolBar.h"
#import "AWETextTopBar.h"
#import "AWEStoryColorChooseView.h"
#import "ACCTextStickerInputController.h"
#import "ACCBubbleProtocol.h"
#import "ACCTextStickerSettingsConfig.h"
#import "ACCTextStickerLibPannelView.h"
#import "ACCTextStickerRecommendInputController.h"
#import "AWERepoStickerModel.h"
#import "ACCTextStickerRecommendDataHelper.h"

static NSString * const kShowSpeakerHintView = @"AWEEditStickerHintKey_TextReading_Speaker";

static AWETextStackViewItemIdentity const kToolBarMentionItemIdentity   = @"mention";
static AWETextStackViewItemIdentity const kToolBarHashtagItemIdentity   = @"hashtag";
static AWETextStackViewItemIdentity const kToolBarColorItemIdentity     = @"color";
static AWETextStackViewItemIdentity const kToolBarAlignmentItemIdentity = @"alignment";
static AWETextStackViewItemIdentity const kToolBarTextStyleItemIdentity = @"textStyle";
static AWETextStackViewItemIdentity const kToolBarTextReadItemIdentity  = @"textRead";

@interface ACCTextStickerEditView ()

/// config
@property (nonatomic, assign) ACCTextStickerEditAbilityOptions viewOptions;
/// sticker
@property (nonatomic, strong) ACCTextStickerView *editingStickerView;
@property (nonatomic, weak) UIView *orignalSuperView;

/// top
@property (nonatomic, strong) ACCAnimatedButton *saveButton;
@property (nonatomic, strong) UIView *lowerMaskView;
@property (nonatomic, strong) AWEEditGradientView *upperMaskView;

/// tool bar
@property (nonatomic, strong) ACCSocialStickerEditToolbar *socialToolbar;
@property (nonatomic, strong) AWEModernTextToolBar *modernTextToolBar;
@property (nonatomic, strong) AWETextTopBar *topTextToolBar;
@property (nonatomic, strong) ACCTextStickerEditWrapedToobarContainer *toolbarContainer;

/// flags
@property (nonatomic, assign, readonly) BOOL supportTextBarTextReadingEntrance;
@property (nonatomic, assign, readonly) BOOL supportTextStickerSocialBind;
@property (nonatomic, assign, readonly) BOOL notSupportMention;
@property (nonatomic, assign) NSInteger totalStickerMentionCountExcludeSelfWhenEditing;
@property (nonatomic, assign) NSInteger totalStickerHashtagCountExcludeSelfWhenEditing;

/// feature
@property (nonatomic, strong) ACCTextReaderSoundEffectsSelectionView *soundEffectsSelectionView;

// 文字推荐相关
@property (nonatomic, strong) ACCTextStickerRecommendInputController *recommendInputController;
@property (nonatomic, strong) ACCTextStickerLibPannelView *libPannel;

@end

@implementation ACCTextStickerEditView
@synthesize editingStickerView = _editingStickerView;

#pragma mark - life cycle
- (instancetype)initWithOptions:(ACCTextStickerEditAbilityOptions)viewOptions
{
    self = [self initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, ACC_SCREEN_HEIGHT)];
    if (self) {
        self.viewOptions = viewOptions;
        [self p_setupABFlags];
        [self p_setup];
    }
    return self;
}

- (void)dealloc
{
    [self removeObservers];
}

#pragma mark - setup
- (void)p_setupABFlags
{
    /// @todo @maxueqiang 全量后清理
    if (self.viewOptions & ACCTextStickerEditAbilityOptionsSupportTextReader) {
        
        if (!(ACCConfigEnum(kConfigInt_text_reader_multiple_sound_effects, ACCTextReaderPhase2Type) == ACCTextReaderPhase2TypeDisable ||
              ACCConfigEnum(kConfigInt_text_reader_multiple_sound_effects, ACCTextReaderPhase2Type) == ACCTextReaderPhase2TypeNotShowInToolBar)) {
            _supportTextBarTextReadingEntrance = YES;
        }
    }
    
    if (self.viewOptions & ACCTextStickerEditAbilityOptionsSupportSocial) {
        _supportTextStickerSocialBind = YES;
    }
    
    if (self.viewOptions & ACCTextStickerEditAbilityOptionsNotSupportMention) {
        _notSupportMention = YES;
    }
}

- (void)p_setup
{
    UIView *lowerMaskView = [[UIView alloc] init];
    lowerMaskView.translatesAutoresizingMaskIntoConstraints = NO;
    lowerMaskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    [lowerMaskView acc_addSingleTapRecognizerWithTarget:self action:@selector(didClickedTextMaskView)];
    [self addSubview:lowerMaskView];
    ACCMasMaker(lowerMaskView, {
        make.edges.equalTo(self);
    });
    lowerMaskView.alpha = 0;
    _lowerMaskView = lowerMaskView;
    
    AWEEditGradientView *upperMaskView = [[AWEEditGradientView alloc] init];
    upperMaskView.translatesAutoresizingMaskIntoConstraints = NO;
    upperMaskView.backgroundColor = [UIColor clearColor];
    upperMaskView.clipsToBounds = YES;
    [self addSubview:upperMaskView];
    ACCMasMaker(upperMaskView, {
        make.top.equalTo(self.mas_top).offset(65 + ACC_NAVIGATION_BAR_OFFSET);
        make.right.left.bottom.equalTo(self);
    });
    upperMaskView.alpha = 0;
    _upperMaskView = upperMaskView;

    ACCAnimatedButton *saveButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeAlpha];
    [saveButton.titleLabel setFont:[ACCFont() acc_systemFontOfSize:17 weight:ACCFontWeightMedium]];
    [saveButton setTitle: ACCLocalizedString(@"done", @"done") forState:UIControlStateNormal];
    [saveButton addTarget:self action:@selector(didClickedSaveButton:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:saveButton];
    _saveButton = saveButton;
    _saveButton.isAccessibilityElement = YES;
    _saveButton.accessibilityLabel = ACCLocalizedString(@"done", @"done");

    ACCMasMaker(saveButton, {
        make.trailing.equalTo(self.mas_trailing);
        make.top.equalTo(self.mas_top).offset(ACC_NAVIGATION_BAR_OFFSET + ([UIDevice acc_isIPhoneX] ? 26.f : 20.f));
        make.size.mas_equalTo(CGSizeMake(66.f, 44.f));
    });
    saveButton.alpha = 0;
    saveButton.hidden = YES;
    saveButton.accessibilityLabel = ACCLocalizedString(@"done", @"done");
    saveButton.accessibilityTraits = UIAccessibilityTraitButton;
    
    [self addSubview:self.topTextToolBar];
    ACCMasMaker(self.topTextToolBar, {
        make.centerX.equalTo(self);
        make.centerY.equalTo(self.saveButton);
    });
    self.topTextToolBar.alpha = 0;
    self.topTextToolBar.hidden = YES;
    
    @weakify(self);
    
    [self.modernTextToolBar setDidSelectedFontBlock:^(AWEStoryFontModel * _Nonnull selectFont, NSIndexPath * _Nonnull indexPath) {
        @strongify(self);
        [self p_onSelectedFont:selectFont atIndexPath:indexPath];
    }];
    
    [self.modernTextToolBar setDidSelectedColorBlock:^(AWEStoryColor * _Nonnull selectColor, NSIndexPath * _Nonnull indexPath) {
        @strongify(self);
        [self p_onSelectedColor:selectColor atIndexPath:indexPath];
    }];
    
    [self.modernTextToolBar setDidSelectedCloseColorViewBtnBlock:^{
        @strongify(self);
        [self.modernTextToolBar updateColorViewShowStatus:NO];
        [self.topTextToolBar updateBarItemWithItemIdentity:kToolBarColorItemIdentity];
    }];
    
    [self p_registerAllToolbarHandlers];
    [self addObservers];
}

#pragma mark - common callback handler
- (void)p_onSelectedFont:(AWEStoryFontModel *)selectFont atIndexPath:(NSIndexPath *)indexPath
{
    self.editingStickerView.textModel.fontModel = selectFont;
    self.editingStickerView.textModel.fontIndex = indexPath;
    [self.editingStickerView updateDisplay];
    [self.topTextToolBar updateBarItemWithItemIdentity:kToolBarTextStyleItemIdentity];
    
    if (self.didSelectedFontBlock) {
        self.didSelectedFontBlock(selectFont, indexPath);
    }
}

- (void)p_onSelectedColor:(AWEStoryColor *)selectColor atIndexPath:(NSIndexPath *)indexPath
{
    self.editingStickerView.textModel.fontColor = selectColor;
    self.editingStickerView.textModel.colorIndex = indexPath;
    [self.editingStickerView updateDisplay];
    if (self.didSelectedColorBlock) {
        self.didSelectedColorBlock(selectColor, indexPath);
    }
}

#pragma mark - stackview handler
- (void)p_registerAllToolbarHandlers
{
    @weakify(self);
    // mention
    [self p_registerToolbarItemConfigProvider:^(UIView<AWETextToolStackViewProtocol> * _Nonnull stackView,
                                                AWETextStackViewItemConfig *itemConfig) {
        
        itemConfig.enable = YES;
        itemConfig.iconImage = itemConfig.iconImage ?: ACCResourceImage(@"icon_text_tool_bar_mention");
        itemConfig.title = @"提及";
        
    } clickHandler:^(UIView<AWETextToolStackViewProtocol> * _Nonnull stackView) {
        @strongify(self);
        
        ACCBLOCK_INVOKE(self.triggeredSocialEntraceBlock, YES, YES);
        
        // 按照需求，单条文字贴纸超了让输入但不处理，但是所有贴纸超了不能输入~
        NSInteger totalMention = self.totalStickerMentionCountExcludeSelfWhenEditing + [self.editingStickerView.inputController numberOfExtrasForType:ACCTextStickerExtraTypeMention];
        NSInteger maxSocialCount = [ACCTextStickerSettingsConfig allStickerEachSociaMaxBindCount];
        if (totalMention >= maxSocialCount) {
            [self p_showToastWithText:[NSString stringWithFormat:@"每条视频最多@%i个人", (int)maxSocialCount]];
            return;
        }
        [self.editingStickerView.inputController appendExtraCharacterWithType:ACCTextStickerExtraTypeMention];
        
    } forItemIdentity:kToolBarMentionItemIdentity];
    
    // hashtag
    [self p_registerToolbarItemConfigProvider:^(UIView<AWETextToolStackViewProtocol> * _Nonnull stackView,
                                                AWETextStackViewItemConfig *itemConfig) {
        itemConfig.enable = YES;
        itemConfig.iconImage = itemConfig.iconImage ?: ACCResourceImage(@"icon_text_tool_bar_hashtag");
        itemConfig.title = @"话题";
        
    } clickHandler:^(UIView<AWETextToolStackViewProtocol> * _Nonnull stackView) {
        @strongify(self);
        
        ACCBLOCK_INVOKE(self.triggeredSocialEntraceBlock, YES, NO);
        
        // 按照需求，单条文字贴纸超了让输入但不处理，但是所有贴纸超了不能输入~
        NSInteger totalHashtag = self.totalStickerHashtagCountExcludeSelfWhenEditing + [self.editingStickerView.inputController numberOfExtrasForType:ACCTextStickerExtraTypeHashtag];
        NSInteger maxSocialCount = [ACCTextStickerSettingsConfig allStickerEachSociaMaxBindCount];
        if (totalHashtag >= maxSocialCount) {
            [self p_showToastWithText:[NSString stringWithFormat:@"每条视频最多添加%i个话题", (int)maxSocialCount]];
            return;
        }
        [self.editingStickerView.inputController appendExtraCharacterWithType:ACCTextStickerExtraTypeHashtag];
        
    } forItemIdentity:kToolBarHashtagItemIdentity];
    
    // color
    [self p_registerToolbarItemConfigProvider:^(UIView<AWETextToolStackViewProtocol> * _Nonnull stackView,
                                                AWETextStackViewItemConfig *itemConfig) {

        @strongify(self);
        itemConfig.enable = YES;
        BOOL isShowingColorView = self.modernTextToolBar.isShowingColorView;
        itemConfig.iconImage = ACCResourceImage(isShowingColorView? @"icon_text_tool_bar_color_selected" : @"icon_text_tool_bar_color");
        itemConfig.title = isShowingColorView ? @"已展开颜色" : @"已折叠颜色";
        
    } clickHandler:^(UIView<AWETextToolStackViewProtocol> * _Nonnull stackView) {
        @strongify(self);
        [self.toolbarContainer switchToToolbarType:ACCTextStickerEditToolbarTypeNormal];
        BOOL isShowingColorView = self.modernTextToolBar.isShowingColorView;
        [self.modernTextToolBar updateColorViewShowStatus:!isShowingColorView];
        ACCBLOCK_INVOKE(self.didSelectedToolbarColorItemBlock, !isShowingColorView);
        
    } forItemIdentity:kToolBarColorItemIdentity];
    
    // alignment
    [self p_registerToolbarItemConfigProvider:^(UIView<AWETextToolStackViewProtocol> * _Nonnull stackView,
                                                AWETextStackViewItemConfig *itemConfig) {
        
        @strongify(self);
        itemConfig.enable = YES;
        itemConfig.iconImage = ACCResourceImage([NSString stringWithFormat:@"icTextAlignment_%@", @(self.textModel.alignmentType)]);
        if (self.textModel.alignmentType == AWEStoryTextAlignmentLeft) {
            itemConfig.title = @"居左";
        } else if (self.textModel.alignmentType == AWEStoryTextAlignmentRight) {
            itemConfig.title = @"居右";
        } else {
            itemConfig.title = @"居中";
        }
    } clickHandler:^(UIView<AWETextToolStackViewProtocol> * _Nonnull stackView) {
        @strongify(self);
        [self didClickToolbarAlignmentButton];
        
    } forItemIdentity:kToolBarAlignmentItemIdentity];
    
    // text style
    [self p_registerToolbarItemConfigProvider:^(UIView<AWETextToolStackViewProtocol> * _Nonnull stackView,
                                                AWETextStackViewItemConfig *itemConfig) {
        
        @strongify(self);
        itemConfig.enable = self.textModel.fontModel.hasBgColor;
        itemConfig.iconImage = ACCResourceImage([NSString stringWithFormat:@"icon_text_tool_bar_text_style_%@", @(self.textModel.textStyle)]);
        NSString *title = @"文本样式";
        if (self.textModel.textStyle == AWEStoryTextStyleStroke) {
            title = [title stringByAppendingString:@",描边"];
        } else if (self.textModel.textStyle == AWEStoryTextStyleBackground) {
            title = [title stringByAppendingString:@",背景"];
        } else if (self.textModel.textStyle == AWEStoryTextStyleAlphaBackground) {
            title = [title stringByAppendingString:@",半透明背景"];
        } else {
            title = [title stringByAppendingString:@",无"];
        }
        itemConfig.title = title;
    } clickHandler:^(UIView<AWETextToolStackViewProtocol> * _Nonnull stackView) {
        @strongify(self);
        [self didClickToolbarTextStyleButton];
        
    } forItemIdentity:kToolBarTextStyleItemIdentity];
    
    // text reader
    [self p_registerToolbarItemConfigProvider:^(UIView<AWETextToolStackViewProtocol> * _Nonnull stackView,
                                                AWETextStackViewItemConfig *itemConfig) {
        @strongify(self);
        NSString *textReaderImgName;
        BOOL isTextReaderEnable    = [self p_isTextReaderEnableForCurrentText];
        BOOL isTextReaderEffective = [self p_isTextReaderEffectiveForCurrentText];
        
        if (!isTextReaderEnable || !isTextReaderEffective) {
            textReaderImgName = @"icTextSpeakNormal";
        } else {
            textReaderImgName = @"icTextSpeakSelect";
        }
        
        itemConfig.enable = isTextReaderEnable;
        itemConfig.iconImage = ACCResourceImage(textReaderImgName);
        itemConfig.title = @"文字转语音";
        
    } clickHandler:^(UIView<AWETextToolStackViewProtocol> * _Nonnull stackView) {
        @strongify(self);
        [self didClickToolbarTextReaderButton];
        
    } forItemIdentity:kToolBarTextReadItemIdentity];
    
}
- (void)p_registerToolbarItemConfigProvider:(AWETextStackViewItemConfigProvider)provider
                               clickHandler:(AWETextStackViewItemClickHandler)clickHandler
                            forItemIdentity:(AWETextStackViewItemIdentity)itemIdentity
{
    [self.topTextToolBar registerItemConfigProvider:provider clickHandler:clickHandler forItemIdentity:itemIdentity];
    
    [self.modernTextToolBar registerItemConfigProvider:provider clickHandler:clickHandler forItemIdentity:itemIdentity];
}

- (void)p_resetTextToobarColorViewShowStatus;
{
    if (self.modernTextToolBar.isShowingColorView) {
        [self.modernTextToolBar updateColorViewShowStatus:NO];
        [self.topTextToolBar updateBarItemWithItemIdentity:kToolBarColorItemIdentity];
    }
}

#pragma mark - Keyboard

- (void)addObservers
{
    [self removeObservers];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardChangeFrameNoti:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardDidShowNotification:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleTextDidChangeNotification:)
                                                 name:UITextViewTextDidChangeNotification
                                               object:self.editingStickerView.textView];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleKeyboardChangeFrameNoti:(NSNotification *)noti
{
    if (!self.window || !self.superview || self.editingStickerView == nil || self.libPannel) {
        return;
    }
    
    CGRect keyboardBounds;
    [[noti.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardBounds];
    
    self.editingStickerView.textModel.keyboardHeight = (keyboardBounds.size.height > 0) ? keyboardBounds.size.height : 260;
    [self.editingStickerView updateDisplay];
}

- (void)handleKeyboardDidShowNotification:(NSNotification *)notification
{
    if (self.libPannel) {
        return;
    }
    [self p_showTextReadHintViewIfNeeded];
}

- (void)handleTextDidChangeNotification:(NSNotification *)notification
{
    if (notification.object != self.editingStickerView.textView || self.libPannel) {
        return;
    }
    [self p_updateToolBarTextReaderIcon];
}

#pragma mark -

- (BOOL)isCurrentDragActive
{
    BOOL dragActive = NO;
    if (@available(iOS 11.0, *)) {
        dragActive = self.editingStickerView.textView.textDragActive;
    }
    return dragActive;
}

- (void)didClickedTextMaskView
{
    if ([self isCurrentDragActive]) {
            return;
        }
    if (self.libPannel) {
        [self existTextLibStatus];
    } else {
        [self stopEditFromSaveButton:NO];
    }
}

- (void)didClickedSaveButton:(UIButton *)button
{
    if ([self isCurrentDragActive]) {
            return;
        }
    [self stopEditFromSaveButton:YES];
}

- (void)stopEditFromSaveButton:(BOOL)fromSaveButton
{
    @weakify(self);
    [self endEditing:YES];
    
    self.editingStickerView.searchKeyworkChangedBlock = nil;
    [self.toolbarContainer switchToToolbarType:ACCTextStickerEditToolbarTypeNormal];
    self.recommendInputController = nil;
    [self.modernTextToolBar updateWithRecommendTitles:@[]];
    
    [_editingStickerView restoreToSuperView:_orignalSuperView animationDuration:0.35 animationBlock:^{
        @strongify(self);
        self.lowerMaskView.alpha = 0;
        self.saveButton.alpha = 0;
        self.saveButton.hidden = YES;
        self.libPannel.hidden = YES;
        self.topTextToolBar.alpha = 0.f;
        self.topTextToolBar.hidden = YES;
        if (self.finishEditAnimationBlock) {
            self.finishEditAnimationBlock(self.editingStickerView);
        }
    } completion:^{
        @strongify(self);
        if (self.onEditFinishedBlock) {
            self.onEditFinishedBlock(self.editingStickerView, fromSaveButton);
        }
        self.upperMaskView.alpha = 0;
        self.editingStickerView = nil;
        [self.soundEffectsSelectionView removeFromSuperview];
        self.soundEffectsSelectionView = nil;
    }];
}

#pragma Mark - public
- (void)startEditStickerView:(ACCTextStickerView *)stickerView
{
    [self startEditStickerView:stickerView inputMode:ACCTextStickerEditEnterInputModeKeyword];
}

- (void)startEditStickerView:(ACCTextStickerView *)stickerView inputMode:(ACCTextStickerEditEnterInputMode)inputMode
{
    AWEStoryTextImageModel *textModel = stickerView.textModel;
    
    if (self.stylePreferenceModel.enableUsingUserPreference) {
        
        if (!textModel.fontModel) {
            textModel.fontModel = self.stylePreferenceModel.preferenceTextFont;
        }
        
        if (!textModel.fontColor) {
            textModel.fontColor = self.stylePreferenceModel.preferenceTextColor;
        }
    }
    
    if (!textModel.fontModel) {
        textModel.fontModel = [ACCCustomFont() stickerFonts].firstObject;
    }
    
    if (!textModel.fontColor) {
        textModel.fontColor = [AWEStoryColorChooseView storyColors].firstObject;
    }

    _orignalSuperView = stickerView.superview;
    _editingStickerView = stickerView;
    if (self.startEditBlock) {
        self.startEditBlock(stickerView);
    }
    
    [self updateModernTextBarWithTextModel:textModel];
    [self.topTextToolBar updateAllBarItems];
    
    if ([ACCTextStickerRecommendDataHelper enableRecommend]) {
        ACCTextStickerRecommendInputController *recommendController = [[ACCTextStickerRecommendInputController alloc] initWithStickerView:stickerView publishViewModel:self.publishViewModel];
        recommendController.toolBar = self.modernTextToolBar;
        recommendController.fromTextMode = self.fromTextMode;
        self.recommendInputController = recommendController;
        
        if (inputMode == AWEModernTextRecommendModeLib) {
            self.libPannel = [self generateLibPannel];
            self.editingStickerView.textView.inputView = self.libPannel;
            self.topTextToolBar.hidden = YES;
            self.saveButton.hidden = YES;
            [self.recommendInputController switchInputMode:YES];
            [self.recommendInputController trackForEnterLib:YES];
        } else {
            self.editingStickerView.textView.inputView = nil;
        }
    }

    [self p_bindInputAccessoryView:inputMode];
    
    self.upperMaskView.alpha = 1;
    [stickerView transportToEditWithSuperView:self.upperMaskView animation:^{
        self.lowerMaskView.alpha = 1;
        self.saveButton.alpha = 1;
        self.topTextToolBar.alpha = 1.f;
        if (inputMode != AWEModernTextRecommendModeLib) {
            self.saveButton.hidden = NO;
            self.topTextToolBar.hidden = NO;
        }
    } animationDuration:0.35];
    
    [self p_resetTextToobarColorViewShowStatus];
    
    [self p_associationSocialBindIfEnable];
    [self p_associationTextViewBindIfEnable];
}

- (void)p_bindInputAccessoryView:(ACCTextStickerEditEnterInputMode)inputMode
{
    if (inputMode == ACCTextStickerEditEnterInputModeKeyword) {
        if (self.supportTextStickerSocialBind) {
            self.editingStickerView.textView.inputAccessoryView = self.toolbarContainer;
        } else {
            self.editingStickerView.textView.inputAccessoryView = self.modernTextToolBar;
        }
    } else {
        self.editingStickerView.textView.inputAccessoryView = nil;
    }
}

- (void)p_associationSocialBindIfEnable
{
    if (!self.supportTextStickerSocialBind) {
        return;
    }
    
    self.socialToolbar.trackInfo = @{@"at_selected_from" : self.editingStickerView.textModel.isAutoAdded? @"auto":@"text_entrance"};
        
    @weakify(self);
    [self.editingStickerView setSearchKeyworkChangedBlock:^(BOOL needSearch, ACCTextStickerExtraType searchType, NSString * _Nonnull keyword) {
        @strongify(self);
        [self updateSearchKeyworkBarStatus:needSearch keywork:keyword searchType:searchType];
    }];
    
    self.editingStickerView.willChangeTextInRangeBlock = ^(NSString * _Nonnull replacementText, NSRange range) {
        @strongify(self);
        if ([replacementText isEqualToString:@"@"] || [replacementText isEqualToString:@"#"])
            ACCBLOCK_INVOKE(self.triggeredSocialEntraceBlock, NO, [replacementText isEqualToString:@"@"]);
    };
    
    ACCTextStickerInputController *inputController = self.editingStickerView.inputController;
    
    NSInteger totalStickerMentionCount = 0;
    NSInteger totalStickerHashtagCount = 0;
    if (self.stickerTotalMentionBindCountProvider) {
        totalStickerMentionCount = self.stickerTotalMentionBindCountProvider();
    }
    if (self.stickerTotalHashtagBindCountProvider) {
        totalStickerHashtagCount = self.stickerTotalHashtagBindCountProvider();
    }

    // 每个文字贴纸最大能绑定的个数
    NSInteger oneTextStickerMaxBindCount = [ACCTextStickerSettingsConfig singleTextStickerEachSociaMaxBindCount];
    // 所有贴纸共享的最大绑定数量
    NSInteger allStickerMaxBindCount = [ACCTextStickerSettingsConfig allStickerEachSociaMaxBindCount];

    NSInteger currentStickerMentionCount = [inputController numberOfExtrasForType:ACCTextStickerExtraTypeMention];
    NSInteger currentStickerHashtagCount = [inputController numberOfExtrasForType:ACCTextStickerExtraTypeHashtag];

    self.totalStickerMentionCountExcludeSelfWhenEditing = totalStickerMentionCount - currentStickerMentionCount;
    self.totalStickerHashtagCountExcludeSelfWhenEditing = totalStickerHashtagCount - currentStickerHashtagCount;
    
    // 单条文本最大输入 和 总的剩余能输入 取两者小值, 注意要减去本身占用的
    inputController.maxHashtagCount = MIN(oneTextStickerMaxBindCount, allStickerMaxBindCount - self.totalStickerHashtagCountExcludeSelfWhenEditing);
    
    inputController.maxMentionCount = MIN(oneTextStickerMaxBindCount, allStickerMaxBindCount - self.totalStickerMentionCountExcludeSelfWhenEditing);
    
    [inputController updateSearchKeywordStatus];
}

- (void)p_associationTextViewBindIfEnable
{
    @weakify(self);
    self.editingStickerView.textSelectedChangeBlock = ^(NSRange range) {
        @strongify(self);
        [self.recommendInputController didSelectKeyboardInput:range];
    };
}

- (void)updateSearchKeyworkBarStatus:(BOOL)needShow
                             keywork:(NSString *)keyword
                          searchType:(ACCTextStickerExtraType)searchType
{
    BOOL isMention = (searchType == ACCTextStickerExtraTypeMention);
    BOOL shouldForbidShow = (isMention && self.notSupportMention);
    if (needShow && !shouldForbidShow) {
        [self.toolbarContainer switchToToolbarType:ACCTextStickerEditToolbarTypeSocial];
        self.socialToolbar.stickerType = isMention? ACCSocialStickerTypeMention : ACCSocialStickerTypeHashTag;
        [self.socialToolbar searchWithKeyword:keyword];
    } else {
        [self.toolbarContainer switchToToolbarType:ACCTextStickerEditToolbarTypeNormal];
    }
}

#pragma mark - getters
- (ACCTextStickerEditWrapedToobarContainer *)toolbarContainer
{
    if (!self.supportTextStickerSocialBind) {
        return nil;
    }
    if (!_toolbarContainer) {
        CGFloat maxBarHeight = MAX([AWEModernTextToolBar barHeight:[ACCTextStickerRecommendDataHelper textBarRecommendMode]], [ACCSocialStickerEditToolbar defaulBarHeight]);
        _toolbarContainer = [[ACCTextStickerEditWrapedToobarContainer alloc] initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, maxBarHeight) normalToolBar:self.modernTextToolBar socialToolBar:self.socialToolbar];
    }
    return _toolbarContainer;
}

- (AWEModernTextToolBar *)modernTextToolBar
{
    if (!_modernTextToolBar) {
        NSArray <AWETextStackViewItemIdentity> *itemIdentityList = nil;
        if (self.supportTextStickerSocialBind) {
            if (self.notSupportMention) {
                itemIdentityList = @[kToolBarHashtagItemIdentity];
            } else {
                itemIdentityList = @[kToolBarMentionItemIdentity, kToolBarHashtagItemIdentity];
            }
        }
        AWEModernTextRecommendMode mode = [ACCTextStickerRecommendDataHelper textBarRecommendMode];
        _modernTextToolBar = [[AWEModernTextToolBar alloc] initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, [AWEModernTextToolBar barHeight:mode]) barItemIdentityList:itemIdentityList];
        [_modernTextToolBar configRecommendStyle:mode];
        if (mode & AWEModernTextRecommendModeRecommend) {
            @weakify(self);
            _modernTextToolBar.didSelectedTitleBlock = ^(NSString *title) {
                @strongify(self);
                [self.recommendInputController didSelectRecommendTitle:title group:nil];
                [self.topTextToolBar updateBarItemWithItemIdentity:kToolBarTextReadItemIdentity];
            };
            _modernTextToolBar.didExposureTitleBlock = ^(NSString *title) {
                @strongify(self);
                [self.recommendInputController didShowRecommendTitle:title group:nil];
            };
        }
        if (mode & AWEModernTextRecommendModeLib) {
            @weakify(self);
            _modernTextToolBar.didCallTitleLibBlock = ^{
                @strongify(self);
                [self enterTextLibStatus];
            };
        }
    }
    return _modernTextToolBar;
}

- (ACCSocialStickerEditToolbar *)socialToolbar
{
    if (!self.supportTextStickerSocialBind) {
        return nil;
    }
    if (!_socialToolbar) {
        _socialToolbar = [[ACCSocialStickerEditToolbar alloc] initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, [ACCSocialStickerEditToolbar defaulBarHeight]) publishModel:self.publishViewModel];
        
        @weakify(self);
        [_socialToolbar setOnSelectMention:^(ACCSocialStickeMentionBindingModel * _Nonnull mentionBindingData) {
            @strongify(self);
            ACCTextStickerExtraModel *extraModel =  [ACCTextStickerExtraModel mentionExtraWithUserId:mentionBindingData.userId secUserID:mentionBindingData.secUserId nickName:mentionBindingData.userName followStatus:mentionBindingData.followStatus];
            
            [self.editingStickerView.inputController appendTextExtraWithExtra:extraModel];
        }];
        [_socialToolbar setOnSelectHashTag:^(ACCSocialStickeHashTagBindingModel * _Nonnull hashTagBindingData) {
            @strongify(self);
            ACCTextStickerExtraModel *extraModel =  [ACCTextStickerExtraModel hashtagExtraWithHashtagName:hashTagBindingData.hashTagName];
            
            [self.editingStickerView.inputController appendTextExtraWithExtra:extraModel];
        }];
    }
    return _socialToolbar;
}

- (AWETextTopBar *)topTextToolBar
{
    if (!_topTextToolBar) {
        
        NSMutableArray <AWETextStackViewItemIdentity> *topbarViewItemIdentityList = [NSMutableArray array];
        [topbarViewItemIdentityList addObjectsFromArray:@[kToolBarAlignmentItemIdentity,
                                                          kToolBarColorItemIdentity,
                                                          kToolBarTextStyleItemIdentity]];
        if (self.supportTextBarTextReadingEntrance) {
            [topbarViewItemIdentityList addObject:kToolBarTextReadItemIdentity];
        }
        _topTextToolBar = [[AWETextTopBar alloc] initWithBarItemIdentityList:[topbarViewItemIdentityList copy]];
    }
    return _topTextToolBar;
}

- (BOOL)p_isTextReaderEnableForCurrentText
{
    NSCharacterSet *charSet = [NSCharacterSet whitespaceCharacterSet];
    NSString *trimmedString = [self.editingStickerView.textView.text stringByTrimmingCharactersInSet:charSet];
    return !ACC_isEmptyString(trimmedString);
}

- (BOOL)p_isTextReaderEffectiveForCurrentText
{
    if (![self p_isTextReaderEnableForCurrentText]) {
        return NO;
    }
    
    return ACCBLOCK_INVOKE(self.getTextReaderModelBlock).useTextRead;
}

- (AWEStoryTextImageModel *)textModel
{
    return self.editingStickerView.textModel;
}

#pragma mark - toobar item click event
- (void)didClickToolbarTextStyleButton
{
    AWEStoryTextImageModel *model = self.editingStickerView.textModel;
    AWEStoryTextStyle style = (model.textStyle + 1) % AWEStoryTextStyleCount;
    model.textStyle = style;
    [self.editingStickerView updateDisplay];
    if (self.didChangeStyleBlock) {
        self.didChangeStyleBlock(style);
    }
}

- (void)didClickToolbarAlignmentButton
{
    AWEStoryTextImageModel *model = self.editingStickerView.textModel;
    AWEStoryTextAlignmentStyle type = (model.alignmentType + 1) % AWEStoryTextAlignmentCount;
    model.alignmentType = type;
    [self.editingStickerView updateDisplay];
    
    if (self.didChangeAlignmentBlock) {
        self.didChangeAlignmentBlock(type);
    }
}

- (void)didClickToolbarTextReaderButton
{
    //Check
    NSDictionary *configs = ACCConfigDict(kConfigDict_text_read_sticker_configs);
    NSInteger editTextReadingMaxCount = [configs acc_integerValueForKey:@"read_text_char_count"] ? : 300;
    NSUInteger characterLength = [self.editingStickerView.textView.text lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    if (characterLength > editTextReadingMaxCount) {
        [self p_showToastWithText:ACCLocalizedString(@"creation_edit_text_reading_voice_toast2", @"Text too long to create speech audio")];
        return;
    } else if (characterLength <= 0) {
        [self p_showToastWithText:ACCLocalizedString(@"creation_edit_text_reading_voice_toast4", @"暂时只支持中文朗读")];
        return;
    }
    NSCharacterSet *charSet = [NSCharacterSet whitespaceCharacterSet];
    NSString *trimmedString = [self.editingStickerView.textView.text stringByTrimmingCharactersInSet:charSet];
    if ([trimmedString isEqualToString:@""]) {
        // it's empty or contains only white spaces
        [self p_showToastWithText:ACCLocalizedString(@"creation_edit_text_reading_voice_toast4", @"暂时只支持中文朗读")];
        return;
    }
    [self.soundEffectsSelectionView removeFromSuperview];
    self.soundEffectsSelectionView = [[ACCTextReaderSoundEffectsSelectionView alloc] initWithFrame:self.frame];
    @weakify(self);
    self.soundEffectsSelectionView.getTextReaderModelBlock = ^AWETextStickerReadModel * _Nonnull {
        @strongify(self);
        return ACCBLOCK_INVOKE(self.getTextReaderModelBlock);
    };
    self.soundEffectsSelectionView.didTapFinishCallback = ^(NSString * _Nonnull audioFilePath, NSString * _Nonnull speakerID, NSString * _Nonnull speakerName) {
        @strongify(self);
        self.saveButton.alpha = 1;
        self.saveButton.hidden = NO;
        self.topTextToolBar.alpha = 1.f;
        self.topTextToolBar.hidden = NO;
        [self.editingStickerView.textView becomeFirstResponder];
        [self.soundEffectsSelectionView removeFromSuperview];
        self.soundEffectsSelectionView = nil;
        ACCBLOCK_INVOKE(self.didTapFinishCallback, audioFilePath, speakerID, speakerName);
        [self p_updateToolBarTextReaderIcon];
    };
    self.soundEffectsSelectionView.didSelectSoundEffectCallback = ^(NSString * _Nullable audioFilePath, NSString * _Nullable audioSpeakerID) {
        @strongify(self);
        ACCBLOCK_INVOKE(self.didSelectTTSAudio, audioFilePath, audioSpeakerID);
    };
    self.saveButton.alpha = 0;
    self.topTextToolBar.alpha = 0.f;
    [self addSubview:self.soundEffectsSelectionView];
    ACCMasMaker(self.soundEffectsSelectionView, {
        make.edges.equalTo(self);
    });
    [self endEditing:YES];
    ACCBLOCK_INVOKE(self.startSelectingTTSAudioBlock);
}

#pragma mark -  recommend
- (void)enterTextLibStatus
{
    self.libPannel = [self generateLibPannel];
    self.topTextToolBar.hidden = YES;
    self.saveButton.hidden = YES;
    self.userInteractionEnabled = NO;
    [self.recommendInputController switchInputMode:YES];
    [self.recommendInputController trackForEnterLib:NO];
    [self.editingStickerView.textView resignFirstResponder];
    // 优化切换键盘体验
    @weakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self);
        self.editingStickerView.textView.inputView = self.libPannel;
        [self p_bindInputAccessoryView:ACCTextStickerEditEnterInputModeTextLib];
        [self.editingStickerView.textView becomeFirstResponder];
        self.userInteractionEnabled = YES;
    });
}

- (void)existTextLibStatus
{
    self.topTextToolBar.hidden = NO;
    self.saveButton.hidden = NO;
    self.userInteractionEnabled = NO;
    [self.recommendInputController switchInputMode:NO];
    [self.editingStickerView.textView resignFirstResponder];
    self.libPannel = nil;
    // 优化切换键盘体验
    @weakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self);
        self.editingStickerView.textView.inputView = nil;
        [self p_bindInputAccessoryView:ACCTextStickerEditEnterInputModeKeyword];
        [self.editingStickerView.textView becomeFirstResponder];
        self.userInteractionEnabled = YES;
    });
}

- (ACCTextStickerLibPannelView *)generateLibPannel
{
    ACCTextStickerLibPannelView *libPannel = [[ACCTextStickerLibPannelView alloc] initWithFrame:CGRectMake(0.f, 0.f, ACC_SCREEN_WIDTH, [ACCTextStickerLibPannelView panelHeight])];
    libPannel.publishViewModel = self.publishViewModel;
    @weakify(self);
    libPannel.onTitleSelected = ^(NSString *title, NSString *tabName) {
        @strongify(self);
        [self.recommendInputController didSelectRecommendTitle:title group:tabName];
        [self.topTextToolBar updateBarItemWithItemIdentity:kToolBarTextReadItemIdentity];
    };
    libPannel.onTitleExposured = ^(NSString *title, NSString *tabName) {
        @strongify(self);
        [self.recommendInputController didShowRecommendTitle:title group:tabName];
    };
    libPannel.onGroupSelected = ^(NSString *group) {
        @strongify(self);
        [self.recommendInputController didSelectLibGroup:group];
    };
    NSString *lastText = self.editingStickerView.textView.text;
    libPannel.onDismiss = ^(BOOL save) {
        @strongify(self);
        if (!save) {
            [self.recommendInputController resetToContent:lastText];
        }
        [self.recommendInputController didExitLibPanel:save];
        [self existTextLibStatus];
    };
    [libPannel updateWithItems:self.publishViewModel.repoSticker.textLibItems];
    return libPannel;
}

#pragma mark -  update

- (void)updateModernTextBarWithTextModel:(AWEStoryTextImageModel *)textModel
{
    { // font
        NSArray<AWEStoryFontModel *> *allFonts = [ACCCustomFont().stickerFonts copy];
        __block NSUInteger fontIndex = NSNotFound;
        [allFonts enumerateObjectsUsingBlock:^(AWEStoryFontModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (textModel.fontModel.title && [obj.title isEqualToString:textModel.fontModel.title]) {
                fontIndex = idx;
                *stop = YES;
            }
        }];
        
        if (fontIndex != NSNotFound) {
            textModel.fontIndex = [NSIndexPath indexPathForRow:fontIndex inSection:0];
        } else {
            if (textModel.fontIndex == nil
                || textModel.fontIndex.row >= allFonts.count) {
                textModel.fontIndex = [NSIndexPath indexPathForRow:0 inSection:0];
            }
        }
        
        [self.modernTextToolBar selectWithFontId:textModel.fontModel.effectId];
    }

    { // color
        UIColor *color = textModel.fontColor.color;
        if (color && ![self.modernTextToolBar.selectedColor.color isEqual:color]) {
            [self.modernTextToolBar selectWithColor:color];
        }
    }

    { // tool bar item
        [self.modernTextToolBar updateAllBarItems];
    }
    
    { // recommend bar
        if (!self.fromTextMode) {
            [self.modernTextToolBar updateWithRecommendTitles:self.publishViewModel.repoSticker.directTitles];
        }
    }
}

- (void)p_updateToolBarTextReaderIcon
{
    [self.topTextToolBar updateBarItemWithItemIdentity:kToolBarTextReadItemIdentity];
}

#pragma mark - util
- (void)p_showTextReadHintViewIfNeeded
{
    if (!self.supportTextBarTextReadingEntrance || ![self p_shouldShowTextReadHintView]) {
        return;
    }
    
    if (!self.topTextToolBar.superview) {
        return;
    }
    
    [ACCCache() setBool:YES forKey:kShowSpeakerHintView];
    [ACCBubble() showBubble:@"试试文字朗读功能" forView:self.topTextToolBar inContainerView:self.topTextToolBar.superview anchorAdjustment:CGPointMake([self.topTextToolBar itemViewCenterOffsetWithItemIdentity:kToolBarTextReadItemIdentity].x, 0) inDirection:ACCBubbleDirectionDown bgStyle:ACCBubbleBGStyleDark completion:nil];
}

- (BOOL)p_shouldShowTextReadHintView
{
    return ![ACCCache() boolForKey:kShowSpeakerHintView];
}

- (void)p_showToastWithText:(NSString *)text
{
    NSArray *windows = [[UIApplication sharedApplication] windows];
    UIWindow *lastWindow = (UIWindow *)[windows lastObject];
    [ACCToast() show:text onView:lastWindow];
}

@end
