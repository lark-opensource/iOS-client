//
//  BDTrackerProtocol+ObserveDeviceID.h
//  BDTrackerProtocol
//
//  Created by on 2020/6/1.
//

#import "BDTrackerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^BDTrackerObserveDeviceIDCallback)(NSString *deviceID, NSString *installID);
typedef void (^BDTrackerProtocolActivateHandler)(NSError *_Nullable error);

@interface BDTrackerProtocol (ObserveDeviceID)

/// those API only for BDInstall AB with TTInstall
/**
 @note only work with BDTracker, if you are working with TTTracker，do not use this api
 @param callback    get deviceID and nstallID if success
 */
+ (void)observeDeviceDidRegistered:(BDTrackerObserveDeviceIDCallback)callback;

/**
  manully activate it with completionHandler and retryTimes
 retryTimes must > 0
*/
+ (void)activateDeviceWithRetryTimes:(NSInteger)retryTimes
                   completionHandler:(nullable BDTrackerProtocolActivateHandler)completionHandler;

/**
 get activate state
 @return YES or No
 */
+ (BOOL)isDeviceActivated;

@end

NS_ASSUME_NONNULL_END
