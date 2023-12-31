//
//  HMDPerformanceReportRequest.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/12/23.
//

#import <Foundation/Foundation.h>
#import "HMDStoreCondition.h"
#import "HMDRecordStore+DeleteRecord.h"

@interface HMDPerformanceReportRequest : NSObject

@property (nonatomic, assign) NSUInteger limitCount;
@property (nonatomic, assign) NSUInteger limitCountFromMemory;
@property (nonatomic, strong) NSArray<HMDStoreCondition *> *dataAndConditions;
@property (nonatomic, strong) NSArray<HMDStoreCondition *> *dataOrConditions;
@property (nonatomic, assign) HMDRecordLocalIDRange uploadingRange;

@end
