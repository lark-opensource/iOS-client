//
//  TTNetInitMetrics.h
//  TTNetworkManager
//
//  Created by taoyiyuan on 2021/3/16.
//

#import <Foundation/Foundation.h>

#import "net/tt_net/base/cronet_init_timing_info.h"

@interface TTNetInitMetrics : NSObject

@property(nonatomic, assign) int64_t initTTNetStartTime;

@property(nonatomic, assign) int64_t initTTNetEndTime;

@property(nonatomic, assign) int64_t mainStartTime;

@property(nonatomic, assign) int64_t mainEndTime;

@property(nonatomic, assign) int64_t initMssdkStartTime;

@property(nonatomic, assign) int64_t initMssdkEndTime;


/*!
 * @discussion Get the default manager singleton instance.
 * @return The the default manager singleton instance.
 */
+ (instancetype)sharedManager;

-(NSDictionary *) constructTTNetInitTimingInfo:(const net::CronetInitTimingInfo *) cronetTimingInfo;

-(bool)initMSSdk;

@end
