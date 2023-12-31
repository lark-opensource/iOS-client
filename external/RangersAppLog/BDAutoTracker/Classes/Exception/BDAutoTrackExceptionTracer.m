//
//  BDAutoTrackExceptionTracer.m
//  RangersAppLog
//
//  Created by bytedance on 2022/8/12.
//

#import "BDAutoTrack+Private.h"
#import "BDAutoTrackDeviceHelper.h"
#import "BDAutoTrackSandBoxHelper.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrackSessionHandler.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackDefaults.h"
#import "BDAutoTrackExceptionTracer.h"

static NSString * const kBDAutoTrackExceptionCrashKey        = @"crash_key";
static NSString * const kBDAutoTrackExceptionCrash           = @"$crash";
static NSString * const kBDAutoTrackExceptionOSVersion       = @"$os_version";
static NSString * const kBDAutoTrackExceptionAppVersion      = @"$app_version";
static NSString * const kBDAutoTrackExceptionDeviceModel     = @"$device_model";
static NSString * const kBDAutoTrackExceptionResolution      = @"$resolution";
static NSString * const kBDAutoTrackExceptionAppChannel      = @"$app_channel";
static NSString * const kBDAutoTrackExceptionCPU             = @"$cpu";
static NSString * const kBDAutoTrackExceptionSessionDuration = @"$session_duration";
static NSString * const kBDAutoTrackExceptionIsBackstage     = @"$is_backstage";
static NSString * const kBDAutoTrackExceptionCrashThread     = @"$crash_thread";
static NSString * const kBDAutoTrackExceptionCrashProcess    = @"$crash_process";
static NSString * const kBDAutoTrackExceptionRom             = @"$rom";
static NSString * const kBDAutoTrackExceptionEventTime       = @"$event_time";
static NSString * const kBDAutoTrackExceptionDetailedStack   = @"$detailed_stack";

@interface BDAutoTrackExceptionTracer()

@property (nonatomic, assign) BOOL hasInit;

@property (nonatomic) NSUncaughtExceptionHandler *originHandler;

@end

@implementation BDAutoTrackExceptionTracer

#pragma mark: init

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static BDAutoTrackExceptionTracer *sharedInstance;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    
    return sharedInstance;
}

- (void)dealloc {}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.hasStart = NO;
        self.hasInit = NO;
        [self sendException];
    }
    return self;
}

#pragma mark: implementation

- (void)start {
    self.hasStart = YES;
    if(!self.hasInit) {
        self.originHandler = NSGetUncaughtExceptionHandler();
        NSSetUncaughtExceptionHandler(&ExceptionHandler);
    }
}

- (void)stop {
    self.hasStart = NO;
}

- (NSString *)parseDetailStack:(NSException *)exception {
    NSInteger max = 100;
    if (exception.callStackSymbols) {
        NSArray *stacks = exception.callStackSymbols;
        if (exception.callStackSymbols.count > max) {
            stacks = [exception.callStackSymbols subarrayWithRange:NSMakeRange(0, max)];
        }
        return [stacks componentsJoinedByString:@"\n"];
    }
    return [NSString stringWithFormat:@"%@", exception.reason];
}

- (void)traceException:(NSException *)exception {
    if (!self.hasStart) {
        return;
    }
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:16];
    [params setValue:bd_device_systemVersion() forKey:kBDAutoTrackExceptionOSVersion];
    [params setValue:bd_sandbox_releaseVersion() forKey:kBDAutoTrackExceptionAppVersion];
    [params setValue:bd_device_decivceModel() forKey:kBDAutoTrackExceptionDeviceModel];
    [params setValue:bd_device_resolutionString() forKey:kBDAutoTrackExceptionResolution];
    [params setValue:bd_device_cpuType() forKey:kBDAutoTrackExceptionCPU];
    [params setValue:@([BDAutoTrackSessionHandler.sharedHandler computeTotalDuration]) forKey:kBDAutoTrackExceptionSessionDuration];
    [params setValue:@(BDAutoTrackSessionHandler.sharedHandler.shouldMarkLaunchedPassively) forKey:kBDAutoTrackExceptionIsBackstage];
    [params setValue:[NSString stringWithFormat:@"%@", NSThread.currentThread] forKey:kBDAutoTrackExceptionCrashThread];
    [params setValue:@"" forKey:kBDAutoTrackExceptionCrashProcess];
    [params setValue:@"" forKey:kBDAutoTrackExceptionRom];
    [params setValue:@(bd_currentInterval().doubleValue * 1000) forKey:kBDAutoTrackExceptionEventTime];
    [params setValue:[self parseDetailStack:exception] forKey:kBDAutoTrackExceptionDetailedStack];
    
    NSArray<BDAutoTrack *> *allTracker = [BDAutoTrack allTrackers];
    for (BDAutoTrack *track in allTracker) {
        if ([track isKindOfClass:[BDAutoTrack class]]) {
            BDAutoTrackLocalConfigService *setting = track.localConfig;
            [params setValue:setting.channel forKey:kBDAutoTrackExceptionAppChannel];
            BDAutoTrackDefaults *defaults = [BDAutoTrackDefaults defaultsWithAppID:track.appID];
            [defaults setValue:params forKey:kBDAutoTrackExceptionCrashKey];
//            NSLog(@"save >>> %@ -> %@", track, params);
        }
    }
}

- (void)sendException {
    NSArray<BDAutoTrack *> *allTracker = [BDAutoTrack allTrackers];
    for (BDAutoTrack *track in allTracker) {
        if (![track isKindOfClass:[BDAutoTrack class]]) {
            continue;;
        }
        BDAutoTrackDefaults *defaults = [BDAutoTrackDefaults defaultsWithAppID:track.appID];
        NSDictionary *params = [defaults dictionaryValueForKey:kBDAutoTrackExceptionCrashKey];
//        NSLog(@"read >>> %@ -> %@", track, params);
        if (params) {
            [track eventV3:kBDAutoTrackExceptionCrash params:params];
            [defaults setValue:nil forKey:kBDAutoTrackExceptionCrashKey];
        }
    }
}

static void ExceptionHandler(NSException *exception) {
    @try {
        [BDAutoTrackExceptionTracer.shared traceException:exception];
    } @catch (NSException *exception2) {
        RL_WARN(nil, @"[Exception]", @"%@", exception2);
    }
    BDAutoTrackExceptionTracer.shared.originHandler(exception);
}

@end
