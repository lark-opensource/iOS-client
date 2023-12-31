//
//  ACCRecorderServiceContainer.m
//  Pods
//
//  Created by Liu Deping on 2020/6/8.
//  Note: MODCameraFactoryImpls & MODCameraControlWrapper inside, do not copy directly!

#import "ACCRecorderServiceContainer.h"
#import <CameraClient/ACCRecordViewControllerInputData.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CameraClient/ACCRecordPropServiceImpl.h>
#import <CameraClient/ACCRecordConfigService.h>
#import <CameraClient/ACCRecordFrameSamplingServiceProtocol.h>
#import <CameraClient/ACCRecordModeFactory.h>
#import <CameraClient/ACCBeautyDataServiceImpl.h>
#import <CameraClient/ACCBeautyServiceImpl.h>
#import <CameraClient/ACCFilterDataServiceImpl.h>
#import <CameraClient/ACCFilterServiceImpl.h>
#import <CameraClient/ACCBeautyBuildInDataSourceImpl.h>
#import <CameraClient/ACCRecordFlowService.h>
#import "ACCRecorderServiceContainer.h"
#import <CameraClient/ACCRecordConfigServiceImpl.h>
#import <CameraClient/ACCRecordTrackServiceImpl.h>
#import <CameraClient/ACCRecordFrameSamplingServiceImpl.h>
#import <CameraClient/ACCCameraServiceNewImpls.h>

#import <CameraClient/ACCCameraFactoryImpls.h>
#import <CameraClient/ACCFilterWrapper.h>
#import <CameraClient/ACCEffectWrapper.h>
#import <CameraClient/ACCBeautyWrapper.h>
#import <CameraClient/ACCRecorderWrapper.h>
#import <CameraClient/ACCAlgorithmWrapper.h>
#import <CameraClient/ACCMessageWrapper.h>
#import <CameraClient/ACCCameraControlWrapper.h>
#import <CameraClient/ACCKaraokeWrapper.h>

#import <CreativeKit/ACCViewController.h>
#import <CameraClient/ACCRecordFlowServiceImpl.h>
#import <CameraClient/ACCRecordSwitchModeServiceImpl.h>
#import <CameraClient/ACCRecordSwitchModeServiceImpl.h>

#import <CameraClient/ACCRecordSwitchModeServiceImpl.h>
#import "LarkVideoDirector/LarkVideoDirector-Swift.h"

#import "MVPBeautyBuildInDataSourceImpl.h"
#import <TTVideoEditor/VERecorder.h>
#import "LVDCameraService.h"

@interface ACCCameraFactoryImpls()
- (IESMMCameraConfig *)cameraConfigWithInputData:(ACCRecordViewControllerInputData *)inputData;
@end

/// 自定义 CameraFactory
@interface MODCameraFactoryImpls : ACCCameraFactoryImpls

@end

@interface MODCameraFactoryImpls ()
@end

@implementation MODCameraFactoryImpls

- (IESMMCameraConfig *)cameraConfigWithInputData:(ACCRecordViewControllerInputData *)inputData
{
    IESMMCameraConfig* config = [super cameraConfigWithInputData:inputData];
    IESMMCaptureRatio captureRatio = IESMMCaptureRatio16_9;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        captureRatio = IESMMCaptureRatio4_3;
    }
    config.captureRatio = captureRatio;
    config.useSystemDetect = YES; // 使用系统检测降低功耗
    if (([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) || [LVDCameraService cameraSupport1080]) {
        config.capturePreset = AVCaptureSessionPreset1920x1080;
    }
    return config;
}
@end

/// 自定义相机控制器
@interface MODCameraControlWrapper : ACCCameraControlWrapper

@end

@interface MODCameraControlWrapper ()
@end

@implementation MODCameraControlWrapper

- (void)resetCapturePreferredSize:(CGSize)size then:(void (^_Nullable)(void))then {
    id<VERecorderPublicProtocol> camera = [self valueForKey: @"camera"];

    if ([camera conformsToProtocol:@protocol(VERecorderPublicProtocol)]) {
        // 指定 capturePreset 和 IESMMCaptureRatio 确保不会被内部逻辑修改
        AVCaptureSessionPreset capturePreset = camera.config.capturePreset;
        IESMMCaptureRatio captureRatio = camera.captureRatio;
        [camera resetCaptureRatio:captureRatio preferredPreset:capturePreset previewSize:size outputSize:size then:then];
    } else {
        [super resetCapturePreferredSize:size then:then];
    }
}
@end

@interface ACCRecorderServiceContainer ()

@property (nonatomic, weak, readwrite) id<ACCBusinessInputData> inputData;
@property (nonatomic, weak, readwrite) id<ACCViewController> viewController;

@end

@implementation ACCRecorderServiceContainer

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
    MVPBeautyBuildInDataSourceImpl *dataSource = [[MVPBeautyBuildInDataSourceImpl alloc] init];
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
    MODCameraFactoryImpls *cameraFactory = [[MODCameraFactoryImpls alloc] initWithInputData:(ACCRecordViewControllerInputData *)(self.inputData)];
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
    MODCameraControlWrapper *wrapper = [MODCameraControlWrapper new];
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
