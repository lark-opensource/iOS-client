//
//  HMDCrashInfo.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#import <Foundation/Foundation.h>
#import "HMDCrashBinaryImage.h"
#import "HMDCrashMetaData.h"
#import "HMDCrashThreadInfo.h"
#import "HMDCrashProcessState.h"
#import "HMDCrashHeaderInfo.h"
#import "HMDCrashStorage.h"
#import "HMDCrashModel.h"
#import "HMDCrashRuntimeInfo.h"
#import "HMDCrashRegisterAnalysis.h"
#import "HMDCrashStackAnalysis.h"
#import "HMDCrashVMRegion.h"
#import "HMDCrashEnvironmentBinaryImages.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDCrashInfo : HMDCrashModel

@property (nonatomic,copy) NSArray<HMDCrashVMRegion *> *regions;

// 关于 image 的使用, 首先生成 imageLoader, 然后用 imageLoader 匹配 stack 等调用栈的符号
// 然后生成最终上报会使用到的 images
@property (nonatomic, strong, nullable) HMDImageOpaqueLoader *imageLoader;

@property (nonatomic, strong, nullable) NSArray<HMDCrashBinaryImage *> *currentlyUsedImages;

@property (nonatomic,strong) HMDCrashMetaData *meta;

@property (nonatomic,strong)HMDCrashHeaderInfo *headerInfo;

@property (nonatomic,copy) NSArray<HMDCrashThreadInfo *> *threads;

/// async stack trace
@property (nonatomic,strong) HMDCrashThreadInfo *stackRecord;

@property (nonatomic,copy) NSArray<NSString *> *queueNames;

@property (nonatomic,copy) NSArray<NSString *> *threadNames;

@property (nonatomic,strong) HMDCrashProcessState *processState;

@property (nonatomic,strong) HMDCrashStorage *storage;

@property (nonatomic,copy) NSDictionary *dynamicInfo;

@property (nonatomic,copy) NSDictionary *extraDynamicInfo;

@property (nonatomic,copy) NSArray *vids;

@property (nonatomic,strong) HMDCrashRuntimeInfo *runtimeInfo;

@property (nonatomic,copy) NSArray<HMDCrashRegisterAnalysis *> *registerAnalysis;

@property (nonatomic,copy) NSArray<HMDCrashStackAnalysis *> *stackAnalysis;

@property (nonatomic,assign) BOOL isEnvAbnormal;

@property (nonatomic,assign) BOOL isCorrupted;

@property (nonatomic,assign) BOOL fileIOError;

@property (nonatomic,copy,nullable) NSString *sdklog;

@property (nonatomic,readonly,nullable) NSString *processLog;

@property (nonatomic,readonly) BOOL isComplete;

@property (nonatomic,assign) BOOL isInvalid;

@property (nonatomic, copy) NSString *gameScriptStack;

@property (nonatomic, strong) NSDate *exceptionFileModificationDate;

@property (nonatomic, assign) BOOL hasDump;

@property (nonatomic, assign) BOOL hasGWPAsan;

//not thread safe
- (void)info:(NSString *)format, ...;
- (void)warn:(NSString *)format, ...;
- (void)error:(NSString *)format, ...;

#pragma mark - Data Saving

@property (nonatomic, strong) NSString *crashLog;

@end

NS_ASSUME_NONNULL_END
