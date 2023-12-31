//
//  HMDOOMAppState.m
//  Pods
//
//  Created by 刘夏 on 2019/11/4.
//

#import "HMDOOMAppState.h"

#import "HeimdallrUtilities.h"
#import "HMDAppExitReasonDetector.h"
#import "HMDALogProtocol.h"
#import "HMDDiskSpaceDistribution.h"
#import "HMDDiskUsage.h"

#include <sys/stat.h>
#include <sys/mman.h>
#include <mach/mach.h>

#import "HMDCrashAppExitReasonMark.h"
#import "HMDOOMCrashSDKLog.h"
#import "HMDFileTool.h"

#import "HMDWatchDogAppExitReasonMark.h"

#define kHMDCharLength 100

//禁止修改字段顺序
typedef struct AppState {
    /*** version 1 ***/
    int fd;
    BOOL isAppEnterBackground;
    BOOL isAppQuitByExit;
    BOOL isAppQuitByUser;
    BOOL isMonitorStopped;
    dispatch_source_memorypressure_flags_t memoryPressure;
    NSTimeInterval memoryPressureTimestamp;
    BOOL isProbablyDeadlock;
    
    /*** version 2 ***/
    bool isCrash;
    BOOL isWatchDog;
    
    double enterForegroundTime;
    double enterBackgroundTime;
    double latestTime; //app存活的最新时间戳，尽可能靠近OOM Crash的时间，可频繁更新
    
    //静态信息
    double appStartTime;
    char internalSessionID[kHMDCharLength];
    char appVersion[kHMDCharLength];
    char buildVersion[kHMDCharLength];
    char sysVersion[kHMDCharLength];
    BOOL isDebug;
    BOOL isXCTest;
    
    //动态信息：关键信息存储在AppsState，其它信息存储文件，如last scene，operation trace等
    double updateTime; //动态信息更新的时间戳
    uint64_t appMemory;//app占用内存
    uint64_t usedMemory;//设备占用内存
    uint64_t totalMemory;//设备总内存
    uint64_t availableMemory;//设备可用内存
    uint64_t appMemoryPeak;//app最大占用内存
    uint64_t heap_size_in_use __attribute__((deprecated("Deprecated! This version is compatible. This field cannot be deleted and the order of it cannot be changed.")));
    uint64_t heap_size_in_use_peak __attribute__((deprecated("Deprecated! This version is compatible. This field cannot be deleted and the order of it cannot be changed.")));
    uint64_t heap_size_allocated __attribute__((deprecated("Deprecated! This version is compatible. This field cannot be deleted and the order of it cannot be changed.")));
    char libraryPath[kHMDCharLength];// 沙盒library路径
    unsigned long exception_main_address;// Main函数的地址
    bool isSlardarMallocInuse; // 是否切换至slardarmalloc内存分配器
    size_t slardarMallocUsageSize; // slardarmalloc使用的mmap文件映射内存
    uint64_t totalVirtualMemory;//app总虚拟内存
    uint64_t usedVirtualMemory;//app占用虚拟内存
    
    int appContinuousQuitTimes; //记录用户连续退出的次数
    
    char thermalState[kHMDCharLength]; //设备温度信息
    
    BOOL isWeakWatchDog; //主线程卡住，在达到卡死阈值前App退出
    bool isCPUException;
    
    double lastSenceChangedTime;//最近一次页面变化的时间戳
} AppState;

@implementation HMDOOMAppState

static AppState *HMDInitializeMMappedFile(int *error) {
    NSString *path = [HMDOOMAppState infoPath];
    
    int fd = open([path UTF8String], O_RDWR | O_CREAT, S_IRWXU);
    if (fd < 0) return NULL;

    struct stat st = {0};
    if (fstat(fd, &st) == -1) {
        close(fd);
        return NULL;
    }
    
    size_t size = round_page(sizeof(AppState));
    if (!HMDFileAllocate(fd, size, error)) {
        close(fd);
        return NULL;
    }

    void *mapped = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (!mapped) {
        close(fd);
        return NULL;
    }
    
    mlock(mapped, size);
    
    AppState *state = (AppState *)mapped;
    state->fd = fd;
    return state;
}

static void getMoreDiskSpace(void) {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        size_t size = round_page(sizeof(AppState));
        [[HMDDiskSpaceDistribution sharedInstance] getMoreDiskSpaceWithSize:size priority:HMDDiskSpacePriorityOOMCrash usingBlock:^(BOOL * _Nonnull stop, BOOL moreSpace) {
            if (!moreSpace) {
                *stop = YES;
                return;
            }
            
            // more space and realloc
            int error = 0;
            AppState *appState;
            if (!(appState = HMDInitializeMMappedFile(&error))) {
                if (error != ENOSPC) {
                    *stop = YES;
                }
            } else {
                if (state) memcpy(appState, state, size);
                state = appState;
                *stop = YES;
            }
        }];
    });
}

static AppState *state = NULL;

+ (instancetype)sharedInstance {
    static HMDOOMAppState *instance;
     static dispatch_once_t onceToken;
     dispatch_once(&onceToken, ^{
         instance = [self new];
         
         if (![[NSFileManager defaultManager] fileExistsAtPath:[HMDOOMAppState infoPath]]) {
             instance.isNewData = YES;
         }
         
         int error = 0;
         if (!(state = HMDInitializeMMappedFile(&error))) {
             HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"OOMDetector faile to create mmaped file");
             static AppState nullState;
             state = &nullState;
             instance.isNewData = YES;

             if (error == ENOSPC) {
                 getMoreDiskSpace();
             }
         }
     });

     return instance;
}

+ (NSString *)infoPath {
    NSString *dir = [[HeimdallrUtilities heimdallrRootPath] stringByAppendingPathComponent:kHMD_OOM_DirectoryName];
    [HMDAppExitReasonDetector findOrCreateDirectoryInPath:dir];
    return [dir stringByAppendingPathComponent:@"oom-state.data"];
}

#pragma mark -

- (BOOL)isAppEnterBackground {
    return state->isAppEnterBackground;
}

- (void)setIsAppEnterBackground:(BOOL)isAppEnterBackground {
    state->isAppEnterBackground = isAppEnterBackground;
    // 只有在前台时间才会上报，所以只需要记录进入前台时间
    if (isAppEnterBackground) {
        state->enterBackgroundTime = [[NSDate date] timeIntervalSince1970];
    } else {
        state->enterForegroundTime = [[NSDate date] timeIntervalSince1970];
    }
}

- (NSTimeInterval)enterForgoundTime {
    return state->enterForegroundTime;
}

- (BOOL)isAppQuitByExit {
    return state->isAppQuitByExit;
}

- (void)setIsAppQuitByExit:(BOOL)isAppQuitByExit {
    state->isAppQuitByExit = isAppQuitByExit;
}

- (BOOL)isAppQuitByUser {
    return state->isAppQuitByUser;
}

- (void)setIsAppQuitByUser:(BOOL)isAppQuitByUser {
    state->isAppQuitByUser = isAppQuitByUser;
}

- (BOOL)isMonitorStopped {
    return state->isMonitorStopped;
}

- (void)setIsMonitorStopped:(BOOL)isMonitorStopped {
    state->isMonitorStopped = isMonitorStopped;
}

- (dispatch_source_memorypressure_flags_t)memoryPressure {
    return state->memoryPressure;
}

- (void)setMemoryPressure:(dispatch_source_memorypressure_flags_t)memoryPressure {
    state->memoryPressure = memoryPressure;
}

- (void)setMemoryPressureTimestamp:(NSTimeInterval)memoryPressureTimestamp {
    state->memoryPressureTimestamp = memoryPressureTimestamp;
}

- (NSTimeInterval)memoryPressureTimestamp {
    return state->memoryPressureTimestamp;
}

- (void)setIsCrash:(BOOL)isCrash {
    state->isCrash = isCrash?true:false;
    // 崩溃的时候需要通过这种安全的赋值方式
    HMDCrashKit_registerAppExitReasonMark(&(state->isCrash));
}

- (BOOL)isCrash {
    return state->isCrash?YES:NO;
}

- (void)setIsWatchDog:(BOOL)isWatchDog {
    state->isWatchDog = isWatchDog;
    
    HMDWatchDog_registerAppExitReasonMark(&(state->isWatchDog));
}

- (BOOL)isWatchDog {
    return state->isWatchDog;
}

- (void)setEnterForegroundTime:(NSTimeInterval)enterForegroundTime {
    state->enterForegroundTime = enterForegroundTime;
}

- (NSTimeInterval)enterForegoundTime {
    return state->enterForegroundTime;
}

- (void)setEnterBackgoundTime:(NSTimeInterval)enterBackgoundTime {
    state->enterBackgroundTime = enterBackgoundTime;
}

- (NSTimeInterval)enterBackgoundTime {
    return state->enterBackgroundTime;
}

- (void)setLatestTime:(NSTimeInterval)latestTime {
    state->latestTime = latestTime;
}

- (NSTimeInterval)latestTime {
    return state->latestTime;
}

- (void)setInternalSessionID:(NSString *)internalSessionID {
    if (internalSessionID.length == 0) {
        memset(state->internalSessionID, 0, kHMDCharLength);
    } else {
        snprintf(state->internalSessionID, kHMDCharLength, "%s", internalSessionID.UTF8String);
    }
}

- (NSString *)internalSessionID {
    return @(state->internalSessionID);
}

- (void)setAppStartTime:(NSTimeInterval)appStartTime {
    state->appStartTime = appStartTime;
}

- (NSTimeInterval)appStartTime {
    return state->appStartTime;
}

- (void)setMemoryInfo:(HMDOOMAppStateMemoryInfo)memoryInfo {
#define SET_MEMORY(x) (state->x = memoryInfo.x)
    SET_MEMORY(updateTime);
    SET_MEMORY(appMemory);
    SET_MEMORY(usedMemory);
    SET_MEMORY(totalMemory);
    SET_MEMORY(availableMemory);
    SET_MEMORY(appMemoryPeak);
    SET_MEMORY(totalVirtualMemory);
    SET_MEMORY(usedVirtualMemory);
#undef SET_MEMORY
}

- (HMDOOMAppStateMemoryInfo)memoryInfo {
    HMDOOMAppStateMemoryInfo memory = {0};
#define SET_MEMORY(x) (memory.x = state->x)
    SET_MEMORY(updateTime);
    SET_MEMORY(appMemory);
    SET_MEMORY(usedMemory);
    SET_MEMORY(totalMemory);
    SET_MEMORY(availableMemory);
    SET_MEMORY(appMemoryPeak);
    SET_MEMORY(totalVirtualMemory);
    SET_MEMORY(usedVirtualMemory);
#undef SET_MEMORY
    return memory;
}

- (void)setIsDebug:(BOOL)isDebug {
    state->isDebug = isDebug;
}

- (BOOL)isDebug {
    return state->isDebug;
}

- (void)setIsXCTest:(BOOL)isXCTest {
    state->isXCTest = isXCTest;
}

- (BOOL)isXCTest {
    return state->isXCTest;
}

- (void)setLibraryPath:(NSString *)libraryPath {
    if (libraryPath.length == 0) {
        memset(state->libraryPath, 0, kHMDCharLength);
    } else {
        snprintf(state->libraryPath, kHMDCharLength, "%s", libraryPath.UTF8String);
    }
}

- (NSString *)libraryPath {
    return @(state->libraryPath);
}

- (void)setAppVersion:(NSString *)appVersion {
    if (appVersion.length == 0) {
        memset(state->appVersion, 0, kHMDCharLength);
    } else {
        snprintf(state->appVersion, kHMDCharLength, "%s", appVersion.UTF8String);
    }
}

- (NSString *)appVersion {
    return @(state->appVersion);
}

- (void)setBuildVersion:(NSString *)buildVersion {
    if (buildVersion.length == 0) {
        memset(state->buildVersion, 0, kHMDCharLength);
    } else {
        snprintf(state->buildVersion, kHMDCharLength, "%s", buildVersion.UTF8String);
    }
}

- (NSString *)buildVersion {
    return @(state->buildVersion);
}

- (void)setSysVersion:(NSString *)sysVersion{
    if (sysVersion.length == 0) {
        memset(state->sysVersion, 0, kHMDCharLength);
    } else {
        snprintf(state->sysVersion, kHMDCharLength, "%s", sysVersion.UTF8String);
    }
}

- (NSString *)sysVersion {
    return @(state->sysVersion);
}

- (unsigned long)exception_main_address {
    return state->exception_main_address;
}

- (void)setException_main_address:(unsigned long)exception_main_address {
    state->exception_main_address = exception_main_address;
}

- (void)setIsSlardarMallocInuse:(BOOL)isSlardarMallocInuse {
    state->isSlardarMallocInuse = isSlardarMallocInuse;
}

- (BOOL)isSlardarMallocInuse {
    return state->isSlardarMallocInuse;
}

- (void)setSlardarMallocUsageSize:(size_t)slardarMallocUsageSize {
    state->slardarMallocUsageSize = slardarMallocUsageSize;
}

- (size_t)slardarMallocUsageSize {
    return state->slardarMallocUsageSize;
}

- (int)appContinuousQuitTimes {
    return state->appContinuousQuitTimes;
}

- (void)setAppContinuousQuitTimes:(int)appContinuousQuitTimes {
    state->appContinuousQuitTimes = appContinuousQuitTimes;
}

- (void)setThermalState:(NSString *)thermalState {
    if (thermalState.length == 0) {
        memset(state->thermalState, 0, kHMDCharLength);
    } else {
        snprintf(state->thermalState, kHMDCharLength, "%s", thermalState.UTF8String);
    }
}

- (NSString *)thermalState {
    return @(state->thermalState);
}

- (BOOL)isWeakWatchDog {
    return state->isWeakWatchDog;
}

-(void)setIsWeakWatchDog:(BOOL)isWeakWatchDog {
    state->isWeakWatchDog = isWeakWatchDog;
    
    HMDWeakWatchDog_registerAppExitReasonMark(&(state->isWeakWatchDog));
}

- (void)setIsCPUException:(BOOL)isCPUException {
    state->isCPUException = isCPUException;
}

- (BOOL)isCPUException {
    return state->isCPUException;
}

- (void)setLastSenceChangedTime:(double)lastSenceChangedTime {
    state->lastSenceChangedTime = lastSenceChangedTime;
}

-(double)lastSenceChangedTime {
    return state->lastSenceChangedTime;
}

- (void)update:(void (^)(HMDOOMAppState * _Nonnull))block msync:(BOOL)msyncFlag {
    if (block) {
        block(self);
    }
    if (msyncFlag) {
        size_t size = round_page(sizeof(AppState));
        msync((void*)state, size, MS_SYNC);
    }
}

- (void)update:(void (^)(HMDOOMAppState *state))block {
    [self update:block msync:NO];
}

@end
