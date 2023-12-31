//
//  AWEStickerMusicManager+Local.m
//  CameraClient-Pods-CameraClient
//
//  Created by Howie He on 2021/3/19.
//

#import "AWEStickerMusicManager+Local.h"
#import "ACCVideoMusicProtocol.h"
#import "ACCMusicNetServiceProtocol.h"

#import <EffectPlatformSDK/IESEffectModel.h>
#import <CreativeKit/ACCMacrosTool.h>

@implementation AWEStickerMusicManager (Local)

+ (BOOL)insertMusicModelToCache:(id<ACCMusicModelProtocol>)musicModel {
    if (!musicModel || ACC_isEmptyString(musicModel.musicID)) {
        return NO;
    }
    
    return [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) cacheMusicModel:musicModel cacheKey:ACCMusicCacheStickerMusicManager];
}
 
+ (id<ACCMusicModelProtocol> _Nullable)fetchtMusicModelFromCache:(NSString *)musicID {
    if (ACC_isEmptyString(musicID)) {
        return nil;
    }
    return [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) fetchCachedMusicWithID:musicID cacheKey:ACCMusicCacheStickerMusicManager];
}

+ (NSURL * _Nullable)localURLForMusic:(id<ACCMusicModelProtocol>)musicModel {
    if (musicModel) {
        NSURL *url = [ACCVideoMusic() localURLForMusic:musicModel];
         BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:url.path];
        if (url && fileExists) {
            return url;
        } else {
            return nil;
        }
    } else {
        return nil;
    }
}

// 依赖强绑定音乐的缓存是否存在
+ (BOOL)needToDownloadMusicWithEffectModel:(IESEffectModel *)effectModel {
    BOOL musicIsForceBind = [self musicIsForceBindStickerWithExtra:effectModel.extra];
    if (musicIsForceBind && effectModel.musicIDs) {
        NSString *musicID = effectModel.musicIDs.firstObject;
        id<ACCMusicModelProtocol> musicModel = [AWEStickerMusicManager fetchtMusicModelFromCache:musicID];
        NSURL *url = [AWEStickerMusicManager localURLForMusic:musicModel];
        //首次展示道具面板，从非常规路径进入下载失败要显示下载成功
        BOOL hasDownloadFailed = [AWEStickerMusicManager getForceBindMusicDownloadFailed:effectModel.effectIdentifier];
        if (([musicModel isOffLine] || !url) && !hasDownloadFailed) {
            return YES;
        }
    }
    return NO;
}

@end
