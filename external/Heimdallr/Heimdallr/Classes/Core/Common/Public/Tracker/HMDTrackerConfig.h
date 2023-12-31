//
//  HMDTrackerConfig.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/12/14.
//

#import "HMDModuleConfig.h"

@interface HMDTrackerConfig : HMDModuleConfig

@property (nonatomic, assign) float flushInterval;
@property (nonatomic, assign) NSInteger flushCount;

@end
