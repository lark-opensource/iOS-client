//
//  ACCTextStickerApplyHandler.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/7/27.
//

#import "ACCTextStickerHandler.h"

#import "ACCTextStickerConfig.h"
#import "ACCTextStickerEditView.h"

#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/NSData+ACCAdditions.h>
#import <CreationKitArch/AWEInteractionStickerLocationModel+ACCSticker.h>
#import "AWEEditStickerHintView.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitArch/ACCEditAndPublishConstants.h>
#import "ACCConfigKeyDefines.h"
#import "ACCStickerBizDefines.h"
#import "ACCTextReadingRequestHelper.h"
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <NLEPlatform/NLESegmentInfoSticker+iOS.h>
#import "NLESegmentSticker_OC+ACCAdditions.h"
#import "NLETrackSlot_OC+ACCAdditions.h"
#import "ACCTextStickerViewStorageModel.h"
#import "ACCSerialization.h"
#import <CreationKitRTProtocol/ACCEditStickerProtocol.h>
#import "ACCRepoImageAlbumInfoModel.h"
#import "ACCImageAlbumData.h"
#import "ACCTextStickerHandlerSpeakerModel.h"
#import "ACCTextStickerCacheHelper.h"
#import "AWEInteractionSocialTextStickerModel.h"
#import "ACCCommerceServiceProtocol.h"
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>

#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitInfra/ACCModuleService.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import "ACCStickerHandler+SocialData.h"
#import "AWERepoStickerModel.h"
#import "IESInfoSticker+ACCAdditions.h"
#import <CameraClientModel/ACCCrossPlatformStickerType.h>

NSString *const kAWEEditTextReadingChangeToastCacheKey = @"kAWEEditTextReadingChangeToastCacheKey";
NSString *const kAWEEditTextReadingRequestMonitorKey = @"edit_text_read_request";

@interface ACCTextStickerHandler ()

@property (nonatomic, strong) ACCTextStickerEditView *textStickerEditView;
@property (nonatomic, strong) AWEEditStickerHintView *textHintView;
@property (nonatomic, weak) UIView<ACCTextLoadingViewProtcol> *loadingView;
@property (nonatomic, strong) ACCTextStickerHandlerSpeakerModel *speakerModel;

@end

@implementation ACCTextStickerHandler

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelReadRequest) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

#pragma mark - ACCTextReaderSoundEffectsSelectionViewControllerProviderProtocol Methods

- (void)didSelectTTSAudio:(NSString *)audioFilePath speakerID:(nonnull NSString *)speakerID
{
    if (audioFilePath == nil || [audioFilePath isEqualToString:@""]) {
        [self.logger logToneCancel:self.speakerModel.editingTextStickerView.textModel.isAddedInEditView];
    } else {
        [self.logger logToneClick:self.speakerModel.editingTextStickerView.textModel.isAddedInEditView
                        speakerID:speakerID
                      speakerName:speakerID
                isDefaultSelected:[self.speakerModel.modelBeforeEditing.soundEffect isEqualToString:self.speakerModel.modelWhileEditing.soundEffect]];
    }
    [self p_applyTTSAudio:audioFilePath speakerID:speakerID];
}

- (void)didTapFinishDelegate:(NSString *)audioFilePath
                   speakerID:(NSString *)speakerID
                 speakerName:(NSString *)speakerName
{
    
}

- (void)didTapCancelDelegate
{
    AWETextStickerReadModel *originalModel = self.speakerModel.modelBeforeEditing;
    [self p_applyTTSAudio:originalModel.audioPath
                speakerID:originalModel.soundEffect];
}

- (AWETextStickerReadModel *)getTextReaderModel
{
    return self.speakerModel.modelBeforeEditing;
}

#pragma mark - Private Methods

- (void)p_applyAudioToVE:(AWETextStickerReadModel *)model
             stickerView:(ACCTextStickerView *)stickerView
         stickerTimeView:(UIView<ACCStickerProtocol> *)stickerTimeView
{
    CGFloat seekTime = 0.f;
    if (model.stickerKey && model.audioPath && !model.useTextRead) {
        NSString *audioPath = [[self.dataProvider textStickerFolderForDraft] stringByAppendingPathComponent:model.audioPath];
        NSURL *audioURL = [NSURL fileURLWithPath:audioPath];
        AVAsset *audioAsset = audioURL ? [AVAsset assetWithURL:audioURL] : nil;
        IESMMVideoDataClipRange *audioRange = [[IESMMVideoDataClipRange alloc] init];
        if (audioAsset && audioRange) {
            model.useTextRead = YES;
            seekTime = stickerTimeView.realStartTime;
            audioRange.attachSeconds = stickerTimeView.realStartTime;
            audioRange.durationSeconds = CMTimeGetSeconds(audioAsset.duration);
            audioRange.repeatCount = 1;
            if (ACCConfigEnum(kConfigInt_text_reader_multiple_sound_effects, ACCTextReaderPhase2Type) == ACCTextReaderPhase2TypeDisable || ACCConfigEnum(kConfigInt_text_reader_multiple_sound_effects, ACCTextReaderPhase2Type) == ACCTextReaderPhase2TypeSameDuration) {
                stickerTimeView.realDuration = MAX(audioRange.durationSeconds, 1.f);
            }
            if (audioRange.attachSeconds + audioRange.durationSeconds > self.player.videoData.totalVideoDuration) {
                if (ACCConfigEnum(kConfigInt_text_reader_multiple_sound_effects, ACCTextReaderPhase2Type) == ACCTextReaderPhase2TypeDisable || ACCConfigEnum(kConfigInt_text_reader_multiple_sound_effects, ACCTextReaderPhase2Type) == ACCTextReaderPhase2TypeSameDuration) {
                    stickerTimeView.realDuration = self.player.videoData.totalVideoDuration - audioRange.attachSeconds;
                }
            }
            // 裁剪音频长度
            CGFloat maxDuration = self.player.videoData.totalVideoDuration - audioRange.attachSeconds;
            audioRange.durationSeconds = MIN(maxDuration, audioRange.durationSeconds);
            [self.dataProvider addTextReadForKey:model.stickerKey asset:audioAsset range:audioRange];
            [stickerView updateBubbleStatusAfterEdit];
        }
    }
    @weakify(self);
    [self.player seekToTimeAndRender:CMTimeMake(seekTime * 1000.f, 1000.f) completionHandler:^(BOOL finished) {
        @strongify(self);
        [self.player play];
    }];
}

- (void)p_applyTTSAudio:(NSString *)audioFilePath speakerID:(nonnull NSString *)speakerID
{
    [self.speakerModel updateModelWhileEditing:audioFilePath speakerID:speakerID];
    ACCTextStickerView *stickerView = self.speakerModel.editingTextStickerView;
    UIView<ACCStickerProtocol> *stickerTimeView = [stickerView.stickerContainer stickerViewWithContentView:stickerView];
    if (stickerTimeView == nil) {
        stickerTimeView = self.speakerModel.editingTextStickerTimeView;
    }
    @weakify(self);
    if (audioFilePath == nil) {
        [self removeTextReadingForStickerView:stickerView];
        stickerView.textModel.readModel = nil;
        [self.player seekToTimeAndRender:CMTimeMake(stickerTimeView.realStartTime * 1000.f, 1000.f) completionHandler:^(BOOL finished) {
            @strongify(self);
            [self.player play];
        }];
    } else {
        [self removeTextReadingForStickerView:stickerView];
        NSString *filePath = [[self.dataProvider textStickerFolderForDraft] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.mp3",[NSUUID UUID].UUIDString,@"readtext"]];
        NSString *fullAudioFilePath = audioFilePath;
        if ([fullAudioFilePath isEqualToString:self.speakerModel.modelBeforeEditing.audioPath]) {
            fullAudioFilePath = [[self.dataProvider textStickerFolderForDraft] stringByAppendingPathComponent: fullAudioFilePath];
        }
        NSError *error = nil;
        [[NSFileManager defaultManager] copyItemAtPath:fullAudioFilePath
                                                        toPath:filePath
                                                         error:&error];
        if (error) {
            AWELogToolError2(@"copy_item", AWELogToolTagEdit, @"copyItemAtPath failed, from [%@] to [%@] :%@", fullAudioFilePath, filePath, error);
        }
        [self.player pause];
        AWETextStickerReadModel *readModel = [[AWETextStickerReadModel alloc] init];
        readModel.stickerKey = self.speakerModel.modelWhileEditing.stickerKey;
        readModel.text = self.speakerModel.modelWhileEditing.text;
        readModel.audioPath = filePath.lastPathComponent;
        readModel.soundEffect = self.speakerModel.modelWhileEditing.soundEffect;
        stickerView.textModel.readModel = readModel;
        [self p_applyAudioToVE:readModel
                   stickerView:stickerView
               stickerTimeView:stickerTimeView];
    }
    if (speakerID != nil) {
        [ACCTextStickerCacheHelper updateLastSelectedSpeaker:speakerID];
    }
}

- (ACCTextStickerEditView *)textStickerEditView {
    if (!_textStickerEditView) {
        ACCTextStickerEditAbilityOptions options = ACCTextStickerEditAbilityOptionsNone;
        if ([self.dataProvider supportTextReading]) {
            options |= ACCTextStickerEditAbilityOptionsSupportTextReader;
        }
        
        // 图文支持@和#
        BOOL isNormalImageAlbum = ([self isImageAlbumEdit] && !ACCConfigBool(kConfigBool_enable_image_album_story));
        
        if (!isNormalImageAlbum) {
            options |= ACCTextStickerEditAbilityOptionsSupportSocial;
        }
        
        if ([IESAutoInline(ACCBaseServiceProvider(), ACCCommerceServiceProtocol) isEnterFromECommerceComment:self.publishViewModel]) {
            options |= ACCTextStickerEditAbilityOptionsNotSupportMention;
        }
        _textStickerEditView = [[ACCTextStickerEditView alloc] initWithOptions:options];
        _textStickerEditView.publishViewModel = self.publishViewModel;
        _textStickerEditView.stylePreferenceModel = self.stylePreferenceModel;
        
        @weakify(self);
        _textStickerEditView.onEditFinishedBlock = ^(ACCTextStickerView * _Nonnull textStickerView, BOOL fromSaveButton) {
            @strongify(self);
            if ([textStickerView.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
                [self.stickerContainerView removeStickerView:textStickerView];
            } else {
                [self showTextHintOnStickerView:[self.stickerContainerView stickerViewWithContentView:textStickerView]
                                      textModel:textStickerView.textModel];
            }
            [self.textStickerEditView removeFromSuperview];
            [self.speakerModel reset];
            [self.logger logTextStickerEditFinished:textStickerView.textView.hasVisibleTexts anchor:NO];
            [self.logger logTextStickerSocialInfoWhenAddFinishedWithTrackInfo:textStickerView.textModel.trackInfo];
            
            ACCBLOCK_INVOKE(self.onFinishedEditAnimationCompletedBlock);
        };
        _textStickerEditView.finishEditAnimationBlock = ^(ACCTextStickerView * _Nonnull textStickerView) {
            @strongify(self);
            !self.editViewOnFinishEdit ?: self.editViewOnFinishEdit(textStickerView);
            [self textEditFinishedForStickerView:textStickerView];
        };
        _textStickerEditView.startEditBlock = ^(ACCTextStickerView * _Nonnull textStickerView) {
            @strongify(self);
            !self.editViewOnStartEdit ?: self.editViewOnStartEdit(textStickerView);
        };
        _textStickerEditView.didSelectedColorBlock = ^(AWEStoryColor *selectColor, NSIndexPath *indexPath) {
            @strongify(self);
            [self.logger logTextStickerDidSelectColor:selectColor.colorString];
            if (self.stylePreferenceModel.enableUsingUserPreference) {
                self.stylePreferenceModel.preferenceTextColor = selectColor;
            }
        };
        _textStickerEditView.didChangeStyleBlock = ^(AWEStoryTextStyle style) {
            @strongify(self);
            [self.logger logTextStickerDidChangeTextStyle:style];
        };
        _textStickerEditView.didSelectedFontBlock = ^(AWEStoryFontModel *model, NSIndexPath *indexPath) {
            @strongify(self);
            [self.logger logTextStickerDidSelectFont:model.title];
            if (self.stylePreferenceModel.enableUsingUserPreference) {
                self.stylePreferenceModel.preferenceTextFont = model;
            }
        };
        _textStickerEditView.didChangeAlignmentBlock = ^(AWEStoryTextAlignmentStyle style) {
            @strongify(self);
            [self.logger logTextStickerDidChangeAlignment:style];
        };
        _textStickerEditView.getTextReaderModelBlock = ^AWETextStickerReadModel * _Nonnull {
            @strongify(self);
            return self.speakerModel.modelWhileEditing;
        };
        _textStickerEditView.startSelectingTTSAudioBlock = ^{
            @strongify(self);
            [self.logger logClickTextReading:self.speakerModel.editingTextStickerView.textModel.isAddedInEditView
                                        type:ACCTextStickerLoggerClickTextReaderTypeEditIcon];
            [self.player pause];
        };
        _textStickerEditView.didSelectTTSAudio = ^(NSString * _Nonnull audioFilePath, NSString * _Nonnull audioSpeakerID) {
            @strongify(self);
            if (audioFilePath == nil || [audioFilePath isEqualToString:@""]) {
                [self.logger logToneCancel:self.speakerModel.editingTextStickerView.textModel.isAddedInEditView];
            } else {
                [self.logger logToneClick:self.speakerModel.editingTextStickerView.textModel.isAddedInEditView
                                speakerID:audioSpeakerID
                              speakerName:audioSpeakerID
                        isDefaultSelected:[self.speakerModel.modelBeforeEditing.soundEffect isEqualToString:self.speakerModel.modelWhileEditing.soundEffect]];
            }
        };
        _textStickerEditView.didTapFinishCallback = ^(NSString * _Nonnull audioFilePath,
                                                      NSString * _Nonnull audioSpeakerID,
                                                      NSString * _Nonnull audioSpeakerName) {
            @strongify(self);
            [self.logger logTextReadingComplete:self.speakerModel.editingTextStickerView.textModel.isAddedInEditView
                                      speakerID:audioSpeakerID
                                    speakerName:audioSpeakerName];
            [self p_applyTTSAudio:audioFilePath speakerID:self.speakerModel.modelWhileEditing.soundEffect];
        };
        _textStickerEditView.didTapCancelCallback = ^{
            
        };
        
        _textStickerEditView.stickerTotalMentionBindCountProvider = ^NSInteger {
            @strongify(self);
            return [self allMentionCountInSticker];
        };
        
        _textStickerEditView.stickerTotalHashtagBindCountProvider = ^NSInteger {
            @strongify(self);
            return [self allHashtahCountInSticker];
        };
        
        _textStickerEditView.triggeredSocialEntraceBlock = ^(BOOL isFromToolbar, BOOL isMention) {
            @strongify(self);
            [self.logger logTextStickerViewDidTriggeredSocialEntraceWithEntraceName:isFromToolbar?@"button":@"input" isMention:isMention];
        };
        
        _textStickerEditView.didSelectedToolbarColorItemBlock = ^(BOOL willShowColorPannel) {
            @strongify(self);
            [self.logger logTextStickerDidSelectedToolbarColorItem:@{@"to_status": willShowColorPannel?@"color":@"font"}];
        };
    }
    return _textStickerEditView;
}

- (void)apply:(UIView<ACCStickerProtocol> *)sticker index:(NSUInteger)idx {
    ACCTextStickerView *textStickerView = (ACCTextStickerView *)sticker.contentView;
    // get text image
    CGFloat imageScale = ACC_SCREEN_SCALE;
    CGFloat scale = [sticker.stickerGeometry.scale floatValue] * [UIScreen mainScreen].scale;
    if (scale > imageScale) {
        imageScale = scale < 10 ? scale : 10;
    }
    
    UIImage *image = nil;
    NSString *textInfoString = [NSString stringWithFormat:@"%@ - %@ - %@", textStickerView.textModel.fontIndex ? : @"", @(textStickerView.textModel.fontSize) ? : @"", @(textStickerView.textModel.alignmentType)];
    if (sticker.hidden) {
        UIView<ACCStickerProtocol> *stickerCopy = [sticker copy];
        stickerCopy.hidden = NO;
        image = [stickerCopy acc_imageWithViewOnScale:imageScale];
        AWELogToolInfo2(@"TextSticker",AWELogToolTagEdit, @"Add Text sticker into player: text = %@, bounds = %@, frame = %@, scale = %@, textInfo = %@, hidden = YES", textStickerView.textView.text ? : @"", NSStringFromCGRect(stickerCopy.bounds), NSStringFromCGRect(stickerCopy.frame), @(imageScale), textInfoString ? : @"");
    } else {
        image = [sticker acc_imageWithViewOnScale:imageScale];
        AWELogToolInfo2(@"TextSticker",AWELogToolTagEdit, @"Add Text sticker into player: text = %@, bounds = %@, frame = %@, scale = %@, textInfo = %@, hidden = NO", textStickerView.textView.text ? : @"", NSStringFromCGRect(sticker.bounds), NSStringFromCGRect(sticker.frame), @(imageScale), textInfoString ? : @"");
    }

    NSData *imageData = UIImagePNGRepresentation(image);
    NSString *imagePath = [self.dataProvider textStickerImagePathForDraftWithIndex:idx];
    [imageData acc_writeToFile:imagePath atomically:YES];
    
    // add text sticker
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo.acc_stickerType = ACCEditEmbeddedStickerTypeText;
    [userInfo setObject:(textStickerView.textStickerId ? : @"") forKey:kACCTextInfoTextStickerIdKey];
    
    NSError *error = nil;
    NSDictionary *textInfo = [MTLJSONAdapter JSONDictionaryFromModel:textStickerView.textModel error:&error] ?: [NSDictionary new];
    if (error) {
        AWELogToolError2(@"textStickerHandler", AWELogToolTagEdit, @"apply modeled textInfo failed: %@", error);
    }
    
    NSError *error1 = nil;
    NSData *textInfoData = [NSJSONSerialization dataWithJSONObject:textInfo options:0 error:&error1];
    if (error1) {
        AWELogToolError2(@"textStickerHandler", AWELogToolTagEdit, @"apply jsonlize textInfo failed: %@", error1);
    }
    
    if (textInfoData) {
        [userInfo setObject:textInfoData forKey:kACCTextInfoModelKey];
    }
    
    AWEInteractionStickerLocationModel *stickerLocation = [[AWEInteractionStickerLocationModel alloc] initWithGeometryModel:({
        ACCStickerGeometryModel *model = [sticker.stickerGeometry copy];
        model.preferredRatio = NO;
        model;
    }) andTimeRangeModel:sticker.stickerTimeRange];
    
    NSError *error2 = nil;
    NSDictionary *textLocation = [MTLJSONAdapter JSONDictionaryFromModel:stickerLocation error:&error2];
    if (error2) {
        AWELogToolError2(@"textStickerHandler", AWELogToolTagEdit, @"apply modeled textLocation failed: %@", error2);
    }
    
    NSError *error3 = nil;
    NSData *textLocationData = [NSJSONSerialization dataWithJSONObject:textLocation options:0 error:&error3];
    if (error3) {
        AWELogToolError2(@"textStickerHandler", AWELogToolTagEdit, @"apply jsonlize textLocation failed: %@", error3);
    }
    
    if (textLocationData) {
        [userInfo setObject:textLocationData forKey:kACCTextLocationModelKey];
    }
    
    if ([sticker.config isKindOfClass:[ACCCommonStickerConfig class]]) {
        ACCCommonStickerConfig *config = (ACCCommonStickerConfig *)sticker.config;
        userInfo[ACCStickerEditableKey] = config.editable;
        userInfo[ACCStickerDeleteableKey] = config.deleteable;
        userInfo[kACCStickerGroupIDKey] = config.groupId;
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
        NSInteger stickerEditId = [self.player addInfoSticker:imagePath withEffectInfo:nil userInfo:userInfo];
        textStickerView.stickerID = stickerEditId;
        CGSize stickerSize = [self.player getInfoStickerSize:stickerEditId];
        CGFloat realScale = stickerSize.width > 0 ? image.size.width / stickerSize.width : 1;
        
        [self.player setStickerAbove:stickerEditId];
        [self.player setSticker:stickerEditId startTime:sticker.realStartTime duration:sticker.realDuration];
        
        // update text sticker position
        CGFloat offsetX = [stickerLocation.x floatValue];
        CGFloat offsetY = -[stickerLocation.y floatValue];
        CGFloat stickerAngle = [stickerLocation.rotation floatValue];
        CGFloat scale = [stickerLocation.scale floatValue];
        scale = scale * realScale;
        
        [self.player setSticker:stickerEditId offsetX:offsetX offsetY:offsetY angle:stickerAngle scale:scale];
    }
    sticker.hidden = YES;

    if (textStickerView.textView.hasVisibleTexts) {
        !self.onStickerApplySuccess ?: self.onStickerApplySuccess();
    }
}

#pragma mark - Sticker Expess

- (BOOL)canExpressSticker:(ACCEditorStickerConfig *)stickerConfig
{
    return [stickerConfig isKindOfClass:[ACCEditorTextStickerConfig class]];
}

- (void)expressSticker:(ACCEditorStickerConfig *)stickerConfig
{
    [self expressSticker:stickerConfig withCompletion:^{
        
    }];
}

- (void)expressSticker:(ACCEditorStickerConfig *)stickerConfig withCompletion:(void (^)(void))completionHandler
{
    if ([self canExpressSticker:stickerConfig]) {
        ACCEditorTextStickerConfig *textStickerConfig = (ACCEditorTextStickerConfig *)stickerConfig;
        AWEInteractionStickerLocationModel *locationModel = [textStickerConfig locationModel];
        locationModel.startTime = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", 0.f]];
        locationModel.endTime = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", self.player.stickerInitialEndTime]];

        __kindof ACCTextStickerView *stickerView = [self addTextWithTextInfo:[textStickerConfig textModel] locationModel:locationModel preferredRatio:YES constructorBlock:^(ACCTextStickerConfig * _Nonnull config) {
            config.deleteable = @(stickerConfig.deleteable);
            config.editable = @(stickerConfig.editable);
            config.groupId = stickerConfig.groupId;
            if ([config.editable isEqual:@NO]) {
                config.secondTapCallback = nil;
            }
            config.alignPoint = textStickerConfig.location.alignPoint;
            config.alignPosition = textStickerConfig.location.alignPosition;
        }];
        if (!stickerConfig.location.persistentAlign) {
            [self.stickerContainerView stickerViewWithContentView:stickerView].config.alignPosition = nil;
        }
    }
}

#pragma mark -

- (BOOL)canHandleSticker:(UIView<ACCStickerProtocol> *)sticker {
    return [sticker.contentView isKindOfClass:[ACCTextStickerView class]];
}

- (BOOL)canRecoverSticker:(ACCRecoverStickerModel *)sticker {
    return sticker.infoSticker.acc_stickerType == ACCEditEmbeddedStickerTypeText;
}

- (void)applyStickerStorageModel:(NSObject<ACCSerializationProtocol> *)stickerStorageModel
                    forContainer:(ACCStickerContainerView *)simContainerView
                    stickerIndex:(NSUInteger)stickerIndex
                 imageAlbumIndex:(NSUInteger)imageAlbumIndex
{
    ACCTextStickerViewStorageModel *textStorageModel = (id)stickerStorageModel;
    if (![textStorageModel isKindOfClass:ACCTextStickerViewStorageModel.class]) {
        return ;
    }
    
    UIView<ACCStickerProtocol> *sticker = [self p_recoverStickerForContainer:simContainerView storageModel:textStorageModel];
    sticker.hidden = NO;
    ACCTextStickerView *textStickerView = (ACCTextStickerView *)sticker.contentView;
    // get text image
    CGFloat imageScale = ACC_SCREEN_SCALE;
    CGFloat scale = [textStorageModel.config.geometryModel.scale floatValue] * [UIScreen mainScreen].scale;
    if (scale > imageScale) {
        imageScale = scale < 10 ? scale : 10;
    }

    UIImage *image = nil;
    NSString *textInfoString = [NSString stringWithFormat:@"%@ - %@ - %@", textStickerView.textModel.fontIndex ? : @"", @(textStickerView.textModel.fontSize) ? : @"", @(textStickerView.textModel.alignmentType)];
    image = [sticker acc_imageWithViewOnScale:imageScale];
    AWELogToolInfo2(@"TextSticker",AWELogToolTagEdit, @"Add Text sticker into player: text = %@, bounds = %@, frame = %@, scale = %@, textInfo = %@, hidden = NO", textStickerView.textView.text ? : @"", NSStringFromCGRect(sticker.bounds), NSStringFromCGRect(sticker.frame), @(imageScale), textInfoString ? : @"");

    NSData *imageData = UIImagePNGRepresentation(image);
    NSString *imagePath = [self.dataProvider textStickerImagePathForDraftWithIndex:stickerIndex];
    [imageData acc_writeToFile:imagePath atomically:YES];

    // add text sticker
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo.acc_stickerType = ACCEditEmbeddedStickerTypeText;
    [userInfo setObject:(textStickerView.textStickerId ? : @"") forKey:kACCTextInfoTextStickerIdKey];

    NSDictionary *textInfo = [MTLJSONAdapter JSONDictionaryFromModel:textStickerView.textModel error:nil] ?: [NSDictionary new];
    NSData *textInfoData = [NSJSONSerialization dataWithJSONObject:textInfo options:0 error:nil];
    if (textInfoData) {
        [userInfo setObject:textInfoData forKey:kACCTextInfoModelKey];
    }

    AWEInteractionStickerLocationModel *stickerLocation = [[AWEInteractionStickerLocationModel alloc] initWithGeometryModel:sticker.stickerGeometry andTimeRangeModel:sticker.stickerTimeRange];
    NSDictionary *textLocation = [MTLJSONAdapter JSONDictionaryFromModel:stickerLocation error:nil];
    NSData *textLocationData = [NSJSONSerialization dataWithJSONObject:textLocation options:0 error:nil];
    if (textLocationData) {
        [userInfo setObject:textLocationData forKey:kACCTextLocationModelKey];
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
        NSInteger stickerEditId = [self.editSticker addInfoSticker:imagePath withEffectInfo:nil userInfo:userInfo imageEditorIndex:imageAlbumIndex];
        textStickerView.stickerID = stickerEditId;
        CGSize stickerSize = [self.editSticker getInfoStickerSize:stickerEditId];
        
        CGFloat realScale = stickerSize.width > 0 ? image.size.width / stickerSize.width : 1;
        BOOL isMagnifyFixed = NO; // 放大的情况下修正完的scale可以直接用
        if (CGSizeEqualToSize(stickerSize, CGSizeZero)) {
            CGFloat layerScale = [self.editSticker getImageEditorTextStickerVEScaleWithImage:image imagePath:imagePath userInfo:userInfo];
            if (layerScale > 0.0) {
                realScale = layerScale;
            }
            isMagnifyFixed = image.scale > ACC_SCREEN_SCALE;
        }

        [self.editSticker setStickerAbove:stickerEditId];
        [self.editSticker setSticker:stickerEditId startTime:sticker.realStartTime duration:sticker.realDuration];

        // update text sticker position
        CGFloat offsetX = [stickerLocation.x floatValue];
        CGFloat offsetY = -[stickerLocation.y floatValue];
        CGFloat stickerAngle = [stickerLocation.rotation floatValue];
        CGFloat scale = [stickerLocation.scale floatValue];
        if (isMagnifyFixed) {
            scale = realScale;
        } else {
            scale = scale * realScale;
        }

        [self.editSticker setSticker:stickerEditId offsetX:offsetX offsetY:offsetY angle:stickerAngle scale:scale];
    }

    if (textStickerView.textView.hasVisibleTexts) {
        !self.onStickerApplySuccess ?: self.onStickerApplySuccess();
    }
    
    [simContainerView removeStickerView:sticker];
}

- (void)finish {
    // 添加文字信息，供审核
    [self.dataProvider storeTextInfoForAuditWith:[self textsArrayInString] imageTextFonts:[self textFontsArrayInString] imageTextFontEffectIds:[self textFontEffectIdsArrayInString]];
    [self.dataProvider clearTextMode];
}

- (void)reset
{
    if (self.isImageAlbumEdit) {
        [self.repoImageAlbumInfo.imageAlbumData.imageAlbumItems enumerateObjectsUsingBlock:^(ACCImageAlbumItemModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj.stickerInfo.stickers enumerateObjectsUsingBlock:^(ACCImageAlbumStickerModel * _Nonnull oneSticker, NSUInteger idx, BOOL * _Nonnull stop) {
                BOOL isTextSticker = oneSticker.userInfo.acc_stickerType == ACCEditEmbeddedStickerTypeText;
                if (isTextSticker) {
                    [self.editSticker removeInfoSticker:oneSticker.uniqueId];
                }
            }];
        }];
    } else {
        [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdText] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([[obj contentView] isKindOfClass:[ACCTextStickerView class]]) {
                if (ACC_FLOAT_GREATER_THAN(0.1, obj.realStartTime)) {
                    obj.hidden = NO;
                } else {
                    obj.hidden = YES;
                }
            }
        }];
        
        [self.player removeStickerWithType:ACCEditEmbeddedStickerTypeText];
    }
}

- (void)addInteractionStickerInfoToArray:(NSMutableArray *)interactionStickers idx:(NSInteger)stickerIndex {
    // Pay attention to the order, lower goes fisrt
    for (UIView<ACCStickerProtocol> *sticker in [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdText] acc_filter:^BOOL(ACCStickerViewType  _Nonnull item) {
        return [item.contentView isKindOfClass:[ACCTextStickerView class]];
    }]) {
        [self addTextInteractionStickerInfo:sticker toArray:interactionStickers idx:stickerIndex];
    }
}

- (void)addTextInteractionStickerInfo:(UIView<ACCStickerProtocol> *)sticker toArray:(NSMutableArray *)interactionStickers idx:(NSInteger)stickerIndex
{
    ACCTextStickerView *textStickerView = (ACCTextStickerView *)sticker.contentView;
    [self p_addTextSocialInfoToInteractionStickers:interactionStickers
                                       stickerView:sticker
                                         textModel:textStickerView.textModel
                                               idx:stickerIndex];
}

- (void)p_addTextSocialInfoToInteractionStickers:(NSMutableArray *)interactionStickers
                                     stickerView:(UIView<ACCStickerProtocol> *)stickerView
                                       textModel:(AWEStoryTextImageModel *)textModel
                                             idx:(NSInteger)stickerIndex
{
    if (ACC_isEmptyArray(textModel.extraInfos)) {
        return;
    }
    
    // 按照从前往后的顺序 而不是添加的顺序
    NSArray<ACCTextStickerExtraModel *> *sortedTextExtras = [ACCTextStickerExtraModel sortedByLocationAscendingWithExtras:textModel.extraInfos];
    
    NSMutableArray <AWEInteractionStickerAssociatedSocialModel *> *bindSocials = [NSMutableArray array];
    
    [sortedTextExtras enumerateObjectsUsingBlock:^(ACCTextStickerExtraModel * _Nonnull extra, NSUInteger idx, BOOL * _Nonnull stop) {
            
        if (!extra.isValid) {
            return;
        }
        
        if (extra.type == ACCTextStickerExtraTypeMention) {
            
            AWEInteractionStickerAssociatedSocialModel *socalModel = [[AWEInteractionStickerAssociatedSocialModel alloc] init];
            
            socalModel.type = AWEInteractionStickerAssociatedSociaTypeMention;
            AWEInteractionStickerSocialMentionModel *mentionModel = [[AWEInteractionStickerSocialMentionModel alloc] init];
            mentionModel.userName = extra.nickname; // userName服务端会实时透传最新的 所以不用校验
            mentionModel.userID = extra.userId;
            mentionModel.secUserID = extra.secUserID;
            mentionModel.followStatus = extra.followStatus;
            socalModel.mentionModel = mentionModel;
            
            [bindSocials addObject:socalModel];
            
        } else if (extra.type == ACCTextStickerExtraTypeHashtag) {
            
            AWEInteractionStickerAssociatedSocialModel *socalModel = [[AWEInteractionStickerAssociatedSocialModel alloc] init];
            
            socalModel.type = AWEInteractionStickerAssociatedSociaTypeHashtag;
            AWEInteractionStickerSocialHashtagModel *hashtagModel = [[AWEInteractionStickerSocialHashtagModel alloc] init];
            hashtagModel.hashtagName = extra.hashtagName;
            // 不用赋值hashtagid 这个是服务端透传的
            socalModel.hashtagModel = hashtagModel;
            
            [bindSocials addObject:socalModel];
        }
    }];
    
    if (ACC_isEmptyArray(bindSocials)) {
        return;
    }
    
    AWEInteractionSocialTextStickerModel *interactionStickerInfo = ({

        AWEInteractionSocialTextStickerModel *interactionModel = [AWEInteractionSocialTextStickerModel new];
        interactionModel.type = AWEInteractionStickerTypeSocialText;
        interactionModel.index = [interactionStickers count] + stickerIndex;
        interactionModel.adaptorPlayer = [self.player needAdaptPlayer];
        interactionModel.isAutoAdded = textModel.isAutoAdded;
        interactionModel;
    });
    
    interactionStickerInfo.textSocialInfos = [bindSocials copy];
    
    UIView *stickerContentView = stickerView.contentView;
    UIView *stickerContainerView = [stickerView.stickerContainer containerView];
    
    if (!stickerContentView || !stickerContainerView) {
        NSAssert(NO, @"check");
        return;
    }
    
    CGPoint point = [stickerView convertPoint:stickerContentView.center toView:stickerContainerView];
    
    AWEInteractionStickerLocationModel *locationInfoModel = [[AWEInteractionStickerLocationModel alloc] initWithGeometryModel:[stickerView interactiveStickerGeometryWithCenterInPlayer:point interactiveBoundsSize:stickerContentView.bounds.size] andTimeRangeModel:stickerView.stickerTimeRange];

    if (locationInfoModel.width && locationInfoModel.height) {
        AWEInteractionStickerLocationModel *finalLocation = [self.player resetStickerLocation:locationInfoModel isRecover:NO];
        if (!finalLocation) {
            return;
        }
        [interactionStickerInfo storeLocationModelToTrackInfo:finalLocation];
    }
    
    [interactionStickers addObject:interactionStickerInfo];
}

- (void)recoverSticker:(ACCRecoverStickerModel *)sticker
{
    if ([self canRecoverSticker:sticker]) {
        IESInfoStickerProps *props = [IESInfoStickerProps new];
        [self.player getStickerId:sticker.infoSticker.stickerId props:props];
        
        CGFloat videoDuration = self.player.videoData.totalVideoDuration;
        if (props.duration < 0 || props.duration > videoDuration) {
            props.duration = videoDuration;
        }

        NSData *textInfoData = [sticker.infoSticker.userinfo objectForKey:kACCTextInfoModelKey] ?: [NSData new];
        
        NSError *error = nil;
        NSDictionary *textInfoDict = [NSJSONSerialization JSONObjectWithData:textInfoData options:0 error:&error] ?: [NSDictionary new];
        if (error) {
            AWELogToolError2(@"recoverSticker", AWELogToolTagEdit, @"recover desjosnlize textInfo failed: %@", error);
        }
        
        NSError *error1 = nil;
        AWEStoryTextImageModel *textInfo = [MTLJSONAdapter modelOfClass:[AWEStoryTextImageModel class] fromJSONDictionary:textInfoDict error:&error1];
        if (error1) {
            AWELogToolError2(@"recoverSticker", AWELogToolTagEdit, @"recover modeled textInfo failed: %@", error1);
        }
        
        id textLocation = [sticker.infoSticker.userinfo objectForKey:kACCTextLocationModelKey];
        NSData *textLocationData = (NSData *)([textLocation isKindOfClass:[NSData class]] ? textLocation : nil);
        
        NSError *error2 = nil;
        NSDictionary *textLocationDict = [NSJSONSerialization JSONObjectWithData:textLocationData options:0 error:&error2];
        if (error2) {
            AWELogToolError2(@"recoverSticker", AWELogToolTagEdit, @"recover desjosnlize textLocation failed: %@", error2);
        }
        
        NSError *error3 = nil;
        AWEInteractionStickerLocationModel *stickerLocation = [MTLJSONAdapter modelOfClass:[AWEInteractionStickerLocationModel class] fromJSONDictionary:textLocationDict error:&error3];
        if (error3) {
            AWELogToolError2(@"recoverSticker", AWELogToolTagEdit, @"recover modeled textLocation failed: %@", error3);
        }
        NSNumber *deleteable = [sticker.infoSticker.userinfo acc_objectForKey:ACCStickerDeleteableKey];
        NSNumber *editable = [sticker.infoSticker.userinfo acc_objectForKey:ACCStickerEditableKey];
        NSNumber *groupID = [sticker.infoSticker.userinfo acc_objectForKey:kACCStickerGroupIDKey];

        /// find anchor models to recover text sticker view
        NSString *textStickerId = ACCDynamicCast([props.userInfo objectForKey:kACCTextInfoTextStickerIdKey],
                                                 NSString);
        ACCTextStickerView *textStickerView = [self addTextWithTextInfo:textInfo locationModel:stickerLocation constructorBlock:^(ACCTextStickerConfig * _Nonnull config) {
            config.deleteable = deleteable;
            config.editable = editable;
            config.groupId = groupID;
        }];
        textStickerView.textStickerId = textStickerId;
    }
}

- (__kindof ACCTextStickerView *)addTextWithTextInfo:(AWEStoryTextImageModel *)textModel locationModel:(AWEInteractionStickerLocationModel *)locationModel constructorBlock:(void (^)(ACCTextStickerConfig *config))constructorBlock
{
    return [self addTextWithTextInfo:textModel locationModel:locationModel preferredRatio:NO constructorBlock:constructorBlock];
}

- (__kindof ACCTextStickerView *)addTextWithTextInfo:(AWEStoryTextImageModel *)textModel locationModel:(AWEInteractionStickerLocationModel *)locationModel preferredRatio:(BOOL)preferredRatio constructorBlock:(void (^)(ACCTextStickerConfig *config))constructorBlock
{
    if (!textModel) {
        return nil;
    }

    ACCTextStickerViewAbilityOptions viewOptions = ACCTextStickerViewAbilityOptionsNone;
    // 图文支持@和#
    BOOL isNormalImageAlbum = ([self isImageAlbumEdit] && !ACCConfigBool(kConfigBool_enable_image_album_story));
    
    if (!isNormalImageAlbum) {
        viewOptions |= ACCTextStickerViewAbilityOptionsSupportSocial;
    }
    ACCTextStickerView *textStickerView = [[ACCTextStickerView alloc] initWithTextInfo:textModel options:viewOptions];
    @weakify(self);
    textStickerView.triggerDragDeleteCallback = ^{
        @strongify(self);
        [self.logger logTextStickerViewWillDeleteWithEnterMethod:@"drag"];
    };
    ACCTextStickerConfig *config = [self textStickerConfig:textModel locationModel:locationModel textStickerView:textStickerView preferredRatio:preferredRatio];
    if (constructorBlock) {
        constructorBlock(config);
    }
    [self.stickerContainerView addStickerView:textStickerView config:config];
    return textStickerView;
}

- (ACCTextStickerConfig *)textStickerConfig:(AWEStoryTextImageModel *)textModel locationModel:(nullable AWEInteractionStickerLocationModel *)locationModel textStickerView:(ACCTextStickerView *)textStickerView
{
    return [self textStickerConfig:textModel locationModel:locationModel textStickerView:textStickerView preferredRatio:NO];
}

- (ACCTextStickerConfig *)textStickerConfig:(AWEStoryTextImageModel *)textModel locationModel:(nullable AWEInteractionStickerLocationModel *)locationModel textStickerView:(ACCTextStickerView *)textStickerView preferredRatio:(BOOL)preferredRatio
{
    ACCTextStickerConfig *config = [[ACCTextStickerConfig alloc] init];
    if ([self.dataProvider supportTextReading]) {
        if (ACCConfigEnum(kConfigInt_text_reader_multiple_sound_effects, ACCTextReaderPhase2Type) == ACCTextReaderPhase2TypeDisable) {
            config.textReadAction = textModel.readModel.useTextRead ? ACCStickerBubbleActionBizTextReadCancel : ACCStickerBubbleActionBizTextRead;
        } else {
            config.textReadAction = ACCStickerBubbleActionBizTextRead;
        }
    }

    @weakify(self);
    config.onceTapCallback = ^(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UITapGestureRecognizer * _Nonnull gesture) {
        @strongify(self);
        [self.logger logTextStickerViewDidTapOnce];
    };
    config.secondTapCallback = ^(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UITapGestureRecognizer * _Nonnull gesture) {
        @strongify(self);
        
        [self editTextStickerView:textStickerView];
        [self markAndRemoveTextHint:AWEEditStickerHintTypeText];
        [self.logger logTextStickerViewDidTapSecond];
    };
    config.gestureCanStartCallback = ^BOOL(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UIGestureRecognizer * _Nonnull gesture) {
        @strongify(self);
        [self markAndRemoveTextHint:AWEEditStickerHintTypeText];
        if ([gesture isKindOfClass:UIPanGestureRecognizer.class] &&
            self.panStart) {
            self.panStart();
        }
        
        return YES;
    };
    config.gestureEndCallback = ^(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UIGestureRecognizer * _Nonnull gesture) {
        @strongify(self);
        if ([gesture isKindOfClass:UIPanGestureRecognizer.class] &&
            self.panEnd) {
            self.panEnd();
        }
    };
    config.readText = ^{
        @strongify(self);
        if (ACCConfigEnum(kConfigInt_text_reader_multiple_sound_effects, ACCTextReaderPhase2Type) == ACCTextReaderPhase2TypeDisable) {
            [self markAndRemoveTextHint:AWEEditStickerHintTypeTextReading];
            if (textStickerView.textModel.readModel.useTextRead) {
                [self.logger logCancelTextReading:textModel.isAddedInEditView];
                [self removeTextReadingForStickerView:textStickerView];
            } else {
                [self.logger logClickTextReading:textModel.isAddedInEditView
                                            type:ACCTextStickerLoggerClickTextReaderTypePopup];
                [self requestTextReadingForStickerView:textStickerView];
            }
        } else {
            // Check
            [self.logger logClickTextReading:textModel.isAddedInEditView
                                        type:ACCTextStickerLoggerClickTextReaderTypePopup];
            NSDictionary *configs = ACCConfigDict(kConfigDict_text_read_sticker_configs);
            NSInteger editTextReadingMaxCount = [configs acc_integerValueForKey:@"read_text_char_count"] ? : 300;
            NSUInteger characterLength = [textStickerView.textView.text lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
            if (characterLength > editTextReadingMaxCount) {
                [ACCToast() show:ACCLocalizedString(@"creation_edit_text_reading_voice_toast2", @"Text too long to create speech audio")];
                return;
            }
            [self.speakerModel updateBeforeEditingWithTextStickerView:textStickerView];
            [self.dataProvider showTextReaderSoundEffectsSelectionViewController];
        }
    };
    config.editText = ^{
        @strongify(self);
        [self editTextStickerView:textStickerView];
        [self markAndRemoveTextHint:AWEEditStickerHintTypeText];
    };
    config.selectTime = ^{
        @strongify(self);
        !self.onTimeSelect ?: self.onTimeSelect(textStickerView);
    };
    config.willDeleteCallback = ^{
        @strongify(self);
        [self removeTextReadingForStickerView:textStickerView];
    };
    if (textStickerView.textModel.isTaskSticker) {
        config.isInDeleteStateCallback = ^{
            if (!ACC_isEmptyString(textStickerView.textView.text)) {
                [[NSNotificationCenter defaultCenter] postNotificationName:ACCStickerComponentDidDeleted object:nil userInfo:nil];
            }
        };
    }
    
    // 图集在story优化模式下不支持点击删除
    if ([self.dataProvider isImageAlbumEdit] || ACCConfigBool(ACCConfigBOOL_allow_sticker_delete)) {
        if ([self.dataProvider isImageAlbumEdit]) {
            config.type = ACCTextStickerConfigType_AlbumImage;
        }
        @weakify(textStickerView);
        config.deleteAction = ^{
            @strongify(self);
            @strongify(textStickerView);
            [self.logger logTextStickerViewWillDeleteWithEnterMethod:@"click"];
            [self.stickerContainerView removeStickerView:textStickerView];
        };
    }
    
    config.typeId = ACCStickerTypeIdText;
    config.hierarchyId = @(ACCStickerHierarchyTypeNormal);
    config.timeRangeModel.pts = [NSDecimalNumber decimalNumberWithString:@"-1"];
    config.gestureInvalidFrameValue = self.dataProvider.gestureInvalidFrameValue;
    if (locationModel) {
        config.timeRangeModel.startTime = locationModel.startTime;
        if (locationModel.endTime.integerValue == -1000) {
            // 从 NLE 恢复会把 endTime 恢复成 -1000，需要还原
            NSString *endTime = [NSString stringWithFormat:@"%.4f", self.player.stickerInitialEndTime];
            config.timeRangeModel.endTime = [NSDecimalNumber decimalNumberWithString:endTime];
        } else {
            config.timeRangeModel.endTime = locationModel.endTime;
        }
    } else {
        NSString *startTime = [NSString stringWithFormat:@"%.4f", 0.f];
        NSString *endTime = [NSString stringWithFormat:@"%.4f", self.player.stickerInitialEndTime];
        config.timeRangeModel.startTime = [NSDecimalNumber decimalNumberWithString:startTime];
        config.timeRangeModel.endTime = [NSDecimalNumber decimalNumberWithString:endTime];
        locationModel = [AWEInteractionStickerLocationModel new];
    }
    if (preferredRatio) {
        config.geometryModel = [locationModel ratioGeometryModel];
    } else {
        config.geometryModel = [locationModel geometryModel];
    }
    if (textModel.isNotDeletableSticker) {
        config.deleteable = @(NO);
    }
    return config;
}

- (UIView<ACCStickerProtocol> *)addTextWithTextInfoAndApply:(AWEStoryTextImageModel *)textModel locationModel:(nullable AWEInteractionStickerLocationModel *)locationModel index:(NSUInteger)idx
{
    if (!textModel) {
        return nil;
    }

    ACCTextStickerView *textStickerView = [[ACCTextStickerView alloc] initWithTextInfo:textModel options:ACCTextStickerViewAbilityOptionsNone];
    UIView<ACCStickerProtocol> *stickerView = [self.stickerContainerView addStickerView:textStickerView config:[self textStickerConfig:textModel locationModel:locationModel textStickerView:textStickerView preferredRatio:NO]];
    stickerView.stickerGeometry.preferredRatio = NO;
    [self apply:stickerView index:idx];
    return stickerView;
}

- (BOOL)canRecoverStickerStorageModel:(NSObject<ACCSerializationProtocol> *)sticker
{
    if ([sticker isKindOfClass:ACCTextStickerViewStorageModel.class]) {
        return YES;
    }
    
    return NO;
}

- (void)recoverStickerForContainer:(ACCStickerContainerView *)containerView storageModel:(ACCTextStickerViewStorageModel *)sticker
{
    [self p_recoverStickerForContainer:containerView storageModel:sticker];
}

- (UIView<ACCStickerProtocol> *)p_recoverStickerForContainer:(ACCStickerContainerView *)containerView storageModel:(ACCTextStickerViewStorageModel *)sticker
{
    @weakify(self);
    ACCTextStickerView *textStickerView = [ACCSerialization restoreFromObj:sticker to:ACCTextStickerView.class];
    textStickerView.triggerDragDeleteCallback = ^{
        @strongify(self);
        [self.logger logTextStickerViewWillDeleteWithEnterMethod:@"drag"];
    };
    ACCTextStickerConfig *config = [ACCSerialization restoreFromObj:sticker to:ACCTextStickerConfig.class];
    if (self.isImageAlbumEdit) {
        config.type = ACCTextStickerConfigType_AlbumImage;
    }
    
    if ([self.dataProvider supportTextReading]) {
        if (ACCConfigEnum(kConfigInt_text_reader_multiple_sound_effects, ACCTextReaderPhase2Type) == ACCTextReaderPhase2TypeDisable) {
            config.textReadAction = sticker.textModel.readModel.useTextRead ? ACCStickerBubbleActionBizTextReadCancel : ACCStickerBubbleActionBizTextRead;
        } else {
            config.textReadAction = ACCStickerBubbleActionBizTextRead;
        }
    }
    
    config.onceTapCallback = ^(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UITapGestureRecognizer * _Nonnull gesture) {
        @strongify(self);
        [self.logger logTextStickerViewDidTapOnce];
    };
    config.secondTapCallback = ^(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UITapGestureRecognizer * _Nonnull gesture) {
        @strongify(self);
        [self editTextStickerView:textStickerView];
        [self markAndRemoveTextHint:AWEEditStickerHintTypeText];
        [self.logger logTextStickerViewDidTapSecond];
    };
    config.gestureCanStartCallback = ^BOOL(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UIGestureRecognizer * _Nonnull gesture) {
        @strongify(self);
        [self markAndRemoveTextHint:AWEEditStickerHintTypeText];
        if ([gesture isKindOfClass:UIPanGestureRecognizer.class] &&
            self.panStart) {
            self.panStart();
        }
        
        return YES;
    };
    config.gestureEndCallback = ^(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UIGestureRecognizer * _Nonnull gesture) {
        @strongify(self);
        if ([gesture isKindOfClass:UIPanGestureRecognizer.class] &&
            self.panEnd) {
            self.panEnd();
        }
    };
    config.readText = ^{
        @strongify(self);
        if (ACCConfigEnum(kConfigInt_text_reader_multiple_sound_effects, ACCTextReaderPhase2Type) == ACCTextReaderPhase2TypeDisable) {
            [self markAndRemoveTextHint:AWEEditStickerHintTypeTextReading];
            if (textStickerView.textModel.readModel.useTextRead) {
                [self.logger logCancelTextReading:textStickerView.textModel.isAddedInEditView];
                [self removeTextReadingForStickerView:textStickerView];
            } else {
                [self.logger logClickTextReading:textStickerView.textModel.isAddedInEditView
                                            type:ACCTextStickerLoggerClickTextReaderTypePopup];
                [self requestTextReadingForStickerView:textStickerView];
            }
        } else {
            // Check
            [self.logger logClickTextReading:textStickerView.textModel.isAddedInEditView
                                        type:ACCTextStickerLoggerClickTextReaderTypePopup];
            NSDictionary *configs = ACCConfigDict(kConfigDict_text_read_sticker_configs);
            NSInteger editTextReadingMaxCount = [configs acc_integerValueForKey:@"read_text_char_count"] ? : 300;
            NSUInteger characterLength = [textStickerView.textView.text lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
            if (characterLength > editTextReadingMaxCount) {
                [ACCToast() show:ACCLocalizedString(@"creation_edit_text_reading_voice_toast2", @"Text too long to create speech audio")];
                return;
            }
            [self.speakerModel updateBeforeEditingWithTextStickerView:textStickerView];
            [self.dataProvider showTextReaderSoundEffectsSelectionViewController];
        }
    };
    config.editText = ^{
        @strongify(self);
        [self editTextStickerView:textStickerView];
        [self markAndRemoveTextHint:AWEEditStickerHintTypeText];
    };
    config.selectTime = ^{
        @strongify(self);
        !self.onTimeSelect ?: self.onTimeSelect(textStickerView);
    };
    config.willDeleteCallback = ^{
        @strongify(self);
        [self removeTextReadingForStickerView:textStickerView];
    };
    if ([self.dataProvider isImageAlbumEdit]) {
        config.type = ACCTextStickerConfigType_AlbumImage;
        @weakify(textStickerView);
        config.deleteAction = ^{
            @strongify(self);
            @strongify(textStickerView);
            [self.logger logTextStickerViewWillDeleteWithEnterMethod:@"click"];
            [self.stickerContainerView removeStickerView:textStickerView];
        };
    }
    
    config.gestureInvalidFrameValue = self.dataProvider.gestureInvalidFrameValue;
    UIView<ACCStickerProtocol> *stickerWrapper = [containerView addStickerView:textStickerView config:config];
    stickerWrapper.stickerGeometry.preferredRatio = NO;
    
    return stickerWrapper;
}

- (void)editTextStickerView:(ACCTextStickerView *)stickerView
{
    [self.speakerModel updateBeforeEditingWithTextStickerView:stickerView];
    [self.stickerContainerView.overlayView addSubview:self.textStickerEditView];
    [self.textStickerEditView startEditStickerView:stickerView];
    if (stickerView.textModel.isTaskSticker) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ACCStickerComponentDidEdited object:nil userInfo:nil];
    }
}

- (void)showTextHintOnStickerView:(UIView *)stickerView
                        textModel:(AWEStoryTextImageModel *)textModel
{
    if (!self.textHintView.superview) {
        [self.uiContainerView addSubview:self.textHintView];
    }
    
    if ([AWEEditStickerHintView isNeedShowHintViewForType:AWEEditStickerHintTypeTextReading] && [self.dataProvider supportTextReading]) {
        [self.textHintView showHint:ACCLocalizedString(@"creation_edit_text_reading_entrance_tap_toast", @"Tap to try text-to-speech") type:AWEEditStickerHintTypeTextReading];
        [AWEEditStickerHintView setNoNeedShowForType:AWEEditStickerHintTypeTextReading];
        [self.logger logTextReadingBubbleShow:textModel.isAddedInEditView];
    } else {
        [self.textHintView showHint:ACCLocalizedString(@"creation_edit_text_double_click", @"双击可编辑文字") type:AWEEditStickerHintTypeText];
    }
    self.textHintView.bounds = (CGRect){CGPointZero, self.textHintView.intrinsicContentSize};
    self.textHintView.center = [stickerView.superview convertPoint:CGPointMake(stickerView.acc_centerX, stickerView.acc_top - self.textHintView.acc_height) toView:self.uiContainerView];
}

- (void)markAndRemoveTextHint:(AWEEditStickerHintType)type
{
    [AWEEditStickerHintView setNoNeedShowForType:type];
    [self.textHintView dismissWithAnimation:YES];
}

- (AWEEditStickerHintView *)textHintView
{
    if (!_textHintView) {
        if (ACCConfigEnum(kConfigInt_text_reader_multiple_sound_effects, ACCTextReaderPhase2Type) == ACCTextReaderPhase2TypeNotShowInToolBar) {
            _textHintView = [[AWEEditStickerHintView alloc] initWithGradientAndFrame:CGRectZero];
        } else {
            _textHintView = [AWEEditStickerHintView new];
        }
    }
    return _textHintView;
}

#pragma mark - text read

- (void)requestTextReadingForStickerView:(ACCTextStickerView *)stickerView
{
    UIView<ACCStickerProtocol> *stickerTimeView = [stickerView.stickerContainer stickerViewWithContentView:stickerView];
    @weakify(self);
    void (^applyAudioAssetBlock)(AWETextStickerReadModel *) = ^(AWETextStickerReadModel *model) {
        @strongify(self);
        [self p_applyAudioToVE:model
                   stickerView:stickerView
               stickerTimeView:stickerTimeView];
    };
    
    AWETextStickerReadModel *readModel = stickerView.textModel.readModel;
    NSString *text = stickerView.textView.text;
    //Use Cache
    if (readModel.audioPath != nil && [readModel.text isEqualToString:text] && [[NSFileManager defaultManager] fileExistsAtPath:[[self.dataProvider textStickerFolderForDraft] stringByAppendingPathComponent:readModel.audioPath]]) {
        [self.player pause];
        ACCBLOCK_INVOKE(applyAudioAssetBlock,readModel);
        return;
    }
    
    //Check
    NSDictionary *configs = ACCConfigDict(kConfigDict_text_read_sticker_configs);
    NSInteger editTextReadingMaxCount = [configs acc_integerValueForKey:@"read_text_char_count"] ? : 300;
    NSUInteger characterLength = [text lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    if (characterLength > editTextReadingMaxCount) {
        [ACCToast() show:ACCLocalizedString(@"creation_edit_text_reading_voice_toast2", @"Text too long to create speech audio")];
        return;
    }
    
    //Request
    UIView<ACCTextLoadingViewProtcol> *loadingView = [ACCLoading() showWindowLoadingWithTitle:ACCLocalizedString(@"creation_edit_text_reading_load", @"Loading...") animated:YES];
    self.loadingView = loadingView;
    [loadingView showCloseBtn:YES closeBlock:^{
        @strongify(self);
        [self cancelReadRequest];
    }];
    
    NSString *fullFilePath = [[self.dataProvider textStickerFolderForDraft] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.mp3",[NSUUID UUID].UUIDString,@"readtext"]];

    [self.player pause];
    [ACCMonitor() startTimingForKey:kAWEEditTextReadingRequestMonitorKey];
    [[ACCTextReadingRequestHelper sharedHelper] requestTextReadingForUploadText:text filePath:fullFilePath completionBlock:^(BOOL success, NSString *filePath, NSError *error) {
        @strongify(self);
        BOOL readSuccess = NO;
        if (success && !error && filePath && stickerView.textStickerId) {
            readSuccess = YES;
            AWETextStickerReadModel *readModel = [[AWETextStickerReadModel alloc] init];
            readModel.stickerKey = stickerView.textStickerId;
            readModel.text = text;
            readModel.audioPath = filePath.lastPathComponent;
            stickerView.textModel.readModel = readModel;
            ACCBLOCK_INVOKE(applyAudioAssetBlock,readModel);
        } else {
            if (self.loadingView) {
                if ([error.domain isEqualToString:@"com.aweme.network.error"]) {
                    [ACCToast() showError:ACCLocalizedString(@"creation_edit_text_reading_Internet_connection_toast", @"No internet connection. Connect to the internet and try again.")];
                } else {
                    [ACCToast() showError:error.localizedDescription];
                }
            }
            [self.player play];
        }
        [self.loadingView dismiss];
        self.loadingView = nil;
        [ACCMonitor() trackService:kAWEEditTextReadingRequestMonitorKey status:readSuccess ? 0 : 1 extra:@{@"code":@(error.code),@"duration":@([ACCMonitor() timeIntervalForKey:kAWEEditTextReadingRequestMonitorKey])}];
        [ACCMonitor() cancelTimingForKey:kAWEEditTextReadingRequestMonitorKey];
    }];
}

- (void)p_requestTextReadingForStickerViewModern:(ACCTextStickerView *)stickerView
{
    UIView<ACCStickerProtocol> *stickerTimeView = [stickerView.stickerContainer stickerViewWithContentView:stickerView];
    @weakify(self);
    void (^applyAudioAssetBlock)(AWETextStickerReadModel *) = ^(AWETextStickerReadModel *model) {
        @strongify(self);
        [self p_applyAudioToVE:model
                   stickerView:stickerView
               stickerTimeView:stickerTimeView];
    };
    
    AWETextStickerReadModel *readModel = stickerView.textModel.readModel;
    NSString *text = stickerView.textView.text;
    //Use Cache
    if (readModel.audioPath != nil && [readModel.text isEqualToString:text] && [[NSFileManager defaultManager] fileExistsAtPath:[[self.dataProvider textStickerFolderForDraft] stringByAppendingPathComponent:readModel.audioPath]]) {
        [self.player pause];
        ACCBLOCK_INVOKE(applyAudioAssetBlock,readModel);
        return;
    }
    
    //Check
    NSDictionary *configs = ACCConfigDict(kConfigDict_text_read_sticker_configs);
    NSInteger editTextReadingMaxCount = [configs acc_integerValueForKey:@"read_text_char_count"] ? : 300;
    NSUInteger characterLength = [text lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    if (characterLength > editTextReadingMaxCount) {
        [ACCToast() show:ACCLocalizedString(@"creation_edit_text_reading_voice_toast2", @"Text too long to create speech audio")];
        return;
    }
    
    //Request
    UIView<ACCTextLoadingViewProtcol> *loadingView = [ACCLoading() showWindowLoadingWithTitle:ACCLocalizedString(@"creation_edit_text_reading_load", @"Loading...") animated:YES];
    self.loadingView = loadingView;
    [loadingView showCloseBtn:YES closeBlock:^{
        @strongify(self);
        [self cancelReadRequest];
    }];
    
    NSString *fullFilePath = [[self.dataProvider textStickerFolderForDraft] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.mp3",[NSUUID UUID].UUIDString,@"readtext"]];

    [self.player pause];
    [[ACCTextReadingRequestHelper sharedHelper] requestTextReaderForUploadText:text
                                                                   textSpeaker:stickerView.textModel.readModel.soundEffect
                                                                      filePath:fullFilePath
                                                               completionBlock:^(BOOL success, NSString *filePath, NSError *error) {
        @strongify(self);
        BOOL readSuccess = NO;
        if (success && !error && filePath && stickerView.textStickerId) {
            readSuccess = YES;
            AWETextStickerReadModel *readModel = [[AWETextStickerReadModel alloc] init];
            readModel.stickerKey = stickerView.textStickerId;
            readModel.text = text;
            readModel.audioPath = filePath.lastPathComponent;
            readModel.soundEffect = stickerView.textModel.readModel.soundEffect;
            stickerView.textModel.readModel = readModel;
            ACCBLOCK_INVOKE(applyAudioAssetBlock,readModel);
        } else {
            if (self.loadingView) {
                if (error) {
                    if ([error.domain isEqualToString:@"com.aweme.network.error"]) {
                        [ACCToast() showError:ACCLocalizedString(@"creation_edit_text_reading_Internet_connection_toast", @"No internet connection. Connect to the internet and try again.")];
                        AWELogToolError2(@"request tts audio", AWELogToolTagEdit, @"requesting text reading for stickerview failed: %@", error);
                    } else {
                        [ACCToast() showError:error.localizedDescription];
                    }
                } else {
                    NSCharacterSet *charSet = [NSCharacterSet whitespaceCharacterSet];
                    NSString *trimmedString = [text stringByTrimmingCharactersInSet:charSet];
                    if ([trimmedString isEqualToString:@""]) {
                        // it's empty or contains only white spaces
                        [ACCToast() show:ACCLocalizedString(@"creation_edit_text_reading_voice_toast4", @"暂时只支持中文朗读")];
                    }
                }
            }
            [self.player play];
        }
        [self.loadingView dismiss];
        self.loadingView = nil;
    }];
}

- (void)removeTextReadingForStickerView:(ACCTextStickerView *)stickerView
{
    AWETextStickerReadModel *readModel = stickerView.textModel.readModel;
    if (readModel.stickerKey) {
        readModel.useTextRead = NO;
        readModel.soundEffect = nil;
        readModel.audioPath = nil;
        [self.dataProvider removeTextReadForKey:readModel.stickerKey];
        [stickerView updateBubbleStatusAfterEdit];
    }
}

- (void)textEditFinishedForStickerView:(ACCTextStickerView *)stickerView
{
    AWETextStickerReadModel *readModel = stickerView.textModel.readModel;
    NSString *text = stickerView.textView.text;
    
    if (ACCConfigEnum(kConfigInt_text_reader_multiple_sound_effects, ACCTextReaderPhase2Type) == ACCTextReaderPhase2TypeDisable) {
        if (readModel.useTextRead && ![readModel.text isEqualToString:text]) {
            NSInteger popCount = [ACCCache() integerForKey:kAWEEditTextReadingChangeToastCacheKey];
            if (popCount < 3) {
                [ACCToast() show:ACCLocalizedString(@"creation_edit_text_reading_voice_toast3", @"Use the text-to-speech feature again to update audio")];
                [ACCCache() setInteger:popCount+1 forKey:kAWEEditTextReadingChangeToastCacheKey];
            }
            [self removeTextReadingForStickerView:stickerView];
        }
    } else {
        { // it's empty or contains only white spaces
            NSCharacterSet *charSet = [NSCharacterSet whitespaceCharacterSet];
            NSString *trimmedString = [text stringByTrimmingCharactersInSet:charSet];
            if ([trimmedString isEqualToString:@""]) {
                [self removeTextReadingForStickerView:stickerView];
                return;
            }
        }
        { // normal
            if (readModel.useTextRead && ![readModel.text isEqualToString:text]) {
                [self removeTextReadingForStickerView:stickerView];
                readModel.soundEffect = self.speakerModel.modelWhileEditing.soundEffect;
                [self p_requestTextReadingForStickerViewModern:stickerView];
            }
        }
    }
}

- (void)cancelReadRequest
{
    if (self.loadingView) {
        [self.loadingView dismiss];
        self.loadingView = nil;
        [self.player play];
        [[ACCTextReadingRequestHelper sharedHelper] cancelTextReadingRequest];
    }
}

#pragma mark - text audit

- (NSArray <ACCStickerViewType> *)textStickerViewList
{
    return [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdText] acc_filter:^BOOL(ACCStickerViewType  _Nonnull item) {
        return [item.contentView isKindOfClass:[ACCTextStickerView class]];
    }];
}

- (NSArray <NSString *> *)textsArray
{
    if ([self textStickerViewList].count == 0) {
        return nil;
    }
    NSMutableArray *strArray = [NSMutableArray array];
    NSArray *stortedTextViews = [self textViewsAscendingByStartTime];
    for (ACCStickerViewType sticker in stortedTextViews) {
        ACCTextStickerView *textStickerView = (ACCTextStickerView *)sticker.contentView;
        NSString *str = textStickerView.textView.text;
        if (str.length) {
            [strArray addObject:str];
        }
    }
    return strArray;
}

- (NSArray <NSString *> *)textFontsArray
{
    if ([self textStickerViewList].count == 0) {
        return nil;
    }
    NSMutableArray *fontsArray = [NSMutableArray array];
    for (ACCStickerViewType sticker in [self textStickerViewList]) {
        ACCTextStickerView *textStickerView = (ACCTextStickerView *)sticker.contentView;
        NSString *font = textStickerView.textModel.fontModel.title;
        if (font.length) {
            [fontsArray addObject:font];
        }
    }
    return fontsArray;
}

- (NSArray <ACCStickerViewType> *)textViewsAscendingByStartTime
{
    return [[self textStickerViewList] sortedArrayUsingComparator:^NSComparisonResult(ACCStickerViewType _Nonnull obj1, ACCStickerViewType _Nonnull obj2) {
        return [@(obj1.realStartTime) compare:@(obj2.realStartTime)];
    }];
}

- (NSArray <NSString *> *)textFontEffectIdsArray
{
    if ([self textStickerViewList].count == 0) {
        return nil;
    }
    NSMutableArray *fontsArray = [NSMutableArray array];
    for (ACCStickerViewType sticker in [self textStickerViewList]) {
        ACCTextStickerView *textStickerView = (ACCTextStickerView *)sticker.contentView;
        NSString *font = textStickerView.textModel.fontModel.effectId;
        if (font.length) {
            [fontsArray addObject:font];
        }
    }
    return fontsArray;
}

- (NSString *)textsArrayInString
{
    if ([self textStickerViewList].count == 0) {
        return nil;
    }
    NSArray <NSString *> *textsArray = [self textsArray];
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:textsArray options:0 error:&error];
    if (error) {
        AWELogToolError2(@"textsArrayInString", AWELogToolTagEdit, @"gen text array failed: %@", error);
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (NSString *)textFontsArrayInString
{
    if ([self textStickerViewList].count == 0) {
        return @"";
    }
    NSArray <NSString *> *textFontsArray = [self textFontsArray];
    if (textFontsArray) {
        return [textFontsArray componentsJoinedByString:@","];
    } else {
        return @"";
    }
}

- (NSString *)textFontEffectIdsArrayInString
{
    if ([self textStickerViewList].count == 0) {
        return @"";
    }
    NSArray <NSString *> *textFontsArray = [self textFontEffectIdsArray];
    if (textFontsArray) {
        return [textFontsArray componentsJoinedByString:@","];
    } else {
        return @"";
    }
}


#pragma mark - ACCStickerMigrationProtocol

+ (BOOL)fillCrossPlatformStickerByUserInfo:(NSDictionary *)userInfo repository:(id<ACCPublishRepository>)sessionModel context:(nonnull id<ACCCrossPlatformMigrateContext>)context sticker:(NLESegmentSticker_OC *__autoreleasing *)sticker
{
    if (userInfo.acc_stickerType == ACCEditEmbeddedStickerTypeText) {
        // find textInfo
        NSData *textInfoData = [userInfo objectForKey:kACCTextInfoModelKey] ?: [NSData new];
        NSError *error = nil;
        NSDictionary *textInfoDict = [NSJSONSerialization JSONObjectWithData:textInfoData options:0 error:&error] ?: [NSDictionary new];
        if (error != nil) {
            AWELogToolError2(@"TextSticker", AWELogToolTagDraft, @"Text Info Data Convert To Json Error: %@", error);
            error = nil;
        }
        AWEStoryTextImageModel *textInfo = [MTLJSONAdapter modelOfClass:[AWEStoryTextImageModel class] fromJSONDictionary:textInfoDict error:&error];
        if (error != nil) {
            AWELogToolError2(@"TextSticker", AWELogToolTagDraft, @"Text Info Json Convert To Model Error: %@", error);
            error = nil;
        }

        // find location info
        id textLocation = [userInfo objectForKey:kACCTextLocationModelKey];
        NSData *textLocationData = (NSData *)([textLocation isKindOfClass:[NSData class]] ? textLocation : nil);
        NSDictionary *textLocationDict = [NSJSONSerialization JSONObjectWithData:textLocationData options:0 error:&error];
        if (error != nil) {
            AWELogToolError2(@"TextSticker", AWELogToolTagDraft, @"Location Data Convert To Json Error: %@", error);
            error = nil;
        }
        AWEInteractionStickerLocationModel *stickerLocation = [MTLJSONAdapter modelOfClass:[AWEInteractionStickerLocationModel class] fromJSONDictionary:textLocationDict error:&error];
        if (error != nil) {
            AWELogToolError2(@"TextSticker", AWELogToolTagDraft, @"Location Json Convert To Model Error: %@", error);
        }

        // find sticker id
        NSString *textStickerId = [userInfo acc_stringValueForKey:kACCTextInfoTextStickerIdKey];
        
        // creat sticker
        NLESegmentImageSticker_OC *sticker_ = [[NLESegmentImageSticker_OC alloc] init];
        sticker_.stickerType = ACCCrossPlatformStickerTypeText;
        sticker_.imageFile = [[NLEResourceNode_OC alloc] init];
        sticker_.imageFile.resourceType = NLEResourceTypeImageSticker;
        sticker_.imageFile.resourceFile = context.resourcePath;
        
        // Text Model
        NSMutableDictionary *textDic = [NSMutableDictionary dictionary];
        textDic[@"text"] = textInfo.content;
        
        // Text Style Model
        NSMutableDictionary *styleDic = [NSMutableDictionary dictionary];
        styleDic[@"font_size"] = @28.f;
        styleDic[@"font_id"] = textInfo.fontModel.effectId;
        if (textInfo.fontColor != nil) {
            NSString *colorStr = [NSString stringWithFormat:@"0xFF%@", [textInfo.fontColor.colorString substringFromIndex:2]];
            styleDic[@"text_color"] = @(colorStr.acc_argbColorHexValue);
            if (textInfo.fontColor.borderColorString != nil) {
                NSString *borderColorString = [NSString stringWithFormat:@"0xFF%@", [textInfo.fontColor.borderColorString substringFromIndex:2]];
                styleDic[@"text_border_color"] = @(borderColorString.acc_argbColorHexValue);
            }
        } else {
            styleDic[@"text_color"] = @(0xFFFFFFFF);
            styleDic[@"text_border_color"] = @(0xFF000000);
        }
        styleDic[@"align_type"] = @(crossPlatformAlignmentFromTextAlignment(textInfo.alignmentType));
        styleDic[@"bg_style"] = @(textInfo.textStyle);
        
        // Text Location Model
        NSMutableDictionary *locationDic = [NSMutableDictionary dictionary];
        locationDic[@"transformX"] = @(context.transformX);
        locationDic[@"transformY"] = @(context.transformY);
        locationDic[@"scale"] = @([stickerLocation.scale floatValue]);
        locationDic[@"rotation"] = @(-1 * [stickerLocation.rotation floatValue]);
        
        // Text Read Model
        NSMutableDictionary *readDic = [NSMutableDictionary dictionary];
        readDic[@"use_text_read"] = @(textInfo.readModel.useTextRead);
        readDic[@"text_read_text"] = textInfo.readModel.text;
        NSString *audioPath = ACC_isEmptyString(textInfo.readModel.audioPath) ? nil : [NSString stringWithFormat:@"./%@", textInfo.readModel.audioPath];
        readDic[@"text_read_audio_path"] = audioPath;
        readDic[@"text_read_speaker_id"] = textInfo.readModel.soundEffect;
        
        /// text extra info
        NSArray *textExtraRet = [textInfoDict  acc_arrayValueForKey:@"extraInfos"];
        
        // extra
        sticker_.extraDict = [NSMutableDictionary dictionary];
        sticker_.extraDict[@"type"] = @3;
        sticker_.extraDict[@"id"] = textStickerId;
        sticker_.extraDict[@"text_info"] = textDic;
        sticker_.extraDict[@"style_info"] = styleDic;
        sticker_.extraDict[@"location_info"] = locationDic;
        sticker_.extraDict[@"text_read_info"] = readDic;
        sticker_.extraDict[@"text_extra_infos"] = textExtraRet;
        sticker_.extraDict[ACCStickerDeleteableKey] = userInfo[ACCStickerDeleteableKey];
        sticker_.extraDict[ACCStickerEditableKey] = userInfo[ACCStickerEditableKey];
        sticker_.extraDict[kACCStickerGroupIDKey] = userInfo[kACCStickerGroupIDKey];

        // iOS resource path
        sticker_.extraDict[ACCCrossPlatformiOSResourcePathKey] = context.resourcePath;
        *sticker = sticker_;

        return YES;
    }
    return NO;
}

+ (void)updateUserInfo:(NSDictionary *__autoreleasing *)userInfo repoModel:(id<ACCPublishRepository>)sessionModel byCrossPlatformSlot:(nonnull NLETrackSlot_OC *)slot
{
    if (slot.sticker.stickerType == ACCCrossPlatformStickerTypeText) {
        NLESegmentSticker_OC *sticker = slot.sticker;
        
        NSString *textStickerID = [sticker.extraDict acc_stringValueForKey:@"id"];
        if (ACC_isEmptyString(textStickerID)) {
            textStickerID = [NSString stringWithFormat:@"%@", @([[NSDate date] timeIntervalSince1970])];
        }
        NSMutableDictionary *temp_userInfo = [NSMutableDictionary dictionary];
        temp_userInfo.acc_stickerType = ACCEditEmbeddedStickerTypeText;
        temp_userInfo[kACCTextInfoTextStickerIdKey] = textStickerID;
        temp_userInfo[ACCStickerDeleteableKey] = [sticker.extraDict acc_objectForKey:ACCStickerDeleteableKey];
        temp_userInfo[ACCStickerEditableKey] = [sticker.extraDict acc_objectForKey:ACCStickerEditableKey];
        temp_userInfo[kACCStickerGroupIDKey] = [sticker.extraDict acc_stringValueForKey:kACCStickerGroupIDKey];

        NSDictionary *textDic = [sticker.extraDict acc_dictionaryValueForKey:@"text_info"];
        NSDictionary *styleDic = [sticker.extraDict acc_dictionaryValueForKey:@"style_info"];
        NSDictionary *locationDic = [sticker.extraDict acc_dictionaryValueForKey:@"location_info"];
        NSDictionary *readDic = [sticker.extraDict acc_dictionaryValueForKey:@"text_read_info"];
        
        // AWEStoryTextImageModel
        AWEStoryTextImageModel *textInfo = [[AWEStoryTextImageModel alloc] init];
        textInfo.content = [textDic acc_stringValueForKey:@"text"];
        textInfo.realStartTime = CMTimeGetSeconds(slot.startTime);
        textInfo.realDuration = CMTimeGetSeconds(slot.endTime) - textInfo.realStartTime;
        
        /// Font
        NSUInteger textColor = [styleDic acc_unsignedIntegerValueForKey:@"text_color"];
        if (textColor != 0) {
            NSString *textColorString = [NSString acc_colorHexStringFrom:(uint32_t)textColor];
            NSString *borderColorString = nil;
            if (textColorString.length >= 8) {
                textColorString = [NSString stringWithFormat:@"0x%@", [textColorString substringFromIndex:2]];
            }
            
            NSUInteger borderColor = [styleDic acc_unsignedIntegerValueForKey:@"text_border_color"];
            if (borderColor != 0) {
                borderColorString = [NSString acc_colorHexStringFrom:(uint32_t)borderColor];
                if (borderColorString.length >= 8) {
                    borderColorString = [NSString stringWithFormat:@"0x%@", [borderColorString substringFromIndex:2]];
                }
            }
            
            AWEStoryColor *fontColor = [AWEStoryColor colorWithTextColorHexString:textColorString borderColorHexString:borderColorString];
            textInfo.fontColor = fontColor;
        }
        textInfo.fontSize = [styleDic acc_floatValueForKey:@"font_size"];
        NSString *fontID = [styleDic acc_stringValueForKey:@"font_id"];
        if (fontID != nil) {
            AWEStoryFontModel *fontModel = [[AWEStoryFontModel alloc] init];
            fontModel.effectId = fontID;
            textInfo.fontModel = fontModel;
        }
        
        /// Alignment
        textInfo.alignmentType = textAlignmentFromCrossPlatformAlignment([styleDic acc_integerValueForKey:@"align_type"]);
        /// Style
        textInfo.textStyle = [styleDic acc_unsignedIntegerValueForKey:@"bg_style"];
        
        /// AWETextStickerReadModel
        NSString *textReadText = [readDic acc_stringValueForKey:@"text_read_text"];
        if (textReadText != nil && textReadText.length > 0) {
            AWETextStickerReadModel *readModel = [[AWETextStickerReadModel alloc] init];
            readModel.stickerKey = textStickerID;
            readModel.useTextRead = [readDic acc_boolValueForKey:@"use_text_read"];
            readModel.text = textReadText;
            NSString *audioPath = [readDic acc_stringValueForKey:@"text_read_audio_path"];
            readModel.audioPath = [audioPath stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"./"]];
            readModel.soundEffect = [readDic acc_stringValueForKey:@"text_read_speaker_id"];
            textInfo.readModel = readModel;
        }
        
        /// text extra info
        NSArray *extraInfosDicArray = [sticker.extraDict acc_arrayValueForKey:@"text_extra_infos"];
        if (!ACC_isEmptyArray(extraInfosDicArray)) {
            NSError *extraTransError = nil;
            textInfo.extraInfos = [MTLJSONAdapter modelsOfClass:[ACCTextStickerExtraModel class] fromJSONArray:extraInfosDicArray error:&extraTransError];
            if (extraTransError != nil) {
                AWELogToolError2(@"TextSticker", AWELogToolTagDraft, @"Text Info Model extraInfos Convert To model Error: %@", extraTransError);
            }
        }
        
        NSError *error = nil;
        NSDictionary *textInfoDic = [MTLJSONAdapter JSONDictionaryFromModel:textInfo error:&error] ?: [[NSDictionary alloc] init];
        if (error != nil) {
            AWELogToolError2(@"TextSticker", AWELogToolTagDraft, @"Text Info Model Convert To Json Error: %@", error);
            error = nil;
        }
        NSData *textInfoData = [NSJSONSerialization dataWithJSONObject:textInfoDic options:0 error:&error];
        if (textInfoData) {
            [temp_userInfo setObject:textInfoData forKey:kACCTextInfoModelKey];
        } else if (error != nil) {
            AWELogToolError2(@"TextSticker", AWELogToolTagDraft, @"Text Info Json Convert To Data Error: %@", error);
            error = nil;
        }
        
        // AWEInteractionStickerLocationModel
        AWEInteractionStickerLocationModel *locationModel = [[AWEInteractionStickerLocationModel alloc] init];
        NSString *startTimeStr = [NSString stringWithFormat:@"%.4f", CMTimeGetSeconds(slot.startTime) * 1000.f]; //精度毫秒
        NSString *endTimeStr = [NSString stringWithFormat:@"%.4f", CMTimeGetSeconds(slot.endTime) * 1000.f];
        locationModel.startTime = [NSDecimalNumber decimalNumberWithString:startTimeStr];
        locationModel.endTime = [NSDecimalNumber decimalNumberWithString:endTimeStr];
        NSString *xStr = [NSString stringWithFormat:@"%.4f", ([locationDic acc_floatValueForKey:@"transformX"] + 1) / 2];
        NSString *yStr = [NSString stringWithFormat:@"%.4f", (-[locationDic acc_floatValueForKey:@"transformY"] + 1) /2];
        CGFloat scale = [locationDic acc_floatValueForKey:@"scale"];
        NSString *scaleStr = [NSString stringWithFormat:@"%.4f", scale != 0 ? scale : slot.scale];
        NSString *rotationStr = [NSString stringWithFormat:@"%.4f", [locationDic acc_floatValueForKey:@"rotation"] * -1.f];
        locationModel.x = [NSDecimalNumber decimalNumberWithString:xStr];
        locationModel.y = [NSDecimalNumber decimalNumberWithString:yStr];
        locationModel.isRatioCoord = YES;
        locationModel.scale = [NSDecimalNumber decimalNumberWithString:scaleStr];
        locationModel.rotation = [NSDecimalNumber decimalNumberWithString:rotationStr];
        locationModel.width = [NSDecimalNumber decimalNumberWithString:@"0"];
        locationModel.height = [NSDecimalNumber decimalNumberWithString:@"0"];
        
        NSDictionary *textLocation = [MTLJSONAdapter JSONDictionaryFromModel:locationModel error:&error];
        if (error != nil) {
            AWELogToolError2(@"TextSticker", AWELogToolTagDraft, @"Location Model Convert To Json Error: %@", error);
            error = nil;
        }
        NSData *textLocationData = [NSJSONSerialization dataWithJSONObject:textLocation options:0 error:&error];
        if (textLocationData) {
            [temp_userInfo setObject:textLocationData forKey:kACCTextLocationModelKey];
        } else if (error != nil) {
            AWELogToolError2(@"TextSticker", AWELogToolTagDraft, @"Location Json Convert To Data Error: %@", error);
            error = nil;
        }
        
        // assignment userInfo
        *userInfo = temp_userInfo;
    }
}
#pragma mark - Getters and Setters

- (ACCTextStickerHandlerSpeakerModel *)speakerModel
{
    if (!_speakerModel) {
        _speakerModel = [[ACCTextStickerHandlerSpeakerModel alloc] init];
    }
    return _speakerModel;
}

@end
