//
//  ACCSocialStickerDataProvider.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/7/12.
//

#import "ACCSocialStickerDataProvider.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import "AWERepoStickerModel.h"
#import "AWERepoDraftModel.h"

@implementation ACCSocialStickerDataProvider

- (NSString *)socialStickerImagePathForDraftWithIndex:(NSInteger)index {
    return [AWEDraftUtils generateModernSocialPathFromTaskId:self.repository.repoDraft.taskID index:index];
}

- (NSArray<AWEInteractionStickerModel *> *)interactionStickers
{
    return self.repository.repoSticker.interactionStickers;
}

@end
