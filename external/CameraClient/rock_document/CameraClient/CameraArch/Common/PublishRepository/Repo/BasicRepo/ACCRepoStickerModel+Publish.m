//
//  AWERepoStickerModel+Publish.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/26.
//

#import "AWERepoStickerModel.h"
#import "ACCRepoStickerModel+Publish.h"
#import <CameraClient/AWEInteractionStickerModel+DAddition.h>
#import "AWERepoVideoInfoModel.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import <TTVideoEditor/IESInfoSticker.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import "AWEInteractionPOIStickerModel.h"
#import "ACCRepoImageAlbumInfoModel.h"
#import <CameraClientModel/ACCVideoCommentModel.h>
#import <CameraClientModel/ACCVideoReplyModel.h>
#import <CameraClientModel/ACCVideoReplyCommentModel.h>
#import <CameraClientModel/ACCVideoReplyStickerReplyType.h>
#import <CameraClient/ACCGrootStickerModel.h>
#import <CreativeKit/NSArray+ACCAdditions.h>

@implementation AWERepoStickerModel (Publish)

/*
！！！发布请求参数相关看这里！！！
 在发布请求参数打包的时候会遍历element中的acc_publishRequestParams得到额外的参数，并塞入原参数集合中（平级）；
 因此只需要在此处编写约定好的key-value即可；[NSNull null]最为空占位，在后续的流程中会被过滤掉。
 */
#pragma mark - ACCRepositoryRequestParamsProtocol - Optional

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    NSMutableDictionary *paramsDict = @{}.mutableCopy;

    if ([self.interactionStickers count] && ![publishViewModel.repoImageAlbumInfo isImageAlbumEdit]) {
        //remove unused key
        [self.interactionStickers enumerateObjectsUsingBlock:^(AWEInteractionStickerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[AWEInteractionPOIStickerModel class]]) {
                AWEInteractionPOIStickerModel *poiStickerModel = (AWEInteractionPOIStickerModel *)obj;
                if (poiStickerModel.poiInfo) {
                    NSMutableDictionary *poiDic = [NSMutableDictionary dictionaryWithDictionary:poiStickerModel.poiInfo];
                    poiDic[@"poi_name"] = nil;
                    poiStickerModel.poiInfo = [NSDictionary dictionaryWithDictionary:poiDic];
                }
            }
        }];
        
        NSError *error = nil;
        NSArray *stickers = [MTLJSONAdapter JSONArrayFromModels:self.interactionStickers error:&error];
        if (error) {
            AWELogToolError(AWELogToolTagPublish, @"%s %@", __PRETTY_FUNCTION__, error);
        }
        if ([stickers count]) {
            //filter useless key
            NSMutableArray <NSDictionary *>*stickers_mut = [NSMutableArray arrayWithArray:stickers];
            [stickers_mut enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSMutableDictionary *obj_mut = [NSMutableDictionary dictionaryWithDictionary:obj];
                if ([obj_mut acc_intValueForKey:@"type"] == AWEInteractionStickerTypePOI) {
                    obj_mut[@"vote_id"] = nil;
                    obj_mut[@"vote_info"] = nil;
                } else if ([obj_mut acc_intValueForKey:@"type"] == AWEInteractionStickerTypePoll) {
                    obj_mut[@"poi_info"] = nil;
                    obj_mut[@"vote_id"] = nil;
                    
                    if (obj_mut[@"vote_info"] && [obj_mut[@"vote_info"] isKindOfClass:[NSDictionary class]]) {
                        NSDictionary *oriVoteDic = nil;
                        if ([obj_mut[@"vote_info"] isKindOfClass:[NSDictionary class]]) {
                            oriVoteDic = (NSDictionary *)obj_mut[@"vote_info"];
                        }
                        NSMutableDictionary *vote_info = [NSMutableDictionary dictionary];
                        NSMutableArray *options = [NSMutableArray array];
                        if (oriVoteDic[@"options"] && [oriVoteDic[@"options"] isKindOfClass:[NSArray class]]) {
                            NSArray *oriVoteOptArr = nil;
                            if ([oriVoteDic[@"options"] isKindOfClass:[NSArray class]]) {
                                oriVoteOptArr = (NSArray *)oriVoteDic[@"options"];
                            }
                            [oriVoteOptArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                if ([obj isKindOfClass:[NSDictionary class]]) {
                                    if (obj[@"option_text"]) {
                                        NSDictionary *optTxt = @{@"option" : obj[@"option_text"]};
                                        [options acc_addObject:optTxt];
                                    }
                                }
                            }];
                        }
                        vote_info[@"options"] = options;
                        vote_info[@"question"] = oriVoteDic[@"question"];
                        obj_mut[@"vote_info"] = [vote_info copy];
                    }
                }
                [stickers_mut replaceObjectAtIndex:idx withObject:obj_mut];
            }];
            
            //后端要求传string,为了给后端和安卓解析
            NSError *jsonError = nil;
            NSData *arrJsonData = [NSJSONSerialization dataWithJSONObject:stickers_mut options:kNilOptions error:&jsonError];
            if (jsonError) {
                AWELogToolError(AWELogToolTagPublish, @"%s %@", __PRETTY_FUNCTION__, jsonError);
            }
            if (arrJsonData) {
                NSString * stickersStr = [[NSString alloc] initWithData:arrJsonData encoding:NSUTF8StringEncoding];
                if (stickersStr) {
                    paramsDict[@"interaction_stickers"] = stickersStr;
                }
            }
        }
    }
    paramsDict[@"text_fonts"] = self.imageTextFonts;
    paramsDict[@"text_font_effect_ids"] = self.imageTextFontEffectIds;
    paramsDict[@"has_text"] = @(self.imageText.length > 0);

    [paramsDict addEntriesFromDictionary:[self customStickersInfos]];
    [paramsDict addEntriesFromDictionary:[self textStickerTrackInfo]];

    NSMutableArray *infoStickers = @[].mutableCopy;
    NSMutableArray *otherStickers = @[].mutableCopy;
    AWERepoVideoInfoModel *videoModel = [publishViewModel extensionModelOfClass:AWERepoVideoInfoModel.class];
    for (IESInfoSticker *infoSticker in videoModel.video.infoStickers) {
        if (infoSticker.isNeedRemove) {
            continue;
        }
        
        // 第三方贴纸
        NSString *type = (NSString *)infoSticker.userinfo[@"type"];
        NSString *remoteStickerID = (NSString *)infoSticker.userinfo[@"stickerID"];
        if (!ACC_isEmptyString(type) && remoteStickerID) {
            NSMutableDictionary *infoStickerDic = [NSMutableDictionary dictionary];
            [infoStickerDic setObject:type forKey:@"type"];
            [infoStickerDic setObject:remoteStickerID forKey:@"id"];
            [otherStickers acc_addObject:infoStickerDic];
        }
        
        // 非三方贴纸
        if (ACC_isEmptyString(type) && remoteStickerID) {
            [infoStickers acc_addObject:remoteStickerID];
        }
    }
    if (otherStickers.count > 0) {
        paramsDict[@"other_sticker"] = [self p_jsonStringEncoded:otherStickers];
    }
    
    //poi贴纸和投票贴纸以及Mention/hashtag贴纸也当成信息化贴纸
    if ([self.interactionStickers count]) {
        [self.interactionStickers enumerateObjectsUsingBlock:^(AWEInteractionStickerModel * _Nonnull acc_obj, NSUInteger idx, BOOL * _Nonnull stop) {
            AWEInteractionStickerModel *obj = acc_obj;
            if ([obj.attr length]) {
                NSData *jsonData = [obj.attr dataUsingEncoding:NSUTF8StringEncoding];
                if (jsonData) {
                    NSError *error = nil;
                    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                        options:NSJSONReadingMutableContainers
                                                                          error:&error];
                    if (error) {
                        AWELogToolError(AWELogToolTagPublish, @"%s %@", __PRETTY_FUNCTION__, error);
                    }
                    if (dic && [dic isKindOfClass:[NSDictionary class]]) {
                        if (dic[@"poi_sticker_id"]) {
                            if (![infoStickers containsObject:dic[@"poi_sticker_id"]]) {
                                [infoStickers acc_addObject:dic[@"poi_sticker_id"]];
                            }
                        }
                        if (dic[@"poll_sticker_id"]) {
                            if (![infoStickers containsObject:dic[@"poll_sticker_id"]]) {
                                [infoStickers acc_addObject:dic[@"poll_sticker_id"]];
                            }
                        }
                        if (dic[@"live_sticker_id"]) {
                            if (![infoStickers containsObject:dic[@"live_sticker_id"]]) {
                                [infoStickers acc_addObject:dic[@"live_sticker_id"]];
                            }
                        }
                    }
                }
            } else if ((obj.type == AWEInteractionStickerTypeHashtag || obj.type == AWEInteractionStickerTypeMention) && !ACC_isEmptyString(obj.stickerID)) {
                [infoStickers acc_addObject:obj.stickerID];
            } else if (obj.type == AWEInteractionStickerTypeGroot && !ACC_isEmptyString(obj.stickerID)) {
                [infoStickers acc_addObject:obj.stickerID];
            }
        }];
    }
    paramsDict[@"info_sticker"] = [infoStickers componentsJoinedByString:@","];
    
    // Video Comment Sticker
    for (ACCShootSameStickerModel *shootSameStickerModel in self.shootSameStickerModels) {
        if (shootSameStickerModel.stickerType == AWEInteractionStickerTypeComment) {
            ACCVideoCommentModel *videoCommentModel = [ACCVideoCommentModel createModelFromJSON:shootSameStickerModel.stickerModelStr];
            if (videoCommentModel) {
                paramsDict[@"reply_id"] = videoCommentModel.commentId;
                if (videoCommentModel.replyToReplyId) {
                    paramsDict[@"reply_to_reply_id"] = videoCommentModel.replyToReplyId;
                }
                paramsDict[@"channel_id"] = @(videoCommentModel.channelId);
                paramsDict[@"reply_aweme_id"] = videoCommentModel.awemeId;
                paramsDict[@"reply_user_id"] = videoCommentModel.userId;
                paramsDict[@"reply_type"] = @(videoCommentModel.replyType);
            }
        }
    }
    
    /**
     Video Reply Video Sticker
     视频评论视频贴纸和视频回复评论贴纸是互斥的，下述信息只会被其中一个赋值
     */
    // 平铺接口，需要新增type判断
    if (self.videoReplyModel != nil) {
        paramsDict[@"reply_aweme_id"] = self.videoReplyModel.playingAwemeId ?: @"";
        paramsDict[@"reply_id"] = self.videoReplyModel.replyId ?: @"";
        paramsDict[@"reply_to_reply_id"] = self.videoReplyModel.replyToReplyId ?: @"";
        paramsDict[@"reply_type"] = @(self.videoReplyModel.replyType) ?: @"";
    }
    
    if (self.videoReplyCommentModel != nil) {
        paramsDict[@"reply_aweme_id"] = self.videoReplyCommentModel.awemeId ?: @"";
        paramsDict[@"reply_id"] = self.videoReplyCommentModel.commentId ?: @"";
        paramsDict[@"reply_to_reply_id"] = self.videoReplyCommentModel.commentToCommentId ?: @"";
        paramsDict[@"reply_type"] = @(self.videoReplyCommentModel.replyType) ?: @"";
        paramsDict[@"reply_user_id"] = self.videoReplyCommentModel.commentUserId ?: @"";
    }
    
    // 增加识别的结果 groot model result
    NSString *grootModelResult = [ACCGrootStickerModel grootModelResultFilterWithString:self.grootModelResult];
    paramsDict[@"groot_model_result"] = grootModelResult;
    return paramsDict.copy;
}

- (NSString *)p_jsonStringEncoded:(id)obj {
    if ([NSJSONSerialization isValidJSONObject:obj]) {
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:kNilOptions error:&error];
        NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        if (error) {
            AWELogToolError(AWELogToolTagPublish, @"%s %@", __PRETTY_FUNCTION__, error);
        }
        return json;
    }
    return nil;
}

@end

