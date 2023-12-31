//
//  TTVideoEngineUtilPrivate.m
//  TTVideoEngine
//
//  Created by 黄清 on 2019/7/22.
//

#import <TTPlayerSDK/TTPlayerDef.h>
#import "TTVideoEngineUtilPrivate.h"
#import "TTVideoEnginePlayerDefinePrivate.h"
#include <sys/stat.h>
#include <sys/mount.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <mach/mach.h>
#import <CommonCrypto/CommonDigest.h>
#import <TTPlayerSDK/ttvideodec.h>
#import "TTVideoEngineEnvConfig.h"
#import "NSDictionary+TTVideoEngine.h"
#import "TTVideoNetUtils.h"
#import "TTVideoEngineEventLoggerProtocol.h"


static dispatch_queue_t taskQueue;

BOOL isTTVideoEngineLogEnabled = NO;

BOOL isIgnoreAudioInterruption = NO;

BOOL isVideoEngineHTTPDNSFirst = NO;

NSArray *sVideoEngineDnsTypes = nil;

NSArray *sVideoEngineQualityInfos = nil;

NSInteger g_TTVideoEngineLogFlag = TTVideoEngineLogFlagDefault;

BOOL g_FocusUseHttpsForApiFetch = YES;

BOOL g_IgnoreMTLDeviceCheck = NO;

BOOL sEnableGlobalMuteFeature = NO;
NSMutableDictionary *sGlobalMuteDic = nil;
NSMutableArray *sGlobalKeyArray = nil;

NSString *gABRPreloadJsonParams = nil;
NSString *gABRStartupJsonParams = nil;
NSString *gABRFlowJsonParams = nil;

id<TTVideoEngineLogDelegate> g_TTVideoEngineLogDelegate = nil;

dispatch_queue_t TTVideoEngineGetQueue() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        taskQueue = dispatch_queue_create("vcloud.engine.task.queue", DISPATCH_QUEUE_SERIAL);
    });
    return taskQueue;
}

BOOL TTVideoIsMainQueue() {
    static const void* mainQueueKey = &mainQueueKey;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_set_specific(dispatch_get_main_queue(), mainQueueKey, (void *)mainQueueKey, nil);
    });
    return dispatch_get_specific(mainQueueKey) == mainQueueKey;
}

void TTVideoRunOnMainQueue(dispatch_block_t block, BOOL sync) {
    if ([NSThread isMainThread]) {
        block();
    }
    else {
        if (sync) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                block();
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                block();
            });
        }
    }
}

NSString *TTVideoEngineGetStrategyName(TTVideoEngineRetryStrategy strategy) {
    switch (strategy) {
        case TTVideoEngineRetryStrategyNone:
            return @"TTVideoEngineRetryStrategyNone";
        case TTVideoEngineRetryStrategyFetchInfo:
            return @"TTVideoEngineRetryStrategyFetchInfo";
        case TTVideoEngineRetryStrategyChangeURL:
            return @"TTVideoEngineRetryStrategyChangeURL";
        case TTVideoEngineRetryStrategyRestartPlayer:
            return @"TTVideoEngineRetryStrategyRestartPlayer";
        default:
            break;
    }
    return @"";
}

int64_t TTVideoEngineGetLocalFileSize(NSString* filePath){
    const char *cpath = [filePath fileSystemRepresentation];
    struct stat statbuf;
    if (cpath && stat(cpath, &statbuf) == 0) {
        return (int64_t)statbuf.st_size;
    }
    return 0L;
}

int64_t TTVideoEngineGetDiskFreeSpecSize(NSString *dir) {
    struct statfs buf;
    int64_t freeSpace = 0;
    if(statfs(dir.UTF8String, &buf) >= 0){
        freeSpace = (int64_t)(buf.f_bsize * buf.f_bfree);
    }
    return freeSpace > 0 ? freeSpace : 0;
}

int64_t TTVideoEngineGetFreeSpace(void) {
    int64_t temSize = 0;
    NSError *error = nil;
    NSDictionary *infoDict = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (infoDict) {
        temSize = [[infoDict objectForKey:NSFileSystemFreeSize] longLongValue];
    }
    return temSize;
}

BOOL TTVideoEngineCheckHostNameIsIP(NSString *hostname) {
    if (hostname == nil || hostname.length < 1) {
        return NO;
    }
    NSURL *urlStr = [NSURL URLWithString:hostname];
    NSString  *ipRegEx =@"([1-9]|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])(\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])){3}";
    NSPredicate *ipTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", ipRegEx];
    BOOL isIP = [ipTest evaluateWithObject:urlStr.host];
    if (isIP) {
        return isIP;
    }
    
    NSRange lbracket = [hostname rangeOfString:@"["];
    NSRange rbracket = [hostname rangeOfString:@"]"];
    if (lbracket.location != NSNotFound && rbracket.location != NSNotFound && lbracket.location < rbracket.location) {
        NSRange range = [hostname rangeOfString:@":"];
        if (range.location != NSNotFound && range.location > lbracket.location && range.location < rbracket.location) {
            return YES;
        }
    }
    return NO;
}


NSString *TTVideoEngineGetDescrptKey(NSString *spade) {
    //
    if (spade == nil || spade.length < 1) {
        return nil;
    }
    //
    NSData *data = [[NSData alloc] initWithBase64EncodedString:spade options:0];
    if (data == nil) {
        return nil;
    }
    char *method = NULL;
    char *key = NULL;
    decodeMethodAndKey((const char *)[data bytes], (int)[data length], &key, &method);
    if (key == NULL) {
        return nil;
    }
    NSString *descrypKey = [NSString stringWithUTF8String:key];
    free(key);
    free(method);
    return descrypKey;
}

NSString *TTVideoEngineBuildBoeUrl(NSString *url) {
    NSString *boeHost = TTVideoEngineEnvConfig.boeHost;
    if (boeHost == nil || boeHost.length < 1) {
        return url;
    }
    //
    if (url == nil || url.length < 1) {
        return nil;
    }
    //
    if([url hasPrefix:@"https"]){
        url = [url stringByReplacingOccurrencesOfString:@"https" withString:@"http"];
    }
    NSRange httpRange = [url rangeOfString:@"http"];
    if (httpRange.location == 0) {
        BOOL isIpAddress = TTVideoEngineCheckHostNameIsIP(url);
        BOOL isBoe = [url containsString:boeHost];
        if (!isIpAddress && !isBoe) {
            NSURL *urlStr = [NSURL URLWithString:url];
            NSMutableString *hostAppend =  [[NSMutableString alloc]init];
            [hostAppend appendString:urlStr.host];
            [hostAppend appendString:boeHost];
            url = [url stringByReplacingOccurrencesOfString:urlStr.host withString:hostAppend];
        }
    }
    return url;
}

void TTVideoEngineCustomLog(const char *info, int level) {
    if (info != NULL) {
        @autoreleasepool {
            if (isTTVideoEngineLogEnabled || (g_TTVideoEngineLogFlag & TTVideoEngineLogFlagPlayer)) {
                TTVideoEngineLogPrint(TTVideoEngineLogSourcePlayer, level, [NSString stringWithUTF8String:info]);
            }
            if(g_TTVideoEngineLogDelegate != nil) {
                [g_TTVideoEngineLogDelegate consoleLog:[NSString stringWithUTF8String:info]];
            }
            if ((g_TTVideoEngineLogFlag & TTVideoEngineLogFlagAlogPlayerAll) ||
                (g_TTVideoEngineLogFlag & TTVideoEngineLogFlagAlogPlayer) ||
                level >= PlayerLogWarn) {
                bd_log_write("", "", "VCloudPlayer", kLogLevelInfo, 0, info);
            }
        }
    }
}

NSString *TTVideoEngineBuildMD5(NSString *data) {
    if (!data || data.length < 1) {
        return nil;
    }
    
    const char *cStr = [data UTF8String];
    unsigned char result[CC_MD2_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    NSMutableString *temString = [NSMutableString string];
    for (int i = 0; i < CC_MD2_DIGEST_LENGTH; i++) {
        [temString appendFormat:@"%02x",result[i]];
    }
    return temString.copy;
}

CGFloat TTVideoEngineAppCpuUsage(void) {
    kern_return_t kr;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;
    thread_basic_info_t basic_info_th;
    
    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS)
        return -1;
    
    float tot_cpu = 0;
    
    for (int j = 0; j < thread_count; j++) {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS)
            return -1;
        
        basic_info_th = (thread_basic_info_t)thinfo;
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            // cpu_usage : Scaled cpu usage percentage. The scale factor is TH_USAGE_SCALE.
            tot_cpu += basic_info_th->cpu_usage / (float)TH_USAGE_SCALE;
        }
    } // for each thread
    
    // must call vm_deallocate.
    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    assert(kr == KERN_SUCCESS);
    
    return tot_cpu;
}

CGFloat TTVideoEngineAppMemoryUsage(void) {
    task_vm_info_data_t vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t kernelReturn = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t) &vmInfo, &count);
    if(kernelReturn == KERN_SUCCESS) {
        int64_t memoryUsageInByte = (int64_t) vmInfo.phys_footprint;
        return memoryUsageInByte / 1024.0 / 1024.0; // M
    } else {
        return -1;
    }
}


NSString *TTVideoEngineGenerateTraceId(NSString *_Nullable deviceId, uint64_t time) {
    NSMutableString *temString = [NSMutableString string];
    if (deviceId) {
        [temString appendString:deviceId];
        [temString appendString:@"T"];
    }
    [temString appendFormat:@"%lld",time];
    [temString appendFormat:@"T"];
    
    uint32_t random = arc4random_uniform(0xFFFF);
    [temString appendFormat:@"%u",random];
    return temString.copy;
}

UIApplication *TTVideoEngineGetApplication() {
    static dispatch_once_t onceToken;
    static BOOL extension = NO;
    dispatch_once(&onceToken, ^{
        if ([[[NSBundle mainBundle] bundlePath] hasSuffix:@".appex"]) extension = YES;
        if (!extension) {
            Class cls = NSClassFromString(@"UIApplication");
            if(!cls || ![cls respondsToSelector:@selector(sharedApplication)]) extension = YES;
        }
    });
    return extension ? nil : [UIApplication sharedApplication];
}

void TTVideoEngineLogPrint(TTVideoEngineLogSource logSource, kBDLogLevel level, NSString *log) {
    if (isTTVideoEngineLogEnabled ||
        (logSource == TTVideoEngineLogSourceEngine && (g_TTVideoEngineLogFlag & TTVideoEngineLogFlagEngine)) ||
        (logSource == TTVideoEngineLogSourcePlayer && (g_TTVideoEngineLogFlag & TTVideoEngineLogFlagPlayer)) ||
        (logSource == TTVideoEngineLogSourceMDL && (g_TTVideoEngineLogFlag & TTVideoEngineLogFlagMDL))) {
        struct timeval tv;
        gettimeofday(&tv, NULL);
        time_t sec = tv.tv_sec;
        struct tm tcur = *localtime((const time_t*)&sec);
        char temp[64] = {0};
        snprintf(temp, 64, "%d-%02d-%02d %02d:%02d:%02d.%06ld+%04ld",1900 + tcur.tm_year, 1 + tcur.tm_mon, tcur.tm_mday,tcur.tm_hour,tcur.tm_min,tcur.tm_sec,(long)tv.tv_usec,(tcur.tm_gmtoff/60/60)*100);
        printf("%s %s \n", temp, log.UTF8String);
    }
}

void TTVideoEngineLogMethod(TTVideoEngineLogSource logSource,kBDLogLevel level,NSString *log) {
    static NSArray *s_tags = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_tags = @[@"VCloudEngine",@"VCloudPlayer",@"VCloudMDL"];
    });
    
    /// Delegate
    if(g_TTVideoEngineLogDelegate != nil) {
        [g_TTVideoEngineLogDelegate consoleLog:log];
    }
    
    TTVideoEngineLogPrint(logSource, level, log);
    /// Alog
    if ((logSource == TTVideoEngineLogSourceEngine && (g_TTVideoEngineLogFlag & TTVideoEngineLogFlagAlogEngine)) ||
        (logSource == TTVideoEngineLogSourcePlayer && (g_TTVideoEngineLogFlag & TTVideoEngineLogFlagAlogPlayer)) ||
        (logSource == TTVideoEngineLogSourceMDL && (g_TTVideoEngineLogFlag & TTVideoEngineLogFlagAlogMDL))) {
        BDALOG_PROTOCOL_TAG((kBDLogLevel)level,s_tags[logSource],@"%@",log);
    }
}

 BOOL TTVideoEngineStringIsBase64Encode(NSString *str) {
    if (str == NULL || str.length == 0) {
        return false;
    } else {
        NSString *regex = @"^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{4}|[A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)$";
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
        return [pred evaluateWithObject:str];
    }
}

NSString *TTVideoEngineBuildHttpsApi(NSString *apiString) {
    NSString *retString = apiString;
    if (g_FocusUseHttpsForApiFetch && [apiString hasPrefix:@"http://"]) {
        retString = [apiString stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
    }
    return retString;
}

NSDictionary *TTVideoEngineStringToDicForIntvalue(NSString *inputStr, NSString *assignStr, NSString *separateStr) {
    if (!(inputStr && inputStr.length > 0)) {
        return @{};
    }
    
    NSMutableDictionary *tempDic = [NSMutableDictionary dictionary];
    NSArray *items = [inputStr componentsSeparatedByString:separateStr];
    if (items.count > 0) {
        for (NSString *item in items) {
            NSArray *subItems = [item componentsSeparatedByString:assignStr];
            if (subItems.count == 2) {
                NSString *key = subItems[0];
                NSString *value = subItems[1];
                [tempDic ttvideoengine_setObject:@([value intValue]) forKey:key];
            }
        }
    }
    
    NSDictionary *goalDic = [tempDic copy];
    return goalDic;
}

NSString *TTVideoEngineGetMobileNetType(void) {
    TTVideoEngineNetWorkWWANStatus state = [[TTVideoEngineNetWorkReachability shareInstance] currentWWANState];
    NSString *currentNet = @"wwan";
    if (TTVideoEngineNetWorkWWANStatus2G == state) {
        currentNet = @"2G";
    } else if (TTVideoEngineNetWorkWWANStatus3G == state) {
        currentNet = @"3G";
    } else if (TTVideoEngineNetWorkWWANStatus4G == state) {
        currentNet = @"4G";
    } else if (TTVideoEngineNetWorkWWANStatus5G == state) {
        currentNet = @"5G";
    }
    return currentNet;
}

/// 埋点模块扩展方法, 用于添加新埋点
void TTVideoEngineLoggerPutToDictionary(NSMutableDictionary *_Nonnull dict, NSString *_Nonnull key, id _Nullable obj) {
    if (!dict) {
        return;
    }
    if (!key) {
        return;
    }
    if (!obj) {
        return;
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        NSNumber *number = (NSNumber *)obj;
        const char *objCtype = [number objCType];
        if (strcmp(objCtype, @encode(int)) == 0) {
            if ([number intValue] == LOGGER_INTEGER_EMPTY_VALUE) {
                return;
            }
        } else if (strcmp(objCtype, @encode(long)) == 0) {
            if ([number longValue] == LOGGER_INTEGER_EMPTY_VALUE) {
                return;
            }
        } else if (strcmp(objCtype, @encode(long long)) == 0) {
            if ([number longLongValue] == LOGGER_INTEGER_EMPTY_VALUE) {
                return;
            }
        } else if (strcmp(objCtype, @encode(float)) == 0) {
            if ([number floatValue] == LOGGER_FLOAT_EMPTY_VALUE || isnan([number floatValue]) || isinf([number floatValue])) {
                return;
            }
        } else if (strcmp(objCtype, @encode(double)) == 0) {
            if ([number doubleValue] == LOGGER_FLOAT_EMPTY_VALUE || isnan([number doubleValue]) || isinf([number doubleValue])) {
                return;
            }
        } else if (strcmp(objCtype, @encode(unsigned int)) == 0) {
            if ([number unsignedIntValue] == LOGGER_INTEGER_EMPTY_VALUE) {
                return;
            }
        } else if (strcmp(objCtype, @encode(unsigned long)) == 0) {
            if ([number unsignedLongValue] == LOGGER_INTEGER_EMPTY_VALUE) {
                return;
            }
        } else if (strcmp(objCtype, @encode(unsigned long long)) == 0) {
            if ([number unsignedLongLongValue] == LOGGER_INTEGER_EMPTY_VALUE) {
                return;
            }
        } else if (strcmp(objCtype, @encode(short)) == 0) {
            if ([number shortValue] == LOGGER_INTEGER_EMPTY_VALUE) {
                return;
            }
        } else if (strcmp(objCtype, @encode(unsigned short)) == 0) {
            if ([number unsignedShortValue] == LOGGER_INTEGER_EMPTY_VALUE) {
                return;
            }
        }
        [dict setObject:number forKey:key];
    } else if ([obj isKindOfClass:[NSString class]]){
        NSString *str = (NSString *)obj;
        if (str.length > 0) {
            [dict setObject:str forKey:key];
        }
    } else if ([obj isKindOfClass:[NSArray class]]) {
        NSArray *array = [(NSArray *)obj copy];
        if (array.count > 0) {
            [dict setObject:array forKey:key];
        }
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *d = [(NSDictionary *)obj copy];
        if (d.count > 0) {
            [dict setObject:d forKey:key];
        }
    }
}
