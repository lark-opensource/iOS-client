//
//  HMDCrashInfoLoader.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#import <Foundation/Foundation.h>
#import "HMDCrashInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDCrashInfoLoader : NSObject

+ (HMDCrashInfo *)loadCrashInfo:(NSString *)inputDir;

@end

NS_ASSUME_NONNULL_END
