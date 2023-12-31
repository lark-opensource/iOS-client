//
//  ACCTextStickerComponent.m
//  Pods
//
//  Created by chengfei xiao on 2019/10/21.
//

#import "AWERepoContextModel.h"
#import "ACCTextStickerComponent.h"
#import <CreationKitArch/ACCCustomFontProtocol.h>
#import <CameraClient/AWEVideoPublishViewModel+FilterEdit.h>

#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCEditViewContainer.h>
#import "ACCVideoEditToolBarDefinition.h"
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import "AWEStoryColorChooseView.h"
#import "AWEStoryFontChooseView.h"
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CameraClient/ACCRepoQuickStoryModel.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>

#import <CreationKitArch/ACCEditAndPublishConstants.h>
#import "ACCFriendsServiceProtocol.h"
#import "ACCStickerBizDefines.h"
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import "ACCLVAudioRecoverUtil.h"
#import "ACCEditTransitionServiceProtocol.h"
#import <CameraClient/ACCRepoQuickStoryModel.h>
#import "ACCTextStickerTextModelHelper.h"

#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import "ACCTextStickerView.h"
#import <CreativeKitSticker/ACCStickerContainerView+ACCStickerCopying.h>
#import <CameraClient/ACCEditAudioEffectProtocolD.h>
#import "ACCTextStickerContainerConfigProtocol.h"
#import <CameraClient/AWERepoDraftModel.h>
#import "ACCEditStickerSelectTimeManager.h"
#import "ACCRepoImageAlbumInfoModel.h"
#import "ACCTextStickerHandler.h"
#import "ACCStickerServiceProtocol.h"
#import "ACCDraftResourceRecoverProtocol.h"
#import "ACCImageAlbumData.h"
#import "ACCVideoEditStickerContainerConfig.h"
#import <CreationKitArch/ACCModelFactoryServiceProtocol.h>
#import "AWERepoVideoInfoModel.h"
#import <CreationKitInfra/ACCLogHelper.h>
#import <CameraClient/ACCRepoTextModeModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CameraClient/ACCRepoBirthdayModel.h>
#import <CameraClient/ACCEditMusicServiceProtocol.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitArch/ACCRepoPublishConfigModel.h>
#import <CameraClient/ACCRepoKaraokeModelProtocol.h>
#import <CameraClient/ACCInteractionStickerFontHelper.h>
#import <CreationKitArch/AWEInteractionStickerModel.h>
#import <CameraClient/AWERepoStickerModel.h>
#import "ACCEditBarItemExtraData.h"
#import "ACCTextStickerConfig.h"
#import "IESInfoSticker+ACCAdditions.h"
#import "ACCEditImageAlbumMixedProtocolD.h"
#import "ACCBarItem+Adapter.h"
#import "ACCToolBarAdapterUtils.h"
#import "ACCTextStickerRecommendDataHelper.h"
#import "ACCWishStickerServiceProtocol.h"

#import "ACCTextStickerServiceProtocol.h"
#import "ACCTextStickerServiceImpl.h"
#import <CreationKitInfra/NSDictionary+ACCAddition.h>

@interface ACCTextStickerComponent ()
<ACCTextStickerDataProvider, ACCStickerServiceSubscriber, ACCDraftResourceRecoverProtocol>

@property (nonatomic, strong) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCStickerServiceProtocol> stickerService;
@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;
@property (nonatomic, strong) id<ACCEditTransitionServiceProtocol> transitionService;
@property (nonatomic, weak)  id<ACCEditAudioEffectProtocol> audioEffectService;
@property (nonatomic, strong) id<ACCTextStickerContainerConfigProtocol> configService;
@property (nonatomic, weak) id<ACCEditMusicServiceProtocol> musicService;
@property (nonatomic, weak) id<ACCWishStickerServiceProtocol> wishService;

@property (nonatomic, strong) ACCTextStickerHandler *textStickerHandler;
@property (nonatomic, strong) ACCTextStickerServiceImpl *serviceImpl;
@property (nonatomic, strong) ACCEditStickerSelectTimeManager *selectTimeManager;
/// Story guide
@property (nonatomic, strong) UIView *storyTextInputGuide;

@end

@implementation ACCTextStickerComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, stickerService, ACCStickerServiceProtocol)
IESAutoInject(self.serviceProvider, configService, ACCTextStickerContainerConfigProtocol);
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, audioEffectService, ACCEditAudioEffectProtocol)
IESAutoInject(self.serviceProvider, transitionService, ACCEditTransitionServiceProtocol)
IESAutoInject(self.serviceProvider, musicService, ACCEditMusicServiceProtocol)
IESAutoInject(self.serviceProvider, wishService, ACCWishStickerServiceProtocol)

#pragma mark - ACCComponentProtocol

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCTextStickerServiceProtocol),
                                   self.serviceImpl);
}

- (void)loadComponentView {
    [self.viewContainer addToolBarBarItem:[self barItem]];
    
}

- (void)componentDidMount {
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    
    // 文字模式进入的时候会将标题转换为文字贴纸
    if (self.repository.repoTextMode.textModel) {
        [self p_addTextStickerWithTextModel:self.repository.repoTextMode.textModel locationModel:nil];
    }
    if (self.repository.repoContext.videoType == AWEVideoTypeNewYearWish) {
        [self.repository.repoSticker syncWishDirectTitles];
    } else if (!self.repository.repoSticker.directTitles.count) {
        [ACCTextStickerRecommendDataHelper requestBasicRecommend:self.repository completion:nil];
    }
    [self bindViewModel];
}

- (void)componentWillAppear {
    [self p_addTextInputGuideIfNeeded];
    if (self.repository.repoFlowControl.step != AWEPublishFlowStepCapture) {
        [ACCLVAudioRecoverUtil recoverAudioIfNeededWithOption:ACCLVFrameRecoverAll publishModel:self.repository editService:self.editService];
    }
}

- (void)componentDidAppear
{
    /// @todo @qiuhang 一大坨业务老代码很难受 尽快迁到sticker config
    [self p_addDateTextSticker];
    [self p_addAvatarTextSticker];
    [self p_addBirthdayTextSticker];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider {
    [self p_registService];
}

- (void)bindViewModel {
    @weakify(self);
    if (self.repository.repoContext.videoType != AWEVideoTypeNewYearWish) {
        [[[self musicService].featchFramesUploadStatusSignal deliverOnMainThread] subscribeNext:^(RACTwoTuple<NSString *,NSError *> * _Nullable x) {
            @strongify(self);
            [ACCTextStickerRecommendDataHelper requestBasicRecommend:self.repository completion:nil];
            [ACCTextStickerRecommendDataHelper requestLibList:self.repository completion:nil];
        }];
    } else {
        [[[self wishService].addWishTextStickerSignal deliverOnMainThread] subscribeNext:^(NSString *x) {
            @strongify(self)
            AWEStoryTextImageModel *textInfo = [self p_defaultTextInfo];
            textInfo.content = x;
            textInfo.isNotDeletableSticker = YES;
            NSDictionary *wishDict = ACCConfigDict(kConfigDict_new_year_wish_default_font_setting);
            AWEStoryFontModel *fontModel = [ACCCustomFont() fontModelForName:[wishDict acc_stringValueForKey:@"font_type"]];
            if ([[NSFileManager defaultManager] fileExistsAtPath:fontModel.localUrl]) {
                textInfo.fontModel = fontModel;
            }
            AWEStoryColor *storyColor = [AWEStoryColor colorWithHexString:[wishDict acc_stringValueForKey:@"font_color"]];
            textInfo.fontColor = storyColor;
            
            ACCTextStickerView *textStickerView = [self.textStickerHandler addTextWithTextInfo:textInfo locationModel:nil constructorBlock:nil];
            // 校正初始位置
            UIView<ACCStickerProtocol> *stickerWrapper = (UIView<ACCStickerProtocol> *)textStickerView.superview;
            stickerWrapper.center = CGPointMake(stickerWrapper.center.x, stickerWrapper.center.y + 48.f);
            
            if (!x.length) {
                [self.textStickerHandler editTextStickerView:textStickerView];
            } else {
                [self.serviceImpl endEditTextStickerView:textStickerView];
            }
        }];
        
        [[[self wishService].replaceWishTextStickerSignal deliverOnMainThread] subscribeNext:^(ACCTextStickerView * _Nullable x) {
            @strongify(self);
            [self.textStickerHandler textEditFinishedForStickerView:x];
        }];
    }
}

- (void)p_addDateTextSticker
{
    AWEVideoPublishViewModel *viewModel = self.repository;
    
    if (!viewModel.repoSticker.dateTextStickerContent || viewModel.repoSticker.dateTextStickerContent.length == 0) {
        return;
    }
    [self p_addTextStickerWithTextModel:[self p_dateTextInfo] locationModel:[self p_dateStickerLocation]];
    viewModel.repoSticker.dateTextStickerContent = nil;
}

- (void)p_addAvatarTextSticker
{
    if (self.repository.repoDraft.isDraft) {
        return;
    }
    if (self.repository.repoQuickStory.isAvatarQuickStory && !ACCConfigBool(ACCConfigBOOL_profile_as_story_enable_silent_publish)) {
        AWEStoryTextImageModel *textInfo = [[AWEStoryTextImageModel alloc] init];
        textInfo.isAutoAdded = YES;
        textInfo.content = self.repository.repoSticker.imageText;
        textInfo.colorIndex = [NSIndexPath indexPathForRow:0 inSection:0];
        textInfo.fontIndex = [NSIndexPath indexPathForRow:0 inSection:0];
        textInfo.realDuration = self.repository.repoVideoInfo.video.totalVideoDuration;
        textInfo.textStyle = AWEStoryTextStyleNo;
        textInfo.fontModel = [[AWEStoryFontChooseView stickerFonts] acc_objectAtIndex:1];
        textInfo.fontColor = [AWEStoryColorChooseView storyColors].firstObject;
        textInfo.realStartTime = 0;
        CGFloat originalFontSize = 36;
        textInfo.fontSize = [ACCTextStickerTextModelHelper fitFontSizeWithContent:(NSString *)textInfo.content fontModel:textInfo.fontModel fontSize:originalFontSize];

        AWEInteractionStickerLocationModel *stickerLocation = [[AWEInteractionStickerLocationModel alloc] init];
        NSString *startTime = [NSString stringWithFormat:@"%.4f", 0.f];
        NSString *endTime = [NSString stringWithFormat:@"%.4f", self.repository.repoVideoInfo.video.totalVideoDuration * 1000];
        stickerLocation.startTime = [NSDecimalNumber decimalNumberWithString:startTime];
        stickerLocation.endTime = [NSDecimalNumber decimalNumberWithString:endTime];
        
        CGFloat offsetY = 90 * ([UIScreen mainScreen].bounds.size.height / 812);
        CGFloat scale = 0.9;
        NSString *offsetYStr = [NSString stringWithFormat:@"%.4f",(CGFloat)offsetY];
        NSString *scaleStr = [NSString stringWithFormat:@"%.4f",(CGFloat)scale];
        NSString *widthStr = [NSString stringWithFormat:@"%.4f",[UIScreen mainScreen].bounds.size.width];

        stickerLocation.y = [NSDecimalNumber decimalNumberWithString:offsetYStr];
        stickerLocation.scale = [NSDecimalNumber decimalNumberWithString:scaleStr];
        stickerLocation.width = [NSDecimalNumber decimalNumberWithString:widthStr];

        [self p_addTextStickerWithTextModel:textInfo locationModel:stickerLocation];
        self.repository.repoSticker.imageText = nil;
    }
}

- (void)p_addBirthdayTextSticker
{
    if (!self.repository.repoBirthday.isIMBirthdayPost || ACC_isEmptyString(self.repository.repoSticker.imageText)) {
        return;
    }
    AWEStoryTextImageModel *textInfo = [[AWEStoryTextImageModel alloc] init];
    textInfo.isAutoAdded = YES;
    textInfo.content = self.repository.repoSticker.imageText;
    textInfo.colorIndex = [NSIndexPath indexPathForRow:0 inSection:0];
    textInfo.fontIndex = [NSIndexPath indexPathForRow:0 inSection:0];
    textInfo.realDuration = self.repository.repoVideoInfo.video.totalVideoDuration;
    textInfo.textStyle = AWEStoryTextStyleNo;
    textInfo.fontModel = [[AWEStoryFontChooseView stickerFonts] acc_objectAtIndex:1];
    textInfo.fontColor = [AWEStoryColorChooseView storyColors].firstObject;
    textInfo.realStartTime = 0;
    textInfo.fontSize = [ACCTextStickerTextModelHelper fitFontSizeWithContent:(NSString *)textInfo.content fontModel:textInfo.fontModel fontSize:56.f];
    AWEInteractionStickerLocationModel *stickerLocation = [[AWEInteractionStickerLocationModel alloc] init];
    NSString *startTime = [NSString stringWithFormat:@"%.4f", 0.f];
    NSString *endTime = [NSString stringWithFormat:@"%.4f", self.repository.repoVideoInfo.video.totalVideoDuration * 1000];
    stickerLocation.startTime = [NSDecimalNumber decimalNumberWithString:startTime];
    stickerLocation.endTime = [NSDecimalNumber decimalNumberWithString:endTime];
    NSString *widthStr = [NSString stringWithFormat:@"%.4f",[UIScreen mainScreen].bounds.size.width];
    stickerLocation.width = [NSDecimalNumber decimalNumberWithString:widthStr];
    [self p_addTextStickerWithTextModel:textInfo locationModel:stickerLocation];
    self.repository.repoSticker.imageText = nil;
}

- (AWEStoryTextImageModel *)p_dateTextInfo
{
    AWEStoryTextImageModel *textInfo = [[AWEStoryTextImageModel alloc] init];
    textInfo.isAutoAdded = YES;
    textInfo.content = self.repository.repoSticker.dateTextStickerContent;
    textInfo.colorIndex = [NSIndexPath indexPathForRow:0 inSection:0];
    textInfo.realStartTime = 0;
    textInfo.realDuration = self.repository.repoVideoInfo.video.totalVideoDuration;
    textInfo.realStartTime = 0;
    if (self.repository.repoQuickStory.isAvatarQuickStory && !ACCConfigBool(ACCConfigBOOL_profile_as_story_enable_silent_publish)) {
        textInfo.textStyle = AWEStoryTextStyleNo;
        textInfo.fontColor = [AWEStoryColor colorWithHexString:@"0xFFFFFF" alpha:0.6];
        textInfo.fontModel = [[AWEStoryFontChooseView stickerFonts] acc_objectAtIndex:1];
    } else if (self.repository.repoQuickStory.isNewCityStory) {
        textInfo.textStyle = AWEStoryTextStyleNo;
        textInfo.fontColor = [AWEStoryColor colorWithHexString:@"0x000000" alpha:1];
        textInfo.fontModel = [[AWEStoryFontChooseView stickerFonts] acc_match:^BOOL(AWEStoryFontModel * _Nonnull item) {
            return [item.fontName isEqualToString:@"默陌专辑手写体"];
        }];
        if (!textInfo.fontModel) {
            textInfo.fontModel = [[AWEStoryFontChooseView stickerFonts] acc_objectAtIndex:1];
        } else if (!textInfo.fontModel.download) {
            textInfo.fontModel = [[AWEStoryFontChooseView stickerFonts] acc_objectAtIndex:1];
        }
        textInfo.fontSize = 21;
        textInfo.content = [textInfo.content stringByReplacingOccurrencesOfString:@"/" withString:@" . "];
    } else {
        textInfo.fontColor = [AWEStoryColorChooseView storyColors].firstObject;
        textInfo.textStyle = AWEStoryTextStyleBackground;
        textInfo.fontModel = [AWEStoryFontChooseView stickerFonts].firstObject;
    }
    textInfo.fontIndex = [NSIndexPath indexPathForRow:0 inSection:0];
    return textInfo;
}

- (AWEInteractionStickerLocationModel *)p_dateStickerLocation
{
    AWEInteractionStickerLocationModel *stickerLocation = [[AWEInteractionStickerLocationModel alloc] init];
    NSString *startTime = [NSString stringWithFormat:@"%.4f", 0.f];
    NSString *endTime = [NSString stringWithFormat:@"%.4f", self.repository.repoVideoInfo.video.totalVideoDuration * 1000];
    stickerLocation.startTime = [NSDecimalNumber decimalNumberWithString:startTime];
    stickerLocation.endTime = [NSDecimalNumber decimalNumberWithString:endTime];
    
    CGFloat offsetY;
    if (self.repository.repoQuickStory.isAvatarQuickStory && !ACCConfigBool(ACCConfigBOOL_profile_as_story_enable_silent_publish)) {
        offsetY = 130 * [UIScreen mainScreen].bounds.size.height / 812;
    } else if (self.repository.repoQuickStory.isNewCityStory){
        offsetY = 0.24 * (([UIScreen mainScreen].bounds.size.width / 9 * 16) + ACC_IPHONE_X_BOTTOM_OFFSET * 2);
    } else {
        offsetY = self.stickerService.stickerContainer.frame.size.height * 0.25;
    }
    
    CGFloat scale = 0.9;
    NSString *offsetYStr = [NSString stringWithFormat:@"%.4f",(CGFloat)offsetY];
    NSString *scaleStr = [NSString stringWithFormat:@"%.4f",(CGFloat)scale];
    stickerLocation.y = [NSDecimalNumber decimalNumberWithString:offsetYStr];
    stickerLocation.scale = [NSDecimalNumber decimalNumberWithString:scaleStr];
    return stickerLocation;
}

#pragma mark - Guide

- (void)p_addTextInputGuideIfNeeded
{
    BOOL shouldShowTextStickerBubble = YES;
    if (self.configService) {
        shouldShowTextStickerBubble = [self.configService shouldShowTextStickerBubble:self.repository];
    }

    if (!shouldShowTextStickerBubble) {
        return;
    }
    NSString *const textStickerShortcutGuideShownFlagKey = @"textStickerShortcutGuideShownFlagKey";
    BOOL isCanvasIntractionGuideEnabled = [IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) singlePhotoOptimizationABTesting].isCanvasInteractionGuideEnabled;
    BOOL hasCanvasInteractionGuideShown = [ACCCache() objectForKey:ACCCanvasInteractionGuideShowDateKey] != nil;
    if (![IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) isTextStickerShortcutEnabled]
        || [ACCCache() boolForKey:textStickerShortcutGuideShownFlagKey]
        || self.repository.repoContext.videoType == AWEVideoTypeReplaceMusicVideo
        || self.repository.repoContext.videoType == AWEVideoTypeNewYearWish
        || self.repository.repoTextMode.textModel != nil
        || [self.stickerService.stickerContainer stickerViewsWithTypeId:ACCStickerTypeIdText].count > 0
        || (isCanvasIntractionGuideEnabled && !hasCanvasInteractionGuideShown)) {
            return;
        }
    [ACCCache() setBool:YES forKey:textStickerShortcutGuideShownFlagKey];
    
    CGFloat guideW = 186.0;
    CGFloat guideH = 34.0;
    UIView *guideContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, guideW, guideH)];
    
    CAShapeLayer *innerLayer = CAShapeLayer.layer;
    CAShapeLayer *outerLayer = CAShapeLayer.layer;
    UIBezierPath *innerPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(9, 9, 14, 14)];
    UIBezierPath *outerPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 32, 32)];
    innerLayer.path = innerPath.CGPath;
    outerLayer.path = outerPath.CGPath;
    
    //inner layer
    innerLayer.fillColor = [UIColor.whiteColor colorWithAlphaComponent:0.7].CGColor;
    innerLayer.shadowRadius = 4.0;
    innerLayer.shadowOffset = CGSizeMake(0, 1);
    innerLayer.shadowColor = [UIColor.blackColor colorWithAlphaComponent:0.1].CGColor;
    
    //outer layer
    outerLayer.fillColor = [UIColor.whiteColor colorWithAlphaComponent:0.5].CGColor;
    outerLayer.strokeColor = [UIColor.blackColor colorWithAlphaComponent:0.05].CGColor;
    outerLayer.borderWidth = 1.0;
    
    [guideContainer.layer addSublayer:outerLayer];
    [guideContainer.layer addSublayer:innerLayer];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(40, 0, guideW - 40, guideH)];
    label.font = [ACCFont() systemFontOfSize:24.0];
    label.textColor = [UIColor.whiteColor colorWithAlphaComponent:0.8];

    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowBlurRadius = 5;
    shadow.shadowOffset = CGSizeMake(0, 0.5);
    shadow.shadowColor = [UIColor.blackColor colorWithAlphaComponent:0.3];
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:ACCLocalizedString(@"creation_edit_status_selfdefined_textdefault", nil) attributes:@{NSShadowAttributeName: shadow}];
    label.attributedText = attributedText;
    [guideContainer addSubview:label];
    guideContainer.userInteractionEnabled = NO;
    [self.viewContainer.containerView  addSubview:guideContainer];
    guideContainer.acc_centerX = self.viewContainer.containerView.acc_width / 2.0;
    guideContainer.acc_centerY = self.viewContainer.containerView.acc_height / 2.0;
    
    self.storyTextInputGuide = guideContainer;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.storyTextInputGuide removeFromSuperview];
        self.storyTextInputGuide = nil;
    });
}

#pragma mark - UI & Action

- (ACCBarItem<ACCEditBarItemExtraData*>*)barItem
{
    let config = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarTextContext];
    if (!config) return nil;
    ACCBarItem<ACCEditBarItemExtraData*>* item = [[ACCBarItem alloc] init];
    item.title = config.title;
    item.imageName = config.imageName;
    item.location = config.location;
    item.itemId = ACCEditToolBarTextContext;
    item.type = ACCBarItemFunctionTypeCover;
    @weakify(self);
    item.barItemActionBlock = ^(UIView * _Nonnull itemView) {
        @strongify(self);
        if (!self.isMounted) {
            return;
        }
        [self.viewContainer.topRightBarItemContainer resetFoldState];
        [self.stickerService deselectAllSticker];

        [self p_textButtonClicked];
    };
    item.extraData = [[ACCEditBarItemExtraData alloc] initWithButtonClass:nil type:AWEEditAndPublishViewDataTypeText];
    return item;
}

- (void)p_textButtonClicked
{
    if ([self p_canAddMoreText]) {
        [self p_showEditView:NO animation:YES];
        [self p_startTextSticker];
        // add an error toast if the stickFonts count is 0 when the font pannel will be displayed
        if ([ACCCustomFont() stickerFonts].count == 0) {
            [ACCToast() show:ACCLocalizedCurrentString(@"creation_text_load_fail")];
        }
    }
    
    //track
    NSMutableDictionary *params = [@{} mutableCopy];
    [params addEntriesFromDictionary:self.repository.repoTrack.referExtra];
    [params addEntriesFromDictionary:self.repository.repoTrack.mediaCountInfo];
    [params setValue:@"click_button" forKey:@"enter_method"];
    id<ACCRepoKaraokeModelProtocol> repoKaraokeModel = [self.repository extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
    [params addEntriesFromDictionary:([repoKaraokeModel.trackParams copy] ?: @{})];
    [ACCTracker() trackEvent:@"click_text_entrance" params:params needStagingFlag:NO];
}

#pragma mark - Sticker

- (void)p_registService {
    [self.stickerService registStickerHandler:self.textStickerHandler];
    [self.stickerService addSubscriber:self];
}

- (ACCTextStickerHandler *)textStickerHandler {
    if (!_textStickerHandler) {
        _textStickerHandler = [ACCTextStickerHandler new];
        _textStickerHandler.repoImageAlbumInfo = self.repository.repoImageAlbumInfo;
         _textStickerHandler.publishViewModel = self.repository;
        _textStickerHandler.dataProvider = self;
        _textStickerHandler.isImageAlbumEdit = self.repository.repoImageAlbumInfo.isImageAlbumEdit;
        @weakify(self);
        _textStickerHandler.onTimeSelect = ^(ACCTextStickerView * _Nonnull stickerView) {
            @strongify(self);
            [self p_selectTimeWithTextStickerView:stickerView];
        };
        _textStickerHandler.editViewOnStartEdit = ^(ACCTextStickerView * _Nonnull stickerView) {
            @strongify(self);
            [self p_showEditView:NO animation:YES];
            [[self editService].imageAlbumMixed setImagePlayerScrollEnable:NO];
            [[self stickerService] startEditingStickerOfType:ACCStickerTypeTextSticker];
            [self.serviceImpl startEditTextStickerView:stickerView];
            [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) stopAutoPlayWithKey:@"textEdit"];
        };
        _textStickerHandler.editViewOnFinishEdit = ^(ACCTextStickerView * _Nonnull stickerView) {
            @strongify(self);
            [self p_showEditView:YES animation:YES];
            [[self editService].imageAlbumMixed setImagePlayerScrollEnable:YES];
            [[self stickerService] finishEditingStickerOfType:ACCStickerTypeTextSticker];
            [self.serviceImpl endEditTextStickerView:stickerView];
        };
        
        _textStickerHandler.onFinishedEditAnimationCompletedBlock = ^{
            @strongify(self);
            [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) startAutoPlayWithKey:@"textEdit"];
        };
        _textStickerHandler.onStickerApplySuccess = ^{
            @strongify(self);
            [self p_onStickerApplySuccess];
        };
        
        AWETextStickerStylePreferenceModel *preferenceModel = [[AWETextStickerStylePreferenceModel alloc] init];
        preferenceModel.enableUsingUserPreference = YES;
        // 产品要求把文字tab的样式带进来
        if (self.repository.repoTextMode.isTextMode) {
            preferenceModel.preferenceTextFont = self.repository.repoTextMode.textModel.fontModel;
            preferenceModel.preferenceTextColor = self.repository.repoTextMode.textModel.fontColor;
        }
        _textStickerHandler.stylePreferenceModel = preferenceModel;
        
        if ([self isImageAlbumEdit]) {
            _textStickerHandler.panStart = ^{
                @strongify(self);
                [self p_showEditView:NO animation:YES];
            };
            _textStickerHandler.panEnd = ^{
                @strongify(self);
                [self p_showEditView:YES animation:YES];
            };
        }
    }
    return _textStickerHandler;
}

- (ACCEditStickerSelectTimeManager *)selectTimeManager
{
    if (!_selectTimeManager) {
        _selectTimeManager = [[ACCEditStickerSelectTimeManager alloc] initWithEditService:self.editService repository:self.repository player:self.stickerService.compoundHandler.player stickerContainer:self.stickerService.stickerContainer transitionService:self.transitionService];
    }
    return _selectTimeManager;
}

- (void)p_showEditView:(BOOL)show animation:(BOOL)animation
{
    self.repository.repoContext.isStickerEdited = YES;
    
    CGFloat alpha = show ? 1 : 0;
    if (show) {
        [[self stickerService] finishEditingStickerOfType:ACCStickerTypeTextSticker];
        if ([ACCToolBarAdapterUtils useToolBarFoldStyle]) {
            [self.viewContainer.topRightBarItemContainer resetFoldState];
        }
    } else {
        [[self stickerService] startEditingStickerOfType:ACCStickerTypeTextSticker];
    }
    
    if (animation) {
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) updateInteractionContainerAlpha:alpha];
            self.viewContainer.containerView.alpha = alpha;
        } completion:^(BOOL finished) {
            
        }];
    } else {
        [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) updateInteractionContainerAlpha:alpha];
        self.viewContainer.containerView.alpha = alpha;
    }
}

- (BOOL)p_canAddMoreText {
    return [self.stickerService canAddMoreText] && self.repository.repoContext.videoType != AWEVideoTypeNewYearWish;
}

- (void)p_startTextSticker {
    if (@available(iOS 11.0, *)) {
        UISelectionFeedbackGenerator *feedbackGenerator = [[UISelectionFeedbackGenerator alloc] init];
        [feedbackGenerator prepare];
        [feedbackGenerator selectionChanged];
    }
    
    AWEStoryTextImageModel *textInfo = [self p_defaultTextInfo];

    ACCTextStickerView *stickerView = [self.textStickerHandler addTextWithTextInfo:textInfo locationModel:nil constructorBlock:nil];
    [self.textStickerHandler editTextStickerView:stickerView];
}

- (AWEStoryTextImageModel *)p_defaultTextInfo
{
    AWEStoryTextImageModel *textInfo = [AWEStoryTextImageModel new];
    textInfo.colorIndex = [NSIndexPath indexPathForRow:0 inSection:0];
    textInfo.fontIndex = [NSIndexPath indexPathForRow:0 inSection:0];
    textInfo.realStartTime = 0;
    textInfo.realDuration = self.repository.repoVideoInfo.video.totalVideoDuration;
    textInfo.isAddedInEditView = YES;
    
    return textInfo;
}

- (void)p_addTextStickerWithTextModel:(AWEStoryTextImageModel *)textModel locationModel:(AWEInteractionStickerLocationModel * _Nullable)locationModel {
    [self.textStickerHandler addTextWithTextInfo:textModel locationModel:locationModel constructorBlock:^(ACCTextStickerConfig * _Nonnull config) {
        if (textModel.isNotEditableSticker) {
            config.editable = @NO;
            config.secondTapCallback = nil;
        }
    }];
}

#pragma mark - ACCStickerServiceSubscriber

- (void)onStartQuickTextInput {
    if ([self p_canAddMoreText]) {
        NSMutableDictionary *params = [@{} mutableCopy];
        [params addEntriesFromDictionary:self.repository.repoTrack.referExtra];
        [params addEntriesFromDictionary:self.repository.repoTrack.mediaCountInfo];
        params[@"enter_method"] = @"click_main";
        [ACCTracker() trackEvent:@"click_text_entrance" params:params needStagingFlag:NO];
        [self p_startTextSticker];
        // add an error toast if the stickFonts count is 0 when the font pannel will be displayed
        if ([ACCCustomFont() stickerFonts].count == 0) {
            [ACCToast() show:ACCLocalizedCurrentString(@"creation_text_load_fail")];
        }
    }
}

#pragma mark - Apply Succeed

- (void)p_onStickerApplySuccess {
    self.repository.repoSticker.hasTextAdded = YES;
}

#pragma mark - ACCTextStickerDataProvider

- (NSValue *)gestureInvalidFrameValue {
    return self.repository.repoSticker.gestureInvalidFrameValue;
}

- (NSString *)textStickerFolderForDraft {
    return [AWEDraftUtils generateDraftFolderFromTaskId:self.repository.repoDraft.taskID];
}

- (NSString *)textStickerImagePathForDraftWithIndex:(NSInteger)index {
    // fix AME-84121, if edit from draft, should not cover original path
    return [AWEDraftUtils generateModernTextImagePathFromTaskId:self.repository.repoDraft.taskID index:index];
}

- (void)storeTextInfoForAuditWith:(NSString *)imageText imageTextFonts:(NSString *)imageTextFonts imageTextFontEffectIds:(NSString *)imageTextFontEffectIds {
    // 添加文字信息，供审核
    self.repository.repoSticker.imageText = imageText;
    self.repository.repoSticker.imageTextFonts = imageTextFonts;
    self.repository.repoSticker.imageTextFontEffectIds = imageTextFontEffectIds;
}

- (void)addTextReadForKey:(NSString *)key asset:(AVAsset *)audioAsset range:(IESMMVideoDataClipRange *)audioRange
{
    [self.repository.repoSticker.textReadingAssets setObject:audioAsset forKey:key];
    [self.repository.repoSticker.textReadingRanges setObject:audioRange forKey:key];
    [ACCGetProtocol(self.editService.audioEffect, ACCEditAudioEffectProtocolD) hotAppendTextReadAudioAsset:audioAsset withRange:audioRange];
    [[self audioEffectService] setVolume:4.f forAudioAssets:@[audioAsset]];
    [[self audioEffectService] refreshAudioPlayer];
}

- (void)removeTextReadForKey:(NSString *)key
{
    AVAsset *toRemove = [self.repository.repoSticker audioAssetInVideoDataWithKey:key];
    [self.repository.repoSticker.textReadingAssets removeObjectForKey:key];
    [self.repository.repoSticker.textReadingRanges removeObjectForKey:key];
    if (toRemove) {
        [[self audioEffectService] hotRemoveAudioAssests:@[toRemove]];
    }
}

- (BOOL)supportTextReading
{
    if ([self isImageAlbumEdit]) {
        return NO;
    }
    let userService = IESAutoInline(self.serviceProvider, ACCUserServiceProtocol);
    return ACCConfigBool(kConfigBool_enable_edit_text_reading) && ![userService isChildMode] && [userService isLogin];
}

- (BOOL)isImageAlbumEdit
{
    return self.repository.repoImageAlbumInfo.isImageAlbumEdit;
}

- (void)clearTextMode
{
    self.repository.repoTextMode.textModel = nil;
}

- (void)showTextReaderSoundEffectsSelectionViewController
{
    @weakify(self);
    ACCStickerContainerView *stickerContainerView =
    [self.stickerService.stickerContainer copyForContext:@""
                                               modConfig:^(NSObject<ACCStickerContainerConfigProtocol> * _Nonnull config) {
        if ([config isKindOfClass:ACCVideoEditStickerContainerConfig.class]) {
            ACCVideoEditStickerContainerConfig *rConfig = (id)config;
            [rConfig reomoveSafeAreaPlugin];
            [rConfig removeAdsorbingPlugin];
            [rConfig removePreviewViewPlugin];
        }
    } modContainer:^(ACCStickerContainerView * _Nonnull stickerContainerView) {
        @strongify(self);
        [stickerContainerView configWithPlayerFrame:self.stickerService.stickerContainer.frame
                                          allowMask:NO];
    } enumerateStickerUsingBlock:^(__kindof ACCBaseStickerView * _Nonnull stickerView,
                                   NSUInteger idx,
                                   ACCStickerGeometryModel * _Nonnull geometryModel,
                                   ACCStickerTimeRangeModel * _Nonnull timeRangeModel) {
        stickerView.config.showSelectedHint = NO;
        stickerView.config.secondTapCallback = NULL;
        geometryModel.preferredRatio = NO;
        stickerView.stickerGeometry.preferredRatio = NO;
    }];
    ACCTextReaderSoundEffectsSelectionViewController *viewController;
    viewController = [[ACCTextReaderSoundEffectsSelectionViewController alloc] initWithEditService:self.editService
                                                                              stickerContainerView:stickerContainerView
                                                                                            player:self.stickerService.compoundHandler.player
                                                                                 transitionService:self.transitionService
                                                                                      dataProvider:self.textStickerHandler];
    [self.transitionService presentViewController:viewController completion:nil];
}



// TODO: @liyingpeng sink select time to sticker SDK
#pragma mark - Select Time

- (void)p_selectTimeWithTextStickerView:(ACCTextStickerView *)stickerView
{
    NSMutableDictionary *params = @{
        @"is_text_reading" : @(stickerView.textModel.readModel.useTextRead)
    }.mutableCopy;
    [params addEntriesFromDictionary:self.repository.repoTrack.referExtra];
    [params setValue:(stickerView.textModel.isAddedInEditView ? @"general_mode" : @"text_mode") forKey:@"text_type"];
    [ACCTracker() trackEvent:@"text_time_set" params:params];
    
    [[self selectTimeManager] modernEditStickerDuration:[self.stickerService.stickerContainer stickerViewWithContentView:stickerView]];
}

#pragma mark - ACCDraftResourceRecoverProtocol

+ (nullable NSArray<NSString *> *)draftResourceIDsToDownloadForPublishViewModel:(nonnull AWEVideoPublishViewModel *)publishModel
{
    NSMutableArray *resourceIDsToDownload = [NSMutableArray array];
    if (publishModel.repoImageAlbumInfo.isImageAlbumEdit) {
        for (ACCImageAlbumItemModel *oneImage in publishModel.repoImageAlbumInfo.imageAlbumData.imageAlbumItems) {
            for (ACCImageAlbumStickerModel *infoSticker in oneImage.stickerInfo.stickers) {
                BOOL isTextSticker = infoSticker.userInfo.acc_stickerType == ACCEditEmbeddedStickerTypeText;
                if (isTextSticker) {
                    NSData *textInfoData = [infoSticker.userInfo objectForKey:kACCTextInfoModelKey] ?: [NSData new];
                    NSError *error = nil;
                    NSDictionary *textInfoDict = [NSJSONSerialization JSONObjectWithData:textInfoData options:0 error:&error] ?: [NSDictionary new];
                    if (error) {
                        AWELogToolError(AWELogToolTagDraft, @"AWEStoryTextImageModel Json From Data Error: %@", error);
                    }
                    error = nil;
                    AWEStoryTextImageModel *textInfo = [MTLJSONAdapter modelOfClass:[AWEStoryTextImageModel class] fromJSONDictionary:textInfoDict error:&error];
                    if (error) {
                        AWELogToolError(AWELogToolTagDraft, @"Story Text Image Model Init From Json Error : %@", error);
                    }
                    NSString *effectID = textInfo.fontModel.effectId;
                    if (!ACC_isEmptyString(effectID) && ![[NSFileManager defaultManager] fileExistsAtPath:textInfo.fontModel.localUrl]) {
                        [resourceIDsToDownload addObject:effectID];
                    }
                }
            }
        }
    } else {
        for (IESInfoSticker *infoSticker in publishModel.repoVideoInfo.video.infoStickers) {
            if (infoSticker.userinfo.acc_stickerType == ACCEditEmbeddedStickerTypeText) {
                NSData *textInfoData = [infoSticker.userinfo objectForKey:kACCTextInfoModelKey] ?: [NSData new];
                NSError *error = nil;
                NSDictionary *textInfoDict = [NSJSONSerialization JSONObjectWithData:textInfoData options:0 error:&error] ?: [NSDictionary new];
                if (error != nil) {
                    AWELogToolError2(@"TextSticker", AWELogToolTagDraft, @"AWEStoryTextImageModel Json From Data Error: %@", error);
                    error = nil;
                }
                AWEStoryTextImageModel *textInfo = [MTLJSONAdapter modelOfClass:[AWEStoryTextImageModel class] fromJSONDictionary:textInfoDict error:&error];
                if (error != nil) {
                    AWELogToolError2(@"TextSticker", AWELogToolTagDraft, @"Story Text Image Model Init From Json Error: %@", error);
                }
                NSString *effectID = textInfo.fontModel.effectId;
                if (!ACC_isEmptyString(effectID)
                    && (ACC_isEmptyString(textInfo.fontModel.localUrl)
                        || ![[NSFileManager defaultManager] fileExistsAtPath:textInfo.fontModel.localUrl])) {
                    [resourceIDsToDownload addObject:effectID];
                }
            }
        }
    }
    
    return resourceIDsToDownload;
}

+ (void)updateWithDownloadedEffects:(NSArray<IESEffectModel *> *)effects
                   publishViewModel:(AWEVideoPublishViewModel *)publishModel
                         completion:(nonnull ACCDraftRecoverCompletion)completion
{
    if (publishModel.repoImageAlbumInfo.isImageAlbumEdit) {
        NSMutableDictionary *stickersKeyDict = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *textInfoKeyDict = [[NSMutableDictionary alloc] init];
        for (ACCImageAlbumItemModel *oneImage in publishModel.repoImageAlbumInfo.imageAlbumData.imageAlbumItems) {
            for (ACCImageAlbumStickerModel *infoSticker in oneImage.stickerInfo.stickers) {
                BOOL isTextSticker = infoSticker.userInfo.acc_stickerType == ACCEditEmbeddedStickerTypeText;
                if (isTextSticker) {
                    NSData *textInfoData = [infoSticker.userInfo objectForKey:kACCTextInfoModelKey] ?: [NSData new];
                    NSError *error = nil;
                    NSDictionary *textInfoDict = [NSJSONSerialization JSONObjectWithData:textInfoData options:0 error:&error] ?: [NSDictionary new];
                    if (error) {
                        AWELogToolError(AWELogToolTagDraft, @"AWEStoryTextImageModel Json From Data Error: %@", error);
                    }
                    error = nil;
                    AWEStoryTextImageModel *textInfo = [MTLJSONAdapter modelOfClass:[AWEStoryTextImageModel class] fromJSONDictionary:textInfoDict error:&error];
                    if (error) {
                        AWELogToolError(AWELogToolTagDraft, @"Story Text Image Model Init From Json Error : %@", error);
                    }
                    
                    NSString *effectID = textInfo.fontModel.effectId;
                    if (effectID) {
                        stickersKeyDict[effectID] = infoSticker;
                        textInfoKeyDict[effectID] = textInfo;
                    }
                }
            }
        }
        
        for (IESEffectModel *effectModel in effects) {
            NSString *effectID = effectModel.effectIdentifier ?: @"";
            NSString *originEffectID = effectModel.effectIdentifier ?: @"";
            if (effectID.length > 0 || originEffectID.length > 0) {
                AWEStoryTextImageModel *textInfo = ACCDynamicCast(textInfoKeyDict[effectID], AWEStoryTextImageModel) ?: ACCDynamicCast(textInfoKeyDict[originEffectID], AWEStoryTextImageModel);
                ACCImageAlbumStickerModel *infoSticker = ACCDynamicCast(stickersKeyDict[effectID], ACCImageAlbumStickerModel) ?: ACCDynamicCast(stickersKeyDict[originEffectID], ACCImageAlbumStickerModel);
                
                if (textInfo && infoSticker) {
                    textInfo.fontModel.localUrl = [ACCCustomFont() fontFilePath:effectModel.filePath];
                    NSError *error = nil;
                    NSDictionary *newTextInfoDict = [MTLJSONAdapter JSONDictionaryFromModel:textInfo error:&error];
                    if (!error && newTextInfoDict) {
                        NSData *newTextInfoData = [NSJSONSerialization dataWithJSONObject:newTextInfoDict
                                                                                  options:0
                                                                                    error:&error];
                        if (newTextInfoData && !error) {
                            NSMutableDictionary *newUserInfo = [[infoSticker userInfo] mutableCopy];
                            newUserInfo[kACCTextInfoModelKey] = newTextInfoData;
                            infoSticker.userInfo = [newUserInfo copy];
                        }
                    } else {
                        AWELogToolError(
                            AWELogToolTagDraft, @"New Text Info Dict From AWEStoryTextImageModel Error : %@", error);
                    }
                }
            }
        }
    } else {
        NSMutableArray<AWEStoryTextImageModel *> *textStickerModels = [NSMutableArray array];
        NSMutableArray<AWEStoryFontModel *> *textStickerFonts = [NSMutableArray array];
        for (IESInfoSticker *infoSticker in publishModel.repoVideoInfo.video.infoStickers) {
            if (infoSticker.userinfo.acc_stickerType == ACCEditEmbeddedStickerTypeText) {
                NSData *textInfoData = [infoSticker.userinfo objectForKey:kACCTextInfoModelKey] ?: [NSData new];
                NSError *error = nil;
                NSDictionary *textInfoDict = [NSJSONSerialization JSONObjectWithData:textInfoData options:0 error:&error] ?: [NSDictionary new];
                if (error != nil) {
                    AWELogToolError2(@"TextSticker", AWELogToolTagDraft, @"AWEStoryTextImageModel Json From Data Error: %@", error);
                    error = nil;
                }
                AWEStoryTextImageModel *textInfo = [MTLJSONAdapter modelOfClass:[AWEStoryTextImageModel class] fromJSONDictionary:textInfoDict error:&error];
                if (error != nil) {
                    AWELogToolError2(@"TextSticker", AWELogToolTagDraft, @"Story Text Image Model Init From Json Error : %@", error);
                }
                
                for (IESEffectModel *effectModel in effects) {
                    NSString *effectID = textInfo.fontModel.effectId;
                    if ([effectID isEqualToString:effectModel.effectIdentifier]) {
                        textInfo.fontModel = [[AWEStoryFontModel alloc] initWithEffectModel:effectModel];
                        textInfo.fontModel.downloadState = AWEStoryTextFontDownloaded;
                        textInfo.fontModel.localUrl = [ACCCustomFont() fontFilePath:effectModel.filePath];
                        error = nil;
                        NSDictionary *newTextInfoDict = [MTLJSONAdapter JSONDictionaryFromModel:textInfo error:&error];
                        if (!error && newTextInfoDict) {
                            NSData *newTextInfoData = [NSJSONSerialization dataWithJSONObject:newTextInfoDict options:0 error:&error];
                            if (newTextInfoData && !error) {
                                NSMutableDictionary *newUserInfo = [[infoSticker userinfo] mutableCopy];
                                newUserInfo[kACCTextInfoModelKey] = newTextInfoData;
                                infoSticker.userinfo = [newUserInfo copy];
                            }
                        } else {
                            AWELogToolError(AWELogToolTagDraft, @"New Text Info Dict From AWEStoryTextImageModel Error : %@", error);
                        }
                        break;
                    }
                }
                
                if (textInfo != nil) {
                    [textStickerModels addObject:textInfo];
                }
                if (textInfo.fontModel != nil) {
                    [textStickerFonts addObject:textInfo.fontModel];
                }
            }
        }
        
        // 草稿迁移后 相关字段恢复
        if (ACC_isEmptyString(publishModel.repoSticker.imageText) && !ACC_isEmptyArray(textStickerModels)) {
            NSError *error = nil;
            NSArray<NSString *> *contents = [textStickerModels acc_mapObjectsUsingBlock:^NSString * _Nonnull(AWEStoryTextImageModel * _Nonnull item, NSUInteger idex) {
                return item.content ?: @"";
            }];
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:contents options:0 error:&error];
            publishModel.repoSticker.imageText = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            publishModel.repoSticker.imageTextFonts = [[textStickerFonts acc_mapObjectsUsingBlock:^NSString * _Nonnull(AWEStoryFontModel *  _Nonnull item, NSUInteger idex) {
                return item.title ?: @"";
            }] componentsJoinedByString:@","];
            publishModel.repoSticker.imageTextFontEffectIds = [[textStickerFonts acc_mapObjectsUsingBlock:^NSString * _Nonnull(AWEStoryFontModel *  _Nonnull item, NSUInteger idex) {
                return item.effectId ?: @"";
            }] componentsJoinedByString:@","];
            
            publishModel.repoSticker.textReadingAssets = [NSMutableDictionary dictionaryWithDictionary:publishModel.repoSticker.textReadingAssets ?: @{}];
            publishModel.repoSticker.textReadingRanges = [NSMutableDictionary dictionaryWithDictionary:publishModel.repoSticker.textReadingRanges ?: @{}];
            [[textStickerModels acc_filter:^BOOL(AWEStoryTextImageModel * _Nonnull item) {
                return !ACC_isEmptyString(item.readModel.stickerKey)
                && item.readModel.useTextRead
                && !ACC_isEmptyString(item.readModel.audioPath)
                && [item.content isEqualToString:item.readModel.text];
            }] enumerateObjectsUsingBlock:^(AWEStoryTextImageModel * _Nonnull textModel, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *audioPath = [[AWEDraftUtils generateDraftFolderFromTaskId:publishModel.repoDraft.taskID] stringByAppendingPathComponent:textModel.readModel.audioPath];
                if ([[NSFileManager defaultManager] fileExistsAtPath:audioPath]) {
                    NSURL *audioURL = [NSURL fileURLWithPath:audioPath];
                    AVAsset *audioAsset = audioURL ? [AVAsset assetWithURL:audioURL] : nil;
                    IESMMVideoDataClipRange *audioRange = [[IESMMVideoDataClipRange alloc] init];
                    if (audioAsset != nil && audioRange != nil) {
                        audioRange.attachSeconds = textModel.realStartTime;
                        audioRange.durationSeconds = CMTimeGetSeconds(audioAsset.duration);
                        audioRange.repeatCount = 1;
                        [publishModel.repoSticker.textReadingAssets setObject:audioAsset forKey:textModel.readModel.stickerKey];
                        [publishModel.repoSticker.textReadingRanges setObject:audioRange forKey:textModel.readModel.stickerKey];
                    }
                }
            }];
        }
    }
   
    ACCBLOCK_INVOKE(completion, nil, NO);
}

- (ACCTextStickerServiceImpl *)serviceImpl
{
    if (!_serviceImpl) {
        _serviceImpl = [[ACCTextStickerServiceImpl alloc] init];
    }
    return _serviceImpl;
}

@end
