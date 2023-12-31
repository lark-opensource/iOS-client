//
//  BDDYCDownloader.m
//  BDDynamically
//
//  Created by zuopengliu on 13/3/2018.
//

#import "BDDYCDownloader.h"
#import "BDDYCModuleModel.h"
#import "BDDYCModule+Internal.h"
#import "BDDYCModuleManager.h"
#import "BDDYCSecurity.h"
#import "BDDYCErrCode.h"
#import "BDDYCMacros.h"
#import "BDDYCZipArchive.h"
#import "BDDYCSessionChallenge.h"
#import "BDDYCModelKey.h"
#import "BDDYCMonitor.h"
#import "BDDYCUtils.h"
#import <BDAlogProtocol/BDAlogProtocol.h>
#import "BDDYCDevice.h"
#import <BDBDQuaterback+Internal.h>

#import <TTNetworkManager/TTNetworkManager.h>
#import "BDQBPostDataHttpRequestSerializer.h"
//#import "NSURLSession.h"

NSString *const kBDQuaterbackLastReportListTimeKey = @"kBetter_last_report_list_time_key";
extern NSString *const kBDDYQuaterbackListDownloadStatusMonitorServiceName;
extern NSString *const kBDDYCQuaterbackWillClearQuaterbacksMonitorServiceName;
NSString *const kBDDQuaterbackDidFetchList = @"kBetter_did_fetch_list";
NSString *const kBDDQuaterbackFetchListKey = @"kBetter_fetch_list_key";
extern NSString *const kBDDYCQuaterbackUnzipTime;
extern NSString *const kBDDYCQuaterbackDownloadZipTime;
extern  NSString *const kBDDYCQuaterbackDownloadStart;
extern  NSString *const kBDDYCQuaterbackDownloadend;

static NSDictionary *BDDYCDictionaryWithJSONData(NSData *inData, NSError * __autoreleasing * resultError)
{
    if (!inData) return nil;
    NSError *serializationError = nil;
    id serializationObject = [NSJSONSerialization JSONObjectWithData:inData
                                                             options:NSJSONReadingAllowFragments
                                                               error:&serializationError];
    if (resultError) {
        *resultError = serializationError;
#ifdef DEBUG
        @try {
            NSString *errText = [[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding];
            NSLog(@"string(inData) = %@", errText);
        } @catch (NSException *exception) {
        } @finally {
        }
#endif
    }
    return [serializationObject isKindOfClass:[NSDictionary class]] ? serializationObject : nil;
}

@implementation BDDYCDownloader

#pragma mark - step1 + step2

+ (id<BDDYCSessionTask>)fetchModulesWithRequest:(BDDYCModuleRequest *)aModuleReq
                                    toDirecotry:(NSString *)fileDir
                                       progress:(void (^)(id aDYCModule, NSInteger modelIdx, NSError *error))progressHandler
                                     completion:(void (^)(NSArray *modules, NSError *error))completionHandler
{
    __block NSError *downloadError = nil;
    NSMutableArray *mutableArray = [NSMutableArray array];
    return [self fetchModulesWithRequest:aModuleReq toDirecotry:fileDir completion:^(BDDYCModuleModel *aModel, NSInteger arrayIdx, NSInteger total, id aDYCModule, NSError *error) {
        
        if (arrayIdx != -1) {
            // -1 表示补丁列表为空或网络出错，不执行 progressHandler 回调
            !progressHandler ? : progressHandler(aDYCModule, arrayIdx, error);
            if (aDYCModule) {
                [mutableArray addObject:aDYCModule];
            }
        }
        
        if (error) {
            NSMutableDictionary *mutUserInfo = [downloadError.userInfo mutableCopy] ? : [NSMutableDictionary new];
            [mutUserInfo setValue:error forKey:[@(arrayIdx) stringValue]];
            downloadError = [NSError errorWithDomain:BDDYCErrorDomain
                                                code:BDDYCErrCodeDownloadFailed
                                            userInfo:mutUserInfo];
        }
        
        // All Tasks Done
        if ([mutableArray count] >= total) {
            !completionHandler ? : completionHandler([mutableArray copy], downloadError);
        }
    }];
}


+ (id<BDDYCSessionTask>)fetchModulesWithRequest:(BDDYCModuleRequest *)aModuleReq
                                    toDirecotry:(NSString *)fileDir
                                     completion:(void (^)(BDDYCModuleModel *aModel, NSInteger arrayIdx, NSInteger count, // source data
                                                          id aDYCModule, NSError *error))completionHandler // response data
{
    BDDYCSessionTask *aDycTask = [BDDYCSessionTask new];
    __weak __typeof(aDycTask) weakDacTask = aDycTask;
    BDDYCModuleListSessionTask *aMdlListTask = [BDDYCDownloader fetchModelListWithRequest:aModuleReq completion:^(NSArray<BDDYCModuleModel *> *moduleList, NSError *error) {
        __strong __typeof(weakDacTask) strongDacTask = weakDacTask;
        NSArray *allLocalModules = [kBDDYCGetLocalQuaterbackModules copy];
        NSMutableArray *availableModules = [NSMutableArray arrayWithCapacity:3];
        [allLocalModules enumerateObjectsUsingBlock:^(BDBDModule *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            __block BOOL needRemove = NO;
            [moduleList enumerateObjectsUsingBlock:^(BDDYCModuleModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
                BOOL isEqualModule =  [[obj.moduleModel.moduleId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:[model.moduleId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
                BOOL offline = model.offline;
                if (isEqualModule && offline) {
                    needRemove = YES;
                }
            }];
            if (needRemove) {
                BOOL clearSuccess = [BDDYCModuleManager clearLocalQuaterbackWithModule:obj];
                if (clearSuccess) {
                    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970] * 1000;
//                    NSArray *patchs = [[BDDYCModuleManager sharedManager] allToLogModules];
                    NSDictionary *data = @{@"betters":@{@"name":obj.moduleModel.name?:@"",
                                                        @"versoin":obj.moduleModel.version?:@"",
                                                        },
                                           @"timestamp":[NSNumber numberWithDouble:interval],
                                           };
                    [BDDYCMonitorGet() trackService:kBDDYCQuaterbackWillClearQuaterbacksMonitorServiceName status:kBDQuaterbackWillClearPatchsStatusPatchListIsEmpty  extra:data];
                }
            }
        }];

        [moduleList enumerateObjectsUsingBlock:^(BDDYCModuleModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!model.offline) {
                [availableModules addObject:model];
            }
        }];

        moduleList = [availableModules copy];
        
        if (error) {
            // download error or list data is empty
            !completionHandler ? : completionHandler(nil, -1, 0, nil, error);
            return;
        }
        aDycTask.moduleListTask.moduleResponseList = moduleList;
        [moduleList enumerateObjectsUsingBlock:^(BDDYCModuleModel *obj, NSUInteger idx, BOOL *stop) {
            if (obj.offline) {
                !completionHandler ? : completionHandler(obj, idx, [moduleList count], nil, nil);
                return;
            }
            
            // judge if need to update
            BDDYCModuleModel *localOldModuleModel = [[BDDYCModuleManager sharedManager] moduleForName:obj.name].moduleModel;
            // Not needs to update

            if (![obj needsUpdateCompareToObject:localOldModuleModel]) {
                //拉取patch列表后需更新本地列表
                if ([[NSFileManager defaultManager] subpathsAtPath:[BDDYCModuleManager alphaMainDirectory]].count > 0 && obj) {
                    // Get old module
                    BDBDModule *oldDYCModule = [[BDDYCModuleManager sharedManager] moduleForName:obj.name];
                    BDBDModule *newDYCModule = oldDYCModule;
                    newDYCModule.moduleModel = obj;
                    [[BDDYCModuleManager sharedManager] removeModuleForName:oldDYCModule.name];
                    [[BDDYCModuleManager sharedManager] addModule:newDYCModule];
                    [[BDDYCModuleManager sharedManager] saveToFile];
                }
                !completionHandler ? : completionHandler(obj, idx, [moduleList count], nil, nil);
                return;
            }

            if (![BDDYCUtils isValidPatchWithConfig:obj needStrictCheck:YES] || obj.offline) {
                if (completionHandler) {
                    completionHandler(obj, idx, [moduleList count], nil, nil);
                }
                return;
            }

            CFTimeInterval downloadStart = CACurrentMediaTime();
            [BDDYCMonitorGet() trackService:kBDDYCQuaterbackDownloadStart metric:nil category:@{
                @"better_name":obj.name?:@"",
                @"version_code":[NSNumber numberWithInteger:[obj.version integerValue]],
                } extra:nil];
            BDDYCModuleSessionTask *aModuleFileTask = [BDDYCDownloader fetchModule:obj toDirecotry:fileDir requestType:aModuleReq.requestType completion:^(BDBDModule *dycModule, NSError *error2) {
                
                BDDYCModuleSessionTask *currTask = [strongDacTask taskForModuleModel:[obj uniquekey]];
                currTask.dycModule = dycModule;
                currTask.error = error2;

                //log
                CFTimeInterval downloadEnd = CACurrentMediaTime();
                NSTimeInterval interval = [[NSDate date] timeIntervalSince1970] * 1000;
                long long milloSecondsInterval = [[NSNumber numberWithDouble:interval] longLongValue];
                NSNumber *timestamp = [NSNumber numberWithLongLong:milloSecondsInterval]?:@(0);
                NSNumber *status = [self statusMap:error2]?:@(0);
                NSDictionary *downloadLogData = @{@"timestamp":timestamp,
                                                  @"better_name":obj.name?:@"",
                                                  @"version_code":[NSNumber numberWithInteger:[obj.version integerValue]],
                                                  @"status":status,
                                                  @"duration":[NSNumber numberWithDouble:(downloadEnd - downloadStart) *1000]?:@(0),
                                                  @"net_type":@(4),
                                                  };
                [BDDYCMonitorGet() trackData:downloadLogData];
                
                if (!error2) {
                    NSDictionary *logData = @{@"timestamp":timestamp,
                                                @"better_name":obj.name?:@"",
                                                @"version_code":[NSNumber numberWithInteger:[obj.version integerValue]],
                                                @"status":status,
                                              @"last_report_list_time":[[NSUserDefaults standardUserDefaults] objectForKey:kBDQuaterbackLastReportListTimeKey]?:@"",
                                                };
                    [BDDYCMonitorGet() trackData:logData];
                }
                
                // Get Module Data
                !completionHandler ? : completionHandler(obj, idx, [moduleList count], dycModule, error2);
            }];
            
            // 下载单个补丁文件任务
            [strongDacTask addModuleTask:aModuleFileTask
                     forModuleModel:[obj uniquekey]];
            
        }];
    }];
    aMdlListTask.request = aModuleReq;
    aDycTask.moduleListTask = aMdlListTask;
    return aDycTask;
}

+ (NSNumber *)statusMap:(NSError *)err {
    if (!err) {
        return [NSNumber numberWithInt:11000];
    }
    
    NSInteger statusCode = 12000;
    switch (err.code) {
        case BDDYCSuccess:
            statusCode = 11000;
            break;
        case BDDYCErrCodeVerifyFailed:
            statusCode = 12001;
            break;
        case BDDYCErrCodeUnzipFailed:
            statusCode = 12002;
            break;
        case BDDYCErrCodeUnzipConditionNotOK:
            statusCode = 12003;
            break;
        case BDDYCErrCodeEncryptFileFail:
            statusCode = 12004;
            break;
        case BDDYCErrCodeWriteFileFail:
            statusCode = 12005;
            break;
        case BDDYCErrCodeConnectionTimeout:
            statusCode = 12006;
            break;
        default:
            statusCode = 12000;
            break;
    }
    return [NSNumber numberWithInteger:statusCode];
}

#pragma mark - step1 (下载整个补丁列表)

+ (BDDYCModuleListSessionTask *)fetchModelListWithRequest:(BDDYCModuleRequest *)aModuleReq
                                               completion:(void (^)(NSArray *, NSError *))completionHandler
{
    BDDYCModuleListSessionTask *aListTask;
    aListTask = [self startFetchModelListWithRequest:aModuleReq completion:^(NSArray *moduleList, NSError *error) {
        
        // Retry
        // TODO:
        !completionHandler ? : completionHandler(moduleList, error);
        
    }];
    return aListTask;
}

+ (BDDYCModuleListSessionTask *)startFetchModelListWithRequest:(BDDYCModuleRequest *)aModuleReq
                                                    completion:(void (^)(NSArray *, NSError *))completionHandler
{
    NSURLRequest *request = [aModuleReq requestWithFormData:nil body:nil];
    
    switch (aModuleReq.requestType) {
        case kBDDYCModuleRequestTypeNSURLSession:
        {
            BDALOG_PROTOCOL_INFO_TAG(@"Better", @"%@: download patch list NSURLSession",[request.URL absoluteString]);
            NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                NSHTTPURLResponse *re = [response isKindOfClass:[NSHTTPURLResponse class]]?(NSHTTPURLResponse *)response:nil;
                NSError *responseDataError = nil;
                NSDictionary *dataDict = !error ? BDDYCDictionaryWithJSONData(data, &responseDataError) : nil;
                [self handleModuleListRequestData:dataDict error:error request:request moduleRequest:aModuleReq statusCode:re.statusCode responseDescription:re.description completion:completionHandler];
                
            }];
            [task resume];
            return [[BDDYCModuleListSessionTask alloc] initWithURLTask:task];
        }
            break;
            
        default:
        {
            BDALOG_PROTOCOL_INFO_TAG(@"Better", @"%@: download patch list TTNet",[request.URL absoluteString]);
            TTHttpTask *task = [[TTNetworkManager shareInstance] requestForJSONWithResponse:request.URL.absoluteString params:aModuleReq.bodyParams method:@"POST" needCommonParams:NO requestSerializer:[BDQBPostDataHttpRequestSerializer class] responseSerializer:nil autoResume:YES callback:^(NSError *error, id obj, TTHttpResponse *response) {
                TTHttpResponse *re = response;
                
                [self handleModuleListRequestData:obj error:error request:request moduleRequest:aModuleReq statusCode:re.statusCode responseDescription:re.description completion:completionHandler];
             }];
            return [[BDDYCModuleListSessionTask alloc] initWithURLTask:task];
        }
            break;
    }
}

+ (void)handleModuleListRequestData:(id)obj
                              error:(NSError *)error
                            request:(NSURLRequest *)request
                            moduleRequest:(BDDYCModuleRequest *)aModuleReq
                         statusCode:(NSInteger)statusCode
                responseDescription:(NSString *)responseDescription
                         completion:(void (^)(NSArray *, NSError *))completionHandler {
    NSDictionary *dataDict = [obj isKindOfClass:[NSDictionary class]]?(NSDictionary *)obj:nil;
    NSError *responseDataError = nil;
    if (dataDict.count <=0) {
        responseDataError = [NSError errorWithDomain:BDDYCErrorDomain
                                                code:BDDYCErrCodeDataError
                                            userInfo:@{NSLocalizedDescriptionKey: @"Unknown error"}];
    }

    __unused id message = dataDict[KBDDYCURLResponseMsgKey];
    NSDictionary *modelDataDict = dataDict[KBDDYCURLResponseDataKey];
    if (modelDataDict && ![modelDataDict isKindOfClass:[NSDictionary class]]) {
        modelDataDict = nil;
        responseDataError = [NSError errorWithDomain:BDDYCErrorDomain
                                                code:BDDYCErrCodeDataError
                                            userInfo:@{NSLocalizedDescriptionKey: @"server return data format error"}];
    }

    if (!responseDataError && statusCode != 200) {
        responseDataError = [NSError errorWithDomain:BDDYCErrorDomain
                                                code:BDDYCErrCodeHTTPError
                                            userInfo:@{NSLocalizedDescriptionKey: @"server return data format error"}];
    }

    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970] * 1000;
    NSMutableDictionary *notifData = [NSMutableDictionary dictionaryWithCapacity:2];
    if (!error && !responseDataError) {
        NSArray *patchList = nil;
        id patchListData = dataDict[KBDDYCURLResponseDataKey];
        if ([patchListData isKindOfClass:[NSDictionary class]]) {
            patchList = [(NSDictionary*)patchListData objectForKey:kBDDYCQuaterbackListRespKey];
        }
        [notifData setValue:patchList?:@[] forKey:kBDDQuaterbackFetchListKey];
        if (patchList.count == 0) {
            NSDictionary *data = @{@"timestamp":[NSNumber numberWithDouble:interval],
                                   @"status":@"patch list is nil",
                                   @"request_des":request.description?:@"",
                                   @"response_des":responseDescription?:@"",
                                   @"resopnse_data":dataDict?:@{},
            };
            [BDDYCMonitorGet() trackService:kBDDYQuaterbackListDownloadStatusMonitorServiceName status:kBDDQuaterbackListDowmLoadStatusSuccessButPatchListIsEmpty extra:data];
            [notifData setValue:@(kBDDQuaterbackListDowmLoadStatusSuccessButPatchListIsEmpty) forKey:kBDDYQuaterbackListDownloadStatusMonitorServiceName?:@""];
            BDALOG_PROTOCOL_INFO_TAG(@"Better", @"%@",data);
        } else {
            NSDictionary *data = @{@"list":dataDict,
                                   @"timestamp":[NSNumber numberWithDouble:interval],
            };
            [BDDYCMonitorGet() trackService:kBDDYQuaterbackListDownloadStatusMonitorServiceName status:kBDQuaterbackListDowmLoadStatusSuccessAndPatchListNotEmpty extra:data];
            [notifData setValue:@(kBDQuaterbackListDowmLoadStatusSuccessAndPatchListNotEmpty) forKey:kBDDYQuaterbackListDownloadStatusMonitorServiceName?:@""];
            BDALOG_PROTOCOL_INFO_TAG(@"Better", @"%@",data);
            //                [self setLastDidSuccessGetPatchListTime:CACurrentMediaTime()];
        }
    } else {
        NSDictionary *data = @{@"error":error.description?:@"",
                               @"response_data_error":responseDataError.description?:@"",
                               @"timestamp":[NSNumber numberWithDouble:interval],
                               @"http code":@(statusCode),
                               @"description":responseDescription?:@"",
        };
        [BDDYCMonitorGet() trackService:kBDDYQuaterbackListDownloadStatusMonitorServiceName status:kBDQuaterbackListDowmLoadStatusError extra:data];
        [notifData setValue:@(kBDQuaterbackListDowmLoadStatusError) forKey:kBDDYQuaterbackListDownloadStatusMonitorServiceName?:@""];
        BDALOG_PROTOCOL_ERROR_TAG(@"Better", @"%@",data);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kBDDQuaterbackDidFetchList object:[notifData copy]];
    if ([[BDBDQuaterback sharedMain].delegate respondsToSelector:@selector(didFailFetchListWithError:)]) {
        [[BDBDQuaterback sharedMain].delegate didFailFetchListWithError:error?:responseDataError];
    }
    NSArray *moduleModels = [BDDYCModuleModel modelsWithDictionary:modelDataDict];
    !completionHandler ? : completionHandler(moduleModels, (error ? : responseDataError));
}

#pragma mark - step2

// 下载某个补丁至指定目录
+ (BDDYCModuleSessionTask *)fetchModule:(BDDYCModuleModel *)aModel
                            toDirecotry:(NSString *)fileDir
                            requestType:(kBDDYCModuleRequestType)requestType
                             completion:(void (^)(id, NSError *))completionHandler
{
    BDDYCModuleSessionTask *aModuleTask;
    __weak typeof(BDDYCModuleSessionTask *) weakModuleTask = aModuleTask;
    aModuleTask = [self startFetchModule:aModel toDirecotry:fileDir requestType:requestType completion:^(id module, NSError *error) {
        if (error && [aModel containsAvailableUrl]) {
            // Retry
            BDDYCModuleSessionTask *aRetryModuleTask = [self fetchModule:aModel toDirecotry:fileDir requestType:requestType completion:^(id retryModule, NSError *retryError) {
                
                !completionHandler ? : completionHandler(retryModule, retryError);
                
            }];
            
            if (aRetryModuleTask) {
                [weakModuleTask.retryTasks addObject:aRetryModuleTask];
            }
            
            return;
        }

        !completionHandler ? : completionHandler(module, error);
    }];
    return aModuleTask;
}

+ (BDDYCModuleSessionTask *)startFetchModule:(BDDYCModuleModel *)aModel
                                 toDirecotry:(NSString *)fileDir
                                 requestType:(kBDDYCModuleRequestType)requestType
                                  completion:(void (^)(id, NSError *))completionHandler
{
    if (!aModel.url && [aModel.backupUrls count] == 0) { BDDYCAssert(NO && "download url cann't be nil"); }
    
    if (!aModel || ![aModel containsAvailableUrl]) {
        NSError *error = [aModel lastDownloadError];
        if (!error) error = [NSError errorWithDomain:BDDYCErrorDomain
                                                code:BDDYCErrCodeDataError
                                            userInfo:@{NSLocalizedDescriptionKey: @"url and backupurls are empty"}];
        !completionHandler ? : completionHandler(nil, error);
        
        return nil;
    }
    
    NSString *urlString = [aModel nextDownloadUrl];
    [aModel startDownloadUrl:urlString];
    
    // create task
//    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]
//                                             cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
//                                         timeoutInterval:30.0];
    
    // [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    CFTimeInterval downloadStart = CACurrentMediaTime();
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *tmpDirectory = NSTemporaryDirectory();
    NSString *zipTmpPathStr = [tmpDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"module_alpha_%@_%@_%@",
                                                                                aModel.name,
                                                                                appVersion,
                                                                                aModel.version]];
    NSURL *destination = [NSURL fileURLWithPath:zipTmpPathStr];
    
    switch (requestType) {
        case kBDDYCModuleRequestTypeNSURLSession:
        {
            BDALOG_PROTOCOL_INFO_TAG(@"Better", @"%@: download patch NSURLSession",zipTmpPathStr);
            // create task
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                                     cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                 timeoutInterval:30.0];
            
            NSURLSessionDataTask *task= [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
//                // temporary files and directories
//                NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
//                NSString *tmpDirectory = NSTemporaryDirectory();
//                NSString *zipTmpPath = [tmpDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"module_alpha_%@_%@_%@",
//                                                                                     aModel.name,
//                                                                                     appVersion,
//                                                                                     aModel.version]];
                
                
                // if the processing flow is failure
                BOOL isFailed = NO;
                
                // save data to tmp file
                BOOL success = [data writeToFile:zipTmpPathStr atomically:YES];
                if (success) {
                    [self handleModuleRequestWithData:data zipTmpPath:zipTmpPathStr aModel:aModel error:error toDirecotry:fileDir urlString:urlString completion:completionHandler];
                } else {
                    BDALOG_PROTOCOL_ERROR_TAG(@"Better", @"%@:  save data to tmp file",zipTmpPathStr);
                }

            }];
            [task resume];
            return [[BDDYCModuleSessionTask alloc] initWithURLTask:task];
        }
            break;
            
        default:
        {
            BDALOG_PROTOCOL_INFO_TAG(@"Better", @"%@: download patch TTNet",zipTmpPathStr);
            TTHttpTask *task = [[TTNetworkManager shareInstance] downloadTaskWithRequest:urlString parameters:nil headerField:@{} needCommonParams:NO progress:nil destination:destination completionHandler:^(TTHttpResponse *response, NSURL *filePath, NSError *error) {
                
                NSData *data = [NSData dataWithContentsOfURL:destination];
                NSString *zipTmpPath = filePath.path;
                [self handleModuleRequestWithData:data zipTmpPath:zipTmpPath aModel:aModel error:error toDirecotry:fileDir urlString:urlString completion:completionHandler];
            }];
            return [[BDDYCModuleSessionTask alloc] initWithURLTask:task];
        }
            break;
    }

}

+ (void)handleModuleRequestWithData:(NSData *)data zipTmpPath:(NSString *)zipTmpPath aModel:(BDDYCModuleModel *)aModel error:(NSError *)error toDirecotry:(NSString *)fileDir urlString:(NSString *)urlString completion:(void (^)(id, NSError *))completionHandler  {
    
//    NSString *zipTmpPath = filePath.path;
    BOOL isFailed = NO;
    // 1. verify file md5
    if (data.length > 0) {
        NSString *md5 = [BDDYCSecurity MD5File:zipTmpPath];
        if (![aModel.md5 isEqualToString:md5]) {
            BDALOG_PROTOCOL_ERROR_TAG(@"Better", @"%@: md5 doesn't match, module md5: %@ file md5: %@", BDDYCErrorDomain, aModel.md5, md5);
            isFailed = YES;
            error = [NSError errorWithDomain:BDDYCErrorDomain
                                        code:BDDYCErrCodeVerifyFailed
                                    userInfo:@{NSLocalizedDescriptionKey: @"md5 doesn't match"}];
            !completionHandler ? : completionHandler(nil, error);
            return;
        }
    } else {
//            NSLog(@"%@: write data: %@ to file: %@ fail", BDDYCErrorDomain, data, zipTmpPath);
        BDALOG_PROTOCOL_ERROR_TAG(@"Better",@"%@: write data: %@ to file: %@ fail", BDDYCErrorDomain, data, zipTmpPath);
        isFailed = YES;
        error = [NSError errorWithDomain:BDDYCErrorDomain
                                    code:BDDYCErrCodeUnknown
                                userInfo:@{NSLocalizedDescriptionKey: @"write data to file fails"}];
        !completionHandler ? : completionHandler(nil, error);
        return;
    }

    // @[@"com.dynamically.privatekey.1",
    //  @"com.dynamically.privatekey.2",
    //  @"com.dynamically.privatekey.3"][arc4random()%3];
    // privateKey = [privateKey stringByAppendingString:@".com.ip.20080618"];
    NSString *privateKey = [NSString stringWithFormat:@"com.dynamically.%@", [BDDYCSecurity randomKeyString]];
    // Close encrypt file
    privateKey = @"eThWmZq4t7w!z%C*F-JaNcRfUjXn2r5u8x/A?D(G+KbPeSgVkYp3s6v9y$B&E)H@McQfTjWmZq4t7w!z%C*F-JaNdRgUkXp2s5u8x/A?D(G+KbPeShVmYq3t6w9y$B&E";
    NSMutableArray *moduleFiles = [NSMutableArray new];
    __block NSError *unzipError;
    //        NSString *const kBDDYCQuaterbackUnzipTime
    CFTimeInterval unzipStart = CACurrentMediaTime();
    BOOL unzipOk = [BDDYCZipArchive unzipFileAtPath:zipTmpPath toDestination:kBDDYCQuaterbackModuleDirectory(aModel.name) privateKey:privateKey completion:^(NSArray<NSString *> *filePaths, NSError *error1) {
        CFTimeInterval unzipEnd = CACurrentMediaTime();
        [BDDYCMonitorGet() event:kBDDYCQuaterbackUnzipTime label:@"label" durations:(unzipEnd - unzipStart)*1000 needAggregate:YES];
        if (filePaths) [moduleFiles addObjectsFromArray:filePaths];
        unzipError = error1;
    }];

    if (!isFailed && (!unzipOk || unzipError)) {
        BDALOG_PROTOCOL_ERROR_TAG(@"Better",@"%@: fail to unzip file: %@", BDDYCErrorDomain, zipTmpPath);
        isFailed = YES;
        error = [NSError errorWithDomain:BDDYCErrorDomain
                                    code:BDDYCErrCodeUnzipFailed
                                userInfo:@{NSLocalizedDescriptionKey: @"fail to unzip file"}];
        !completionHandler ? : completionHandler(nil, error);
        return;
    }

    BDBDModule *aDYCModule = nil;
    // success or contain files
    if (!isFailed || moduleFiles.count > 0) {
        BDALOG_PROTOCOL_INFO_TAG(@"Better",@"download module [%@] : url (%@), files (%@)", aModel.name, urlString, moduleFiles);

        aDYCModule = [BDBDModule moduleWithFiles:moduleFiles];
        aDYCModule.moduleModel = aModel;
        aDYCModule.moduleModel.privateKey = privateKey;
        [BDDYCMonitorGet() trackService:kBDDYCQuaterbackDownloadend metric:nil category:[aDYCModule toPropertyListDictionary] extra:nil];
        !completionHandler ? : completionHandler(aDYCModule, nil);
    } else {
        aDYCModule = [BDBDModule moduleWithFiles:moduleFiles]?:[BDBDModule new];
        aDYCModule.moduleModel = aModel;
        aDYCModule.moduleModel.privateKey = privateKey;
        [aModel recordError:error forDownloadUrl:urlString];
        !completionHandler ? : completionHandler(nil, error);
    }
    if ([[BDBDQuaterback sharedMain].delegate respondsToSelector:@selector(moduleData:didFetchWithError:)]) {
        [[BDBDQuaterback sharedMain].delegate moduleData:aModel didFetchWithError:error];
    }


    // clear temporary files
    [[NSFileManager defaultManager] removeItemAtPath:zipTmpPath error:nil];
}

#pragma mark -

+ (void)unzipZipFile:(NSString *)zipPath
         toDirecotry:(NSString *)fileDir
          completion:(void (^)(id aDYCModule, NSError *error))completionHandler
{
    if (!zipPath || ![[NSFileManager defaultManager] fileExistsAtPath:zipPath]) {
        NSError *error = [NSError errorWithDomain:BDDYCErrorDomain
                                             code:BDDYCErrCodeUnknown
                                         userInfo:@{NSLocalizedDescriptionKey: @"zip文件不存在"}];
        !completionHandler ? : completionHandler(nil, error);
        return;
    }
    
    if (!fileDir || ![[NSFileManager defaultManager] fileExistsAtPath:fileDir]) {
        NSError *error = [NSError errorWithDomain:BDDYCErrorDomain
                                             code:BDDYCErrCodeUnknown
                                         userInfo:@{NSLocalizedDescriptionKey: @"解压目录为空或不存在"}];
        !completionHandler ? : completionHandler(nil, error);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        // if the processing flow is failed
        BOOL isFailed = NO;
        NSError *error;
        
        // Close encrypt file
        NSString *privateKey = nil;
        NSMutableArray *moduleFiles = [NSMutableArray new];
        __block NSError *unzipError;
        BOOL unzipOk = [BDDYCZipArchive unzipFileAtPath:zipPath toDestination:fileDir privateKey:privateKey completion:^(NSArray<NSString *> *filePaths, NSError *error1) {
            if (filePaths) [moduleFiles addObjectsFromArray:filePaths];
            unzipError = error1;
        }];
        
        if (!isFailed && (!unzipOk || unzipError)) {
            BDALOG_PROTOCOL_ERROR_TAG(@"%@: fail to unzip file: %@", BDDYCErrorDomain, zipPath);
            isFailed = YES;
            error = [NSError errorWithDomain:BDDYCErrorDomain
                                        code:BDDYCErrCodeUnzipFailed
                                    userInfo:@{NSLocalizedDescriptionKey: @"fail to unzip file"}];
        }
        
        // success or contain files
        if (!isFailed || moduleFiles.count > 0) {
            BDBDModule *aDYCModule = [BDBDModule moduleWithFiles:moduleFiles];
            aDYCModule.moduleModel.privateKey = privateKey;
            dispatch_async(dispatch_get_main_queue(), ^{
                !completionHandler ? : completionHandler(aDYCModule, nil);
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                !completionHandler ? : completionHandler(nil, error);
            });
        }
    });
}

@end
