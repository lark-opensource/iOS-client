//
//  ACCRecordFrameSamplingBaseHandler.m
//  AAWELaunchOptimization
//
//  Created by limeng on 2020/5/11.
//

#import "ACCRecordFrameSamplingBaseHandler.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSTimer+ACCAdditions.h>
#import <pthread/pthread.h>

#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import "ACCSecurityFramesSaver.h"
#import "AWERecordInformationRepoModel.h"
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreationKitArch/IESEffectModel+ACCSticker.h>
#import <CameraClient/ACCSecurityFramesSaver.h>

@interface ACCRecordFrameSamplingBaseHandler ()

@property (nonatomic, strong) NSTimer *recordFramesTimer;
/// 抽帧数据集合
@property (nonatomic, strong, readonly) NSMutableArray<NSString *> *samplingFrames;

@end
@implementation ACCRecordFrameSamplingBaseHandler {
    pthread_mutex_t _samplingFramesLock;
}

@synthesize frameSamplingContext = _frameSamplingContext;
@synthesize cameraService = _cameraService;
@synthesize samplingFrames = _samplingFrames;
@synthesize running = _running;
@synthesize timeInterval = _timeInterval;
@synthesize delegate = _delegate;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _samplingFrames = [NSMutableArray array];
        pthread_mutex_init(&_samplingFramesLock, NULL);
    }
    return self;
}

- (void)dealloc
{
    _running = NO;
    [self stopTimer];
    pthread_mutex_destroy(&_samplingFramesLock);
}

- (void)prepareToSampleFrame
{
    [self removeAllFrames];
}

- (void)firstSampling
{
    [self sampleFrame];
}

- (void)timedSampling
{
    @weakify(self);
    self.recordFramesTimer = [NSTimer acc_scheduledTimerWithTimeInterval:self.timeInterval block:^(NSTimer * _Nonnull timer) {
        @strongify(self);
        [self sampleFrame];
    } repeats:YES];
}

- (void)sampleFrame
{
    @weakify(self);
    [self.cameraService.recorder captureSourcePhotoAsImageByUser:NO completionHandler:^(UIImage * _Nonnull rawImage, NSError * _Nonnull error) {
        @strongify(self);
        if (rawImage) {
            // 将处理结果并入集合
            [self addFrameIfNeed:rawImage];
        } else {
            AWELogToolError(AWELogToolTagSecurity, @"[sample] 视频抽帧失败 %@", error);
        }
    } afterProcess:[self needAfterProcess]];
}

- (void)sampleFrameForPixloop
{
    if (self.frameSamplingContext.bgPhoto) {
        return;
    }
    
    @weakify(self);
    [self.cameraService.recorder captureSourcePhotoAsImageByUser:NO completionHandler:^(UIImage * _Nonnull rawImage, NSError * _Nonnull error) {
        @strongify(self);
        if (rawImage) {
            // 预处理
            UIImage *processedImage = [self preprocessFrame:rawImage];
            // 将处理结果并入集合
            self.frameSamplingContext.bgPhoto = processedImage;
        } else {
            AWELogToolError(AWELogToolTagSecurity, @"[sample] 视频抽帧失败 %@", error);
        }
    } afterProcess:[self needAfterProcess]];
}

- (void)samplingCompleted
{
    if ([self.delegate respondsToSelector:@selector(samplingCompleted:samplingFrames:)]) {
        [self.delegate samplingCompleted:self samplingFrames:self.samplingFrames];
    }
}

- (UIImage *)preprocessFrame:(UIImage *)rawImage
{
    return [ACCSecurityFramesSaver standardCompressImage:rawImage];
}

- (void)addFrameIfNeed:(UIImage *)processedImage
{
    if (processedImage) {
        @weakify(self);
        [ACCSecurityFramesSaver saveImage:processedImage type:ACCSecurityFrameTypeRecord taskId:self.publishModel.repoDraft.taskID completion:^(NSString * _Nonnull path, BOOL success, NSError * _Nonnull error) {
            @strongify(self);
            if (success) {
                [self p_addFrameIfNeed:path];
                AWELogToolInfo(AWELogToolTagSecurity, @"[save] 保存抽帧文件成功");

                [self saveHQVFrame:processedImage];
            }
        }];
    }
}

- (void)p_addFrameIfNeed:(NSString *)path
{
    if (!ACC_isEmptyString(path)) {
        pthread_mutex_lock(&_samplingFramesLock);
        [_samplingFrames addObject:path];
        pthread_mutex_unlock(&_samplingFramesLock);
    }
}

- (void)stopTimer
{
    if ([self.recordFramesTimer isValid]) {
        [self.recordFramesTimer invalidate];
    }
    self.recordFramesTimer = nil;
}

- (BOOL)needAfterProcess
{
    return NO;
}

/// 抽帧数据集合
- (NSMutableArray<NSString *> *)mutableSamplingFrames
{
    NSMutableArray<NSString *> *array = nil;
    pthread_mutex_lock(&_samplingFramesLock);
    array = [_samplingFrames mutableCopy];
    pthread_mutex_unlock(&_samplingFramesLock);
    return array;
}

/// 抽帧数据集合
- (NSArray<NSString *> *)immutableSamplingFrames
{
    NSArray<NSString *> *array = nil;
    pthread_mutex_lock(&_samplingFramesLock);
    array = [_samplingFrames copy];
    pthread_mutex_unlock(&_samplingFramesLock);
    return array;
}

#pragma mark - ACCRecordFrameSamplingHandlerProtocol
- (BOOL)shouldHandle:(nonnull id<ACCRecordFrameSamplingServiceProtocol>)samplingContext
{
    _frameSamplingContext = samplingContext;
    return NO;
}

- (void)configCameraService:(id<ACCCameraService>)cameraService samplingContext:(id<ACCRecordFrameSamplingServiceProtocol>)samplingContext
{
    _cameraService = cameraService;
    _frameSamplingContext = samplingContext;
    [_cameraService.message addSubscriber:self];
}

- (void)startWithCameraService:(id<ACCCameraService>)cameraService timeInterval:(NSTimeInterval)timeInterval
{
    if (self.isRunning) {
        return;
    }
    _running = YES;
    _cameraService = cameraService;
    _timeInterval = timeInterval;

    [_cameraService.message addSubscriber:self];
    
    // 0. 抽帧准备
    [self prepareToSampleFrame];
    // 1. 立即抽帧一次
    [self firstSampling];
    // 2. 开启定时抽帧
    [self timedSampling];
}

- (void)stop
{
    if (!self.isRunning) {
        return;
    }
    _running = NO;
    [self stopTimer];
    [self samplingCompleted];
    [self removeAllFrames];
}

- (void)removeAllFrames
{
    pthread_mutex_lock(&_samplingFramesLock);
    [_samplingFrames removeAllObjects];
    pthread_mutex_unlock(&_samplingFramesLock);
}

- (void)reduceSamplingFramesByThreshold:(NSUInteger)threshold
{
    pthread_mutex_lock(&_samplingFramesLock);
    if ([_samplingFrames count] == threshold) {
        [_samplingFrames enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (idx % 2 != 0) {
                [_samplingFrames removeObjectAtIndex:idx];
            }
        }];
    }
    pthread_mutex_unlock(&_samplingFramesLock);
}

- (void)saveBgPhotosForTakePicture
{
    // do nothing
}

#pragma mark - HQV

- (BOOL)enableHQVFrame
{
    // https://bytedance.feishu.cn/docs/doccnzGeXSGWZHUn33g4K9XpMWh#
    // 如果需要抽高清帧，那么每一段视频的第4s，以及第8s抽。一开始就有1帧，所以应该是采样第3帧保存完后抽一张高清帧
    // 相当于第4张是高清帧，5/6帧抽完后抽第2张高清帧
    NSInteger count = self.samplingFrames.count;
    return ((count == 3 || count == 6) && ACCConfigBool(kConfigBool_enable_hq_vframe));
}

- (void)saveHQVFrame:(UIImage *)processedImage
{
    if ([self enableHQVFrame]) {
        @weakify(self);
        [ACCSecurityFramesSaver saveImage:processedImage type:ACCSecurityFrameTypeRecord taskId:self.publishModel.repoDraft.taskID compressed:NO completion:^(NSString * _Nonnull path, BOOL success, NSError * _Nonnull error) {
            @strongify(self);
            if (success) {
                [self p_addFrameIfNeed:path];
                
                AWELogToolInfo(AWELogToolTagSecurity, @"[save] 保存HQ抽帧文件成功");
            }
        }];
    }
}

#pragma mark - ACCEffectEvent

- (void)onEffectMessageReceived:(IESMMEffectMessage *)message
{
    // do nothing
}

#pragma mark - Getter
- (UIImage *)faceImage
{
    return self.frameSamplingContext.bgPhoto;
}

- (NSArray<UIImage *> *)multiAssetsPixaloopSelectedImages
{
    return self.frameSamplingContext.multiAssetsPixaloopSelectedImages;
}

- (IESEffectModel *)currentSticker
{
    return self.frameSamplingContext.currentSticker;
}

- (AWEVideoPublishViewModel *)publishModel
{
    return self.frameSamplingContext.publishModel;
}

@end
