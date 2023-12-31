//
//  AWERecordFirstFrameTrackerNew.m
//  CameraClient-Pods-Aweme
//
//  Created by Liyingpeng on 2021/7/19.
//

#import "AWERecordFirstFrameTrackerNew.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CameraClient/ACCKdebugSignPost.h>
#import "ACCRepoRecorderTrackerToolModel.h"
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreativeKit/ACCENVProtocol.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreativeKit/NSArray+ACCAdditions.h>

NSString * const kAWERecordEventFirstFrame = @"first_frame_duration";
NSString * const kAWERecordEventUserInteractiveEnableDuration = @"user_interactive_enable_duration";
NSString * const kAWERecordEventPreControlerInit = @"pre_controller_init_cost";
NSString * const kAWERecordEventControlerInit = @"controller_init_cost";
NSString * const kAWERecordEventViewLoad = @"view_load_cost";
NSString * const kAWERecordEventViewDidLoad = @"view_did_load_cost";
NSString * const kAWERecordEventViewWillAppear = @"view_will_appear_cost";
NSString * const kAWERecordEventViewAppear = @"view_appear_cost";
NSString * const kAWERecordEventCameraCreate = @"camera_create_cost";
NSString * const kAWERecordEventPostCameraCreate = @"post_camera_create_cost";
NSString * const kAWERecordEventBeforeCameraCreate = @"before_camera_create_cost";
NSString * const kAWERecordEventStartCameraCapture = @"before_camera_capture_cost";
NSString * const kAWERecordEventCameraCaptureFirstFrame = @"camera_capture_first_frame_cost";
NSString * const kAWERecordEventEffectFirstFrame = @"effect_first_frame_duration";

static NSString *const kAWERecordFirstFrameTrackerCacheKey = @"kAWERecordFirstFrameTrackerCacheKey";

@interface AWERecordFirstFrameTrackerNew ()

@property (nonatomic, assign) NSInteger recordCount;
@property (nonatomic, weak) ACCRecordViewControllerInputData *inputData;

@end

@implementation AWERecordFirstFrameTrackerNew

+ (instancetype)sharedTracker
{
    static id shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[self alloc] init];
    });
    
    return shareInstance;
}

- (instancetype)init
{
    self = [super initWithName:@"tool_performance_record_first_frame"];
    if (self) {
        self.waitingKeyArray = @[kAWERecordEventFirstFrame, kAWERecordEventViewAppear, kAWERecordEventEffectFirstFrame];
        self.primaryKey = kAWERecordEventFirstFrame;
        
        @weakify(self);
        self.additionHandleBlock = ^(NSMutableDictionary * _Nonnull params) {
            @strongify(self);
            
            NSDictionary *bizParams = [self getBizParmas:self.inputData];
            [params addEntriesFromDictionary:bizParams];
            // saf test add metric
            if ([IESAutoInline(ACCBaseServiceProvider(), ACCENVProtocol) currentEnv] == ACCENVSaf && params[kAWERecordEventFirstFrame]) {
                NSMutableDictionary *metricExtra = @{}.mutableCopy;
                UInt64 end_time = (UInt64)([[NSDate date] timeIntervalSince1970] * 1000);
                UInt64 start_time = end_time - (UInt64)([params[kAWERecordEventFirstFrame] integerValue]);
                [metricExtra addEntriesFromDictionary:@{@"metric_name": kAWERecordEventFirstFrame, @"start_time": @(start_time), @"end_time": @(end_time)}];
                NSMutableArray *metrics = @[metricExtra].mutableCopy;
                if (params[@"effect_first_frame_duration"]) {
                    [metrics acc_addObject:@{@"metric_name": kAWERecordEventEffectFirstFrame,
                                             @"start_time": @(start_time),
                                             @"end_time": @(start_time + [params acc_integerValueForKey:@"effect_first_frame_duration"])}];
                }
                params[@"metric_extra"] = [metrics copy];
            }
            // user interactive duration param
            NSInteger userInteractive = [self getDurationBetween:kAWERecordEventFirstFrame and:kAWERecordEventViewAppear];
            params[kAWERecordEventUserInteractiveEnableDuration] = @(userInteractive);
            
            params[@"new_flag"] = @(1);

            [ACCCache() setBool:NO forKey:kAWERecordFirstFrameTrackerCacheKey];
            
            //恢复默认值
            self.forceLoadComponent = NO;
            
            ACCKdebugSignPostEnd(10, 0, 0, 0, 0);
        };
        
        BOOL pendingSession = [ACCCache() boolForKey:kAWERecordFirstFrameTrackerCacheKey];
        if (pendingSession) {
            [self failedTrackWithErrorCode:AWERecordFirstFrameTrackErrorExit noEventTracking:YES];
            [ACCCache() setBool:NO forKey:kAWERecordFirstFrameTrackerCacheKey];
        }
    }
    return self;
}

- (void)eventBegin:(NSString *)event
{
    if (!event) {
        return;
    }
    
    if ([event isEqualToString:self.primaryKey]) {
        [self checkNewSessionBegin];
    }
    [super eventBegin:event];
}

- (void)finishTrackWithInputData:(ACCRecordViewControllerInputData *)inputData {
    self.inputData = inputData;
    [self startTrack];
}

- (void)finishTrackWithInputData:(ACCRecordViewControllerInputData *)inputData errorCode:(AWERecordFirstFrameTrackError)errorCode {
    self.inputData = inputData;
    [self failedTrackWithErrorCode:errorCode];
}

- (NSDictionary *)getBizParmas:(ACCRecordViewControllerInputData *)inputData {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    AWEVideoPublishViewModel *publishViewModel = inputData.publishModel;
    [params addEntriesFromDictionary:publishViewModel.repoRecorderTrackerTool.trackerDic ?: @{}];
    
    //track
    if (publishViewModel.repoTrack.referExtra) {
        [params addEntriesFromDictionary:publishViewModel.repoTrack.referExtra];
    }
    [params addEntriesFromDictionary:inputData.publishModel.repoTrack.commonTrackInfoDic?:@{}];
    params[@"record_count"] = @(self.recordCount);
    params[@"page_load_ui_cost"] = @(inputData.publishModel.repoRecorderTrackerTool.pageLoadUICost);
    params[@"force_load_component"] = @(self.forceLoadComponent);
    return params.copy;
}

- (void)checkNewSessionBegin {
    if (!self.finished) {
        NSAssert(NO, @"fatal error");
        [self failedTrackWithErrorCode:AWERecordFirstFrameTrackErrorDuplicated];
    }
    ACCKdebugSignPostStart(10, 0, 0, 0, 0);
    self.recordCount++;
    [ACCCache() setBool:YES forKey:kAWERecordFirstFrameTrackerCacheKey];
}

@end
