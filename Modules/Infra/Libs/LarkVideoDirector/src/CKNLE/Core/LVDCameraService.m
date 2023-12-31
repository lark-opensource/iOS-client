//
//  RecorderServiceContainer.m
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/1/18.
//

#import "LVDCameraService.h"

NSString * const ACCNewYearWishModuleLokiKey = @"newyearwishimages";
NSString * const kACCRecognitionDetectModeAnimal = @"3";

#import "CameraRecordController.h"
#import "CameraRecordConfig.h"
#import "NLEEditorManager.h"
#import "MVPBaseServiceContainer.h"
#import <AVFoundation/AVCaptureDevice.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>
#import <CameraClient/AWEEffectPlatformManager.h>
#import <CameraClient/AWERecordDefaultCameraPositionUtils.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/AWEStudioMeasureManager.h>
#import <TTVideoEditor/IESMMTrackerManager.h>
#import <TTVideoEditor/IESMMParamModule.h>
#import <TTVideoEditor/VEPreloadModule.h>
#import <TTVideoEditor/IESMMDeviceAuthor.h>
#import <AWELazyRegister/AWELazyRegisterPremain.h>
#import <AWELazyRegister/AWELazyRegister.h>
#import <CreationKitArch/AWEColorFilterDataManager.h>
#import <ReactiveObjC/NSObject+RACDeallocating.h>
#import <ReactiveObjC/RACSignal.h>
#import <CreationKitArch/AWEColorFilterDataManager.h>
#import <CreationKitArch/AWEEffectFilterDataManager.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreativeKit/ACCResourceHeaders.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import "LarkVideoDirector/LarkVideoDirector-Swift.h"

// 标记 VE 相机是否支持 1080P
static BOOL cameraPreviewUpTo1080P = YES;

@implementation LVDCameraService

+ (void)load
{
    [AWELazyRegister evaluateLazyRegisterForModule:@AWELazyRegisterModulePremain];
}

+ (BOOL)available {
    return true;
}

+ (void)setCameraSupport1080:(BOOL)support {
    cameraPreviewUpTo1080P = support;
}

+ (BOOL)cameraSupport1080 {
    return cameraPreviewUpTo1080P;
}

+ (UIViewController *)cameraControllerWith:(id<LVDCameraControllerDelegate>)delegate
                                cameraType:(LVDCameraType)type {
    return [LVDCameraService cameraControllerWith:delegate
                                       cameraType:type
                                   cameraPosition:AVCaptureDevicePositionUnspecified
                                 videoMaxDuration:0];
}

+ (UIViewController *)cameraControllerWith:(id<LVDCameraControllerDelegate>)delegate
                                cameraType:(LVDCameraType)type
                            cameraPosition:(AVCaptureDevicePosition)position
                          videoMaxDuration:(double)maxDuration {
    [LVDCameraMonitor logWithInfo:@"enter video camera" message:@""];
    [VideoEditorManagerBridge setupVideoEditorIfNeeded];
    [MVPBaseServiceContainer sharedContainer].cameraType = type;
    if (type == LVDCameraTypeOnlySupportPhoto) {
        [LVDCameraSession setCameraScene:LVDCameraSessionSceneCamera];
    } else {
        [LVDCameraSession setCameraScene:LVDCameraSessionSceneVideoRecord];
    }
    // iPad 默认支持更高品质画质同时判断 cameraPreviewUpTo1080P
    if (([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) || cameraPreviewUpTo1080P) {
        [IESMMParamModule sharedInstance].capturePreviewUpTo1080P = YES;
    } else {
        [IESMMParamModule sharedInstance].capturePreviewUpTo1080P = NO;
    }
    [self setupCameraClient];
    ACCRecordViewControllerInputData *input = [[ACCRecordViewControllerInputData alloc] init];
    if (position != AVCaptureDevicePositionUnspecified) {
        input.cameraPosition = position;
    } else {
        NSNumber *storedKey = [ACCCache() objectForKey:HTSVideoDefaultDevicePostionKey];
        if (storedKey == nil) {
            input.cameraPosition = AVCaptureDevicePositionBack;
        }
    }
    input.publishModel = [[AWEVideoPublishViewModel alloc] init];
    // 暂时没看到其他使用这个属性的地方，借用来存自定义时长
    input.publishModel.repoContext.maxDuration = maxDuration;
    CameraRecordConfig *config = [[CameraRecordConfig alloc] initWithInputData:input];
    CameraRecordController *vc = [[CameraRecordController alloc] initWithBusinessConfiguration:config];
    vc.delegate = delegate;
    [vc.rac_willDeallocSignal subscribeCompleted:^{
        // 监听相机页面释放
        [LVDCameraSession deactiveIfNeededWith:AVAudioSessionCategoryPlayAndRecord];
        [LVDCameraMonitor endCameraPowerMonitor];
    }];
    [LVDCameraMonitor startCameraPowerMonitor];
    [LVDCameraMonitor startCamera];
    [self setupVECameraSession];
    return vc;
}

+ (UIViewController *)videoEditorControllerWith:(id<LVDVideoEditorControllerDelegate>)delegate
                                         assets:(NSArray<AVAsset *>*)assets
                                           from:(UIViewController*)vc {
    [LVDCameraMonitor logWithInfo:@"enter video editor vc" message:[[NSString alloc] initWithFormat:@" %d assets", [assets count]]];
    [self setupCameraClient];
    [MVPBaseServiceContainer sharedContainer].editorDelegate = delegate;
    [MVPBaseServiceContainer sharedContainer].inCamera = NO;
    [LVDCameraSession setCameraScene:LVDCameraSessionSceneEditor];
    [self setupVECameraSession];
    [LVDCameraSession setCategory:AVAudioSessionCategoryPlayback options:0];
    [LVDCameraSession setActive:YES];
    UIViewController *controller = [NLEEditorManager createDVEViewControllerWithAssets:assets from:vc];
    return controller;
}

+(void)setupCameraClient {
    [AWEEffectPlatformManager configEffectPlatform];
    [[AWEStudioMeasureManager sharedMeasureManager] asyncOperationBlock:^{
        [VEPreloadModule prepareVEContext];
        [VEPreloadModule setEffectAPIUsingAsync];
        [EffectPlatform cachedEffectsOfPanel:@"beautifynew" category:@"all"];
        [EffectPlatform cachedEffectsOfPanel:@"colorfilternew"];
        [EffectPlatform cachedEffectsOfPanel: @"sticker"];
    }];

    [[AWEColorFilterDataManager defaultManager] injectBuildInFilterArrayBlock:^NSArray<IESEffectModel *> *{
            NSMutableArray *effectArray = @[].mutableCopy;
            NSString *normalResource = [NSString acc_strValueWithName:AWEColorFilterBiltinResourceName];
            NSString *filterBundlePath = [NSString acc_bundlePathWithName:@"Filter"];
            NSArray *effectDic = @[@{@"effectName":ACCLocalizedString(@"filter_local_normal", @"normal"),
                                     @"effectIdentifier":@"100",
                                     @"sourceIdentifier":@"100",
                                     @"resourceId": @"100",
                                     @"builtinIcon":[[filterBundlePath stringByAppendingPathComponent:normalResource] stringByAppendingPathComponent:@"thumbnail.jpg"],
                                     @"builtinResource":[filterBundlePath stringByAppendingPathComponent:normalResource],
                                     @"types":@[@"cfilter"],
                                     @"tags":@[@"pinyin:normal",@"normal"],
                                     @"effectNameEn":@"Normal",
                                     @"isBuildin" : @(YES),
                                     @"extra": @"{\"filterconfig\":\"{\\\"items\\\":[{\\\"min\\\":0,\\\"max\\\":100,\\\"value\\\":38,\\\"tag\\\":\\\"Filter_intensity\\\",\\\"name\\\":\\\"Filter_intensity\\\"}]}\"}",
                                     },
                                   ];

            for (NSDictionary *dic in effectDic) {
                NSError *error = nil;
                IESEffectModel *effect = [[IESEffectModel alloc] initWithDictionary:dic error:&error];
                if (error) {
//                    AWELogToolError(AWELogToolTagRecord, @"json convert to IESEffectModel error: %@", error);
                }
                if (effect) {
                    [effectArray addObject:effect];
                }
            }

            return effectArray;
        }];

    [[AWEColorFilterDataManager defaultManager] updatePanelName: @"filter"];
}

+(void)setupVECameraSession {
    [IESMMDeviceAuthor setExternalSettingBlock:^BOOL(AVAudioSession *audioSession, AVAudioSessionCategory category, AVAudioSessionCategoryOptions option, NSError *__autoreleasing *error) {
        [LVDCameraSession setCategory:category options:option];
        return YES;
    } activeBlock:^BOOL(AVAudioSession *audioSession, BOOL active, AVAudioSessionSetActiveOptions option, NSError *__autoreleasing *error) {
        [LVDCameraSession setActive:active options:option];
        return YES;
    } noOptionActiveBlock:^BOOL(AVAudioSession *audioSession, BOOL active, NSError *__autoreleasing *error) {
        [LVDCameraSession setActive:active];
        return YES;
    } port:^BOOL(AVAudioSession *audioSession, AVAudioSessionPortOverride port, NSError *__autoreleasing *error) {
        // 默认不 override output port
        return YES;
    }];
}

@end
