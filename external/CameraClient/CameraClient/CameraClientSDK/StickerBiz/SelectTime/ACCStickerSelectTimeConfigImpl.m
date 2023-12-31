//
//  ACCStickerSelectTimeConfigImpl.m
//  CameraClient-Pods-Aweme
//
//  Created by guochenxiang on 2020/8/25.
//

#import "ACCStickerSelectTimeConfigImpl.h"
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoStickerModel.h>
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoStickerModel.h>

@implementation ACCStickerSelectTimeConfigImpl

- (NSDictionary *)referExtra
{
    return self.repository.repoTrack.referExtra;
}

- (NSMutableDictionary<NSString *, IESMMVideoDataClipRange *> *)textReadingRanges
{
    return self.repository.repoSticker.textReadingRanges;
}

- (NSValue *)sizeOfVideo
{
    return self.repository.repoVideoInfo.sizeOfVideo;
}

- (AWEVideoSource)videoSource
{
    return self.repository.repoContext.videoSource;
}

- (CGFloat)maxDuration
{
    CGFloat max2DGameDurarion = 300.f;
    if (self.repository.repoContext.videoType == AWEVideoType2DGame)
        return max2DGameDurarion; //拍摄页在使用小游戏道具时不会修改maxDuration，后续若有修改可删除此处
    return self.repository.repoContext.maxDuration;
}

- (ACCEditVideoData *)video
{
    return self.repository.repoVideoInfo.video;
}

- (AVAsset *)audioAssetInVideoDataWithKey:(NSString *)key
{
    return [self.repository.repoSticker audioAssetInVideoDataWithKey:key];
}

@end
