//  Heimdallr
//
//  Created by 谢俊逸 on 2019/06/13.
//


#import "HMDGameTrackerConfig.h"
#import "HMDGameTracker.h"
#import "hmd_section_data_utility.h"

NSString *const kHMDModuleGameTracker = @"game";

HMD_MODULE_CONFIG(HMDGameTrackerConfig)

@implementation HMDGameTrackerConfig
+ (NSString *)configKey
{
    return kHMDModuleGameTracker;
}

- (id<HeimdallrModule>)getModule
{
    return [HMDGameTracker sharedTracker];
}
@end
