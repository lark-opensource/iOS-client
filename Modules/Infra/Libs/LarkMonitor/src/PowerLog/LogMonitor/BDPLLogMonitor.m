//
//  BDPLLogMonitor.m
//  LarkMonitor
//
//  Created by ByteDance on 2023/4/24.
//

#import "BDPLLogMonitor.h"
#import "BDPowerLogUtility.h"
@interface BDPLLogMonitor()
{
    NSLock *_lock;
    long long _preTotalCount;
    long long _preTimeStamp;
    NSMutableDictionary *_counterDict;
    NSMutableDictionary *_totalCounterDict;
    NSLock *_dataLock;
    dispatch_source_t _timer;
}
@property (nonatomic, copy, readwrite) NSString *type;
@property (nonatomic, copy, readwrite) BDPLLogMonitorConfig *config;
@property (nonatomic, assign, readwrite) BOOL enable;
@property (nonatomic, assign, readwrite) long long totalLogCount;

@end

@implementation BDPLLogMonitor

+ (instancetype)monitorWithType:(NSString *)type config:(BDPLLogMonitorConfig *)config {
    return [[BDPLLogMonitor alloc] initWithType:type config:config];
}

- (instancetype)initWithType:(NSString *)type config:(BDPLLogMonitorConfig *)config {
    if (self = [self init]) {
        self.type = type;
        self.config = config;
        _lock = [[NSLock alloc] init];
        _counterDict = [NSMutableDictionary dictionary];
        _totalCounterDict = [NSMutableDictionary dictionary];
        _dataLock = [[NSLock alloc] init];
    }
    return self;
}

- (void)start {
    [_lock lock];
    if (!_enable) {
        _enable = YES;
        if (_timer) {
            dispatch_cancel(_timer);
        }
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
        dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, self.config.timewindow * NSEC_PER_SEC, 0);
        WEAK_SELF
        dispatch_source_set_event_handler(_timer, ^{
            STRONG_SELF
            if (!strongSelf)
                return;
            [strongSelf timerFired];
        });
        dispatch_resume(self->_timer);
    }
    [_lock unlock];
}

- (void)timerFired {
    if (!self.enable) return;
    
    [_dataLock lock];
    
    long long timestamp = (long long)(CACurrentMediaTime() * 1000);
    if (_preTimeStamp > 0) {
        long long deltaTime = timestamp - _preTimeStamp;
        //delta time is too short
        if (deltaTime < self.config.timewindow * 1000 * 0.5) {
            [_dataLock unlock];
            return;
        }
        
        long long deltaCount = _totalLogCount - _preTotalCount;
        double deltaCountPerSec = deltaCount / (deltaTime / 1000.0);
        
        if (deltaCountPerSec >= self.config.logThresholdPerSecond) { //high power event -> xlog、applog、slardarlog
            id<BDPLLogMonitorDelegate> delegate = self.delegate;
            if ([delegate respondsToSelector:@selector(onHighFrequentEvents:deltaTime:count:counterDict:)]) {
                [delegate onHighFrequentEvents:self deltaTime:deltaTime count:deltaCount counterDict:_counterDict];
            }
        }
        
        [_counterDict removeAllObjects];
    }
    _preTotalCount = _totalLogCount;
    _preTimeStamp = timestamp;
    
    [_dataLock unlock];
}

- (void)stop {
    [_lock lock];
    if (_enable) {
        _enable = NO;
        if (_timer) {
            dispatch_cancel(_timer);
            _timer = NULL;
        }
    }
    [_lock unlock];
}

- (void)addLog:(NSString *)category {
    if (!_enable) return;
        
    [_dataLock lock];
    _totalLogCount += 1;
    long long val = [[_counterDict bdpl_objectForKey:category cls:NSNumber.class] longLongValue];
    [_counterDict bdpl_setObject:@(val + 1) forKey:category];
    if (_config.enableLogCountMetrics) {
        long long total = [[_totalCounterDict bdpl_objectForKey:category cls:NSNumber.class] longLongValue];
        [_totalCounterDict bdpl_setObject:@(total + 1) forKey:category];
    }
    [_dataLock unlock];
}

- (NSDictionary *)totalCounterDict {
    if (!_enable || !_config.enableLogCountMetrics) return nil;
    
    [_dataLock lock];
    
    NSMutableDictionary *counterDict = [_totalCounterDict mutableCopy];
    [counterDict bdpl_setObject:@(_totalLogCount) forKey:@"__total_log_count__"];
        
    [_dataLock unlock];
    return counterDict;
}

@end
