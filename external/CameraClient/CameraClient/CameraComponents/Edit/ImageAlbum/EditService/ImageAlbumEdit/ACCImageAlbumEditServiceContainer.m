//
//  ACCImageAlbumEditServiceContainer.m
//  CameraClient-Pods-Aweme
//
//  Created by Howie He on 2021/3/10.
//

#import "ACCImageAlbumEditServiceContainer.h"
#import "ACCEditViewControllerInputData.h"

#import "ACCImageAlbumEditService.h"
#import "ACCRepoImageAlbumInfoModel.h"
#import "ACCImageAlbumEditSessionBuilder.h"
#import "ACCEditImageAlbumMixedWraper.h"
#import "ACCImageAlbumEditFilterWraper.h"
#import "ACCImageAlbumEditHDRWraper.h"
#import "ACCImageAlbumEditStickerWraper.h"
#import "ACCEditImageAlbumCaptureFrameWraper.h"
#import "ACCRepoImageAlbumInfoModel.h"

#import "ACCRepoImageAlbumInfoModel.h"
#import <CreativeKit/ACCUIViewControllerProtocol.h>
#import <CreativeKit/ACCBusinessConfiguration.h>

@interface ACCImageAlbumEditServiceContainer ()

@property (nonatomic, weak, readwrite) id<ACCBusinessInputData> inputData;
@property (nonatomic, weak, readwrite) id<ACCUIViewControllerProtocol> viewController;

@end

@implementation ACCImageAlbumEditServiceContainer

IESAutoInject(self, inputData, ACCBusinessInputData);
IESAutoInject(self, viewController, ACCUIViewControllerProtocol);

IESProvidesSingleton(ACCEditFilterProtocol)
{
    ACCImageAlbumEditFilterWraper *wrapper = [[ACCImageAlbumEditFilterWraper alloc] init];
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    [wrapper setEditSessionProvider:editSessionBuilder];
    return wrapper;
}

IESProvidesSingleton(ACCEditStickerProtocol)
{
    ACCImageAlbumEditStickerWraper *wrapper = [[ACCImageAlbumEditStickerWraper alloc] init];
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    [wrapper setEditSessionProvider:editSessionBuilder];
    return wrapper;
}

IESProvidesSingleton(ACCEditSessionBuilderProtocol)
{
    NSAssert(self.inputData.publishModel != nil, @"PublishModel can not be nil");
    return [[ACCImageAlbumEditSessionBuilder alloc] initWithInputData:self.inputData];
}

IESProvidesSingleton(ACCEditServiceProtocol)
{
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);

    ACCImageAlbumEditService *editService = [[ACCImageAlbumEditService alloc] init];
    editService.editBuilder = editSessionBuilder;
    [editService configResolver:self];
    return editService;
}

IESProvidesSingleton(ACCImageEditHDRProtocol)
{
    ACCImageAlbumEditHDRWraper *wrapper = [[ACCImageAlbumEditHDRWraper alloc] init];
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    [wrapper setEditSessionProvider:editSessionBuilder];
    return wrapper;
}

IESProvidesSingleton(ACCEditCaptureFrameProtocol)
{
    ACCEditImageAlbumCaptureFrameWraper *wrapper = [[ACCEditImageAlbumCaptureFrameWraper alloc] init];
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    [wrapper setEditSessionProvider:editSessionBuilder];
    return wrapper;
}

IESProvidesSingleton(ACCEditImageAlbumMixedProtocol)
{
    if (!self.inputData.publishModel.repoImageAlbumInfo.isImageAlbumEdit) {
        //直接把判断条件写在NSAssert中会导致ACCRepoImageAlbumInfoModel头文件引用静态检测不通过
        NSAssert(NO, @"unsupported for video edit mode");
    }
    
    ACCEditImageAlbumMixedWraper *wrapper = [[ACCEditImageAlbumMixedWraper alloc] init];
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    [wrapper setEditSessionProvider:editSessionBuilder];
    return wrapper;
}

@end
