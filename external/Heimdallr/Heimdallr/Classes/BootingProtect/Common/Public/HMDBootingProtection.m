//
//  HMDBootingProtection.m
//  Created by joy on 2018/4/9.

#include <stdatomic.h>
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
#include <objc/runtime.h>
#import "Heimdallr.h"
#import "HMDFileTool.h"
#import "HMDUserDefaults.h"
#import "HMDCrashTracker.h"
#import "Heimdallr+Private.h"
#import "HMDSessionTracker.h"
#import "HeimdallrUtilities.h"
#import "HMDOOMCrashTracker.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDBootingProtection.h"
#import "HMDExcludeModuleHelper.h"
#import "HMDCrashDirectory+Private.h"

#include "pthread_extended.h"

static NSString *kBootingProtectRootPath = nil;
static NSString *kLastTimeLaunchExitFilePath = nil;
static NSString *kCrashFilesDirectoryPath = nil;

static NSString *const kHMDExitReasonFrequencyKey = @"kHMDExitReasonFrequencyKey";

CLANG_ATTR_OBJC_DIRECT_MEMBERS
@implementation HMDBootingProtection

+ (void)startProtectWithLaunchTimeThreshold:(NSTimeInterval)launchTimeThreshold
                           handleCrashBlock:(HandleCrashBlock)handleCrashBlock
                           CLANG_ATTR_OCLINT_SUPPRESS_BLOCK_CAPTURE_SELF
{
    if(handleCrashBlock == nil) DEBUG_RETURN_NONE;
    
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) DEBUG_RETURN_NONE;
    
    [HMDBootingProtection setDirectory];
    
    [HMDBootingProtection markLaunchCompleteAfterLaunchTimeThreshold:launchTimeThreshold];
    
    BOOL lastTimeLaunchComplete = [HMDBootingProtection checkAndMarkLaunchState];
    if  (lastTimeLaunchComplete){
        [HMDBootingProtection clearCrashFiles];
        handleCrashBlock(0);
        return;
    }
    
    if(!HMDCrashTracker.sharedTracker.isRunning){
        NSAssert(NO, @"CrashDetect not started! Check if HMDCrashTracker has been started.");
        handleCrashBlock(0);
        return;
    }
    
    BOOL lastTimeCrash = HMDCrashDirectory.lastTimeCrash;
    
    if(lastTimeCrash) {
        NSInteger currentCount = [HMDBootingProtection crashCount];
        currentCount++;
        handleCrashBlock(currentCount);
        [HMDBootingProtection increaseCrashFiles];
    } else {
        [HMDBootingProtection clearCrashFiles];
        handleCrashBlock(0);
    }
}

static pthread_mutex_t shared_appExitReasonLock = PTHREAD_MUTEX_INITIALIZER;

// 访问需要在 shared_appExitReasonLock 保护范围内
static BOOL shared_finishedDetectExitReason = NO;
static NSMutableArray <HandleExitReasonBlock> * _Nullable shared_callbackArray = nil;
static HMDApplicationRelaunchReason shared_exitReason = HMDApplicationRelaunchReasonNoData;
static NSUInteger shared_frequency = 0;
static BOOL shared_isLaunchCrash = NO;


+ (void)appExitReasonWithLaunchCrashTimeThreshold:(NSTimeInterval)launchCrashTimeThreshold
                                      handleBlock:(HandleExitReasonBlock)handleBlock {
    
    NSAssert(Heimdallr.shared.enableWorking,
             @"Heimdallr is uninitialized! Method should be calling after heimdallr initialized.");
    
    if (handleBlock == nil) DEBUG_RETURN_NONE;
    
    pthread_mutex_lock(&shared_appExitReasonLock);
    if(shared_finishedDetectExitReason) {
        pthread_mutex_unlock(&shared_appExitReasonLock);
        handleBlock(shared_exitReason, shared_frequency, shared_isLaunchCrash);
        return;
    }
    
    
    if (shared_callbackArray.count > 0) {
        // thread exist detection not complete
        [shared_callbackArray addObject:handleBlock];
        pthread_mutex_unlock(&shared_appExitReasonLock);
        return;
    }
    
    // add detection inside calloutArray
    if(shared_callbackArray == nil)
       shared_callbackArray = NSMutableArray.array;
    [shared_callbackArray addObject:handleBlock];
    pthread_mutex_unlock(&shared_appExitReasonLock);
    
    
    dispatch_on_heimdallr_queue(YES, ^{
        [self detectExitReasonOnHeimdallrQueue:launchCrashTimeThreshold];
        GCC_FORCE_NO_OPTIMIZATION
    });
}

+ (void)detectExitReasonOnHeimdallrQueue:(NSTimeInterval)launchCrashTimeThreshold {
    HMD_DEBUG_ASSERT_ON_Heimdallr_QUEUE();
    
    //Crash
    if ([HMDCrashTracker sharedTracker].isRunning) {
        
        BOOL lastTimeCrash = HMDCrashDirectory.lastTimeCrash;
        if (lastTimeCrash) {
            pthread_mutex_lock(&shared_appExitReasonLock);
            shared_exitReason = HMDApplicationRelaunchReasonCrash;
            shared_frequency = [self saveFrequencyWithReason:shared_exitReason];
            shared_finishedDetectExitReason = YES;
            shared_isLaunchCrash = [self isLaunchCrashWithReason:shared_exitReason timeThreshold:launchCrashTimeThreshold];
            
            NSArray * currentCallBacks = [shared_callbackArray copy];
            
            [shared_callbackArray removeAllObjects];
            pthread_mutex_unlock(&shared_appExitReasonLock);
            [self performCallback:currentCallBacks];
            return;
        }
    }
    
    // OOM
    if ([[HMDOOMCrashTracker sharedTracker] isRunning]) {
        HMDExcludeModuleCallback excludedBlock = ^{
            pthread_mutex_lock(&shared_appExitReasonLock);
            shared_exitReason = [HMDOOMCrashTracker sharedTracker].reason;
            shared_frequency = [self saveFrequencyWithReason:shared_exitReason];
            shared_isLaunchCrash = [self isLaunchCrashWithReason:shared_exitReason timeThreshold:launchCrashTimeThreshold];
            shared_finishedDetectExitReason = YES;
            
            NSArray * currentCallBacks = [shared_callbackArray copy];
            
            [shared_callbackArray removeAllObjects];
            pthread_mutex_unlock(&shared_appExitReasonLock);
            [self performCallback:currentCallBacks];
        };
        
        HMDExcludeModuleHelper *excludedHelper = [[HMDExcludeModuleHelper alloc] initWithSuccess:excludedBlock
                                                                                         failure:excludedBlock
                                                                                         timeout:excludedBlock];
        
        [excludedHelper addClass:HMDOOMCrashTracker.class forDependency:HMDExcludeModuleDependencyFinish];
        [excludedHelper startDetection];
        
        return;
    }
    
    // Other
    
    pthread_mutex_lock(&shared_appExitReasonLock);
    shared_frequency = [self saveFrequencyWithReason:shared_exitReason];
    shared_finishedDetectExitReason = YES;
    
    NSArray * currentCallBacks = [shared_callbackArray copy];
    
    [shared_callbackArray removeAllObjects];
    pthread_mutex_unlock(&shared_appExitReasonLock);
    [self performCallback:currentCallBacks];
}

+ (void)performCallback:(NSArray<HandleExitReasonBlock> *)callbacks {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (HandleExitReasonBlock callback in callbacks) {
            callback(shared_exitReason, shared_frequency, shared_isLaunchCrash);
        }
    });
}

#pragma mark - lastTimeLaunchState

+ (BOOL)checkAndMarkLaunchState {
    BOOL launchExit = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:kLastTimeLaunchExitFilePath]) {
        launchExit = YES;
    } else {
        hmdCheckAndCreateDirectory(kLastTimeLaunchExitFilePath);
    }
    return !launchExit;
}

+ (void)markLaunchCompleteAfterLaunchTimeThreshold:(NSTimeInterval)launchTimeThreshold{
    if(isnan(launchTimeThreshold) || isinf(launchTimeThreshold) || launchTimeThreshold <= 0.0)
        launchTimeThreshold = 5.0;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(launchTimeThreshold * NSEC_PER_SEC)),
                   dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
                   ^{
        [[NSFileManager defaultManager] removeItemAtPath:kLastTimeLaunchExitFilePath error:nil];
    });
}

+ (void)setDirectory {
    NSString *heimdallrRootPath = [HeimdallrUtilities heimdallrRootPath];
    NSFileManager *manager = [NSFileManager defaultManager];
    kBootingProtectRootPath = [heimdallrRootPath stringByAppendingPathComponent:@"BootingProtect"];
    BOOL isDirectory = YES;
    if (![manager fileExistsAtPath:kBootingProtectRootPath isDirectory:&isDirectory] || !isDirectory) {
        hmdCheckAndCreateDirectory(kBootingProtectRootPath);
    }
    
    kCrashFilesDirectoryPath = [kBootingProtectRootPath stringByAppendingPathComponent:@"CrashFiles"];
    isDirectory = YES;
    if (![manager fileExistsAtPath:kCrashFilesDirectoryPath isDirectory:&isDirectory] || !isDirectory) {
        hmdCheckAndCreateDirectory(kCrashFilesDirectoryPath);
    }
    
    kLastTimeLaunchExitFilePath = [kBootingProtectRootPath stringByAppendingPathComponent:@"LastTimeLaunchExit"];
}

+ (void)increaseCrashFiles {
    NSString *crashFileName = [kCrashFilesDirectoryPath stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    hmdCheckAndCreateDirectory(crashFileName);
}

+ (void)clearCrashFiles {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [manager contentsOfDirectoryAtPath:kCrashFilesDirectoryPath error:nil];
    for (NSString *fileName in files) {
        NSString *filePath = [kCrashFilesDirectoryPath stringByAppendingPathComponent:fileName];
        [manager removeItemAtPath:filePath error:nil];
    }
}

#pragma mark - crashCount

// get CrashCount
+ (NSUInteger)crashCount {
    static NSUInteger crashCount;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:kCrashFilesDirectoryPath error:nil];
        crashCount = [files count];
    });
    return crashCount;
}

#pragma - mark - launch crash

+ (BOOL)isLaunchCrashWithReason:(HMDApplicationRelaunchReason)reason timeThreshold:(NSTimeInterval)timeThreshold {
    BOOL isLaunchCrash = NO;
    if (reason == HMDApplicationRelaunchReasonFOOM ||
        reason == HMDApplicationRelaunchReasonCrash ||
        reason == HMDApplicationRelaunchReasonWatchDog) {
        
        if (hermas_enabled()) {
            NSDictionary *latestSessionDic = [HMDSessionTracker latestSessionDicAtLastLaunch];
            if (!latestSessionDic) {
                double duration = [latestSessionDic hmd_doubleForKey:@"duration"];
                isLaunchCrash = (timeThreshold - duration > 0) ? YES : NO;
            }
        } else {
            CLANG_DIAGNOSTIC_PUSH
            CLANG_DIAGNOSTIC_IGNORE_DEPRECATED_DECLARATIONS
            HMDApplicationSession *latestSession = [HMDSessionTracker latestSessionAtLastLaunch];
            CLANG_DIAGNOSTIC_POP
            if (latestSession != nil) {
                isLaunchCrash = (timeThreshold - latestSession.duration > 0) ? YES : NO;
            }
        }
    }
    return isLaunchCrash;
}

#pragma - mark - frequency

+ (NSUInteger)saveFrequencyWithReason:(HMDApplicationRelaunchReason)reason {
    NSString *reasonKey = [NSString stringWithFormat:@"%u", reason];
    NSDictionary *frequencyDic = [[HMDUserDefaults standardUserDefaults] objectForKeyCompatibleWithHistory:kHMDExitReasonFrequencyKey];
    NSUInteger frequency = 1;
    
    if (frequencyDic) {
        frequency = [frequencyDic hmd_unsignedIntegerForKey:reasonKey];
        if (frequency) frequency ++;
        else frequency = 1;
    }

    NSDictionary *dic = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:frequency] forKey:reasonKey];
    [[HMDUserDefaults standardUserDefaults] setObject:dic forKey:kHMDExitReasonFrequencyKey];
    
    return frequency;
}

#pragma mark - 好用工具 (´・ω・`)

+ (void)deleteAllFilesUnderDocumentsLibraryCaches {

    NSString *documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *libraryDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];

    NSMutableArray<NSString *> *array = [NSMutableArray arrayWithCapacity:3];

    if(documentDir != nil) [array addObject:documentDir];
    if(libraryDir != nil) [array addObject:libraryDir];
    if(cacheDir != nil) [array addObject:cacheDir];

    NSFileManager *manager = [NSFileManager defaultManager];

    for (NSString *filepath in array) {
        if ([manager fileExistsAtPath:filepath]) {
            NSArray<NSString *> *subFileArray = [manager contentsOfDirectoryAtPath:filepath error:nil];
            for (NSString *subFileName in subFileArray) {
                NSString *subFilePath = [filepath stringByAppendingPathComponent:subFileName];
                [manager removeItemAtPath:subFilePath error:nil];
            }
        }
    }
}

@end
