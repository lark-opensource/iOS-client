//
//  HMDExceptionModuleReporter.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/6/10.
//

#import "HMDExceptionModuleReporter.h"
#import "HMDExceptionModuleReporter+Internal.h"
#include <pthread.h>
#import "NSDictionary+HMDSafe.h"
#import "HMDUserExceptionModuleReporter.h"
#import "HMDDefaultExceptionModuleReporter.h"
#import "HMDExceptionDataWrapper.h"
#if RANGERSAPM
#import "RangersAPMWatchDogModuleReporter.h"
#import "RangersAPMUploadHelper.h"
#endif

#import "HMDUploadHelper.h"
#import "HMDInjectedInfo.h"
#import "HMDHeimdallrConfig.h"
#import "HMDMacro.h"
#import "NSDictionary+HMDHTTPQuery.h"
#import "HMDNetworkManager.h"
#import "HMDNetworkReqModel.h"
#import "HMDJSON.h"
// PrivateServices
#import "HMDServerStateService.h"
#import "HMDURLManager.h"
#import "HMDURLSettings.h"

@interface HMDExceptionModuleReporter ()

@end

@implementation HMDExceptionModuleReporter

+ (instancetype)reporterWithExceptionType:(HMDExceptionType)exceptionType {
    if (exceptionType == HMDDefaultExceptionType ||
        exceptionType == HMDCPUExceptionType ||
        exceptionType == HMDCaptureBacktraceExceptionType ||
        exceptionType == HMDMetricKitExceptionType ||
        exceptionType == HMDUIFrozenExceptionType ||
        exceptionType == HMDFDExceptionType) {
        HMDDefaultExceptionModuleReporter *reporter = [[HMDDefaultExceptionModuleReporter alloc] init];
        reporter.reporterType = HMDReporterException;
        return reporter;
    } else if (exceptionType == HMDUserExceptionType) {
        HMDUserExceptionModuleReporter *reporter = [[HMDUserExceptionModuleReporter alloc] init];
        reporter.reporterType = HMDReporterUserException;
        return reporter;
    }
#if RANGERSAPM
    else if (exceptionType == HMDWatchDogExceptionType) {
        return [[RangersAPMWatchDogModuleReporter alloc] init];
    }
#endif
    NSAssert(NO, @"invalid exception type : %ld", exceptionType);
    return nil;
}

- (instancetype)init {
    if (self = [super init]) {
        self.exceptionModules = [NSMutableSet set];
        pthread_rwlock_init(&rwlock, NULL);
        self.exceptionReportQueue = dispatch_queue_create("com.heimdallr.exception_report", NULL);
        self.exceptionResponseQueue = dispatch_queue_create("com.heimdallr.exception_response", NULL);
        self.condtion = [[NSCondition alloc] init];
    }
    return self;
}

- (void)addReportModule:(id<HMDExceptionReporterDataProvider>)module {
    pthread_rwlock_wrlock(&rwlock);
    if(module) {
        [self.exceptionModules addObject:module];
    }
    pthread_rwlock_unlock(&rwlock);
}

- (void)removeReportModule:(id<HMDExceptionReporterDataProvider>)module
{
    pthread_rwlock_wrlock(&rwlock);
    if(module) {
        [self.exceptionModules removeObject:module];
    }
    pthread_rwlock_unlock(&rwlock);
}

- (void)reportExceptionData
{
    dispatch_async(self.exceptionReportQueue, ^{
        @autoreleasepool {
            [self _reportExceptionData];
        }
    });
}

- (void)_reportExceptionData {
    if (!hmd_is_server_available(self.reporterType)) {
        return;
    }

    WAIT_FOR_REPORT;
    HMDExceptionDataWrapper *wrapper = [self _allExceptionData];
    if (wrapper) {
        [self _uploadWithDataWrapper:wrapper completion:^(BOOL isSuccess) {
            FINISH_REPORT;
        }];
    } else {
        FINISH_REPORT;
    }
}

- (HMDExceptionDataWrapper *)_allExceptionData
{
    pthread_rwlock_rdlock(&rwlock);
    NSArray<id<HMDExceptionReporterDataProvider>> *modules = [self.exceptionModules allObjects];
    pthread_rwlock_unlock(&rwlock);
    
    HMDExceptionDataWrapper *wrapper = nil;
    for (id<HMDExceptionReporterDataProvider> module in modules) {
        @autoreleasepool {
            if ([module respondsToSelector:@selector(pendingExceptionData)]) {
                NSArray *result = [module pendingExceptionData];
                if (result && result.count > 0) {
                    if (!wrapper) {
                        wrapper = [[HMDExceptionDataWrapper alloc] init];
                    }
                    [wrapper.dataDicts addObjectsFromArray:result];
                    [wrapper.modules addObject:module];
                }
            }
        }
    }
    return wrapper;
}

- (NSArray *)debugRealExceptionDataWithConfig:(HMDDebugRealConfig *)config
{
    return [[self _debugRealExceptionDataWrappersWithConfig:config] dataDicts];
}

- (void)reportDebugRealExceptionData:(HMDDebugRealConfig *)config
{
    dispatch_async(self.exceptionReportQueue, ^{
        [self _reportDebugRealExceptionData:config];
    });
}

- (void)_reportDebugRealExceptionData:(HMDDebugRealConfig *)config {
    if (!hmd_is_server_available(self.reporterType)) {
        return;
    }
    
    WAIT_FOR_REPORT;
    HMDExceptionDataWrapper *wrapper = [self _debugRealExceptionDataWrappersWithConfig:config];
    if (wrapper) {
        [self _uploadWithDataWrapper:wrapper completion:^(BOOL isSuccess) {
            FINISH_REPORT;
        }];
    } else {
        FINISH_REPORT;
    }
}

- (HMDExceptionDataWrapper *)_debugRealExceptionDataWrappersWithConfig:(HMDDebugRealConfig *)config
{
    pthread_rwlock_rdlock(&rwlock);
    NSArray<id<HMDExceptionReporterDataProvider>> *modules = [self.exceptionModules allObjects];
    pthread_rwlock_unlock(&rwlock);
    
    HMDExceptionDataWrapper *wrapper = nil;
    for (id<HMDExceptionReporterDataProvider> module in modules) {
        @autoreleasepool {
            if ([module respondsToSelector:@selector(pendingDebugRealExceptionDataWithConfig:)]) {
                NSArray *result = [module pendingDebugRealExceptionDataWithConfig:config];
                if (result && result.count > 0) {
                    if (!wrapper) {
                        wrapper = [[HMDExceptionDataWrapper alloc] init];
                    }
                    [wrapper.dataDicts addObjectsFromArray:result];
                    [wrapper.modules addObject:module];
                }
            }
        }
    }
    return wrapper;
}

- (void)cleanupExceptionDataWithConfig:(HMDDebugRealConfig *)config
{
    pthread_rwlock_rdlock(&rwlock);
    NSArray<id<HMDExceptionReporterDataProvider>> *modules = [self.exceptionModules allObjects];
    pthread_rwlock_unlock(&rwlock);
    [modules enumerateObjectsUsingBlock:^(id<HMDExceptionReporterDataProvider>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @autoreleasepool {
            if ([obj respondsToSelector:@selector(cleanupExceptionDataWithConfig:)]) {
                [obj cleanupExceptionDataWithConfig:config];
            }
        }
        
    }];
}

#pragma mark - Wrapper Upload

- (void)_uploadWithDataWrapper:(HMDExceptionDataWrapper *)wrapper completion:(void (^)(BOOL isSuccess))completion {
    if (wrapper.dataDicts.count == 0) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    
    id<HMDURLProvider> urlProvider = [self moduleURLProvier];
    NSAssert(urlProvider != nil, @"Exception reporter need a module URL provier!");
    [self uploadDataWithDataDicts:wrapper.dataDicts appID:nil urlProvider:urlProvider completion:^(BOOL isSuccess, BOOL isDropData, NSDictionary * _Nullable responseDict) {
        for (id module in wrapper.modules) {
            @autoreleasepool {
                if ([module respondsToSelector:@selector(exceptionReporterDidReceiveResponse:)]){
                    [module exceptionReporterDidReceiveResponse:isSuccess];
                }
                if (isDropData && [module respondsToSelector:@selector(dropExceptionData)]) {
                    [module dropExceptionData];
                }
            }
        }
        if (completion) {
            completion(isSuccess);
        }
    }];
}

- (void)uploadDataWithDataDicts:(NSArray<NSDictionary *> *)dataDicts
                          appID:(NSString *)appID
                    urlProvider:(id<HMDURLProvider>)urlProvider
                     completion:(HMDExceptionUploadCompletion)completion {
#if RANGERSAPM
    NSDictionary *headerInfo = [RangersAPMUploadHelper headerInfoForAppID:appID];
#else
    NSDictionary *headerInfo = [[HMDUploadHelper sharedInstance] headerInfo];
#endif
    appID = appID ?: [HMDInjectedInfo defaultInfo].appID;
    [self _uploadDataWithDataDicts:dataDicts
                             appID:appID
                        headerInfo:headerInfo
                       urlProvider:urlProvider
                        completion:completion];
}

- (void)_uploadDataWithDataDicts:(NSArray<NSDictionary *> *)dataDicts
                           appID:(NSString *)appID
                      headerInfo:(NSDictionary *)headerInfo
                     urlProvider:(id<HMDURLProvider>)urlProvider
                      completion:(HMDExceptionUploadCompletion)completion {
    NSMutableDictionary *body = [NSMutableDictionary dictionaryWithCapacity:2];
    [body setValue:dataDicts forKey:@"data"];
    [body setValue:headerInfo forKey:@"header"];
    
    NSString *requestURL = [HMDURLManager URLWithProvider:urlProvider forAppID:[HMDInjectedInfo defaultInfo].appID];
    if (requestURL == nil) {
        if (completion) {
            completion(NO, NO, nil);
        }
        return;
    }
    
    { // Add URL Query
        NSMutableDictionary *queryDict = [NSMutableDictionary dictionary];
        if (!HMDIsEmptyDictionary(headerInfo)) {
            [queryDict addEntriesFromDictionary:headerInfo];
        }
        NSDictionary *commonParams = [HMDInjectedInfo defaultInfo].commonParams;
        if (!HMDIsEmptyDictionary(commonParams)) {
            [queryDict addEntriesFromDictionary:commonParams];
        }
        NSString *queryStr = [queryDict hmd_queryString];
        if (queryStr.length > 0) {
            requestURL = [NSString stringWithFormat:@"%@?%@", requestURL, queryStr];
        }
    }
    
    NSMutableDictionary * headerDict = [NSMutableDictionary dictionaryWithCapacity:2];
    [headerDict setValue:@"application/json; encoding=utf-8" forKey:@"Content-Type"];
    [headerDict setValue:@"application/json" forKey:@"Accept"];
    
#if RANGERSAPM
    NSString *currentAid = [headerInfo hmd_stringForKey:@"aid"];
    if (currentAid) {
        headerDict = [NSMutableDictionary dictionaryWithDictionary:[RangersAPMUploadHelper headerFieldsForAppID:currentAid withCustomHeaderFields:headerDict]];
    }
#endif
    
    HMDNetworkReqModel *request = [[HMDNetworkReqModel alloc] init];
    request.requestURL = requestURL;
    request.method = @"POST";
    request.headerField = headerDict;
    request.params = [body copy];
    request.needEcrypt = [urlProvider shouldEncrypt];
    
    [[HMDNetworkManager sharedInstance] asyncRequestWithModel:request callback:^(NSError *error, id jsonObj) {
        dispatch_async(self.exceptionResponseQueue, ^{
            // 判断是否上传成功，需要 Module 清理数据
            NSDictionary *maybeDictionary = jsonObj;
            if (![maybeDictionary isKindOfClass:[NSDictionary class]]) {
                if (completion) {
                    completion(NO, NO, nil);
                }
                return;
            }

            BOOL isSuccess = NO;
            BOOL isDropData = NO;

            NSDictionary *result = [maybeDictionary hmd_dictForKey:@"result"];
            if (result != nil) {
                NSString *message = [result hmd_stringForKey:@"message"];
                if ([message isEqualToString:@"success"]) {
                    isSuccess = YES;
                }
            }
            NSInteger statusCode = [maybeDictionary hmd_intForKey:@"status_code"];
            HMDServerState errCode = hmd_update_server_checker(self.reporterType, result, statusCode);
            if ((errCode & HMDServerStateDropAllData) == HMDServerStateDropAllData) {
                isDropData = YES;
            }
            if (completion) {
                completion(isSuccess, isDropData, maybeDictionary);
            }
        });
    }];
}

#pragma mark - Subclass Override

- (id<HMDURLProvider>)moduleURLProvier {
    NSAssert(NO, @"Subclass must override this method.");
    return nil;
}

@end
