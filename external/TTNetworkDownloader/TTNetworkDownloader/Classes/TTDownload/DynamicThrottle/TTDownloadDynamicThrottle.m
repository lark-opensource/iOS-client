#import "TTDownloadDynamicThrottle.h"

NS_ASSUME_NONNULL_BEGIN

static const uint8_t kMeasureSpeedTimesDefault = 3; //measure bandwidth 3 times

//if real bandwidth less than 500kb/s,throttle speed will be lowest.
static const int64_t kStartThrottleBandWidthMin = 500 * 1024;
static const int64_t kDownloadLowestSpeed = 10;
static const uint8_t kObservationBufferLengthDefault = 5;
static const uint8_t kCheckObservationBufferLengthDefault = 5;
static const float_t kMatchConditionPercentDefault = 1.0;
static const uint8_t kRttGapDefault = 20; //20ms
static const int64_t kSpeedGapDefault = 100 * 1024; //100kb/s
static const float_t kMatchConditionPercentMin = 0.3;

static const int64_t kDynamicBalanceDivisionThreshold = 1024 * 1024; //1M

static const int64_t kReserveBandwidthMin = 300 * 1024;
static const int64_t kReserveBandwidthDeltaThreshold = 1024 * 1024; //1M

static const float_t kReserveBandwidthDeltaCoefficient = 0.2;
static const int64_t kReserveBandwidthDeltaConstant = -200 * 1024;

@interface TTDownloadDynamicThrottle()
//@property (nonatomic, strong) dispatch_source_t timer;

@property (atomic, copy) ActionBlock onDoThrottle;

@property (atomic, strong) TTObservationBuffer *observationBuff;

@property (atomic, assign) uint8_t observationBufferLength;

@property (atomic, strong) TTObservationBuffer *checkObservationBuff;

@property (atomic, assign) uint8_t checkObservationBufferLength;

@property (atomic, assign) uint8_t measureTimes;

@property (atomic, assign) uint8_t measureTimesMax;

@property (atomic, assign) int64_t bandWidth;

@property (atomic, assign) int64_t startThrottleBandWidthMin;

@property (atomic, assign) BOOL isDynamicBalance;

@property (atomic, assign) int64_t reserveBandWidth;

@property (atomic, assign) uint8_t rttGap;

@property (atomic, assign) uint8_t speedGap;

@property (atomic, assign) float_t matchConditionPercent;

@property (atomic, assign) int64_t dynamicBalanceDivisionThreshold;

@property (atomic, assign) float_t bandwidthDeltaCoefficient;

@property (atomic, assign) int64_t bandwidthDeltaConstant;
@end

@implementation TTDownloadDynamicThrottle

- (id)initWithOutputAction:(ActionBlock)action params:(DownloadGlobalParameters *)params throttleSpeed:(int64_t)speed {
    self = [super init];
    if (self) {
        self.onDoThrottle = action;
        self.isDynamicBalance = (speed == kDynamicThrottleBalanceEnable) ? YES : NO;
        self.measureTimesMax = params.measureSpeedTimes > 0 ? params.measureSpeedTimes : kMeasureSpeedTimesDefault;
        self.measureTimes = self.measureTimesMax;
        self.reserveBandWidth = speed < kDynamicThrottleBalanceEnable ? llabs(speed) : 0;
        
        self.observationBufferLength = params.observationBufferLength > 0 ? params.observationBufferLength : kObservationBufferLengthDefault;
        self.checkObservationBufferLength = params.checkObservationBufferLength > 0 ? params.checkObservationBufferLength : kCheckObservationBufferLengthDefault;
        
        self.observationBuff = [[TTObservationBuffer alloc] initWithCapacity:self.observationBufferLength];
        self.checkObservationBuff = [[TTObservationBuffer alloc] initWithCapacity:self.checkObservationBufferLength];
        self.startThrottleBandWidthMin = params.startThrottleBandWidthMin > 0 ? params.startThrottleBandWidthMin : kStartThrottleBandWidthMin; //500 kb/s
        self.rttGap = params.rttGap > 0 ? params.rttGap : kRttGapDefault;
        self.speedGap = params.speedGap > 0 ? params.speedGap : kSpeedGapDefault;
        
        self.matchConditionPercent = params.matchConditionPercent > kMatchConditionPercentMin ? params.matchConditionPercent : kMatchConditionPercentDefault;
        
        self.dynamicBalanceDivisionThreshold = params.dynamicBalanceDivisionThreshold > 0 ? params.dynamicBalanceDivisionThreshold : kDynamicBalanceDivisionThreshold;
        self.bandwidthDeltaCoefficient = params.bandwidthDeltaCoefficient > 0 ? params.bandwidthDeltaCoefficient : kReserveBandwidthDeltaCoefficient;
        self.bandwidthDeltaConstant = llabs(params.bandwidthDeltaConstant) > 0 ? params.bandwidthDeltaCoefficient : kReserveBandwidthDeltaConstant;
    }
    return self;
}

- (void)setDynamicThrottleSpeed:(int64_t)speed {
    if (kDynamicThrottleBalanceEnable == speed) {
        self.isDynamicBalance = YES;
    } else if (speed < kDynamicThrottleBalanceEnable) {
        self.reserveBandWidth = llabs(speed);
    }
}

- (void)startMeasureBandwidth {
    DLLOGD(@"dynamicSpeed6:++++++++++startMeasureBandwidth++++++++++");
    if (self.onDoThrottle) {
        /**
         *Close throttle to measure bandwidth.
         */
        self.onDoThrottle(kCloseThrottle);
    }

    self.measureTimes = self.measureTimesMax;
}

- (TTObservation *)createObservation:(TTNetworkQuality *)nqe
                      netQualityType:(TTNetEffectiveConnectionType)netQualityType
                               speed:(int64_t)speed
                       throttleSpeed:(int64_t)throttleSpeed {
    TTObservation *observation = [[TTObservation alloc] init];
    observation.tcpRtt = nqe.transportRttMs;
    observation.httpRtt = nqe.httpRttMs;
    observation.netQualityType = netQualityType;
    observation.realNetSpeed = speed;
    observation.throttleSpeed = throttleSpeed;
    DLLOGD(@"dynamicSpeed6:dynamicThrottle new:tcpRtt=%lu,httpRtt=%lu,netQualityType=%@,realNetSpeed=%lld,throttlespeed=%lld", (unsigned long)observation.tcpRtt, (unsigned long)observation.httpRtt, [TTDownloadTask netQualityTypeToString:netQualityType], observation.realNetSpeed, observation.throttleSpeed);
    return observation;
}

- (void)createObservationAndCheck:(TTObservation *)observation {
    
    DLLOGD(@"dynamicSpeed6:enter>>>>>>createObservationAndCheck,observationBuff.size=%lu,observationCheckBuff.size=%lu", (unsigned long)[self.observationBuff getBufferRealSize], (unsigned long)[self.checkObservationBuff getBufferRealSize]);
    
    NSUInteger checkResult = 0U;
    
    if ([self.observationBuff isFull]
        && [self.observationBuff observationCheckByPercent:observation
                                                   percent:self.matchConditionPercent
                                                    rttGap:self.rttGap
                                                  speedGap:self.speedGap]
        && (checkResult = [self.checkObservationBuff isExistSameCheckResultType:observation])) {
        
        DLLOGD(@"dynamicSpeed6:checkObservationBuff addObserve,rtt=%lu", (unsigned long)observation.tcpRtt);
        [self.checkObservationBuff addObservation:observation];
        
        if ([self.checkObservationBuff isFull]) {
            if (checkResult & TCP_RTT_INCREASE) {
                DLLOGD(@"dynamicSpeed6:checkResult & TCP_RTT_INCREASE");
                [self startMeasureBandwidth];
                return;
            }
            
            if (checkResult & TCP_RTT_DECREASE) {
                DLLOGD(@"dynamicSpeed6:checkResult & TCP_RTT_DECREASE");
                [self startMeasureBandwidth];
                return;
            }
            
            if (checkResult & HTTP_RTT_INCREASE) {
                DLLOGD(@"checkResult & HTTP_RTT_INCREASE");
                [self startMeasureBandwidth];
                return;
            }
            
            if (checkResult & HTTP_RTT_DECREASE) {
                DLLOGD(@"checkResult & HTTP_RTT_DECREASE");
                [self startMeasureBandwidth];
                return;
            }
            
            if (checkResult & NET_BE_GOOD) {
                DLLOGD(@"checkResult & NET_BE_GOOD");
                [self startMeasureBandwidth];
                return;
            }
            
            if (checkResult & NET_BE_BAD) {
                DLLOGD(@"checkResult & NET_BE_BAD");
                [self startMeasureBandwidth];
                return;
            }
            
            if (checkResult & DOWNLOAD_SPEED_TOO_LOW) {
                DLLOGD(@"checkResult & DOWNLOAD_SPEED_TOO_LOW");
                [self startMeasureBandwidth];
                return;
            }
        }
        return;
    } else {
        if (![self.checkObservationBuff isEmpty]) {
            DLLOGD(@"dynamicSpeed6:checkObservationBuff not empty self.observationBuff addObserveWithBuffer:");
            [self.observationBuff addObservationWithBuffer:self.checkObservationBuff];
        }
        DLLOGD(@"dynamicSpeed6:createObservationAndCheck:self.observationBuff addObserve:observation");
        [self.observationBuff addObservation:observation];
    }
    DLLOGD(@"dynamicSpeed6:end<<<<<<<<<createObservationAndCheck,observationBuff.size=%lu,observationCheckBuff.size=%lu", (unsigned long)[self.observationBuff getBufferRealSize], (unsigned long)[self.checkObservationBuff getBufferRealSize]);
}

- (void)dynamicCheckAndThrottle:(TTNetworkQuality *)nqe
                 netQualityType:(TTNetEffectiveConnectionType)netQualityType
                          speed:(int64_t)speed
                  throttleSpeed:(int64_t)throttleSpeed {
    DLLOGD(@"dynamicSpeed6:dynamicCheckAndThrottle");
    if (speed <= 0) {
        return;
    }
    
    TTObservation *observation = [self createObservation:nqe
                                          netQualityType:netQualityType
                                                   speed:speed
                                           throttleSpeed:throttleSpeed];
    
    if (self.measureTimes > 0) {
        /**
         *Measure bandWidth.
         */
        DLLOGD(@"dynamicSpeed6:observationBuff add");
        [self.observationBuff addObservation:observation];
        if (--self.measureTimes == 0) {
            TTObservation *avgObservation = [self.observationBuff getAverageObservation:(self.measureTimesMax - 1)];
            DLLOGD(@"dynamicSpeed6:get average speed=%lld", avgObservation.realNetSpeed);
            self.measureTimes = -1;
            [self doThrottle:avgObservation];
            DLLOGD(@"dynamicSpeed6:observationBuff clearBuff");
            [self.observationBuff clearBuff];
            [self.checkObservationBuff clearBuff];
            return;
        }
    } else {
        [self createObservationAndCheck:observation];
    }
}

- (void)doThrottle:(TTObservation *)avgObservation {
    if (!avgObservation) {
        return;
    }

    if (self.isDynamicBalance) {
        DLLOGD(@"self.isDynamicBalance is yes");
        [self doDynamicBalance:avgObservation];
    } else if (self.reserveBandWidth > 0) {
        DLLOGD(@"self.reserveBandWidth > 0,value=%lld", self.reserveBandWidth);
        [self doReserveBandWidth:avgObservation];
    }
}

- (void)doDynamicBalance:(TTObservation *)avgObservation {
    int64_t throttleSpeed = 0;
    /**
     *If average speed is less than startThrottleBandWidthMin,task's download speed will be lowest.
     *If average speed between startThrottleBandWidthMin(500kb/s) and dynamicBalanceDivisionThreshold(1M/s),
     *real throttle speed is average speed minus startThrottleBandWidthMin.
     *If average speed is greater than dynamicBalanceDivisionThreshold,
     *real throttle speed is average speed divided by two.
     */
    if (avgObservation.realNetSpeed < self.startThrottleBandWidthMin) {
        throttleSpeed = kDownloadLowestSpeed;
    } else if (avgObservation.realNetSpeed > self.dynamicBalanceDivisionThreshold) {
        throttleSpeed = avgObservation.realNetSpeed / 2;
    } else {
        throttleSpeed = avgObservation.realNetSpeed - self.startThrottleBandWidthMin;
    }
    DLLOGD(@"+++++++++doThrottle++++++++++throttleSpeed=%lld", throttleSpeed);
    if (self.onDoThrottle) {
        self.onDoThrottle(throttleSpeed);
    }
}

- (void)doReserveBandWidth:(TTObservation *)avgObservation {
    int64_t throttleSpeed = 0;

    if (avgObservation.realNetSpeed <= kReserveBandwidthMin
        || self.reserveBandWidth >= avgObservation.realNetSpeed) {
        throttleSpeed = kDownloadLowestSpeed;
    } else if ((avgObservation.realNetSpeed >= kReserveBandwidthDeltaThreshold)
               && (self.reserveBandWidth < (avgObservation.realNetSpeed / 3))) {
        int64_t realReserveBandWidth = self.reserveBandWidth + ((avgObservation.realNetSpeed * self.bandwidthDeltaCoefficient) + self.bandwidthDeltaConstant);
        throttleSpeed = (avgObservation.realNetSpeed - realReserveBandWidth);
    } else {
        throttleSpeed = avgObservation.realNetSpeed - self.reserveBandWidth;
    }
    DLLOGD(@"+++++++++doThrottle+++++2+reserve=%lld+++bandWidth=%lld+throttleSpeed=%lld", self.reserveBandWidth, avgObservation.realNetSpeed, throttleSpeed);
    if (self.onDoThrottle) {
        self.onDoThrottle(throttleSpeed);
    }
}

- (void)inputUserRtt:(NSUInteger)rtt {
    
}

- (void)inputTcpRtt:(NSUInteger)rtt {
    
}

@end

NS_ASSUME_NONNULL_END
