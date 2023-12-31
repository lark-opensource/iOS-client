//
//  HMDCrashlogProcessor.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#import "HMDCrashlogProcessor.h"
#import "HMDCrashlogFormatter.h"
#import "HMDCrashInfo.h"
#import "HMDCrashInfoLoader.h"
#import "HMDCrashDirectory.h"
#import "NSDictionary+HMDJSON.h"
#import "NSData+HMDGzip.h"
#import "HMDUploadHelper.h"
#import "HMDInjectedInfo+UniqueKey.h"
#import "HMDInfo+DeviceInfo.h"
#import "HMDInfo+DeviceEnv.h"
#include <mach/vm_page_size.h>
#import "NSString+HMDJSON.h"
#import "HMDCrashEventLogger.h"
#import "HMDCrashEnviroment.h"
#import <BDDataDecorator/NSData+DataDecorator.h>
#import "HMDNetworkManager.h"
#import "UIApplication+HMDUtility.h"
#include "HMDCrashHeader.h"
#import "HMDNetworkInjector.h"
#import "HMDMemoryUsage.h"
#import "HMDInfo+AutoTestInfo.h"
#import "HMDCrashDirectory+Path.h"
// PrivateServices
#import "HMDServerStateService.h"
#import "HMDZipArchiveService.h"

#define HMD_CRASH_FILE_BOUNDARY @"AaB03x"
#define HMD_CRASH_NEW_LINE [[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]

@interface HMDCrashlogProcessor ()
{
    BOOL _needLastCrash;
    HMDCrashInfo *_latestCrashInfo;
    NSDictionary *_latestPostData;
}
@end

@implementation HMDCrashlogProcessor

- (void)startProcess:(BOOL)needLastCrash
{
    _needLastCrash = needLastCrash;
    
    NSError *error = nil;
    NSString *processingDir = HMDCrashDirectory.processingDirectory;
    NSString *preparedDir = HMDCrashDirectory.preparedDirectory;
    NSArray<NSString *> *dirs;
    //容灾
    if (hmd_drop_all_data(HMDReporterCrash)) {
        dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:preparedDir error:&error];
        [dirs enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *path = [preparedDir stringByAppendingPathComponent:obj];
            BOOL isDirectory = NO;
            if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
                //should never happen!
                return;
            }
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }];
    }
    
    dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:processingDir error:&error];
    [dirs enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @autoreleasepool {
            NSString *path = [processingDir stringByAppendingPathComponent:obj];
            BOOL isDirectory = NO;
            if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
                //should never happen!
                return;
            }
            if (!isDirectory) {
                //should never happen!
                [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                return;
            }
            //容灾
            if (hmd_drop_data(HMDReporterCrash)) {
                [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
            }
            else {
                NSString *outputPath = [preparedDir stringByAppendingFormat:@"/%@",obj];
                if ([self generateCrashlogWithInputDir:path outputPath:outputPath]) {
                    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                }
            }
        }
    }];
    
    if (needLastCrash) {
        if (_latestCrashInfo) {
            HMDCrashReportInfo *crash = [[HMDCrashReportInfo alloc] init];
            if (_latestPostData) {
                crash.memoryUsage = [_latestPostData hmd_doubleForKey:@"memory_usage"];
                crash.freeMemoryUsage = [_latestPostData hmd_doubleForKey:@"free_memory_usage"];
                crash.freeMemoryPercent = [_latestPostData hmd_doubleForKey:@"free_memory_percent"];
                crash.freeDiskUsage = [_latestPostData hmd_doubleForKey:@"free_disk_usage"];
                crash.isLaunchCrash = [_latestPostData hmd_integerForKey:@"is_launch_crash"];
                crash.operationTrace = [_latestPostData hmd_dictForKey:@"operation_trace"];
                crash.filters = [_latestPostData hmd_dictForKey:@"filters"];
                crash.customParams = [_latestPostData hmd_dictForKey:@"custom"];
                _latestPostData = nil;
            }
            crash.isBackground = [_latestCrashInfo.dynamicInfo hmd_integerForKey:@"is_background"];
            crash.access = [_latestCrashInfo.dynamicInfo hmd_stringForKey:@"access"];
            crash.lastScene = [_latestCrashInfo.dynamicInfo hmd_stringForKey:@"last_scene"];
            crash.networkQuality = [_latestCrashInfo.dynamicInfo hmd_integerForKey:@"network_quality"];
            crash.business = [_latestCrashInfo.dynamicInfo hmd_stringForKey:@"business"];
            crash.crashType = _latestCrashInfo.headerInfo.crashType;
            crash.time = _latestCrashInfo.headerInfo.crashTime;
            crash.bundleVersion = _latestCrashInfo.meta.bundleVersion;
            crash.appVersion = _latestCrashInfo.meta.appVersion;
            crash.name = _latestCrashInfo.headerInfo.name;
            crash.reason = _latestCrashInfo.headerInfo.reason;
            crash.sessionID = _latestCrashInfo.meta.UUID;
            crash.crashLog = _latestCrashInfo.crashLog;
            crash.usedVM = _latestCrashInfo.processState.usedVirtualMemory;
            crash.totalVM = _latestCrashInfo.processState.totalVirtualMemory;
            
            self.crashReport = crash;
            _latestCrashInfo = nil;
        }
    }
}

- (BOOL)generateCrashlogWithInputDir:(NSString *)inputDir outputPath:(NSString *)outputPath
{
    HMDCrashInfo *info = [HMDCrashInfoLoader loadCrashInfo:inputDir];
    
    if (_needLastCrash) {
        if (_latestCrashInfo) {
            if (info.headerInfo.crashTime > _latestCrashInfo.headerInfo.crashTime) {
                _latestCrashInfo = info;
            }
        }else{
            _latestCrashInfo = info;
        }
    }

    if (info.fileIOError || info.isCorrupted) {
        [info error:@"error happend! clear files"];
        [HMDCrashEventLogger logCrashEvent:info];
    }
    
    HMDCrashMetaData *meta = info.meta;
    if (!meta) {
        meta = [HMDCrashEnviroment currentMetaData];
        meta.UUID = @"missing";
        [info warn:@"meta is missing, use current meta"];
        info.meta = meta;
    }
    
    if (info.fileIOError || info.isCorrupted) {
        NSString *sdkInfoName = @"sdk_info";
        NSString *sdkInfoFile = [inputDir stringByAppendingPathComponent:sdkInfoName];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isSdkInfoExist = [fileManager fileExistsAtPath:sdkInfoFile];
        NSString *extendDir = [inputDir stringByAppendingPathComponent:@"Extend"];
        BOOL isExist = [fileManager fileExistsAtPath:extendDir];
        if (isSdkInfoExist && isExist) {
            {
                [fileManager moveItemAtPath:sdkInfoFile toPath:[extendDir stringByAppendingPathComponent:sdkInfoName]  error:nil];
            }
        }
    }
    
    NSString *zipPath = [self zipCrashExtendWithInputDir:inputDir];
    if (zipPath) info.hasDump = YES;
    if (info.hasDump) {
        NSArray *files = [self crashExtendFilesWithInputDir:inputDir];
        for (NSString *fileName in files) {
            if ([fileName isEqualToString:@"gwpasan.txt"]) {
                info.hasGWPAsan = YES;
                break;
            }
        }
    }

    NSDictionary *postData = [self postDataWithCrashInfo:info];
    
    if (_needLastCrash) {
        if (_latestPostData) {
            if ([postData hmd_integerForKey:@"timestamp"] > [_latestPostData hmd_integerForKey:@"timestamp"]) {
                _latestPostData = postData;
            }
        } else {
            _latestPostData = postData;
        }
    }
    NSError *error = nil;
    NSData *crashData = [postData hmd_jsonData:&error];
    if (!crashData || error) {
        [info error:@"post data convert to json error:%@ userinfo:%@",error.localizedDescription,error.userInfo];
    }
    if (crashData) {
        NSMutableData *data = [[NSMutableData alloc] init];
        [data appendData:[[NSString stringWithFormat:@"--%@", HMD_CRASH_FILE_BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
        [data appendData:HMD_CRASH_NEW_LINE];
        [data appendData:[@"Content-Disposition: form-data; name=\"json\"" dataUsingEncoding:NSUTF8StringEncoding]];
        [data appendData:HMD_CRASH_NEW_LINE];
        [data appendData:[@"Content-Type: text/plain; charset=UTF-8" dataUsingEncoding:NSUTF8StringEncoding]];
        [data appendData:HMD_CRASH_NEW_LINE];
        [data appendData:HMD_CRASH_NEW_LINE];
        NSData * encryptedData = nil;
        BOOL isNeedEncrypt = self.needEncrypt;
        if (isNeedEncrypt) {
            HMDNetEncryptBlock encryptBlock = [[HMDNetworkInjector sharedInstance] encryptBlock];
            if (encryptBlock) {
                encryptedData = encryptBlock(crashData);
            } else {
                encryptedData = [crashData bd_dataByDecorated];
            }
        }
        [data appendData:encryptedData?:crashData];

        //add extend info for crash
        if (zipPath) {
            [data appendData:HMD_CRASH_NEW_LINE];
            [data appendData:[[NSString stringWithFormat:@"--%@", HMD_CRASH_FILE_BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
            [data appendData:HMD_CRASH_NEW_LINE];
            [data appendData:[@"Content-Disposition: form-data; name=\"file\"; filename=\"file\"" dataUsingEncoding:NSUTF8StringEncoding]];
            [data appendData:HMD_CRASH_NEW_LINE];
            [data appendData:[@"Content-Transfer-Encoding: binary" dataUsingEncoding:NSUTF8StringEncoding]];
            [data appendData:HMD_CRASH_NEW_LINE];
            [data appendData:HMD_CRASH_NEW_LINE];

            [data appendData:[NSData dataWithContentsOfFile:zipPath]];
        }

        [data appendData:HMD_CRASH_NEW_LINE];
        [data appendData:[[NSString stringWithFormat:@"--%@--",HMD_CRASH_FILE_BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
        NSData * gzipData = [data hmd_gzipDeflate];


        NSString *ext_gz = @"g";
        NSString *ext_encrypt = @"e";
        NSString *ext_dump = @"d";
        NSString *finaPath = outputPath;
        
        if (encryptedData && gzipData) {
            finaPath = [[finaPath stringByAppendingPathExtension:ext_gz] stringByAppendingPathExtension:ext_encrypt];
        }else if (encryptedData){
            finaPath = [finaPath stringByAppendingPathExtension:ext_encrypt];
        }else if (gzipData){
            finaPath = [finaPath stringByAppendingPathExtension:ext_gz];
        }
        if (zipPath) {
            finaPath = [finaPath stringByAppendingPathExtension:ext_dump];
        }

        [[NSFileManager defaultManager] removeItemAtPath:finaPath error:nil];
        
        NSData *finalData = gzipData?:data;
        BOOL dataWriteSuccess = [finalData writeToFile:finaPath options:NSDataWritingAtomic error:&error];
        if (!dataWriteSuccess) {
            [info error:@"final data write disk error:%@,%@",error.localizedDescription,error.userInfo];
        }else{
            [info info:@"final data write success"];
        }
        
        [HMDCrashEventLogger logCrashEvent:info];

        return dataWriteSuccess;
    }
    
    return NO;
}

- (NSArray *)crashExtendFilesWithInputDir:(NSString *)inputDir {
    NSString *extendDir = [inputDir stringByAppendingPathComponent:@"Extend"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExist = [fileManager fileExistsAtPath:extendDir];
    if (isExist) {
        return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:extendDir error:nil];
    }
    return nil;
}

- (NSString *)zipCrashExtendWithInputDir:(NSString *)inputDir {
    NSError *error = nil;
    NSString *extendDir = [inputDir stringByAppendingPathComponent:@"Extend"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExist = [fileManager fileExistsAtPath:extendDir];
    if (isExist) {
        NSString *zipFile = [extendDir stringByAppendingPathComponent:@"extend.zip"];
        BOOL isZipExist = [fileManager fileExistsAtPath:zipFile];
        if (isZipExist) {
            return zipFile;
        }
        NSArray<NSString *> *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:extendDir error:&error];
        if (files.count == 0) {
            return nil;
        }
        NSMutableArray *extendFiles = [NSMutableArray new];

        [files enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *extendFile = [extendDir stringByAppendingFormat:@"/%@", obj];
            [extendFiles addObject:extendFile];
        }];
#ifdef DEBUG
        NSString *sdkInfoFile = [inputDir stringByAppendingPathComponent:@"sdk_info"];
        BOOL isSdkInfoExist = [fileManager fileExistsAtPath:sdkInfoFile];
        if (isSdkInfoExist) {
            [extendFiles addObject:sdkInfoFile];
        }
#endif
        if (extendFiles.count > 0) {
            BOOL isZip = [HMDZipArchiveService createZipFileAtPath:zipFile withFilesAtPaths:[extendFiles copy]];
            if (isZip) {
                return zipFile;
            }
        }
    }

    return nil;
}

- (NSArray *)registerAnalysis:(HMDCrashInfo *)info {
    NSMutableArray *regDictArray = [NSMutableArray array];
    [info.registerAnalysis enumerateObjectsUsingBlock:^(HMDCrashRegisterAnalysis * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [regDictArray hmd_addObject:obj.postDict];
    }];
    return regDictArray;
}

- (NSArray *)stackAnalysis:(HMDCrashInfo *)info {
    NSMutableArray *stackDictArray = [NSMutableArray array];
    [info.stackAnalysis enumerateObjectsUsingBlock:^(HMDCrashStackAnalysis * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [stackDictArray hmd_addObject:obj.postDict];
    }];
    return stackDictArray;
}

- (NSArray *)regionDicts:(HMDCrashInfo *)info {
    NSMutableArray *dicts = [NSMutableArray array];
    [info.regions enumerateObjectsUsingBlock:^(HMDCrashVMRegion * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [dicts hmd_addObject:obj.postDict];
    }];
    return dicts;
}

- (NSDictionary *)crashDetail:(HMDCrashInfo *)info {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict hmd_setObject:info.headerInfo.typeStr forKey:@"type"];
    [dict hmd_setObject:info.headerInfo.name forKey:@"name"];
    [dict hmd_setObject:info.headerInfo.reason forKey:@"reason"];
    if (info.headerInfo.crashType == HMDCrashTypeMachException) {
        [dict hmd_setObject:[NSString stringWithFormat:@"0x%018llx",info.headerInfo.faultAddr] forKey:@"fault_address"];
        [dict hmd_setObject:[NSString stringWithFormat:@"0x%018llx",info.headerInfo.mach_code] forKey:@"mach_code"];
        [dict hmd_setObject:[NSString stringWithFormat:@"0x%018llx",info.headerInfo.mach_subcode] forKey:@"mach_subcode"];
    } else if (info.headerInfo.crashType == HMDCrashTypeFatalSignal) {
        [dict hmd_setObject:[NSString stringWithFormat:@"0x%018llx",info.headerInfo.faultAddr] forKey:@"fault_address"];
        [dict hmd_setObject:@(info.headerInfo.signum) forKey:@"signum"];
        [dict hmd_setObject:@(info.headerInfo.sigcode) forKey:@"sigcode"];
    }
    if (info.runtimeInfo.selector.length > 0) {
        [dict hmd_setObject:info.runtimeInfo.selector forKey:@"objc_selector"];
    }
    if (info.runtimeInfo.crashInfos.count > 0) {
        [info.runtimeInfo.crashInfos enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:NSString.class]) {
                [dict hmd_setObject:obj forKey:[NSString stringWithFormat:@"crash_info_%lu",(unsigned long)idx]];
            }
        }];
    }
    NSMutableString * errorStr = [NSMutableString string];
    if (info.currentlyUsedImages.count == 0) {
        [errorStr appendString:@"Lossing BinaryImage Info! "];
    }
    __block BOOL hasCrashedThread = NO;
    [info.threads enumerateObjectsUsingBlock:^(HMDCrashThreadInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.crashed) {
            hasCrashedThread = YES;
            *stop = YES;
        }
    }];
    if (hasCrashedThread == NO) {
        [errorStr appendString:@"Lossing Crashed Thread Info! "];
    }
    if (errorStr.length > 0) {
        [dict hmd_setSafeObject:errorStr forKey:@"crash_file_error_info"];
    }
    return dict;
}

- (NSDictionary *)postDataWithCrashInfo:(HMDCrashInfo *)info
{
    NSString *crashLog = [HMDCrashlogFormatter formatedLogWithCrashInfo:info];
    info.crashLog = crashLog;
    
    HMDCrashMetaData *meta = info.meta;
    
    long long timestamp = 0;
    if (info.headerInfo.crashTime) {
        timestamp = info.headerInfo.crashTime;
    }
    else if (info.exceptionFileModificationDate) {
        timestamp = [info.exceptionFileModificationDate timeIntervalSince1970];
    }
    else {
        timestamp = [[NSDate date] timeIntervalSince1970];
    }
    timestamp = timestamp * 1000;
    
    NSMutableDictionary *postData = [NSMutableDictionary dictionary];
    [postData hmd_setObject:@(timestamp) forKey:@"timestamp"];
    [postData hmd_setObject:crashLog forKey:@"data"];
    [postData hmd_setObject:meta.UUID forKey:@"session_id"];
    if (meta.isAppExtension) {
        [postData hmd_setObject:@"extension" forKey:@"event_type"];
        [postData hmd_setObject:meta.appExtensionType forKey:@"extension_type"];
    } else {
        [postData hmd_setObject:@"crash" forKey:@"event_type"];
    }
    
    [postData hmd_setObject:meta.appVersion forKey:@"app_version"];
    [postData hmd_setObject:meta.bundleVersion forKey:@"update_version_code"];
    
    NSArray *stackAnalysis = [self stackAnalysis:info];
    if (stackAnalysis.count) {
        [postData hmd_setObject:stackAnalysis forKey:@"stack_analysis"];
    }
    
    NSArray *registerAnalysis = [self registerAnalysis:info];
    if (registerAnalysis.count) {
        [postData hmd_setObject:registerAnalysis forKey:@"register_analysis"];
    }
    
    NSArray *regionDicts = [self regionDicts:info];
    if (regionDicts.count) {
        [postData hmd_setObject:regionDicts forKey:@"vmmap"];
    }
    
    NSDictionary *crashDetail = [self crashDetail:info];
    if (crashDetail.count) {
        [postData hmd_setObject:crashDetail forKey:@"crash_detail"];
    }
    
    double memoryUsage = info.processState.appUsedBytes/HMD_MB;
    [postData hmd_setObject:@(memoryUsage) forKey:@"memory_usage"];

    double freeMemoryBytes = info.processState.freeBytes;
    [postData hmd_setObject:@(hmd_calculateMemorySizeLevel(freeMemoryBytes)) forKey:HMD_Free_Memory_Key];
    
    u_int64_t virtualMemory = info.processState.usedVirtualMemory;
    [postData hmd_setObject:@(virtualMemory) forKey:@"used_virtual_memory"];
    
    u_int64_t totalVirtualMemory = info.processState.totalVirtualMemory;
    [postData hmd_setObject:@(totalVirtualMemory) forKey:@"total_virtual_memory"];

    NSInteger freeDisk = (NSInteger)(ceil(info.storage.free/(300 * HMD_MB)));
    [postData hmd_setObject:@(freeDisk) forKey:@"d_zoom_free"];
    
    double free_memory_percent = 0;
    if (info.processState.totalBytes > 0) {
        free_memory_percent = freeMemoryBytes / info.processState.totalBytes;
    } else if (meta.physicalMemory > 0) {
        free_memory_percent = freeMemoryBytes / meta.physicalMemory;
    }
    free_memory_percent = (int)(free_memory_percent*100)/100.0;
    [postData hmd_setObject:@(free_memory_percent) forKey:HMD_Free_Memory_Percent_key];
    
    NSTimeInterval inAppTime = 0;
    if (info.headerInfo.crashTime) {
        inAppTime = info.headerInfo.crashTime - meta.startTime;
    }
    [postData hmd_setObject:@(inAppTime) forKey:@"inapp_time"];
    
    NSTimeInterval launchCrashThreshold = self.launchCrashThreshold;
    if (launchCrashThreshold == 0) {
        launchCrashThreshold = 8;
    }
    [postData hmd_setObject:@(inAppTime<launchCrashThreshold ? 1 : 0) forKey:@"is_launch_crash"];
    
    [postData hmd_setObject:meta.sdkVersion forKey:@"sdk_version"];
    [postData hmd_setObject:meta.osVersion forKey:@"os_version"];
    [postData hmd_setObject:@(meta.isMacARM) forKey:@"is_mac_arm"];
    BOOL isJailBroken = info.isEnvAbnormal || [HMDInfo defaultInfo].isEnvAbnormal;
    [postData hmd_setObject:@(isJailBroken) forKey:@"is_env_abnormal"];
    [postData hmd_setObject:@(info.hasDump) forKey:@"has_dump"];
    [postData hmd_setObject:@(meta.exceptionMainAddress) forKey:@"exception_main_address"];

    {
        NSMutableDictionary *dynamicInfo = [NSMutableDictionary dictionary];
        if (info.dynamicInfo) {
            [dynamicInfo addEntriesFromDictionary:info.dynamicInfo];
        }
        NSString *custom = [dynamicInfo hmd_stringForKey:@"custom"];
        NSString *filters = [dynamicInfo hmd_stringForKey:@"filters"];
        NSString *customAddressAnalysis = [dynamicInfo hmd_stringForKey:@"custom_address_analysis"];
        NSArray *customAddressAnalysisArr = [customAddressAnalysis hmd_jsonObject];
        NSDictionary *filterDict = [filters hmd_jsonDict];
        NSMutableDictionary *customDict = [NSMutableDictionary dictionary];
        NSDictionary *customJSONDict = [custom hmd_jsonDict];
        if (customJSONDict) {
            [customDict addEntriesFromDictionary:customJSONDict];
        }
        
        if (info.extraDynamicInfo.count) {
            [customDict addEntriesFromDictionary:info.extraDynamicInfo];
        }
        
        if (info.runtimeInfo.selector.length > 0) {
            [customDict hmd_setObject:info.runtimeInfo.selector forKey:@"objc_selector"];
        }
        if (info.runtimeInfo.crashInfos.count > 0) {
            [info.runtimeInfo.crashInfos enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:NSString.class]) {
                    [customDict hmd_setObject:obj forKey:[NSString stringWithFormat:@"crash_info_%lu",(unsigned long)idx]];
                }
            }];
        }
                
        NSString *userID = [dynamicInfo hmd_stringForKey:@"userID"];
        NSString *scopedUserID = [dynamicInfo hmd_stringForKey:@"scopedUserID"];
        [dynamicInfo removeObjectForKey:@"userID"];
        [dynamicInfo removeObjectForKey:@"scopedUserID"];
        NSString *userName = [dynamicInfo hmd_stringForKey:@"userName"];
        [dynamicInfo removeObjectForKey:@"userName"];
        NSString *email = [dynamicInfo hmd_stringForKey:@"email"];
        [dynamicInfo removeObjectForKey:@"email"];
        [customDict hmd_setObject:userID forKey:@"user_id"];
        [customDict hmd_setObject:scopedUserID forKey:@"scoped_user_id"];
        [customDict hmd_setObject:userName forKey:@"user_name"];
        [customDict hmd_setObject:email forKey:@"email"];
        //vids
        [customDict hmd_setObject:info.vids forKey:@"vids"];

        NSString *operationTraceString = [dynamicInfo hmd_stringForKey:@"operation_trace"];
        [dynamicInfo removeObjectForKey:@"operation_trace"];
        if (operationTraceString.length > 0) {
            NSDictionary *operationTraceDict = [operationTraceString hmd_jsonDict];
            [dynamicInfo hmd_setObject:operationTraceDict forKey:@"operation_trace"];
        }
        [dynamicInfo hmd_setObject:customDict forKey:@"custom"];
        
        NSMutableDictionary *tmpfilterDic = filterDict ? filterDict.mutableCopy:[NSMutableDictionary new];
        // GWPAsan
        if (info.hasGWPAsan) {
            [tmpfilterDic setObject:@"1" forKey:@"GWPASan"];
        }
        // atuoTestInfo
        if ([HMDInfo isBytest]) {
            NSDictionary *automationTestInfoDic = [[HMDInfo defaultInfo] automationTestInfoDic];
            if ([automationTestInfoDic hmd_hasKey:@"automation_test_type"]) {
                [tmpfilterDic setObject:[automationTestInfoDic hmd_stringForKey:@"automation_test_type"] forKey:@"automation_test_type"];
            }
        }
        if (stackAnalysis.count) {
            [tmpfilterDic hmd_setObject:@"1" forKey:@"hmd_stack_analysis"];
        }
        if (registerAnalysis.count) {
            [tmpfilterDic hmd_setObject:@"1" forKey:@"hmd_register_analysis"];
        }
        if (regionDicts.count) {
            [tmpfilterDic hmd_setObject:@"1" forKey:@"hmd_vmmap"];
        }
        if (crashDetail.count) {
            [tmpfilterDic hmd_setObject:@"1" forKey:@"hmd_crash_detail"];
        }

        [tmpfilterDic hmd_setObject:@(totalVirtualMemory-virtualMemory).stringValue forKey:@"available_virtual_memory"];
        
        
        [dynamicInfo hmd_setObject:[tmpfilterDic copy] forKey:@"filters"];
        if (customAddressAnalysisArr && [customAddressAnalysisArr isKindOfClass:NSArray.class] && customAddressAnalysisArr.count > 0) {
            [dynamicInfo hmd_setObject:customAddressAnalysisArr forKey:@"custom_address_analysis"];
        }
        int is_background = [dynamicInfo hmd_intForKey:@"is_background"];
        [dynamicInfo hmd_setObject:@(is_background) forKey:@"is_background"];
        int is_exit = [dynamicInfo hmd_intForKey:@"is_exit"];
        [dynamicInfo hmd_setObject:@(is_exit) forKey:@"is_exit"];
        [postData addEntriesFromDictionary:dynamicInfo];
    }

    NSMutableDictionary *header = [NSMutableDictionary dictionaryWithDictionary:[HMDUploadHelper sharedInstance].headerInfo];
    [header hmd_setObject:meta.appVersion forKey:@"app_version"];
    [header hmd_setObject:meta.bundleVersion forKey:@"update_version_code"];
    [header hmd_setObject:@(isJailBroken) forKey:@"is_env_abnormal"];
    
    [[HMDInjectedInfo defaultInfo] confUniqueKeyForData:header timestamp:timestamp eventType:@"crash"];
    
    [postData setValue:[header copy] forKey:@"header"];
    [postData setValue:[info.gameScriptStack copy] forKey:@"game_script_stack"];
    return postData;
}

@end
