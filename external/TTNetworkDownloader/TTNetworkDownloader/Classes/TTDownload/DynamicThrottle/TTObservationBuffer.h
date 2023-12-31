#import "TTObservation.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RttType) {
    TCP_RTT,
    HTTP_RTT,
    NET_TYPE,
};

typedef NS_ENUM(NSUInteger, ObservationCheckResult) {
    TCP_RTT_INCREASE       = 1 << 0,
    TCP_RTT_DECREASE       = 1 << 1,
    HTTP_RTT_INCREASE      = 1 << 2,
    HTTP_RTT_DECREASE      = 1 << 3,
    NET_BE_GOOD            = 1 << 4,
    NET_BE_BAD             = 1 << 5,
    DOWNLOAD_SPEED_TOO_LOW = 1 << 6,
};

@class TTObservation;
@interface TTObservationBuffer : NSObject

- (id)initWithCapacity:(NSUInteger)size;

- (void)setCapacity:(NSUInteger)size;

- (void)addObservation:(TTObservation *)observation;

- (void)addObservationWithBuffer:(TTObservationBuffer *)newObservationBuffer;

- (NSUInteger)observationCheckByPercent:(TTObservation *)observation
                                percent:(float)percent
                                 rttGap:(NSInteger)rttGap
                               speedGap:(int64_t)speedGap;

- (TTObservation *)getAverageObservation:(NSInteger)newestObservationCount;

- (TTObservation *)getFirstObservation;

- (BOOL)isFull;

- (BOOL)isEmpty;

- (void)clearBuff;

- (NSUInteger)getBufferRealSize;

- (BOOL)isExistSameCheckResultType:(TTObservation *)observation;

@end

NS_ASSUME_NONNULL_END
