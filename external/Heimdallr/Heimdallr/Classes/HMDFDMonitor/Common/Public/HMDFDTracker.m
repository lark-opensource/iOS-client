//
//  HMDFDMonitor.m
//  Pods
//
//  Created by wangyinhui on 2021/6/28.
//
#import "HMDFDTracker.h"
#import <BDFishhook/BDFishhook.h>
#import <sys/fcntl.h>
#import <sys/socket.h>
#import <sys/stat.h>
#include <arpa/inet.h>
#import <unistd.h>
#include <stdatomic.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>

#import "HMDALogProtocol.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDUserExceptionTracker.h"
#import "HMDThreadBacktraceParameter.h"
#import "HMDThreadBacktrace.h"
#include "HMDAsyncThread.h"
#import "HMDAppleBacktracesLog.h"
#import "HMDFDRecord.h"
#import "HMDExceptionReporter.h"
#import "HMDStoreCondition.h"
#import "Heimdallr.h"
#import "Heimdallr+Private.h"
#import "HMDMacro.h"
#import "HMDMemoryUsage.h"
#import "HMDDiskUsage.h"
#import "HMDNetworkHelper.h"
#import "HMDInjectedInfo+UniqueKey.h"
#import "HMDFDConfig.h"
#import "HMDFishhookQueue.h"

#import "HMDHermasHelper.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
// PrivateServices
#import "HMDServerStateService.h"

#define DEFAULT_FD_MAX_COUNT 5000
#define DEFAULT_WARN_FD 2000
#define MIN_WARN_FD_INTERVAL 20
#define MIN_WARN_FD_RATE 0.5
#define MAX_BACKTRACE_COUNT 20

#define HMD_OPEN_MAX 10240

#define HMD_MODE_BLK @"block_special"
#define HMD_MODE_CHR @"char_special"
#define HMD_MODE_DIR @"directory"
#define HMD_MODE_FIFO @"fifo_or_socket"
#define HMD_MODE_REG @"regular_file"
#define HMD_MODE_LNK @"symbolic_link"
#define HMD_MODE_SOCK @"socket"
#define HMD_MODE_OTHER @"other"

#define HMD(x) FD_MONITOR_##x
#define ORI(func) hmd_fd_ori_##func
#define REBINDING(func) \
    {#func, HMD(func), NULL}

#define HOOK(ret_type,func,...) \
static ret_type (*ORI(func))(__VA_ARGS__) = func;\
static ret_type (HMD(func))(__VA_ARGS__)

#define FD_ORI_PTR(func) \
+ (void *)ptr_##func { \
    return &ORI(func);\
}

#define IS_MAX_FD_COUNT(A,B,C) \
A > B && A > C

typedef enum {
    HMDHookFDTypeUNKNOWN,
    HMDHookFDTypeREG,
    HMDHookFDTypeSOCK,
    HMDHookFDTypeFIFO
} HMDHookFDType;


static NSString *const HMDFileDescriptorEventType = @"fd_exception";
static atomic_bool IsFDUseUp = false;
static atomic_int WarnFD = 0;
static atomic_int LastMaxFD = 0;

static atomic_int reg_count = 0;
static atomic_int sock_count = 0;
static atomic_int fifo_count = 0;

static int sampleInterval = 0;
static float WarnRate = 0.7;

bool hmd_upgrade_max_fd(int max_fd) {
    int current_max_fd = getdtablesize();
    if (max_fd <= current_max_fd || max_fd >= HMD_OPEN_MAX) {
        return false;
    }
    struct rlimit limit = {0};
    int ret = getrlimit(RLIMIT_NOFILE, &limit);
    if (ret < 0) return false;
    limit.rlim_cur = max_fd;
    ret = setrlimit(RLIMIT_NOFILE, &limit);
    if (ret < 0)
        return false;
    return true;
    
}

static HMDHookFDType get_primary_fd_type(void) {
    if (IS_MAX_FD_COUNT(reg_count, sock_count, fifo_count)) {
        return HMDHookFDTypeREG;
    }
    if (IS_MAX_FD_COUNT(sock_count, reg_count, fifo_count)) {
        return HMDHookFDTypeSOCK;
    }
    if (IS_MAX_FD_COUNT(fifo_count, reg_count, sock_count)) {
        return HMDHookFDTypeFIFO;
    }
    
    return HMDHookFDTypeUNKNOWN;
}

static int check_result_err(int result, HMDHookFDType fd_type){
    if (result < 0 && !IsFDUseUp){
        if(errno == ENFILE || errno == EMFILE){
            IsFDUseUp = true;
            [[HMDFDTracker sharedTracker] recodeWarnFDBacktrace:-1 withErr:errno];
            [[HMDFDTracker sharedTracker] recodeFileDescriptors];
        }
    }
    if (result > WarnFD && !IsFDUseUp) {
        int CurrentMaxFD = getdtablesize();
        //update warn fd when tablesize changed
        if (LastMaxFD != CurrentMaxFD) {
            LastMaxFD = CurrentMaxFD;
            WarnFD = (int)(CurrentMaxFD * WarnRate);
            return result;
        }
        //只对占用fd最多的文件类型进行堆栈采集
        if (fd_type != get_primary_fd_type()) {
            return result;
        }
        //update next warn fd
        if (sampleInterval > 0){
            WarnFD += sampleInterval;
        }else{
            WarnFD += (int)(CurrentMaxFD * 0.1);
        }
        
        [[HMDFDTracker sharedTracker] recodeWarnFDBacktrace:result withErr:0];
    }
    return result;
}

#pragma mark -file
HOOK(int, open, const char *path, int flags, ...) {
    reg_count++;
    if ((flags & O_CREAT) != 0) {
        // mode only applies to O_CREAT
        va_list ap = {0};
        mode_t mode = 0;
        va_start(ap, flags);
        mode = va_arg(ap, int);
        va_end(ap);
        int fd = hmd_fd_ori_open(path, flags, mode);
        return check_result_err(fd, HMDHookFDTypeREG);
    }
    int fd = hmd_fd_ori_open(path, flags);
    return check_result_err(fd, HMDHookFDTypeREG);
}

HOOK(int, openat, int dirfd, const char *path, int flags, ...){
    reg_count++;
    if ((flags & O_CREAT) != 0) {
        // mode only applies to O_CREAT
        va_list ap = {0};
        mode_t mode = 0;
        va_start(ap, flags);
        mode = va_arg(ap, int);
        va_end(ap);
        int fd = hmd_fd_ori_openat(dirfd, path, flags, mode);
        return check_result_err(fd, HMDHookFDTypeREG);
    }
    int fd = hmd_fd_ori_openat(dirfd, path, flags);
    return check_result_err(fd, HMDHookFDTypeREG);
}

HOOK(int, creat, const char *path, mode_t mode){
    reg_count++;
    int fd = hmd_fd_ori_creat(path, mode);
    return check_result_err(fd, HMDHookFDTypeREG);
}

HOOK(int, openx_np, const char *path, int flags, filesec_t fsec){
    reg_count++;
    int fd = hmd_fd_ori_openx_np(path, flags, fsec);
    return check_result_err(fd, HMDHookFDTypeREG);
}

HOOK(int, open_dprotected_np, const char *path, int flags, int class, int dpflags, ...){
    reg_count++;
    if ((flags & O_CREAT) != 0) {
        // mode only applies to O_CREAT
        va_list ap = {0};
        mode_t mode = 0;
        va_start(ap, dpflags);
        mode = va_arg(ap, int);
        va_end(ap);
        int fd = hmd_fd_ori_open_dprotected_np(path, flags, class, dpflags, mode);
        return check_result_err(fd, HMDHookFDTypeREG);
    }
    int fd = hmd_fd_ori_open_dprotected_np(path, flags, class, dpflags);
    return check_result_err(fd, HMDHookFDTypeREG);
}

#pragma mark -socket
HOOK(int, socket, int domain, int type, int protocol){
    sock_count++;
    int fd = hmd_fd_ori_socket(domain, type, protocol);
    return check_result_err(fd, HMDHookFDTypeSOCK);
}

#pragma mark -pipe
HOOK(int, pipe, int fildes[2]){
    fifo_count++;
    int result = hmd_fd_ori_pipe(fildes);
    if (result >= 0) {
        check_result_err(fildes[0], HMDHookFDTypeFIFO);
        return result;
    }
    return check_result_err(result, HMDHookFDTypeFIFO);
}

#pragma mark -add image callback
static void image_add_callback(const struct mach_header *mh, intptr_t vmaddr_slide) {
    dispatch_async(hmd_fishhook_queue(), ^{
        Dl_info info;
        if (dladdr(mh, &info) == 0) {
    #ifdef DEBUG
            printf("%s: dladdr(%p, ...) failed", __FUNCTION__, mh);
    #endif
            return;
        }
        struct bd_rebinding r[] = {
            //file
            REBINDING(open),
            REBINDING(creat),
            REBINDING(openat),
            REBINDING(openx_np),
            REBINDING(open_dprotected_np),
            //scoket
            REBINDING(socket),
            //pipe
            REBINDING(pipe)
        };
        int ret = bd_rebind_symbols_image((void *)mh, vmaddr_slide, r, sizeof(r)/sizeof(struct bd_rebinding));
        if (ret < 0){
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDFDMonitor] hookFDCreate err");
        }
        
    });
}


@interface HMDFDTracker() <HMDExceptionReporterDataProvider>
@property (atomic, strong) dispatch_queue_t syncQueue;
@property (nonatomic, strong) NSDictionary *fds;
@property (nonatomic, strong) NSString *homePath;
@property (nonatomic, strong) NSMutableArray<HMDThreadBacktrace *> *backtraces;
@property (nonatomic, assign) int maxFD;
@property (nonatomic, strong) NSString *errType;
@property (nonatomic, strong) NSArray<HMDStoreCondition *> *andConditions;
@property (nonatomic, strong) HMInstance *instance;
@end

@implementation HMDFDTracker

+ (instancetype)sharedTracker{
    static HMDFDTracker *monitor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        monitor = [[HMDFDTracker alloc] init];
    });
    return monitor;
}

-(instancetype)init{
    self = [super init];
    if (self) {
        _syncQueue = dispatch_queue_create("com.heimdallr.FDMonitor.syncQueue", DISPATCH_QUEUE_SERIAL);
        _homePath = [NSString stringWithFormat:@"/private%@", NSHomeDirectory()];
        _backtraces = [NSMutableArray new];
    }
    return self;
}

- (HMInstance *)instance {
    if (!_instance) {
        _instance = [[HMEngine sharedEngine] instanceWithModuleId:kModuleExceptionName aid:[HMDInjectedInfo defaultInfo].appID];
    }
    return _instance;
}

- (void)start{
    [super start];
#if !__has_feature(thread_sanitizer)
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        LastMaxFD = getdtablesize();
        WarnFD = (int)(LastMaxFD * WarnRate);
        if (WarnFD <= 0) {
            WarnFD = DEFAULT_WARN_FD;
        }
        _dyld_register_func_for_add_image(image_add_callback);
//        dispatch_async(hmd_fishhook_queue(), ^{
//            struct bd_rebinding r[] = {
//                //file
//                REBINDING(open),
//                REBINDING(creat),
//                REBINDING(openat),
//                REBINDING(openx_np),
//                REBINDING(open_dprotected_np),
//                //scoket
//                REBINDING(socket),
//                //pipe
//                REBINDING(pipe)
//            };
//            bd_rebind_symbols_patch(r, sizeof(r)/sizeof(struct bd_rebinding));
//        });
        
    });
#endif
}

- (void)stop{
    [super stop];
}

- (BOOL)needSyncStart {
    return NO;
}

- (BOOL)performanceDataSource {
    return NO;
}

- (BOOL)exceptionDataSource {
    return YES;
}

- (void)updateConfig:(HMDFDConfig *)config {
    config.enableUpload = YES;
    [super updateConfig:config];
    if (config.sampleInterval > MIN_WARN_FD_INTERVAL) {
        sampleInterval = config.sampleInterval;
    }
    if (config.fdWarnRate > MIN_WARN_FD_RATE) {
        WarnRate = config.fdWarnRate;
    }
    if (config.maxFD > 0) {
        hmd_upgrade_max_fd(config.maxFD);
    }
}

#pragma mark -- ori func
//file
FD_ORI_PTR(open)

FD_ORI_PTR(creat)
FD_ORI_PTR(openat)
FD_ORI_PTR(openx_np)
FD_ORI_PTR(open_dprotected_np)
//scoket
FD_ORI_PTR(socket)
//pipe
FD_ORI_PTR(pipe)

#pragma mark --fd monitor

- (NSDictionary *)getPathInfoForFD:(int)fd withType:(NSString *)type {
    NSMutableDictionary *fdInfo = [NSMutableDictionary new];
    [fdInfo hmd_setObject:@(fd) forKey:@"fd"];
    [fdInfo hmd_setObject:type forKey:@"type"];
    char buf[MAXPATHLEN+1];
    fcntl(fd , F_GETPATH, buf);
    if (errno != 0){
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDFDMonitor] getPathInfoForFD err  %s", strerror(errno));
        [fdInfo hmd_setObject:@"unknown" forKey:@"path"];
    }else{
        NSString *filePath = [NSString stringWithUTF8String:buf];
        if ([filePath hasPrefix:_homePath]){
            filePath = [filePath substringFromIndex: [_homePath length]];
        }
        [fdInfo hmd_setObject:filePath forKey:@"path"];
    }
    return [fdInfo copy];
}

- (NSDictionary *)getScoketInfoForFD:(int)fd {
    NSMutableDictionary *fdInfo = [NSMutableDictionary new];
    [fdInfo setObject:@(fd) forKey:@"fd"];
    [fdInfo hmd_setObject:HMD_MODE_SOCK forKey:@"type"];
    struct sockaddr_in local, peer;
    socklen_t local_len = sizeof(local);
    socklen_t peer_len = sizeof(peer);
    char local_ip[20];
    char peer_ip[20];
    int result = getsockname(fd, (struct sockaddr *)&local, &local_len);
    if (result < 0){
        [fdInfo setObject:@"unknown" forKey:@"local_ip"];
        [fdInfo setObject:@"unknown" forKey:@"local_port"];
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDFDMonitor] getsockname err  %s", strerror(errno));
    }else{
        inet_ntop(AF_INET, &local.sin_addr, local_ip, sizeof(local_ip));
        [fdInfo setObject:[NSString stringWithUTF8String:local_ip] forKey:@"local_ip"];
        [fdInfo setObject:@(ntohs(local.sin_port)) forKey:@"local_port"];
    }
    result = getpeername(fd, (struct sockaddr *)&peer, &peer_len);
    if (result < 0){
        [fdInfo setObject:@"unknown" forKey:@"peer_ip"];
        [fdInfo setObject:@"unknown" forKey:@"peer_port"];
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDFDMonitor] getpeername err  %s", strerror(errno));
    }else{
        inet_ntop(AF_INET, &peer.sin_addr, peer_ip, sizeof(peer_ip));
        [fdInfo setObject:[NSString stringWithUTF8String:peer_ip] forKey:@"peer_ip"];
        [fdInfo setObject:@(ntohs(peer.sin_port)) forKey:@"peer_port"];
    }
    return [fdInfo copy];
}

- (NSDictionary *)getFIFOInfoForFD:(int)fd withInode:(uint64_t)inode{
    NSMutableDictionary *fdInfo = [NSMutableDictionary new];
    [fdInfo hmd_setObject:@(fd) forKey:@"fd"];
    [fdInfo hmd_setObject:@(inode) forKey:@"inode"];
    [fdInfo hmd_setObject:HMD_MODE_FIFO forKey:@"type"];
    char buf[MAXPATHLEN+1];
    fcntl(fd , F_GETPATH, buf);
    if (errno != 0){
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDFDMonitor] getFIFOInfoForFD err  %s", strerror(errno));
        [fdInfo hmd_setObject:@"unknown" forKey:@"path"];
    }else{
        [fdInfo hmd_setObject:[NSString stringWithUTF8String:buf] forKey:@"path"];
    }
    return [fdInfo copy];
}

- (void)recodeWarnFDBacktrace:(int)fd withErr:(int)err{
    if (!self.isRunning) {
        return;
    }
    HMDThreadBacktraceParameter *parameter = [[HMDThreadBacktraceParameter alloc] init];
    parameter.keyThread = (thread_t)hmdthread_self();
    parameter.suspend = NO;
    parameter.skippedDepth = 3;
    parameter.needDebugSymbol = YES;
    HMDThreadBacktrace *backtrace = [HMDThreadBacktrace backtraceOfThreadWithParameter:parameter];
    dispatch_async(_syncQueue, ^{
        if (fd < 0) {
            if (err == ENFILE) {
                self.errType = @"ENFILE";
            }else if (err == EMFILE) {
                self.errType = @"EMFILE";
            }else {
                self.errType = @"UNKNOWN";
            }
            backtrace.name = [NSString stringWithFormat:@"%@(%s, max fd: %d)", backtrace.name, strerror(err), getdtablesize()];
            backtrace.crashed = YES;
        } else {
            backtrace.name = [NSString stringWithFormat:@"%@(current fd: %d)", backtrace.name, fd];
            backtrace.crashed = NO;
        }
        [self.backtraces addObject:backtrace];
        HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"[HMDFDMonitor] app consume too much fd， current fd:%d, max fd:%d", fd, getdtablesize());
        if(self.backtraces.count > MAX_BACKTRACE_COUNT) {
            [self.backtraces removeObjectAtIndex:0];
        }
    });
}

- (void)recodeFileDescriptors {
    dispatch_async(_syncQueue, ^(void){
        if (!self.isRunning){
            return;
        }
        BOOL needDropData = hermas_enabled() ? hermas_drop_data(kModuleExceptionName) : hmd_drop_data(HMDReporterException);
        if (needDropData) {
            return;
        }
        self.maxFD = getdtablesize();
        NSMutableArray *allfds = [NSMutableArray new];
        int flags;
        int fd;
        int max_fd_count = MIN(self.maxFD,DEFAULT_FD_MAX_COUNT);
        struct stat filestat;
        
        for (fd = 0; fd < max_fd_count; fd++) {
            errno = 0;
            flags = fcntl(fd, F_GETFD, 0);
            if (flags == -1 && errno) {
                continue;
            }
            int result = fstat(fd, &filestat);
            if (result != -1){
                if(S_ISBLK(filestat.st_mode)){
                    [allfds addObject:[self getPathInfoForFD:fd withType:HMD_MODE_BLK]];
                    continue;
                }
                if(S_ISCHR(filestat.st_mode)){
                    [allfds addObject:[self getPathInfoForFD:fd withType:HMD_MODE_CHR]];
                    continue;
                }
                if(S_ISDIR(filestat.st_mode)){
                    [allfds addObject:[self getPathInfoForFD:fd withType:HMD_MODE_DIR]];
                    continue;
                }
                if(S_ISFIFO(filestat.st_mode)){
                    [allfds addObject:[self getFIFOInfoForFD:fd withInode:filestat.st_ino]];
                    continue;
                }
                if (S_ISREG(filestat.st_mode)){
                    [allfds addObject:[self getPathInfoForFD:fd withType:HMD_MODE_REG]];
                    continue;
                }
                if(S_ISLNK(filestat.st_mode)){
                    [allfds addObject:[self getPathInfoForFD:fd withType:HMD_MODE_LNK]];
                    continue;
                }
                if (S_ISSOCK(filestat.st_mode)){
                    [allfds addObject: [self getScoketInfoForFD:fd]];
                    continue;
                }
                [allfds addObject:[self getPathInfoForFD:fd withType:HMD_MODE_OTHER]];
            }
            
        }
        
        if ([self.errType isEqual:@"ENFILE"]) {
            self.maxFD = fd;
        }
        
        self.fds = [allfds copy];
        [self reporterFDExceptionData];
    });
}


- (Class<HMDRecordStoreObject>)storeClass {
    return [HMDFDRecord class];
}

- (void)reporterFDExceptionData{
    if (!_fds || (_fds.count==0) || !_backtraces || (_backtraces.count==0) ){
        return;
    }
    NSMutableArray *bts = [NSMutableArray new];
    __block int index = 0;
    [_backtraces enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(HMDThreadBacktrace * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.threadIndex = index++;
        [bts addObject:obj];
    }];
    NSString *log = [HMDAppleBacktracesLog logWithBacktraces:[bts copy]
                                                        type:HMDLogExceptionFD
                                                   exception:nil
                                                      reason:nil];
    NSString * appleLog = [NSString stringWithFormat:@"ExceptionType:%@\n%@", HMDFileDescriptorEventType, log];
    HMDFDRecord *newRecord = [HMDFDRecord newRecord];
    newRecord.log = appleLog;
    newRecord.maxFD = _maxFD;
    newRecord.fds = _fds;
    newRecord.errType = _errType;
    hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
    newRecord.memoryUsage          = memoryBytes.appMemory / HMD_MB;
    newRecord.freeMemoryUsage      = memoryBytes.availabelMemory / HMD_MB;
    newRecord.freeDiskBlockSize    = [HMDDiskUsage getFreeDisk300MBlockSize];
    newRecord.business             = [HMDInjectedInfo defaultInfo].business ?: @"unknown";
    newRecord.access               = [HMDNetworkHelper connectTypeName];
    newRecord.lastScene            = [HMDTracker getLastSceneIfAvailable];
    newRecord.operationTrace       = [HMDTracker getOperationTraceIfAvailable];
    
    if (hermas_enabled()) {
        if (hermas_drop_data(kModuleExceptionName)) return;
        // update record
        [self updateRecordWithConfig:newRecord];
        
        // record
        BOOL recordImmediately = [HMDHermasHelper recordImmediately];
        HMRecordPriority priority = recordImmediately ? HMRecordPriorityRealTime : HMRecordPriorityHigh;
        [self.instance recordData:newRecord.reportDictionary priority:priority];
        
    } else {
        if(hmd_drop_data(HMDReporterException)) return;
        [self didCollectOneRecord:newRecord trackerBlock:^(BOOL flag) {
            if (flag) {
                [[HMDExceptionReporter sharedInstance] reportExceptionDataWithExceptionTypes:@[@(HMDFDExceptionType)]];
            } else {
                HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDFDMonitor] save fd record err");
            }
        }];
    }
    
    _backtraces = nil;
    _fds = nil;
}


- (NSArray *)pendingExceptionData {
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key                = @"timestamp";
    condition1.threshold          = 0;
    condition1.judgeType          = HMDConditionJudgeGreater;

    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key                = @"timestamp";
    condition2.threshold          = [[NSDate date] timeIntervalSince1970];
    condition2.judgeType          = HMDConditionJudgeLess;

    _andConditions = @[ condition1, condition2 ];

    NSArray<HMDFDRecord *> *records =
        [[Heimdallr shared].database getObjectsWithTableName:[[self storeClass] tableName]
                                                       class:[self storeClass]
                                               andConditions:_andConditions
                                                orConditions:nil];
    
    if (!records || records.count == 0) {
        return nil;
    }
    
    NSMutableArray *dataArray = [NSMutableArray array];

    for (HMDFDRecord *record in records) {
        
        NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
        long long timestamp = MilliSecond(record.timestamp);
        [dataValue setValue:@(timestamp) forKey:@"timestamp"];
        [dataValue setValue:HMDFileDescriptorEventType forKey:@"event_type"];
        [dataValue setValue:record.sessionID forKey:@"session_id"];
        [dataValue setValue:record.log forKey:@"stack"];
        [dataValue setValue:@(record.inAppTime) forKey:@"inapp_time"];
        [dataValue setValue:record.errType forKey:@"error_type"];
        [dataValue setValue:@(record.maxFD) forKey:@"max_fd"];
        [dataValue setValue:record.fds forKey:@"fds"];
        [dataValue setValue:@(record.memoryUsage) forKey:@"memory_usage"];
        [dataValue setValue:@(record.freeDiskBlockSize) forKey:@"d_zoom_free"];
        [dataValue setValue:@(hmd_calculateMemorySizeLevel(((uint64_t)record.freeMemoryUsage)*HMD_MEMORY_MB)) forKey:HMD_Free_Memory_Key];
        hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
        CGFloat          allMemory   = memoryBytes.totalMemory / HMD_MB;
        CGFloat freeMemoryRate = ((int)(record.freeMemoryUsage/allMemory*100))/100.0;
        [dataValue setValue:@(freeMemoryRate) forKey:HMD_Free_Memory_Percent_key];
        [dataValue setValue:record.business forKey:@"business"];
        [dataValue setValue:record.lastScene forKey:@"last_scene"];
        [dataValue setValue:record.operationTrace forKey:@"operation_trace"];
        [dataValue setValue:@(record.netQualityType) forKey:@"network_quality"];
        
        [dataValue addEntriesFromDictionary:record.environmentInfo];

        [[HMDInjectedInfo defaultInfo] confUniqueKeyForData:dataValue timestamp:timestamp eventType:HMDFileDescriptorEventType];
        
        [dataArray addObject:dataValue];
    }
    
    return dataArray;
}

// Response 之后数据清除等工作
- (void)exceptionReporterDidReceiveResponse:(BOOL)isSuccess{
    if (isSuccess)
        [[Heimdallr shared].database deleteObjectsFromTable:[[self storeClass] tableName]
                                              andConditions:_andConditions
                                               orConditions:nil];
}

- (void)dropExceptionData{
    [[Heimdallr shared].database deleteAllObjectsFromTable:[[self storeClass] tableName]];
}

#pragma mark - reporter

- (HMDExceptionType)exceptionType
{
    return HMDFDExceptionType;
}

@end
