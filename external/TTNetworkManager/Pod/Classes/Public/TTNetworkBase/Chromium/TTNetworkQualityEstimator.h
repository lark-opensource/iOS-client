//
//  TTNetworkQualityEstimator.h
//  TTNetworkManager
//
//  Created by zhangzeming.chairman on 2020/9/7.
//

#ifndef TTNetworkQualityEstimator_h
#define TTNetworkQualityEstimator_h

#define INVALID_RTT_OR_THROUGHPUT_VALUE -1
#define INVALID_PACKET_LOSS_RATE_OR_VARIANCE_VALUE -1.0

typedef NS_ENUM(NSInteger, TTPacketLossProtocol) {
  PACKET_LOSS_PROTOCOL_INVALID = -1,
  PACKET_LOSS_PROTOCOL_TCP = 0,
  PACKET_LOSS_PROTOCOL_QUIC,
  PACKET_LOSS_PROTOCOL_LAST
};

@interface TTNetworkQuality : NSObject

@property(nonatomic, assign) NSInteger httpRttMs;

@property(nonatomic, assign) NSInteger transportRttMs;

@property(nonatomic, assign) NSInteger downstreamThroughputKbps;

@end

@interface TTNetworkQualityV2 : NSObject
@property(nonatomic, assign) int level;

@property(nonatomic, assign) int effectivHttpRttMs;

@property(nonatomic, assign) int effectiveTransportRttMs;

@property(nonatomic, assign) int effectiveRxThroughputKbps;
@end

@interface TTPacketLossMetrics : NSObject

@property(nonatomic, assign) TTPacketLossProtocol protocol;

@property(nonatomic, assign) double upstreamLossRate;

@property(nonatomic, assign) double upstreamLossRateVariance;

@property(nonatomic, assign) double downstreamLossRate;

@property(nonatomic, assign) double downstreamLossRateVariance;

@end

#endif /* TTNetworkQualityEstimator_h */
