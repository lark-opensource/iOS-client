//
//  ACCEditServiceContainer.m
//  Pods
//
//  Created by Liu Deping on 2020/6/11.
//

#import "ACCEditServiceContainer.h"
#import "ACCEditViewControllerInputData.h"
#import "ACCEditorDraftServiceImpl.h"
#import "ACCEditService.h"
#import "ACCEditSessionBuilder.h"
#import "ACCEditFilterWraper.h"
#import "ACCEditBeautyWrapper.h"
#import "ACCEditPreviewWraper.h"
#import "ACCEditStickerWraper.h"
#import "ACCEditCanvasWrapper.h"
#import "ACCEditHDRWraper.h"
#import "ACCEditAudioEffectWraper.h"
#import "ACCEditEffectWraper.h"
#import "ACCEditPlayerMonitorService.h"
#import "ACCEditCaptureFrameWrapper.h"
#import <CameraClient/ACCEditSmartMovieProtocol.h>


@interface ACCEditServiceContainer ()

@end

@implementation ACCEditServiceContainer

IESProvidesSingleton(ACCPublishRepository)
{
    NSAssert(self.inputData.publishModel != nil, @"PublishModel can not be nil");
    return self.inputData.publishModel;
}

IESProvidesSingleton(ACCEditorDraftService)
{
    NSAssert(self.inputData != nil, @"inputData can not be nil");
    ACCEditorDraftServiceImpl *draftService = [[ACCEditorDraftServiceImpl alloc] initWithPublishModel:self.inputData.publishModel];
    return draftService;
}

IESProvidesSingleton(ACCEditSessionBuilderProtocol)
{
    NSAssert(self.inputData.publishModel != nil, @"PublishModel can not be nil");

    ACCEditSessionBuilder *editSessionBuilder = [[ACCEditSessionBuilder alloc] initWithPublishModel:self.inputData.publishModel];
    [editSessionBuilder configResolver:self];
    return editSessionBuilder;
}

IESProvidesSingleton(ACCEditServiceProtocol)
{
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    
    ACCEditService *editService = [[ACCEditService alloc] init];
    editService.editBuilder = editSessionBuilder;
    [editService configResolver:self];
    return editService;
}

IESProvidesSingleton(ACCEditFilterProtocol)
{
    ACCEditFilterWraper *wrapper = [[ACCEditFilterWraper alloc] init];
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    [wrapper setEditSessionProvider:editSessionBuilder];
    return wrapper;
}

IESProvidesSingleton(ACCEditBeautyProtocol)
{
    ACCEditBeautyWrapper *wrapper = [[ACCEditBeautyWrapper alloc] init];
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    [wrapper setEditSessionProvider:editSessionBuilder];
    return wrapper;
}

IESProvidesSingleton(ACCEditPreviewProtocol)
{
    ACCEditPreviewWraper *wrapper = [[ACCEditPreviewWraper alloc] init];
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    [wrapper setEditSessionProvider:editSessionBuilder];
    return wrapper;
}

IESProvidesSingleton(ACCEditStickerProtocol)
{
    ACCEditStickerWraper *wrapper = [[ACCEditStickerWraper alloc] init];
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    [wrapper setEditSessionProvider:editSessionBuilder];
    return wrapper;
}

IESProvidesSingleton(ACCEditCanvasProtocol)
{
    ACCEditCanvasWrapper *wrapper = [[ACCEditCanvasWrapper alloc] initWithPublishModel:self.inputData.publishModel];
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    [wrapper setEditSessionProvider:editSessionBuilder];
    return wrapper;
}

IESProvidesSingleton(ACCEditHDRProtocol)
{
    ACCEditHDRWraper *wrapper = [[ACCEditHDRWraper alloc] init];
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    [wrapper setEditSessionProvider:editSessionBuilder];
    return wrapper;
}

IESProvidesSingleton(ACCEditAudioEffectProtocol)
{
    ACCEditAudioEffectWraper *wrapper = [[ACCEditAudioEffectWraper alloc] init];
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    [wrapper setEditSessionProvider:editSessionBuilder];
    return wrapper;
}

IESProvidesSingleton(ACCEditEffectProtocol)
{
    ACCEditEffectWraper *wrapper = [[ACCEditEffectWraper alloc] init];
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    [wrapper setEditSessionProvider:editSessionBuilder];
    return wrapper;
}

IESProvidesSingleton(ACCEditCaptureFrameProtocol)
{
    ACCEditCaptureFrameWrapper *wrapper = [[ACCEditCaptureFrameWrapper alloc] init];
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    [wrapper setEditSessionProvider:editSessionBuilder];
    return wrapper;
}

IESProvidesSingleton(ACCEditPlayerMonitorProtocol)
{
    ACCEditPlayerMonitorService *wrapper = [[ACCEditPlayerMonitorService alloc] init];
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    [wrapper setEditSessionProvider:editSessionBuilder];
    return wrapper;
}

IESProvidesSingleton(ACCEditMultiTrackProtocol)
{
    return nil; // VESDK 不实现支持多轨编辑
}

IESProvidesSingleton(ACCEditSmartMovieProtocol)
{
    // SmartMovieEditService is nil when not using nle for edit
    return nil;
}

@end
