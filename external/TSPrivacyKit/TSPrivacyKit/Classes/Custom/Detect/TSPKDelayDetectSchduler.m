//
//  TSPKDelayDetectSchduler.m
//  TSPrivacyKit-Pods-AwemeCore
//
//  Created by bytedance on 2022/1/17.
//

#import "TSPKDelayDetectSchduler.h"
#import "TSPKUtils.h"
#import "TSPKLogger.h"
#import "TSPrivacyKitConstants.h"
#import "TSPKThreadPool.h"
#import "TSPKPageStatusStore.h"
#import "TSPKLock.h"

@implementation TSPKDelayDetectModel
@end

@interface TSPKDelayDetectSchduler ()

@property(nonatomic, strong) dispatch_source_t timer;
@property (nonatomic) NSTimeInterval lastCheckTime;//timestamp of last check
@property (nonatomic) NSTimeInterval scheduleDetectTime;//timestamp to schedule detect task
@property (nonatomic, strong) TSPKDelayDetectModel *delayDetectModel;
@property (nonatomic, weak) id <TSPKDelayDetectDelegate> delegate;
@property (nonatomic, strong) id<TSPKLock> lock;

@end

@implementation TSPKDelayDetectSchduler

- (instancetype)initWithDelayDetectModel:(TSPKDelayDetectModel *)delayDetectModel
                                delegate:(nonnull id<TSPKDelayDetectDelegate>)delegate {
    self = [super init];
    if (self) {
        _lock = [TSPKLockFactory getLock];
        self.delayDetectModel = delayDetectModel;
        self.delegate = delegate;
        [self addNotifications];
    }

    return self;
}

- (void)dealloc {
    [self removeNotifications];
    [self cancelDetectAction];
}

#pragma mark - Notification

- (void)addNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationBecomeInactive) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)removeNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationBecomeInactive {
    [self cancelDetectAction];
}

#pragma mark - public method

- (void)startDelayDetect {
    [self scheduleDetectAction];
}

- (void)stopDelayDetect {
    [self cancelDetectAction];
}

- (BOOL)isDelaying {
    [self.lock lock];
    BOOL isDelay = (self.timer != nil);
    [self.lock unlock];
    
    return isDelay;
}

- (NSTimeInterval)timeDelay {
    return self.delayDetectModel.detectTimeDelay;
}

#pragma mark - private method

- (void)scheduleDetectAction {
    [self.lock lock];
    BOOL isTimerExist = (self.timer != nil);
    [self.lock unlock];
    
    if (isTimerExist) {
        if (self.delayDetectModel.isCancelPrevDetectWhenStartNewDetect) {
            [self cancelDetectAction];
        } else {
            return;
        }
    }

    if (self.delayDetectModel.detectTimeDelay <= 0) {
        [self executeDetectAction];
    } else {
        [self.lock lock];
        BOOL isTimerNotExist = (self.timer == nil);

        if (isTimerNotExist) {
            self.scheduleDetectTime = [TSPKUtils getRelativeTime];
            // timer now may work on other thread, so replace NSTimer with dispatch_source_t
            dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, [[TSPKThreadPool shardPool] workQueue]);
            dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC));
            uint64_t interval = (uint64_t)(self.delayDetectModel.detectTimeDelay * NSEC_PER_SEC);
            dispatch_source_set_timer(timer, start, interval, 0);
            
            __block BOOL isFirstTrigger = YES;
            __weak typeof(self) weakSelf = self;
            dispatch_source_set_event_handler(timer, ^{
                if (isFirstTrigger) {
                    // it will trigger immediately so ignore the first time
                    isFirstTrigger = NO;
                } else {
                    // trigger
                    [weakSelf executeDetectAction];
                }
            });
            dispatch_resume(timer);
        
            self.timer = timer;
        }
        [self.lock unlock];
    }
}

- (void)cancelDetectAction {
    self.scheduleDetectTime = 0;
    [self.lock lock];
    if (self.timer) {
        dispatch_source_cancel(self.timer);
        self.timer = nil;
    }
    [self.lock unlock];
}

- (void)executeDetectAction {
    // precheck block
    if ([self.delegate respondsToSelector:@selector(isContinueExecuteAction)]) {
        BOOL isContinue = [self.delegate isContinueExecuteAction];
        
        if (!isContinue) {
            [self cancelDetectAction];
            return;
        }
    }
    
    NSTimeInterval now = [TSPKUtils getRelativeTime];
    
    //reset the schedule
    self.lastCheckTime = now;
    NSTimeInterval timeGap = now - self.scheduleDetectTime;
    if (self.scheduleDetectTime < DBL_EPSILON) {
        timeGap = 0;
    }
        
    // cancel timer
    [self cancelDetectAction];
    
    if (self.delayDetectModel.isAnchorPageCheck) {
        // double check whether the cared VC is still appear
        NSString *comparedVC;
        if ([self.delegate respondsToSelector:@selector(getComparePage)]) {
            comparedVC = [self.delegate getComparePage];
        }
        
        if ([[TSPKPageStatusStore shared] pageStatus:comparedVC] == TSPKPageStatusDisappear) {
            [TSPKLogger logWithTag:TSPKLogCheckTag message:[NSString stringWithFormat:@"detect cancelled, anchorPage %@ already disappear", comparedVC]];
            return;
        }
        
        // double check whether the top VC is the cared VC
        __block NSString *curTopVC = nil;
        if ([NSThread isMainThread]) {
            curTopVC = [TSPKUtils topVCName];
        } else {
            NSCondition *waitHandle = [NSCondition new];
            dispatch_async(dispatch_get_main_queue(), ^(){
                curTopVC = [TSPKUtils topVCName];
                [waitHandle signal];
            });
            [waitHandle waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        }
        
        if (curTopVC && comparedVC && ![curTopVC isEqualToString:comparedVC]) {
            NSString *content = [NSString stringWithFormat:@"detect cancelled, curTopPageName:%@ comparedPageName:%@", curTopVC ? curTopVC: @"unknown", comparedVC ? comparedVC: @"unknown"];
            [TSPKLogger logWithTag:TSPKLogCheckTag message:content];
            return;
        }
    }
    
    // execute detect block
    if ([self.delegate respondsToSelector:@selector(executeDetectWithActualTimeGap:)]) {
        NSTimeInterval timeGapToCancelDetect = MAX(timeGap, self.delayDetectModel.detectTimeDelay);
        [self.delegate executeDetectWithActualTimeGap:timeGapToCancelDetect];
    }
}

@end
