//
//  HMDMetrickitConfig.h
//  Heimdallr
//
//  Created by maniackk on 2021/4/21.
//

#import "HMDTrackerConfig.h"


extern NSString * _Nullable const kHMDModuleMetrickitKey; 

@interface HMDMetrickitConfig : HMDTrackerConfig

@property(nonatomic, assign) BOOL isUploadMetric;

@property(nonatomic, assign) BOOL isFixSegmentRename;

@end

