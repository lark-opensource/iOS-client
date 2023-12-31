//
//  TTMonitor+AppLog.m
//  Heimdallr
//
//  Created by joy on 2018/3/28.
//

#import "HMDTTMonitor+AppLog.h"

@implementation HMDTTMonitor (AppLog)

-(void)trackAppLogWithTag:(NSString *)tag label:(NSString *)label{
    [self trackAppLogWithTag:tag label:label extraValue:nil];
}

-(void)trackAppLogWithTag:(NSString *)tag label:(NSString *)label extraValue:(NSDictionary *)extra
{
    if (!tag || !label) {
        return;
    }
    NSString * value = [NSString stringWithFormat:@"%@_%@", tag, label];
    [[HMDTTMonitor defaultManager] hmdTrackService:@"applog" metric:nil category:@{@"value":value} extra:extra];
}

@end
