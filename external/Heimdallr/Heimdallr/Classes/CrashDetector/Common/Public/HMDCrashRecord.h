//
//  HMDCrashRecord.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/1/12.
//

#import <Foundation/Foundation.h>
#import "HMDTrackerRecord.h"
#import "HMDThreadBacktrace.h"
#import "HMDJSONable.h"


typedef enum : NSUInteger {
    HMDCrashRecordTypeUnknown,
    HMDCrashRecordTypeMachException,
    HMDCrashRecordTypeSignal,
    HMDCrashRecordTypeCPPException,
    HMDCrashRecordTypeNSException
} HMDCrashRecordType;

typedef enum : NSUInteger {
    /* 常用的类型 */
    HMDMachCrashType_UNKOWN,
    HMDMachCrashType_EXC_BAD_ACCESS,
    HMDMachCrashType_EXC_BAD_INSTRUCTION,
    HMDMachCrashType_EXC_CRASH,
    
    HMDMachCrashType_EXC_ARITHMETIC,
    HMDMachCrashType_EXC_EMULATION,
    HMDMachCrashType_EXC_SOFTWARE,
    HMDMachCrashType_EXC_BREAKPOINT,
    HMDMachCrashType_EXC_SYSCALL,
    HMDMachCrashType_EXC_MACH_SYSCALL,
    HMDMachCrashType_EXC_RPC_ALERT
} HMDMachCrashType;

@interface HMDCrashRecord : HMDTrackerRecord

//additional performance data
@property (nonatomic, assign) double memoryUsage;
@property (nonatomic, assign) double freeMemoryUsage;
@property (nonatomic, assign) double freeMemoryPercent;
@property (nonatomic, assign) double freeDiskUsage;
@property (nonatomic, assign) NSUInteger isLaunchCrash;
@property (nonatomic, assign) NSUInteger isBackground;
@property (nonatomic, copy, nullable) NSDictionary<NSString*, id> *customParams;
@property (nonatomic, copy, nullable) NSString *access;
@property (nonatomic, copy, nullable) NSString *lastScene;
@property (nonatomic, copy, nullable) NSString *business;//业务方
@property (nonatomic, copy, nullable) NSDictionary<NSString*, id> *filters;
@property (nonatomic, copy, nullable) NSString *crashShortVersion;
@property (nonatomic, copy, nullable) NSString *crashBuildVersion;
@property (nonatomic, copy, nullable) NSString *crashExceptionName;
@property (nonatomic, copy, nullable) NSString *crashReason;
@property (nonatomic, assign) HMDCrashRecordType crashType;
@property (nonatomic, readonly) HMDMachCrashType machCrashType; // 当 crashType 是 mach 时 该返回有用
@property (nonatomic, copy, nullable) NSDictionary *operationTrace;
@property (nonatomic, copy, nullable) NSString *crashLog;

@end

