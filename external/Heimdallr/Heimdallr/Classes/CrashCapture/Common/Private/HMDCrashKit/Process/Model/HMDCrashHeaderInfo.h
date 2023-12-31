//
//  HMDCrashHeaderInfo.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#import <Foundation/Foundation.h>
#import "HMDCrashHeader_Public.h"
#import "HMDCrashModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDCrashHeaderInfo : HMDCrashModel

@property(nonatomic, assign) uint64_t faultAddr;

@property(nonatomic, assign) NSTimeInterval crashTime;  // seconds since 1970

@property(nonatomic, assign) HMDCrashType crashType;

@property(nonatomic, copy) NSString *typeStr;

@property(nonatomic, assign) int mach_type;

@property(nonatomic, assign) int64_t mach_code;

@property(nonatomic, assign) int64_t mach_subcode;

@property(nonatomic, assign) int signum;

@property(nonatomic, assign) int sigcode;

@property(nonatomic, copy) NSString *name;

@property(nonatomic, copy) NSString *reason;

@end

NS_ASSUME_NONNULL_END
