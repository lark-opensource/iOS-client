//
//  AWERecordInformationRepoModel+ACCRepositoryRequestParamsProtocol.m
//  CameraClient-Pods-Aweme
//
//  Created by Howie He on 2021/3/26.
//

#import "AWERepoStickerModel.h"
#import "AWERepoCaptionModel.h"
#import "AWERecordInformationRepoModel+ACCRepositoryRequestParamsProtocol.h"
#import <CreationKitArch/AWEColorFilterDataManager.h>
#import "AWEInteractionPOIStickerModel.h"
#import <CreationKitArch/ACCRepoFilterModel.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreationKitArch/AWEEffectFilterDataManager.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <CreationKitArch/ACCRepoPropModel.h>
#import <CameraClient/ACCRepoRecorderTrackerToolModel.h>
#import <CameraClient/AWERepoContextModel.h>
#import <CreationKitArch/HTSVideoSepcialEffect.h>
#import <CreationKitArch/ACCRepoCutSameModel.h>
#import <CreationKitArch/ACCRepoStickerModel.h>
#import <CreationKitArch/ACCRepoPublishConfigModel.h>
#import <CameraClient/ACCRepoImageAlbumInfoModel.h>
#import <CameraClient/AWEStudioDefines.h>
#import <CameraClient/AWEInteractionMentionStickerModel.h>
#import <CameraClient/AWEInteractionHashtagStickerModel.h>
#import <CameraClient/AWEInteractionVideoReplyCommentStickerModel.h>
#import <CreativeKit/ACCMacros.h>
#import <CameraClient/AWEInteractionVideoShareStickerModel.h>
#import <CameraClient/ACCImageAlbumData.h>
#import <CreationKitArch/ACCEditAndPublishConstants.h>
#import <CreationKitArch/HTSVideoDefines.h>
#import <CreationKitArch/AWECoverTextModel.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "AWERepoPropModel.h"
#import "AWERepoMusicModel.h"
#import <CreationKitArch/ACCVideoDataProtocol.h>
#import <CameraClientModel/ACCVideoCommentModel.h>
#import "AWEInteractionEditTagStickerModel.h"
#import <CameraClientModel/ACCVideoCanvasType.h>

@implementation AWERecordInformationRepoModel (ACCRepositoryRequestParamsProtocol)

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
    
    __block NSInteger activityType = 0;
    __block NSNumber* greenScreen = @0;
    __block BOOL strAppendFirst = YES;
    __block NSMutableString *gradePropList = [[NSMutableString alloc] init];
    __block NSString *welfareActivityID = nil;
    NSArray<AWEVideoFragmentInfo *> *videoFragmentInfo = self.fragmentInfo.copy;
    NSMutableArray *cameraPositions = @[].mutableCopy;
    NSMutableArray *prettify = @[].mutableCopy;
    NSMutableArray *filters = @[].mutableCopy;
    NSMutableArray *filterIDs = @[].mutableCopy;
    NSMutableArray *effects = @[].mutableCopy;
    NSMutableArray *effectIds = @[].mutableCopy;
    NSMutableArray *stickers = @[].mutableCopy;
    NSMutableArray *speedArray = @[].mutableCopy;
    NSMutableArray *useDelayRecordArray = @[].mutableCopy;
    NSMutableArray *useStabilizationArray = @[].mutableCopy;
    NSMutableArray *smooths = @[].mutableCopy;
    NSMutableArray *shapes = @[].mutableCopy;
    NSMutableArray *eyes = @[].mutableCopy;
    NSMutableArray *activityTimerange = @[].mutableCopy;
    NSMutableArray *recordModes = @[].mutableCopy;
    NSMutableArray *backgrounds = @[].mutableCopy;
    NSMutableArray *arTextArray = @[].mutableCopy;
    NSMutableArray *stickerTextArray = @[].mutableCopy;
    NSMutableArray *delayRecordModeArray = @[].mutableCopy;
    NSMutableArray *stickerMatchIdArray = @[].mutableCopy;
    
    NSDictionary *speedMap = @{@(HTSVideoSpeedVerySlow):@"1",
                               @(HTSVideoSpeedSlow):@"2",
                               @(HTSVideoSpeedNormal):@"3",
                               @(HTSVideoSpeedFast):@"4",
                               @(HTSVideoSpeedVeryFast):@"5",};
    
    [videoFragmentInfo enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [delayRecordModeArray acc_addObject:@(obj.delayRecordModeType)];
        
        if (strAppendFirst) {
            if (([obj.stickerId length] != 0) && ([obj.stickerGradeKey length] != 0)) {
                [gradePropList appendString:[NSString stringWithFormat:@"%@:%@",obj.stickerId,obj.stickerGradeKey]];
                strAppendFirst = NO;
            }
        } else {
            if (([obj.stickerId length] != 0) && ([obj.stickerGradeKey length] != 0)) {
                [gradePropList appendString:[NSString stringWithFormat:@",%@:%@",obj.stickerId,obj.stickerGradeKey]];
            }
        }
        
        // Green screen image & video
        if (![obj.pic2VideoSource isEqualToString:@"none"]) {
            greenScreen = @1;
        }
        if (obj.stickerVideoAssetURL != nil) {
            greenScreen = @1;
        }
        
        [cameraPositions acc_addObject:obj.cameraPosition == AVCaptureDevicePositionFront?@"1":@"0"];
        [prettify acc_addObject:obj.beautify?@"1":@"0"];
        
        NSString *name = [AWEColorFilterDataManager effectWithID:obj.colorFilterId].pinyinName;
        
        if (name) {
            [filters acc_addObject:name];
        }
        
        if (obj.colorFilterId.length > 0) {
            [filterIDs acc_addObject:obj.colorFilterId];
        }
        
        if (obj.stickerId.length > 0) {
            [stickers acc_addObject:obj.stickerId];
        }
        
        if (obj.background.length > 0) {
            [backgrounds acc_addObject:obj.background];
        }
        
        if (obj.recordMode.length > 0) {
            [recordModes acc_addObject:obj.recordMode];
        }
        
        if (speedMap[@(obj.speed)]) {
            [speedArray acc_addObject:speedMap[@(obj.speed)]];
        }
        
        [smooths acc_addObject:@(obj.smooth)];
        
        if (obj.reshape > 0) {
            [eyes acc_addObject:@(obj.reshape)];
            [shapes acc_addObject:@(obj.reshape)];
        } else {
            [eyes acc_addObject:@(obj.eye)];
            if (obj.shape >= 0) {
                [shapes acc_addObject:@(obj.shape)];
            }
        }
        [useDelayRecordArray acc_addObject:(obj.delayRecordModeType > 0 ? @"1" : @"0")];
        [useStabilizationArray acc_addObject:(obj.useStabilization ? @"1" : @"0")];
        
        if (obj.activityTimerange.count) {
            for (AWETimeRange *timeRange in obj.activityTimerange) {
                if (timeRange.duration.doubleValue > 0) {
                    [activityTimerange acc_addObject:timeRange];
                    if (obj.activityType != 0) {
                        
                        activityType = obj.activityType;
                    }
                }
            }
        }
        
        if (obj.arTextArray.count) {
            for (NSString *arText in obj.arTextArray) {
                if (!ACC_isEmptyString(arText)) {
                    [arTextArray acc_addObject:arText];
                }
            }
        }
        
        if (obj.stickerTextArray.count) {
            for (NSString *stickerText in obj.stickerTextArray) {
                if (!ACC_isEmptyString(stickerText)) {
                    [stickerTextArray acc_addObject:stickerText];
                }
            }
        }

        if (welfareActivityID == nil && obj.welfareActivityID != nil) {
            welfareActivityID = obj.welfareActivityID;
        }
        
        if(obj.stickerMatchId.length > 0){
          [stickerMatchIdArray acc_addObject:obj.stickerMatchId];
        }
    }];
    
    AWERepoContextModel *contextModel = [self.repository extensionModelOfClass:AWERepoContextModel.class];
    if (contextModel.isQuickStoryPictureVideoType && self.pictureToVideoInfo != nil) {
        if (self.pictureToVideoInfo.arTextArray.count) {
            for (NSString *arText in self.pictureToVideoInfo.arTextArray) {
                if (!ACC_isEmptyString(arText)) {
                    [arTextArray acc_addObject:arText];
                }
            }
        }

        if (self.pictureToVideoInfo.stickerTextArray.count) {
            for (NSString *stickerText in self.pictureToVideoInfo.stickerTextArray) {
                if (!ACC_isEmptyString(stickerText)) {
                    [stickerTextArray acc_addObject:stickerText];
                }
            }
        }

        if (!ACC_isEmptyString(self.pictureToVideoInfo.welfareActivityID)) {
            welfareActivityID = self.pictureToVideoInfo.welfareActivityID;
        }
    }
    // if video fragment count equal to 0, should extract information frome publishModel
    ACCRepoFilterModel *filterModel = [self.repository extensionModelOfClass:ACCRepoFilterModel.class];
    if (videoFragmentInfo.count == 0) {
        if (!ACC_isEmptyString(filterModel.colorFilterId)) {
            [filterIDs acc_addObject:filterModel.colorFilterId];
        }
        NSString *name = [AWEColorFilterDataManager effectWithID:filterModel.colorFilterId].pinyinName;
        if (!ACC_isEmptyString(name)) {
            [filters acc_addObject:name];
        }
    }
    
    id<ACCVideoDataProtocol> videoData = [self.repository extensionModelOfProtocol:@protocol(ACCVideoDataProtocol)];
    [videoData.effect_timeRange enumerateObjectsUsingBlock:^(IESMMEffectTimeRange * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *name = [[AWEEffectFilterDataManager defaultManager] effectWithID:obj.effectPathId].effectName;
        if (name) {
            [effects acc_addObject:name];
        }
        if (obj.effectPathId) {
            [effectIds acc_addObject:obj.effectPathId];
        }
    }];
    
    NSString *timeEffectName = [HTSVideoSepcialEffect effectWithType:videoData.effect_timeMachineType].name;
    if (timeEffectName) {
        [effects acc_addObject:timeEffectName];
    }
    [effectIds acc_addObject:@(videoData.effect_timeMachineType)];
    
    NSError *error = nil;
    resultDict[@"activity_timerange"] = [MTLJSONAdapter JSONArrayFromModels:activityTimerange error:&error];
    if (error) {
        AWELogToolError(AWELogToolTagPublish, @"%s %@", __PRETTY_FUNCTION__, error);
    }
    
    //
    // 如果拍摄 fragment 为空，添加开拍前应用的道具id
    // 拍照或者拍摄小于 1s 的视频，还没有生成 fragment，此时也要记录应用的道具 id
    //
    if (videoFragmentInfo.count == 0 && contextModel.isRecord && !contextModel.isAudioRecord) {
        AWERepoPropModel *stickerModel = [self.repository extensionModelOfClass:AWERepoPropModel.class];
        if (stickerModel.propId.length > 0) {
            [stickers acc_addObject:stickerModel.propId];
        }
    }
    if (contextModel.isAudioRecord) {
        [stickers removeAllObjects];
    }
    
    resultDict[@"filter_name"] = [filters componentsJoinedByString:@","];
    resultDict[@"filter_id"] = [filterIDs componentsJoinedByString:@","];
    resultDict[@"camera"] = [cameraPositions componentsJoinedByString:@","];
    resultDict[@"prettify"] = [prettify componentsJoinedByString:@","];
    resultDict[@"fx_name"] = [effects componentsJoinedByString:@","];
    resultDict[@"effect_id"] = [effectIds componentsJoinedByString:@","];
    resultDict[@"stickers"] = [stickers componentsJoinedByString:@","];
    resultDict[@"speed"] = [speedArray componentsJoinedByString:@","];
    resultDict[@"anti_shake"] = [useStabilizationArray componentsJoinedByString:@","];
    resultDict[@"use_countdown"] = [useDelayRecordArray componentsJoinedByString:@","];
    resultDict[@"smooth"] = [smooths componentsJoinedByString:@","];
    resultDict[@"shape"] = [shapes componentsJoinedByString:@","];
    resultDict[@"eye"] = [eyes componentsJoinedByString:@","];
    resultDict[@"background"] = [backgrounds componentsJoinedByString:@","];
    resultDict[@"record_mode"] = [recordModes componentsJoinedByString:@","];
    resultDict[@"countdown_list"] = [delayRecordModeArray componentsJoinedByString:@","] ? : @"";
    resultDict[@"activity_type"] = @(activityType);
    if (greenScreen.integerValue > 0) {
        resultDict[@"green_screen"] = greenScreen;
    }
    resultDict[@"grade_prop_list"] = [gradePropList copy];
    resultDict[@"ar_text"] = [arTextArray btd_safeJsonStringEncoded];
    
    if (stickerMatchIdArray.count > 0) {
        resultDict[@"sticker_match_id"] = [stickerMatchIdArray componentsJoinedByString:@","];
    }
    
    ACCRepoRecorderTrackerToolModel *recorderTrackerToolModel = [self.repository extensionModelOfClass:ACCRepoRecorderTrackerToolModel.class];
    if (welfareActivityID != nil) {
        resultDict[@"welfare_activity_id"] = welfareActivityID;
        recorderTrackerToolModel.publishWelfareActivityID = welfareActivityID;
    }
    
    NSMutableArray *stickerTextDictArray = @[].mutableCopy;
    if (stickerTextArray.count) {//message bubble
        [stickerTextDictArray acc_addObject:@{@"type": @(AWEVideoPublisherTextTypeBubbleMessage), @"data": stickerTextArray}];
    }
    NSMutableArray *mentionStickers = [NSMutableArray array];
    NSMutableArray *hashtagStickers = [NSMutableArray array];
    AWERepoStickerModel *stickerModel = [self.repository extensionModelOfClass:AWERepoStickerModel.class];
    [stickerModel.interactionStickers enumerateObjectsUsingBlock:^(AWEInteractionStickerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.type == AWEInteractionStickerTypePoll) {//vote sticker
            NSMutableArray *optionArr = [NSMutableArray array];
            [obj.voteInfo.options enumerateObjectsUsingBlock:^(AWEInteractionVoteStickerOptionsModel * _Nonnull obj_op, NSUInteger idx_op, BOOL * _Nonnull stop_op) {
                [optionArr btd_addObject:obj_op.optionText?:@""];
            }];
            NSDictionary *dataDic = @{ @"question" : obj.voteInfo.question?:@"",
                                       @"options"  : optionArr?:@[] };
            [stickerTextDictArray acc_addObject:@{@"type": @(AWEInteractionStickerTypePoll), @"data": dataDic}];
        } else if (obj.type == AWEInteractionStickerTypeMention) {
            AWEInteractionMentionStickerModel *mentionSticker = ([obj isKindOfClass:[AWEInteractionMentionStickerModel class]]) ? (AWEInteractionMentionStickerModel *)obj : nil;
            NSString *username = (NSString *)mentionSticker.mentionedUserInfo[@"text_content"];
            if (!ACC_isEmptyString(username)) {
                [mentionStickers acc_addObject:username];
            }
            mentionSticker.mentionedUserInfo = [mentionSticker.mentionedUserInfo mtl_dictionaryByRemovingValuesForKeys:@[@"text_content"]];
        } else if (obj.type == AWEInteractionStickerTypeHashtag) {
            AWEInteractionHashtagStickerModel *hashtagSticker = ([obj isKindOfClass:[AWEInteractionHashtagStickerModel class]]) ? (AWEInteractionHashtagStickerModel *)obj : nil;
            NSString *hashtagName = (NSString *)hashtagSticker.hashtagInfo[@"hashtag_name"];
            if (!ACC_isEmptyString(hashtagName)) {
                [hashtagStickers acc_addObject:hashtagName];
            }
        } else if ([obj isKindOfClass:[AWEInteractionPOIStickerModel class]]) {
            AWEInteractionPOIStickerModel *poiStickerModel = (AWEInteractionPOIStickerModel *)obj;
            poiStickerModel.poiStyleInfo = nil;
        } else if (obj.type == AWEInteractionStickerTypeVideoReplyComment) {
            AWEInteractionVideoReplyCommentStickerModel *videoReplyCommentModel = ([obj isKindOfClass:[AWEInteractionVideoReplyCommentStickerModel class]]) ? (AWEInteractionVideoReplyCommentStickerModel *)obj : nil;
            if (!ACC_isEmptyString(videoReplyCommentModel.videoReplyCommentInfo.commentText)) {
                [stickerTextDictArray acc_addObject:@{
                    @"type": @(AWEVideoPublisherTextTypeCommentSticker),
                    @"data": @[videoReplyCommentModel.videoReplyCommentInfo.commentText ?: @""],
                }];
            }
        }
    }];
    if (!ACC_isEmptyArray(mentionStickers)) {
        [stickerTextDictArray acc_addObject:@{
            @"type" : @(AWEVideoPublisherTextTypeMentionSticker),
            @"data" : mentionStickers,
        }];
    }
    if (!ACC_isEmptyArray(hashtagStickers)) {
        [stickerTextDictArray acc_addObject:@{
            @"type" : @(AWEVideoPublisherTextTypeHashtagSticker),
            @"data" : hashtagStickers,
        }];
    }
    
    if (!ACC_isEmptyString(publishViewModel.repoSticker.videoShareInfo.authorName)) {
        [stickerTextDictArray acc_addObject:@{
            @"type" : @(AWEVideoPublisherTextTypeText),
            @"data" : @[publishViewModel.repoSticker.videoShareInfo.authorName],
        }];
    }
    
    // 分享评论到日常评论信息：评论者名字和评论内容
    if (!ACC_isEmptyString(publishViewModel.repoSticker.videoShareInfo.commentUserNickname) &&
        !ACC_isEmptyString(publishViewModel.repoSticker.videoShareInfo.commentContent)) {
        [stickerTextDictArray acc_addObject:@{
            @"type" : @(AWEVideoPublisherTextTypeShareCommentToStoryCommentInfo),
            @"data" : @[publishViewModel.repoSticker.videoShareInfo.commentUserNickname, publishViewModel.repoSticker.videoShareInfo.commentContent],
        }];
    }
    
    if (publishViewModel.repoVideoInfo.canvasType == ACCVideoCanvasTypeMusicStory) {

        [stickerTextDictArray addObject:@{
            @"type" : @(AWEVideoPublisherTextTypeMusicStoryCoverText),
            @"data" : @[
                    publishViewModel.repoMusic.music.musicName ?:@"",
                    publishViewModel.repoMusic.music.authorName ?:@""
            ],
        }];
    }
    
    BOOL isImageAlbum = publishViewModel.repoImageAlbumInfo.isImageAlbumEdit;
    
    if (!ACC_isEmptyString(stickerModel.imageText) && !isImageAlbum) { // 图集文字贴纸使用type 13送审
        NSData *textData = [stickerModel.imageText dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *textArray = nil;
        NSError *jsonError = nil;
        if (textData) {
            textArray = [NSJSONSerialization JSONObjectWithData:textData options:0 error:&jsonError];
        }
        
        if (jsonError) {
            AWELogToolError(AWELogToolTagPublish, @"%s %@", __PRETTY_FUNCTION__, jsonError);
        } else if (!ACC_isEmptyArray(textArray)) {
            [stickerTextDictArray acc_addObject:@{@"type": @(AWEVideoPublisherTextTypeText), @"data": textArray}];
        }
    }
    
    for (ACCShootSameStickerModel *shootSameStickerModel in stickerModel.shootSameStickerModels) {
        if (shootSameStickerModel.stickerType == AWEInteractionStickerTypeComment) {
            ACCVideoCommentModel *videoCommentModel = [ACCVideoCommentModel createModelFromJSON:shootSameStickerModel.stickerModelStr];
            if (!ACC_isEmptyString(videoCommentModel.commentMsg)) {
                [stickerTextDictArray btd_addObject:@{@"type": @(AWEVideoPublisherTextTypeCommentSticker), @"data": @[videoCommentModel.commentMsg]}];
            }
        }
    }
    
    AWERepoCaptionModel *captionModel = [publishViewModel extensionModelOfClass:AWERepoCaptionModel.class];
    
    NSString *captionCheck = [captionModel captionWordsForCheck];
    if (captionCheck.length) {
        [stickerTextDictArray acc_addObject:@{@"type": @(AWEVideoPublisherTextTypeCaption), @"data": @[captionCheck]}];
    }
    
    ACCRepoCutSameModel *cutSameModel = [self.repository extensionModelOfClass:ACCRepoCutSameModel.class];
    if (cutSameModel.cutSameEditedTexts.count) {
        [stickerTextDictArray acc_addObject:@{@"type": @(AWEVideoPublisherTextTypeCutSame), @"data" : cutSameModel.cutSameEditedTexts}];
    }
    
    ACCRepoPublishConfigModel *publishConfigModel = [self.repository extensionModelOfClass:ACCRepoPublishConfigModel.class];
    if (publishConfigModel.coverTextModel && !ACC_isEmptyArray(publishConfigModel.coverTextModel.texts)) {
        [stickerTextDictArray acc_addObject:@{@"type" : @(AWEVideoPublisherTextTypeCoverText), @"data" : publishConfigModel.coverTextModel.texts}];
    }
    
    if (isImageAlbum) {
        NSMutableArray *tagsArray = [NSMutableArray array];
        NSMutableArray *allImageData = [[NSMutableArray alloc] init];
        [publishViewModel.repoImageAlbumInfo.imageAlbumData.imageAlbumItems enumerateObjectsUsingBlock:^(ACCImageAlbumItemModel * _Nonnull obj, NSUInteger imageIdx, BOOL * _Nonnull stop) {
            NSMutableArray *oneImageStickers = [[NSMutableArray alloc] init];
            NSMutableArray *oneImageTags = [[NSMutableArray alloc] init];

            [[obj.stickerInfo.interactionStickers acc_filter:^BOOL(AWEInteractionStickerModel * _Nonnull item) {
                return [item isKindOfClass:[AWEInteractionEditTagStickerModel class]];
            }] enumerateObjectsUsingBlock:^(AWEInteractionEditTagStickerModel * _Nonnull oneSticker, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *tagString = @"自定义";
                if (oneSticker.editTagInfo.type == ACCEditTagTypeUser) {
                    tagString = @"用户";
                } else if (oneSticker.editTagInfo.type == ACCEditTagTypePOI) {
                    tagString = @"POI";
                } else if (oneSticker.editTagInfo.type == ACCEditTagTypeCommodity) {
                    tagString = @"商品";
                } else if (oneSticker.editTagInfo.type == ACCEditTagTypeBrand) {
                    tagString = @"品牌";
                } else if (oneSticker.editTagInfo.type == ACCEditTagTypeSelfDefine) {
                    tagString = @"自定义";
                }
                [oneImageTags acc_addObject:@{
                    @"text": oneSticker.editTagInfo.text?:@"",
                    @"tag_type": tagString?:@""}];
            }];
            if (oneImageTags.count > 0) {
                NSMutableDictionary *oneImageDict = [[NSMutableDictionary alloc] init];
                oneImageDict[@"index"] = @(imageIdx);
                oneImageDict[@"content"] = oneImageTags;
                
                [tagsArray acc_addObject:oneImageDict];
            }

            [obj.stickerInfo.stickers enumerateObjectsUsingBlock:^(ACCImageAlbumStickerModel * _Nonnull oneSticker, NSUInteger idx, BOOL * _Nonnull stop) {
                NSData *textInfoData = ACCDynamicCast([oneSticker.userInfo objectForKey:kACCTextInfoModelKey], NSData);
                if (textInfoData) {
                    NSDictionary *textInfoDict = [NSJSONSerialization JSONObjectWithData:textInfoData options:0 error:nil];
                    if (textInfoDict) {
                        AWEStoryTextImageModel *textInfo = [MTLJSONAdapter modelOfClass:[AWEStoryTextImageModel class] fromJSONDictionary:textInfoDict error:nil];
                        if (textInfo.content.length) {
                            [oneImageStickers acc_addObject:textInfo.content];
                        }
                    }
                }
            }];
            
            if (oneImageStickers.count) {
                NSMutableDictionary *oneImageDict = [[NSMutableDictionary alloc] init];
                oneImageDict[@"index"] = @(imageIdx);
                oneImageDict[@"content"] = oneImageStickers;
                
                [allImageData acc_addObject:oneImageDict];
            }
        }];
        
        if (tagsArray.count > 0) {
            [stickerTextDictArray acc_addObject:@{@"type" : @(AWEVideoPublisherTextTypeTags),
                                                  @"data" : tagsArray}];
        }

        if (allImageData.count) {
            [stickerTextDictArray acc_addObject:@{@"type" : @(AWEVideoPublisherTextTypeAlbumImageSticker),
                                              @"data" : allImageData}];
        }
    }
    
    // 文字送审逻辑参考 https://bytedance.feishu.cn/docs/doccnk4uDCQWWg7h234br88RkAe
    if ([stickerTextDictArray count]) {
        resultDict[@"sticker_text"] = [self p_jsonStringEncoded:stickerTextDictArray];
    }
    
    return [resultDict copy];
}

- (NSString *)p_jsonStringEncoded:(id)obj {
    if ([NSJSONSerialization isValidJSONObject:obj]) {
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:kNilOptions error:&error];
        if (error) {
            AWELogToolError(AWELogToolTagNone, @"%s %@", __PRETTY_FUNCTION__, error);
        }
        NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return json;
    }
    return nil;
}

@end
