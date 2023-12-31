//
//  HMDCleanupConfig.m
//  Heimdallr
//
//  Created by fengyadong on 2018/2/11.
//

#import "HMDCleanupConfig.h"
#import "HMDStoreCondition.h"
#import "NSObject+HMDAttributes.h"
#import "HMDHermasCleanupSetting.h"

@implementation HMDCleanupConfig

#define kHMDDBExpectedLevel_DFT 50
#define kHMDDBDevastateLevel_DFT 500

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(maxSessionCount, max_session, @(50), @(50))
        HMD_ATTR_MAP_DEFAULT(maxRemainDays, max_remain_days, @(7), @(7))
        HMD_ATTR_MAP_DEFAULT(expectedDBSize, expected_database_size, @(kHMDDBExpectedLevel_DFT), @(kHMDDBExpectedLevel_DFT))
        HMD_ATTR_MAP_DEFAULT(devastateDBSize, devastate_database_size, @(kHMDDBDevastateLevel_DFT), @(kHMDDBDevastateLevel_DFT))
    };
}

@end
