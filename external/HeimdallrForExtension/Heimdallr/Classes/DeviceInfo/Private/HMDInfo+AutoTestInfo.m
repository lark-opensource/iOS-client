//
//	HMDInfo+AutoTestInfo.m
// 	Heimdallr
// 	
// 	Created by Hayden on 2020/2/16. 
//

#import "HMDInfo+AutoTestInfo.h"
#import "NSArray+HMDSafe.h"
#import "NSDictionary+HMDSafe.h"
#include <stdatomic.h>

@implementation HMDInfo (AutoTestInfo)

#pragma - mark test info

+ (BOOL)isBytest {
    if ([self _automationTestInfoDictionary]) {
        return YES;
    }
    else {
        return NO;
    }
}

+ (NSDictionary *)bytestFilter {
    NSDictionary *infoDic = [self _automationTestInfoDictionary];
    if (infoDic) {
        return [infoDic hmd_dictForKey:@"slardar_filter"];
    }
    
    return nil;
}

- (NSDictionary *)automationTestInfoDic {
    static NSDictionary *automationTestInfoDic = nil;
    static atomic_flag once = ATOMIC_FLAG_INIT;
    if (!atomic_flag_test_and_set_explicit(&once, memory_order_relaxed)) {
        NSDictionary *tempdic = [self.class _automationTestInfoDictionary];
        if (tempdic) {
            NSMutableDictionary *infoDic = [NSMutableDictionary new];
            for (NSString *key in tempdic.allKeys) {
                id value = tempdic[key];
                if ([value isKindOfClass:[NSString class]]) {
                    [infoDic setValue:value forKey:key];
                }
            }
            automationTestInfoDic = infoDic.copy;
        }
    }
    return automationTestInfoDic ?: [NSDictionary new];
}

+ (NSDictionary *)_automationTestInfoDictionary {
    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
    return [infoDic hmd_dictForKey:@"AutomationTestInfo"];
}

@end
