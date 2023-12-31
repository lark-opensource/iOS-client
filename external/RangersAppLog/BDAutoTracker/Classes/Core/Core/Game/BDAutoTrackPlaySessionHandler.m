//
//  BDAutoTrackPlaySessionHandler.m
//  Applog
//
//  Created by bob on 2019/4/10.
//

#import "BDAutoTrackPlaySessionHandler.h"
#import "BDAutoTrack+Private.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackTimer.h"
#import "BDAutoTrackMacro.h"
#import "BDAutoTrackUtility.h"
#import "NSDictionary+VETyped.h"

static NSString *const kBDAutoTrackerPlaySessionTimer           = @"PlaySessionTimer";
static NSString *const kBDAutoTrackerPlaySessionNo              = @"kBDAutoTrackerPlaySessionNo";

static NSString *const kBDAutoTrackerPlaySessionEventName       = @"play_session";
static const NSTimeInterval  kBDAutoTrackerPlaySessionInterval  = 60;

@interface BDAutoTrackPlaySessionHandler ()

@property (nonatomic, copy) NSString *startTime;
@property (nonatomic, assign) NSUInteger sessionNumber;
@property (nonatomic, copy) NSString *sessionDate;
@property (nonatomic, assign) NSUInteger sendTimes;
@property (nonatomic, assign) NSTimeInterval lastRecordTime;
@property (nonatomic, assign) BOOL started;

/// 在此队列打playSessionEvent
@property (nonatomic, strong) dispatch_queue_t playSessionEventQueue;

@property (nonatomic, strong) NSMutableDictionary *sessionData;


@end

@implementation BDAutoTrackPlaySessionHandler

- (instancetype)init {
    self = [super init];
    if (self) {
        self.playSessionInterval = kBDAutoTrackerPlaySessionInterval;
        self.playSessionEventQueue = dispatch_queue_create("com.applog.playSessionEvent", DISPATCH_QUEUE_SERIAL);
        [self loadSessionData];
    }
    
    return self;
}

- (NSString *)sessionDataPath
{
    return [bd_trackerLibraryPath() stringByAppendingPathComponent:@"session.dat"];
}

- (void)loadSessionData
{
    @try {
        NSString *path = [self sessionDataPath];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSDictionary* sessionData = [NSDictionary dictionaryWithContentsOfFile:path];
            if (sessionData && [sessionData isKindOfClass:[NSDictionary class]]) {
                self.sessionNumber = [[sessionData objectForKey:@"sno"] unsignedLongValue];
                self.sessionDate = [sessionData objectForKey:@"sdt"];
            }
        }
    }@catch(...){}
}

- (void)saveSessionData
{
    @try {
        NSString *path = [self sessionDataPath];
        NSString *sessionDt = [self.sessionDate copy];
        NSNumber *sessionNo = @(self.sessionNumber);
        NSDictionary *data = @{
            @"sno":sessionNo,
            @"sdt":sessionDt?:@""
        };
        [data writeToFile:path atomically:YES];
    }@catch(...){};
}

- (void)startPlaySessionWithTime:(NSString *)startTime {
    
    self.lastRecordTime = CFAbsoluteTimeGetCurrent();
    self.startTime = startTime;
    self.sendTimes = 0;
    NSString *nowDate = bd_dateTodayString();
    if ([self.sessionDate isEqualToString:nowDate]) { //saveDay
        self.sessionNumber += 1;
    } else {
        self.sessionNumber = 1;
        self.sessionDate = nowDate;
    }
    self.started = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self saveSessionData];
    });
    
    BDAutoTrackWeakSelf;
    dispatch_block_t action = ^{
        BDAutoTrackStrongSelf;
        [self playSessionEvent];
    };
    [[BDAutoTrackTimer sharedInstance] scheduledDispatchTimerWithName:kBDAutoTrackerPlaySessionTimer
                                                         timeInterval:self.playSessionInterval
                                                                queue:self.playSessionEventQueue
                                                              repeats:YES
                                                               action:action];
}

- (void)stopPlaySession {
    if (self.started) {
        dispatch_async(self.playSessionEventQueue, ^{
            [self playSessionEvent];
        });
    }
    self.started = NO;
    [[BDAutoTrackTimer sharedInstance] cancelTimerWithName:kBDAutoTrackerPlaySessionTimer];
}

/*!游戏模式心跳事件。此方法永远会被调用，但是只会向开启gameModeEnable开关的实例入库playSession事件。
 * 执行队列: self.playSessionEventQueue
 * @discussion
 * play_session 事件触发逻辑：
 * Android 端：
 * 1、进入前台（包括启动应用）时
 * 2、进入后台时
 * 3、使用期间每分钟上报
 * 4、页面切换时
 * iOS 端：
 * 1. 进入前台（包括启动应用）时
 * 2. 进入后台时
 * 3. 使用期间每分钟上报
 * 4. 切换UUID时
*/
- (void)playSessionEvent {
    if (self.started) {
        self.sendTimes++;
        
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:4];
        [params setValue:self.startTime forKey:@"session_start_time"];
        [params setValue:@(self.sessionNumber) forKey:@"session_no"];
        [params setValue:@(self.sendTimes) forKey:@"send_times"];
        CFTimeInterval current = CFAbsoluteTimeGetCurrent();
        [params setValue:@((NSUInteger)(current - self.lastRecordTime)) forKey:@"current_duration"];
        self.lastRecordTime = current;
        NSDictionary *data = @{kBDAutoTrackEventType:kBDAutoTrackerPlaySessionEventName,
                               kBDAutoTrackEventData:params
        };
        [BDAutoTrack trackPlaySessionEventWithData:data];
    }
}

@end
