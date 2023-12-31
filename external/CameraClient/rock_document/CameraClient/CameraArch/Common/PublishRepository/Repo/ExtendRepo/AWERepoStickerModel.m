//
//  AWERepoStickerModel.m
//  CameraClient-Pods-Aweme
//
//  Created by 马超 on 2021/4/11.
//

#import "AWERepoStickerModel.h"

#import <CreationKitArch/AWEInteractionStickerModel.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <TTVideoEditor/IESInfoSticker.h>
#import <CreationKitArch/ACCEditAndPublishConstants.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import <CreationKitArch/ACCPublishRepository.h>
#import <CreationKitArch/AWEInfoStickerInfo.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoPublishConfigModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitArch/CKConfigKeysDefines.h>
#import <CreativeKit/ACCMacrosTool.h>
#import <CameraClientModel/ACCVideoCommentModel.h>
#import <CameraClientModel/ACCVideoReplyCommentModel.h>

#import "AWERepoVideoInfoModel.h"
#import "ACCConfigKeyDefines.h"
#import "IESInfoSticker+ACCAdditions.h"
#import "AWERepoMusicModel.h"
#import "AWEInteractionVideoShareStickerModel.h"
#import <CameraClientModel/ACCTextRecommendModel.h>
#import <CameraClientModel/ACCVideoReplyModel.h>

NSString *const ACCStickerDeleteableKey = @"deleteable";
NSString *const ACCStickerEditableKey = @"text_editable";

@implementation AWEVideoPublishViewModel (AWERepoSticker)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:AWERepoStickerModel.class];
    return info;
}

- (AWERepoStickerModel *)repoSticker {
    AWERepoStickerModel *stickerModel = [self extensionModelOfClass:AWERepoStickerModel.class];
    NSAssert(stickerModel, @"extension model should not be nil");
    return stickerModel;
}

@end

@implementation AWERepoStickerModel

#pragma mark - Track Info

/// Video Comment Sticker
- (NSDictionary *)videoCommentStickerTrackInfo
{
    ACCRepoTrackModel *trackModel = [self.repository extensionModelOfClass:ACCRepoTrackModel.class];
    if (![trackModel.referString isEqualToString:@"comment_reply"]) {
        return [NSDictionary dictionary];
    }
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    [self.shootSameStickerModels enumerateObjectsUsingBlock:^(ACCShootSameStickerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.stickerType == AWEInteractionStickerTypeComment) {
            ACCVideoCommentModel *videoCommentModel = [ACCVideoCommentModel createModelFromJSON:obj.stickerModelStr];
            param[@"reply_comment_id"] = videoCommentModel.commentId;
            param[@"reply_user_id"] = videoCommentModel.userId;
            *stop = YES;
        }
    }];
    return [param copy];
}


- (BOOL)supportMusicLyricSticker
{
    ACCRepoDuetModel *duetModel = [self.repository extensionModelOfClass:ACCRepoDuetModel.class];
    ACCRepoUploadInfomationModel *uploadModel = [self.repository extensionModelOfClass:ACCRepoUploadInfomationModel.class];
    NSAssert(duetModel, @"extension model should not be nil");
    NSAssert(uploadModel, @"extension model should not be nil");

    AWERepoMusicModel *musicModel = [self.repository extensionModelOfClass:[AWERepoMusicModel class]];

    if (musicModel.disableMusicModule) {
        return NO;
    }

    if (duetModel.isDuet) {
        return NO;
    }
    
    if (!ACCConfigBool(kConfigBool_enable_new_clips) && uploadModel.isAIVideoClipMode) {
        return NO;
    }
    
    return YES;
}

- (void)syncWishDirectTitles
{
    NSArray<NSString *> *wishTitles = ACCConfigArray(kConfigArray_new_year_recommend_wish);
    NSMutableArray<ACCTextStickerRecommendItem *> *items = [[NSMutableArray alloc] init];
    [wishTitles acc_forEach:^(NSString *obj) {
        ACCTextStickerRecommendItem *item = [[ACCTextStickerRecommendItem alloc] init];
        item.content = obj;
        [items acc_addObject:item];
    }];
    self.directTitles = [items copy];
}

- (BOOL)containsStickerType:(AWEInteractionStickerType)stickerType
{
    __block BOOL result = NO;
    [self.shootSameStickerModels enumerateObjectsUsingBlock:^(ACCShootSameStickerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.stickerType == stickerType) {
            result = YES;
            *stop = YES;
        }
    }];
    return result;
}


- (NSDictionary *)textStickerTrackInfo
{
    NSMutableDictionary *param = [@{
        @"is_text_reading" : self.textReadingAssets.count > 0 ? @1 : @0,
        @"text_added" : @(self.hasTextAdded)
    } mutableCopy];
    if (self.textReadingAssets.count > 0) {
        NSMutableArray *toneList = [NSMutableArray array];
        AWERepoVideoInfoModel *videoInfoModel = [self.repository extensionModelOfClass:AWERepoVideoInfoModel.class];
        if (videoInfoModel == nil) {
            return [param copy];
        }
        [videoInfoModel.video.infoStickers enumerateObjectsUsingBlock:^(IESInfoSticker * _Nonnull infoSticker, NSUInteger idx, BOOL * _Nonnull stop) {
            id textInfoObject = [infoSticker.userinfo objectForKey:kACCTextInfoModelKey];
            NSData *textInfoData = nil;
            if ([textInfoObject isKindOfClass:[NSData class]]) {
                textInfoData = (NSData *)textInfoObject;
            }
            if (textInfoData == nil) {
                return;
            }
            NSError *error = nil;
            NSDictionary *textInfoDict = [NSJSONSerialization JSONObjectWithData:textInfoData options:0 error:&error] ?: nil;
            if (error || textInfoDict == nil) {
                AWELogToolError2(@"textReaderTrack", AWELogToolTagEdit, @"textStickerTextReaderTrackInfo get textInfo failed: %@", error);
                return;
            }
            error = nil;
            AWEStoryTextImageModel *textInfo = [MTLJSONAdapter modelOfClass:[AWEStoryTextImageModel class] fromJSONDictionary:textInfoDict error:&error];
            if (error || textInfo == nil) {
                AWELogToolError2(@"textReaderTrack", AWELogToolTagEdit, @"textStickerTextReaderTrackInfo modeled textInfo failed: %@", error);
                return;
            }
            if (!textInfo.readModel.useTextRead || !textInfo.readModel.soundEffect) {
                return;
            }
            [toneList acc_addObject:textInfo.readModel.soundEffect];
        }];
        if (ACC_isEmptyArray(toneList)) {
            return [param copy];
        }
        [param setValue:[toneList componentsJoinedByString:@","] forKey:@"tone_list"];
    }
    return [param copy];
}

- (id)copyWithZone:(NSZone *)zone {
    AWERepoStickerModel *model = [super copyWithZone:zone];
    model.videoShareInfo = [self.videoShareInfo copy];
    model.dateTextStickerContent = self.dateTextStickerContent;
    model.textImage = self.textImage;
    model.currentLyricStickerID = self.currentLyricStickerID;//用于歌词贴纸按钮点击埋点
    model.textReadingURLs = self.textReadingURLs;
    model.interactionStickersString = self.interactionStickersString;
    model.interactionImgPath = self.interactionImgPath;
    model.interactionProps = self.interactionProps;
    model.pollImgPath = self.pollImgPath;
    model.infoStickersJson = self.infoStickersJson;
    model.adjustTo9V16EditFrame = self.adjustTo9V16EditFrame;
    model.videoReplyModel = [self.videoReplyModel copy];
    model.videoReplyCommentModel = [self.videoReplyCommentModel copy];
    // groot贴纸
    model.grootModelResult = self.grootModelResult;
    model.recorderGrootModelResult = self.recorderGrootModelResult;
    model.appliedAutoSocialStickerInAlbumMode = self.appliedAutoSocialStickerInAlbumMode;
    model.recorderInteractionStickers = self.recorderInteractionStickers;
    model.recordStickerPlayerFrame = self.recordStickerPlayerFrame;
    model.shouldRecoverRecordStickers = self.shouldRecoverRecordStickers;
    
    if (self.stickerShootSameEffectModel != nil) {
        NSError *error = nil;
        NSDictionary *parameter = [MTLJSONAdapter JSONDictionaryFromModel:self.stickerShootSameEffectModel error:&error];
        if (error) {
            AWELogToolError(AWELogToolTagDraft, @"%s %@", __PRETTY_FUNCTION__, error);
        } else if (parameter) {
            NSError *convertError = nil;
            model.stickerShootSameEffectModel = [MTLJSONAdapter modelOfClass:[IESEffectModel class] fromJSONDictionary:parameter error:&convertError];
            if (convertError) {
                AWELogToolError(AWELogToolTagDraft, @"%s %@", __PRETTY_FUNCTION__, convertError);
            }
        }
    }
    model.shootSameStickerModels = [NSMutableArray array];
    for (ACCShootSameStickerModel *shootSameStickerModel in self.shootSameStickerModels) {
        [model.shootSameStickerModels acc_addObject:[shootSameStickerModel copy]];
    }
    model.stickerConfigAssembler = self.stickerConfigAssembler;
    model.assetCreationDate = self.assetCreationDate;
    return model;
}

- (NSDictionary *)socialStickerTrackInfoDic {
    
    __block NSInteger mentionStickerCount = 0;
    __block NSInteger hashTagStickerCount = 0;
    [self.interactionStickers enumerateObjectsUsingBlock:^(AWEInteractionStickerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.type == AWEInteractionStickerTypeMention) {
            mentionStickerCount ++;
        } else if (obj.type == AWEInteractionStickerTypeHashtag) {
            hashTagStickerCount ++;
        }
    }];
    
    return @{
        @"at_prop_cnt":@(mentionStickerCount),
        @"tag_prop_cnt":@(hashTagStickerCount)
    };
}

- (NSMutableArray<ACCShootSameStickerModel *> *)shootSameStickerModels
{
    if (!_shootSameStickerModels) {
        _shootSameStickerModels = [NSMutableArray array];
    }
    return _shootSameStickerModels;
}

- (NSArray *)infoStickerChallengeNames {
    // info sticker
    NSMutableArray *challenges = @[].mutableCopy;
    for (AWEInfoStickerInfo *info in self.infoStickerArray) {
        if (info.challengeName.length && ![challenges containsObject:info.challengeName]) {
            [challenges addObject:info.challengeName];
        }
    }
    return challenges.copy;
}

- (NSArray *)infoStickerChallengeIDs {
    // info sticker
    NSMutableArray *challenges = @[].mutableCopy;
    for (AWEInfoStickerInfo *info in self.infoStickerArray) {
        if (info.challengeID.length && ![challenges containsObject:info.challengeID]) {
            [challenges addObject:info.challengeID];
        }
    }
    return challenges.copy;
}

/// this method will be called while app going to edit view (e.g. from AWEStudioClipOutputAdapter (album) to edit view)
/// @param model new model, which is an empty model and does not contain any info. You need to update it here and assign properties to it.
/// @param origin old model
- (void)willEnterEditPageFromClipPage:(AWEVideoPublishViewModel *)model
                 originalPublishModel:(AWEVideoPublishViewModel *)origin
{
    if (self.stickerShootSameEffectModel != nil) {
        NSError *error = nil;
        NSDictionary *parameter = [MTLJSONAdapter JSONDictionaryFromModel:self.stickerShootSameEffectModel error:&error];
        if (error) {
            AWELogToolError(AWELogToolTagDraft, @"%s %@", __PRETTY_FUNCTION__, error);
        } else if (parameter) {
            NSError *convertError = nil;
            AWERepoStickerModel *repoStickerModel = [model extensionModelOfClass:[AWERepoStickerModel class]];
            repoStickerModel.stickerShootSameEffectModel = [MTLJSONAdapter modelOfClass:[IESEffectModel class] fromJSONDictionary:parameter error:&convertError];
            if (convertError) {
                AWELogToolError(AWELogToolTagDraft, @"%s %@", __PRETTY_FUNCTION__, convertError);
            }
        }
    }
    AWERepoStickerModel *repoStickerModel = [model extensionModelOfClass:[AWERepoStickerModel class]];
    repoStickerModel.shootSameStickerModels = [self.shootSameStickerModels mutableCopy];
    repoStickerModel.videoReplyModel = [self.videoReplyModel copy];
    repoStickerModel.videoReplyCommentModel = [self.videoReplyCommentModel copy];
    repoStickerModel.recorderInteractionStickers = [self.recorderInteractionStickers copy];
    repoStickerModel.recordStickerPlayerFrame = self.recordStickerPlayerFrame;
    repoStickerModel.shouldRecoverRecordStickers = self.shouldRecoverRecordStickers;
}

- (NSDictionary *)acc_referExtraParams
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    if (self.stickerShootSameEffectModel != nil) {
        mutableDict[@"has_daily_sticker"] = @(1);
    }
    AWERepoVideoInfoModel *videoInfoModel = [self.repository extensionModelOfClass:[AWERepoVideoInfoModel class]];
    if ([videoInfoModel.video.infoStickers acc_match:^BOOL(IESInfoSticker * _Nonnull item) {
        return item.acc_stickerType == ACCEditEmbeddedStickerTypeDaily;
    }]) {
        mutableDict[@"has_daily_sticker"] = @(1);
    };
    
    // 从拍摄页开始带上的贴纸
    if (!ACC_isEmptyArray(self.shootSameStickerModels)) {
        [self.shootSameStickerModels enumerateObjectsUsingBlock:^(ACCShootSameStickerModel * _Nonnull shootSameStickerModel, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!ACC_isEmptyDictionary(shootSameStickerModel.referExtraParams)) {
                [mutableDict addEntriesFromDictionary:shootSameStickerModel.referExtraParams];
            }
            if (shootSameStickerModel.stickerType == AWEInteractionStickerTypeComment) {
                mutableDict[@"reply_object"] =  @"comment";
                if (shootSameStickerModel.isDeleted) {
                    mutableDict[@"is_retain_sticker"] = @(0);
                } else {
                    mutableDict[@"is_retain_sticker"] = @(1);
                }
            }
        }];
    }
    
    if (self.videoReplyModel != nil) {
        mutableDict[@"reply_object"] =  @"video";
        
        if (self.videoReplyModel.isDeleted) {
            mutableDict[@"is_retain_sticker"] = @(0);;
        } else {
            mutableDict[@"is_retain_sticker"] = @(1);;
        }
    }
    
    if (ACC_isEmptyDictionary(mutableDict)) {
        return nil;
    } else {
        return [mutableDict copy];
    }
}

@end
