//
//  ACCPOIStickerDataProvider.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/7/12.
//

#import "ACCPOIStickerDataProvider.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import "AWERepoStickerModel.h"
#import "AWERepoDraftModel.h"
#import "AWERepoTrackModel.h"
#import "AWERepoVideoInfoModel.h"
#import "AWERepoContextModel.h"

@implementation ACCPOIStickerDataProvider

- (NSString *)currentTaskId
{
    return self.repository.repoDraft.taskID;
}

- (NSString *)poiStickerFolderForDraft
{
    return [AWEDraftUtils generateDraftFolderFromTaskId:self.repository.repoDraft.taskID];
}

- (NSString *)poiStickerImagePathForDraft
{
    return [AWEDraftUtils generatePathFromTaskId:self.repository.repoDraft.taskID name:[AWEDraftUtils generateName:@"poi.png" withDraftTag:self.repository.repoDraft.tagForDraftFromBackEdit]];
}

- (BOOL)hasInfoStickerAddEdgeData
{
    return self.repository.repoVideoInfo.video.infoStickerAddEdgeData != nil;
}

- (NSArray<AWEInteractionStickerModel *> *)interactionStickers
{
    return self.repository.repoSticker.interactionStickers;
}

- (NSDictionary *)baseTrackData
{
    return @{
        @"enter_from" : @"video_edit_page",
        @"shoot_way"  : self.repository.repoTrack.referString ?: @"",
        @"creation_id": self.repository.repoContext.createId ?: @"",
        @"content_source" : self.repository.repoTrack.referExtra[@"content_source"] ?: @"",
        @"content_type" : self.repository.repoTrack.referExtra[@"content_type"] ?: @"",
    };
}

@end
