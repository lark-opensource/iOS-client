//
//  ACCTextStickerRecommendDataHelper.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/8/1.
//

#import "ACCTextStickerRecommendDataHelper.h"
#import "AWERepoMusicModel.h"
#import "AWERepoContextModel.h"
#import "AWERepoStickerModel.h"
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCNetServiceProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/ACCStickerNetServiceProtocol.h>

@implementation ACCTextStickerRecommendDataHelper

+ (void)requestBasicRecommend:(AWEVideoPublishViewModel *)publishModel completion:(nullable void(^)( NSArray<ACCTextStickerRecommendItem *> *, NSError *))completion
{
    if ([ACCTextStickerRecommendDataHelper textBarRecommendMode] & AWEModernTextRecommendModeRecommend) {
        [IESAutoInline(ACCBaseServiceProvider(), ACCTextLibararyNetServiceProtocol) requestTextRecommendForZipURI:publishModel.repoMusic.zipURI creationId:publishModel.repoContext.createId keyword:@"" completionBlock:^(NSError *error, NSArray *result) {
            if (!error && result.count) {
                NSArray<ACCTextStickerRecommendItem *> *list = [MTLJSONAdapter modelsOfClass:ACCTextStickerRecommendItem.class fromJSONArray:result error:nil];
                publishModel.repoSticker.directTitles = list;
                ACCBLOCK_INVOKE(completion, list, nil);
            } else {
                ACCBLOCK_INVOKE(completion, nil, error);
            }
        }];
    } else {
        ACCBLOCK_INVOKE(completion, nil, nil);
    }
}

+ (void)requestRecommend:(NSString *)keyword publishModel:(AWEVideoPublishViewModel *)publishModel completion:(nullable void(^)(NSArray<ACCTextStickerRecommendItem *> *, NSError *))completion
{
    if ([ACCTextStickerRecommendDataHelper textBarRecommendMode] & AWEModernTextRecommendModeRecommend) {
        [IESAutoInline(ACCBaseServiceProvider(), ACCTextLibararyNetServiceProtocol) requestTextRecommendForZipURI:publishModel.repoMusic.zipURI creationId:publishModel.repoContext.createId keyword:keyword completionBlock:^(NSError *error, NSArray *result) {
            if (!error && result.count) {
                NSArray<ACCTextStickerRecommendItem *> *list = [MTLJSONAdapter modelsOfClass:ACCTextStickerRecommendItem.class fromJSONArray:result error:nil];
                ACCBLOCK_INVOKE(completion, list, nil);
            } else {
                ACCBLOCK_INVOKE(completion, nil, error);
            }
        }];
    } else {
        ACCBLOCK_INVOKE(completion, nil, nil);
    }
}

+ (void)requestLibList:(AWEVideoPublishViewModel *)publishModel completion:(nullable void(^)(NSArray<ACCTextStickerLibItem *> *, NSError *))completion
{
    if ([ACCTextStickerRecommendDataHelper textBarRecommendMode] & AWEModernTextRecommendModeLib) {
        [IESAutoInline(ACCBaseServiceProvider(), ACCTextLibararyNetServiceProtocol) requestTextLibForZipURI:publishModel.repoMusic.zipURI creationId:publishModel.repoContext.createId completionBlock:^(NSError *error, NSArray *result) {
            if (!error) {
                NSArray<ACCTextStickerLibItem *> *list = [MTLJSONAdapter modelsOfClass:ACCTextStickerLibItem.class fromJSONArray:result error:nil];
                publishModel.repoSticker.textLibItems = list;
                ACCBLOCK_INVOKE(completion, list, nil);
            } else {
                ACCBLOCK_INVOKE(completion, nil, error);
            }
        }];
    } else {
        ACCBLOCK_INVOKE(completion, nil, nil);
    }
}

+ (BOOL)enableRecommend
{
    return [ACCTextStickerRecommendDataHelper textBarRecommendMode] != AWEModernTextRecommendModeNone;
}

+ (AWEModernTextRecommendMode)textBarRecommendMode
{
    BOOL showRecommend = ACCConfigBool(kConfigBool_studio_text_recommend);
    BOOL showLib = ACCConfigBool(kConfigBool_studio_textsticker_lib);
    if (showRecommend && showLib) return AWEModernTextRecommendModeBoth;
    if (showRecommend) return AWEModernTextRecommendModeRecommend;
    if (showLib) return AWEModernTextRecommendModeLib;
    return AWEModernTextRecommendModeNone;
}

@end
