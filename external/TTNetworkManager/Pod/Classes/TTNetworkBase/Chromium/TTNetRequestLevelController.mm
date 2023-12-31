//
//  TTNetRequestLevelController.m
//  TTNetworkManager
//
//  Created by liuzhe on 2021/9/2.
//

#import "TTNetRequestLevelController.h"
#import "TTHttpTaskChromium.h"
#import "TTRequestDispatcher.h"

@interface TTNetRequestLevelController()
#ifndef DISABLE_REQ_LEVEL_CTRL
// all request status env var
@property(atomic, assign) NSTimeInterval p0LastPassTime;
@property(atomic, assign) int p0Count;
@property(atomic, assign) int p1Count;

// request wait and notify
@property(nonatomic, assign) BOOL requestLevelControlEnabled;
@property(atomic, strong) NSMutableArray<TTHttpTaskChromium*>* p1WaitingQueue;
@property(atomic, strong) NSLock* queueLock;

// tnc config
@property(atomic, assign) BOOL requestLevelControlTNCEnabled;
@property(atomic, strong) NSLock* tncParamLock;
@property(nonatomic, strong) NSSet<NSString*>* p0PathSet;
@property(nonatomic, strong) NSSet<NSString*>* p2PathSet;
@property(atomic, assign) int p1Random;
@property(atomic, assign) long p0Countdown;
@property(atomic, assign) int p1MaxCount;
#endif
@end

@implementation TTNetRequestLevelController
#ifndef DISABLE_REQ_LEVEL_CTRL

+(instancetype)shareInstance {
    static id singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

-(id)init {
    self = [super init];
    if (self) {
        _p0Count = 0;
        _p0LastPassTime = 0;
        _p1Count = 0;
        _requestLevelControlEnabled = NO;
        _p1WaitingQueue = [NSMutableArray array];
        _queueLock = [[NSLock alloc] init];
        _requestLevelControlTNCEnabled = NO;
        _p0PathSet = [NSSet set];
        _p2PathSet = [NSSet set];
        _tncParamLock = [[NSLock alloc] init];
        _p1Random = 0;
        _p0Countdown = 0;
        _p1MaxCount = 0;
    }
    return self;
}

-(void)start {
    self.p0Count = 0;
    self.p1Count = 0;
    self.requestLevelControlEnabled = YES;
}

-(void)stop {
    self.p0Count = 0;
    self.p1Count = 0;
    self.requestLevelControlEnabled = NO;
    [self releaseP1Request];
}

-(BOOL)isRequestLevelControlEnabled {
    return self.requestLevelControlEnabled
            && self.requestLevelControlTNCEnabled
            && ![[TTRequestDispatcher shareInstance] isRequestDispatcherWorking];
}

// The First thing a task should do is get its own level
-(int)getLevelForRequestPath:(NSString*)path {
    [self.tncParamLock lock];
    int level = 1;
    if ([self isPathInSet:self.p0PathSet path:path]) {
        self.p0LastPassTime = [[NSDate date] timeIntervalSince1970] * 1000;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.p0Countdown * NSEC_PER_MSEC)),
                       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if ([[NSDate date] timeIntervalSince1970] - self.p0LastPassTime >= self.p0Countdown && self.p0Count > 0) {
                [self releaseP1Request];
            }
        });
        level = 0;
        ++self.p0Count;
    } else if ([self isPathInSet:self.p2PathSet path:path]) {
        level = [self checkP0Done] == YES ? 0 : 2;
    } else {
        ++self.p1Count;
        level = 1;
    }
    [self.tncParamLock unlock];
    return level;
}

// call this method when level is 1
-(BOOL)maybeAddP1Task:(TTHttpTaskChromium*)httpTask {
    if ([self checkP0Done] == YES || self.p1Count > self.p1MaxCount) {
        return NO;
    }
    
    [self.queueLock lock];
    [self.p1WaitingQueue addObject:httpTask];
    [self.queueLock unlock];
    return YES;
}

-(BOOL)checkP0Done {
    if (self.p0Count <= 0) {
        return YES;
    }
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970] * 1000;
    if (time - self.p0LastPassTime > self.p0Countdown) {
        return YES;
    }
    
    return NO;
}

-(void)notifyTaskCancel:(TTHttpTaskChromium*)httpTask {
    [self.queueLock lock];
    if (self.p1WaitingQueue.count > 0 && [self.p1WaitingQueue containsObject:httpTask]) {
        [self.p1WaitingQueue removeObject:httpTask];
    }
    [self.queueLock unlock];
}

-(void)notifyTaskFinish:(TTHttpTaskChromium*)httpTask {
    if (httpTask.level == 0 && self.p0Count > 0) {
        --self.p0Count;
        if (self.p0Count == 0) {
            [self releaseP1Request];
        }
    } else if (httpTask.level == 1 && self.p1Count > 0) {
        --self.p1Count;
    }
}

-(void)releaseP1Request {
    [self.queueLock lock];
    for (TTHttpTaskChromium *task in self.p1WaitingQueue) {
        int delay = 0;
        if (self.p1Count > 3) {
            delay = (arc4random() % self.p1Random);
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_MSEC)),
                       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [task resume];
        });
    }
    [self.p1WaitingQueue removeAllObjects];
    [self.queueLock unlock];
}

- (void)getReqCtlConfig:(NSDictionary*)data {
    self.requestLevelControlTNCEnabled = NO;
    if (!data) return;
    
    id configData = data[@"runtime_req_ctl_config"];
    if (!configData) return;
    
    [self.tncParamLock lock];
    self.requestLevelControlTNCEnabled = YES;
    NSDictionary* configDict = configData;
    
    id p0Array = configDict[@"p0"];
    if (p0Array) {
        self.p0PathSet = [NSSet setWithArray:p0Array];
    }
    id p2Array = configDict[@"p2"];
    if (p2Array) {
        self.p2PathSet = [NSSet setWithArray:p2Array];
    }
    id p0Countdown = configDict[@"p0_countdown"];
    if (p0Countdown) {
        self.p0Countdown = [p0Countdown intValue];
    }
    id p1Random = configDict[@"p1_random"];
    if (p1Random) {
        self.p1Random = [p1Random intValue];
    }
    id p1MaxCount = configDict[@"p1_maxCount"];
    if (p1MaxCount) {
        self.p1MaxCount = [p1MaxCount intValue];
    }
    [self.tncParamLock unlock];
}

-(BOOL)isPathInSet:(NSSet*)set path:(NSString*)path {
    for (NSString* prefix in set) {
        if ([path hasPrefix:prefix]) {
            return YES;
        }
    }
    return NO;
}
#endif
@end
