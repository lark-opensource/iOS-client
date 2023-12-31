//
//  HMDTTMonitor+CustomTag.m
//  Heimdallr-6ca2cf9f
//
//  Created by 崔晓兵 on 2/8/2022.
//

#import "HMDTTMonitor+CustomTag.h"
#import "HMDTTMonitorTagHelper.h"

@implementation HMDTTMonitor (CustomTag)

+ (void)setMonitorTagVerifyBlock:(TagVerifyBlock _Nonnull)tagVerifyBlock {
    [HMDTTMonitorTagHelper setMonitorTagVerifyBlock:tagVerifyBlock];
}


+ (void)setMonitorTag:(NSInteger)tag {
    [HMDTTMonitorTagHelper setMonitorTag:tag];
}

@end
