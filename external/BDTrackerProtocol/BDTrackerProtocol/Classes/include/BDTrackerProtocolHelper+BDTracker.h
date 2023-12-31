//
//  BDTrackerProtocolHelper+BDTracker.h
//  BDTrackerProtocol
//
//  Created by bob on 2020/3/20.
//

#import "BDTrackerProtocolHelper.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTrackerProtocolHelper (BDTracker)

+ (void)bdTrackEventWithCustomKeys:(NSString *)event
                             label:(NSString *)label
                             value:(nullable NSString *)value
                            source:(nullable NSString *)source
                          extraDic:(nullable NSDictionary *)extraDic;
@end

NS_ASSUME_NONNULL_END
