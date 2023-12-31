//
//  HMDCPUExceptionMonitor+Reporter.h
//  Heimdallr
//
//  Created by zhangxiao on 2020/9/9.
//

#import "HMDCPUExceptionMonitor.h"
#import "HMDCPUExceptionRecordManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDCPUExceptionMonitor (Reporter)

@property (nonatomic, strong) HMDCPUExceptionRecordManager *recordManager;
@property (nonatomic, assign) BOOL readFromDB;

@end

NS_ASSUME_NONNULL_END
