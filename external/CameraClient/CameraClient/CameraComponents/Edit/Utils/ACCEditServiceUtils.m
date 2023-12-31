//
//  ACCEditServiceUtils.m
//  CameraClient-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2021/1/28.
//

#import "ACCEditServiceUtils.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "AWERepoVideoInfoModel.h"
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>

#import "ACCEditServiceImpls.h"
#import "ACCEditSessionBuilderImpls.h"
#import "ACCEditSessionBuilder.h"
#import "ACCNLEPublishEditService.h"
#import "ACCNLEPublishEditorBuilder.h"
#import "ACCNLEEditorBuilder.h"
#import "ACCImageAlbumEditService.h"
#import "ACCImageAlbumEditSessionBuilder.h"
#import "ACCNLEUtils.h"
#import "ACCRepoImageAlbumInfoModel.h"
#import "ACCEditSessionConfigBuilder.h"

@implementation ACCEditServiceUtils

+ (id<ACCEditServiceProtocol>)editServiceOnlyForPublishWithPublishModel:(AWEVideoPublishViewModel *)publishModel
                                                                   isMV:(BOOL)isMV
{
    id<ACCEditServiceProtocol> editService = nil;
    if (publishModel.repoImageAlbumInfo.isImageAlbumEdit) {
        editService = [[ACCImageAlbumEditService alloc] initForPublish];
        editService.editBuilder = [[ACCImageAlbumEditSessionBuilder alloc] initWithPublishModel:publishModel];
    } else if ([ACCNLEUtils creativePolicyWithRepository:publishModel] == ACCCreativePolicyNLE) {
        VEEditorSessionConfig *config = [self p_publishConfigWithIsMV:isMV publishModel:publishModel];
        [ACCNLEUtils createNLEVideoData:publishModel config:config moveResource:YES needCommit:NO completion:nil];
        editService = [[ACCNLEPublishEditService alloc] initWithPublishModel:publishModel];
        editService.editBuilder = [[ACCNLEPublishEditorBuilder alloc] initWithPublishModel:publishModel];
    } else {
        editService = [[ACCEditServiceImpls alloc] init];
        editService.editBuilder = [[ACCEditSessionBuilderImpls alloc] initWithPublishModel:publishModel isMV:isMV];
    }
    return editService;
}

+ (id<ACCEditServiceProtocol>)editServiceForPublishTaskWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    id<ACCEditServiceProtocol> editService = nil;
    if (publishModel.repoImageAlbumInfo.isImageAlbumEdit) {
        editService = [[ACCImageAlbumEditService alloc] initForPublish];
        editService.editBuilder = [[ACCImageAlbumEditSessionBuilder alloc] initWithPublishModel:publishModel];
    } else if ([ACCNLEUtils creativePolicyWithRepository:publishModel] == ACCCreativePolicyNLE) {
        [ACCNLEUtils createNLEVideoData:publishModel config:nil moveResource:YES needCommit:NO completion:nil];
        editService = [[ACCNLEPublishEditService alloc] initWithPublishModel:publishModel];
        editService.editBuilder = [[ACCNLEEditorBuilder alloc] initWithPublishModel:publishModel];
    } else {
        editService = [[ACCEditServiceImpls alloc] init];
        editService.editBuilder = [[ACCEditSessionBuilder alloc] initWithPublishModel:publishModel];
    }
    return editService;
}

+ (VEEditorSessionConfig *)p_publishConfigWithIsMV:(BOOL)isMV
                                      publishModel:(AWEVideoPublishViewModel *)publishModel
{
    VEEditorSessionConfig *config = nil;
    if (isMV) {
        config = [ACCEditSessionConfigBuilder mvEditorSessionConfigWithPublishModel:publishModel];
    } else {
        config = [ACCEditSessionConfigBuilder publishEditorSessionConfigWithPublishModel:publishModel];
    }
    return config;
}

+ (void)dismissPreviewEdge:(id<ACCEditServiceProtocol>)editService
              publishModel:(AWEVideoPublishViewModel *)publishModel
{
    //remove if needs
    BOOL isAllStickersInPlayer = [publishModel.repoUploadInfo.extraDict[@"isAllStickersInPlayer"] boolValue];
    BOOL hasLyricSticker = [self hasLyricSticker:publishModel];
    if (isAllStickersInPlayer && !hasLyricSticker) {
        [editService.mediaContainerView updateOriginalFrameWithSize:editService.mediaContainerView.containerSize];
        publishModel.repoVideoInfo.playerFrame = editService.mediaContainerView.originalPlayerFrame;
        editService.preview.previewEdge = nil;
    }
}

+ (BOOL)hasLyricSticker:(AWEVideoPublishViewModel *)publishModel
{
    return [publishModel.repoVideoInfo.video.infoStickers btd_contains:^BOOL(IESInfoSticker * _Nonnull obj) {
        return obj.isSrtInfoSticker;
    }];
}

@end
