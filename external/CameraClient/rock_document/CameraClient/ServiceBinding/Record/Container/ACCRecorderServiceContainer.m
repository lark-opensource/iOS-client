//
//  ACCRecorderServiceContainer.m
//  Pods
//
//  Created by Liu Deping on 2020/6/8.
//

#import "ACCRecorderServiceContainer.h"
#import "ACCRecordFlowServiceImpl.h"
#import <CameraClient/ACCRecordViewControllerInputData.h>
#import <CameraClient/ACCJSRuntimeContext.h>

#import <CreationKitRTProtocol/ACCCameraService.h>
#import "ACCRecordSwitchModeServiceImpl.h"
#import "ACCRecordPropServiceImpl.h"
#import "ACCPropExploreServiceImpl.h"
#import "ACCRecognitionServiceImpl.h"
#import "ACCRecordConfigService.h"
#import "ACCRecordFrameSamplingServiceProtocol.h"
#import "ACCRecordModeFactory.h"
#import <CameraClient/ACCBeautyDataServiceImpl.h>
#import <CameraClient/ACCBeautyServiceImpl.h>
#import "ACCFilterDataServiceImpl.h"
#import "ACCFilterServiceImpl.h"
#import "ACCBeautyBuildInDataSourceImpl.h"
#import "ACCAudioPortServiceImpl.h"

#import "ACCRecorderServiceContainer.h"
#import "ACCRecordConfigServiceImpl.h"
#import "ACCRecordTrackServiceImpl.h"
#import "ACCRecordFrameSamplingServiceImpl.h"
#import "ACCCameraServiceNewImpls.h"

#import "ACCCameraFactoryImpls.h"
#import "ACCFilterWrapper.h"
#import "ACCEffectWrapper.h"
#import "ACCBeautyWrapper.h"
#import "ACCRecorderWrapper.h"
#import "ACCAlgorithmWrapper.h"
#import "ACCMessageWrapper.h"
#import "ACCCameraControlWrapper.h"
#import "ACCKaraokeWrapper.h"
#import "ACCFlowerServiceImpl.h"

#import <CreativeKit/ACCUIViewControllerProtocol.h>

@interface ACCRecorderServiceContainer ()

@property (nonatomic, weak, readwrite) id<ACCBusinessInputData> inputData;
@property (nonatomic, weak, readwrite) id<ACCUIViewControllerProtocol> viewController;

@end

@implementation ACCRecorderServiceContainer

- (instancetype)initWithParentContainer:(IESContainer *)container {
    self = [super initWithParentContainer:container];
    if (self) {
        [ACCJSRuntimeContext sharedInstance].recorderServiceProvider = self;
    }
    return self;
}

IESAutoInject(self, inputData, ACCBusinessInputData);
IESAutoInject(self, viewController, ACCUIViewControllerProtocol);

IESProvidesSingleton(ACCBeautyDataService)
{
    ACCBeautyDataServiceImpl *data = [[ACCBeautyDataServiceImpl alloc] initWithRepository:self.inputData.publishModel];
    return data;
}

IESProvidesSingleton(ACCBeautyService)
{
    ACCBeautyServiceImpl *beautyService = [[ACCBeautyServiceImpl alloc] init];
    beautyService.inputData = (ACCRecordViewControllerInputData *)self.inputData;
    beautyService.repository = self.inputData.publishModel;
    beautyService.serviceProvider = self;
    return beautyService;
}

IESProvidesSingleton(ACCBeautyBuildInDataSource)
{
    ACCBeautyBuildInDataSourceImpl *dataSource = [[ACCBeautyBuildInDataSourceImpl alloc] init];
    return dataSource;
}

IESProvidesSingleton(ACCFilterDataService)
{
    ACCFilterDataServiceImpl *data = [[ACCFilterDataServiceImpl alloc] initWithRepository:self.inputData.publishModel];
    return data;
}

IESProvidesSingleton(ACCRecordFlowService)
{
    NSAssert(self.inputData.publishModel != nil, @"PublishModel can not be nil");
    ACCRecordFlowServiceImpl *flow = [[ACCRecordFlowServiceImpl alloc] init];
    flow.cameraService = IESAutoInline(self, ACCCameraService);
    flow.recordConfigService = IESAutoInline(self, ACCRecordConfigService);
    flow.repository = self.inputData.publishModel;
    return flow;
}

IESProvidesSingleton(ACCRecordSwitchModeService)
{
    NSAssert(self.inputData != nil, @"InputData can not be nil");
    ACCRecordSwitchModeServiceImpl *switchMode = [[ACCRecordSwitchModeServiceImpl alloc] init];
    switchMode.repository = self.inputData.publishModel;
    switchMode.modeFactory = IESAutoInline(self, ACCRecordModeFactory);
    switchMode.configService = IESAutoInline(self, ACCRecordConfigService);
    switchMode.videoConfig = IESAutoInline(self, ACCVideoConfigProtocol);
    return switchMode;
}

IESProvidesSingleton(ACCFilterService, ACCFilterPrivateService)
{
    ACCFilterServiceImpl *filterService = [[ACCFilterServiceImpl alloc] init];
    filterService.inputData = (ACCRecordViewControllerInputData *)self.inputData;
    filterService.repository = self.inputData.publishModel;
    filterService.serviceProvider = self;
    return filterService;
}

IESProvidesSingleton(ACCRecordPropService)
{
    NSAssert(self.inputData != nil, @"InputData can not be nil");
    ACCRecordPropServiceImpl *prop = [[ACCRecordPropServiceImpl alloc] init];
    prop.cameraService = IESAutoInline(self, ACCCameraService);
    prop.recordConfigService = IESAutoInline(self, ACCRecordConfigService);
    prop.samplingService = IESAutoInline(self, ACCRecordFrameSamplingServiceProtocol);
    prop.repository = self.inputData.publishModel;
    return prop;
}

IESProvidesSingleton(ACCRecognitionService)
{
    return [[ACCRecognitionServiceImpl alloc] initWithInputData:(ACCRecordViewControllerInputData *)(self.inputData)];
}

IESProvidesSingleton(ACCFlowerService) {
    return [[ACCFlowerServiceImpl alloc] initWithInputData:(ACCRecordViewControllerInputData *)(self.inputData)];
}


IESProvidesSingleton(ACCPropExploreService)
{
    ACCPropExploreServiceImpl *explore = [[ACCPropExploreServiceImpl alloc] init];
    explore.serviceProvider = self;
    return explore;
}

IESProvidesSingleton(ACCAudioPortService)
{
    return [[ACCAudioPortServiceImpl alloc] init];
}

IESProvidesSingleton(ACCPublishRepository)
{
    NSAssert(self.inputData.publishModel != nil, @"PublishModel can not be nil");
    return self.inputData.publishModel;
}

IESProvidesSingleton(ACCRecordConfigService)
{
    NSAssert(self.inputData.publishModel != nil, @"PublishModel can not be nil");
    return [[ACCRecordConfigServiceImpl alloc] initWithPublishModel:self.inputData.publishModel];
}

IESProvidesSingleton(ACCRecordTrackService)
{
    NSAssert(self.inputData.publishModel != nil, @"PublishModel can not be nil");
    return [[ACCRecordTrackServiceImpl alloc] initWithPublishModel:self.inputData.publishModel];
}

IESProvidesSingleton(ACCRecordFrameSamplingServiceProtocol)
{
    NSAssert(self.inputData.publishModel != nil, @"PublishModel can not be nil");
    return [[ACCRecordFrameSamplingServiceImpl alloc] initWithPublishModel:self.inputData.publishModel];
}

#pragma mark - camera basic capability

IESProvidesSingleton(ACCCameraFactory)
{
    NSAssert(self.inputData != nil, @"InputData can not be nil");
    ACCCameraFactoryImpls *cameraFactory = [[ACCCameraFactoryImpls alloc] initWithInputData:(ACCRecordViewControllerInputData *)(self.inputData)];
    return cameraFactory;
}
IESProvidesSingleton(ACCCameraService)
{
    id<ACCCameraFactory> cameraFactory = IESAutoInline(self, ACCCameraFactory);
    ACCCameraServiceNewImpls *cameraService = [[ACCCameraServiceNewImpls alloc] init];
    cameraService.cameraFactory = cameraFactory;
    [cameraService configResolver:self];
    return cameraService;
}
IESProvidesSingleton(ACCCameraControlProtocol) {
    ACCCameraControlWrapper *wrapper = [ACCCameraControlWrapper new];
    id<ACCCameraFactory> cameraFactory = IESAutoInline(self, ACCCameraFactory);;
    [wrapper setCameraProvider:cameraFactory];
    return wrapper;
}
IESProvidesSingleton(ACCFilterProtocol) {
    ACCFilterWrapper *wrapper = [ACCFilterWrapper new];
    id<ACCCameraFactory> cameraFactory = IESAutoInline(self, ACCCameraFactory);;
    [wrapper setCameraProvider:cameraFactory];
    return wrapper;
}
IESProvidesSingleton(ACCEffectProtocol) {
    ACCEffectWrapper *wrapper = [ACCEffectWrapper new];
    id<ACCCameraFactory> cameraFactory = IESAutoInline(self, ACCCameraFactory);;
    [wrapper setCameraProvider:cameraFactory];
    return wrapper;
}
IESProvidesSingleton(ACCBeautyProtocol) {
    ACCBeautyWrapper *wrapper = [ACCBeautyWrapper new];
    id<ACCCameraFactory> cameraFactory = IESAutoInline(self, ACCCameraFactory);;
    [wrapper setCameraProvider:cameraFactory];
    return wrapper;
}
IESProvidesSingleton(ACCRecorderProtocol) {
    ACCRecorderWrapper *wrapper = [ACCRecorderWrapper new];
    id<ACCCameraFactory> cameraFactory = IESAutoInline(self, ACCCameraFactory);;
    [wrapper setCameraProvider:cameraFactory];
    return wrapper;
}
IESProvidesSingleton(ACCAlgorithmProtocol) {
    ACCAlgorithmWrapper *wrapper = [ACCAlgorithmWrapper new];
    id<ACCCameraFactory> cameraFactory = IESAutoInline(self, ACCCameraFactory);;
    [wrapper setCameraProvider:cameraFactory];
    return wrapper;
}
IESProvidesSingleton(ACCMessageProtocol) {
    ACCMessageWrapper *wrapper = [ACCMessageWrapper new];
    id<ACCCameraFactory> cameraFactory = IESAutoInline(self, ACCCameraFactory);;
    [wrapper setCameraProvider:cameraFactory];
    return wrapper;
}

IESProvidesSingleton(ACCKaraokeProtocol) {
    ACCKaraokeWrapper *wrapper = [[ACCKaraokeWrapper alloc] init];
    id<ACCCameraFactory> cameraFactory = IESAutoInline(self, ACCCameraFactory);;
    [wrapper setCameraProvider:cameraFactory];
    return wrapper;
}

@end
