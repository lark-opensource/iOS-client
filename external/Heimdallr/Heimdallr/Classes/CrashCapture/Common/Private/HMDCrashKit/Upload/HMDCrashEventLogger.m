//
//  HMDCrashEventLogger.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/23.
//

#import "HMDCrashEventLogger.h"
#import "HMDCrashEventLogger+URLPathProvider.h"
#import "HMDCrashDirectory.h"
#import "HMDCrashDirectory+Path.h"
#import "NSDictionary+HMDJSON.h"
#import "HMDInjectedInfo.h"
#import "NSString+HMDJSON.h"
#import "HMDNetworkManager.h"
#import "HMDNetworkHelper.h"
#import "HMDCrashEnviroment.h"
#import "HMDNetworkReqModel.h"
#import "HMDMacro.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDUploadHelper.h"
#import "NSDictionary+HMDHTTPQuery.h"
#import "HMDCrashKit+Internal.h"
// PrivateServices
#import "HMDServerStateService.h"
#import "HMDURLManager.h"

@interface HMDCrashEventLogger ()
@property (nonatomic,strong) HMDCrashMetaData *currentMeta;
@end

@implementation HMDCrashEventLogger
{
    dispatch_queue_t _queue;
    BOOL _isUploading;
}
+ (instancetype)sharedInstance
{
    static HMDCrashEventLogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[HMDCrashEventLogger alloc] init];
    });
    return logger;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    if (self = [super init]) {
        _queue = dispatch_queue_create("hmd_crash_event_logger", NULL);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (HMDCrashMetaData *)currentMeta
{
    if (!_currentMeta) {
        _currentMeta = [HMDCrashEnviroment currentMetaData];
    }
    return _currentMeta;
}

- (void)logCrashEvent:(HMDCrashInfo *)info
{
    dispatch_async(_queue, ^{
        [self _logCrashEvent:info];
    });
}

- (void)_logCrashEvent:(HMDCrashInfo *)info
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict hmd_setObject:@"iOS" forKey:@"os"];
    [dict hmd_setObject:@"crash" forKey:@"event_type"];
    [dict hmd_setObject:info.meta.deviceModel forKey:@"device_model"];
    [dict hmd_setObject:@((long long)(info.headerInfo.crashTime*1000)) forKey:@"crash_time"];
    [dict hmd_setObject:info.headerInfo.typeStr forKey:@"crash_type"];
    [dict hmd_setObject:@(info.isEnvAbnormal?1:0) forKey:@"is_env_abnormal"];
    [dict hmd_setObject:info.meta.osVersion forKey:@"os_version"];
    [dict hmd_setObject:info.meta.appVersion forKey:@"app_version"];
    [dict hmd_setObject:info.meta.bundleVersion forKey:@"update_version_code"];
    [dict hmd_setObject:info.meta.sdkVersion forKey:@"sdk_version"];
    
    NSString *uuid = info.meta.UUID;

    [dict hmd_setObject:uuid forKey:@"crash_summary"];
    
    NSString *eventDir = HMDCrashDirectory.eventDirectory;
    
    NSString *fileName = [NSUUID UUID].UUIDString;
    NSString *path = [eventDir stringByAppendingPathComponent:fileName];

    [dict hmd_setObject:@((long long)([NSDate date].timeIntervalSince1970*1000)) forKey:@"event_time"];
    [dict hmd_setObject:@"crash" forKey:@"event"];
    
    int state = 0;
    if (info.isComplete) {
        state = 0; //full
    }else if (info.currentlyUsedImages.count > 0 && info.threads.count > 0){
        if(!info.isInvalid){
            state = 1; //basic
        } else {
            state = 2; //invalidparse
        }
    }else{
        state = 3; //broken
    }
    [dict hmd_setObject:@(state) forKey:@"state"];
    
    NSString *errorInfo = [NSString stringWithFormat:@"%@\n%@",info.sdklog,info.processLog];
    [dict hmd_setObject:errorInfo forKey:@"error_info"];
    [[dict hmd_jsonData] writeToFile:path atomically:YES];
}

- (void)logUploadEvent:(NSString *)filePath error:(NSError *)error backgroundSession:(BOOL)backgroundSession;
{
    dispatch_async(_queue, ^{
        [self _logUploadEvent:filePath error:error backgroundSession:backgroundSession];
        [self uploadAllEvents];
    });
}

- (void)_logUploadEvent:(NSString *)filePath error:(NSError *)error backgroundSession:(BOOL)backgroundSession;
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict hmd_setObject:@"iOS" forKey:@"os"];
    [dict hmd_setObject:@"crash" forKey:@"event_type"];
    [dict hmd_setObject:self.currentMeta.deviceModel forKey:@"device_model"];
    [dict hmd_setObject:self.currentMeta.osVersion forKey:@"os_version"];
    [dict hmd_setObject:self.currentMeta.appVersion forKey:@"app_version"];
    [dict hmd_setObject:self.currentMeta.bundleVersion forKey:@"update_version_code"];
    [dict hmd_setObject:self.currentMeta.sdkVersion forKey:@"sdk_version"];
    [dict hmd_setObject:@(backgroundSession?1:0) forKey:@"backgroundsession"];

    NSString *uuid = [filePath.lastPathComponent stringByDeletingPathExtension];
    [dict hmd_setObject:uuid forKey:@"crash_summary"];
    
    NSString *eventDir = HMDCrashDirectory.eventDirectory;
    
    NSString *fileName = [NSUUID UUID].UUIDString;
    NSString *path = [eventDir stringByAppendingPathComponent:fileName];
    
    [dict hmd_setObject:@((long long)([NSDate date].timeIntervalSince1970*1000)) forKey:@"event_time"];
    [dict hmd_setObject:@"upload" forKey:@"event"];

    if (error) {
        NSString *errorInfo = [NSString stringWithFormat:@"%@\n%@",error.localizedDescription,error.userInfo];
        [dict hmd_setObject:errorInfo forKey:@"error_info"];
        [dict hmd_setObject:@(error.code) forKey:@"state"];
    }else{
        [dict hmd_setObject:@(0) forKey:@"state"];
    }
    
    [[dict hmd_jsonData] writeToFile:path atomically:YES];

}

- (void)uploadAllEvents
{
    HMDStopUpload crashStopUpload = [HMDInjectedInfo defaultInfo].crashStopUpload;
    if (crashStopUpload && crashStopUpload()) {
        return;
    }
    
    dispatch_async(_queue, ^{
        [self _uploadAllEvents];
    });
}

- (void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) _uploadAllEvents
{
    if (_isUploading) {
        return;
    }
    NSArray *fileNames = [self collectAllFileNames];
    if (fileNames.count == 0) {
        return;
    }
    
#if !RANGERSAPM
    NSArray *datas = [self constructPostDataWithFileNames:fileNames];
    if (datas.count == 0) {
        return;
    }
    
    _isUploading = YES;
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:datas forKey:@"data"];

    NSString *url = [HMDURLManager URLWithHostProvider:HMDSharedCrashKit.networkProvider pathProvider:self forAppID:nil];
    if (url == nil) {
        _isUploading = NO;
        return;
    }
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    NSDictionary *maybeDictionary = [HMDInjectedInfo defaultInfo].commonParams;
    if ([maybeDictionary isKindOfClass:NSDictionary.class]) {
        [dic addEntriesFromDictionary:maybeDictionary];
    }
    NSDictionary *headerInfo = [HMDUploadHelper sharedInstance].headerInfo;
    if (headerInfo) {
        [dic addEntriesFromDictionary:headerInfo];
    }
    NSString *queryString = [dic hmd_queryString];
    url = [NSString stringWithFormat:@"%@?%@", url, queryString];
    
    NSMutableDictionary *headerField = [NSMutableDictionary dictionary];
    [headerField setValue:@"application/json; encoding=utf-8" forKey:@"Content-Type"];
    [headerField setValue:@"application/json" forKey:@"Accept"];
    
    HMDNetworkReqModel *reqModel = [HMDNetworkReqModel new];
    reqModel.requestURL = url;
    reqModel.method = @"POST";
    reqModel.headerField = headerField;
    reqModel.params = params;
    reqModel.needEcrypt = [HMDSharedCrashKit.networkProvider shouldEncrypt];
    [[HMDNetworkManager sharedInstance] asyncRequestWithModel:reqModel callback:^(NSError *error, id jsonObj) {
        dispatch_async(self->_queue, ^{
            if ([jsonObj isKindOfClass:[NSDictionary class]]) {
                NSDictionary *result = [jsonObj hmd_dictForKey:@"result"];
                NSString *msg = [result hmd_stringForKey:@"message"];
                NSInteger statusCode = [(NSDictionary *)jsonObj hmd_intForKey:@"status_code"];
                HMDServerState serverState = hmd_update_server_checker(HMDReporterCrashEvent, result, statusCode);
                BOOL isDropData = (serverState & HMDServerStateDropAllData) == HMDServerStateDropAllData;
                if ([msg isEqualToString:@"success"] || isDropData) {
                    [self cleanUpWithFileNames:fileNames];
                }
            }
            self->_isUploading = NO;
        });
    }];
#else
    [self cleanUpWithFileNames:fileNames];
#endif
}

- (NSArray *)collectAllFileNames
{
    NSArray<NSString *> *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:HMDCrashDirectory.eventDirectory error:nil];
    if (fileNames.count == 0) {
        return nil;
    }
    __block NSMutableArray *results = nil;
    [fileNames enumerateObjectsUsingBlock:^(NSString *_Nonnull fileName, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!results) {
            results = [NSMutableArray array];
        }
        [results hmd_addObject:fileName];
    }];
    return results;
}

- (NSArray *)constructPostDataWithFileNames:(NSArray *)fileNames
{
    NSMutableArray *results = [NSMutableArray array];
    [fileNames enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *data = [self constructPostDataWithFileName:obj];
        [results hmd_addObject:data];
    }];
    return results;
}

- (NSDictionary *)constructPostDataWithFileName:(NSString *)fileName
{
    NSString *filePath = [HMDCrashDirectory.eventDirectory stringByAppendingPathComponent:fileName];
    NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    NSDictionary *dict = [content hmd_jsonDict];
    if (dict.count == 0) {
        return nil;
    }
    NSMutableDictionary *result = [dict mutableCopy];
    [result hmd_setObject:[HMDInjectedInfo defaultInfo].deviceID forKey:@"device_id"];
    if ([HMDInjectedInfo defaultInfo].scopedDeviceID) {
        [result hmd_setObject:[HMDInjectedInfo defaultInfo].scopedDeviceID forKey:@"scoped_device_id"];
    }
    [result hmd_setObject:[HMDInjectedInfo defaultInfo].appID forKey:@"aid"];
    [result hmd_setObject:[HMDNetworkHelper connectTypeName]  forKey:@"access"];

    if (![result hmd_hasKey:@"app_version"]) {
        [result hmd_setObject:self.currentMeta.appVersion forKey:@"app_version"];
    }
    if (![result hmd_hasKey:@"update_version_code"]) {
        [result hmd_setObject:self.currentMeta.bundleVersion forKey:@"update_version_code"];
    }
    if (![result hmd_hasKey:@"sdk_version"]) {
        [result hmd_setObject:self.currentMeta.sdkVersion forKey:@"sdk_version"];
    }
    return result;
}

- (void)cleanUpWithFileNames:(NSArray *)fileNames
{
    NSString *basePath = HMDCrashDirectory.eventDirectory;
    [fileNames enumerateObjectsUsingBlock:^(NSString * _Nonnull fileName, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *filePath = [basePath stringByAppendingPathComponent:fileName];
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }];
}

+ (void)logCrashEvent:(HMDCrashInfo *)info
{
    if (!hmd_drop_data(HMDReporterCrashEvent)) {
#if !RANGERSAPM
        [[HMDCrashEventLogger sharedInstance] logCrashEvent:info];
#endif
    }
}

+ (void)logUploadEvent:(NSString *)filePath error:(NSError *)error backgroundSession:(BOOL)backgroundSession
{
    if (hmd_is_server_available(HMDReporterCrashEvent)) {
#if !RANGERSAPM
        [[HMDCrashEventLogger sharedInstance] logUploadEvent:filePath error:error backgroundSession:backgroundSession];
#endif
    }
}

#pragma mark - notification

- (void)didEnterBackground:(NSNotification *)notification
{
    [self uploadAllEvents];
}

- (void)willEnterForeground:(NSNotification *)notification
{
    [self uploadAllEvents];
}

@end
