//
//  HMDCrashlogFormatter.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#import <Foundation/Foundation.h>
#import "HMDCrashInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDCrashlogFormatter : NSObject

+ (NSString *)formatedLogWithCrashInfo:(HMDCrashInfo *)crashInfo;

@end

NS_ASSUME_NONNULL_END
