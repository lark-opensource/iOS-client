//
//  ACCNLEEditServiceContainer.m
//  Pods
//
//  Created by Liu Deping on 2020/6/11.
//

#import "ACCNLEEditServiceContainer.h"
#import "ACCEditViewControllerInputData.h"
#import "ACCEditorDraftServiceImpl.h"
#import "ACCEditCanvasWrapper.h"
#import "ACCEditPlayerMonitorService.h"
#import "ACCEditCaptureFrameWrapper.h"

// NLE
#import "ACCNLEEditService.h"
#import "ACCNLEEditorBuilder.h"
#import "ACCNLEEditStickerWrapper.h"
#import "ACCNLEEditFilterWrapper.h"
#import "ACCNLEEditSpecialEffectWrapper.h"
#import "ACCNLEEditPreviewWrapper.h"
#import "ACCNLEEditHDRWrapper.h"
#import "ACCNLEEditBeautyWrapper.h"
#import "ACCNLEEditCanvasWrapper.h"
#import "ACCNLEEditAudioEffectWrapper.h"
#import "ACCNLEEditCaptureFrameWrapper.h"
#import "ACCNLEEditMultiTrackWrapper.h"

#import "ACCNLEEditSmartMovieWrapper.h"
#import <CreativeKit/ACCUIViewControllerProtocol.h>

@interface ACCNLEEditServiceContainer ()

@property (nonatomic, weak, readwrite) id<ACCBusinessInputData> inputData;
@property (nonatomic, weak, readwrite) id<ACCUIViewControllerProtocol> viewController;

@end

@implementation ACCNLEEditServiceContainer

IESAutoInject(self, inputData, ACCBusinessInputData);
IESAutoInject(self, viewController, ACCUIViewControllerProtocol);

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
    ACCNLEEditorBuilder *editSessionBuilder = [[ACCNLEEditorBuilder alloc] initWithPublishModel:self.inputData.publishModel];
    [editSessionBuilder configResolver:self];
    return editSessionBuilder;
}

IESProvidesSingleton(ACCEditServiceProtocol)
{
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    ACCNLEEditService *editService = [[ACCNLEEditService alloc] init];
    editService.editBuilder = editSessionBuilder;
    [editService configResolver:self];
    return editService;
}

IESProvidesSingleton(ACCEditFilterProtocol)
{
    ACCNLEEditFilterWrapper *wrapper = [[ACCNLEEditFilterWrapper alloc] init];
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    [wrapper setEditSessionProvider:editSessionBuilder];
    return wrapper;
}

IESProvidesSingleton(ACCEditBeautyProtocol)
{
    ACCNLEEditBeautyWrapper *wrapper = [[ACCNLEEditBeautyWrapper alloc] init];
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    [wrapper setEditSessionProvider:editSessionBuilder];
    return wrapper;
}

IESProvidesSingleton(ACCEditPreviewProtocol)
{
    ACCNLEEditPreviewWrapper *wrapper = [[ACCNLEEditPreviewWrapper alloc] init];
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    [wrapper setEditSessionProvider:editSessionBuilder];
    return wrapper;
}

IESProvidesSingleton(ACCEditStickerProtocol)
{
    ACCNLEEditStickerWrapper *wrapper = [ACCNLEEditStickerWrapper new];
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    [wrapper setEditSessionProvider:editSessionBuilder];
    return wrapper;
}

IESProvidesSingleton(ACCEditCanvasProtocol)
{
    ACCNLEEditCanvasWrapper *wrapper = [[ACCNLEEditCanvasWrapper alloc] initWithPublishModel:self.inputData.publishModel];
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    [wrapper setEditSessionProvider:editSessionBuilder];
    return wrapper;
}

IESProvidesSingleton(ACCEditHDRProtocol)
{
    ACCNLEEditHDRWrapper *wrapper = [[ACCNLEEditHDRWrapper alloc] init];
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    [wrapper setEditSessionProvider:editSessionBuilder];
    return wrapper;
}

IESProvidesSingleton(ACCEditAudioEffectProtocol)
{
    ACCNLEEditAudioEffectWrapper *wrapper = [[ACCNLEEditAudioEffectWrapper alloc] init];
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    [wrapper setEditSessionProvider:editSessionBuilder];
    return wrapper;
}

IESProvidesSingleton(ACCEditEffectProtocol)
{
    ACCNLEEditSpecialEffectWrapper *wrapper = [[ACCNLEEditSpecialEffectWrapper alloc] init];
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    [wrapper setEditSessionProvider:editSessionBuilder];
    return wrapper;
}

IESProvidesSingleton(ACCEditCaptureFrameProtocol)
{
    ACCNLEEditCaptureFrameWrapper *wrapper = [[ACCNLEEditCaptureFrameWrapper alloc] init];
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
    ACCNLEEditMultiTrackWrapper *wrapper = [[ACCNLEEditMultiTrackWrapper alloc] init];
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = IESAutoInline(self, ACCEditSessionBuilderProtocol);
    [wrapper setEditSessionProvider:editSessionBuilder];
    return wrapper;
}

IESProvidesSingleton(ACCEditSmartMovieProtocol)
{
    ACCNLEEditSmartMovieWrapper *wrapper = [[ACCNLEEditSmartMovieWrapper alloc] init];
    id<ACCEditSessionBuilderProtocol> editSessionBuilder = [self resolveObject:@protocol(ACCEditSessionBuilderProtocol)];
    [wrapper setEditSessionProvider:editSessionBuilder];
    return wrapper;
}

@end
