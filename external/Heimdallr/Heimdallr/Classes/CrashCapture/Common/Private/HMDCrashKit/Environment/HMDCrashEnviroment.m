//
//  HMDCrashEnviroment.m
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/9.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#include <sys/sysctl.h>
#import <UIKit/UIKit.h>

#import "HMDCrashKit.h"
#import "HMDCrashKit+Internal.h"

#import "HMDCrashEnviroment.h"
#import "HMDCrashDirectory.h"
#import "HMDCrashDirectory+Path.h"
#include "HMDCrashSDKLog.h"
#include "HMDCrashFileBuffer.h"
#include <sys/utsname.h>
#import "NSData+HMDJSON.h"
#import "NSDictionary+HMDJSON.h"
#include <mach-o/arch.h>
#import "HMDCrashException.h"
#import "HMDCrashException_fileDescriptor.h"
#import "HeimdallrUtilities.h"
#import "NSDictionary+HMDSafe.h"
#import "UIApplication+HMDUtility.h"
#if !SIMPLIFYEXTENSION
#import "HMDDiskSpaceDistribution.h"
#import "HMDSessionTracker.h"
#endif
#include "HMDCrashDetect_Private.h"
#include <errno.h>
#import <HMDInfo.h>
#import <HMDInfo+DeviceInfo.h>
#import "hmd_thread_backtrace.h"
#include "HMDCrashRegionFile.h"
#import "HMDCrashEnvironmentBinaryImages.h"

static FileBuffer meta;

@interface HMDCrashEnviroment ()

@property(class, nonatomic, readonly) NSString *kernelOSVersion;

@end

@implementation HMDCrashEnviroment

+ (void)setup {
    [self createFileEnvironment];
    [self writeMetadata];
    [self setupAsyncUtil];
}

+ (void)setupAsyncUtil {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        hmdcrash_init_filename();
    });
}

+ (void)createFileEnvironment {
    NSString *directory = HMDCrashDirectory.currentDirectory;
    NSString *sdk_info_path = [directory stringByAppendingPathComponent:@"sdk_info"];
    NSString *meta_path = [directory stringByAppendingPathComponent:@"meta"];
    
    // SDK Log
    if(!OpenSDK(sdk_info_path.UTF8String)) HMDLog(@"crash sdk log open error!");
        
    // open Meta
    if((meta = hmd_file_open_buffer(meta_path.UTF8String)) == HMDCrashFileBufferInvalid)
        SDKLog_error("open metadata file failed");
    
    // Binary image
    HMDCrashEnvironmentBinaryImages_initWithDirectory(directory);
    HMDCrashEnvironmentBinaryImages_save_async_blocked_mainFile();
    // HMDCrashEnvironmentBinaryImages_save_async_nonBlocked_loadCommandFile();
    HMDCrashEnvironmentBinaryImages_prepare_for_realTimeFile();
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (prepare_exception() == ENOSPC)
        {
#if !SIMPLIFYEXTENSION
            [[HMDDiskSpaceDistribution sharedInstance] getMoreDiskSpaceWithSize:needDiskSpace priority:HMDDiskSpacePriorityCrash usingBlock:^(BOOL * _Nonnull stop, BOOL moreSpace) {
                if (moreSpace) {
                    if (prepare_exception() != ENOSPC) {
                        *stop = YES;
                    }
                }
            }];
#endif
        }
    });
}

#if !SIMPLIFYEXTENSION
+ (HMDCrashMetaData *)currentMetaData {
    NSDictionary *dict = [self metaDict];
    HMDCrashMetaData *meta = [HMDCrashMetaData objectWithDictionary:dict];
    return meta;
}
#endif

+ (NSDictionary *)metaDict
{
    const NXArchInfo* archInfo = NXGetLocalArchInfo();
    const char *arch_name = "";
    if (archInfo && archInfo->name) {
        arch_name = archInfo->name;
    }
    NSString *archName = [NSString stringWithUTF8String:arch_name];
    
    NSString *UUID = HMDCrashDirectory.UUID;
    NSString *processName = NSProcessInfo.processInfo.processName;
    int processID = NSProcessInfo.processInfo.processIdentifier;
    NSString *OSBuildVersion = [self kernelOSVersion];
    unsigned long long physical_memory = NSProcessInfo.processInfo.physicalMemory;
    
    NSString *OSVersion = HeimdallrUtilities.systemVersion;
    NSString *systemName = HeimdallrUtilities.systemName;
    BOOL isMacARM = HeimdallrUtilities.isiOSAppOnMac;
    
    NSString* OSFullVersion = [NSString stringWithFormat:@"%@ %@ (%@)", systemName, OSVersion, OSBuildVersion];
    
    NSString *deviceModel = [[HMDInfo defaultInfo] decivceModel];
    
    NSString *shortVersion = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *bundleVersion = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *bundleID = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    
    NSString *sdkVersion = HMDSharedCrashKit.sdkVersion;
    NSString *commitID = HMDSharedCrashKit.commitID;
    
    unsigned long main_address = hmdbt_get_app_main_addr();

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict hmd_setObject:archName forKey:@"arch"];
    [dict hmd_setObject:UUID forKey:@"uuid"];
    [dict hmd_setObject:processName forKey:@"process_name"];
    [dict hmd_setObject:@(processID) forKey:@"process_id"];
    [dict hmd_setObject:OSFullVersion forKey:@"os_full_version"];
    [dict hmd_setObject:OSVersion forKey:@"os_version"];
    [dict hmd_setObject:OSBuildVersion forKey:@"os_build_version"];
    [dict hmd_setObject:deviceModel forKey:@"device_model"];
    [dict hmd_setObject:shortVersion forKey:@"app_version"];
    [dict hmd_setObject:bundleVersion forKey:@"bundle_version"];
    [dict hmd_setObject:bundleID forKey:@"bundle_id"];
    [dict hmd_setObject:@(physical_memory) forKey:@"physical_memory"];
    
    if ([UIApplication hmd_isAppExtension]) {
        [dict hmd_setObject:@(YES) forKey:@"is_app_extension"];
        [dict hmd_setObject:[UIApplication hmd_appExtensionPointIdentifier] forKey:@"app_extension_type"];
    }
    
    NSTimeInterval initTimeStamp = 0.0;
#if SIMPLIFYEXTENSION
    initTimeStamp = [[NSDate date] timeIntervalSince1970];
#else
    initTimeStamp = [HMDSessionTracker currentSession].timestamp;
#endif
    if (@available(iOS 15.0, *)) {
        [dict hmd_setObject:@(initTimeStamp) forKey:@"start_time"];
    } else {
        pid_t pid = getpid();
        int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, pid };
        struct kinfo_proc proc;
        size_t size = sizeof(proc);
        if (sysctl(mib, 4, &proc, &size, NULL, 0) == 0) {
            NSTimeInterval time = proc.kp_proc.p_starttime.tv_sec + ((CFTimeInterval)proc.kp_proc.p_starttime.tv_usec/1000000);
            [dict hmd_setObject:@(time) forKey:@"start_time"];
        } else {
            [dict hmd_setObject:@(initTimeStamp) forKey:@"start_time"];
        }
    }
    
    [dict hmd_setObject:sdkVersion forKey:@"sdk_version"];
    [dict hmd_setObject:commitID forKey:@"commit_id"];
    [dict hmd_setObject:@(isMacARM) forKey:@"is_mac_arm"];
    [dict hmd_setObject:@(main_address) forKey:@"exception_main_address"];

    return @{@"meta":dict};
}

+ (void)writeMetadata {
    
    NSDictionary *dict = [self metaDict];
    if (dict.count) {
        NSError *error = nil;
        NSData *data = [dict hmd_jsonData:&error];
        if (data) {
            [data enumerateByteRangesUsingBlock:^(const void * _Nonnull bytes, NSRange byteRange, BOOL * _Nonnull stop) {
                hmd_file_write_block(meta, bytes, byteRange.length);
            }];
        }else{
            NSString *errorInfo = error.localizedDescription;
            if (!errorInfo) {
                errorInfo = @"(null)";
            }
            SDKLog_error("data metadata JSON serial failed, error:%s",errorInfo.UTF8String);
        }
    }

    hmd_file_close_buffer(meta);
}

+ (NSString *)kernelOSVersion {
    size_t size;
    int rt = sysctlbyname("kern.osversion", NULL, &size, NULL, 0);
    if(rt != 0 || size == 0) return nil;
    char *raw;
    if((raw = malloc(size)) != NULL) {
        rt = sysctlbyname("kern.osversion", raw, &size, NULL, 0);
        if(rt != 0) {free(raw); return nil;}
        NSString *result = [NSString stringWithUTF8String:raw];
        free(raw);
        return result;
    }
    return nil;
}

@end
