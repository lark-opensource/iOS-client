//
//  HMDMonitorRecord+DBStore.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/1/2.
//

#import "HMDMonitorRecord+DBStore.h"

@implementation HMDMonitorRecord (DBStore)

+ (NSString *)tableName;
{
    return NSStringFromClass(self.class);
}

+ (NSArray<NSDictionary *> *)aggregateDataForRecords:(NSArray *)records {
    return nil;
}


+ (NSArray<NSDictionary *> *)reportDataForRecords:(NSArray *)records {
    return nil;
}

+ (NSUInteger)cleanupWeight {
    return 30u;
}

@end
