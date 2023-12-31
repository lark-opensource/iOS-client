//
//  HMDFDConfig.h
//  Pods
//
//  Created by wangyinhui on 2021/6/29.
//

#import "HMDTrackerConfig.h"


extern NSString * _Nullable const kHMDModuleFDMonitor;

@interface HMDFDConfig : HMDTrackerConfig

@property (nonatomic, assign) int sampleInterval;

@property (nonatomic, assign) double fdWarnRate;

//upgrade max_fd in app, rang (getdtablesize, 10240)
@property (nonatomic, assign) int maxFD;

@end

