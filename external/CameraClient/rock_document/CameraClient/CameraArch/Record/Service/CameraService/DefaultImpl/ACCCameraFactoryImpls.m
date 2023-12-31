//
//  ACCCameraFactoryImpls.m
//  Pods
//
//  Created by liyingpeng on 2020/7/6.
//

#import "ACCCameraFactoryImpls.h"
#import "ACCEditVideoDataDowngrading.h"
#import <TTVideoEditor/IESMMParamModule.h>
#import <TTVideoEditor/VERecorder.h>

#import <CreativeKit/ACCCacheProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import "AWERecordDefaultCameraPositionUtils.h"
#import <CreativeKit/ACCMonitorProtocol.h>
#import "AWECameraPreviewContainerView.h"
#import "AWEVideoRecordOutputParameter.h"
#import "ACCConfigKeyDefines.h"
#import "ACCFeedbackProtocol.h"
#import <CreationKitInfra/ACCI18NConfigProtocol.h>
#import "AWERecordFirstFrameTrackerNew.h"
#import "AWE2DStickerTextGenerator.h"
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import "AWERepoVideoInfoModel.h"
#import "ACCConfigKeyDefines.h"
#import "ACCRepoRearResourceModel.h"
#import "UIDevice+ACCAdditions.h"

@interface ACCCameraFactoryImpls ()

@property (nonatomic, weak) ACCRecordViewControllerInputData *inputData;

@property (nonatomic, strong, readwrite) AWECameraPreviewContainerView *cameraPreviewView;
@property (nonatomic, strong, readwrite) id<VERecorderPublicProtocol> camera;

@property (nonatomic, strong) NSHashTable *subscribers;

@end

@implementation ACCCameraFactoryImpls

- (instancetype)initWithInputData:(ACCRecordViewControllerInputData *)inputData
{
    self = [super init];
    if (self) {
        _inputData = inputData;
    }
    return self;
}

#pragma mark - ACCCameraFactory

- (id<VERecorderPublicProtocol>)buildCameraWithContext:(const void *)context completionBlock:(ACCCameraFactoryCompletionBlock)completionBlock {

    [IESMMParamModule sharedInstance].effectJsonConfig = ACCConfigString(kConfigString_effect_json_config);

    id<VERecorderPublicProtocol> camera = [self createCameraWithContext:context completion:completionBlock];

    [camera setInputLanguage:[ACCI18NConfig() currentLanguage]];
    [ACCFeedback() acc_recordForCameraInit:AWEStudioFeedBackStatusStart code:0];
    
    if (!camera) {
        NSDictionary *errorData = @{@"service"   : @"record_error",
                                    @"action"    : @"init camera"};
        [ACCMonitor() trackData:errorData logTypeStr:@"aweme_movie_publish_log"];
        NSInteger applicationState = [UIApplication sharedApplication].applicationState;
        [ACCMonitor() trackService:@"aweme_open_camera_error_rate"
                            status:1
                             extra:@{ @"applicationState": @(applicationState)}];
        // feedback
        [ACCFeedback() acc_recordForCameraInit:AWEStudioFeedBackStatusFail code:1];
        return camera;
    } else {
        [ACCMonitor() trackService:@"aweme_open_camera_error_rate" status:0 extra:nil];
        [ACCFeedback() acc_recordForCameraInit:AWEStudioFeedBackStatusSuccess code:0];
    }
    
    [camera setMaxStickerMemoryCache:[UIDevice acc_isPoorThanIPhone6S] ? 10.0 : 30];
    [camera setMattingDetectModel:ACCConfigBool(kConfigBool_enable_large_matting_detect_model)];
    [camera setHandDetectLowpower:!ACCConfigBool(kConfigBool_enable_large_gesture_detect_model)];
    camera.notNeedAutoStartAudioCapture = YES;
    
    [camera setEffectBitmapRequestBlock:^IESEffectBitmapStruct(NSString * _Nullable text, IESEffectTextLayoutStruct layout) {
        return [AWE2DStickerTextGenerator generate2DTextBitmapWithText:text textLayout:layout];
    }];
    
    if (self.inputData.publishModel.repoMusic.music) {
        [camera muteBGM:YES];
    }

    @weakify(camera);
    @weakify(self);
    [camera setFirstEffectRenderBlock:^{
        @strongify(camera);
                
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wnonnull"
        acc_dispatch_main_async_safe(^{
            @strongify(self);
            [[AWERecordFirstFrameTrackerNew sharedTracker] eventEnd:kAWERecordEventEffectFirstFrame trackingBeginEvent:kAWERecordEventFirstFrame];
            [[AWERecordFirstFrameTrackerNew sharedTracker] eventEnd:@"render_interval" trackingEndEvent:kAWERecordEventFirstFrame];

            [[AWERecordFirstFrameTrackerNew sharedTracker] finishTrackWithInputData:self.inputData];
            [camera setFirstEffectRenderBlock:nil];
        });
        AWELogToolInfo2(@"first_frame", AWELogToolTagRecord, @"record first frame call back excute");
        #pragma clang diagnostic pop
    }];
    for (id<ACCCameraBuildListener> subscriber in self.subscribers) {
        [subscriber onCameraInit:camera];
    }
    self.camera = camera;
    return camera;
}

- (id<VERecorderPublicProtocol>)createCameraWithContext:(const void *)context completion:(ACCCameraFactoryCompletionBlock)completion
{
    IESMMCameraConfig *config = [self cameraConfigWithInputData:self.inputData];
    id<VERecorderPublicProtocol> camera;
    if (self.inputData.publishModel.repoDuet.isDuet) {
        camera = [self createDuetCameraWithConfig:config completion:completion];
    } else {
        camera = [VERecorder createRecorderWithView:self.cameraPreviewView config:config cameraComplete:completion];
    }
    [camera setCameraContext:context];
    self.cameraPreviewView.camera = camera;
    return camera;
}

- (IESMMCameraConfig *)cameraConfigWithInputData:(ACCRecordViewControllerInputData *)inputData
{
    IESMMCameraConfig *config = [[IESMMCameraConfig alloc] init];
    if (ACCConfigBool(kConfigBOOL_enable_reduce_prop_frame_rate)) {
        ACCRepoRearResourceModel *rearSource = [self.inputData.publishModel extensionModelOfClass:ACCRepoRearResourceModel.class];
        if (rearSource.stickerIDArray.count > 0 || self.inputData.prioritizedStickers.count > 0) {
            config.preferedFrameRate = ACCConfigInt(kConfigInt_studio_prop_record_frame_rate);
        }
    }
    config.previewType = IESMMCameraPreviewGL;
    [self configCameraDeviceTypesIfNeededFor:config];
    config.customSwitchAnimation = YES;
    config.enableExposureOptimize = inputData.publishModel.repoVideoInfo.isExposureOptmize;
    config.landscapeDetectEnable = YES;
    config.previewModeType = IESPreviewModePreserveAspectRatioAndFill;
    
    config.enableTapFocus = YES;
    AVCaptureDevicePosition defaultPosition = [self defaultPosition];
    if (inputData.cameraPosition != AVCaptureDevicePositionUnspecified) {
        defaultPosition = inputData.cameraPosition;
    }
    config.cameraPosition = defaultPosition;
    config.enableTapexposure = YES;
    config.videoData = acc_videodata_make_hts(inputData.publishModel.repoVideoInfo.video);
    config.useSDKGesture = NO;
    config.noNeedEffectFrameCount = ACCConfigInt(kConfigInt_no_effect_frame_count);
    config.dropFrameCount = 3;
    config.noDropFirstStartCaptureFrame = !ACCConfigBool(kConfigBool_studio_enable_drop_first_start_capture_frame);
    config.isNeedCaptureRecordFirstFrame = YES;
    // 因为微距镜头在打开防抖时有明显的取景位移，暂时关闭防抖，等待苹果修复
    config.rearPreferredStabilizationMode = AVCaptureVideoStabilizationModeOff;
    return config;
}

- (void)configCameraDeviceTypesIfNeededFor:(IESMMCameraConfig *)config
{
    if (@available(iOS 10.0, *)) {
        config.preferredRearCameraDeviceTypes = [self preferredRearCameraDeviceTypes];
    }
}

- (NSArray<AVCaptureDeviceType> *)preferredRearCameraDeviceTypes API_AVAILABLE(ios(10.0))
{
    if (@available(iOS 13.0, *)) {
        return @[AVCaptureDeviceTypeBuiltInTripleCamera,
                 AVCaptureDeviceTypeBuiltInDualCamera,
                 AVCaptureDeviceTypeBuiltInDualWideCamera,
                 AVCaptureDeviceTypeBuiltInWideAngleCamera];
    } else if (@available(iOS 10.2, *)) {
        return @[AVCaptureDeviceTypeBuiltInDualCamera,
                 AVCaptureDeviceTypeBuiltInWideAngleCamera];
    } else {
        return @[AVCaptureDeviceTypeBuiltInDuoCamera,
                 AVCaptureDeviceTypeBuiltInWideAngleCamera];
    }
}

- (void)addCameraListener:(id<ACCCameraBuildListener>)listener {
    NSAssert([NSThread isMainThread], @"Must be called by the main thread");
    if (self.camera) {
        [listener onCameraInit:self.camera];
    } else {
        [self.subscribers addObject:listener];
    }
}

- (NSHashTable *)subscribers {
    if (!_subscribers) {
        _subscribers = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    return _subscribers;
}

#pragma mark -DuetMerge 2020-2-9

- (id<VERecorderPublicProtocol>)createDuetCameraWithConfig:(IESMMCameraConfig *)config completion:(ACCCameraFactoryCompletionBlock)completion
{
    // 使用合拍重构方案
    config.previewModeType = IESPreviewModePreserveAspectRatio;
    id<VERecorderPublicProtocol> camera;
    CGSize videoSize = self.inputData.publishModel.repoVideoInfo.video.transParam.videoSize;
    CGSize maxDuetRecordSize = CGSizeMake(720, 1280);
    if ([AWEVideoRecordOutputParameter issourceSize:videoSize exceedLimitWithTargetSize:maxDuetRecordSize]) {
        CGSize resizeTargetSize = [AWEVideoRecordOutputParameter getSizeWithSourceSize:videoSize targetSize:maxDuetRecordSize];
        self.inputData.publishModel.repoVideoInfo.video.transParam.videoSize = resizeTargetSize;
        AWELogToolInfo2(@"resolution", AWELogToolTagRecord, @"Limited duet size with originalDuetSize:%@, resizeTargetSize:%@.", NSStringFromCGSize(videoSize), NSStringFromCGSize(resizeTargetSize));
    }

    config.isProcessMultiInput = YES;
    config.noNeedEffectFrameCount = 0;
    camera = [VERecorder createRecorderWithView:self.cameraPreviewView config:config cameraComplete:^{
        ACCBLOCK_INVOKE(completion);
    }];

    return camera;
}

#pragma mark - getter

- (AVCaptureDevicePosition)defaultPosition
{
    NSNumber *storedKey = [ACCCache() objectForKey:HTSVideoDefaultDevicePostionKey];
    if (storedKey != nil) {
        return [storedKey integerValue];
    } else {
        return AVCaptureDevicePositionFront;
    }
}

- (AWECameraPreviewContainerView *)cameraPreviewView
{
    if (!_cameraPreviewView) {
        _cameraPreviewView = [[AWECameraPreviewContainerView alloc] init];
    }
    return _cameraPreviewView;
}

@end
