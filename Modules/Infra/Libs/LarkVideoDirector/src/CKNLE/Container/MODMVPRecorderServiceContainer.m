//
//  MODMVPRecorderServiceContainer.m
//  DouYin
//
//  Created by liyingpeng on 2020/11/26.
//  Copyright © 2020 Bytedance. All rights reserved.
//

#import "MODMVPRecorderServiceContainer.h"
#import "MVPBaseServiceContainer.h"
#import <CreationKitRTProtocol/ACCCameraService.h>

#import "ACCRecorderServiceContainer.h"
#import <CameraClient/ACCRecordViewControllerInputData.h>
#import <CameraClient/ACCRecordFlowServiceImpl.h>
#import <CameraClient/ACCRecordConfigService.h>
#import <CameraClient/ACCRecordSwitchModeServiceImpl.h>
#import <CameraClient/ACCRecordPropServiceImpl.h>
#import <CameraClient/ACCRecordFrameSamplingServiceProtocol.h>
#import "MVPRecordModeFactoryImpl.h"
#import <CreativeKit/ACCRecorderViewContainer.h>
#import "MVPBarItemResourceConfigRecorderManagerImpl.h"
#import "MVPRecordFlowConfigProtocolImpl.h"
#import "MODStickerApplyHandlerTemplateImpl.h"
#import "MODRecorderBarItemSortDataSource.h"

#import <CameraClient/AWERecoderToolBarContainer.h>
#import <CameraClient/ACCRecorderViewContainerImpl.h>
#import <CreativeKit/ACCViewController.h>
#import <CameraClient/ACCCameraFactory.h>
#import <CameraClient/AWERecoderToolBarContainer.h>
#import <CameraClient/ACCRecorderViewContainerImpl.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>
#import <CameraClient/ACCToolBarContainerAdapter.h>
#import <CameraClient/ACCToolBarContainerPageEnum.h>
#import <CameraClient/ACCToolBarAdapterUtils.h>
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import <CreativeKit/ACCViewController.h>

#import <CreativeKit/ACCViewController.h>

#import "LVDRecordConfigService.h"

@implementation MODMVPRecorderServiceContainer

IESProvidesSingleton(ACCRecordFlowService)
{
    NSAssert(self.inputData.publishModel != nil, @"PublishModel can not be nil");
    ACCRecordFlowServiceImpl *flow = [[ACCRecordFlowServiceImpl alloc] init];
    flow.cameraService = [self resolveObject:@protocol(ACCCameraService)];
    flow.recordConfigService = [self resolveObject:@protocol(ACCRecordConfigService)];
    flow.repository = self.inputData.publishModel;
    return flow;
}

IESProvidesSingleton(ACCRecordSwitchModeService)
{
    NSAssert(self.inputData != nil, @"InputData can not be nil");
    ACCRecordSwitchModeServiceImpl *switchMode = [[ACCRecordSwitchModeServiceImpl alloc] init];
    switchMode.repository = self.inputData.publishModel;
    switchMode.modeFactory = [self resolveObject:@protocol(ACCRecordModeFactory)];
    switchMode.configService = [self resolveObject:@protocol(ACCRecordConfigService)];
    switchMode.videoConfig = [self resolveObject:@protocol(ACCVideoConfigProtocol)];
    return switchMode;
}

IESProvidesSingleton(ACCRecordPropService)
{
    NSAssert(self.inputData != nil, @"InputData can not be nil");
    ACCRecordPropServiceImpl *prop = [[ACCRecordPropServiceImpl alloc] init];
    prop.cameraService = [self resolveObject:@protocol(ACCCameraService)];
    prop.recordConfigService = [self resolveObject:@protocol(ACCRecordConfigService)];
    prop.samplingService = [self resolveObject:@protocol(ACCRecordFrameSamplingServiceProtocol)];
    prop.repository = self.inputData.publishModel;
    return prop;
}

IESProvidesSingleton(ACCRecorderViewContainer)
{
    NSAssert(self.viewController.view != nil, @"containerView can not be nil");

    ACCRecorderViewContainerImpl *viewContainer = [[ACCRecorderViewContainerImpl alloc] initWithRootView:self.viewController.view];
    id<ACCRecorderBarItemContainerView> barItemContainer = [[AWERecoderToolBarContainer alloc] initWithContentView:viewContainer.interactionView];
    barItemContainer.delegate = [MVPBaseServiceContainer sharedContainer];
    MODRecorderBarItemSortDataSource *sortDataSource = [[MODRecorderBarItemSortDataSource alloc] init];
        barItemContainer.sortDataSource = sortDataSource;
    [viewContainer injectBarItemContainer:barItemContainer];

    return viewContainer;
}

IESProvidesSingleton(ACCBarItemResourceConfigManagerProtocol)
{
    return [[MVPBarItemResourceConfigRecorderManagerImpl alloc] init];
}

IESProvides(ACCRecordFlowConfigProtocol)
{
    MVPRecordFlowConfigProtocolImpl *flowConfig = [[MVPRecordFlowConfigProtocolImpl alloc] init];
    return flowConfig;
}

IESProvidesSingleton(ACCRecordModeFactory)
{
    MVPRecordModeFactoryImpl *factory = [[MVPRecordModeFactoryImpl alloc] init];
    factory.repository = self.inputData.publishModel;
    return factory;
}

IESProvidesSingleton(ACCStickerApplyHandlerTemplate)
{
    return [[MODStickerApplyHandlerTemplateImpl alloc] init];
}

IESProvidesSingleton(ACCRecordConfigService)
{
    NSAssert(self.inputData.publishModel != nil, @"PublishModel can not be nil");
    return [[LVDRecordConfigService alloc] initWithPublishModel:self.inputData.publishModel];
}

@end
