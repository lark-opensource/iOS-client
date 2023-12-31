//
//  BDPTrackerHelper.m
//  Timor
//
//  Created by 维旭光 on 2019/7/4.
//

#import "BDPTrackerHelper.h"
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPUniqueID.h>


@implementation BDPTrackerHelper

+ (void)setLoadState:(nullable NSString *)loadState forUniqueID:(BDPUniqueID *)uniqueID
{
    if (uniqueID.isValid) {
        NSString *key = [BDPTrackerHelper _loadStateKeyWithUniqueID:uniqueID];
        [BDPTracker setTag:key value:loadState];
    }
}

+ (NSString *)getLoadStateByUniqueID:(BDPUniqueID *)uniqueID
{
    NSString *key = [BDPTrackerHelper _loadStateKeyWithUniqueID:uniqueID];
    return [BDPTracker getTag:key];
}

+ (NSString *)_loadStateKeyWithUniqueID:(BDPUniqueID *)uniqueID
{
    return BDP_STRING_CONCAT(@"load_state_", uniqueID.fullString ?: @"");
}

@end
