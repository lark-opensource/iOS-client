//
//	HMDTTMonitorCounter.m
// 	Heimdallr
// 	
// 	Created by Hayden on 2020/4/24. 
//

#import "HMDTTMonitorCounter.h"
#import "HeimdallrUtilities.h"
#import "HMDALogProtocol.h"

#include <sys/stat.h>
#include <sys/mman.h>
#include <mach/mach.h>
#include <stdatomic.h>
#import "HMDFileTool.h"
#import "HMDInfo+AppInfo.h"

//禁止修改字段顺序
typedef struct EventCounter {
    atomic_llong sequenceNumber;    // 采样命中的事件的序列号，单调递增
    atomic_llong uniqueCode;        // 所有事件的唯一码
} EventCounter;

@interface HMDTTMonitorCounter () {
    EventCounter *_counter;
}

@property (nonatomic, assign, readwrite) BOOL isRunning;
@property (nonatomic, copy) NSString *appID;

@end

@implementation HMDTTMonitorCounter

static EventCounter *HMDInitializeMMappedFile(NSString *appID) {
    NSString *path = [HMDTTMonitorCounter infoPathWithAppID:appID];
    
    int fd = open([path UTF8String], O_RDWR | O_CREAT, S_IRWXU);
    if (fd < 0) return NULL;

    struct stat st = {0};
    if (fstat(fd, &st) == -1) {
        close(fd);
        return NULL;
    }
    
    size_t size = round_page(sizeof(EventCounter));
    if (!HMDFileAllocate(fd, size, NULL)) {
        close(fd);
        return NULL;
    }

    void *mapped = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (!mapped) {
        close(fd);
        return NULL;
    }
        
    EventCounter *counter = (EventCounter *)mapped;
    close(fd);
    return counter;
}

- (instancetype)initCounterWithAppID:(NSString *)appID {
    if (self = [super init]) {
        __weak typeof(self) weakSelf = self;
        self.appID = appID;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                if (!(strongSelf->_counter = HMDInitializeMMappedFile(appID))) {
                    HMDALOG_PROTOCOL_ERROR_TAG(@"HMDEventTrace", @"TTMonitor counter faile to create mmaped file, appid : %@", appID);
                }
                else {
                    strongSelf.isRunning = YES;
                    HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"TTMonitor counter success to create mmaped file, appid : %@", appID);
                    
                    if ([[HMDInfo defaultInfo] whetherAppIsUpdated]) {
                        [strongSelf resetSequenceCode];
                    }
                }
            }
        });
    }
    
    return self;
}

+ (NSString *)infoPathWithAppID:(NSString *)appID {
    NSString *dir = [[HeimdallrUtilities heimdallrRootPath] stringByAppendingPathComponent:@"TTMonitor"];
    NSFileManager *manager = [NSFileManager defaultManager];
    
    BOOL isDictionary;
    BOOL isExist = [manager fileExistsAtPath:dir isDirectory:&isDictionary];
    if (!isExist) {
        hmdCheckAndCreateDirectory(dir);
    }
    
    NSString *fileName = [appID stringByAppendingString:@"-counterV2.data"];
    return [dir stringByAppendingPathComponent:fileName];
}

#pragma - mark counter

- (void)resetSequenceCode {
    if (!_counter) return;

    atomic_exchange_explicit(&_counter->sequenceNumber, 0, memory_order_acq_rel);
    atomic_exchange_explicit(&_counter->uniqueCode, 0, memory_order_acq_rel);
}

- (int64_t)generateSequenceNumber {
    if (!_isRunning) {
        static atomic_flag onceToken = ATOMIC_FLAG_INIT;
        if (!atomic_flag_test_and_set_explicit(&onceToken, memory_order_acq_rel)) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"HMDEventTrace", @"TTMonitor counter with sequence number is not running! Appid : %@", self.appID);
        }
        
        return -1;
    }
    
    // atomic
    long long sequenceNumber = atomic_fetch_add_explicit(&_counter->sequenceNumber, 1, memory_order_acq_rel);
    
    return sequenceNumber;
}

- (int64_t)generateUniqueCode {
    if (!_isRunning) {
        static atomic_flag onceToken = ATOMIC_FLAG_INIT;
        if (!atomic_flag_test_and_set_explicit(&onceToken, memory_order_acq_rel)) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"HMDEventTrace", @"TTMonitor counter with unique code is not running! Appid : %@", self.appID);
        }
        
        return -1;
    }
    
    // atomic
    long long uniqueCode = atomic_fetch_add_explicit(&_counter->uniqueCode, 1, memory_order_acq_rel);
    
    return uniqueCode;
}

@end
