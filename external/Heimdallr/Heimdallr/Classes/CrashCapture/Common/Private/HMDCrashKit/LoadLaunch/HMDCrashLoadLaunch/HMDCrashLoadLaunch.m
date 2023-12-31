//
//  HMDCrashLoadLaunch.c
//  Heimdallr
//
//  Created by sunrunwang on 2024/08/08.
//

/* 崩溃模块 Load 启动的核心逻辑文件
 
    1. 业务创建启动参数 HMDCLoadOption 作为启动开始
    2. 业务调用 HMDCrashLoadLaunch 函数启动 Load 崩溃捕获
 
    3. HMDCrashLoadLaunch_directory 负责前期 Directory 文件夹创建,
                                    以及是否崩溃发生的判断
 
        (1) 创建基础文件夹
 
            CrashDetect/
                Active/
                    exception       文件用于判断是否上次发生崩溃
                LoadLaunch/         Load Launch 专属文件夹
                    Pending/        确认在 Load 阶段发生的崩溃, 但先暂存在此文件夹
                    Processing/     确认需要在 Load 阶段进行处理的崩溃,
                                    完成后会丢到 LoadLaunch/Prepared
                    Prepared/       确认需要在 Load 阶段进行上报的崩溃
                Processing/

 */

#import <zlib.h>
#import <stddef.h>
#import <stdbool.h>
#import <sys/stat.h>
#import <stdatomic.h>
#import <sys/sysctl.h>
#import <mach-o/arch.h>
#import <sys/utsname.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <Foundation/Foundation.h>

#import "HMDMacro.h"
#import "HMDTimeSepc.h"
#import "HMDURLSettings.h"
#import "HMDCrashDetect.h"
#import "HMDCLoadContext.h"
#import "HMDCrashLoadMeta.h"
#import "HMDCrashLoadSync.h"
#import "HMDCrashLoadModel.h"
#import "HMDCrashLoadReport.h"
#import "HMDCrashLoadLaunch.h"
#import "HMDCrashLoadOption.h"
#import "HMDCrashLoadLogger.h"
#import "HMDCrashLoadProfile.h"
#import "HMDCrashLoadLogger+Path.h"
#import "HMDCrashLoadSync+Private.h"
#import "HMDCrashLoadSync_LowLevel.h"
#import "HMDCrashLoadLaunch+Private.h"
#import "HMDCrashLoadReport+Private.h"
#import "HMDCrashDirectory_LowLevel.h"
#import "HMDCrashLoadOption+Private.h"
#import "HMDCrashLoadBackgroundSession.h"
#import "HMDCrashEnvironmentBinaryImages.h"

#pragma mark - Macro

#define PROFILE_TIME(_path) \
    option->timeProfile._path = HMD_XNUSystemCall_timeSince1970()

#pragma mark - Declaration

NS_ASSUME_NONNULL_BEGIN

static bool HMDCrashLoadLaunch_once        (void);
static bool HMDCrashLoadLaunch_safeGuard   (void);
static void HMDCrashLoadLaunch_prepare     (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_directory   (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_environment (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_detection   (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_process     (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_upload      (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_sync        (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_finish      (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_report      (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_endGuard    (HMDCLoadContext * context);

static void HMDCrashLoadLaunch_prepareMeta (HMDCLoadContext * context);

static void HMDCrashLoadLaunch_prepare_markStarting (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_prepare_fileManager  (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_prepare_raiseFDLimit (HMDCLoadContext * context);

static void HMDCrashLoadLaunch_directory_loadProcessing    (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_directory_trackerProcessing (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_directory_loadPending       (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_directory_trackerLastTime   (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_directory_trackerActive     (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_directory_loadPrepared      (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_directory_currentDirectory  (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_directory_loadMirror        (HMDCLoadContext * context);

static void HMDCrashLoadLaunch_environment_binaryImage (HMDCLoadContext * context);

static void HMDCrashLoadLaunch_process_internal           (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_process_triggerPrepareMeta (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_process_eachContent        (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_process_loadContent        (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_process_formatCrashLog     (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_process_dataDictionary     (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_process_multipartData      (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_process_gzipData           (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_process_outputData         (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_process_report             (HMDCLoadContext * context);

static void HMDCrashLoadLaunch_upload_internal                (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_upload_triggerPrepareMeta      (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_upload_constructURL            (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_upload_createBackgroundSession (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_upload_eachContent             (HMDCLoadContext * context);

static void HMDCrashLoadLaunch_prepareMeta_frozen     (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_prepareMeta_loadMirror (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_prepareMeta_profile    (HMDCLoadContext * context);

static void HMDCrashLoadLaunch_sync_outdateMirror    (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_sync_registerMirror   (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_sync_currentDirectory (HMDCLoadContext * context);
static void HMDCrashLoadLaunch_sync_markStarted      (HMDCLoadContext * context);

static HMDCLoadContext * _Nullable
contextFromOption(HMDCLoadOptionRef _Nullable externalOption);

static BOOL checkAndCreateDirectory(NSString * _Nonnull path,
                                    BOOL * _Nullable folderAlreadyExist);

static NSString *joinPath(NSString * _Nonnull path1, NSString * _Nonnull path2);

static NSArray<NSString *> * _Nullable dirContent(NSString * _Nonnull path);

static NSArray<NSString *> * _Nullable linesOfFile(NSString * _Nonnull path);

static NSString * _Nullable kernelOSVersionToString(void);

static NSString * _Nullable hardwareModelToString(void);

static NSString * _Nullable systemOrOSVersionToString(NSOperatingSystemVersion version);

static NSString * _Nullable systemControlByNameToString(const char * _Nonnull name);

static NSString * _Nullable deviceModelToString(bool iOSAppOnMac);

static bool processIsiOSAppOnMac(NSProcessInfo *process);

static NSString * _Nullable commitIDToString(void);

static NSString * _Nullable threadNameForThread(HMDCLoadContext * context,
                                                HMDCrashThreadInfo *thread,
                                                unsigned int threadIndex);

static NSString * _Nullable stackTraceForThread(HMDCLoadContext * context,
                                                HMDCrashThreadInfo *thread);

static NSString * _Nullable frameToString(HMDCrashFrameInfo *eachFrame,
                                          unsigned int frameIndex);

static NSDictionary * _Nullable crashDetailDictionary(HMDCLoadContext * context);

static NSString * _Nonnull SDKVersionString(void);

static NSDictionary * _Nullable JSONDataToDictionary(NSData * data);

static NSData * _Nullable dictionaryToJSONData(NSDictionary * dictionary);

static NSData * _Nullable dataFromUTF8(const char * _Nonnull rawString);

static void queryAddKeyString(NSMutableArray<NSURLQueryItem *> *queryItems,
                              NSString *key, NSString * stringValue);

static void queryAddKeyNumber(NSMutableArray<NSURLQueryItem *> *queryItems,
                              NSString *key, NSNumber * numberValue);

static NSString * _Nullable mirrorProfileAtPath(NSString *profilePath);

static NSData * _Nullable readMirrorProfileData(NSString *filePath);

static NSString * _Nullable profileDecision(NSString *mirrorValue,
                                            NSString *userValue,
                                            NSString *defaultValue,
                                            HMDCLoadOptionPriority priority);

NS_ASSUME_NONNULL_END

#pragma mark - Entrance

HMDCrashLoadReport * _Nullable
HMDCrashLoadLaunch_internal(HMDCLoadOptionRef _Nonnull externalOption);

HMDCrashLoadReport * _Nullable
HMDCrashLoadLaunch(HMDCLoadOptionRef _Nonnull externalOption) {
    HMDCrashLoadReport *report = nil;
    
    @try {
        report = HMDCrashLoadLaunch_internal(externalOption);
        
    } @catch (NSException *exception) {
        CLOAD_LOG("exception %s raised", exception.reason.UTF8String);
        DEBUG_POINT;
    }
    
    return report;
}

HMDCrashLoadReport * _Nullable
HMDCrashLoadLaunch_internal(HMDCLoadOptionRef _Nonnull externalOption) {

    if(!HMDCrashLoadLaunch_once()) return nil;
    
    if(!HMDCrashLoadLaunch_safeGuard()) return nil;
    
    HMDCLoadContext * context;
    
    context = contextFromOption(externalOption);
    
    if(context == nil) DEBUG_RETURN(nil);
    
    HMDCLoadOptionRef option = context.option;
    
    PROFILE_TIME(launch.beginTime);
    
    HMDCrashLoadLaunch_prepare(context);
    
    HMDCrashLoadLaunch_directory(context);
    
    HMDCrashLoadLaunch_environment(context);
    
    HMDCrashLoadLaunch_detection(context);
    
    HMDCrashLoadLaunch_process(context);
    
    HMDCrashLoadLaunch_upload(context);
    
    HMDCrashLoadLaunch_sync(context);
    
    HMDCrashLoadLaunch_finish(context);
    
    PROFILE_TIME(launch.endTime);
    
    HMDCrashLoadLaunch_report(context);
    
    HMDCrashLoadLaunch_endGuard(context);
    
    return context.report;
}

#pragma mark - Once Routine

static bool HMDCrashLoadLaunch_once(void) {
    
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(!atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
        CLOAD_LOG("[Once] load launch first time launch");
        return true;
    }
    
    CLOAD_LOG("[Once] detecting second time try to load launch, exit process");
    
    DEBUG_RETURN(false);
}

#pragma mark - Safe guard Routine

static bool HMDCrashLoadLaunch_safeGuard(void) {
    NSString * safeGuardMark1 = @"1";
    NSString * safeGuardMark2 = @"2";
    
    NSString *relativePath = @"Library/Heimdallr/CrashCapture/LoadLaunch/SafeGuard";
    NSString *directory    = joinPath(NSHomeDirectory(), relativePath);
    
    CLOAD_LOG("[SafeGuard] directory %s", CLOAD_PATH(directory));
    
    BOOL directoryAlreadyExist = NO;
    BOOL flag = checkAndCreateDirectory(directory, &directoryAlreadyExist);
    
    CLOAD_LOG("[DIR] create %s", CLOAD_PATH(directory));
    
    if(!flag) {
        CLOAD_LOG("[SafeGuard] prevent crash load launching, failed to create "
                  "directory at %s", CLOAD_PATH(directory));
        DEBUG_RETURN(false);
    }
    
    if(!directoryAlreadyExist) {
        CLOAD_LOG("[SafeGuard] permit crash load launching, first time create "
                  "directory at path %s", CLOAD_PATH(directory));
        return true;
    }
    
    NSString *mark1Path = joinPath(directory, safeGuardMark1);
    
    
    directoryAlreadyExist = NO;
    flag = checkAndCreateDirectory(mark1Path, &directoryAlreadyExist);
    
    CLOAD_LOG("[DIR] create %s", CLOAD_PATH(mark1Path));
    
    if(!flag) {
        CLOAD_LOG("[SafeGuard] prevent crash load launching, failed to create "
                  "mark1 directory at %s", CLOAD_PATH(mark1Path));
        DEBUG_RETURN(false);
    }
    
    DEVELOP_DEBUG_ASSERT(!directoryAlreadyExist);
    
    if(!directoryAlreadyExist) {
        CLOAD_LOG("[SafeGuard] permit crash load launching, mark1 not found at "
                  "path %s", CLOAD_PATH(mark1Path));
        return true;
    }
    
    CLOAD_LOG("[SafeGuard] warning, mark1 exist at path %s, crash load launch "
              "may have some problem, fetching mark2", CLOAD_PATH(mark1Path));
    
    NSString *mark2Path = joinPath(directory, safeGuardMark2);
    
    directoryAlreadyExist = NO;
    flag = checkAndCreateDirectory(mark2Path, &directoryAlreadyExist);
    
    CLOAD_LOG("[DIR] create %s", CLOAD_PATH(mark2Path));
    
    if(!flag) {
        CLOAD_LOG("[SafeGuard] prevent crash load launching, failed to create "
                  "mark2 directory at %s", CLOAD_PATH(mark2Path));
        DEBUG_RETURN(false);
    }
    
    DEVELOP_DEBUG_ASSERT(!directoryAlreadyExist);
    
    if(!directoryAlreadyExist) {
        CLOAD_LOG("[SafeGuard] permit crash load launching, mark2 not found at "
                  "path %s", CLOAD_PATH(mark2Path));
        return true;
    }
    
    CLOAD_LOG("[SafeGuard] prevent crash load launching, mark1 and mark2 exist "
              "path path %s %s", CLOAD_PATH(mark1Path), CLOAD_PATH(mark2Path));
    
    DEVELOP_DEBUG_RETURN(false);
}

#pragma mark - Prepare Routine

static void HMDCrashLoadLaunch_prepare(HMDCLoadContext * context) {
    DEBUG_ASSERT(context != NULL);
        
    HMDCLoadOptionRef option = context.option;
    
    PROFILE_TIME(prepare.beginTime);
    
    CLOAD_LOG("[Progress] prepare begin");
    
    HMDCrashLoadLaunch_prepare_markStarting(context);
    
    HMDCrashLoadLaunch_prepare_fileManager(context);
    
    HMDCrashLoadLaunch_prepare_raiseFDLimit(context);

    CLOAD_LOG("[Progress] prepare end");
    
    PROFILE_TIME(prepare.endTime);
}

static void HMDCrashLoadLaunch_prepare_markStarting(HMDCLoadContext * context) {
    CLOAD_LOG("[Sync] mark load launch starting");
    
    HMDCrashLoadSync_setStarting(true);
}

static void HMDCrashLoadLaunch_prepare_fileManager(HMDCLoadContext * context) {
    
    context.manager = NSFileManager.defaultManager;
}

static void HMDCrashLoadLaunch_prepare_raiseFDLimit(HMDCLoadContext * context) {
    #define HMD_CLOAD_RAISE_FD_COUNT UINT64_C(4096)
    
    rlim_t raiseTo = HMD_CLOAD_RAISE_FD_COUNT;
    
    struct rlimit limit = {0};
    int ret = getrlimit(RLIMIT_NOFILE, &limit);
    if(ret != 0) DEBUG_RETURN_NONE;
    
    rlim_t currentLimit = limit.rlim_cur;
    
    if(currentLimit >= raiseTo) {
        CLOAD_LOG("[FD] current limit is %" PRIu64 ", which is larger than %"
                  PRIu64 ", no need to raise FD", currentLimit, raiseTo);
        return;
    }
    
    if(limit.rlim_max < raiseTo) {
        CLOAD_LOG("[FD] max limit is %#" PRIX64 ", which is less than raise to %"
                  PRIu64 ", unable to raise FD", limit.rlim_max, raiseTo);
        DEBUG_RETURN_NONE;
    }
    
    limit.rlim_cur = raiseTo;
    
    ret = setrlimit(RLIMIT_NOFILE, &limit);
    
    if(ret != 0) {
        CLOAD_LOG("[FD] failed to raise limit to %" PRIu64 ", max limit is "
                  "%#" PRIX64 ", errno is %d", raiseTo, limit.rlim_max, errno);
        DEBUG_RETURN_NONE;
    }
    
    CLOAD_LOG("[FD] successfully upgrade limit from %" PRIu64 " to %" PRIu64 ", "
              "max limit is %#" PRIX64, currentLimit, raiseTo, limit.rlim_max);
}

#pragma mark - Directory Routine

static void HMDCrashLoadLaunch_directory(HMDCLoadContext * context) {
    /* (1) 构建文件夹层级
            CrashCapture/
                Active/             上次 App 崩溃数据, 以及本次初始化崩溃地方
                LastTime/           如果没有发生崩溃，留给 BinaryImage 缓存地方
                Processing/         丢给 CrashTracker 处理的正常崩溃地方
                LoadLaunch/
                    SafeGuard/      用于判断是否模块启动成功 ( SafeGuard Routine
                    Pending/        Load 阶段崩溃缓存
                    Processing/     确定要进行上报的 Load 崩溃处理地方
                    Prepared/       准备好 Load 阶段上传的地方
                    Mirror/         存储 UID DID 缓存的地方
     
       (2) 具体操作
            1. LoadLaunch/Processing 存在数据 ✅
                (1) 如果没有启用选项 dropCrashIfProcessFailed 这事情与我无关
                (2) 不存在 markDrop 文件, 放置 markDrop 标记
                (3) 若存在 markDrop 文件, 标记 Load 处理失败
                (4) 若存在 markDrop 文件, 清空 LoadLaunch/Processing 内部文件
            2. Processing 文件夹存在数据 ✅
                (1) 如果没有启用选项 crashTrackerProcessFailed 这事情与我无关
                (2) 不存在 markFailed 文件, 放置 markFailed 标记
                (3) 若存在 markFailed 文件, 标记 CrashTracker 处理失败
                (3) 若存在 markFailed 文件, 移动到 LoadLaunch/Processing
            3. LoadLaunch/Pending 文件夹存在数据 ✅
                (1) 发生连续 Load 崩溃
                (2) 标记 pendingCrashExist
            4. 清空 LastTime 文件夹数据 ✅
            5. Active 文件夹 ✅
                (1) 若不存在 exception 文件 => 移动到 LastTime
                (2) 存在 exception 文件 => 上次发生崩溃咯
                (3) 不存在 meta 文件 => 上次发生 Load 阶段崩溃
                (4) 将非 Load 崩溃的普通日志移动到 Processing
                (5) 若不存在 meta 文件，移动日志到 LoadLaunch/Pending
                (6) 如果没有启用选项 keepLoadCrash，移动日志到 LoadLaunch/Pending
                (7) 移动日志到 LoadLaunch/Processing
                (8) 如果启用 keepLoadCrashIncludePreviousCrashCount 选项
                    那么移动该数量的崩溃日志到 LoadLaunch/Processing
            6. LoadLaunch/Prepared 创建文件夹 ✅
            7. Active/CurrentDirectory 创建 Current Directory ✅
            8. LoadLaunch/Mirror ✅
                (1) 如果未启用 userProfile.enableMirror 清空文件夹数据并返回
     
        (3) Tracker 响应
     
            1. Prepared 无变动
            2. Processing 无变动
            3. Eventlog 无变动
            4.
     */
    
    DEBUG_ASSERT(context != NULL);
    
    HMDCLoadOptionRef option = context.option;
    
    PROFILE_TIME(directory.beginTime);
    
    CLOAD_LOG("[Progress] directory begin");
    
    // 基础路径
    NSString *crashDirectory = @"Library/Heimdallr/CrashCapture";
    NSString *baseDirectory  = joinPath(NSHomeDirectory(), crashDirectory);
    NSString *loadDirectory  = joinPath(baseDirectory, @"LoadLaunch");
    
    context.trackerProcessing = joinPath(baseDirectory, @"Processing");
    context.trackerLastTime   = joinPath(baseDirectory, @"LastTime");
    context.trackerActive     = joinPath(baseDirectory, @"Active");
    
    context.loadSafeGuard  = joinPath(loadDirectory, @"SafeGuard");
    context.loadProcessing = joinPath(loadDirectory, @"Processing");
    context.loadPrepared   = joinPath(loadDirectory, @"Prepared");
    context.loadPending    = joinPath(loadDirectory, @"Pending");
    context.loadMirror     = joinPath(loadDirectory, @"Mirror");
    
    // LoadLaunch/Processing
    HMDCrashLoadLaunch_directory_loadProcessing(context);
    
    // Processing
    HMDCrashLoadLaunch_directory_trackerProcessing(context);
    
    // LoadLaunch/Pending
    HMDCrashLoadLaunch_directory_loadPending(context);
    
    // LastTime
    HMDCrashLoadLaunch_directory_trackerLastTime(context);
    
    // Active
    HMDCrashLoadLaunch_directory_trackerActive(context);

    // LoadLaunch/Prepared
    HMDCrashLoadLaunch_directory_loadPrepared(context);
    
    // Active/CurrentDirectory
    HMDCrashLoadLaunch_directory_currentDirectory(context);
    
    // LoadLaunch/Mirror
    HMDCrashLoadLaunch_directory_loadMirror(context);
    
    CLOAD_LOG("[Progress] directory end");
    
    PROFILE_TIME(directory.endTime);
}

static void HMDCrashLoadLaunch_directory_loadProcessing(HMDCLoadContext * context) {
    
    HMDCLoadOptionRef option = context.option;
    NSString *loadProcessing = context.loadProcessing;
    NSFileManager *manager = context.manager;
    
    DEBUG_ASSERT(option != NULL && loadProcessing != nil);
    DEBUG_ASSERT(manager != nil);
    
    BOOL directoryAlreadyExist = NO;
    checkAndCreateDirectory(loadProcessing, &directoryAlreadyExist);
    
    CLOAD_LOG("[DIR] create %s", CLOAD_PATH(loadProcessing));
    
    if(!option->directoryOption.dropCrashIfProcessFailed) {
        CLOAD_LOG("[OPTION] directoryOption.dropCrashIfProcessFailed disabled");
        return;
    }
    
    if(unlikely(!directoryAlreadyExist)) return;
    
    NSArray<NSString *> *contents = dirContent(loadProcessing);
    
    for(NSString *eachContent in contents) {
        NSString *contentPath = joinPath(loadProcessing, eachContent);
        
        BOOL isDirectory = NO;
        BOOL isExist = [manager fileExistsAtPath:contentPath
                                     isDirectory:&isDirectory];
        
        DEBUG_ASSERT(isExist && isDirectory);
        
        if(unlikely(!isExist)) continue;
        
        if(unlikely(!isDirectory)) {
            CLOAD_LOG("[DIR] delete %s, this should be directory not file, "
                      "delete file to correct error", CLOAD_PATH(contentPath));
            [manager removeItemAtPath:contentPath error:nil];
            continue;
        }
        
        NSString *markDropPath = joinPath(contentPath, @"markDrop");
        
        isExist = [manager fileExistsAtPath:markDropPath
                                isDirectory:&isDirectory];
        
        DEBUG_ASSERT(!isExist || !isDirectory);
        
        if(isExist && isDirectory) {
            CLOAD_LOG("[DIR] delete %s, found markDrop directory which should be "
                      "file, delete directory to correct this error",
                      CLOAD_PATH(markDropPath));
            
            [manager removeItemAtPath:markDropPath error:nil];
            isExist = NO;
        }
        
        if(!isExist) {
            CLOAD_LOG("create markDrop file at %s, mark to drop this whole "
                      "directory if second time see the markDrop file",
                      CLOAD_PATH(markDropPath));
            
            [manager createFileAtPath:markDropPath
                             contents:nil
                           attributes:nil];
            continue;
        }
        
        CLOAD_LOG("[DIR] delete %s, markDrop file found, delete the whole "
                  "directory as load process continue failed",
                  CLOAD_PATH(contentPath));
        
        [manager removeItemAtPath:contentPath error:nil];
    }
}

static void HMDCrashLoadLaunch_directory_trackerProcessing(HMDCLoadContext * context) {
    
    HMDCLoadOptionRef option = context.option;
    NSString *trackerProcessing = context.trackerProcessing;
    NSString *loadProcessing = context.loadProcessing;
    NSFileManager *manager = context.manager;
    
    DEBUG_ASSERT(option != NULL && trackerProcessing != nil);
    DEBUG_ASSERT(loadProcessing != NULL && manager != nil);
    
    BOOL directoryAlreadyExist = NO;
    checkAndCreateDirectory(trackerProcessing, &directoryAlreadyExist);
    
    CLOAD_LOG("[DIR] create %s", CLOAD_PATH(trackerProcessing));
    
    if(!option->uploadOption.crashTrackerProcessFailed) {
        CLOAD_LOG("[OPTION] uploadOption.crashTrackerProcessFailed disabled");
        return;
    }
    
    if(unlikely(!directoryAlreadyExist)) return;
    
    NSArray<NSString *> *contents = dirContent(trackerProcessing);
    
    for(NSString *eachContent in contents) {
        NSString *contentPath = joinPath(trackerProcessing, eachContent);
        
        BOOL isDirectory = NO;
        BOOL isExist = [manager fileExistsAtPath:contentPath
                                     isDirectory:&isDirectory];
        
        DEBUG_ASSERT(isExist && isDirectory);
        
        if(unlikely(!isExist)) continue;
        
        if(unlikely(!isDirectory)) {
            CLOAD_LOG("[DIR] delete %s, this should be directory not file, "
                      "delete file to correct error", CLOAD_PATH(contentPath));
            [manager removeItemAtPath:contentPath error:nil];
            continue;
        }
        
        NSString *markFailedPath = joinPath(contentPath, @"markFailed");
        
        isExist = [manager fileExistsAtPath:markFailedPath
                                isDirectory:&isDirectory];
        
        DEBUG_ASSERT(!isExist || !isDirectory);
        
        if(isExist && isDirectory) {
            CLOAD_LOG("[DIR] delete %s, found markFailed directory which should "
                      "be file, delete directory to correct this error",
                      CLOAD_PATH(markFailedPath));
            
            [manager removeItemAtPath:markFailedPath error:nil];
            isExist = NO;
        }
        
        if(!isExist) {
            CLOAD_LOG("create markFailed file at %s, will try to move the "
                      "whole directory if second time see the markFailed file",
                      CLOAD_PATH(markFailedPath));
            
            [manager createFileAtPath:markFailedPath
                             contents:nil
                           attributes:nil];
            continue;
        }
        
        NSString *moveToPath = joinPath(loadProcessing, eachContent);
        
        [manager moveItemAtPath:contentPath
                         toPath:moveToPath
                          error:nil];
        
        CLOAD_LOG("[DIR] move %s to %s, will try to upload crash log, because "
                  "tracker process failed", CLOAD_PATH(contentPath),
                  CLOAD_PATH(moveToPath));
        
        option->failureStatus.moveTrackerProcessFailedCount += 1;
    }
}

static void HMDCrashLoadLaunch_directory_loadPending(HMDCLoadContext * context) {
    
    HMDCLoadOptionRef option = context.option;
    NSString *loadPending = context.loadPending;
    // NSFileManager *manager = context.manager;
    
    DEBUG_ASSERT(option != NULL && loadPending != nil);
    // DEBUG_ASSERT(manager != nil);
    
    BOOL directoryAlreadyExist = NO;
    checkAndCreateDirectory(loadPending, &directoryAlreadyExist);
    
    if(unlikely(!directoryAlreadyExist)) return;
    
    NSArray<NSString *> *pendingContents = dirContent(loadPending);
    
    if(likely(pendingContents.count == 0)) return;
    
    option->urgentStatus.pendingCrashExist = true;
}

static void HMDCrashLoadLaunch_directory_trackerLastTime(HMDCLoadContext * context) {
    NSString *trackerLastTime = context.trackerLastTime;
    NSFileManager *manager = context.manager;
    
    DEBUG_ASSERT(trackerLastTime != nil && manager != nil);
    
    BOOL directoryAlreadyExist = NO;
    checkAndCreateDirectory(trackerLastTime, &directoryAlreadyExist);
    
    CLOAD_LOG("[DIR] create %s", CLOAD_PATH(trackerLastTime));
    
    if(unlikely(!directoryAlreadyExist)) return;
    
    NSArray *lastTimeContents = dirContent(trackerLastTime);
    
    for(NSString *content in lastTimeContents) {
        NSString *contentPath = joinPath(trackerLastTime, content);
        [manager removeItemAtPath:contentPath error:nil];
        
        CLOAD_LOG("[DIR] delete %s, lastTime content", CLOAD_PATH(contentPath));
    }
}

static void HMDCrashLoadLaunch_directory_trackerActive(HMDCLoadContext * context) {
    
    HMDCLoadOptionRef option    = context.option;
    NSString *trackerActive     = context.trackerActive;
    NSString *trackerLastTime   = context.trackerLastTime;
    NSString *loadPending       = context.loadPending;
    NSString *trackerProcessing = context.trackerProcessing;
    NSString *loadProcessing    = context.loadProcessing;
    NSFileManager *manager      = context.manager;
    
    DEBUG_ASSERT(option != NULL && trackerActive != nil);
    DEBUG_ASSERT(trackerLastTime != nil && loadPending != nil);
    DEBUG_ASSERT(trackerProcessing != nil && loadProcessing != nil);
    DEBUG_ASSERT(manager != nil);
    
    BOOL mayNeedPreviousPendingCrash = NO;
    
    BOOL directoryAlreadyExist = NO;
    checkAndCreateDirectory(trackerActive, &directoryAlreadyExist);
    
    if(unlikely(!directoryAlreadyExist)) return;
    
    NSArray<NSString *> *activeContents = dirContent(trackerActive);
    
    for(NSString *content in activeContents) {
        NSString *contentPath = joinPath(trackerActive, content);
        
        BOOL isDirectory = NO;
        BOOL isExist = [manager fileExistsAtPath:contentPath
                                     isDirectory:&isDirectory];
        
        DEBUG_ASSERT(isExist && isDirectory);
        
        if(unlikely(!isExist)) continue;
        
        if(unlikely(!isDirectory)) {
            CLOAD_LOG("[DIR] delete %s, this should be directory not file, "
                      "delete file to correct error", CLOAD_PATH(contentPath));
            [manager removeItemAtPath:contentPath error:nil];
            continue;
        }
        
        NSString *exceptionPath = joinPath(contentPath, @"exception");
        
        isExist = [manager fileExistsAtPath:exceptionPath
                                isDirectory:&isDirectory];
        
        DEBUG_ASSERT(!isExist || (isExist && !isDirectory));
        
        if(likely(!isExist) || unlikely(isDirectory)) {
            NSString *movePath = joinPath(trackerLastTime, content);
            
            CLOAD_LOG("[DIR] move %s to %s, crash not happened lastTime",
                      CLOAD_PATH(contentPath), CLOAD_PATH(movePath));
            
            [manager moveItemAtPath:contentPath
                             toPath:movePath
                              error:nil];
            continue;
        }
        
        option->urgentStatus.lastTimeCrash = true;
        
        NSString *metaPath = joinPath(contentPath, @"meta");
        
        isExist = [manager fileExistsAtPath:metaPath isDirectory:&isDirectory];
        
        if(isExist) {
            NSString *movePath = joinPath(trackerProcessing, content);
            
            CLOAD_LOG("[DIR] move %s to %s, found meta file, last time crash is "
                      "not load crash, move to tracker processing",
                      CLOAD_PATH(contentPath), CLOAD_PATH(movePath));
            
            [manager moveItemAtPath:contentPath
                             toPath:movePath
                              error:nil];
            continue;
        }
        
        option->urgentStatus.lastTimeLoadCrash = true;
        
        CLOAD_LOG("lastTime crash is confirmed to be load crash");
        
        if(!option->urgentStatus.pendingCrashExist) {
            
            NSString *movePath = joinPath(loadPending, content);
            
            CLOAD_LOG("[DIR] move %s to %s, pending load crash not exist, will "
                      "move load crash to pending, expect tracker process "
                      "it", CLOAD_PATH(contentPath), CLOAD_PATH(movePath));
            
            [manager moveItemAtPath:contentPath
                             toPath:movePath
                              error:nil];
            
            continue;
        }
        
        if(!option->uploadOption.keepLoadCrash) {
            
            NSString *movePath = joinPath(loadPending, content);
            
            CLOAD_LOG("[OPTION] uploadOption.keepLoadCrash disabled");
            
            CLOAD_LOG("[DIR] move %s to %s, pending crash exist, but option "
                      "uploadOption.keepLoadCrash disabled, move to pending ",
                      CLOAD_PATH(contentPath), CLOAD_PATH(movePath));
            
            [manager moveItemAtPath:contentPath
                             toPath:movePath
                              error:nil];
            
            continue;
        }
        
        NSString *movePath = joinPath(loadProcessing, content);
        
        CLOAD_LOG("[DIR] move %s to %s, keep load crash found, will move crash "
                  "log to load upload processing", CLOAD_PATH(contentPath),
                  CLOAD_PATH(movePath));
        
        [manager moveItemAtPath:contentPath
                         toPath:movePath
                          error:nil];
        
        mayNeedPreviousPendingCrash = YES;
    }
    
    if(!mayNeedPreviousPendingCrash) return;
    
    uint32_t maxPreviousCount =
        option->uploadOption.keepLoadCrashIncludePreviousCrashCount;
    
    if(maxPreviousCount == 0) return;
    
    NSArray<NSString *> *loadPendingContents = dirContent(loadPending);
    
    DEBUG_ASSERT(loadPendingContents.count > 0);
    
    uint32_t previousIndex = 0;
    
    for(NSString *content in loadPendingContents) {
        NSString *contentPath = joinPath(loadPending, content);
        NSString *movePath = joinPath(loadProcessing, content);
        
        CLOAD_LOG("[DIR] move %s to %s, keep load crash found, will move pending "
                  "crash to load processing, current index %" PRIu32 ", max "
                  "include count %" PRIu32, CLOAD_PATH(contentPath),
                  CLOAD_PATH(movePath), previousIndex, maxPreviousCount);
        
        [manager moveItemAtPath:contentPath
                         toPath:movePath
                          error:nil];
        
        if(previousIndex + 1 >= maxPreviousCount)
            break;
        
        previousIndex += 1;
    }
}

static void HMDCrashLoadLaunch_directory_loadPrepared(HMDCLoadContext * context) {
    NSString *loadPrepared = context.loadPrepared;
    DEBUG_ASSERT(loadPrepared != nil);
    
    checkAndCreateDirectory(loadPrepared, NULL);
    
    CLOAD_LOG("[DIR] create %s", CLOAD_PATH(loadPrepared));
}

static void HMDCrashLoadLaunch_directory_currentDirectory(HMDCLoadContext * context) {
    NSString *trackerActive = context.trackerActive;
    DEBUG_ASSERT(trackerActive != nil);
    
    NSString *folderName = NSUUID.UUID.UUIDString;
    if(folderName.length == 0) {
        folderName = [NSString stringWithFormat:@"%" PRIu32 , arc4random()];
    }
    
    // Assume current active folder is empty
    DEBUG_ASSERT(dirContent(trackerActive).count == 0);
    
    // Create current directory
    
    NSString *currentPath =
        [trackerActive stringByAppendingPathComponent:folderName];
    
    checkAndCreateDirectory(currentPath, NULL);
    
    CLOAD_LOG("[DIR] create %s", CLOAD_PATH(currentPath));
    
    context.currentDirectory = currentPath;
    
    // Expect exception file path
    
    NSString *exceptionFilePath =
        [currentPath stringByAppendingPathComponent:@"exception"];
    
    HMDCrashDirectory_setExceptionPath(exceptionFilePath.UTF8String);
}

static void HMDCrashLoadLaunch_directory_loadMirror(HMDCLoadContext * context) {
    // HMDCLoadOptionRef option = context.option;
    NSString *loadMirror = context.loadMirror;
    // NSFileManager *manager = context.manager;
    
    DEBUG_ASSERT(loadMirror != nil);
    
    BOOL directoryAlreadyExist = NO;
    checkAndCreateDirectory(loadMirror, &directoryAlreadyExist);
}

#pragma mark - Environment routine


static void HMDCrashLoadLaunch_environment(HMDCLoadContext * context) {
    DEBUG_ASSERT(context != NULL);
        
    HMDCLoadOptionRef option = context.option;
    
    PROFILE_TIME(environment.beginTime);
    
    CLOAD_LOG("[Progress] environment begin");
    
    HMDCrashLoadLaunch_environment_binaryImage(context);

    CLOAD_LOG("[Progress] environment end");
    
    PROFILE_TIME(environment.endTime);
}

static void HMDCrashLoadLaunch_environment_binaryImage(HMDCLoadContext * context) {
    NSString *currentDirectory = context.currentDirectory;
    DEBUG_ASSERT(currentDirectory != nil);
    
    // Binary Image
    HMDCrashEnvironmentBinaryImages_initWithDirectory(currentDirectory);
    
    // Real Time
    HMDCrashEnvironmentBinaryImages_prepare_for_realTimeFile();
}

#pragma mark - Detection routine

static void HMDCrashLoadLaunch_detection(HMDCLoadContext * context) {
    
    DEBUG_ASSERT(context != NULL);
        
    HMDCLoadOptionRef option = context.option;
    
    PROFILE_TIME(detection.beginTime);
    
    CLOAD_LOG("[Progress] detection begin");
    
    // Start detection
    HMDCrashStartDetect();

    CLOAD_LOG("[Progress] detection end");
    
    PROFILE_TIME(detection.endTime);
}

#pragma mark - Processing routine

static void HMDCrashLoadLaunch_process(HMDCLoadContext * context) {
    
    DEBUG_ASSERT(context != NULL);
        
    HMDCLoadOptionRef option = context.option;
    
    PROFILE_TIME(process.beginTime);
    
    CLOAD_LOG("[Progress] process begin");
    
    HMDCrashLoadLaunch_process_internal(context);
    
    CLOAD_LOG("[Progress] process end");
    
    PROFILE_TIME(process.endTime);
}

static void HMDCrashLoadLaunch_process_internal(HMDCLoadContext * context) {
    
    NSString *loadProcessing = context.loadProcessing;
    NSFileManager *manager = context.manager;
    
    DEBUG_ASSERT(loadProcessing != nil && manager != nil);
    
    NSArray<NSString *> *contents = dirContent(loadProcessing);
    
    if(contents.count == 0) {
        CLOAD_LOG("[Process] ignored, nothing exist at processing "
                  "directory %s", CLOAD_PATH(loadProcessing));
        return;
    }
    
    HMDCrashLoadLaunch_process_triggerPrepareMeta(context);
    
    HMDCrashLoadMeta *meta = context.meta;
    
    if(meta == nil || meta.appID == nil) {
        CLOAD_LOG("failed to start processing, meta or appID is missing");
        return;
    }
    
    for(NSString *eachContent in contents) {
        NSString *contentPath = joinPath(loadProcessing, eachContent);
        
        BOOL isDirectory = NO;
        BOOL isExist = [manager fileExistsAtPath:contentPath
                                     isDirectory:&isDirectory];
        
        if(unlikely(!isExist)) continue;
        
        if(unlikely(!isDirectory)) {
            CLOAD_LOG("[DIR] delete %s, this should be directory not file, "
                      "delete file to correct error", CLOAD_PATH(contentPath));
            [manager removeItemAtPath:contentPath error:nil];
            continue;
        }
        
        context.processPath = contentPath;
        context.processUUID = eachContent;
        
        HMDCrashLoadLaunch_process_eachContent(context);
        
        DEBUG_ASSERT(context.model.successFlag);
        
        CLOAD_LOG("%s to process crash UUID %s",
                  context.model.successFlag ? "succeeded" : "failed",
                  context.processUUID.UTF8String);
        
        CLOAD_LOG("[DIR] delete %s, after process crash log",
                  CLOAD_PATH(contentPath));
        
        [manager removeItemAtPath:contentPath error:nil];
    }
}

static void HMDCrashLoadLaunch_process_triggerPrepareMeta(HMDCLoadContext * context) {
    DEBUG_ASSERT(context.meta == nil);
    
    CLOAD_LOG("prepare crash meta for processing crash log");
    
    HMDCrashLoadLaunch_prepareMeta(context);
}

static void HMDCrashLoadLaunch_process_eachContent(HMDCLoadContext * context) {
    
    HMDCrashLoadLaunch_process_loadContent(context);
    
    HMDCrashLoadLaunch_process_formatCrashLog(context);
    
    HMDCrashLoadLaunch_process_dataDictionary(context);
    
    HMDCrashLoadLaunch_process_multipartData(context);
    
    HMDCrashLoadLaunch_process_gzipData(context);
    
    HMDCrashLoadLaunch_process_outputData(context);
    
    HMDCrashLoadLaunch_process_report(context);
}

static void HMDCrashLoadLaunch_process_loadContent(HMDCLoadContext * context) {
    HMDCrashLoadModel *model = HMDCrashLoadModel.model;
    context.model = model;
    
    if(model == nil) DEBUG_RETURN_NONE;
    
    NSString *processPath = context.processPath;
    DEBUG_ASSERT(processPath != nil);
    
    // Binary Image
    
    HMDImageOpaqueLoader *imageLoader =
        [[HMDImageOpaqueLoader alloc] initWithDirectory:processPath];
    model.imageLoader = imageLoader;
    
    // Exception File
    
    NSString *exceptionFilePath = joinPath(processPath, @"exception");
    NSArray<NSString *> * _Nullable lines = linesOfFile(exceptionFilePath);
    
    for(NSString *eachLine in lines) {
        DEBUG_ASSERT(eachLine.length != 0 || eachLine == lines.lastObject);
        
        if(eachLine.length == 0) continue;
        
        NSData *lineData = [eachLine dataUsingEncoding:NSUTF8StringEncoding];
        
        if(unlikely(lineData == nil)) DEBUG_CONTINUE;
        
        NSDictionary * _Nullable eachLineDict = JSONDataToDictionary(lineData);
        
        DEBUG_ASSERT(eachLineDict != nil || eachLine == lines.lastObject);
        
        if(unlikely(eachLineDict == nil)) continue;
        
        NSDictionary * _Nullable dictContent;
        NSArray * _Nullable arrayContent;
        
        if((dictContent = [eachLineDict hmd_dictForKey:@"exception"]) != nil) {
            model.headerInfo =
                [HMDCrashHeaderInfo objectWithDictionary:dictContent];
            continue;
        }
        
        if((arrayContent = [eachLineDict hmd_arrayForKey:@"threads"]) != nil) {
            model.threads =
                [HMDCrashThreadInfo objectsWithDicts:arrayContent];
            continue;
        }
        
        if((dictContent = [eachLineDict hmd_dictForKey:@"stack_record"]) != nil) {
            model.asyncRecord =
                [HMDCrashThreadInfo objectWithDictionary:dictContent];
            
            // thread names should is recorded in async stack trace
            // the content of async stack trace is the same as normal thread
            // except for the thread name key
            model.asyncRecord.threadName = [eachLineDict hmd_stringForKey:@"thread_name"];
            continue;
        }
        
        if((arrayContent = [eachLineDict hmd_arrayForKey:@"dispatch_name"]) != nil) {
            model.queueNames = arrayContent;
            continue;
        }
        
        if((arrayContent = [eachLineDict hmd_arrayForKey:@"pthread_name"]) != nil) {
            model.threadNames = arrayContent;
            continue;
        }
    }
    
    // For each thread
    for(HMDCrashThreadInfo *eachThread in model.threads) {
        [eachThread generateFrames:imageLoader];
    }
    
    // For async stack stack record trace
    [model.asyncRecord generateFrames:imageLoader];
    
    // Fix crashTime
    if(model.headerInfo.crashTime == 0) {
       model.headerInfo.crashTime = HMD_XNUSystemCall_timeSince1970();
    }
}

static void HMDCrashLoadLaunch_process_formatCrashLog(HMDCLoadContext * context) {
    // Incident Identifier: %@              UUID
    // CrashReporter Key:   temporary       
    // Hardware Model:      %@              deviceModel
    // @Process:            %@ [%u]         processName, processID
    // Path:                %@"             homeDirectory
    // Identifier:          %@              bundleID
    // Version:             %@              appVersion(bundleVersion)
    //
    // Code Type:           %@              arch
    // Parent Process:      [launchd]
    // OS Version:          %@              osFullVersion
    //
    // Report Version:      104
    // Date/Time:           %@              yyyy-MM-dd HH:mm:ss Z
    // Launch Time:         %@              yyyy-MM-dd HH:mm:ss Z
    // commit:              %@              commitID
    // Heimdallr_Crash_Log
    //
    // crashTypeString %@                   headerInfo.typeStr
    // exception %@                         headerInfo.name
    // reason %@                            headerInfo.reason
    // fault_address: 0x%016llx             headerInfo.faultAddr
    // mach_codes: 0x%016llx 0x%016llx      headerInfo.mach_code/mach_subcode
    // sig_num: %d                          headerInfo.signum
    // sig_code: %d                         headerInfo.sigcode
    
    HMDCrashLoadMeta  *meta  = context.meta;
    HMDCrashLoadModel *model = context.model;
    
    if(model == nil || meta == nil)
        DEBUG_RETURN_NONE;
    
    NSString *UUID = context.processUUID;
    if(UUID == nil) {
        UUID = NSUUID.UUID.UUIDString;
        context.processUUID = UUID;
    }
    
    NSString *OSBuildVersion = meta.OSBuildVersion;
    NSString *processName    = meta.processName;
    unsigned int processID   = meta.processID;
    NSString *OSVersion      = meta.OSVersion;
    
#if TARGET_OS_IOS
    NSString *OSFullVersion = [NSString stringWithFormat:@"iOS %@ (%@)",
                               OSVersion, OSBuildVersion];
#else
#error target is not iOS, what should this be ?
#endif
    
    NSString *deviceModel = meta.deviceModel;
    
    NSString *homeDirectory = NSHomeDirectory();
    
    NSString *bundleID = meta.bundleID;
    
    // AppVersion
    NSString *shortVersion =meta.bundleShortVersion;
    
    NSString *bundleVersion = meta.bundleVersion;
    
    NSString *version = [NSString stringWithFormat:@"%@(%@)",
                        shortVersion, bundleVersion];
    
    NSString *codeType = meta.codeType;
    
    HMDCrashHeaderInfo *headerInfo = model.headerInfo;
    
    NSDate *crashDate =
        [NSDate dateWithTimeIntervalSince1970:headerInfo.crashTime];
    
    NSDateFormatter *formatter = NSDateFormatter.new;
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
    
    NSString *crashTimeString = [formatter stringFromDate:crashDate];
    
    // We don't know about crash, but this is a launch crash
    NSString *launchTimeString = crashTimeString;
    
    NSString *commitID = @"";
    
    NSString * _Nullable maybeCommitID = commitIDToString();
    if(maybeCommitID != nil) commitID = maybeCommitID;
    
    NSString *crashTypeString = headerInfo.typeStr;
    NSString *exception       = headerInfo.name;
    NSString *reason          = headerInfo.reason;
    uint64_t faultAddress     = headerInfo.faultAddr;
    int sigNum                = headerInfo.signum;
    int sigCode               = headerInfo.sigcode;
    int64_t machCode          = headerInfo.mach_code;
    int64_t machSubCode       = headerInfo.mach_subcode;
    
    NSMutableString *crashLog = [NSMutableString stringWithFormat:
    @"Incident Identifier: %@"                                       "\n"
     "CrashReporter Key:   temporary"                                "\n"
     "Hardware Model:      %@"                                       "\n"
     "@Process:            %@ [%u]"                                  "\n"
     "Path:                %@"                                       "\n"
     "Identifier:          %@"                                       "\n"
     "Version:             %@"                                       "\n"
                                                                     "\n"
     "Code Type:           %@"                                       "\n"
     "Parent Process:      [launchd]"                                "\n"
     "OS Version:          %@"                                       "\n"
                                                                     "\n"
     "Report Version:      104"                                      "\n"
     "Date/Time:           %@"                                       "\n"
     "Launch Time:         %@"                                       "\n"
     "commit:              %@"                                       "\n"
     "Heimdallr_Crash_Log"                                           "\n"
                                                                     "\n"
     "crashTypeString %@"                                            "\n"
     "exception %@"                                                  "\n"
     "reason %@"                                                     "\n"
     "fault_address: 0x%016llx"                                      "\n"
     "mach_codes: 0x%016llx 0x%016llx"                               "\n"
     "sig_num: %d"                                                   "\n"
     "sig_code: %d"                                                  "\n\n",
      UUID, deviceModel, processName, processID, homeDirectory,
      bundleID, version, codeType, OSFullVersion, crashTimeString,
      launchTimeString, commitID, crashTypeString, exception, reason,
      faultAddress, machCode, machSubCode, sigNum, sigCode];
    
    BOOL foundCrashThread = NO;
    
    unsigned int threadIndex = 0;
    
    for(HMDCrashThreadInfo * eachThread in model.threads) {
        
        if(!foundCrashThread)
            foundCrashThread = eachThread.crashed;
        
        NSString *eachName = threadNameForThread(context, eachThread, threadIndex);
        NSString *eachTrace = stackTraceForThread(context, eachThread);
        
        if(eachName.length == 0) eachName = @"";
        if(eachTrace.length == 0) eachTrace = @"";
        
        [crashLog appendFormat:@"%@%@\n\n", eachName, eachTrace];
        
        threadIndex += 1;
    }
    
    if(!foundCrashThread) {
        NSString *emptyCrashTrace =
        @"Thread 1000 name:  null\n"
         "Thread Crashed:\n"
         "0 NULL 0x0 0x012345 + 0 ((null)) + 0)";
        [crashLog appendFormat:@"%@\n\n", emptyCrashTrace];
    }
    
    NSArray<HMDCrashBinaryImage *> *binaryImages =
        model.imageLoader.currentlyUsedImages;
    
    [crashLog appendString:@"Binary Images:\n"];
    
    for(HMDCrashBinaryImage *eachBinaryImage in binaryImages) {
        
        BOOL    isMainImage = eachBinaryImage.isMain;
        uint64_t  imageBase = eachBinaryImage.base;
        uint64_t  imageSize = eachBinaryImage.size;
        NSString *imageName = eachBinaryImage.name;
        NSString *imageArch = eachBinaryImage.arch;
        NSString *imageUUID = eachBinaryImage.uuid;
        NSString *imagePath = eachBinaryImage.path;
        
        uint64_t imageLast = imageBase + imageSize - 1;
        
        NSString *mainImageMark = isMainImage ? @"+" : @"";
        
        NSString *eachImageContent =
            [NSString stringWithFormat:@"%#18llx - %#18llx %@%@ %@ <%@> %@\n",
             imageBase, imageLast, mainImageMark, imageName,
             imageArch, imageUUID, imagePath];
        
        if(eachImageContent != nil)
            [crashLog appendString:eachImageContent];
    }
    
    if(!meta.envAbnormal) {
        meta.envAbnormal = model.imageLoader.envAbnormal;
    }
    
    if(binaryImages.count == 0) {
        [crashLog appendString:
         @"0x000 - 0x001 +HMDPlaceHolderImage arm64 <uuid> "
          "/Bundle/Application/HMDPlaceHolderImage.app\n"];
    }
    
    model.crashLog = crashLog;
}

static void HMDCrashLoadLaunch_process_dataDictionary(HMDCLoadContext * context) {
    // "timestamp"                  (n)crashTime    timeIntervalSince1970 * 1000
    // "data"                       "crashLog"
    // "session_id"                 "meta.UUID"
    // "event_type"                 "crash"
    // "app_version"                "meta.appVersion"
    // "update_version_code"        "meta.bundleVersion"
    // "crash_detail" {
    //      "type":   "headerInfo.typeStr"
    //      "name":   "headerInfo.name"
    //      "reason": "headerInfo.reason"
    //
    //      "fault_address": "0x%018llx"      headerInfo.faultAddr
    //      "mach_code":     "0x%018llx"      headerInfo.mach_code
    //      "mach_subcode":  "0x%018llx"      mach_subcode
    //
    //      "fault_address": "0x%018llx"      headerInfo.faultAddr
    //      "signum": (n)                     headerInfo.signum
    //      "sigcode": (b)                    headerInfo.sigcode
    // }
    // "memory_usage": (n)processState.appUsedBytes/HMD_MB
    // "m_zoom_free": (n)hmd_calculateMemorySizeLevel(freeMemoryBytes)
    // "used_virtual_memory": (n)virtualMemory
    // "total_virtual_memory": (n)totalVirtualMemory
    // "d_zoom_free": (n)ceil(info.storage.free/(300 * HMD_MB))
    // "m_zoom_percent": (n)free_memory_percent
    // "inapp_time": (n)crashTime - startTime
    // "is_launch_crash": (n)0/1
    // "sdk_version": "meta.sdkVersion"
    // "os_version": "meta.osVersion"
    // "is_mac_arm": (n)meta.isMacARM
    // "is_env_abnormal": (n)isJailBroken
    // "has_dump": (n)info.hasDump
    // "exception_main_address": (n)meta.exceptionMainAddress
    // "custom": {
    //      "user_id": "userID"
    //      "scoped_user_id": scopedUserID
    //      "user_name": "userName"
    //      "email": "email"
    // }
    // "is_background": (n)is_background
    // "is_exit": (n)is_exit
    // "app_version": "meta.appVersion"
    // "update_version_code": "meta.bundleVersion"
    // "header": {
    //      "app_version": "meta.appVersion"
    //      "update_version_code": "meta.bundleVersion"
    //      "is_env_abnormal": (n)isJailBroken
    //      "unique_key": @"%@_%@_%lld_%@" appID deviceID
    //                     timestamp(headerInfo.crashTime) "crash"
    //      "os": "iOS"
    //      "timezone": ([[NSTimeZone localTimeZone] secondsFromGMT] / 3600)
    //      "is_env_abnormal": (n)is_env_abnormal
    //      "os_version": "systemVersion"
    //      "device_model": "deviceModel"
    //      "language": "currentLanguage"
    //      "resolution": "resolutionString"
    //      "region": "countryCode"
    //      "device_performance_level": "devicePerformaceLevel"
    //      "is_mac_arm": (n)is_mac_arm
    //      "package_name": "bundleIdentifier"
    //      "app_version": "shortVersion"
    //      "update_version_code": "buildVersion"
    //      "display_name": "appDisplayName"
    //      "is_upgrade_user": "isUpgradeUser"
    //      "crash_version": "KHMDCrashVersionString"
    //      "heimdallr_version": "sdkVersion"
    //      "sdk_version": "sdkVersion"
    //      "heimdallr_version_code": "sdkVersionCode"
    //      "mcc_mnc": @"%@%@" carrierMCC,carrierMNC
    //      "access": "connectTypeName"
    //      "carrier_region": "carrierRegions"
    //      "carrier_region1": "carrierRegions"
    //      "carrier_region2": "carrierRegions"
    //      "channel": "channel"
    //      "aid": "aid"
    //      "appName": "appName"
    //      "install_id": "install_id"
    //      "device_id": "device_id"
    //      "uid": "uid"
    //      "scoped_device_id": "scopedDeviceID"
    //      "scoped_user_id": "scopedUserID"
    // }
    
    HMDCrashLoadModel *model = context.model;
    HMDCrashLoadMeta *meta = context.meta;
    HMDCrashLoadProfile *profile = meta.profile;
    
    if(model == nil || meta == nil || profile == nil)
        DEBUG_RETURN_NONE;
    
    NSMutableDictionary * dataDict = NSMutableDictionary.dictionary;
    
    // (timestamp) ms since 1970
    NSTimeInterval crashTime = model.headerInfo.crashTime;
    uint64_t timestamp = crashTime * 1000;
    [dataDict hmd_setObject:@(timestamp) forKey:@"timestamp"];
    
    // (data)
    NSString * _Nullable crashLog = model.crashLog;
    DEBUG_ASSERT(crashLog.length != 0);
    [dataDict hmd_setObject:crashLog forKey:@"data"];
    
    // (session_id)
    NSString * _Nullable UUID = context.processUUID;
    DEBUG_ASSERT(UUID.length != 0);
    [dataDict hmd_setObject:UUID forKey:@"session_id"];
    
    // (event_type)
    [dataDict hmd_setObject:@"crash" forKey:@"event_type"];
    
    // (app_version) CFBundleShortVersionString
    [dataDict hmd_setObject:meta.bundleShortVersion forKey:@"app_version"];
    
    // (update_version_code) CFBundleVersion
    [dataDict hmd_setObject:meta.bundleVersion forKey:@"update_version_code"];
    
    // (crash_detail)
    NSDictionary * crashDetail = crashDetailDictionary(context);
    [dataDict hmd_setObject:crashDetail forKey:@"crash_detail"];
    
    // (is_launch_crash)
    [dataDict hmd_setObject:@(1) forKey:@"is_launch_crash"];
    
    // (sdk_version)
    DEBUG_ASSERT(meta.SDKVersion != nil);
    [dataDict hmd_setObject:meta.SDKVersion forKey:@"sdk_version"];
    
    // (os_version)
    [dataDict hmd_setObject:meta.OSVersion forKey:@"os_version"];
    
    // (is_mac_arm)
    [dataDict hmd_setObject:@(meta.isiOSAppOnMac) forKey:@"is_mac_arm"];
    
    // (is_env_abnormal)
    [dataDict hmd_setObject:@(meta.envAbnormal) forKey:@"is_env_abnormal"];
    
    // (custom)
    NSDictionary *customDict = @{ @"hmd_load_crash": @"1" };
    [dataDict hmd_setObject:customDict forKey:@"custom"];
    
    // (filters)
    NSMutableDictionary *filterDict =
        [NSMutableDictionary dictionaryWithCapacity:2];
    
    [filterDict hmd_setObject:@"1" forKey:@"hmd_load_crash"];
    
    if(meta.autoTestType != nil) {
        [filterDict hmd_setObject:meta.autoTestType
                           forKey:@"automation_test_type"];
    }
    
    [dataDict hmd_setObject:filterDict forKey:@"filters"];
    
    // (header)
    NSMutableDictionary *headerDict = NSMutableDictionary.dictionary;
    
    // (header) (unique_key)
    NSString *uniqueKey =
        [NSString stringWithFormat:@"%@_%@_%llu_crash",
         meta.appID, profile.deviceID, (unsigned long long)timestamp];
    [headerDict hmd_setObject:uniqueKey forKey:@"unique_key"];
    
    // (header) (app_version)
    [headerDict hmd_setObject:meta.bundleShortVersion forKey:@"app_version"];
    
    // (header) (update_version_code)
    [headerDict hmd_setObject:meta.bundleVersion forKey:@"update_version_code"];
    
    // (header) (is_env_abnormal)
    [headerDict hmd_setObject:@(meta.envAbnormal) forKey:@"is_env_abnormal"];
    
    // HMDUploadHelper - header_info
    
    // (header) (os)
    [headerDict hmd_setObject:@"iOS" forKey:@"os"];
    
    // (header) (timezone)
    [headerDict hmd_setObject:@(meta.hoursFromGMT) forKey:@"timezone"];
    
    // (header) (os_version)
    [headerDict hmd_setObject:meta.OSVersion forKey:@"os_version"];
    
    // (header) (device_model)
    [headerDict hmd_setObject:meta.deviceModel forKey:@"device_model"];
    
    // (header) (language)
    [headerDict hmd_setObject:meta.language forKey:@"language"];
    
    // (header) (region)
    [headerDict hmd_setObject:meta.region forKey:@"region"];
    
    // (header) (is_mac_arm)
    [headerDict hmd_setObject:@(meta.isiOSAppOnMac) forKey:@"is_mac_arm"];
    
    // (header) (package_name)
    [headerDict hmd_setObject:meta.bundleID forKey:@"package_name"];
    
    // (header) (app_version) (already exist)
    // [headerDict hmd_setObject:meta->_bundleShortVersion forKey:@"app_version"];
    
    // (header) (update_version_code) (already exist)
    // [headerDict hmd_setObject:meta.bundleVersion forKey:@"update_version_code"];
    
    // (header) (display_name)
    [headerDict hmd_setObject:meta.displayName forKey:@"display_name"];
    
    // (header) (crash_version)
    [headerDict hmd_setObject:@"1.0" forKey:@"crash_version"];
    
    // (header) (heimdallr_version)
    [headerDict hmd_setObject:meta.SDKVersion forKey:@"heimdallr_version"];
    
    // (header) (sdk_version)
    [headerDict hmd_setObject:meta.SDKVersion forKey:@"sdk_version"];
    
    // (header) (channel)
    [headerDict hmd_setObject:profile.channel forKey:@"channel"];
    
    // (header) (aid)
    [headerDict hmd_setObject:meta.appID forKey:@"aid"];
    
    // (header) (appName)
    [headerDict hmd_setObject:profile.appName forKey:@"appName"];
    
    // (header) (install_id)
    [headerDict hmd_setObject:profile.installID forKey:@"install_id"];
    
    // (header) (device_id)
    [headerDict hmd_setObject:profile.deviceID forKey:@"device_id"];
    
    // (header) (uid)
    [headerDict hmd_setObject:profile.userID forKey:@"uid"];
    
    // (header) (scoped_device_id)
    [headerDict hmd_setObject:profile.scopedDeviceID forKey:@"scoped_device_id"];
    
    // (header) (scoped_user_id)
    [headerDict hmd_setObject:profile.scopedUserID forKey:@"scoped_user_id"];
    
    [dataDict hmd_setObject:headerDict forKey:@"header"];
    
    // 2023.9.19 测试 上报字段数据最少量级为, 以下字段什么都不能缺
    // 以及 filters 和 custom 可以没有
    // 但里面字段必须都是字符串类型 "stringKey": "stringValue"
    //
    //    {
    //      "crash_detail": {
    //        "type": "NSException",
    //        "name": "6",
    //        "reason": "6"
    //      },
    //      "event_type": "crash",
    //      "header": {
    //        "device_id": "1",
    //        "aid": "492373",
    //        "os": "iOS",
    //        "timezone": 8,
    //        "crash_version": "1.0",
    //        "unique_key": "492373_6416679887_1695047951045_crash"
    //      }
    //    }
    
    model.dataDict = dataDict;
}

static void HMDCrashLoadLaunch_process_multipartData(HMDCLoadContext * context) {
    
    HMDCrashLoadModel *model = context.model;
    
    if(model == nil) DEBUG_RETURN_NONE;
    
    NSDictionary * dataDict = model.dataDict;
    
    if(dataDict == nil) DEBUG_RETURN_NONE;
    
    NSData *crashData = dictionaryToJSONData(dataDict);
    
    if(crashData == nil) DEBUG_RETURN_NONE;
    
    NSData *newPart = dataFromUTF8("--AaB03x");
    NSData *newLine = dataFromUTF8("\r\n");
    NSData *endPart = dataFromUTF8("--AaB03x--");
    
    if(newPart == nil || newLine == nil || endPart == nil)
        DEBUG_RETURN_NONE;
    
    NSData *contentDispose =
        dataFromUTF8("Content-Disposition: form-data; name=\"json\"");
    
    NSData *contentType =
        dataFromUTF8("Content-Type: text/plain; charset=UTF-8");
    
    if(contentDispose == nil || contentType == nil)
        DEBUG_RETURN_NONE;
    
    NSMutableData *data = NSMutableData.data;
    
    // --AaB03x\r\n
    [data appendData:newPart];
    [data appendData:newLine];
    
    // Content-Disposition: xx \r\n
    [data appendData:contentDispose];
    [data appendData:newLine];
    
    // Content-Type: xx \r\n
    [data appendData:contentType];
    [data appendData:newLine];
    
    // \r\n
    // \r\n
    [data appendData:newLine];
    [data appendData:newLine];
    
    // crashData \r\n
    [data appendData:crashData];
    [data appendData:newLine];
    
    // --AaB03x--
    [data appendData:endPart];
    
    model.multipartData = data;
}

static void HMDCrashLoadLaunch_process_gzipData(HMDCLoadContext * context) {
    
    HMDCrashLoadModel *model = context.model;
    
    if(model == nil) DEBUG_RETURN_NONE;
    
    NSData * multipartData = model.multipartData;
    if(multipartData == nil) DEBUG_RETURN_NONE;
    
    NSUInteger dataLength = multipartData.length;
    
    if(dataLength == 0)
        DEBUG_RETURN_NONE;
    
    z_stream stream;
    stream.zalloc = Z_NULL;
    stream.zfree  = Z_NULL;
    stream.opaque = Z_NULL;
    stream.total_out = 0;
    stream.next_in  = (Bytef *)multipartData.bytes;
    stream.avail_in = (uInt) dataLength;
    
    int rt = deflateInit2(&stream,
                          Z_DEFAULT_COMPRESSION,
                          Z_DEFLATED,
                          (15+16), 8, Z_DEFAULT_STRATEGY);
    
    if(rt != Z_OK) DEBUG_RETURN_NONE;
    
    // 16KB
    NSMutableData *gzipData = [NSMutableData dataWithLength:0x4000];
    
    do {
        if(stream.total_out >= gzipData.length)
            [gzipData increaseLengthBy:0x4000];
        
        stream.next_out  = gzipData.mutableBytes + stream.total_out;
        stream.avail_out = (uInt)(gzipData.length - stream.total_out);
        
        deflate(&stream, Z_FINISH);
        
    } while(stream.avail_out == 0);
    
    deflateEnd(&stream);
    
    [gzipData setLength:stream.total_out];
    
    model.gzipData = gzipData;
}

static void HMDCrashLoadLaunch_process_outputData(HMDCLoadContext * context) {
    
    NSString *loadPrepared = context.loadPrepared;
    NSString *processUUID  = context.processUUID;
    HMDCrashLoadModel *model = context.model;
    NSFileManager *manager = context.manager;
    
    if(loadPrepared == nil || processUUID == nil)
        DEBUG_RETURN_NONE;
    
    if(model == nil || manager == nil)
        DEBUG_RETURN_NONE;
    
    NSData *gzipData = model.gzipData;
    
    DEBUG_ASSERT(gzipData != nil);
    
    NSString *outputPath = joinPath(loadPrepared, processUUID);
    
    NSData *outputData = gzipData;
    
    if (outputData == nil) {
        outputData = model.multipartData;
    }
    
    if (outputData == nil) DEBUG_RETURN_NONE;
    
    if (gzipData != nil) {
        outputPath = [outputPath stringByAppendingPathExtension:@"gzip"];
    }
    
    DEBUG_ASSERT(![manager fileExistsAtPath:outputPath]);
    
    if (unlikely([manager fileExistsAtPath:outputPath])) {
        [manager removeItemAtPath:outputPath error:nil];
    }
    
    BOOL success = [outputData writeToFile:outputPath
                                   options:NSDataWritingAtomic
                                     error:nil];
    
    if(!success) DEBUG_RETURN_NONE;
    
    model.successFlag = YES;
}

static void HMDCrashLoadLaunch_process_report(HMDCLoadContext * context) {
    HMDCrashLoadModel *model = context.model;
    if(model == nil) DEBUG_RETURN_NONE;
    
    if(likely(model.successFlag)) return;
    
    HMDCLoadOptionRef option = context.option;
    
    option->failureStatus.processCrashFailedCount += 1;
}

#pragma mark - Upload routine

static void HMDCrashLoadLaunch_upload(HMDCLoadContext * context) {
    DEBUG_ASSERT(context != NULL);
        
    HMDCLoadOptionRef option = context.option;
    
    PROFILE_TIME(upload.beginTime);
    
    CLOAD_LOG("[Progress] upload begin");
    
    HMDCrashLoadLaunch_upload_internal(context);

    CLOAD_LOG("[Progress] upload end");
    
    PROFILE_TIME(upload.endTime);
}

static void HMDCrashLoadLaunch_upload_internal(HMDCLoadContext * context) {
    
    HMDCLoadOptionRef option = context.option;
    if(unlikely(!option->uploadOption.enable)) {
        CLOAD_LOG("UPLOAD disabled by option, uploading process exit");
        return;
    }
    
    NSString *loadPrepared = context.loadPrepared;
    NSFileManager *manager = context.manager;
    DEBUG_ASSERT(loadPrepared != nil && manager != nil);
    
    NSArray<NSString *> *preparedContents = dirContent(loadPrepared);
    
    if(preparedContents.count == 0) {
        CLOAD_LOG("[Upload] ignored, nothing exist at prepared "
                  "directory %s", CLOAD_PATH(loadPrepared));
        return;
    }
    
    HMDCrashLoadLaunch_upload_triggerPrepareMeta(context);
    
    HMDCrashLoadMeta *meta = context.meta;
    
    if(meta == nil || meta.appID == nil) {
        CLOAD_LOG("failed to start upload, meta or appID is missing");
        return;
    }

    HMDCrashLoadLaunch_upload_constructURL(context);
    
    HMDCrashLoadLaunch_upload_createBackgroundSession(context);
    
    if(context.uploadingURL == nil || context.session == nil) {
        CLOAD_LOG("upload URL %p session %p, exit upload process",
                  context.uploadingURL, context.session);
        return;
    }
    
    for(NSString *eachContent in preparedContents) {
        NSString *contentPath = joinPath(loadPrepared, eachContent);
        
        BOOL isDirectory = NO;
        BOOL isExist = [manager fileExistsAtPath:contentPath
                                     isDirectory:&isDirectory];
        
        if(unlikely(!isExist)) continue;
        
        if(unlikely(isDirectory)) {
            CLOAD_LOG("[DIR] delete %s, this should be file not directory, "
                      "delete it to correct error", CLOAD_PATH(contentPath));
            [manager removeItemAtPath:contentPath error:nil];
            continue;
        }
        
        context.uploadingName = eachContent;
        context.uploadingPath = contentPath;
        
        HMDCrashLoadLaunch_upload_eachContent(context);
    }
}

static void HMDCrashLoadLaunch_upload_triggerPrepareMeta(HMDCLoadContext * context) {
    DEBUG_ASSERT(context.meta == nil || context.processUUID != nil);
    
    CLOAD_LOG("prepare crash meta for uploading crash log");
    
    HMDCrashLoadLaunch_prepareMeta(context);
}

static void HMDCrashLoadLaunch_upload_constructURL(HMDCLoadContext *context) {
    HMDCrashLoadMeta *meta = context.meta;
    HMDCrashLoadProfile *profile = meta.profile;
    
    if(meta == nil) DEBUG_RETURN_NONE;
    
    NSString *uploadingHost = meta.uploadingHost;
    
    if(uploadingHost == nil) {
        CLOAD_LOG("missing uploading host, construct uploading URL exit");
        return;
    }
    
    NSURLComponents *URLComponents = NSURLComponents.alloc.init;
    
    URLComponents.scheme = @"https";
    URLComponents.host = uploadingHost;
    URLComponents.path = HMDCrashUploadURLDefaultPath; // /service/2/app_log_exception/
    
    NSMutableArray<NSURLQueryItem *> *queryItems = NSMutableArray.array;
    
    queryAddKeyString(queryItems, @"os", @"iOS");
    
    queryAddKeyNumber(queryItems, @"timezone", @(meta.hoursFromGMT));
    
    queryAddKeyNumber(queryItems, @"is_env_abnormal", @(meta.envAbnormal));
    
    queryAddKeyString(queryItems, @"os_version", meta.OSVersion);
    
    queryAddKeyString(queryItems, @"device_model", meta.deviceModel);
    
    queryAddKeyString(queryItems, @"language", meta.language);
    
    queryAddKeyString(queryItems, @"region", meta.region);
    
    queryAddKeyNumber(queryItems, @"is_mac_arm", @(meta.isiOSAppOnMac));
    
    queryAddKeyString(queryItems, @"package_name", meta.bundleID);
    
    queryAddKeyString(queryItems, @"app_version", meta.bundleShortVersion);
    
    queryAddKeyString(queryItems, @"update_version_code", meta.bundleVersion);
    
    queryAddKeyString(queryItems, @"display_name", meta.displayName);
    
    queryAddKeyString(queryItems, @"crash_version", @"1.0");
    
    queryAddKeyString(queryItems, @"heimdallr_version", meta.SDKVersion);
    
    queryAddKeyString(queryItems, @"sdk_version", meta.SDKVersion);
    
    queryAddKeyString(queryItems, @"channel", profile.channel);
    
    queryAddKeyString(queryItems, @"aid", meta.appID);
    
    queryAddKeyString(queryItems, @"appName", profile.appName);
    
    queryAddKeyString(queryItems, @"install_id", profile.installID);
    
    queryAddKeyString(queryItems, @"device_id", profile.deviceID);
    
    queryAddKeyString(queryItems, @"uid", profile.userID);
    
    queryAddKeyString(queryItems, @"scoped_device_id", profile.scopedDeviceID);
    
    queryAddKeyString(queryItems, @"scoped_user_id", profile.scopedUserID);
    
    queryAddKeyString(queryItems, @"have_dump", @"false");
    
    // 缺失字段: heimdallr_version_code
    // carrier mcc_mnc access carrier_region
    // is_upgrade_user resolution
    
    // 2023.9.19 测试, 必须至少有 os=iOS 和 has_dump=false 字段
    // has dump 意味着是否额外上传一个压缩文件包 ( 看 CrashTracker 里面处理
    // https://mon.zijieapi.com/service/2/app_log_exception/?os=iOS&have_dump=false
    
    URLComponents.queryItems = queryItems;
    
    context.uploadingURL = URLComponents.URL;
    
    CLOAD_LOG("[Upload] URL: %s", context.uploadingURL.absoluteString.UTF8String);
}

static void HMDCrashLoadLaunch_upload_createBackgroundSession(HMDCLoadContext * context) {
    context.session = [HMDCrashLoadBackgroundSession sessionWithContext:context];
}

static void HMDCrashLoadLaunch_upload_eachContent(HMDCLoadContext *context) {
    HMDCrashLoadBackgroundSession *session = context.session;
    NSURL *uploadingURL = context.uploadingURL;
    
    if(session == nil || uploadingURL == nil)
        DEBUG_RETURN_NONE;
    
    NSString *uploadingName = context.uploadingName;
    NSString *uploadingPath = context.uploadingPath;
    
    CLOAD_LOG("[Upload] try uploading crash log %s", uploadingName.UTF8String);
    
    if(uploadingName == nil || uploadingPath == nil)
        DEBUG_RETURN_NONE;
    
    NSArray<NSString *> *previousUploading = session.previousUploading;
    
    if([previousUploading containsObject:uploadingName]) {
        CLOAD_LOG("[Upload] crash log %s already uploading in previous upload",
                  uploadingName.UTF8String);
        return;
    }
    
    [session uploadPath:uploadingPath name:uploadingName];
}

#pragma mark - Sync routine

static void HMDCrashLoadLaunch_sync(HMDCLoadContext * context) {
    DEBUG_ASSERT(context != NULL);
        
    HMDCLoadOptionRef option = context.option;
    
    PROFILE_TIME(sync.beginTime);
    
    CLOAD_LOG("[Progress] sync begin");
    
    HMDCrashLoadLaunch_sync_outdateMirror(context);
    
    HMDCrashLoadLaunch_sync_registerMirror(context);
    
    HMDCrashLoadLaunch_sync_currentDirectory(context);
    
    HMDCrashLoadLaunch_sync_markStarted(context);

    CLOAD_LOG("[Progress] sync end");
    
    PROFILE_TIME(sync.endTime);
}

static void HMDCrashLoadLaunch_sync_outdateMirror(HMDCLoadContext * context) {
    DEBUG_ASSERT(context != NULL);
        
    NSFileManager *manager = context.manager;
    HMDCLoadOptionRef option = context.option;
    
    if(option == NULL || manager == nil) DEBUG_RETURN_NONE;
    
    
    NSString *loadMirror = context.loadMirror;
    if(loadMirror == nil) {
        CLOAD_LOG("load mirror path is nil, outdate mirror failed");
        return;
    }
    
    NSString *profilePath = joinPath(loadMirror, @"mirror.profile");
    
    BOOL isDirectory = NO;
    BOOL isExist = [manager fileExistsAtPath:profilePath
                                 isDirectory:&isDirectory];
    
    if(unlikely(!isExist)) {
        CLOAD_LOG("mirror.profile not exist at path %s, outdate finished",
                  CLOAD_PATH(profilePath));
        return;
    }
    
    if(unlikely(isDirectory)) {
        CLOAD_LOG("[DIR] delete %s, mirror should be file not directory",
                  CLOAD_PATH(profilePath));
        
        [manager removeItemAtPath:profilePath error:nil];
        return;
    }
    
    NSString *outdatePath = joinPath(loadMirror, @"mirror.outdate.profile");
    
    isDirectory = NO;
    isExist = [manager fileExistsAtPath:profilePath
                            isDirectory:&isDirectory];
    
    if(isExist) {
        CLOAD_LOG("[DIR] delete %s, clear outdate mirror for new mirror",
                  CLOAD_PATH(outdatePath));
        
        [manager removeItemAtPath:outdatePath error:nil];
    }
    
    CLOAD_LOG("[DIR] move %s to %s, outdate mirror",
              CLOAD_PATH(profilePath), CLOAD_PATH(outdatePath));
    
    [manager moveItemAtPath:profilePath toPath:outdatePath error:nil];
}

static void HMDCrashLoadLaunch_sync_registerMirror(HMDCLoadContext * context) {
    DEBUG_ASSERT(context != NULL);
        
    HMDCLoadOptionRef option = context.option;
    
    
    if(!option->userProfile.enableMirror) {
        CLOAD_LOG("mirror disabled, register mirror cancelled");
        return;
    }
    
    NSString *loadMirror = context.loadMirror;
    if(loadMirror == nil) {
        CLOAD_LOG("load mirror path is nil, register mirror failed");
        return;
    }
    
    NSString *profilePath = joinPath(loadMirror, @"mirror.profile");
    
    HMDCrashLoadSync.sync.mirrorPath = profilePath;
    
    CLOAD_LOG("[Mirror] registered, expect tracker to write mirror data");
}

static void HMDCrashLoadLaunch_sync_currentDirectory(HMDCLoadContext * context) {
    DEBUG_ASSERT(!HMDCrashLoadSync.sync.started);
    
    CLOAD_LOG("[Sync] tracker active as %s", CLOAD_PATH(context.trackerActive));
    
    HMDCrashLoadSync.sync.currentDirectory = context.currentDirectory;
}

static void HMDCrashLoadLaunch_sync_markStarted(HMDCLoadContext * context) {
    
    HMDCrashLoadSync_setStarted(true);
    
    CLOAD_LOG("[Sync] mark load launch started");
}

#pragma mark - Finish Routine

static void HMDCrashLoadLaunch_finish(HMDCLoadContext * context) {
    DEBUG_ASSERT(context != NULL);
        
    HMDCLoadOptionRef option = context.option;
    
    PROFILE_TIME(finish.beginTime);
    
    CLOAD_LOG("[Progress] finish begin");
    
    // code here
    
    CLOAD_LOG("[Progress] finish end");
    
    PROFILE_TIME(finish.endTime);
}

#pragma mark - Report routine

static void HMDCrashLoadLaunch_report(HMDCLoadContext * context) {
    DEBUG_ASSERT(context != NULL);
        
    HMDCLoadOptionRef option = context.option;
    
    PROFILE_TIME(report.beginTime);
    
    CLOAD_LOG("[Progress] report begin");
    
    HMDCrashLoadReport *report = HMDCrashLoadReport.report;
    context.report = report;
    
    report.lastTimeCrash     = option->urgentStatus.lastTimeCrash;
    report.lastTimeLoadCrash = option->urgentStatus.lastTimeLoadCrash;
    
    NSTimeInterval launchDuration = option->timeProfile.launch.endTime -
        option->timeProfile.launch.beginTime;
    
    report.launchDuration    = launchDuration;
    
    report.moveTrackerProcessFailedCount =
        option->failureStatus.moveTrackerProcessFailedCount;
    
    report.dropCrashIfProcessFailedCount =
        option->failureStatus.dropCrashIfProcessFailedCount;

    CLOAD_LOG("[Progress] report end");
    
    PROFILE_TIME(report.endTime);
}

#pragma mark - End Guard routine

static void HMDCrashLoadLaunch_endGuard(HMDCLoadContext * context) {
    
    CLOAD_LOG("[Progress] endGuard begin");
    
    NSString *loadSafeGuard = context.loadSafeGuard;
    NSFileManager *manager = context.manager;
    
    DEBUG_ASSERT(loadSafeGuard != nil && manager != nil);
    
    BOOL directoryAlreadyExist = NO;
    checkAndCreateDirectory(loadSafeGuard, &directoryAlreadyExist);
    
    CLOAD_LOG("[DIR] create %s", CLOAD_PATH(loadSafeGuard));
    
    if(unlikely(!directoryAlreadyExist)) DEBUG_RETURN_NONE;
    
    NSArray *contents = dirContent(loadSafeGuard);
    
    for(NSString *content in contents) {
        NSString *contentPath = joinPath(loadSafeGuard, content);
        [manager removeItemAtPath:contentPath error:nil];
        
        CLOAD_LOG("[DIR] delete %s, safeGuard content", CLOAD_PATH(contentPath));
    }
    
    CLOAD_LOG("[Progress] endGuard end");
}

#pragma mark - PrepareMeta Routine

static void HMDCrashLoadLaunch_prepareMeta(HMDCLoadContext * context) {
    DEBUG_ASSERT(context != NULL);
    
    CLOAD_LOG("[Progress] prepareMeta begin");
    
    if(context.meta != nil) {
        CLOAD_LOG("crash meta already prepared, no need to prepare again");
        return;
    }
    
    // initialize meta
    HMDCrashLoadMeta *meta = HMDCrashLoadMeta.meta;
    context.meta = meta;
    
    if(meta == nil) DEBUG_RETURN_NONE;
    
    HMDCrashLoadLaunch_prepareMeta_frozen(context);
    
    HMDCrashLoadLaunch_prepareMeta_loadMirror(context);
    
    HMDCrashLoadLaunch_prepareMeta_profile(context);
    
    CLOAD_LOG("[Progress] prepareMeta end");
}

static void HMDCrashLoadLaunch_prepareMeta_frozen(HMDCLoadContext * context) {
    HMDCrashLoadMeta *meta = context.meta;
    if(meta == nil) DEBUG_RETURN_NONE;
    
    // uploadingHost
    HMDCLoadOptionRef option = context.option;
    DEBUG_ASSERT(option != NULL);
    
    if(option->uploadOption.host != NULL) {
        meta.uploadingHost =
            [NSString stringWithUTF8String:option->uploadOption.host];
    }
    
    if(option->uploadOption.appID != NULL) {
        meta.appID =
            [NSString stringWithUTF8String:option->uploadOption.appID];
    }
    
    // codeType
    const NXArchInfo * _Nullable archInfo = NXGetLocalArchInfo();
    const char * rawArchName = "unknown_arch";
    if(archInfo != NULL && archInfo->name != NULL) rawArchName = archInfo->name;
    meta.codeType           = [NSString stringWithUTF8String:rawArchName];
    
    // bundle ID
    // bundle short version
    // bundle version
    // auto test type
    NSBundle *mainBundle = NSBundle.mainBundle;
    NSDictionary *infoDictionary = mainBundle.infoDictionary;
    
    meta.bundleID           = [infoDictionary objectForKey:@"CFBundleIdentifier"];
    meta.bundleShortVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    meta.bundleVersion      = [infoDictionary objectForKey:@"CFBundleVersion"];
    meta.displayName        = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    if (meta.displayName == nil) {
        meta.displayName    = [infoDictionary objectForKey:@"CFBundleName"];
    }
    NSDictionary * autoDict   = [infoDictionary hmd_dictForKey:@"AutomationTestInfo"];
    if(autoDict != nil) {
        meta.autoTestType   = [autoDict hmd_stringForKey:@"automation_test_type"];
        meta.testRuntime    = [autoDict hmd_stringForKey:@"test_runtime"];
        meta.offline        = YES;
    }
    
    // SDK Version
    // OS Build Version
    meta.SDKVersion         = SDKVersionString();
    meta.OSBuildVersion     = kernelOSVersionToString();
    
    // is iOS App On Mac
    // device model
    // OS version
    // process name
    // process ID
    NSProcessInfo *processInfo = NSProcessInfo.processInfo;
    NSOperatingSystemVersion rawSystemVersion = processInfo.operatingSystemVersion;
    
    meta.isiOSAppOnMac = processIsiOSAppOnMac(processInfo);
    meta.deviceModel   = deviceModelToString(meta.isiOSAppOnMac);
    meta.OSVersion     = systemOrOSVersionToString(rawSystemVersion);
    meta.processName   = processInfo.processName;
    meta.processID     = processInfo.processIdentifier;
    
    // hours from GMT
    meta.hoursFromGMT = NSTimeZone.localTimeZone.secondsFromGMT / 3600;
    
    // language
    // region
    NSLocale *currentLocale = NSLocale.currentLocale;
    
    meta.language = [currentLocale objectForKey:NSLocaleLanguageCode];
    meta.region   = [currentLocale objectForKey:NSLocaleCountryCode];
    
    // envAbnormal
     meta.envAbnormal = NO;
}

static void HMDCrashLoadLaunch_prepareMeta_loadMirror(HMDCLoadContext * context) {
    HMDCrashLoadMeta *meta = context.meta;
    NSFileManager *manager = context.manager;
    HMDCLoadOptionRef option = context.option;
    
    if(option == NULL || manager == nil || meta == nil) DEBUG_RETURN_NONE;
    
    if(unlikely(!option->userProfile.enableMirror)) {
        CLOAD_LOG("[PrepareMeta][Mirror] not to prepare meta from mirror, "
                  "userProfile.enableMirror not enabled");
        return;
    }
    
    NSString *loadMirror = context.loadMirror;
    if(loadMirror == nil) {
        CLOAD_LOG("[PrepareMeta][Mirror] load mirror path is nil, prepare meta "
                  "mirror failed");
        return;
    }
    
    NSString *profilePath = joinPath(loadMirror, @"mirror.profile");
    BOOL profileOutdate = NO;
    
    CLOAD_LOG("[PrepareMeta][Mirror] try reading mirror profile at path %s",
              CLOAD_PATH(profilePath));
    
    profilePath = mirrorProfileAtPath(profilePath);
    
    if(unlikely(profilePath == nil)) {
        CLOAD_LOG("[PrepareMeta][Mirror] mirror profile not exist at path %s, "
                  "try read outdate file", CLOAD_PATH(loadMirror));
        
        profilePath = joinPath(loadMirror, @"mirror.outdate.profile");
        
        CLOAD_LOG("[PrepareMeta][Mirror] try reading outdate mirror profile "
                  "at path %s", CLOAD_PATH(profilePath));
        
        profileOutdate = YES;
        profilePath = mirrorProfileAtPath(profilePath);
    }
    
    if(unlikely(profilePath == nil)) {
        CLOAD_LOG("[PrepareMeta][Mirror] unable to find any mirror profile "
                  "under directory %s", CLOAD_PATH(loadMirror));
        return;
    }
    
    NSData *profileData = readMirrorProfileData(profilePath);
    if(profileData == nil) {
        CLOAD_LOG("[PrepareMeta][Mirror] unable to read profile data from file "
                  "at path %s", CLOAD_PATH(profilePath));
        return;
    }
    
    if(profileData.length == 0) {
        CLOAD_LOG("[PrepareMeta][Mirror] profile data is empty at path %s",
                  CLOAD_PATH(profilePath));
        return;
    }
    
    NSDictionary *profileDictionary = JSONDataToDictionary(profileData);
    if(profileDictionary == nil) {
        CLOAD_LOG("[PrepareMeta][Mirror] unable to convert data of profile "
                  "file %s to JSON", CLOAD_PATH(profilePath));
        return;
    }
    
    HMDCrashLoadProfile *mirrorProfile;
    mirrorProfile = [HMDCrashLoadProfile mirrorProfile:profileDictionary
                                               outdate:profileOutdate];
    
    CLOAD_LOG("[PrepareMeta][Mirror] load %s from file %s, channel %s, "
              "appName %s, installID %s, deviceID %s, userID %s, "
              "scopedDeviceID %s, scopedUserID %s",
              profileOutdate?"outdated mirror":"mirror",
              CLOAD_PATH(profilePath),
              mirrorProfile.channel.UTF8String,
              mirrorProfile.appName.UTF8String,
              mirrorProfile.installID.UTF8String,
              mirrorProfile.deviceID.UTF8String,
              mirrorProfile.userID.UTF8String,
              mirrorProfile.scopedDeviceID.UTF8String,
              mirrorProfile.scopedUserID.UTF8String);
    
    meta.mirrorProfile = mirrorProfile;
}

static void HMDCrashLoadLaunch_prepareMeta_profile(HMDCLoadContext *context) {
    HMDCrashLoadMeta *meta = context.meta;
    NSFileManager *manager = context.manager;
    HMDCLoadOptionRef option = context.option;
    
    if(option == NULL || manager == nil || meta == nil) DEBUG_RETURN_NONE;
    
    HMDCrashLoadProfile *mirrorProfile;
    HMDCrashLoadProfile *userProfile;
    HMDCrashLoadProfile *defaultProfile;
    HMDCrashLoadProfile *profile;
    
    mirrorProfile = meta.mirrorProfile;
    userProfile = [HMDCrashLoadProfile userProfile:option];
    defaultProfile = HMDCrashLoadProfile.defaultProfile;
    profile = HMDCrashLoadProfile.alloc.init;
    
    meta.userProfile = userProfile;
    
#define MAKE_PROFILE_DECISION(_propertyName)                                   \
    profile._propertyName = profileDecision                                    \
    (      mirrorProfile. _propertyName,                                       \
             userProfile. _propertyName,                                       \
          defaultProfile. _propertyName,                                       \
     option->userProfile. _propertyName ## Priority)
    
    MAKE_PROFILE_DECISION(channel);
    MAKE_PROFILE_DECISION(appName);
    MAKE_PROFILE_DECISION(installID);
    MAKE_PROFILE_DECISION(deviceID);
    MAKE_PROFILE_DECISION(userID);
    MAKE_PROFILE_DECISION(scopedDeviceID);
    MAKE_PROFILE_DECISION(scopedUserID);
    
    CLOAD_LOG("[PrepareMeta][Profile] channel %s, appName %s, installID %s, "
              "deviceID %s, userID %s, scopedDeviceID %s, scopedUserID %s",
              profile.channel.UTF8String, profile.appName.UTF8String,
              profile.installID.UTF8String, profile.deviceID.UTF8String,
              profile.userID.UTF8String, profile.scopedDeviceID.UTF8String,
              profile.scopedUserID.UTF8String);
    
    meta.profile = profile;
}

#pragma mark - Supporting function

#pragma mark ShortCut

static NSString * _Nullable profileDecision(NSString *mirrorValue,
                                            NSString *userValue,
                                            NSString *defaultValue,
                                            HMDCLoadOptionPriority priority) {
    if(mirrorValue != nil && userValue != nil) {
        if(priority == HMDCLoadOptionPriority_mirror_user_default) {
            return mirrorValue;
        }
        else if(priority == HMDCLoadOptionPriority_user_mirror_default) {
            return userValue;
        }
        else {
            DEBUG_RETURN(mirrorValue);
        }
    }
    
    if(mirrorValue != nil) return mirrorValue;
    
    if(userValue != nil)   return userValue;
    
    return defaultValue;
}


static NSData * _Nullable readMirrorProfileData(NSString *filePath) {
    const char * _Nonnull rawFilePath = filePath.UTF8String;
    if(rawFilePath == NULL) DEBUG_RETURN(nil);
    
    int fd = open(rawFilePath, O_RDONLY);
    if(fd < 0) return nil;
    
    #define HMD_CLOAD_MIRROR_PROFILE_EXPECTED_SIZE 512
    
    size_t expectedSize = HMD_CLOAD_MIRROR_PROFILE_EXPECTED_SIZE;
    uint8_t *buffer = __builtin_alloca(expectedSize);
    
    ssize_t readAmount = read(fd, buffer, expectedSize);
    
    NSData *result = nil;
    
    DEBUG_ASSERT(readAmount <= expectedSize);
    
    if(readAmount < 0) {
        CLOAD_LOG("can not read profile at path %s, return code %ld",
                  CLOAD_PATH(filePath), (long)readAmount);
        goto LABEL_close_fd;
    }
    
    if(readAmount == 0) {
        CLOAD_LOG("empty profile content at path %s", CLOAD_PATH(filePath));
        goto LABEL_close_fd;
    }
    
    const void * _Nullable nullTerminator;
    nullTerminator = memchr(buffer, '\0', readAmount);
    
    if(likely(nullTerminator != NULL)) {
        
        size_t bytesCount = (uintptr_t)nullTerminator - (uintptr_t)buffer;
        DEBUG_ASSERT(bytesCount < readAmount);
        
        result = [NSData dataWithBytes:buffer length:bytesCount];
        goto LABEL_close_fd;
    }
    
    if(likely(readAmount < expectedSize)) {
        
        result = [NSData dataWithBytes:buffer length:readAmount];
        goto LABEL_close_fd;
    }
    
    // fallback for large file
    result = [NSData dataWithContentsOfFile:filePath];
    
LABEL_close_fd:
    close(fd);
    return result;
}

// return profilePath if it is file at path
static NSString * _Nullable mirrorProfileAtPath(NSString *profilePath) {
    
    NSFileManager *manager = NSFileManager.defaultManager;
    
    BOOL isDirectory = NO;
    BOOL isExist = [manager fileExistsAtPath:profilePath
                                 isDirectory:&isDirectory];
    
    if(likely(isExist && !isDirectory))
        return profilePath;
    
    if(likely(!isExist)) return nil;
    
    DEBUG_ASSERT(isExist && isDirectory);
    
    CLOAD_LOG("[DIR] delete %s, profile should be file not directory",
              CLOAD_PATH(profilePath));
    
    [manager removeItemAtPath:profilePath error:nil];
    
    return nil;
}

static void queryAddKeyString(NSMutableArray<NSURLQueryItem *> *queryItems,
                              NSString *key, NSString * stringValue) {
    DEBUG_ASSERT(queryItems != nil);
    
    if(stringValue == nil || key == nil) DEBUG_RETURN_NONE;
    
    NSURLQueryItem *item = [NSURLQueryItem queryItemWithName:key
                                                       value:stringValue];
    
    if(item == nil) DEBUG_RETURN_NONE;
    
    [queryItems addObject:item];
}

static void queryAddKeyNumber(NSMutableArray<NSURLQueryItem *> *queryItems,
                              NSString *key, NSNumber * numberValue) {
    DEBUG_ASSERT(queryItems != nil);
    
    if(numberValue == nil || key == nil) DEBUG_RETURN_NONE;
    
    unsigned long uLongValue = numberValue.unsignedLongValue;
    
    NSString *stringValue = [NSString stringWithFormat:@"%lu", uLongValue];
    
    if(stringValue == nil) DEBUG_RETURN_NONE;
    
    NSURLQueryItem *item = [NSURLQueryItem queryItemWithName:key
                                                       value:stringValue];
    
    if(item == nil) DEBUG_RETURN_NONE;
    
    [queryItems addObject:item];
}

static HMDCLoadContext * _Nullable
contextFromOption(HMDCLoadOptionRef _Nullable externalOption) {
    if(externalOption == NULL) DEBUG_RETURN(NULL);
    return [HMDCLoadContext contextWithOption:externalOption];
}

static BOOL checkAndCreateDirectory(NSString * _Nonnull path,
                                    BOOL * _Nullable folderAlreadyExist) {
    
    if(folderAlreadyExist != NULL) folderAlreadyExist[0] = NO;
    
    NSFileManager *manager = NSFileManager.defaultManager;
    
    BOOL isDirectory;
    BOOL isExist = [manager fileExistsAtPath:path isDirectory:&isDirectory];
    
    if(isExist && isDirectory) {
        if(folderAlreadyExist != NULL) folderAlreadyExist[0] = YES;
        return YES;
    }
    
    BOOL successFlag = [manager createDirectoryAtPath:path
                          withIntermediateDirectories:YES
                                           attributes:nil
                                                error:nil];
    
    if(successFlag) return YES;
    
    return NO;
}

static NSString *joinPath(NSString * _Nonnull path1, NSString * _Nonnull path2) {
    DEBUG_ASSERT(path1 != NULL && path2 != NULL);
    return [path1 stringByAppendingPathComponent:path2];
}

static NSArray<NSString *> * _Nullable dirContent(NSString * _Nonnull path) {
    
    NSFileManager *manager = NSFileManager.defaultManager;
    DEBUG_ASSERT(manager != nil && path != nil);
    
    return [manager contentsOfDirectoryAtPath:path error:nil];
}

#define MAX_RECOVER_EXCEPTION_FILE_SIZE (1024 * 1024)   // 1MB

static NSArray<NSString *> * _Nullable linesOfFile(NSString * _Nonnull path) {
    DEBUG_ASSERT(path != nil);
    
    NSString * _Nullable content =
        [NSString stringWithContentsOfFile:path
                                  encoding:NSUTF8StringEncoding
                                     error:nil];
    
    if(content.length > 0) {
        return [content componentsSeparatedByString:@"\n"];
    }
    
    NSMutableArray<NSString *> *result = nil;
    
    NSString *standardPath = [path stringByStandardizingPath];
    const char *rawFilePath = standardPath.UTF8String;
    
    int fileDescriptor = open(rawFilePath, O_RDONLY | O_NOFOLLOW);
    if (fileDescriptor < 0) DEBUG_RETURN(nil);
    
    struct stat fileStatus;
    if(fstat(fileDescriptor, &fileStatus) != 0)
        goto clean_FD;
    
    off_t fileSize = fileStatus.st_size;
    
    if(fileSize == 0 || fileSize > MAX_RECOVER_EXCEPTION_FILE_SIZE)
        goto clean_FD;
    
    char * _Nullable tempStorage = malloc(fileStatus.st_size);
    
    if(tempStorage == nil)
        goto clean_FD;
    
    ssize_t readAmount = read(fileDescriptor, tempStorage, fileStatus.st_size);
    
    if(readAmount <= 0 || readAmount > fileSize)
        goto clean_storage_FD;
    
    result = NSMutableArray.array;
    
    ssize_t lineBeginIndex = 0;
    
    for(ssize_t index = 0; index < readAmount; index++) {
        
        // reach the end of file
        if(tempStorage[index] == '\0') break;
        
        // not meeting any file break
        if(tempStorage[index] != '\n') continue;
        
        // no line exist
        if(lineBeginIndex == index) break;
        
        // mark end of string
        tempStorage[index] = '\0';
        
        NSString * _Nullable lineString = nil;
        
        lineString = [NSString stringWithCString:tempStorage + lineBeginIndex
                                        encoding:NSUTF8StringEncoding];
        
        if(lineString != nil) {
            [result addObject:lineString];
        }
        
        lineBeginIndex = index + 1;
    }
    
clean_storage_FD:
    free(tempStorage);
clean_FD:
    close(fileDescriptor);
    
    return result;
}

static NSDictionary * _Nullable JSONDataToDictionary(NSData * data) {
    if(data == nil) DEBUG_RETURN(nil);
    
    id _Nullable maybeDictionary;
    maybeDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                      options:0
                                                        error:nil];
    
    if(maybeDictionary == nil) return nil;
    
    if(![maybeDictionary isKindOfClass:NSDictionary.class])
        return nil;
    
    return maybeDictionary;
}

static NSData * _Nullable dictionaryToJSONData(NSDictionary * dictionary) {
    if(dictionary == nil) DEBUG_RETURN(nil);
    
    BOOL isValid = NO;
    
    @try {
        isValid = [NSJSONSerialization isValidJSONObject:dictionary];
    } @catch (id anyException) {
        DEBUG_RETURN(nil);
    }
    
    if(!isValid) DEBUG_RETURN(nil);
    
    NSData *JSONData = nil;
    
    @try {
        JSONData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                   options:0
                                                     error:NULL];
    } @catch (id anyException) {
        DEBUG_RETURN(nil);
    }
    
    return JSONData;
}

static NSData * _Nullable dataFromUTF8(const char * _Nonnull rawString) {
    if(rawString == NULL) DEBUG_RETURN(nil);
    
    NSString *string = [NSString stringWithUTF8String:rawString];
    if(string == nil) DEBUG_RETURN(nil);
    
    return [string dataUsingEncoding:NSUTF8StringEncoding];
}

#pragma mark System Information

static NSString * _Nullable systemOrOSVersionToString(NSOperatingSystemVersion version) {
    if(version.patchVersion == 0) {
        return [NSString stringWithFormat:@"%lu.%lu", version.majorVersion,
                                                      version.minorVersion];
    }
    return [NSString stringWithFormat:@"%lu.%lu.%lu",
            version.majorVersion, version.minorVersion, version.patchVersion];
}

static bool processIsiOSAppOnMac(NSProcessInfo * process) {
    
    if(process == nil) DEBUG_RETURN(false);
    
    Class processClass = object_getClass(process);
    SEL   selector = sel_registerName("isiOSAppOnMac");
    
    bool respondTo = class_respondsToSelector(processClass, selector);
    if (!respondTo) return false;
    
    BOOL result = ((BOOL (*)(id, SEL))objc_msgSend)(process, selector);
    
    return result;
}

static NSString * _Nullable deviceModelToString(bool iOSAppOnMac) {
    if(iOSAppOnMac) {
        return hardwareModelToString();
    }
    
    struct utsname systemInfo;
    if(uname(&systemInfo) != 0) {
        return @"unknown";
    }
    
    COMPILE_ASSERT(sizeof(systemInfo.machine) == _SYS_NAMELEN);
    COMPILE_ASSERT(sizeof(systemInfo.machine) >= 1);
    
    systemInfo.machine[sizeof(systemInfo.machine) - 1] = '\0';
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

static NSString * _Nullable kernelOSVersionToString(void) {
    return systemControlByNameToString("kern.osversion");
}

static NSString * _Nullable hardwareModelToString(void) {
    return systemControlByNameToString("hw.model");
}

static NSString * _Nullable systemControlByNameToString(const char * _Nonnull name) {
    
    if(name == NULL) DEBUG_RETURN(nil);
    
    size_t size;
    
    int rt = sysctlbyname(name, NULL, &size, NULL, 0);
    if(rt != 0 || size == 0) DEBUG_RETURN(nil);
    
    char * _Nullable temp = malloc(size);
    if(temp == NULL) DEBUG_RETURN(nil);
    
    rt = sysctlbyname(name, temp, &size, NULL, 0);
    
    NSString * _Nullable result = nil;
    
    if(rt == 0) {
        temp[size - 1] = '\0';
        result = [NSString stringWithUTF8String:temp];
    }
    
    free(temp);
    
    return result;
}

static NSString * _Nullable commitIDToString(void) {
    
    NSString *plistPath = [NSBundle.mainBundle pathForResource:@"Heimdallr"
                                                        ofType:@"plist"];
    if(plistPath == nil) return nil;
    
    NSDictionary *data = [NSDictionary.alloc initWithContentsOfFile:plistPath];
    
    if(data == nil) return nil;
    
    return [data hmd_stringForKey:@"commit"];
}

static NSString * _Nonnull SDKVersionString(void) {
#ifdef Heimdallr_POD_VERSION
static NSString *const kHeimdallrPodVersion = Heimdallr_POD_VERSION;
#else
static NSString *const kHeimdallrPodVersion = @"0.8.39.0";
#endif
    return kHeimdallrPodVersion;
}

#pragma mark Crash Log format

static NSString * _Nullable threadNameForThread(HMDCLoadContext * context,
                                                HMDCrashThreadInfo *thread,
                                                unsigned int threadIndex) {
    DEBUG_ASSERT(context != nil && thread != nil);
    
    HMDCrashLoadModel *model = context.model;
    DEBUG_ASSERT(model != nil);
    
    BOOL isCrashed = thread.crashed;
    NSString * threadName = thread.threadName;

    if(likely(!isCrashed)) {
        return [NSString stringWithFormat:
                @"Thread %u name:  %@\nThread %u\n",
                threadIndex, threadName, threadIndex];
    }
    
    DEBUG_ASSERT(isCrashed);
    
    HMDCrashThreadInfo *asyncRecord = model.asyncRecord;
    NSString * asyncThreadName = asyncRecord.threadName;
    
    if(likely(asyncRecord == nil)) {
        return [NSString stringWithFormat:
                @"Thread %u name:  %@\nThread %u Crashed:\n",
                threadIndex, threadName, threadIndex];
    }
    
    return [NSString stringWithFormat:
            @"Thread %u name:  %@(Enqueued from %@)\nThread %u Crashed:\n",
            threadIndex, threadName, asyncThreadName, threadIndex];
}

static NSString * _Nullable stackTraceForThread(HMDCLoadContext * context,
                                                HMDCrashThreadInfo *thread) {
    DEBUG_ASSERT(context != nil && thread != nil);
    
    HMDCrashLoadModel *model = context.model;
    DEBUG_ASSERT(model != nil);
    
    NSArray<HMDCrashFrameInfo *> *frames = thread.frames;
    NSUInteger frameCount = frames.count;
    
    HMDCrashThreadInfo *asyncRecord = nil;
    NSArray<HMDCrashFrameInfo *> *asyncFrames = nil;
    NSUInteger asyncFramesCount = 0;
    
    BOOL isCrashed = thread.crashed;
    
    if(isCrashed) {
        asyncRecord = model.asyncRecord;
        asyncFrames = asyncRecord.frames;
        asyncFramesCount = asyncFrames.count;
    }
    
    NSUInteger capacity = frameCount;
    if(asyncFramesCount > 0) capacity += (asyncFramesCount + 1);
    
    NSMutableArray *stackTraces = [NSMutableArray arrayWithCapacity:capacity];
    
    unsigned int frameIndex = 0;
    
    for(HMDCrashFrameInfo *eachFrame in frames) {
        
        NSString *currentTrace = frameToString(eachFrame, frameIndex);
        
        if(currentTrace != nil)
            [stackTraces addObject:currentTrace];
        
        frameIndex += 1;
    }
    
    if(asyncFramesCount > 0) {
        NSString *enqueueString =
            [NSString stringWithFormat:@"Enqueued from %@",
             asyncRecord.threadName];
        
        if(enqueueString != nil)
            [stackTraces addObject:enqueueString];
    }
    
    frameIndex = 0;
    
    for(HMDCrashFrameInfo *eachFrame in asyncFrames) {
        
        NSString *currentTrace = frameToString(eachFrame, frameIndex);
        
        if(currentTrace != nil)
            [stackTraces addObject:currentTrace];
        
        frameIndex += 1;
    }
    
    return [stackTraces componentsJoinedByString:@"\n"];
}

static NSString * _Nullable frameToString(HMDCrashFrameInfo *frame,
                                          unsigned int frameIndex) {
    NSString *imageName = @"NULL";
    
    // assume not symbolicated
    DEBUG_ASSERT(!frame.symbolicated);
    
    HMDCrashBinaryImage *image = frame.image;
    
    if(image != nil) {
        NSString *tempName = image.name;
        if(tempName != nil) imageName = tempName;
    }
    
    uint64_t frameAddress  = frame.addr;
    uint64_t imageBase     = image.base;
    uint64_t addressOffset = frameAddress - imageBase;
    
    NSString *trace =
        [NSString stringWithFormat:
        @"%-4u %-30@ 0x%016llx 0x%llx + %llu ((null)) + 0)",
        frameIndex, imageName, frameAddress, imageBase, addressOffset];
    
    return trace;
}

static NSDictionary * _Nullable crashDetailDictionary(HMDCLoadContext * context) {
    DEBUG_ASSERT(context != nil);
    
    HMDCrashLoadModel *model = context.model;
    DEBUG_ASSERT(model != nil);
    
    HMDCrashHeaderInfo *headerInfo = model.headerInfo;
    
    NSMutableDictionary *crashDetail = NSMutableDictionary.dictionary;
    [crashDetail hmd_setObject:headerInfo.typeStr forKey:@"type"];
    [crashDetail hmd_setObject:headerInfo.name    forKey:@"name"];
    [crashDetail hmd_setObject:headerInfo.reason  forKey:@"reason"];
    
    HMDCrashType crashType = headerInfo.crashType;
    
    if(crashType == HMDCrashTypeMachException) {
        NSString *faultAddr, *machCode, *machSubcode;
        
        faultAddr   = [NSString stringWithFormat:@"%#018llx", headerInfo.faultAddr];
        machCode    = [NSString stringWithFormat:@"%#018llx", headerInfo.mach_code];
        machSubcode = [NSString stringWithFormat:@"%#018llx", headerInfo.mach_subcode];
        
        [crashDetail hmd_setObject:faultAddr   forKey:@"fault_address"];
        [crashDetail hmd_setObject:machCode    forKey:@"mach_code"];
        [crashDetail hmd_setObject:machSubcode forKey:@"mach_subcode"];
        
    } else if(crashType == HMDCrashTypeFatalSignal) {
        NSString *faultAddr;
        faultAddr = [NSString stringWithFormat:@"%#018llx", headerInfo.faultAddr];
        
        [crashDetail hmd_setObject:faultAddr             forKey:@"fault_address"];
        [crashDetail hmd_setObject:@(headerInfo.signum)  forKey:@"mach_code"];
        [crashDetail hmd_setObject:@(headerInfo.sigcode) forKey:@"mach_subcode"];
    }
    
    return crashDetail;
}
