//
//  TTVideoEngineEventManager.m
//  Pods
//
//  Created by guikunzhi on 16/12/23.
//
//

#import "TTVideoEngineEventManager.h"
#import "TTVideoEngineUtil.h"
#import "TTVideoEngineUtilPrivate.h"
#import "TTVideoEngine+Tracker.h"

static const NSUInteger kLatestEventsCount = 10;

@interface TTVideoEngineEventManager ()

@property (nonatomic, strong) NSMutableArray *events;
@property (nonatomic, strong) NSMutableArray *latestEvents;
@property (nonatomic, strong) dispatch_queue_t eventQueue;
@property (nonatomic, assign) NSInteger eventVersion;

@end

@implementation TTVideoEngineEventManager

static TTVideoEngineEventManager *manager;
static const void *eventQueueKey = &eventQueueKey;

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[TTVideoEngineEventManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        _eventQueue = dispatch_queue_create("vclould.engine.eventManager.queue", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(_eventQueue, eventQueueKey, (void *_Nullable)eventQueueKey, nil);
        _events = [NSMutableArray array];
        _latestEvents = [NSMutableArray array];
        _eventVersion = TTEVENT_LOG_VERSION_NEW;
    }
    return self;
}

- (void)setLogVersion:(NSInteger)version {
    TTVideoEngineLog(@"setLogVersion:%d", version);
    if (version == TTEVENT_LOG_VERSION_NEW || version == TTEVENT_LOG_VERSION_OLD) {
        _eventVersion = version;
    }
}

- (NSInteger)logVersion {
    TTVideoEngineLog(@"getLogVersion:%d", _eventVersion);
    return _eventVersion;
}

- (void)addEvent:(NSDictionary *)event {
    dispatch_async(self.eventQueue, ^{
        if (!event) {
            return;
        }
        
        [self.events addObject:[event copy]];
        NSDictionary *merror = [event objectForKey:@"merror"];
        if (merror) {
            [self.latestEvents  addObject:[event copy]];
        }
        if (self.latestEvents.count > kLatestEventsCount) {
            [self.latestEvents removeObjectAtIndex:0];
        }
        
        if (self.innerDelegate) {
            if ([self.innerDelegate respondsToSelector:@selector(eventManagerDidUpdate:)]) {
                [self.innerDelegate eventManagerDidUpdate:self];
            }
        } else {
            id<TTVideoEngineReporterProtocol> reportManager = [[TTVideoEngine reportHelperClass] sharedManager];
            
            if (reportManager && reportManager.enableAutoReportLog) {
                [reportManager autoReportEventlogIfNeededV1:self];
            } else {
                if (self.delegate && [self.delegate respondsToSelector:@selector(eventManagerDidUpdate:)]) {
                    [self.delegate eventManagerDidUpdate:self];
                }
            }
        }
    });
}

- (void)addEventV2:(NSDictionary *)event eventName:(NSString *)eventName {
    dispatch_async(self.eventQueue, ^{
        if (!event) {
            return;
        }
        
        if (self.innerDelegate) {
            if (self.innerDelegate && [self.delegate respondsToSelector:@selector(eventManagerDidUpdateV2:eventName:params:)]) {
                [self.innerDelegate eventManagerDidUpdateV2:self eventName:eventName params:event];
            }
        } else {
            id<TTVideoEngineReporterProtocol> reportManager = [[TTVideoEngine reportHelperClass] sharedManager];
            if (reportManager && reportManager.enableAutoReportLog) {
                [reportManager autoReportEventlogIfNeededV2WithEventName:eventName params:event];
            } else {
                if (self.delegate && [self.delegate respondsToSelector:@selector(eventManagerDidUpdateV2:eventName:params:)]) {
                    [self.delegate eventManagerDidUpdateV2:self eventName:eventName params:event];
                }
            }
        }
    });
}

- (NSArray<NSDictionary *> *)popAllEvents {
    __block NSArray *events;
    dispatch_block_t block = ^(){
        events = [NSArray arrayWithArray:self.events];
        self.events = [NSMutableArray array];
    };
    if (dispatch_get_specific(eventQueueKey) == eventQueueKey) {
        block();
    }
    else {
        dispatch_sync(self.eventQueue, ^{
            block();
        });
    }
    return events;
}

- (NSArray<NSDictionary *> *)feedbackEvents {
    __block NSArray *events;
    dispatch_block_t block = ^(){
        events = [NSArray arrayWithArray:self.latestEvents];
        self.latestEvents = [NSMutableArray array];
    };
    if (dispatch_get_specific(eventQueueKey) == eventQueueKey) {
        block();
    }
    else {
        dispatch_sync(self.eventQueue, ^{
            block();
        });
    }
    return events;
}

@end
