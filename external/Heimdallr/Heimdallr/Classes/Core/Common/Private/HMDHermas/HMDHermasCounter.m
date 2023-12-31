//
//  HMDHermasCounter.m
//  Heimdallr-8bda3036
//
//  Created by 崔晓兵 on 27/5/2022.
//

#import "HMDHermasCounter.h"
#include <sys/stat.h>
#include <sys/mman.h>
#include <mach/mach.h>
#include <stdatomic.h>
#import "HMDFileTool.h"
#import "HeimdallrUtilities.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDInfo+AppInfo.h"
#import "HMDFileTool.h"


typedef struct HermasCounter {
    atomic_ullong sequenceCode;
} HermasCounter;

@interface HMDHermasCounter ()
@property (nonatomic, strong) NSDictionary *classMap;
@property (nonatomic, strong) NSDictionary *moduleNameMap;

@end

@implementation HMDHermasCounter {
    HermasCounter *_counter;
}

+ (instancetype)shared {
    static HMDHermasCounter *counter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        counter = [[HMDHermasCounter alloc] init];
    });
    return counter;
}

// 如果需要更新 key-value 键值对顺序，尤其是 value 的值，一定要更新应用信息的基本信息。
// 具体参考：HMDInfo+AppInfo.h 中的 whetherAppIsUpdated 方法，目前支持的字段是：应用版本、应用 build 版本、bundle ID、Heimdallr版本。
- (NSDictionary *)classMap {
    if (!_classMap) {
        _classMap = @{
            // performace
            @"HMDBatteryMonitorRecord" : @(0),
            @"HMDCPUMonitorRecord" : @(1),
            @"HMDDiskMonitorRecord" : @(2),
            @"HMDFPSMonitorRecord" : @(3),
            @"HMDFrameDropRecord" : @(4),
            @"HMDMemoryMonitorRecord" : @(5),
            @"HMDControllerTimeRecord" : @(6),
            @"HMDUITrackRecord" : @(7),
            @"HMDHTTPDetailRecord" : @(8),
            @"HMDNetTrafficMonitorRecord" : @(9),
            @"HMDLaunchTimingRecord" : @(10),
            @"HMDStartRecord" : @(11),
            @"HMDTTMonitorRecord" : @(12),
            
            // exception
            @"HMDExceptionRecord" : @(13),
            @"HMDCPUExceptionV2Record" : @(14),
            @"HMDWatchdogProtectRecord" : @(15),
            @"HMDANRRecord" : @(16),
            @"HMDWatchDogRecord" : @(17),
            @"HMDUIFrozenRecord" : @(18),
            @"HMDOOMCrashRecord" : @(19),
            @"HMDFDRecord" : @(20),
            @"HMDDartRecord" : @(21),
            @"HMDGameRecord" : @(22),
            @"HMDMetricKitRecord" : @(23),

            // user exception
            @"HMDUserExceptionRecord" : @(24),
            
            // open tracing
            @"HMDOTTrace" : @(25),
            @"HMDOTSpan" : @(26),
            
            // has no record class
            @"CaptureBacktrace" : @(27),
            @"MetricKit" : @(28),
            @"OOMDetector" : @(29),
        };
    }
    return _classMap;
}

- (instancetype)init {
    if (self = [super init]) {
        _counter = [self initializeMMappFile];
        
        if ([[HMDInfo defaultInfo] whetherAppIsUpdated]) {
            [self resetSequenceCode];
        }
    }
    return self;
}

- (unsigned long long)generateSequenceCode:(NSString *)key {
    NSInteger index = [self.classMap hmd_integerForKey:key];
    unsigned long long code =  [self generateSequenceCodeWithIndex:index];
//    NSLog(@"[sequence_code] key = %@, code = %llu", key, code);
    return code;
}

- (unsigned long long)generateSequenceCodeWithIndex:(NSUInteger)index; {
    if (!_counter) return -1;
    // atomic
    unsigned long long sequenceNumber = atomic_fetch_add_explicit(&(_counter+index)->sequenceCode, 1, memory_order_acq_rel);
    return sequenceNumber;
}

- (void)resetSequenceCode {
    if (!_counter) return;
    
    for (int i = 0; i < self.classMap.count; i++) {
        atomic_exchange_explicit(&(_counter + i)->sequenceCode, 0, memory_order_acq_rel);
    }
}

#pragma mark - Private

- (HermasCounter *)initializeMMappFile {
    NSString *dir = [NSString stringWithFormat:@"%@/hermas", [HeimdallrUtilities heimdallrRootPath]];
    BOOL isDictionary;
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDictionary];
    if (!isExist) {
        hmdCheckAndCreateDirectory(dir);
    }
    NSString *path = [dir stringByAppendingPathComponent:@"hermas_counter.data"];
    
    int fd = open([path UTF8String], O_RDWR | O_CREAT, S_IRWXU);
    if (fd < 0) return NULL;

    struct stat st = {0};
    if (fstat(fd, &st) == -1) {
        close(fd);
        return NULL;
    }
    
    size_t size = round_page(sizeof(HermasCounter) * self.classMap.count);
    if (!HMDFileAllocate(fd, size, NULL)) {
        close(fd);
        return NULL;
    }

    void *mapped = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (!mapped) {
        close(fd);
        return NULL;
    }
        
    HermasCounter *counter = (HermasCounter *)mapped;
    close(fd);
    return counter;
}

@end
