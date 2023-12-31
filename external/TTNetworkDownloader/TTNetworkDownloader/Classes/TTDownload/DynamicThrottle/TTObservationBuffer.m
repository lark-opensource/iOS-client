
#import "TTObservationBuffer.h"
#import "TTObservation.h"
#import "TTDownloadLog.h"

NS_ASSUME_NONNULL_BEGIN

static const NSUInteger kBufferSizeDefault = 5;

@interface TTObservationBuffer ()

@property (nonatomic, assign) NSUInteger bufferSizeMax;

@property (nonatomic, strong) NSMutableArray *list;

@end

@implementation TTObservationBuffer

- (id)initWithCapacity:(NSUInteger)size {
    self = [super init];
    if (self) {
        self.bufferSizeMax = size > 0 ? size : kBufferSizeDefault;
        self.list = [[NSMutableArray alloc] initWithCapacity:self.bufferSizeMax];
    }
    return self;
}

- (void)setCapacity:(NSUInteger)size {
    @synchronized (self.list) {
        if (size > 0) {
            self.bufferSizeMax = size;
        }
    }
}

- (void)addObservation:(TTObservation *)observation {
    @synchronized (self.list) {
        while (self.list.count >= self.bufferSizeMax) {
            [self.list removeObjectAtIndex:0];
        }
        [self.list addObject:observation];
    }
    DLLOGD(@"dynamicSpeed6::throttle:self.list.size=%lu", (unsigned long)self.list.count);
}

- (BOOL)isFull {
    @synchronized (self.list) {
        DLLOGD(@"dynamicSpeed6:self.list.count=%lu,self.buffSize=%lu", (unsigned long)self.list.count, (unsigned long)self.bufferSizeMax);
        return self.list.count >= self.bufferSizeMax;
    }
}

- (NSUInteger)getBufferRealSize {
    @synchronized (self.list) {
        return self.list.count;
    }
}

- (BOOL)isEmpty {
    @synchronized (self.list) {
        return self.list.count == 0;
    }
}

- (void)clearBuff {
    DLLOGD(@"enter clearBuff");
    @synchronized (self.list) {
        [self.list removeAllObjects];
    }
}

- (BOOL)isExistSameCheckResultType:(TTObservation *)observation {
    @synchronized (self.list) {
        NSUInteger ret = ~0U;
        for (TTObservation *obj in self.list) {
            ret &= obj.checkResult;
        }
        DLLOGD(@"dynamicSpeed6:isExistSameCheckResultType:printMark:%@", [self printMark:(ret &= observation.checkResult)]);
        return ret &= observation.checkResult;
    }
}

#ifdef DOWNLOADER_DEBUG
- (NSString *)printMark:(NSUInteger)mark {
    int count = sizeof(mark) * 8;
    NSString *str = @"";
    for (int i = 0; i < count; i++) {
        if (mark & (1 << i)) {
            str = [@"1" stringByAppendingString:str];
        } else {
            str = [@"0" stringByAppendingString:str];
        }
    }
    DLLOGD(@"str = %@", str);
    return str;
}
#endif

- (void)addObservationWithBuffer:(TTObservationBuffer *)newObservationBuffer {
    DLLOGD(@"enter addObserveWithBuffer");
    if (!newObservationBuffer) {
        return;
    }
    
    TTObservation *observation = nil;
    while (nil != (observation = [newObservationBuffer getFirstObservation])) {
        [self addObservation:observation];
    }
}

- (TTObservation *)getFirstObservation {
    @synchronized (self.list) {
        TTObservation *ret = [self.list firstObject];
        if (ret) {
            [self.list removeObjectAtIndex:0];
        }
        DLLOGD(@"getFirstObservation");
        return ret;
    }
}

- (NSUInteger)observationCheckByPercent:(TTObservation *)observation
                             percent:(float)percent
                              rttGap:(NSInteger)rttGap
                            speedGap:(int64_t)speedGap {
    uint8_t tcp_rtt_increase_count  = 0U;
    uint8_t tcp_rtt_decrease_count  = 0U;
    uint8_t http_rtt_increase_count = 0U;
    uint8_t http_rtt_decrease_count = 0U;
    uint8_t net_type_be_good_count  = 0U;
    uint8_t net_type_be_bad_count   = 0U;
    uint8_t speed_too_low_count     = 0U;
    NSUInteger observationCount     = 0U;
    NSUInteger ret                  = 0U;
    
    @synchronized (self.list) {
        observationCount = ceil(percent * self.list.count);
        for (TTObservation *obj in self.list) {
            if (observation.tcpRtt > obj.tcpRtt + rttGap) {
                tcp_rtt_increase_count++;
            } else if (observation.tcpRtt + rttGap < obj.tcpRtt) {
                tcp_rtt_decrease_count++;
            }
            
            if (observation.httpRtt > obj.httpRtt + rttGap) {
                http_rtt_increase_count++;
            } else if (observation.httpRtt + rttGap < obj.httpRtt) {
                http_rtt_decrease_count++;
            }
            
            if (observation.netQualityType > obj.netQualityType) {
                net_type_be_good_count++;
            } else if (observation.netQualityType < obj.netQualityType) {
                net_type_be_bad_count++;
            }
            
            if ((observation.realNetSpeed + speedGap) < observation.throttleSpeed) {
                speed_too_low_count++;
            }
        }
    }
    
    if (tcp_rtt_increase_count >= observationCount) {
        ret |= TCP_RTT_INCREASE;
    }
    
    if (tcp_rtt_decrease_count >= observationCount) {
        ret |= TCP_RTT_DECREASE;
    }
    
    if (http_rtt_increase_count >= observationCount) {
        ret |= HTTP_RTT_INCREASE;
    }
    
    if (http_rtt_decrease_count >= observationCount) {
        ret |= HTTP_RTT_DECREASE;
    }
    
    if (net_type_be_good_count >= observationCount) {
        ret |= NET_BE_GOOD;
    }
    
    if (net_type_be_bad_count >= observationCount) {
        ret |= NET_BE_BAD;
    }
    
    if (speed_too_low_count >= observationCount) {
        ret |= DOWNLOAD_SPEED_TOO_LOW;
    }
    
    observation.checkResult = ret;
    DLLOGD(@"dynamicSpeed6:tcp_rtt_increase_count=%u", tcp_rtt_increase_count);
    DLLOGD(@"dynamicSpeed6:tcp_rtt_decrease_count=%u", tcp_rtt_decrease_count);
    DLLOGD(@"dynamicSpeed6:http_rtt_increase_count=%u", http_rtt_increase_count);
    DLLOGD(@"dynamicSpeed6:http_rtt_decrease_count=%u", http_rtt_decrease_count);
    DLLOGD(@"dynamicSpeed6:net_type_be_good_count=%u", net_type_be_good_count);
    DLLOGD(@"dynamicSpeed6:net_type_be_bad_count=%u", net_type_be_bad_count);
    DLLOGD(@"dynamicSpeed6:speed_too_low_count=%u", speed_too_low_count);
    DLLOGD(@"dynamicSpeed6:ret=%lu", (unsigned long)ret);
    
    return ret;
}

- (TTObservation *)getAverageObservation:(NSInteger)newestObservationCount {
    if (newestObservationCount <= 0) {
        return nil;
    }
    @synchronized (self.list) {
        TTObservation *observation = [[TTObservation alloc] init];
        NSInteger observationCount = newestObservationCount;
        NSUInteger i = self.list.count;
        for (; i > 0 && observationCount > 0; i--, observationCount--) {
            TTObservation *obj = [self.list objectAtIndex:(i - 1)];
            observation.tcpRtt += obj.tcpRtt;
            observation.httpRtt += obj.httpRtt;
            observation.realNetSpeed += obj.realNetSpeed;
        }
        
        if (!observationCount) {
            observation.tcpRtt = ceil((float)observation.tcpRtt / newestObservationCount);
            observation.httpRtt = ceil((float)observation.httpRtt / newestObservationCount);
            observation.realNetSpeed = ceil((float)observation.realNetSpeed / newestObservationCount);
        }
        
        if (!i && observationCount) {
            observation.tcpRtt = ceil((float)observation.tcpRtt / self.list.count);
            observation.httpRtt = ceil((float)observation.httpRtt / self.list.count);
            observation.realNetSpeed = ceil((float)observation.realNetSpeed / self.list.count);
        }
        
        TTObservation *obj = [self.list lastObject];
        observation.netQualityType = obj.netQualityType;
        return observation;
    }
}

@end

NS_ASSUME_NONNULL_END
