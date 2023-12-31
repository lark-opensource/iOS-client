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
#import "HMDCrashDebugAssert.h"
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
static NSString *activeDirectory;
static NSString *eventDirectory;

+ (void)setupDirectory {

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

#if SIMPLIFYEXTENSION
    activeDirectory = [[HMDCrashAppGroupURL appGroupCrashFilesURL].resourceSpecifier copy];  // copy is must ⚠️
#else
    activeDirectory = [[baseDirectory stringByAppendingPathComponent:@"Active"] copy];  // copy is must ⚠️
#endif
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
                    else [manager removeItemAtPath:contentPath error:nil];
                }
                else [manager removeItemAtPath:contentPath error:nil];
            }
        }];
        if(detectedExceptionFile && content.count == 1) {
            active_directory_has_exceptionFile = YES;
        };
    } else {
        hmdCheckAndCreateDirectory(activeDirectory);
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
        } else {
            hmdCheckAndCreateDirectory(activeDirectory);
        }
#endif
    atomic_thread_fence(memory_order_release);      // push all data to synchronized with each CPU-cores
}

+ (BOOL)lastTimeCrash {
    return active_directory_has_exceptionFile;
};

+ (BOOL)isUrgent { return atomic_load_explicit(&urgentFlag, memory_order_acquire); }

+ (NSString *)baseDirectory { return baseDirectory; }

+ (NSString *)preparedDirectory { return preparedDirectory; }

+ (NSString *)processingDirectory { return processingDirectory; }

+ (NSString *)activeDirectory { return activeDirectory; }

+ (NSString *)eventDirectory { return eventDirectory; }

#pragma mark - current folder

static NSString *currentDirectory;
static NSString *currentExtendDirectory;

static char vmmap_path[FILENAME_MAX];
static char memory_analyze_path[FILENAME_MAX];
static char exception_tmp_path[FILENAME_MAX];
static char exceptionPath[FILENAME_MAX];
static char crash_info_path[FILENAME_MAX];
static char crash_extend_path[FILENAME_MAX];
static char fd_info_path[FILENAME_MAX];
static char gwpasan_info_path[FILENAME_MAX];
static char home_path[FILENAME_MAX];

+ (void)setupCurrentFolder {
    DEBUG_ONCE
    currentDirectory = [[activeDirectory stringByAppendingPathComponent:UUID] copy];
    hmdCheckAndCreateDirectory(currentDirectory);
    NSString *exceptionLocation = [currentDirectory stringByAppendingPathComponent:@"exception"];
    strncpy(exceptionPath, exceptionLocation.UTF8String, FILENAME_MAX - 1);
    exceptionPath[FILENAME_MAX - 1] = '\0';
    snprintf(exception_tmp_path, sizeof(exception_tmp_path), "%s.tmp", exceptionPath);
    snprintf(vmmap_path, sizeof(vmmap_path), "%s/vmmap", currentDirectory.UTF8String);
    snprintf(memory_analyze_path, sizeof(memory_analyze_path), "%s/memory", currentDirectory.UTF8String);
    snprintf(crash_info_path, sizeof(crash_info_path), "%s/crashinfo", currentDirectory.UTF8String);
    
    //extend info dir
    currentExtendDirectory = [[currentDirectory stringByAppendingPathComponent:@"Extend"] copy];
    hmdCheckAndCreateDirectory(currentExtendDirectory);
    strncpy(crash_extend_path, currentDirectory.UTF8String, FILENAME_MAX - 1);
    crash_extend_path[FILENAME_MAX - 1] = '\0';
    //extend info -- fd
    snprintf(fd_info_path, sizeof(fd_info_path), "%s/fd.txt", currentExtendDirectory.UTF8String);
    snprintf(gwpasan_info_path, sizeof(gwpasan_info_path), "%s/gwpasan.txt", currentExtendDirectory.UTF8String);
    snprintf(home_path, sizeof(home_path), "/private%s", NSHomeDirectory().UTF8String);
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

const char *_Nonnull HMDCrashDirectory_exceptionPath(void) {
    return exceptionPath;
}

const char * _Nullable HMDCrashDirectory_homePath(void) {
    return hmd_home_path;
}

const char *_Nonnull HMDCrashDirectory_exception_tmp_path(void) {
    return exception_tmp_path;
}

const char *_Nonnull HMDCrashDirectory_memory_analyze_path(void) {
    return memory_analyze_path;
}

const char * _Nullable HMDCrashDirectory_vmmap_path(void) {
    return vmmap_path;
}

const char * _Nullable HMDCrashDirectory_crash_info_path(void) {
    return crash_info_path;
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

const char * _Nullable HMDApplication_home_path(void) {
    return home_path;
}

