//
//  HMDTTLeaksFinderRecord.m
//  Heimdallr_Example
//
//  Created by bytedance on 2020/5/29.
//  Copyright © 2020 ghlsb@hotmail.com. All rights reserved.
//

#import "TTHMDLeaksFinderRecord.h"

@implementation TTHMDLeaksFinderRecord

- (NSDictionary *)customData {
    return @{
        @"leaks_retain_cycle": self.retainCycle ?: @"",
        @"leaks_view_stack": self.viewStack ?: @"",
        @"leaks_cycle_key_class": self.cycleKeyClass ?: @"",
        @"leaks_build_info": self.buildInfo ?: @"",
        @"leaks_id": self.leaksId ?: @"",
        @"leak_size": self.leakSize ?: @"",
        @"leak_size_round": self.leakSizeRound ?:@"",
    };
}

@end
