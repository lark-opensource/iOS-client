//
//  ACCVideoEditTipsViewModel.m
//  CameraClient-Pods-DouYin
//
//  Created by chengfei xiao on 2020/8/6.
//

#import "ACCVideoEditTipsViewModel.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreationKitArch/ACCRepoStickerModel.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import "ACCRepoImageAlbumInfoModel.h"
#import "ACCConfigKeyDefines.h"
#import "AWERepoVideoInfoModel.h"
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>

NSString *const kAWENormalVideoEditHasMusicLyricBubbleShowKey = @"kAWENormalVideoEditHasMusicLyricBubbleShowKey";
NSString *const kAWENormalVideoEditNoMusicLyricBubbleShowKey = @"kAWENormalVideoEditNoMusicLyricBubbleShowKey";

NSString *const kAWENormalVideoEditDonationBubbleShowKey = @"kAWENormalVideoEditDonationBubbleShowKey";
NSString *const kAWENormalVideoEditCustomBubbleShowKey = @"kAWENormalVideoEditCustomBubbleShowKey";
NSString *const kAWENormalVideoEditLiveStickerBubbleShowKey = @"kAWENormalVideoEditLiveStickerBubbleShowKey";
NSString *const kAWENormalVideoEditGrootStickerBubbleShowKey = @"kAWENormalVideoEditGrootStickerBubbleShowKey";
NSString *const kAWENormalVideoEditKaraokeStickerBubbleShowKey = @"kAWENormalVideoEditKaraokeStickerBubbleShowKey";
NSString *const kAWENormalVideoEditClipAtShareToStorySceneBubbleShowKey = @"kAWENormalVideoEditClipAtShareToStorySceneBubbleShowKey";
NSString *const kAWENormalVideoEditNewYearWishBubbleShowKey = @"kAWENormalVideoEditNewYearWishesBubbleShowKey";

@interface ACCVideoEditTipsViewModel()
@end


@implementation ACCVideoEditTipsViewModel

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _isNormalVideoCanShowMusicStickerBubble = YES;
    }
    return self;
}

- (BOOL)allowShowLyricStickerBubble
{
    if (self.inputData.publishModel.repoImageAlbumInfo.isImageAlbumEdit) {
        return NO;
    }
    if (!self.isNormalVideoCanShowMusicStickerBubble || self.isVCAppeared || ![self.inputData.publishModel.repoSticker supportMusicLyricSticker]) {
        return NO;
    }
    
    BOOL hasMusicLyric = self.inputData.publishModel.repoMusic.music && self.inputData.publishModel.repoMusic.music.lyricUrl;
    NSString *cacheKey = hasMusicLyric ? kAWENormalVideoEditHasMusicLyricBubbleShowKey : kAWENormalVideoEditNoMusicLyricBubbleShowKey;
    NSInteger showBubbleCount = [ACCCache() integerForKey:cacheKey];
    //BOOL allowShowBubble = (showBubbleCount < 2);
    if (showBubbleCount) {
        return NO;
    }
    return YES;
}

#pragma mark 是否显示分享到日常场景剪裁 bubble
- (BOOL)allowShowClipAtShareToStorySceneBubble
{
    NSInteger maxDuration = ACCConfigInt(kConfigInt_enable_share_to_story_clip_default_duration_in_edit_page);
    BOOL enableDefaultClip = maxDuration > 0;
    if (ACCConfigBool(kConfigBool_enable_share_to_story_add_clip_capacity_in_edit_page) &&
        enableDefaultClip &&
        (self.inputData.publishModel.repoVideoInfo.canvasType == ACCVideoCanvasTypeShareAsStory ||
         self.inputData.publishModel.repoVideoInfo.canvasType == ACCVideoCanvasTypeMusicStory)) {
        AVAsset *avAsset = self.inputData.publishModel.repoVideoInfo.video.videoAssets.firstObject;
        CGFloat videoDuration = CMTimeGetSeconds(avAsset.duration);
        NSString *key = [NSString stringWithFormat:@"%@%@", kAWENormalVideoEditClipAtShareToStorySceneBubbleShowKey, [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) currentLoginUserModel].userID];
        NSInteger showBubbleCount = [ACCCache() integerForKey:key];
        return videoDuration > maxDuration && showBubbleCount < 1;
    }
    
    return NO;
}

@end
