//
//  ACCPhotoToVideoViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by 李辉 on 2020/4/14.
//

#import "ACCPhotoToVideoViewModel.h"

#import "ACCMVTemplateManagerProtocol.h"
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitArch/ACCRepoPublishConfigModel.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreationKitArch/ACCRepoStickerModel.h>

@interface ACCPhotoToVideoViewModel ()

@property (nonatomic, strong) id<ACCMVTemplateManagerProtocol> mvTemplateManager;

@end

@implementation ACCPhotoToVideoViewModel

#pragma mark - download music list

- (void)exportMVVideoWithPublishModel:(AWEVideoPublishViewModel *)publishModel failedBlock:(void(^)(void))failedBlock
{
    if (self.mvTemplateManager) {
        self.mvTemplateManager = nil;
    }
    self.mvTemplateManager = IESAutoInline(ACCBaseServiceProvider(), ACCMVTemplateManagerProtocol);
    AWEVideoPublishViewModel *model = publishModel.copy;
    model.repoPublishConfig.coverImage = nil;
    model.repoSticker.interactionStickers = nil;
    model.repoSticker.infoStickerArray = [NSMutableArray array];
    [self.mvTemplateManager configPublishModel:model];
    [self.mvTemplateManager exportMVVideoWithImage:publishModel.repoUploadInfo.toBeUploadedImage doneBlock:nil failedBlock:failedBlock];
}

@end
