//
//  TTMonitor+AppLog.h
//  Heimdallr
//
//  Created by joy on 2018/3/28.
//

#import "HMDTTMonitor.h"

@interface HMDTTMonitor (AppLog)

-(void)trackAppLogWithTag:(nonnull NSString *)tag label:(nonnull NSString *)label;

-(void)trackAppLogWithTag:(nonnull NSString *)tag label:(nonnull NSString *)label extraValue:(nullable NSDictionary *)extra;
@end
