//
//  HMDThreadMonitorTool.m
//  Heimdallr
//
//  Created by zhangxiao on 2021/10/9.
//

#import "HMDThreadMonitorTool.h"
#import "HMDGCD.h"
#import "HMDMacro.h"
#import <mach/mach.h>
#import "NSDictionary+HMDSafe.h"
#import "HMDAsyncThread.h"

static const int hour = 3600;
static const int minute = 60;
static const int second = 1;

NSString *const kHMDTHREADCOUNTEXCEPTION = @"hmd_thread_count_exception";
NSString *const kHMDSPECIALTHREADCOUNTEXCEPTION = @"hmd_special_thread_count_exception";

static void *hmd_thread_monitor_queue_key = &hmd_thread_monitor_queue_key;
static void *hmd_thread_monitor_queue_context = &hmd_thread_monitor_queue_context;

dispatch_queue_t hmd_get_thread_monitor_queue(void)
{
    static dispatch_queue_t monitor_queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        monitor_queue = dispatch_queue_create("com.hmd.heimdallr.thread.monitor", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(monitor_queue, hmd_thread_monitor_queue_key, hmd_thread_monitor_queue_context, 0);
    });
    return monitor_queue;
}

void dispatch_on_thread_monitor_queue(dispatch_block_t block)
{
    if (block == NULL) {
        return;
    }
    if (dispatch_get_specific(hmd_thread_monitor_queue_key) == hmd_thread_monitor_queue_context) {
        block();
    } else {
        hmd_safe_dispatch_async(hmd_get_thread_monitor_queue(), block);
    }
}

@interface HMDThreadMonitorTool()

@property (nonatomic, strong) NSArray *businessList;

@end

@implementation HMDThreadMonitorTool

+ (instancetype)shared {
    static HMDThreadMonitorTool *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDThreadMonitorTool alloc] init];
    });
    return instance;
}

#pragma mark --- life cycle
- (instancetype)init {
    if (self = [super init]) {
        _businessList = [NSArray array];
    }
    return self;
}

- (void)updateWithBussinessList:(NSArray *)list {
    self.businessList = [list copy];
}

- (HMDThreadMonitorInfo *)getAllThreadInfo {
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    thread_basic_info_t basic_info_th;
    // get threads in the task
    kern_return_t kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return nil;
    }

    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;
    
    HMDThreadMonitorInfo *info = [[HMDThreadMonitorInfo alloc] init];
    // for each thread
    for (int idx = 0; idx < (int)thread_count; idx++) {
        thread_info_count = THREAD_INFO_MAX;
        thread_t thread_id = thread_list[idx];
        kr = thread_info(thread_id, THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return nil;
        }
        basic_info_th = (thread_basic_info_t)thinfo;
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            @autoreleasepool {
                char cThreadName[256] = {0};
                hmdthread_getName(thread_id, cThreadName, sizeof(cThreadName));
                info.allThreadCount += 1;
                NSString *threadNameStr = [HMDThreadMonitorTool preProcessThreadName:cThreadName];
                if (threadNameStr) {
                    // 如果该线程名命中了聚合逻辑，则只记录聚合后的线程名
                    NSString *bizName = [self getBussinessFromThreadName:threadNameStr];
                    if(bizName) {
                        threadNameStr = bizName;
                    }
                    NSUInteger threadCount = [info.allThreadDic hmd_integerForKey:threadNameStr] + 1;
                    [info.allThreadDic hmd_setObject:@(threadCount) forKey:threadNameStr];
                    if (threadCount > info.mostThreadCount) {
                        info.mostThreadCount = threadCount;
                        info.mostThread = threadNameStr;
                        info.mostThreadID = thread_id;
                        
                    }
                }
            }
        }
    }

    for(size_t index = 0; index < thread_count; index++)
        mach_port_deallocate(mach_task_self(), thread_list[index]);

    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    NSAssert(kr == KERN_SUCCESS,@"The return value is illegal!");

    return info;
}

+ (NSString *)preProcessThreadName:(const char *)cThreadName {
    size_t size = strlen(cThreadName);
    if (size > 0 && strcmp(cThreadName, "null") != 0) {
        char name[256] = {0};
        for(int i = 0, j = 0; i < size; i ++) {
            // 部分线程使用 16进制地址值 作为线程名，直接处理成 ‘*’
            if(i + 1< size && cThreadName[i] == '0' && cThreadName[i+1] == 'x') {
                i += 2;
                while(i < size && (isdigit(cThreadName[i]) || (cThreadName[i] >= 'a' && cThreadName[i] <= 'f'))) {
                    i ++;
                }
                name[j ++] = '*';
            }
            
            // 将连续的数字处理成‘*’，避免线程名 metric 过多
            if(i < size && isdigit(cThreadName[i])) {
                if(j > 0 && name[j-1] == '*') {
                    continue;
                } else {
                    name[j ++] = '*';
                }
            }
            else if(i < size){
                name[j ++] = cThreadName[i];
            }
        }
        return [NSString stringWithUTF8String:name];
    }
    return nil;
}

- (NSString *)getBussinessFromThreadName:(NSString *)name {
    __block NSString *ret = nil;
    if(self.businessList && self.businessList.count) {
        [self.businessList enumerateObjectsUsingBlock:^(NSString * _Nonnull bizName, NSUInteger idx, BOOL * _Nonnull stop) {
            if([name containsString:bizName]) {
                ret = [NSString stringWithFormat:@"business_%@", bizName];
                *stop = YES;
            }
        }];
    }
    return ret;
}

// threadDic 的 k/v 是 (NSString *)thread_name / (NSNumber) count
+ (NSString *)stringFromDictionary:(NSDictionary *)threadDic {
    if(HMDIsEmptyDictionary(threadDic)) {
        return nil;
    }
    NSMutableString *string = [NSMutableString string];
    [threadDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        [string appendFormat:@"%@ : %@\n", key, obj.stringValue];
    }];
    return [string copy];
}

+ (NSString *)getSpecialThreadLevel:(NSUInteger)count {
    if(count > 30) {
        return @">30";
    } else {
        NSUInteger level = count / 10;
        return [NSString stringWithFormat:@"%lu~%lu", level * 10, (level+1) * 10];
    }
}

+ (NSString *)getInAppTimeLevel:(NSTimeInterval)inAppTime {
    if(inAppTime > hour * 3) {
        return @"3h < t";
    } else if(inAppTime > hour) {
        return @"1h < t <= 3h";
    } else if(inAppTime > 0.5 * hour) {
        return @"0.5h < t <= 1h";
    } else if(inAppTime > 10 * minute) {
        return @"10min < t <= 0.5h";
    } else if(inAppTime > 5 * minute) {
        return @"5min < t <= 10min";
    } else if(inAppTime > minute) {
        return @"1min < t <= 5min";
    } else if(inAppTime > 30 * second) {
        return @"30s < t <= 1min";
    } else if(inAppTime > 8 * second) {
        return @"8s < t <= 30s";
    } else {
        return @"0s < t <= 8s";
    }
}

@end
