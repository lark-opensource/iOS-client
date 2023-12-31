//
//  AWERepoTrackModel.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/14.
//

#import "AWERepoCutSameModel.h"
#import <CreationKitArch/ACCRepoFlowControlModel.h>

#import <ByteDanceKit/NSArray+BTDAdditions.h>

#import "AWERepoContextModel.h"
#import <CreationKitArch/HTSVideoDefines.h>
#import <CreativeKit/ACCMacros.h>
#import "AWERepoTrackModel.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCPerformanceUtilsProtocol.h>
#import "ACCRepoTextModeModel.h"
#import "ACCRepoMissionModelProtocol.h"
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitArch/ACCRepoChallengeModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import "AWERepoPropModel.h"
#import <CreationKitArch/ACCRepoReshootModel.h>
#import "ACCRepoTextModeModel.h"
#import "ACCRepoQuickStoryModel.h"
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <TTVideoEditor/IESInfoSticker.h>
#import "AWERepoVideoInfoModel.h"
#import <CreationKitArch/ACCRepoStickerModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoTranscodingModel.h>
#import <CreationKitArch/ACCRepoFlowControlModel.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CameraClient/AWEInteractionStickerModel+DAddition.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreationKitArch/ACCRepoPublishConfigModel.h>
#import <CreationKitArch/ACCTextExtraProtocol.h>
#import "ACCHashTagServiceProtocol.h"
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "ACCCreativeBrightnessABUtil.h"
#import "ACCVideoPublishProtocol.h"
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CameraClient/ACCRepoKaraokeModelProtocol.h>
#import "AWEInteractionSocialTextStickerModel.h"
#import "AWEInteractionMentionStickerModel.h"
#import "AWEInteractionHashtagStickerModel.h"
#import "IESInfoSticker+ACCAdditions.h"
#import "AWERecordInformationRepoModel.h"
#import "ACCRepoImageAlbumInfoModel.h"
#import "AWERepoPublishConfigModel.h"
#import "AWERepoFlowerTrackModel.h"
#import "ACCImageAlbumData.h"
#import "ACCRecognitionTrackModel.h"
#import <CreationKitArch/AWEColorFilterDataManager.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CameraClient/AWERepoMusicModel.h>
#import <CameraClient/AWERepoMVModel.h>
#import <CreativeKit/ACCResourceBundleProtocol.h>
#import <CameraClient/ACCActivityConfigProtocol.h>
#import <CameraClient/ACCCommerceServiceProtocol.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <CameraClientModel/AWEVideoRecordButtonType.h>
#import <CameraClientModel/ACCTextExtraType.h>
#import <CameraClient/ACCRepoAudioModeModel.h>


/*
 ！！！model注入看这里！！！
 在大部分情况下，需要在AWEVideoPublishViewModel初始化的时候注入业务model，以便后续的取值/赋值
 当然也可以不使用这个能力，而使用ACCPublishRepository的setExtensionModelByClass:在合适的时机注入，这个就由各业务方根据具体情况去判断。
 */
@interface AWEVideoPublishViewModel (AWERepoTrack) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (AWERepoTrack)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
	ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:AWERepoTrackModel.class];
	return info;
}

- (AWERepoTrackModel *)repoTrack
{
    AWERepoTrackModel *trackModel = [self extensionModelOfClass:AWERepoTrackModel.class];
    NSAssert(trackModel, @"extension model should not be nil");
    return trackModel;
}

@end

@interface AWERepoTrackModel ()

@property (nonatomic, copy) NSString *shareEditFrom;

@end

@implementation AWERepoTrackModel
@synthesize repository;

- (NSString *)shareEditFrom
{
    if (!_shareEditFrom) {
        ACCRepoUploadInfomationModel *model = [self.repository extensionModelOfClass:[ACCRepoUploadInfomationModel class]];
        AWEVideoPublishSourceInfo *info = model.sourceInfos.firstObject;
        NSDictionary *jsonInfo = [info jsonInfo];
        if ([jsonInfo isKindOfClass:[NSDictionary class]]) {
            NSDictionary *data = [jsonInfo acc_dictionaryValueForKey:@"data"];
            _shareEditFrom = [data acc_stringValueForKey:@"product"];
        }
    }
    return _shareEditFrom;
}

#pragma mark - public

- (NSDictionary *)commonTrackInfoDic
{
    NSMutableDictionary *dic = @{}.mutableCopy;
    dic[@"shoot_way"] = self.referString;
    ACCRepoContextModel *context = [self.repository extensionModelOfClass:ACCRepoContextModel.class];
    dic[@"creation_id"] = context.createId;
    dic[@"creation_session_id"] = self.creationSessionId;
    return [dic copy];
}

- (NSDictionary *)performanceTrackInfoDic
{
    NSMutableDictionary *dic = @{}.mutableCopy;
    dic[@"brightness"] = @([ACCPerformanceUtils() acc_screenBrightness]);
    dic[@"origin_brightness"] = [ACCCreativeBrightnessABUtil shareBrightnessManager].currentBrightness;
    dic[@"app_ui_mode"] = [IESAutoInline(ACCBaseServiceProvider(), ACCResourceBundleProtocol) isDarkMode] ? @"dark" : @"light";
    return dic;
}

- (NSDictionary *)videoFragmentInfoDictionary
{
    NSMutableDictionary *infoDictionary = @{}.mutableCopy;
    // Only take some original code into else , no other changes
    ACCRepoUploadInfomationModel *repoUploadInfo = [self.repository extensionModelOfClass:[ACCRepoUploadInfomationModel class]];
    AWERepoVideoInfoModel *repoVideoInfo = [self.repository extensionModelOfClass:[AWERepoVideoInfoModel class]];
    ACCRepoStickerModel *repoSticker = [self.repository extensionModelOfClass:[ACCRepoStickerModel class]];
    AWERepoPropModel *repoProp = [self.repository extensionModelOfClass:[AWERepoPropModel class]];
    ACCRepoImageAlbumInfoModel *albumInfo = [self.repository extensionModelOfClass:[ACCRepoImageAlbumInfoModel class]];

    // Only take some original code into else , no other changes
    if (repoVideoInfo.fragmentInfo.count == 0) {
        infoDictionary[@"is_speed_change"] = @(repoUploadInfo.isSpeedChange); // 上传视频是否调整速度
        infoDictionary[@"prop_list"] = repoProp.propId; // Only one prop can be used when shooting photo, directly set its ID to `prop_list`.
    } else {

        NSMutableArray *stickers = @[].mutableCopy;
        NSMutableArray *propTabOrderList = @[].mutableCopy;
        NSMutableArray *propImprPosList = @[].mutableCopy;
        NSMutableArray *propRecIDs = @[].mutableCopy;
        NSMutableArray *beautifyInfo = @[].mutableCopy;
        
        NSMutableArray *filters = @[].mutableCopy;
        NSMutableArray *filterIDs = @[].mutableCopy;
        NSMutableArray *smoothList = @[].mutableCopy;
        NSMutableArray *reshapeList = @[].mutableCopy;
        __block BOOL isSpeedChange = NO;
        
        [repoVideoInfo.fragmentInfo enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if (obj.stickerId.length > 0) {
                [stickers acc_addObject:obj.stickerId];
            }
            
            if (obj.colorFilterId) {
                [filters acc_addObject:obj.colorFilterName ?: @""];
                [filterIDs acc_addObject:obj.colorFilterId ?: @""];
            }
            
            if (!HTSVideoSpeedEqual(obj.speed, HTSVideoSpeedNormal)) {
                isSpeedChange = YES;
            }

            if (obj.propIndexPath) {
                [propTabOrderList acc_addObject:@(obj.propIndexPath.section).stringValue];
                [propImprPosList acc_addObject:@(obj.propIndexPath.row + 1).stringValue];
            }
            
            if (obj.composerBeautifyInfo) {
                [beautifyInfo acc_addObject:obj.composerBeautifyInfo];
            }
            
            [propRecIDs acc_addObject: ACC_isEmptyString(obj.propRecId) ? @"0" : obj.propRecId];
            
            NSUInteger smooth = round(obj.smooth * 100.0);
            NSUInteger reshape = round(obj.reshape * 100.0);
            
            [smoothList acc_addObject:@(smooth).stringValue];
            [reshapeList acc_addObject:@(reshape).stringValue];
        }];
        
        infoDictionary[@"prop_list"] = [stickers componentsJoinedByString:@","];
        infoDictionary[@"prop_tab_order"] = [propTabOrderList componentsJoinedByString:@","];
        infoDictionary[@"prop_impr_position"] = [propImprPosList componentsJoinedByString:@","];
        infoDictionary[@"prop_rec_id"] = [propRecIDs componentsJoinedByString:@","];
        infoDictionary[@"smooth_list"] = [smoothList componentsJoinedByString:@","];
        infoDictionary[@"reshape_list"] = [reshapeList componentsJoinedByString:@","];
        infoDictionary[@"is_speed_change"] = isSpeedChange ? @"1" : @"0"; // 拍摄视频是否调整速度
        infoDictionary[@"filter_list"] = [filters componentsJoinedByString:@","];
        infoDictionary[@"filter_id_list"] = [filterIDs componentsJoinedByString:@","];
        
        // combine multiple pieces of beautify_info into one json.
        // NOTE: each video corresponds to a specific beautify_info.
        if ([NSJSONSerialization isValidJSONObject:beautifyInfo]) {
            NSError *jsonError = nil;
            NSData *beautifyInfoData = [NSJSONSerialization dataWithJSONObject:beautifyInfo options:0 error:&jsonError];
            if (jsonError) {
                AWELogToolError2(@"track", AWELogToolTagTracker, @"gen beautifyInfoData failed: %@", jsonError);
            }
            
            if (beautifyInfoData != nil) {
                infoDictionary[@"beautify_info"] = [[NSString alloc] initWithData:beautifyInfoData encoding:NSUTF8StringEncoding];
            }
        }
    }

    NSMutableArray *editEffects = @[].mutableCopy;
    [repoVideoInfo.video.effect_timeRange enumerateObjectsUsingBlock:^(IESMMEffectTimeRange * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.effectPathId) {
            [editEffects acc_addObject:obj.effectPathId];
        }
    }];
    infoDictionary[@"effect_list"] = [editEffects componentsJoinedByString:@","];
    
    NSMutableArray *infoStickers = @[].mutableCopy;
    NSMutableArray *infoStickersTab = @[].mutableCopy;
    if ([albumInfo isImageAlbumEdit]) {
        NSMutableArray *filters = @[].mutableCopy;
        NSMutableArray *filterIDs = @[].mutableCopy;
        [albumInfo.imageAlbumData.imageAlbumItems enumerateObjectsUsingBlock:^(ACCImageAlbumItemModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj.stickerInfo.stickers enumerateObjectsUsingBlock:^(ACCImageAlbumStickerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *remoteStickerID = [obj.userInfo acc_stringValueForKey:@"stickerID"];
                NSString *tabName = [obj.userInfo acc_stringValueForKey:@"tabName"];
                if (remoteStickerID) {
                    [infoStickers acc_addObject:remoteStickerID];
                    [infoStickersTab acc_addObject:tabName ? : @""];
                }
            }];
            NSString *filterId = obj.filterInfo.effectIdentifier;
            NSString *filterName = [AWEColorFilterDataManager effectWithID:filterId].pinyinName;
            if (filterId) {
                [filterIDs acc_addObject:filterId];
            }
            if (filterName) {
                [filters acc_addObject:filterName];
            }
        }];
        infoDictionary[@"filter_list"] = [filters componentsJoinedByString:@","];
        infoDictionary[@"filter_id_list"] = [filterIDs componentsJoinedByString:@","];
    }
    
    for (IESInfoSticker *infoSticker in repoVideoInfo.video.infoStickers) {
        NSString *remoteStickerID = (NSString *)infoSticker.userinfo[@"stickerID"];
        NSString *tabName = ACCDynamicCast(infoSticker.userinfo[@"tabName"], NSString);
        if (remoteStickerID && !infoSticker.acc_isNotNormalInfoSticker) {
            [infoStickers acc_addObject:remoteStickerID];
            [infoStickersTab acc_addObject:tabName ? : @""];
        }
    }
    if ([repoSticker.interactionStickers count]) {
        [repoSticker.interactionStickers enumerateObjectsUsingBlock:^(AWEInteractionStickerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!ACC_isEmptyString(obj.attr)) {
                NSData *jsonData = [obj.attr dataUsingEncoding:NSUTF8StringEncoding];
                if (jsonData) {
                    NSError *jsonError = nil;
                    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                        options:NSJSONReadingMutableContainers
                                                                          error:&jsonError];
                    if (jsonError) {
                        AWELogToolError2(@"track", AWELogToolTagTracker, @"gen interactionStickers failed: %@", jsonError);
                    }
                    
                    if (dic && [dic isKindOfClass:[NSDictionary class]]) {
                        NSString *poiStickerID = [dic acc_stringValueForKey:@"poi_sticker_id"];
                        if (!ACC_isEmptyString(poiStickerID)) {
                            if (![infoStickers containsObject:poiStickerID]) {
                                [infoStickers acc_addObject:poiStickerID];
                            }
                        }
                        NSString *pollStickerID = [dic acc_stringValueForKey:@"poll_sticker_id"];
                        if (!ACC_isEmptyString(pollStickerID)) {
                            if (![infoStickers containsObject:pollStickerID]) {
                                [infoStickers acc_addObject:pollStickerID];
                            }
                        }
                        NSString *liveStickerID = [dic acc_stringValueForKey:@"live_sticker_id"];
                        if (!ACC_isEmptyString(liveStickerID)) {
                            if (![infoStickers containsObject:liveStickerID]) {
                                [infoStickers acc_addObject:liveStickerID];
                            }
                        }
                        NSString *commentStickerID = [dic acc_stringValueForKey:@"comment_sticker_id"];
                        if (!ACC_isEmptyString(commentStickerID)) {
                            if (![infoStickers containsObject:commentStickerID]) {
                                [infoStickers btd_addObject:@"comment"];
                                [infoStickersTab btd_addObject:@"comment_reply"];
                            }
                        }
                    }
                }
            }
        }];
    }
    
    infoDictionary[@"info_sticker_list"] = [infoStickers componentsJoinedByString:@","] ? : @"";
    infoDictionary[@"infosticker_from"] = [infoStickersTab componentsJoinedByString:@","] ? : @"";
    
    return infoDictionary;
}

- (NSDictionary *)liteVideoFragmentInfoDictionary
{
    // @prefix: vfi = VideoFragmentInfo
    NSMutableDictionary *vfi = ACCDynamicCast(self.videoFragmentInfoDictionary, NSMutableDictionary);
    if(!vfi){
        vfi = [NSMutableDictionary dictionaryWithDictionary:self.videoFragmentInfoDictionary];
    }
    vfi[@"is_speed_change"] = nil;
    vfi[@"reshape_list"] = nil;
    vfi[@"smooth_list"] = nil;
    return vfi;
}
- (NSDictionary *)socialInfoTrackDic
{
    NSMutableSet<NSString *> *mentionFromSet = [NSMutableSet set];
    NSMutableSet<NSString *> *hashtagFromSet = [NSMutableSet set];
    
    /// 数据产品确认不需要去重
    NSMutableArray <NSString *> *hashtagNameList = [NSMutableArray array];
    NSMutableArray <NSString *> *mentionUserIdList = [NSMutableArray array];
    
    ACCRepoStickerModel *repoSticker = [self.repository extensionModelOfClass:[ACCRepoStickerModel class]];
    ACCRepoPublishConfigModel *repoConfig = [self.repository extensionModelOfClass:ACCRepoPublishConfigModel.class];
    
    // add mention hashtag info from interaction stickers(include mention/hashtag stcikers and text stickers)
    [[repoSticker.interactionStickers copy] enumerateObjectsUsingBlock:^(AWEInteractionStickerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj.type == AWEInteractionStickerTypeMention) {
            AWEInteractionMentionStickerModel *mentionSticker = ([obj isKindOfClass:[AWEInteractionMentionStickerModel class]]) ? (AWEInteractionMentionStickerModel *)obj : nil;
            NSString *userId = [mentionSticker.mentionedUserInfo acc_stringValueForKey:@"user_id"];
            if (!ACC_isEmptyString(userId)) {
                [mentionFromSet addObject:obj.isAutoAdded?@"auto":@"prop_entrance"];
                [mentionUserIdList acc_addObject:userId];
            }
            
        } else if (obj.type == AWEInteractionStickerTypeHashtag) {
            AWEInteractionHashtagStickerModel *hashtagSticker = ([obj isKindOfClass:[AWEInteractionHashtagStickerModel class]]) ? (AWEInteractionHashtagStickerModel *)obj : nil;
            NSString *hashtagName = [hashtagSticker.hashtagInfo acc_stringValueForKey:@"hashtag_name"];
            if (!ACC_isEmptyString(hashtagName)) {
                [hashtagNameList acc_addObject:hashtagName];
                [hashtagFromSet addObject:obj.isAutoAdded?@"auto":@"prop_entrance"];
            }
            
        } else if (obj.type == AWEInteractionStickerTypeSocialText) {
            AWEInteractionSocialTextStickerModel *socialTextSticker = nil;
            if ([obj isKindOfClass:[AWEInteractionSocialTextStickerModel class]]) {
                socialTextSticker = (AWEInteractionSocialTextStickerModel *)obj;
            }
            NSArray <AWEInteractionStickerAssociatedSocialModel *> *socialModels = socialTextSticker.textSocialInfos;
            [[socialModels copy] enumerateObjectsUsingBlock:^(AWEInteractionStickerAssociatedSocialModel * _Nonnull socialModel, NSUInteger idx, BOOL * _Nonnull stop) {
                
                if (socialModel.type == AWEInteractionStickerAssociatedSociaTypeMention &&
                    !ACC_isEmptyString(socialModel.mentionModel.userID)) {
                    
                    [mentionFromSet addObject:obj.isAutoAdded?@"auto":@"text_entrance"];
                    [mentionUserIdList acc_addObject:socialModel.mentionModel.userID];
                    
                } else if (socialModel.type == AWEInteractionStickerAssociatedSociaTypeHashtag &&
                           !ACC_isEmptyString(socialModel.hashtagModel.hashtagName)) {
                    
                    [hashtagFromSet addObject:obj.isAutoAdded?@"auto":@"text_entrance"];
                    [hashtagNameList acc_addObject:socialModel.hashtagModel.hashtagName];
                }
            }];
        }
    }];
    
    // add mention info from title
    [[repoConfig.titleExtraInfo copy] enumerateObjectsUsingBlock:^(id<ACCTextExtraProtocol>_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj.accType == ACCTextExtraTypeUser &&
            !ACC_isEmptyString(obj.userId)) {
            
            [mentionFromSet addObject:@"title"];
            [mentionUserIdList acc_addObject:obj.userId];
        }
    }];
    
    // add hashtag info from title
    if (!ACC_isEmptyString(repoConfig.publishTitle)) {
        
        NSArray<id<ACCTextExtraProtocol>> *textExtras = [ACCHashTagService() resolveHashTagsWithText:repoConfig.publishTitle];
        
        [[textExtras copy] enumerateObjectsUsingBlock:^(id<ACCTextExtraProtocol>  _Nonnull extra, NSUInteger idx, BOOL * _Nonnull stop) {
            if (extra.accType == ACCTextExtraTypeChallenge && !ACC_isEmptyString(extra.hashtagName)) {
                [hashtagNameList acc_addObject:extra.hashtagName];
                [hashtagFromSet addObject:@"title"];
            }
        }];
    }

    NSString *hashtagFromsString = @"";
    if (hashtagFromSet.count) {
        hashtagFromsString = [[hashtagFromSet allObjects] componentsJoinedByString:@","];
    }
    
    NSString *mentionFromsString = @"";
    if (mentionFromSet.count) {
        mentionFromsString = [[mentionFromSet allObjects] componentsJoinedByString:@","];
    }
    
    NSString *hashtagNamesString = @"";
    if (hashtagNameList.count) {
        hashtagNamesString = [hashtagNameList componentsJoinedByString:@","];
    }
    
    NSDictionary *ret = @{
        @"at_prop_cnt":@(mentionUserIdList.count),
        @"tag_prop_cnt":@(hashtagNameList.count),
        @"tag_selected_from":hashtagFromsString ?:@"",
        @"at_selected_from":mentionFromsString ?:@"",
        @"tag_name" : hashtagNamesString ?:@""
    };
    
    return ret;
}

- (void)trackPostEvent:(NSString *)event enterMethod:(NSString *)enterMethod
{
    [self trackPostEvent:event enterMethod:enterMethod extraInfo:nil];
}

- (void)trackPostEvent:(NSString *)event enterMethod:(NSString *)enterMethod extraInfo:(NSDictionary *)extraInfo
{
    [self trackPostEvent:event enterMethod:enterMethod extraInfo:extraInfo isForceSend:NO];
}

- (void)trackPostEvent:(NSString *)event
           enterMethod:(NSString *)enterMethod
             extraInfo:(NSDictionary *)extraInfo
           isForceSend:(BOOL)isForceSend
{
    AWERepoContextModel *repoContext = [self.repository extensionModelOfClass:[AWERepoContextModel class]];
    ACCRepoTranscodingModel *repoTranscoding = [self.repository extensionModelOfClass:[ACCRepoTranscodingModel class]];
    ACCRepoUploadInfomationModel *repoUploadInfo = [self.repository extensionModelOfClass:[ACCRepoUploadInfomationModel class]];
    ACCRecordInformationRepoModel *repoRecordInfo = [self.repository extensionModelOfClass:[ACCRecordInformationRepoModel class]];
    AWERepoVideoInfoModel *repoVideoInfo = [self.repository extensionModelOfClass:[AWERepoVideoInfoModel class]];
    
    BOOL isIMRecord = repoContext.recordSourceFrom == AWERecordSourceFromIM || repoContext.recordSourceFrom == AWERecordSourceFromIMGreet;
    if (isIMRecord && isForceSend == NO) {
        return;
    }
    NSMutableDictionary *params = repoTranscoding.videoQualityTraceInfo;
    [params addEntriesFromDictionary:self.referExtra];
    // 分段视频滤镜id和name
    NSDictionary *videoFragmentInfo = self.videoFragmentInfoDictionary;
    if (videoFragmentInfo) {
        [params addEntriesFromDictionary:videoFragmentInfo];
    }
    
    if (enterMethod) {
        params[@"enter_method"] = enterMethod;
    }
    if (repoVideoInfo.enableHDRNet) {
        params[@"improve_status"] = @"on";
        params[@"improve_method"] = @"hdr";
    } else {
        params[@"improve_status"] = @"off";
    }
    params[@"new_selected_method"] = self.selectedMethod;
    if (repoContext.videoType == AWEVideoTypeNormal && repoUploadInfo.originUploadVideoClipCount) {
        params[@"upload_type"] = repoUploadInfo.originUploadVideoClipCount.integerValue == 1 ? @"single_content" : @"multiple_content";
    }
    if (extraInfo) {
        [params addEntriesFromDictionary:extraInfo];
    }
    NSDictionary *beautifyDic = repoRecordInfo.beautifyTrackInfoDic;
    if (beautifyDic) {
        [params addEntriesFromDictionary:beautifyDic];
    }
    
    if (self.schemaTrackParmForActivity) {
        [params addEntriesFromDictionary:self.schemaTrackParmForActivity];
    }
    
    params[@"publish_cnt"] = @([ACCVideoPublish() publishTaskCount]);

    [ACCTracker() trackEvent:event
                       params:params
              needStagingFlag:NO];
}

- (nonnull NSDictionary *)referExtra
{
    NSMutableDictionary *extra = @{}.mutableCopy;
    
    [self.repository.extensionModels enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (![obj respondsToSelector:@selector(acc_referExtraParams)]) {
            return;
        }
        NSDictionary *extensionParams = [obj acc_referExtraParams];
        [extensionParams enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull paramsKey, id  _Nonnull paramValue, BOOL * _Nonnull stop) {
            if (![paramValue isKindOfClass:[NSNull class]]) {
                extra[paramsKey] = paramValue;
            }
        }];
    }];
        
    id<ACCRepoMissionModelProtocol> missionModel = [self.repository extensionModelOfProtocol:@protocol(ACCRepoMissionModelProtocol)];
    ACCRepoChallengeModel *challengeModel = [self.repository extensionModelOfClass:ACCRepoChallengeModel.class];
    ACCRepoUploadInfomationModel *uploadModel = [self.repository extensionModelOfClass:ACCRepoUploadInfomationModel.class];
    ACCRepoMusicModel *musicModel = [self.repository extensionModelOfClass:ACCRepoMusicModel.class];
    AWERepoContextModel *contextModel = [self.repository extensionModelOfClass:AWERepoContextModel.class];
    ACCRepoPropModel *propModel = [self.repository extensionModelOfClass:ACCRepoPropModel.class];
    ACCRepoReshootModel *reshootModel = [self.repository extensionModelOfClass:ACCRepoReshootModel.class];
    ACCRepoTextModeModel *textModel = [self.repository extensionModelOfClass:ACCRepoTextModeModel.class];
    AWERepoCutSameModel *cutSameModel = [self.repository extensionModelOfClass:AWERepoCutSameModel.class];
    ACCRepoDuetModel *duetModel = [self.repository extensionModelOfClass:ACCRepoDuetModel.class];
    ACCRecognitionTrackModel *recognitionModel = [self.repository extensionModelOfClass:ACCRecognitionTrackModel.class];
    AWERepoPublishConfigModel *repoConfigModel =  [self.repository extensionModelOfClass:AWERepoPublishConfigModel.class];
    ACCRepoAudioModeModel *audioModeModel = [self.repository extensionModelOfClass:ACCRepoAudioModeModel.class];
    ACCRepoQuickStoryModel *quickStoryModel = [self.repository extensionModelOfClass:ACCRepoQuickStoryModel.class];
    
    extra[@"task_id"] = [missionModel acc_mission].ID ?: challengeModel.challenge.task.ID;
    
    NSDictionary *contentTypeMap = [self contentTypeMap];

    NSString *contentType = contentTypeMap[@(contextModel.videoType)] ? : @"video";

    if (AWEVideoTypePicture == contextModel.videoType) {
        contentType = @"slideshow";
    }
    if (uploadModel.isAIVideoClipMode) {
        contentType = @"sound_sync";
    } else if (contextModel.videoType == AWEVideoTypeMV && !cutSameModel.isClassicalMV) {
        contentType = @"jianying_mv";
    } else if (textModel.isTextMode) {
        contentType = @"text";
    } else if (duetModel.isDuet) {
        contentType = @"duet_video";
    } else if (recognitionModel){
        contentType = @"reality";
    } else if (audioModeModel.isAudioMode) {
        contentType = @"audio";
    }
    
    if (AWEVideoTypeOneClickFilming == contextModel.videoType) {
        contentType = @"ai_upload";
    }
    
    extra[@"content_type"] = contentType;
    
    //直播录屏、高光按照普通视频处理，但要区分content_type
    switch (contextModel.videoType) {
        case AWEVideoTypeLiveScreenShot:
            extra[@"content_type"] = @"live_record";
            break;
        case AWEVideoTypeLiveBackRecord:
            extra[@"content_type"] = @"live_back_record";
            break;
            
        case AWEVideoTypeLiveHignLight:
            extra[@"content_type"] = @"live_highlight";
            break;
        case AWEVideoTypeLivePlayback:
            extra[@"content_type"] = @"live_replay";
            break;
        case AWEVideoTypeKaraoke:
            extra[@"content_type"] = @"pop_music";
        default:
            break;
    }
    
    if ([contextModel.activityVideoType integerValue] == ACCActivityVideoTypeHighLight) {
        extra[@"content_type"] = @"memory_mv";
    } else if ([contextModel.activityVideoType integerValue] == ACCActivityVideoTypeYearEndReport) {
        extra[@"content_type"] = @"annual_report";
    } else if ([contextModel.activityVideoType integerValue] == ACCActivityVideoTypeNewYearWish) {
        extra[@"content_type"] = @"wish";
    }

    if (self.contentType) {
        extra[@"content_type"] = self.contentType;
    }
    
    if ([uploadModel.extraDict objectForKey:@"content_type"]) {
        [extra setValue:[uploadModel.extraDict objectForKey:@"content_type"] forKey:@"content_type"];
    }
    
    extra[@"content_source"] = [self contentSource];
    BOOL isReuseFeedMusic = [musicModel.musicSelectedFrom containsString:@"same_prop_music"];
    BOOL isReuseFeedSticker = [propModel.propSelectedFrom containsString:@"direct_shoot"];
    if (isReuseFeedMusic) {
        extra[@"reuse_prop_music"] = isReuseFeedSticker ? @"prop_music" : @"music";
    } else if (isReuseFeedSticker) {
        extra[@"reuse_prop_music"] = @"prop";
    }
    if (contextModel.videoSource != AWEVideoSourceCapture) {
        extra[@"upload_type"] = uploadModel.originUploadVideoClipCount.integerValue == 1 ? @"single_content" : @"multiple_content";
    }
    extra[@"edit_from"] = self.shareEditFrom;
    
    extra[@"creation_id"] = (reshootModel.isReshoot && reshootModel.fromCreateId.length > 0) ? reshootModel.fromCreateId : contextModel.createId;
    extra[@"creation_session_id"] = self.creationSessionId;
    extra[@"mix_type"] = [self mediaCountInfo][@"mix_type"];
    
    // 单图发为图集按照图集的content type
    if (AWEVideoTypeImageAlbum == contextModel.videoType ||
        repoConfigModel.isPublishCanvasAsImageAlbum) {
        extra[@"content_type"] = @"multi_photo";
    }
    if (self.shootPreviousPage) {
        extra[@"shoot_previous_page"] = self.shootPreviousPage;
    }
    
    if (cutSameModel.isNewCutSameOrSmartFilming) {
        [extra addEntriesFromDictionary:[cutSameModel smartVideoAdditionParamsForPublishTrack]];
    }
    
    if ([quickStoryModel.friendsFeedPostPromotionType isEqualToString:@"friends_feed_post_promotion_video"]) {
        extra[@"template_type"] = @"video";
    }
    if ([quickStoryModel.friendsFeedPostPromotionType isEqualToString:@"friends_feed_post_promotion_music"]) {
        extra[@"template_type"] = @"music";
    }
    
    extra[@"is_commerce_comment"] = ([IESAutoInline(ACCBaseServiceProvider(), ACCCommerceServiceProtocol) isEnterFromECommerceComment:self.repository] ? @1 : @0);

    return extra;
}

- (NSDictionary *)contentTypeMap
{
    NSDictionary *contentTypeMap = @{
                                     @(AWEVideoTypeNormal)          :   @"video",
                                     @(AWEVideoTypePicture)         :   @"photo",
                                     @(AWEVideoTypePhotoMovie)      :   @"slideshow",
                                     @(AWEVideoTypeLivePhoto)       :   @"slideshow",
                                     @(AWEVideoTypeStory)           :   @"video",
                                     @(AWEVideoTypeStoryPicVideo)   :   @"photo",
                                     @(AWEVideoTypeStoryPicture)    :   @"photo",
                                     @(AWEVideoTypeQuickStoryPicture)    :   @"slideshow",
                                     @(AWEVideoTypeMV)              :   @"mv",
                                     @(AWEVideoTypePhotoToVideo)      :   @"slideshow",
                                     @(AWEVideoTypeMoments)         :   @"moment",
                                     @(AWEVideoTypeReplaceMusicVideo):  @"replace_music",
                                     @(AWEVideoTypeSmartMV)         :   @"smart_mv",
    };
    
    return contentTypeMap;
}

- (NSDictionary<NSNumber *, NSString *> *)recordButtonTypeTrackInfoMap
{
    NSDictionary *map = @{
        @(AWEVideoRecordButtonTypeUnknown) : @"",
        @(AWEVideoRecordButtonTypeMixHoldTap) : @"video",
        @(AWEVideoRecordButtonTypeStory) : @"fast_shoot",
        @(AWEVideoRecordButtonTypeMixHoldTap15Seconds) : @"video_15",
        @(AWEVideoRecordButtonTypeMixHoldTapLongVideo) : @"video_60",
        @(AWEVideoRecordButtonTypeText) : @"text",
        @(AWEVideoRecordButtonTypeMiniGame) : @"micro_game",
        @(AWEVideoRecordButtonTypeMixHoldTap60Seconds) : @"video_60",
        @(AWEVideoRecordButtonTypeMixHoldTap3Minutes) : @"video_180",
        @(AWEVideoRecordButtonTypeLivePhoto) : @"dynamic_photo",
        @(AWEVideoRecordButtonTypeTheme) : @"theme_shoot",
    };
    return map;
}

- (NSString *)tabName
{
    // 春节tab name
    AWERepoFlowerTrackModel *flowerTrackModel = [self.repository extensionModelOfClass:AWERepoFlowerTrackModel.class];
    if (flowerTrackModel.fromFlowerCamera) {
        return flowerTrackModel.flowerTabName;
    }
    
    ACCRepoFlowControlModel *flowModel = [self.repository extensionModelOfClass:ACCRepoFlowControlModel.class];
    NSString *tabName = [self recordButtonTypeTrackInfoMap][@(flowModel.videoRecordButtonType)];
    if (ACC_isEmptyString(tabName)) {
        ACCRepoContextModel *contextModel = [self.repository extensionModelOfClass:ACCRepoContextModel.class];
        if (contextModel.videoType == AWEVideoTypeQuickStoryPicture || contextModel.videoType == AWEVideoTypePhotoToVideo) {
            return @"photo";
        }
    }
    return tabName;
}

- (NSString *)contentSource
{
    ACCRepoContextModel *contextModel = [self.repository extensionModelOfClass:ACCRepoContextModel.class];
    ACCRepoUploadInfomationModel *uploadModel = [self.repository extensionModelOfClass:ACCRepoUploadInfomationModel.class];
    ACCRepoAudioModeModel *audioModeModel = [self.repository extensionModelOfClass:ACCRepoAudioModeModel.class];
    
    NSString *contentSource = contextModel.videoSource == AWEVideoSourceAlbum ? @"upload" : @"shoot";
    if (contextModel.isMVVideo) {
        contentSource = @"upload";
    } else if (AWEVideoTypePhotoMovie == contextModel.videoType) {
        contentSource = @"upload";
    } else if ([uploadModel isAIVideoClipMode]) {
        contentSource = @"upload";
    } else if (AWEVideoTypeReplaceMusicVideo == contextModel.videoType) {
        contentSource = @"replace_music";
    } else if (audioModeModel.isAudioMode == YES) {
        contentSource = @"upload";
    }
    if (contextModel.videoSource == AWEVideoSourceRemoteResource) {
        contentSource = @"auto_produce";
    }
    return contentSource;
}

- (NSDictionary *)publishCommonTrackDict {
    ACCRepoContextModel *contextModel = [self.repository extensionModelOfClass:ACCRepoContextModel.class];
    ACCRepoTranscodingModel *transCodingModel = [self.repository extensionModelOfClass:ACCRepoTranscodingModel.class];
    return @{
        @"shoot_way":self.referString?:@"",
        @"creation_id":contextModel.createId?:@"",
        @"content_type":self.referExtra[@"content_type"]?:@"",
        @"content_source":self.referExtra[@"content_source"]?:@"",
        @"is_multi_content":self.mediaCountInfo[@"is_multi_content"]?:@"",
        @"file_size" : @(transCodingModel.uploadFileSize)
    };
}

- (NSString *)isMultiContentValue
{
    return self.mediaCountInfo[@"is_multi_content"]?:@"";
}

- (BOOL)musicLandingMultiLengthInitially
{
    return [self.referString isEqualToString:@"single_song"] && ACCConfigInt(kConfigInt_always_force_landing_quick_shoot_music_option) == ACCStoryMusicLandingMultiLengthInitially;
}

#pragma mark - getter

- (NSString *)creationSessionId
{
    if (!_creationSessionId) {
        _creationSessionId = [[NSUUID UUID] UUIDString];
    }
    return _creationSessionId;
}

/*
!!! 必须实现 ！！！
 NSCopying 协议的实现是必须的
 1.在repository被拷贝的时候element也需要被深拷贝
 2.在一些需要传递repository容器的场景下element也需要被深拷贝。
 */
#pragma mark - NSCopying - Required
- (id)copyWithZone:(NSZone *)zone
{
    AWERepoTrackModel *model = [super copyWithZone:zone];
    
    model.creationSessionId = self.creationSessionId;
    model.selectedMethod = self.selectedMethod;
    model.contentType = self.contentType;
    model.shootPreviousPage = self.shootPreviousPage;
    model.isRestoreFromBackup = self.isRestoreFromBackup;
    model.hasRecordEnterEvent = self.hasRecordEnterEvent;
    model.isClickPlus = self.isClickPlus;
    
    // story入口埋点
    model.storyGuidePlusIconType = self.storyGuidePlusIconType;
    model.friendLabel = self.friendLabel;
    model.entrance = self.entrance;
    
    // 魔方h5入口埋点
    model.magic3ComponentId = self.magic3ComponentId;
    model.magic3Source = self.magic3Source;
    model.magic3ActivityId = self.magic3ActivityId;

    model.schemaTrackParmForActivity = self.schemaTrackParmForActivity;
    model.schemaTrackParams = self.schemaTrackParams;
    model.extraTrackInfo = self.extraTrackInfo;
    
    model.activityExtraJson = self.activityExtraJson;

    model.lastItemId = self.lastItemId;
    model.originalFromMvId = self.originalFromMvId;
    model.originalFromMusicId = self.originalFromMusicId;
    model.enterStatus = self.enterStatus;
    model.isLongTitle = self.isLongTitle;
    model.isDiskResumeUpload = self.isDiskResumeUpload;
    
    return model;
}
    
#pragma mark - ACCRepositoryTrackContextProtocol

- (NSDictionary *)acc_referExtraParams {
    NSMutableDictionary *extra = [super acc_referExtraParams].mutableCopy;
    if (self.referString) {
        extra[@"shoot_way"] = self.enterShootPageExtra[@"shoot_way"] ? : self.referString ? : @"";
        extra[@"shoot_entrance"] = self.referString; //这个 key 是啥两个数据分析师口径不统一，都打上吧
    }
    
    extra[@"entrance"] = self.entrance;
    
    if (self.recordRouteNumber != nil) {
        extra[@"route"] = self.recordRouteNumber;
    }
    
    if (self.enterFrom) {
        extra[@"enter_from"] = self.enterFrom;
    }
    
    if (self.enterMethod) {
        extra[@"enter_method"] = self.enterMethod;
    }
    extra[@"friend_label"] = self.friendLabel ? : @"";

    return extra.copy;
}


/*
！！！发布请求参数相关看这里！！！
 在发布请求参数打包的时候会遍历element中的acc_publishRequestParams得到额外的参数，并塞入原参数集合中（平级）；
 因此只需要在此处编写约定好的key-value即可；[NSNull null]最为空占位，在后续的流程中会被过滤掉。
 */
#pragma mark - ACCRepositoryRequestParamsProtocol - Optional
- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    NSMutableDictionary *paramDict = nil;
    // check ACCRepoTrackModel 中是否有实现
    if ([super respondsToSelector:@selector(acc_publishRequestParams:)]) {
        paramDict = [[super acc_publishRequestParams:publishViewModel] mutableCopy];
    }
    // check paramDict 是否返回的是nil
    if (!paramDict) {
        paramDict = @{}.mutableCopy;
    }
    
    if (self.schemaTrackParmForActivity) {
        NSString *json = [self.schemaTrackParmForActivity acc_dictionaryToJson];
        paramDict[@"activity_mob_json"] = json;
    }
    
    if (!ACC_isEmptyString(self.lastItemId)) {
        paramDict[@"last_item_id"] = self.lastItemId;
    }
    
    if (!ACC_isEmptyString(self.activityExtraJson)) {
        paramDict[@"activity_extra_json"] = self.activityExtraJson;
    }
    
    if ([IESAutoInline(ACCBaseServiceProvider(), ACCActivityConfigProtocol) isVXE]) {
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        if (!ACC_isEmptyString(self.activityExtraJson)) {
            NSDictionary *dict = [self.activityExtraJson acc_jsonDictionary];
            if (dict) {
                [params addEntriesFromDictionary:dict];
            }
        }
        params[@"e_activity_user"] = @(YES);
        
        NSString *activityExtraJson = [params acc_dictionaryToJson];
        if (!ACC_isEmptyString(activityExtraJson)) {
            paramDict[@"activity_extra_json"] = activityExtraJson;
        }
    }
    
    return [paramDict copy];
}

- (NSDictionary *)acc_publishTrackEventParams:(AWEVideoPublishViewModel *)publishViewModel
{
    NSMutableDictionary *paramDict = [NSMutableDictionary dictionary];
    if (self.magic3ComponentId) {
        paramDict[@"magic3_compid"] = self.magic3ComponentId;
    }
    if (self.magic3Source) {
        paramDict[@"magic3_source"] = self.magic3Source;
    }
    if (self.magic3ActivityId) {
        paramDict[@"magic3_activityId"] = self.magic3ActivityId;
    }
    if (self.schemaTrackParmForActivity) {
        [paramDict addEntriesFromDictionary:self.schemaTrackParmForActivity];
    }
    
    if (self.originalFromMusicId && ![self.originalFromMusicId isEqual:@""]) {
        paramDict[@"from_music_id"] = self.originalFromMusicId;
        AWERepoMusicModel *model = [self.repository extensionModelOfClass:[AWERepoMusicModel class]];
        BOOL useDefaultMusic = [model.music.musicID isEqual:self.originalFromMusicId];
        if (useDefaultMusic) {
            paramDict[@"is_default_music"] = @(1);
        } else {
            paramDict[@"is_default_music"] = @(0);
        }
    }
    
    if (self.originalFromMvId && ![self.originalFromMvId isEqual:@""]) {
        paramDict[@"from_mv_id"] = self.originalFromMvId;
        AWERepoMVModel *model = [self.repository extensionModelOfClass:[AWERepoMVModel class]];
        BOOL useDefaultMV = [model.mvID isEqual:self.originalFromMvId] ||
                            [model.templateModelId isEqual:self.originalFromMvId];
        if (useDefaultMV) {
            paramDict[@"is_default_mv"] = @(1);
        } else {
            paramDict[@"is_default_mv"] = @(0);
        }
    }

    return paramDict;
}

#pragma mark - Getter

- (NSDictionary *)extraTrackInfo
{
    if (!_extraTrackInfo) {
        _extraTrackInfo = [[NSDictionary alloc] init];
    }
    
    return _extraTrackInfo;
}

- (NSDictionary *)referExtraByAppend:(NSDictionary *)extras
{
    NSMutableDictionary *ret = [[NSMutableDictionary alloc] initWithDictionary:self.referExtra?:@{}];
    [ret addEntriesFromDictionary:extras?:@{}];
    return [ret copy];
}

@end
