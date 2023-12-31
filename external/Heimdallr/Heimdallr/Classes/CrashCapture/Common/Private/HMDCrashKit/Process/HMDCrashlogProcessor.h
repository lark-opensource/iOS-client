//
//  HMDCrashlogProcessor.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#import <Foundation/Foundation.h>
#import "HMDCrashReportInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDCrashlogProcessor : NSObject

@property (nonatomic,assign) BOOL needEncrypt;
@property (nonatomic,assign) NSTimeInterval launchCrashThreshold;
@property (nonatomic,strong) HMDCrashReportInfo *crashReport;

- (void)startProcess:(BOOL)needLastCrash;

@end

NS_ASSUME_NONNULL_END
