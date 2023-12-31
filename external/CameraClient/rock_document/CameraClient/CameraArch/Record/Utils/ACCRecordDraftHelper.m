//
//  ACCRecordDraftHelper.m
//  Pods
//
//  Created by songxiangwu on 2019/8/16.
//

#import "ACCRecordDraftHelper.h"
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CameraClient/ACCDraftProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import "AWERepoVideoInfoModel.h"
#import <CameraClient/AWERepoDraftModel.h>
#import <CreationKitInfra/ACCLogProtocol.h>

@implementation ACCRecordDraftHelper

+ (void)saveBackupWithRepository:(AWEVideoPublishViewModel *)repository
{
    [ACCDraft() saveDraftWithPublishViewModel:repository
                                           video:repository.repoVideoInfo.video
                                          backup:!repository.repoDraft.originalDraft
                                      completion:^(BOOL success, NSError * _Nonnull error) {
        if ([error.domain isEqual:NSCocoaErrorDomain] && error.code == NSFileWriteOutOfSpaceError) {
            [ACCToast() show:ACCLocalizedString(@"disk_full", @"磁盘空间不足，请清理缓存后重试")];
            AWELogToolError(AWELogToolTagDraft, @"saveDraftWithPublishViewModel failed, error:%@", error);
        }
    }];
}

+ (void)saveBackupWithPublishModel:(AWEVideoPublishViewModel *)publishModel video:(ACCEditVideoData *)video
{
    [publishModel.repoVideoInfo updateVideoData:video]; //从发布界面返回后 model 持有的 videodata 将与 camera 所持有的不同。
    
    [ACCDraft() saveDraftWithPublishViewModel:publishModel
                                        video:publishModel.repoVideoInfo.video
                                       backup:!publishModel.repoDraft.originalDraft
                                   completion:^(BOOL success, NSError * _Nonnull error) {
        if ([error.domain isEqual:NSCocoaErrorDomain] && error.code == NSFileWriteOutOfSpaceError) {
            [ACCToast() show:ACCLocalizedString(@"disk_full", @"磁盘空间不足，请清理缓存后重试")];
        }
        
        if (error) {
            AWELogToolError2(@"backup", AWELogToolTagDraft, @"saveBackupWithPublishModel error: %@", error);
        }
    }];
}

@end
