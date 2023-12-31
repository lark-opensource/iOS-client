//
//  AWEStudioMeasureManager.m
//  Pods
//
// Created by Hao Yipeng on June 11, 2019
//

#import "AWEStudioMeasureManager.h"
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCHeimdallrProtocol.h>
#import "AWEDraftUtils.h"
#import <EffectPlatformSDK/IESEffectDefines.h>

NSString * const kAWEStudioClickPlusToFirstFrameAppearService = @"awe_studio_click_plus_to_first_frame_appear";
NSString * const kAWEVideoRecorderMonitorTrackServiceName = @"aweme_video_recorder_enter_timming_log";

#define TestStudioMeasure 0

@interface AWEStudioMeasureManager ()

@property (nonatomic, assign) BOOL cameraFirstLaunched;

@property (nonatomic, assign) CFTimeInterval clickPlusTimeStamp;
@property (nonatomic, assign) BOOL enterRecordPageFromPlusButton;

@property (nonatomic, assign) CFTimeInterval viewDidLoadTimeStamp;
@property (nonatomic, assign) CFTimeInterval viewDidLoadedToFirstFrameAppearDuration;
@property (nonatomic, assign) BOOL viewDidLoaded;

@property (nonatomic, strong) dispatch_queue_t taskQueue;

// performance track
@property (nonatomic, assign) BOOL hadTrackDraftInfo;
@property (nonatomic, assign) NSTimeInterval draftClickStart;
@property (nonatomic, assign) BOOL hadTrackEffectInfo;
@property (nonatomic, assign) BOOL hadTrackCaptureIMG;
@end


@implementation AWEStudioMeasureManager

+ (instancetype)sharedMeasureManager {
    static AWEStudioMeasureManager *_sharedMeasureManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedMeasureManager = [[AWEStudioMeasureManager alloc] init];
    });
    
    return _sharedMeasureManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _taskQueue = dispatch_queue_create("com.AWEStudio.queue.measureManager", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - Performance

- (void)trackClickPlusTime {
    self.enterRecordPageFromPlusButton = YES;
    self.clickPlusTimeStamp = [self p_currentTimeInterval];
}

- (void)cancelTrackClickPlusTime {
    self.enterRecordPageFromPlusButton = NO;
    self.clickPlusTimeStamp = 0;
}

- (void)trackClickPlusToRecordPageFirstFrameAppearWithReferString:(NSString *)referString {
    CFTimeInterval endedTime = [self p_currentTimeInterval];
#if TestStudioMeasure
    CFTimeInterval appearDuration = 0;
#endif
    if (self.enterRecordPageFromPlusButton) {
        // Distinguish between cold and hot start 0: cold start 1: hot start
        CFTimeInterval firstFrameAppearDuration = (endedTime - self.clickPlusTimeStamp) * 1000; // ms -> s
#if TestStudioMeasure
        appearDuration = firstFrameAppearDuration;
#endif
        NSDictionary *extra = @{
                                @"clickPlusToRecordFirstFrameAppearDuration" : @(firstFrameAppearDuration),
                                @"referString" : referString ?: @"",
                                };
        [self asyncMonitorTrackService:kAWEStudioClickPlusToFirstFrameAppearService status:self.cameraFirstLaunched ? 1 : 0 extra:extra];
        [self cancelTrackClickPlusTime];
    }

    
    if (self.viewDidLoaded) {
        self.viewDidLoadedToFirstFrameAppearDuration = (endedTime - self.viewDidLoadTimeStamp) * 1000;
        NSDictionary *data = @{
                               @"viewDidLoadStart_cameraFirstFrameAppear" : @(self.viewDidLoadedToFirstFrameAppearDuration)
                               };
        [self asyncMonitorTrackService:kAWEVideoRecorderMonitorTrackServiceName status:self.cameraFirstLaunched ? 1 : 0 extra:data];
        [self cancelTrackViewDidLoad];
    }
    
#if TestStudioMeasure
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString *title = [NSString stringWithFormat:@"clickPlusToRecordFirstFrameAppearDuration:%@", @(appearDuration)];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle: ACCLocalizedCurrentString(@"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
        [alertController acc_show];
    });
#endif
    
    self.cameraFirstLaunched = YES;
}

// Camera life cycle
- (void)trackViewDidLoad {
    self.viewDidLoadTimeStamp = [self p_currentTimeInterval];
    self.viewDidLoaded = YES;
}

- (void)cancelTrackViewDidLoad {
    // Only the time of entering aweideorecorderviewcontroller for the first time is counted
    self.viewDidLoaded = NO;
}

- (void)cancelOnceTrack {
    [self cancelTrackClickPlusTime];
    [self cancelTrackViewDidLoad];
}

#pragma mark - Monitor

- (void)asyncOperationBlock:(dispatch_block_t)block {
    dispatch_async(_taskQueue, ^{
        ACCBLOCK_INVOKE(block);
    });
}

- (void)asyncMonitorTrackService:(NSString *)trackService status:(NSInteger)status extra:(NSDictionary *)extra {
    dispatch_async(_taskQueue, ^{
        [ACCMonitor() trackService:trackService status:status extra:extra];
    });
}

- (void)asyncMonitorTrackService:(NSString *)trackService value:(float)value extra:(NSDictionary *)extra {
    dispatch_async(_taskQueue, ^{
        [ACCMonitor() trackService:trackService floatValue:value extra:extra];
    });
}
- (void)asyncMonitorTrackData:(NSDictionary *)trackData logTypeStr:(NSString *)logTypeStr {
    dispatch_async(_taskQueue, ^{
        [ACCMonitor() trackData:trackData logTypeStr:logTypeStr];
    });
}

#pragma mark - Private Method

- (CFTimeInterval)p_currentTimeInterval {
    return CACurrentMediaTime();
}

#pragma mark - performance track

// only track once during the app life cycle
- (void)trackOfDraftInfo:(NSInteger)count
{
    if (!self.hadTrackDraftInfo) {
        self.hadTrackDraftInfo = YES;
        [self asyncOperationBlock:^{
            NSMutableDictionary *params = @{}.mutableCopy;
            params[@"count"] = @(count);
            
            NSString *path = [AWEDraftUtils draftRootPath];
            unsigned long long foldersize = 0;
            if ([path length]) {
                foldersize = [ACCHeimdallrService() folderSizeAtPath:path];
            }
            params[@"storage_size"] = @(foldersize);
            [ACCTracker() trackEvent:@"tool_performance_draft_info" params:params.copy needStagingFlag:NO];
        }];
    }
}

- (void)trackOfDraftClickStart
{
    self.draftClickStart = CFAbsoluteTimeGetCurrent();
}

- (void)trackOfDraftClickEnd:(NSDictionary *)trackParams
{
    if (self.draftClickStart) {
        NSTimeInterval duration = CFAbsoluteTimeGetCurrent() - self.draftClickStart;
        self.draftClickStart = 0;
        NSMutableDictionary *params = @{}.mutableCopy;
        params[@"duration"] = @((NSInteger)(duration * 1000));
        [params addEntriesFromDictionary:trackParams];
        [ACCTracker() trackEvent:@"tool_performance_draft_to_publish" params:params.copy needStagingFlag:NO];
    }
}

// only track once during the app life cycle
- (void)trackEffectInfo
{
    if (!self.hadTrackEffectInfo) {
        self.hadTrackEffectInfo = YES;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSMutableDictionary *params = @{}.mutableCopy;
            NSString *uncompressPath = IESEffectUncompressPathWithIdentifier(nil);
            unsigned long long foldersize = 0;
            if ([uncompressPath length]) {
                foldersize = [ACCHeimdallrService() folderSizeAtPath:uncompressPath];// it would cost plenty of time
            }
            params[@"storage_size"] = @(foldersize);
            [ACCTracker() trackEvent:@"tool_performance_effect_storage_space" params:params.copy needStagingFlag:NO];
        });
    }
}

// only track once during the app life cycle
- (void)trackCaptureIMG:(nullable NSDictionary * (^)(void))block
{
    if (!self.hadTrackCaptureIMG) {
        self.hadTrackCaptureIMG = YES;
        NSDictionary *params = ACCBLOCK_INVOKE(block);
        [ACCTracker() trackEvent:@"tool_performance_record_fetch_frames" params:params needStagingFlag:NO];
    }
}

@end
