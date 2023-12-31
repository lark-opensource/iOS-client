//
//  ACCStickerPannelFilterImpl.m
//  Pods
//
//  Created by liyingpeng on 2020/8/23.
//

#import "AWERepoContextModel.h"
#import "ACCStickerPannelFilterImpl.h"
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import "ACCConfigKeyDefines.h"
#import <CreationKitArch/ACCRepoStickerModel.h>
#import <CameraClient/ACCRepoImageAlbumInfoModel.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import "AWERepoVideoInfoModel.h"
#import "ACCRepoTextModeModel.h"
#import "ACCCommerceServiceProtocol.h"
#import <CreationKitArch/ACCRepoGameModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CameraClient/ACCCommerceServiceProtocol.h>
#import <CameraClientModel/ACCVideoCanvasType.h>

@implementation ACCStickerPannelFilterImpl

- (NSArray<NSString *> *)filterTags {
    NSMutableArray *result = @[].mutableCopy;
    if (!ACCConfigBool(kConfigBool_info_sticker_support_uploading_pictures) || [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isChildMode] || self.repository.repoContext.isIMRecord || [IESAutoInline(ACCBaseServiceProvider(), ACCCommerceServiceProtocol)  isFromMissionQuickStartWithPublishViewModel:self.repository]){
        [result addObject:@"uploadimagesticker"];
    }
    
    if (![self.dataSource canOpenLiveSticker] || ![IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin] || [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isChildMode] || self.repository.repoContext.isIMRecord) {
        [result addObject:@"livesticker"];
    }
    
    if (ACCConfigEnum(kConfigInt_search_sticker_type, ACCEditSearchStickerType) == ACCEditSearchStickerTypeDisable || self.repository.repoContext.isIMRecord || [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isChildMode]) {
        [result btd_addObject:@"searchsticker"];
    }
    
    // socialSticker is base on sticker ContainerRefactor
    if (!ACCConfigBool(kConfigBool_sticker_support_mention_hashtag) || self.repository.repoContext.isIMRecord ) {
        [result addObject:@"mention"];
        [result addObject:@"hashtag"];
        [result addObject:@"mention2"];
        [result addObject:@"hashtag2"];
    }
            
    if (!ACCConfigBool(kConfigBool_sticker_support_poi_mention_hashtag_UI_uniform)){
        [result addObject:@"mention2"];
        [result addObject:@"hashtag2"];
    } else {
        [result addObject:@"mention"];
        [result addObject:@"hashtag"];
    }
            
    if (!ACCConfigBool(kConfigBool_sticker_support_poi_mention_hashtag_UI_uniform)) {
        [result addObject:@"poi2"];
    } else {
        [result addObject:@"poisticker"];
    }

    if (!ACCConfigBool(kConfigBool_sticker_support_groot) ||
        self.repository.repoContext.isIMRecord ||
        self.repository.repoContext.videoType == AWEVideoTypeKaraoke ||
        self.repository.repoTextMode.isTextMode ||
        self.repository.repoGame.gameType != ACCGameTypeNone ||
        self.repository.repoDuet.isDuet ||
        self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeMusicStory) {
        [result addObject:@"groot"];
    }
    
    /// @description: 拍摄后登录模式禁用Groot和温度贴纸
    if(![IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin]){
        [result addObject:@"groot"];
        [result addObject:@"weather"];
    }
    
    if (self.repository.repoContext.isIMRecord) {//filter poll effect for story
        [result addObject:@"pollsticker"];
        [result addObject:@"lyricssticker"];
    } else if (![self.repository.repoSticker supportMusicLyricSticker] || self.repository.repoContext.videoType == AWEVideoTypeKaraoke) {
        [result addObject:@"lyricssticker"];
    }
    
    if (self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeMusicStory) {
        [result addObject:@"lyricssticker"];
    }
    
    // commerce comment page will hide mention stickers
    if ([IESAutoInline(ACCBaseServiceProvider(), ACCCommerceServiceProtocol) isEnterFromECommerceComment:self.repository]) {
        [result addObject:@"mention"];
        [result addObject:@"mention2"];
    }
    return result.copy;
}

- (BOOL)isIMPhoto
{
    return self.repository.repoContext.isIMRecord && ([self.repository.repoContext isPhoto] || self.repository.repoContext.videoType == AWEVideoTypeStoryPicture);
}

- (BOOL)isAlbumImage
{
    return self.repository.repoImageAlbumInfo.isImageAlbumEdit;
}

- (BOOL)isCommerce
{
    return [IESAutoInline(ACCBaseServiceProvider(), ACCCommerceServiceProtocol) isEnterFromECommerceComment:self.repository];
}

@end
