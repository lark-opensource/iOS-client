//
//  BDLynxTracker.m
//  BDLynx-Pods-Aweme
//
//  Created by bill on 2020/5/19.
//

#import "BDLynxTracker.h"
#import "BDLUtils.h"

@implementation BDLynxTracker

+ (void)trackLynxLifeCycleTrigger:(NSString *)trigger
                          channel:(NSString *)channel
                          logType:(NSString *)logType
                          service:(NSString *)service
                             data:(NSDictionary *)tdata {
  NSMutableDictionary *data = [NSMutableDictionary dictionary];

  NSMutableDictionary *category = [NSMutableDictionary dictionary];
  [category setObject:@"lynx" forKey:@"type"];
  [category setObject:trigger forKey:@"trigger"];
  [category setValue:channel forKey:@"channel"];
  [category setValue:channel forKey:@"lynx_channel"];

  NSMutableDictionary *metrics = [NSMutableDictionary dictionary];

  [metrics setObject:@([[NSDate date] timeIntervalSince1970] * 1000.0) forKey:@"event_ts"];

  [data setObject:service forKey:@"service"];
  [data setObject:@0 forKey:@"status"];
  [data setObject:category forKey:@"category"];
  [data setObject:metrics forKey:@"metrics"];
  [data setObject:@{@"ts" : @([[NSDate date] timeIntervalSince1970] * 1000.0)} forKey:@"value"];

  [data addEntriesFromDictionary:tdata];

  [BDLUtils trackData:data logTypeStr:logType];
}

@end
