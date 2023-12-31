//
//  monitor.h
//  Playground
//
//  Created by bytedance on 2021/11/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface MonitorInfo : NSObject

- (nonnull instancetype)init:(nonnull NSString*)appID
                    deviceID:(nonnull NSString*)deviceID
                     channel:(nonnull NSString*)channel
                   hostAppID:(nonnull NSString*)hostAppID
                  appVersion:(nonnull NSString*)appVersion;

@property(nonatomic, copy, readonly, nonnull) NSString* appID; /**sdkID, VMSDK iOS sdkID is 8398*/
@property(nonatomic, copy, readwrite) NSString* deviceID;

@property(nonatomic, copy, readwrite) NSString* channel; /**host app channel: App Store/local_test*/
@property(nonatomic, copy, readwrite) NSString* hostAppID;  /**host app ID*/
@property(nonatomic, copy, readwrite) NSString* appVersion; /**host app version*/

@end
NS_ASSUME_NONNULL_END
