//
//  ACCLivePhotoFramesRecorder.m
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/7/18.
//

#import "ACCLivePhotoFramesRecorder.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSTimer+ACCAdditions.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CoreServices/CoreServices.h>
#import "ACCRecorderProtocolD.h"
#import <CreativeKit/ACCProtocolContainer.h>
#import "AWERepoDraftModel.h"
#import <TTVideoEditor/IESMMCaptureOptions.h>

/* [性能日志仅DEBUG用, RELEASE下无效]
    仅DEBUG为1，但现在规范上禁止了DEBUG宏的使用
 ACCLPPerfStart: 性能日志开始
 ACCLPPerfEnd:   性能日志结束
 */
#if 0
#   ifndef ACCLPPerfInfo
#   define ACCLPPerfInfo(fmt, ...) \
        do { \
            NSLog(fmt, ##__VA_ARGS__); \
        } while(0)
#   endif
#   ifndef ACCLPPerfStart
#   define ACCLPPerfStart(symbol) \
        let symbol = CFAbsoluteTimeGetCurrent()
#   endif
#   ifndef ACCLPPerfEnd
#   define ACCLPPerfEnd(symbol, fmt, ...) \
        do { \
            let symbol ## _duration = CFAbsoluteTimeGetCurrent() - symbol; \
            NSLog(fmt, ##__VA_ARGS__); \
        } while(0)
#   endif
#else
#   ifndef ACCLPPerfInfo
#   define ACCLPPerfInfo(fmt, ...)
#   endif
#   ifndef ACCLPPerfStart
#   define ACCLPPerfStart(symbol)
#   endif
#   ifndef ACCLPPerfEnd
#   define ACCLPPerfEnd(symbol, fmt, ...)
#   endif
#endif

static NSString *ACCLivePhotoFolder = @"live_photo";

NS_INLINE BOOL ACCDoubleEqual(double n1, double n2)
{
    return ABS(n1 - n2) <= DBL_EPSILON;
}

@interface ACCLivePhotoResult ()

@property (nonatomic, strong, readwrite) id<ACCLivePhotoConfigProtocol> config;
@property (nonatomic, copy  , readwrite) NSArray<NSString *> *framePaths;
@property (nonatomic, assign, readwrite) CGFloat contentRatio;

@end


@implementation ACCLivePhotoResult

@synthesize config       = _config;
@synthesize framePaths   = _framePaths;
@synthesize contentRatio = _contentRatio;

@end


@implementation ACCLivePhotoConfig

@synthesize repository     = _repository;
@synthesize recordDuration = _recordDuration;
@synthesize recordInterval = _recordInterval;
@synthesize stepBlock      = _stepBlock;
@synthesize willCompleteBlock = _willCompleteBlock;

- (id)copyWithZone:(NSZone *)zone
{
    ACCLivePhotoConfig *config = [[[self class] allocWithZone:zone] init];
    config.repository     = self.repository;
    config.recordDuration = self.recordDuration;
    config.recordInterval = self.recordInterval;
    config.stepBlock      = self.stepBlock;
    config.willCompleteBlock = self.willCompleteBlock;
    return config;
}

@end


@interface ACCLivePhotoFramesRecorder ()

/// 配置信息
@property (nonatomic, copy, readwrite) id<ACCLivePhotoConfigProtocol> config;
/// 录制计时器
@property (nonatomic, strong) NSTimer *recordFramesTimer;
/// 当前抽帧数量
@property (nonatomic, assign) NSInteger framesCount;
/// 抽帧文件Path集合 ( pts -> path )
@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, NSString *> *samplingFrames;
@property (nonatomic, assign) CGFloat contentRatio;
/// 录制服务
@property (nonatomic, weak) id<ACCRecorderProtocol> recorder;
/// 是否正在抽帧
@property (nonatomic, assign, getter=isRunning, readwrite) BOOL running;
/// 记录运行中的任务数，因captureSourcePhoto回调可能乱序，所以要根据任务数为0来判断整体完成
@property (nonatomic, assign) NSInteger numOfTaskRunning;
/// 完成回调
@property (nonatomic, copy) void(^completionBlk)(id<ACCLivePhotoResultProtocol> _Nullable data, NSError * _Nullable error);
/// 进度回调
@property (nonatomic, copy) void(^progressBlk)(NSTimeInterval currentDuration);
/// 从开始录制经过的时间，仅用于进度，一般比实际消耗的时间大，设备性能越好越接近实际消耗的时间
@property (nonatomic, assign) NSTimeInterval elapse;
@property (nonatomic, assign) NSTimeInterval oldElapse;
@property (nonatomic, assign) NSTimeInterval almostCompleteElapse;
/// 开始的时刻
@property (nonatomic, assign) CFAbsoluteTime startTime;
@property (nonatomic, strong) NSNumber *realTotalCount;
/// 每次start都会重新生成一个唯一id
@property (atomic, copy) NSString *sessionId;

@end

@implementation ACCLivePhotoFramesRecorder

- (instancetype)initWithConfig:(id<ACCLivePhotoConfigProtocol>)config
{
    self = [super init];
    if (self) {
        _config = [config copyWithZone:nil];
        _samplingFrames = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    _running = NO;
    [self uninstallObserver];
    [self stopTimer];
}

- (void)prepareToSampleFrame
{
    // 重拍的情况，先删掉老帧
    [self removeOldFiles];
    [self removeAllFrames];
    self.contentRatio = 0.0;
    self.sessionId = [[NSUUID UUID].UUIDString.lowercaseString stringByReplacingOccurrencesOfString:@"-" withString:@""];
    self.framesCount = 0;
    self.realTotalCount = nil;
    self.numOfTaskRunning = 0;
    self.elapse = 0.0;
    self.oldElapse = -1.0;
    self.almostCompleteElapse = -1.0;
    self.startTime = CFAbsoluteTimeGetCurrent();
    [self installObserver];
}

- (void)firstSampling
{
    [self sampleFrame];
}

- (void)timedSampling
{
    [self stopTimer];
    @weakify(self);
    self.recordFramesTimer = [NSTimer acc_scheduledTimerWithTimeInterval:self.config.recordInterval block:^(NSTimer * _Nonnull timer) {
        @strongify(self);
        [self sampleFrame];
    } repeats:YES];
}

- (void)updateRealTotalCountIfNeeded
{
    if (self.realTotalCount != nil) {
        return;
    }
    BOOL isTimeEnd = (CFAbsoluteTimeGetCurrent() - self.startTime >= self.config.recordDuration);
    if (isTimeEnd) {
        self.realTotalCount = @(self.framesCount);
    }
}

- (BOOL)shouldStopTimer
{
    if (self.realTotalCount != nil) {
        return self.framesCount >= [self.realTotalCount integerValue];
    }
    return self.framesCount >= [self expectedTotalCount];
}

- (NSInteger)expectedTotalCount
{
    return round(self.config.recordDuration / self.config.recordInterval);
}

- (void)sampleFrame
{
    NSInteger curIndex = self.framesCount;
    self.framesCount += 1;
    NSTimeInterval curDuration = self.framesCount * self.config.recordInterval;
    [self simulateRecorderState:ACCCameraRecorderStateRecording];
    
    [self updateRealTotalCountIfNeeded];
    BOOL isLast = [self shouldStopTimer];
    if (isLast) {
        // 录制和IO都是异步的，timer次数够了就可以停了
        [self stopTimer];
        // 进度到100%，快门的UI就重置了，所以这里稍微减一点点
        CGFloat const epsilon = 0.002;
        curDuration = self.config.recordDuration * (1.0 - epsilon);
        self.almostCompleteElapse = curDuration;
    }
    self.elapse = curDuration;

    @weakify(self);
    // [注意]
    // 下面captureSourcePhoto接口在连续调用场景时，存在早调用但晚回调的情况，所以:
    // 回调进度的时候需要实时取self.elapse，而不要用curDuration，否则会有进度条倒退的问题
    ++ self.numOfTaskRunning;
    ACCLPPerfStart(capture_photo);

    IESMMCaptureOptions *options = [[IESMMCaptureOptions alloc] init];
    options.captureMode = IESMMCaptureOptionModeSilence;
    options.disableEffects = NO;
    options.captureByUser = NO;
    options.disableFastCaptureContinue = YES;
    
    [ACCGetProtocol(self.recorder, ACCRecorderProtocolD) captureImageWithOptions:options finishHandler:^(UIImage * _Nullable image, NSDictionary * _Nullable metadata, NSError * _Nullable error) {
        @strongify(self);
        if (!self.isRunning) {
            // stop by handleResignActive, or failed
            return;
        }

        ACCLPPerfEnd(capture_photo, @"[lpperf] capture(@%02ld): %.3fs%@", (long)curIndex, capture_photo_duration, isLast ? @", <<<LAST>>>" : @"");
        NSValue *ptsValue = ACCDynamicCast(metadata[@"pts"], NSValue);
        CMTime pts = ptsValue != nil ? [ptsValue CMTimeValue] : kCMTimeInvalid;
        ACCLPPerfInfo(@"[lpperf] pts(@%02ld): %f, image: 0x%lx", (long)curIndex, CMTimeGetSeconds(pts), (uintptr_t)image);
        BOOL isPtsUsable = CMTIME_IS_NUMERIC(pts);
        
        if (error != nil) {
            AWELogToolError(AWELogToolTagRecord, @"[live photo] captureSourcePhoto失败, error:%@", error);
        }
        [self addFrameIfNeed:image index:curIndex pts:CMTimeGetSeconds(pts) completion:^(BOOL success, CGFloat ratio, NSError * _Nonnull error) {
            @strongify(self);
            if (!self.isRunning) {
                // stop by handleResignActive, or failed
                return;
            }
            -- self.numOfTaskRunning;
            [self notifyProgress];
            self.contentRatio = ratio;
            
            BOOL isRealLast = ([self shouldStopTimer] && self.numOfTaskRunning <= 0);
            if (isRealLast) {
                ACCLPPerfInfo(@"[lpperf] finish at %02ld", (long)curIndex);
                NSArray<NSString *> *framePaths = [self immutableSamplingFrames];
                if (framePaths.count > 0) {
                    ACCLivePhotoResult *data = [[ACCLivePhotoResult alloc] init];
                    data.config = self.config;
                    data.framePaths = framePaths;
                    data.contentRatio = ratio;
                    [self notifyStopWithResult:data error:nil];
                }
                else {
                    [self notifyStopWithResult:nil error:error];
                }
            }
            else if (!isPtsUsable) {
                // VE性能优化提供 disableFastCaptureContinue 模式：
                // 此模式下，当快拍某帧失败时，不会使用原系统拍照的逻辑兜底，从而大幅提升连拍效率；
                // 但也因为无兜底了，所以会回调空的image，这里留空即表示丢弃这种空帧；
            }
            else if (error != nil) {
                [self notifyStopWithResult:nil error:error];
            }
        }];
    }];
    
    NSInteger total = 0;
    if (self.realTotalCount != nil) {
        total = [self.realTotalCount integerValue];
    }
    else {
        total = [self expectedTotalCount];
    }
    ACCBLOCK_INVOKE(self.config.stepBlock, self.config, curIndex, total, [self expectedTotalCount]);
}

- (void)samplingCompletedWithResult:(ACCLivePhotoResult * _Nullable)result error:(NSError * _Nullable)error
{
    ACCLPPerfInfo(@"[lpperf] --- Will END --- %f", CFAbsoluteTimeGetCurrent() - self.startTime);
    [self simulateRecorderState:ACCCameraRecorderStatePausing];
    if (error) {
        ACCLPPerfInfo(@"[lpperf] --- Did END --- %f", CFAbsoluteTimeGetCurrent() - self.startTime);
        ACCBLOCK_INVOKE(self.completionBlk, nil, error);
    }
    else {
        // fix: 进度条到不了100%
        static NSTimeInterval const WaitAnimDuration = 0.25;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(WaitAnimDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // 最终成功才让进度到达100%
            self.elapse = self.config.recordDuration;
            [self notifyProgress];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                ACCLPPerfInfo(@"[lpperf] --- Did END --- %f", CFAbsoluteTimeGetCurrent() - self.startTime);
                ACCBLOCK_INVOKE(self.completionBlk, result, nil);
            });
        });
    }
}

- (void)addFrameIfNeed:(UIImage *)processedImage index:(NSInteger)index pts:(Float64)pts completion:(void(^)(BOOL success, CGFloat ratio, NSError * _Nonnull error))completion
{
    CGFloat ratio = 0.0;
    if (processedImage) {
        if (processedImage.size.width != 0.0) {
            ratio = processedImage.size.height / processedImage.size.width;
        }
        @weakify(self);
        [ACCLivePhotoFramesRecorder saveImage:processedImage index:index taskId:self.config.repository.repoDraft.taskID sessionId:self.sessionId completion:^(NSString *path, BOOL success, NSError *error) {
            @strongify(self);
            if (success) {
                [self p_addFrameIfNeed:path index:index pts:pts];
            }
            ACCBLOCK_INVOKE(completion, success, ratio, error);
        }];
    }
    else {
        NSError *error = [ACCLivePhotoFramesRecorder makeErrorWithCode:-1 reason:@"recorder capture rawImage failed"];
        acc_dispatch_main_async_safe(^{
            ACCBLOCK_INVOKE(completion, NO, ratio, error);
        });
    }
}

- (void)p_addFrameIfNeed:(NSString *)path index:(NSInteger)index pts:(Float64)pts
{
    NSAssert([NSThread isMainThread], @"thread safe check");
    if (!ACC_isEmptyString(path)) {
        _samplingFrames[@(pts)] = path;
    }
}

- (void)stopTimer
{
    if ([self.recordFramesTimer isValid]) {
        [self.recordFramesTimer invalidate];
    }
    self.recordFramesTimer = nil;
}

- (NSArray<NSString *> *)immutableSamplingFrames
{
    NSAssert([NSThread isMainThread], @"thread safe check");
    NSDictionary<NSNumber *, NSString *> *framesCopy = [_samplingFrames copy];
    NSArray<NSNumber *> *sortedKeys = [[framesCopy allKeys] sortedArrayUsingSelector:@selector(compare:)];
    
    NSMutableArray<NSString *> *array = [[NSMutableArray alloc] init];
    for (NSNumber *index in sortedKeys) {
        [array btd_addObject:framesCopy[index]];
    }
    return array;
}

- (void)startWithRecorder:(id<ACCRecorderProtocol>)recorder
                 progress:(void(^ _Nullable)(NSTimeInterval currentDuration))progress
               completion:(void(^ _Nullable)(id<ACCLivePhotoResultProtocol> _Nullable data, NSError * _Nullable error))completion
{
    NSAssert(!self.isRunning, @"recorder already running!");
    self.progressBlk = progress;
    self.completionBlk = completion;
    self.running = YES;
    self.recorder = recorder;
        
    // 0. 采集准备
    [self prepareToSampleFrame];
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        [self handleResignActive];
        return;
    }
    // 1. 立即采集一次
    [self firstSampling];
    // 2. 开启定时采样
    [self timedSampling];
}

// 为了驱动UI，比如submode组件的UI
- (void)simulateRecorderState:(ACCCameraRecorderState)state
{
    self.recorder.recorderState = state;
}

- (void)notifyProgress
{
    if (ACCDoubleEqual(self.oldElapse, self.elapse)) {
        return;
    }
    self.oldElapse = self.elapse;
    ACCBLOCK_INVOKE(self.progressBlk, self.elapse);
    
    if (ACCDoubleEqual(self.almostCompleteElapse, self.elapse)) {
        ACCBLOCK_INVOKE(self.config.willCompleteBlock, self.config);
    }
}

- (void)notifyStopWithResult:(ACCLivePhotoResult * _Nullable)result error:(NSError * _Nullable)error
{
    if (!self.isRunning) {
        return;
    }
    self.running = NO;
    [self uninstallObserver];
    [self stopTimer];
    [self samplingCompletedWithResult:result error:error];
    [self removeAllFrames];
}

- (void)removeAllFrames
{
    NSAssert([NSThread isMainThread], @"thread safe check");
    [_samplingFrames removeAllObjects];
}

+ (NSError *)makeErrorWithCode:(NSInteger)code reason:(NSString *)reason
{
    NSError *error = [NSError errorWithDomain:@"ACCLivePhotoFramesRecorderErrorDomain" code:code userInfo:@{ NSLocalizedDescriptionKey: reason ?: @"" }];
    return error;
}

#pragma mark - App Inactive

- (void)installObserver
{
    [self uninstallObserver];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleResignActive) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)uninstallObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleResignActive
{
    [self notifyProgress];
    NSArray<NSString *> *framePaths = [self immutableSamplingFrames];
    
    if (framePaths.count > 0 && !ACCDoubleEqual(self.contentRatio, 0.0)) {
        ACCLivePhotoResult *data = [[ACCLivePhotoResult alloc] init];
        data.config = self.config;
        data.framePaths = framePaths;
        data.contentRatio = self.contentRatio;
        [self notifyStopWithResult:data error:nil];
    }
    else {
        NSError *error = [ACCLivePhotoFramesRecorder makeErrorWithCode:-999 reason:@"app resign active"];
        [self notifyStopWithResult:nil error:error];
    }
}

#pragma mark - Save Image

+ (dispatch_queue_t)livePhotoSaveQueue
{
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
        queue = dispatch_queue_create("com.AWEStudio.queue.livePhotoSave", attr);
    });
    
    return queue;
}

/// 移除所有旧的图片帧（草稿里引用文件除外）
- (void)removeOldFiles
{
    NSString *taskId = self.config.repository.repoDraft.taskID;
    if (ACC_isEmptyString(taskId)) {
        NSAssert(NO, @"taskId is nil");
        return;
    }
    NSArray<NSString *> *imagePathList = self.config.repository.repoLivePhoto.imagePathList;
    dispatch_queue_t queue = [ACCLivePhotoFramesRecorder livePhotoSaveQueue];
    
    dispatch_async(queue, ^{
        NSString *draftFolder = [AWEDraftUtils generateDraftFolderFromTaskId:taskId];
        NSString *framesFolder = [draftFolder stringByAppendingPathComponent:ACCLivePhotoFolder];
        NSMutableSet<NSString *> *keepList = [[NSMutableSet alloc] init];
        for (NSString *rp in imagePathList) {
            NSString *p = [[draftFolder stringByAppendingPathComponent:rp] stringByStandardizingPath];
            [keepList addObject:p];
        }
        [ACCLivePhotoFramesRecorder p_removeFilesInFolder:framesFolder ignoreList:keepList];
    });
}

+ (void)p_removeFilesInFolder:(NSString *)folder ignoreList:(NSSet<NSString *> *)ignoreList
{
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:folder isDirectory:&isDirectory]) {
        return;
    }
    if (!isDirectory) {
        return;
    }
    
    let enumerator = [[NSFileManager defaultManager] enumeratorAtURL:[NSURL URLWithString:folder] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:nil];
    
    for (NSURL *item in enumerator) {
        NSString *itemPath = [[item path] stringByStandardizingPath];
        if ([ignoreList containsObject:itemPath]) {
            continue;
        }
        [[NSFileManager defaultManager] removeItemAtPath:itemPath error:nil];
    }
}

+ (NSString *)p_framePathWithTaskId:(NSString *)taskId
                              index:(NSInteger)index
                          sessionId:(NSString *)sessionId
{
    if (ACC_isEmptyString(taskId)) {
        NSAssert(NO, @"taskId is nil");
        return @"";
    }
    
    NSString *draftFolder = [AWEDraftUtils generateDraftFolderFromTaskId:taskId];
    NSString *frameFolder = [draftFolder stringByAppendingPathComponent:ACCLivePhotoFolder];
    
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:frameFolder isDirectory:&isDirectory]) {
        NSError *createDirectoryError;
        [[NSFileManager defaultManager] createDirectoryAtPath:frameFolder
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&createDirectoryError];
        if (createDirectoryError) {
            AWELogToolError(AWELogToolTagRecord, @"[live photo] 创建folder失败，folder: %@，error: %@", frameFolder, @(createDirectoryError.code));
            frameFolder = draftFolder;
        }
    }
    
    NSString *name = [NSString stringWithFormat:@"lv_%ld_%@.jpeg", (long)index, sessionId];
    NSString *framePath = [frameFolder stringByAppendingPathComponent:name];
    
    NSAssert(![[NSFileManager defaultManager] fileExistsAtPath:framePath], @"[live photo] invalid frame path = %@", framePath);
    
    return framePath;
}

+ (void)writeImage:(UIImage *)image
             index:(NSInteger)index
            taskId:(NSString *)taskId
         sessionId:(NSString *)sessionId
        completion:(void(^)(NSString *path, NSError *error))completion
{
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        NSData *data = nil;
        @autoreleasepool {
            ACCLPPerfStart(image_data);
            // UIImageJPEGRepresentation 在 iOS10 及以上是线程安全的，iOS9已不支持
            data = UIImageJPEGRepresentation(image, 0.6);
            ACCLPPerfEnd(image_data, @"[lpperf]   data(@%02ld): %.3fs, size: %lu", (long)index, image_data_duration, (unsigned long)data.length);
        }
        
        dispatch_queue_t queue = [self livePhotoSaveQueue];
        dispatch_async(queue, ^{
            
            NSString *path = [self p_framePathWithTaskId:taskId index:index sessionId:sessionId];
            
            if (ACC_isEmptyString(path)) {
                NSError *error = [self makeErrorWithCode:-10 reason:@"Invalid file path"];
                ACCBLOCK_INVOKE(completion, path, error);
                return;
            }

            ACCLPPerfStart(image_save);
            dispatch_fd_t fd = open(path.UTF8String, O_WRONLY | O_CREAT | O_APPEND, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
            dispatch_data_t ddata = dispatch_data_create(data.bytes, data.length, queue, ^{
                // dispatch_data生命周期内，强持有data
                [data self];
            });
            
            dispatch_write(fd, ddata, queue, ^(dispatch_data_t  _Nullable data, int errcode) {
                close(fd);
                ACCLPPerfEnd(image_save, @"[lpperf]     save(@%02ld): %.3fs", (long)index, image_save_duration);

                NSError *error = errcode ? [self makeErrorWithCode:errcode reason:@"dispatch_write error"] : nil;
                ACCBLOCK_INVOKE(completion, path, error);
            });

        });
    });
        
}

+ (void)saveImage:(UIImage *)image
            index:(NSInteger)index
           taskId:(NSString *)taskId
        sessionId:(NSString *)sessionId
       completion:(void (^)(NSString *path, BOOL success, NSError *error))completion
{
    [self writeImage:image index:index taskId:taskId sessionId:sessionId completion:^(NSString *path, NSError *saveError) {
        
        NSString *relativePath = [AWEDraftUtils relativePathFrom:path taskID:taskId];
        if (saveError) {
            AWELogToolError(AWELogToolTagRecord, @"[live photo] 保存文件失败，error:%@，path:@%", saveError, path);

            if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                NSError *deleteError = nil;
                [[NSFileManager defaultManager] removeItemAtPath:path error:&deleteError];
                if (deleteError) {
                    AWELogToolWarn(AWELogToolTagRecord, @"[live photo] 删除文件失败，error:%@，path:@%", @(deleteError.code), path);
                }
            }
        }

        acc_dispatch_main_async_safe(^{
            ACCBLOCK_INVOKE(completion, relativePath, !saveError, saveError);
        });

    }];
}

@end
