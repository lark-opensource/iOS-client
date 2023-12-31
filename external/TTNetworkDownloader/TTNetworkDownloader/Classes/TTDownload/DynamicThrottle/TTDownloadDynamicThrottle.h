
#import "TTDownloadManager.h"
#import "TTObservationBuffer.h"
#import "TTDownloadMetaData.h"
#import "TTDownloadTask.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^ActionBlock)(int64_t speed);

@interface TTDownloadDynamicThrottle : NSObject

- (id)initWithOutputAction:(ActionBlock)action params:(DownloadGlobalParameters *)params throttleSpeed:(int64_t)speed;

- (void)dynamicCheckAndThrottle:(TTNetworkQuality *)nqe
                 netQualityType:(TTNetEffectiveConnectionType)netQualityType
                          speed:(int64_t)speed
                  throttleSpeed:(int64_t)throttleSpeed;

- (void)inputUserRtt:(NSUInteger)userRtt;

- (void)inputTcpRtt:(NSUInteger)tcpRtt;

- (void)setDynamicThrottleSpeed:(int64_t)speed;

- (void)startMeasureBandwidth;

@end

NS_ASSUME_NONNULL_END
