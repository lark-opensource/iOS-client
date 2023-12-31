//
//  BDPAppManagerTrackEvent.h
//  Timor
//
//  Created by liubo on 2018/12/7.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPModel.h>

//埋点文档: https://docs.bytedance.net/sheet/b1HB2wGtZQTykxftL1KYPd#1

@interface BDPAppManagerTrackEvent : NSObject

#pragma mark - Common Load Track Event
//#pragma mark - Async Load Track Event

+ (void)asyncLoadTrackEventUseAsyncWithUniqueID:(BDPUniqueID *)uniqueID launchFrom:(NSString *)launchFrom;
+ (void)asyncLoadTrackEventNotifyEndWithUniqueID:(BDPUniqueID *)uniqueID launchFrom:(NSString *)launchFrom latestVersion:(NSString *)latestVersion currentVersion:(NSString *)currentVersion;
+ (void)asyncLoadTrackEventApplyEndWithUniqueID:(BDPUniqueID *)uniqueID launchFrom:(NSString *)launchFrom latestVersion:(NSString *)latestVersion currentVersion:(NSString *)currentVersion;

#pragma mark - Preload Track Event

//+ (void)preloadTrackEventAppPreloadListWithSuccess:(BOOL)success duration:(NSTimeInterval)duration errorMsg:(NSString *)errorMsg;
+ (void)preloadTrackEventResourceWithResID:(NSString *)resID success:(BOOL)success duration:(NSTimeInterval)duration errorMsg:(NSString *)errorMsg;

@end
