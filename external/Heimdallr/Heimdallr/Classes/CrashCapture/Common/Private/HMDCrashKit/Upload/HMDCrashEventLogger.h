//
//  HMDCrashEventLogger.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/23.
//

#import <Foundation/Foundation.h>
#import "HMDCrashInfo.h"
NS_ASSUME_NONNULL_BEGIN

@interface HMDCrashEventLogger : NSObject

+ (void)logCrashEvent:(HMDCrashInfo *)info;
+ (void)logUploadEvent:(NSString *)filePath error:(NSError *)error backgroundSession:(BOOL)backgroundSession;

@end

NS_ASSUME_NONNULL_END
