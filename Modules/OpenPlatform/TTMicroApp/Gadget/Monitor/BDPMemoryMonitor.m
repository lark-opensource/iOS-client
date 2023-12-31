//
//  BDPMemoryMonitor.m
//  Timor
//
//  Created by MacPu on 2018/10/18.
//

#import "BDPMemoryMonitor.h"
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPTracker.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPVersionManager.h>
#import <OPFoundation/BDPTrackerConstants.h>

#import <OPFoundation/NSTimer+BDPWeakTarget.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/BDPSettingsManager+BDPExtension.h>

#import <mach/mach.h>
#import <assert.h>

#import <ECOInfra/ECOConfig.h>
#import <ECOInfra/ECOConfigService.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <ECOInfra/BDPUtils.h>
#import <ECOProbeMeta/ECOProbeMeta-Swift.h>
#import <OPFoundation/BDPMonitorEvent.h>

@implementation BDPMemoryMonitor

static NSString * const kEcosystemMemoryWarningKey     = @"ecosystem_memory_warning";
static NSString * const kMemoryWarningEnable           = @"isMemoryWarningEnable";
static NSString * const kMemoryWarningDetectInterval   = @"memoryDetectInterval";
static NSString * const kMemoryWarningWarningValue     = @"memoryWarningValue";
static NSString * const kMemoryWarningWarningRatio     = @"memoryWarningRatio";
static NSString * const kMemoryWarningKillValue        = @"memoryKillValue";
static NSString * const kMemoryWarningKillRatio        = @"memoryKillRatio";

/// resident_size(驻留内存)无法反映应用的真实物理内存，而且 Xcode 的 Debug Gauge 使用的应该是 phys_footprint，这个从 WebKit 和 XNU 的源码都能够得到佐证
/// reference: https://github.com/aozhimin/iOS-Monitor-Platform/issues/5#issuecomment-429518591
+ (CGFloat)currentMemoryUsageInBytes {
    CGFloat memoryUsageInByte = 0;
    task_vm_info_data_t vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t kernelReturn = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t) &vmInfo, &count);
    if(kernelReturn == KERN_SUCCESS) {
        memoryUsageInByte = (int64_t) vmInfo.phys_footprint;
    } else {
        memoryUsageInByte = -1.0f;
    }
    return memoryUsageInByte;
}

+ (double)avaliableMemory
{
    vm_statistics_data_t vmStats;
    mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
    kern_return_t kernReturn = host_statistics(mach_host_self(),HOST_VM_INFO,(host_info_t)&vmStats,&infoCount);
    
    if (kernReturn != KERN_SUCCESS) {
        return NSNotFound;
    }
    
    return (vm_page_size * vmStats.free_count + vm_page_size * vmStats.inactive_count);
}


static NSTimer *memoryDetectiveTimer = nil;
static NSMutableDictionary<BDPUniqueID *,id> *killDic = nil;
static NSMutableDictionary<BDPUniqueID *,id> *warningDic = nil;
static BDPUniqueID *currentUniqueID = nil;

+ (void)registerMemoryWarningTimerWithUniqueID:(nonnull BDPUniqueID*)uniqueID warningBlock:(actionBlock)warningBlock killBlock:(actionBlock)killBlock
{
    if (![self isMemoryWarningEnable]) {
        return;
    }
    
    if (!memoryDetectiveTimer) {
        killDic = [NSMutableDictionary dictionary];
        warningDic = [NSMutableDictionary dictionary];
        
        memoryDetectiveTimer = [NSTimer bdp_repeatedTimerWithInterval:[self getMemoryWaringValueForKey:kMemoryWarningDetectInterval] target:[self class] block:^(NSTimer * _Nonnull timer) {

            //防止特殊情况收到该回调
            @synchronized (currentUniqueID) {
                BDPCommon *common = BDPCommonFromUniqueID(currentUniqueID);
                if (!common.isActive) {
                    return;
                }
            }
            
            NSInteger memoryWarningValue = [self getMemoryWaringValueForKey:kMemoryWarningWarningValue];
            NSInteger memoryWarningRatio = [self getMemoryWaringValueForKey:kMemoryWarningWarningRatio];
            NSInteger memoryKillValue = [self getMemoryWaringValueForKey:kMemoryWarningKillValue];
            NSInteger memoryKillRatio = [self getMemoryWaringValueForKey:kMemoryWarningKillRatio];
            
            long long physicalMemory = [NSProcessInfo processInfo].physicalMemory;
            double usedMemory = [BDPMemoryMonitor currentMemoryUsageInBytes];
            
            if (usedMemory/1024/1024 > memoryWarningValue && usedMemory/physicalMemory*100 > memoryWarningRatio) {
                if (usedMemory/1024/1024 > memoryKillValue || usedMemory/physicalMemory*100 > memoryKillRatio) {
                    @synchronized (currentUniqueID) {
                        BDPLogInfo(@"memory kill %@" ,currentUniqueID.appID?:@"-1");
                        BDPMonitorWithCode(EPMClientOpenPlatformCommonPerformanceCode.op_memory_kill, uniqueID)
                        .addCategoryValue(BDPTrackerAppIDKey,currentUniqueID.appID?:@"-1")
                        .addCategoryValue(BDPTrackerLibVersionKey,[BDPVersionManager localLibVersionString])
                        .addMetricValue(@"usedMemory", @(usedMemory))
                        .flush();
                                                
                        actionBlock block = [killDic objectForKey:currentUniqueID];
                        if (block) {
                            block();
                        }
                    }
                }else
                {
                    @synchronized (currentUniqueID) {
                        BDPLogInfo(@"memory warning %@" ,currentUniqueID.appID?:@"-1");
                        BDPMonitorWithCode(EPMClientOpenPlatformCommonPerformanceCode.op_memory_warning, uniqueID)
                        .addCategoryValue(BDPTrackerAppIDKey,currentUniqueID.appID?:@"-1")
                        .addCategoryValue(BDPTrackerLibVersionKey,[BDPVersionManager localLibVersionString])
                        .addMetricValue(@"usedMemory",@(usedMemory))
                        .flush();
                        actionBlock block = [warningDic objectForKey:currentUniqueID];
                        if (block) {
                            block();
                        }
                    }
                }
            }
        }];
        
        [[NSRunLoop currentRunLoop] addTimer:memoryDetectiveTimer forMode:NSRunLoopCommonModes];
    }
    
    @synchronized (currentUniqueID) {
        if (![currentUniqueID isEqual:uniqueID]) {
            currentUniqueID = uniqueID;
            [killDic setObject:killBlock forKey:uniqueID];
            [warningDic setObject:warningBlock forKey:uniqueID];
        }
    }
}

+ (void)unregisterMemoryWarningTimerWithUniqueID:(BDPUniqueID*)uniqueID
{
    if (![self isMemoryWarningEnable]) {
        return;
    }
    @synchronized (currentUniqueID) {
        [killDic removeObjectForKey:uniqueID];
        [warningDic removeObjectForKey:uniqueID];
        if ([killDic count] == 0 || [warningDic count] == 0) {
            [memoryDetectiveTimer invalidate];
            memoryDetectiveTimer = nil;
            killDic = nil;
            warningDic = nil;
            currentUniqueID = nil;
        }
    }
}

+ (void)didReceiveMemoryWarning
{
    if ([self isMemoryWarningEnable]) {
        [memoryDetectiveTimer fire];
    }
}

+ (BOOL)isMemoryWarningEnable
{
    id<ECOConfigService> service = [ECOConfig service];
    NSDictionary<NSString *, id> *config = BDPSafeDictionary([service getDictionaryValueForKey:kEcosystemMemoryWarningKey]);
    return [config bdp_boolValueForKey2:kMemoryWarningEnable];
}


+(NSInteger)getMemoryWaringValueForKey:(NSString *)key{
    if (BDPIsEmptyString(key)) {
        BDPLogError(@"getMemoryWaringValueForKey with empty key");
        return INT_MAX;
    }
    id<ECOConfigService> service = [ECOConfig service];
    NSDictionary<NSString *, id> *config = BDPSafeDictionary([service getDictionaryValueForKey:kEcosystemMemoryWarningKey]);
    return [config bdp_integerValueForKey:key];
}


@end
