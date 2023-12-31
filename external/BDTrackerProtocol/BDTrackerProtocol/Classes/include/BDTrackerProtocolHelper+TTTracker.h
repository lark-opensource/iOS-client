//
//  BDTrackerProtocolHelper+TTTracker.h
//  BDTrackerProtocol
//
//  Created by bob on 2020/3/20.
//

#import "BDTrackerProtocolHelper.h"
#import "BDTrackerProtocol+ObserveDeviceID.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTrackerProtocolHelper (TTTracker)

+ (nullable NSString *)tttrackerDeviceID;
+ (nullable NSString *)tttrackerInstallID;
+ (nullable NSString *)tttrackerClientDID;
+ (nullable NSString *)tttrackerSessionID;
+ (void)ttTrackEventWithCustomKeys:(NSString *)event
                             label:(NSString *)label
                             value:(nullable NSString *)value
                            source:(nullable NSString *)source
                          extraDic:(nullable NSDictionary *)extraDic;
+ (void)observeDeviceDidRegistered:(BDTrackerObserveDeviceIDCallback)callback;
+ (void)activateDeviceWithRetryTimes:(NSInteger)retryTimes
                   completionHandler:(BDTrackerProtocolActivateHandler)completionHandler;
+ (BOOL)isDeviceActivated;

@end

NS_ASSUME_NONNULL_END
