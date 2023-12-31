//
//  HMDOOMCrashRecord.h
//  Heimdallr
//
//  Created by sunrunwang on don't matter time
//

#import "HMDTrackerRecord.h"

extern NSString * _Nonnull const kHMDOOMCrashRecordTableName;

@interface HMDOOMCrashRecord : HMDTrackerRecord

@property(nonatomic, strong, nullable) NSString *internalStorageSession;
@property(nonatomic, assign) double appUsedMemory;      /* MB hmd_MemoryBytes */
@property(nonatomic, assign) double appUsedMemoryPercent;/* % hmd_MemoryBytes */
@property(nonatomic, assign) double deviceFreeMemory;   /* MB hmd_MemoryBytes */
@property(nonatomic, assign) double freeMemoryPercent;/* % hmd_MemoryBytes*/
@property(nonatomic, assign) double freeDiskSpace;      /* MB HMDDiskUsage */
@property(nonatomic, assign) double freeDiskBlockSize;
@property(nonatomic, strong, nullable) NSString *business;
@property(nonatomic, strong, nullable) NSString *lastScene;
@property(nonatomic, strong, nullable) NSDictionary<NSString*, id> *customParams;
@property(nonatomic, strong, nullable) NSDictionary<NSString*, id> *filters;
@property(nonatomic, strong, nullable) NSDictionary *operationTrace;
@property(nonatomic, copy, nullable) NSString *binaryInfo;
@property(nonatomic, copy, nullable) NSString *loginfo DEPRECATED_MSG_ATTRIBUTE("Please do not use this property"); // sdklogij记录的log信息

@end
