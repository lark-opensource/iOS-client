//
//  HMDCrashDirectory.m
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/9.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#include <string.h>
#include <stdatomic.h>
#include "pthread_extended.h"
#import "HMDCrashDirectory.h"
#import "HMDCrashDirectory+Private.h"
#import "HMDCrashHeader.h"
#include "pthread_extended.h"
#include "HMDCrashDirectory_LowLevel.h"
#import "HMDCrashSDKLog.h"
#include "hmd_crash_safe_tool.h"
#import "HMDCrashOnceCatch.h"
#import "HMDCrashAppGroupURL.h"
#import "HMDFileTool.h"
#include "HMDMacro.h"
#import "HMDCrashDirectory+Path.h"
#if !SIMPLIFYEXTENSION
#import "HMDCrashLoadSync_LowLevel.h"
#endif

#pragma mark urgent flag

/// urgent flag is used when urgent condtion, more than three pending crash processing
static atomic_bool urgentFlag;

#pragma mark active access mtx

static BOOL active_directory_has_exceptionFile = NO;

@implementation HMDCrashDirectory

+ (void)setup {
    [HMDCrashDirectory setupUUID];
    [HMDCrashDirectory setupDirectory];
    [HMDCrashDirectory setupCurrentFolder];
}

#pragma mark - UUID

static NSString *UUID;

+ (void)setupUUID {
    UUID = [NSUUID UUID].UUIDString;
    if (UUID.length == 0) {
        UUID = [NSString stringWithFormat:@"%lld",(long long)([NSDate date].timeIntervalSince1970 * 1000)];
    }
}

+ (NSString *)UUID {
    return UUID;
}

#pragma mark - Default Directory

static const char * crash_directory = "Library/Heimdallr/CrashCapture";

static NSString *baseDirectory;
static NSString *preparedDirectory;
static NSString *processingDirectory;
static NSString *lastTimeDirectory;
static NSString *activeDirectory;
static NSString *eventDirectory;
static NSString *loadLaunchPendingDirectory;
#if !SIMPLIFYEXTENSION
static BOOL loadLaunchStarted;
#endif

+ (void)setupDirectory {
    
#if !SIMPLIFYEXTENSION
    loadLaunchStarted = HMDCrashLoadSync_started();
#else
    BOOL loadLaunchStarted = NO;
#endif

    baseDirectory = [[NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithUTF8String:crash_directory]] copy];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDirectory; BOOL isExist;
    
    preparedDirectory = [[baseDirectory stringByAppendingPathComponent:@"Prepared"] copy];  // copy is must ⚠️
    isExist = [manager fileExistsAtPath:preparedDirectory isDirectory:&isDirectory];
    if(isExist) {
        if(isDirectory) {
            NSArray<NSString *> *contents = [manager contentsOfDirectoryAtPath:preparedDirectory error:nil];
            if(contents.count > 0) atomic_store_explicit(&urgentFlag, true, memory_order_release);
        } else {
            [manager removeItemAtPath:preparedDirectory error:nil];
            isExist = NO;
        }
    }
    if(!isExist) hmdCheckAndCreateDirectory(preparedDirectory);
        
    processingDirectory = [[baseDirectory stringByAppendingPathComponent:@"Processing"] copy]; // copy is must ⚠️
    isExist = [manager fileExistsAtPath:processingDirectory isDirectory:&isDirectory];
    if(isExist) {
        if(isDirectory) {
            NSArray<NSString *> *processingContent = [manager contentsOfDirectoryAtPath:processingDirectory error:nil];
            if(processingContent.count > 0) atomic_store_explicit(&urgentFlag, true, memory_order_release);
        } else {
            [manager removeItemAtPath:processingDirectory error:nil];
            isExist = NO;
        }
    }
    if(!isExist) hmdCheckAndCreateDirectory(processingDirectory);
    
    eventDirectory = [[baseDirectory stringByAppendingPathComponent:@"Eventlog"] copy];  // copy is must ⚠️
    isExist = [manager fileExistsAtPath:eventDirectory isDirectory:&isDirectory];
    if(isExist) {
        if(!isDirectory) {
            [manager removeItemAtPath:eventDirectory error:nil];
            isExist = NO;
        }
    }
    if(!isExist) hmdCheckAndCreateDirectory(eventDirectory);
    
#if !SIMPLIFYEXTENSION
    // Creating lastTime Directory
    // lastTime Directory is used to store lastTime Environment Data
    // only if it is not consumed by Crash module (because maybe other module need info inside)
    // Action Taken
    // [1] Create folder if not exist
    // [2] Delete previous data inside
    // [3] Move anything in Active to LastTime, if and only if it doesn't have exception file
    
    if(!loadLaunchStarted) {
        lastTimeDirectory = [[baseDirectory stringByAppendingPathComponent:@"LastTime"] copy];
        isExist = [manager fileExistsAtPath:lastTimeDirectory isDirectory:&isDirectory];
        if(isExist) {
            if(isDirectory) {
                NSArray *contents = [manager contentsOfDirectoryAtPath:lastTimeDirectory error:nil];
                for(NSString *content in contents) {
                    NSString *contentPath = [lastTimeDirectory stringByAppendingPathComponent:content];
                    [manager removeItemAtPath:contentPath error:nil];
                }
            } else {
                [manager removeItemAtPath:lastTimeDirectory error:nil];
                isExist = NO;
            }
        }
        if(!isExist) hmdCheckAndCreateDirectory(lastTimeDirectory);
    }
#endif

    
#if SIMPLIFYEXTENSION
        activeDirectory = [[HMDCrashAppGroupURL appGroupCrashFilesURL].resourceSpecifier copy];  // copy is must ⚠️
#else
        activeDirectory = [[baseDirectory stringByAppendingPathComponent:@"Active"] copy];  // copy is must ⚠️
#endif
    
    COND_DEBUG_LOG(loadLaunchStarted, "[CrashKit] load launch started, active directory setup ignored");
    
    if(!loadLaunchStarted) {
        isExist = [manager fileExistsAtPath:activeDirectory isDirectory:&isDirectory];
        if (isExist && !isDirectory) {
            [manager removeItemAtPath:activeDirectory error:nil];
            isExist = NO;
        }
        
        if (isExist) {
            NSArray<NSString *> *content = [manager contentsOfDirectoryAtPath:activeDirectory error:nil];
            __block BOOL detectedExceptionFile = NO;
            [content enumerateObjectsUsingBlock:^(NSString * _Nonnull content, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *contentPath = [activeDirectory stringByAppendingPathComponent:content];
                BOOL dir = NO;
                BOOL exist = [manager fileExistsAtPath:contentPath isDirectory:&dir];
                if(exist) {
                    if(dir) {
                        NSString *exceptionPath = [contentPath stringByAppendingPathComponent:@"exception"];
                        exist = [manager fileExistsAtPath:exceptionPath isDirectory:&dir];
                        if(exist && !dir) {
    #if !SIMPLIFYEXTENSION
                            [manager moveItemAtPath:contentPath toPath:[processingDirectory stringByAppendingPathComponent:content] error:nil];
                            detectedExceptionFile = YES;
    #endif
                        }
                        else {
    #if !SIMPLIFYEXTENSION
                            // instead of delete, we move file to last
                            [manager moveItemAtPath:contentPath toPath:[lastTimeDirectory stringByAppendingPathComponent:content] error:nil];
    #else
                            [manager removeItemAtPath:contentPath error:nil];
    #endif
                        }
                    }
                    else [manager removeItemAtPath:contentPath error:nil];
                }
            }];
            if(detectedExceptionFile) {
                active_directory_has_exceptionFile = YES;
            };
        } else {
            hmdCheckAndCreateDirectory(activeDirectory);
        }
    }
    
    //处理extension监控抓取的crash
#if !SIMPLIFYEXTENSION
    NSString *appGroupActiveDirectory = [[HMDCrashAppGroupURL appGroupCrashFilesURL].resourceSpecifier copy];
    isExist = [manager fileExistsAtPath:appGroupActiveDirectory isDirectory:&isDirectory];
        if (isExist && !isDirectory) {
            [manager removeItemAtPath:appGroupActiveDirectory error:nil];
            isExist = NO;
        }
    
        if (isExist) {
            NSArray<NSString *> *content = [manager contentsOfDirectoryAtPath:appGroupActiveDirectory error:nil];
            [content enumerateObjectsUsingBlock:^(NSString * _Nonnull content, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *contentPath = [appGroupActiveDirectory stringByAppendingPathComponent:content];
                BOOL dir = NO;
                BOOL exist = [manager fileExistsAtPath:contentPath isDirectory:&dir];
                if(exist) {
                    if(dir) {
                        NSString *exceptionPath = [contentPath stringByAppendingPathComponent:@"exception"];
                        exist = [manager fileExistsAtPath:exceptionPath isDirectory:&dir];
                        if(exist && !dir) {
                            [manager moveItemAtPath:contentPath toPath:[processingDirectory stringByAppendingPathComponent:content] error:nil];
                        }
                    } else {
                        [manager removeItemAtPath:contentPath error:nil];
                    }
                }
            }];
        }
#endif
    
    // 处理 LoadPending 抓到的崩溃
    loadLaunchPendingDirectory = [[baseDirectory stringByAppendingPathComponent:@"LoadLaunch/Pending"] copy];
    isExist = [manager fileExistsAtPath:loadLaunchPendingDirectory isDirectory:&isDirectory];
    if (isExist && !isDirectory) {
        [manager removeItemAtPath:loadLaunchPendingDirectory error:nil];
        isExist = NO;
    }
    
    if (isExist) {
        NSArray<NSString *> *contents = [manager contentsOfDirectoryAtPath:loadLaunchPendingDirectory error:nil];
        [contents enumerateObjectsUsingBlock:^(NSString * _Nonnull content, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *contentPath = [loadLaunchPendingDirectory stringByAppendingPathComponent:content];
            BOOL dir = NO;
            BOOL exist = [manager fileExistsAtPath:contentPath isDirectory:&dir];
            if(exist) {
                if(dir) {
                    NSString *exceptionPath = [contentPath stringByAppendingPathComponent:@"exception"];
                    exist = [manager fileExistsAtPath:exceptionPath isDirectory:&dir];
                    if(exist && !dir) {
                        [manager moveItemAtPath:contentPath toPath:[processingDirectory stringByAppendingPathComponent:content] error:nil];
                    } else {
                        [manager removeItemAtPath:contentPath error:nil];
                    }
                } else {
                    [manager removeItemAtPath:contentPath error:nil];
                }
            }
        }];
    }
    
    atomic_thread_fence(memory_order_release);      // push all data to synchronized with each CPU-cores
}

+ (BOOL)lastTimeCrash {
    return active_directory_has_exceptionFile;
};

+ (BOOL)isUrgent { return atomic_load_explicit(&urgentFlag, memory_order_acquire); }

+ (NSString *)baseDirectory { return baseDirectory; }

+ (NSString *)preparedDirectory { return preparedDirectory; }

+ (NSString *)processingDirectory { return processingDirectory; }

+ (NSString *)lastTimeDirectory { return lastTimeDirectory; }

+ (NSString *)activeDirectory { return activeDirectory; }

+ (NSString *)eventDirectory { return eventDirectory; }

#pragma mark - current folder

static NSString *currentDirectory;
static NSString *currentExtendDirectory;

static char vmmap_path[FILENAME_MAX];
static char memory_analyze_path[FILENAME_MAX];
static char exception_tmp_path[FILENAME_MAX];
static char exceptionPath[FILENAME_MAX];
static char crash_extend_path[FILENAME_MAX];
static char fd_info_path[FILENAME_MAX];
static char gwpasan_info_path[FILENAME_MAX];
static char NSHomeDirectory_path[FILENAME_MAX];
static size_t NSHomeDirectory_path_length = 0;
static char dynamic_data_path[FILENAME_MAX];

+ (void)setupCurrentFolder {
#if SIMPLIFYEXTENSION
    BOOL loadLaunchStarted = NO;
#endif
    
#if !SIMPLIFYEXTENSION
    if(loadLaunchStarted) {
        currentDirectory = HMDCrashLoadSync_currentDirectory();
    } else {
        currentDirectory = [[activeDirectory stringByAppendingPathComponent:UUID] copy];
        hmdCheckAndCreateDirectory(currentDirectory);
    }
#else
    currentDirectory = [[activeDirectory stringByAppendingPathComponent:UUID] copy];
    hmdCheckAndCreateDirectory(currentDirectory);
#endif
    
    
    DEBUG_ASSERT(currentDirectory != nil);
    DEBUG_ASSERT([NSFileManager.defaultManager fileExistsAtPath:currentDirectory]);
    
    if(!loadLaunchStarted) {
        NSString *exceptionLocation = [currentDirectory stringByAppendingPathComponent:@"exception"];
        strncpy(exceptionPath, exceptionLocation.UTF8String, FILENAME_MAX - 1);
        exceptionPath[FILENAME_MAX - 1] = '\0';
    } else {
        DEBUG_ASSERT(strcmp([currentDirectory stringByAppendingPathComponent:@"exception"].UTF8String, exceptionPath) == 0);
    }
    
    snprintf(exception_tmp_path, sizeof(exception_tmp_path), "%s.tmp", exceptionPath);
    snprintf(vmmap_path, sizeof(vmmap_path), "%s/vmmap", currentDirectory.UTF8String);
    snprintf(memory_analyze_path, sizeof(memory_analyze_path), "%s/memory", currentDirectory.UTF8String);
    snprintf(dynamic_data_path, sizeof(dynamic_data_path), "%s/dynamic", currentDirectory.UTF8String);
    
    //extend info dir
    currentExtendDirectory = [[currentDirectory stringByAppendingPathComponent:@"Extend"] copy];
    hmdCheckAndCreateDirectory(currentExtendDirectory);
    strncpy(crash_extend_path, currentDirectory.UTF8String, FILENAME_MAX - 1);
    crash_extend_path[FILENAME_MAX - 1] = '\0';
    
    //extend info -- fd
    snprintf(fd_info_path, sizeof(fd_info_path), "%s/fd.txt", currentExtendDirectory.UTF8String);
    snprintf(gwpasan_info_path, sizeof(gwpasan_info_path), "%s/gwpasan.txt", currentExtendDirectory.UTF8String);
    snprintf(NSHomeDirectory_path, sizeof(NSHomeDirectory_path), "/private%s", NSHomeDirectory().UTF8String);
    NSHomeDirectory_path_length = strlen(NSHomeDirectory_path);
}

+ (NSString *)currentDirectory { return currentDirectory; }

+ (BOOL)checkAndMarkLaunchState {
    NSString *launchFilePath = [baseDirectory stringByAppendingPathComponent:@"launch"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:launchFilePath]) {
        SDKLog_warn("launch file exists, launch crash may happened!");
        return YES;
    }
    
    if (!hmdCheckAndCreateDirectory(launchFilePath)) {
        SDKLog_error("launch file create failed!");
    }
    
    return NO;
}

+ (void)removeLaunchState {
    if (catch_thread() > 0) {
        return;
    }
    NSString *launchFilePath = [baseDirectory stringByAppendingPathComponent:@"launch"];
    NSError *error = nil;
    if ([[NSFileManager defaultManager] removeItemAtPath:launchFilePath error:&error]) {
        SDKLog("launch state file removed success!");
    } else {
        SDKLog_error("launch state file removed failed! %s",[error localizedDescription].UTF8String);
    }
}

@end

#pragma mark - Exposed for exception file

// exception written path
const char *_Nonnull HMDCrashDirectory_exceptionPath(void) {
    return exceptionPath;
}

void HMDCrashDirectory_setExceptionPath(const char * _Nonnull pathFromLoadLaunch) {
    if(pathFromLoadLaunch == NULL) DEBUG_RETURN_NONE;
    
    COMPILE_ASSERT(sizeof(exceptionPath) >= 1);
    strncpy(exceptionPath, pathFromLoadLaunch, sizeof(exceptionPath) - 1);
    exceptionPath[sizeof(exceptionPath) - 1] = '\0';
}

// exception temp path
const char *_Nonnull HMDCrashDirectory_exception_tmp_path(void) {
    return exception_tmp_path;
}

const char *_Nonnull HMDCrashDirectory_memory_analyze_path(void) {
    return memory_analyze_path;
}

const char * _Nullable HMDCrashDirectory_vmmap_path(void) {
    return vmmap_path;
}

const char * _Nullable HMDCrashDirectory_extend_path(void) {
    return crash_extend_path;
}

const char * _Nullable HMDCrashDirectory_fd_info_path(void) {
    return fd_info_path;
}

const char * _Nullable HMDCrashDirectory_gwpasan_info_path(void) {
    return gwpasan_info_path;
}

const char * _Nullable HMDCrashDirectory_NSHomeDirectory_path(void) {
    return NSHomeDirectory_path;
}

size_t HMDCrashDirectory_NSHomeDirectory_path_length(void) {
    size_t length = NSHomeDirectory_path_length;
    if(length >= FILENAME_MAX) length = FILENAME_MAX - 1;
    return length;
}

const char * _Nullable HMDCrashDirectory_dynamic_data_path(void) {
    return dynamic_data_path;
}
