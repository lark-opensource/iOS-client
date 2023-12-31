
#import <TTNetworkManager/TTNetworkManager.h>
#import "TTObservationBuffer.h"

@interface TTObservation : NSObject

@property (nonatomic, assign) NSUInteger tcpRtt;

@property (nonatomic, assign) NSUInteger httpRtt;

@property (nonatomic, assign) TTNetEffectiveConnectionType netQualityType;

@property (nonatomic, assign) int64_t realNetSpeed;

@property (nonatomic, assign) NSUInteger checkResult;

@property (nonatomic, assign) int64_t throttleSpeed;

@end
