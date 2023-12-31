//
//  HMDCrashAddressAnalysis.h
//  AWECloudCommand-iOS13.0
//
//  Created by yuanzhangjing on 2019/12/1.
//

#import "HMDCrashModel.h"
#import "HMDCrashVMRegion.h"
#import "HMDCrashAddressObjectInfo.h"
#import "HMDCrashBinaryImage.h"

@interface HMDCrashAddressAnalysis : HMDCrashModel

@property (nonatomic,assign) uintptr_t value;

@property (nonatomic,strong) HMDCrashBinaryImage *image;
@property (nonatomic,strong) HMDCrashSegment *segment;
@property (nonatomic,strong) HMDCrashSection *section;

@property (nonatomic,strong) HMDCrashVMRegion *regionInfo;
@property (nonatomic,strong) HMDCrashAddressObjectInfo *objectInfo;
@property (nonatomic,copy) NSString *stringInfo;

@end
