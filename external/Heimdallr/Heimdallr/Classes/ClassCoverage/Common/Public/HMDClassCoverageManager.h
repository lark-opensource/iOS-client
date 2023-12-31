//
//  HMDClassCoverageManager.h
//  Pods
//
//  Created by kilroy on 2020/6/8.
//

#import <Foundation/Foundation.h>
#import "HeimdallrModule.h"

@interface HMDClassCoverageManager: HeimdallrModule

+ (nonnull instancetype)sharedInstance;

//手动生成线上无用类检测报告接口
- (void)manuallyGenerateReportWithCheckInterval:(NSTimeInterval)checkInterval
                                       wifiOnly:(BOOL)wifiOnly;
@end
