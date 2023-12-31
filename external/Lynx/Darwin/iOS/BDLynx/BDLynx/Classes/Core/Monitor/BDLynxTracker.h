//
//  BDLynxTracker.h
//  BDLynx-Pods-Aweme
//
//  Created by bill on 2020/5/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDLynxTracker : NSObject

+ (void)trackLynxLifeCycleTrigger:(NSString *)trigger
                          channel:(NSString *)channel
                          logType:(NSString *)logType
                          service:(NSString *)service
                             data:(NSDictionary *)tdata;
@end

NS_ASSUME_NONNULL_END
