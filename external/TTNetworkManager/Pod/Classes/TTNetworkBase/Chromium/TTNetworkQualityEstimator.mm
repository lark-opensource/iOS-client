//
//  TTNetworkQualityEstimator.m
//  TTNetworkManager
//
//  Created by zhangzeming.chairman on 2020/9/7.
//

#import "TTNetworkQualityEstimator.h"

#import <Foundation/Foundation.h>
#import "TTNetworkManager.h"

@implementation TTNetworkQuality

- (instancetype)init {
    self = [super init];
    if (self) {
        self.httpRttMs = INVALID_RTT_OR_THROUGHPUT_VALUE;
        self.transportRttMs = INVALID_RTT_OR_THROUGHPUT_VALUE;
        self.downstreamThroughputKbps = INVALID_RTT_OR_THROUGHPUT_VALUE;
    }
    return self;
}

@end

@implementation TTNetworkQualityV2

- (instancetype)init {
    self = [super init];
    if (self) {
        self.level = NQL_UNKNOWN;
        self.effectivHttpRttMs = INVALID_RTT_OR_THROUGHPUT_VALUE;
        self.effectiveTransportRttMs = INVALID_RTT_OR_THROUGHPUT_VALUE;
        self.effectiveRxThroughputKbps = INVALID_RTT_OR_THROUGHPUT_VALUE;
    }
    return self;
}

@end


@implementation TTPacketLossMetrics

- (instancetype)init {
    self = [super init];
    if (self) {
        self.protocol = PACKET_LOSS_PROTOCOL_INVALID;
        self.upstreamLossRate = INVALID_PACKET_LOSS_RATE_OR_VARIANCE_VALUE;
        self.upstreamLossRateVariance = INVALID_PACKET_LOSS_RATE_OR_VARIANCE_VALUE;
        self.downstreamLossRate = INVALID_PACKET_LOSS_RATE_OR_VARIANCE_VALUE;
        self.downstreamLossRateVariance = INVALID_PACKET_LOSS_RATE_OR_VARIANCE_VALUE;
    }
    return self;
}

@end
