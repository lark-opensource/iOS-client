//
//  HMDModuleConfig+StartWeight.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/6/5.
//

#import "HMDModuleConfig+StartWeight.h"

@implementation HMDModuleConfig (StartWeight)

- (HMDModuleStartWeight)startWeight
{
    return HMDDefaultModuleStartWeight;
}

- (NSComparisonResult)compareStartWeight:(HMDModuleConfig *)config
{
    if (self.startWeight > config.startWeight) {
        return NSOrderedDescending;
    }else if (self.startWeight == config.startWeight){
        return NSOrderedSame;
    }else{
        return NSOrderedAscending;
    }
}

@end
