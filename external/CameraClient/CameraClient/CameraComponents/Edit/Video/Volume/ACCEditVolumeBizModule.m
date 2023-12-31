//
//  ACCEditVolumeBizModule.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/9/18.
//

#import "ACCEditVolumeBizModule.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import "AWERepoVideoInfoModel.h"
#import "ACCRepoCanvasBusinessModel.h"
#import "AWERepoContextModel.h"
#import <IESInject/IESInjectDefines.h>
#import <CreativeKit/ACCBusinessConfiguration.h>

@interface ACCEditVolumeBizModule ()

@property (nonatomic, weak) id<IESServiceProvider> serviceProvider;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) AWEVideoPublishViewModel *repository;
@property (nonatomic, weak) id<ACCBusinessInputData> inputData;

@end

@implementation ACCEditVolumeBizModule
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, inputData, ACCBusinessInputData)

- (instancetype)initWithServiceProvider:(nonnull id<IESServiceProvider>)serviceProvider
{
    self = [super init];
    if (self) {
        _serviceProvider = serviceProvider;
    }
    return self;
}

- (void)setup
{
    if (self.repository.repoContext.videoType == AWEVideoTypeReplaceMusicVideo) {
        [self.editService.audioEffect setVolumeForVideo:0.0];
    }

    if (self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeShareAsStory) {
        if ([self.repository.repoCanvasBusiness.rePostMusicModel isOffLine]) {
            [self.editService.audioEffect setVolumeForVideo:0.0];
        } else {
            [self.editService.audioEffect setVolumeForVideo:1.0];
        }
    }
}

- (AWEVideoPublishViewModel *)repository
{
    return self.inputData.publishModel;
}

@end
