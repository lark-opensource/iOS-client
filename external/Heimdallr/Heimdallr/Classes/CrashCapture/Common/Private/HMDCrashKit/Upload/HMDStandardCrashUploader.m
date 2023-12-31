//
//  HMDStandardCrashUploader.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/22.
//

#import "HMDStandardCrashUploader.h"
#import "HMDStandardCrashUploader+URLPathProvider.h"
#import "HMDCrashEventLogger.h"
#import "HMDCrashKit+Internal.h"
// Utility
#import "HMDMacro.h"
#import "HMDMacroManager.h"
#import "HMDDynamicCall.h"
#import "HMDSimpleBackgroundTask.h"
#import "NSData+HMDJSON.h"
#import "NSDictionary+HMDHTTPQuery.h"
#import "NSDictionary+HMDSafe.h"
#import "UIApplication+HMDUtility.h"
// DeviceInfo
#import "HMDInjectedInfo.h"
// Mach
#import "HMDCrashSDKLog.h"
// Network
#import "HMDNetworkManager.h"
#import "HMDNetworkUploadModel.h"
#import "HMDURLBackgrounSessionManager.h"
#import "HMDUploadHelper.h"
#if RANGERSAPM
#import "RangersAPMUploadHelper.h"
#endif
// PrivateServices
#import "HMDDebugLogger.h"
#import "HMDServerStateService.h"
#import "HMDURLManager.h"

#define HMD_CRASH_FILE_BOUNDARY @"AaB03x"

NSString *hmd_crash_uploader_background_task = @"hmd_crash_uploader_background_task";
NSString *hmd_crash_uploader_background_session = @"hmd_crash_uploader_background_session";

// hardcode
static NSString * const HMD_kTTNetColdStartFinishNotification = @"kTTNetColdStartFinishNotification";

@interface HMDStandardCrashUploader () <HMDURLBackgrounSessionManagerDelegate>

@property (nonatomic, strong) dispatch_queue_t uploadQueue;
@property (nonatomic, strong) HMDURLBackgrounSessionManager *backgroundSessionManager;
@property (nonatomic, assign) BOOL isBackgroundSessionInvalid;
@property (nonatomic, strong) NSMutableSet *uploadingFileNames;
@property (nonatomic, strong) NSMutableSet *previousUploadFileNames;
@property (nonatomic, copy) NSString *crashPath;
@property (atomic, assign) BOOL ttnetReady;
@property (nonatomic, assign) CFTimeInterval lastCrashTimestamp;

@end

@implementation HMDStandardCrashUploader

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _crashPath = path;
        _uploadQueue = dispatch_queue_create("com.heimdallr.crashlog.upload", DISPATCH_QUEUE_SERIAL);
        _uploadingFileNames = [NSMutableSet setWithCapacity:4];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        if ([HMDInjectedInfo defaultInfo].useTTNetUploadCrash) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ttnetReadyNotification) name:HMD_kTTNetColdStartFinishNotification object:nil];
        }
    }
    return self;
}

- (void)ttnetReadyNotification {
    self.ttnetReady = YES;
    [self asyncUploadCrashLogIfNeeded];
}

#pragma mark - crashlog upload

- (void)setLastCrashTimestamp:(CFTimeInterval)crashTimestamp {
    _lastCrashTimestamp = crashTimestamp;
}

- (void)uploadCrashLogIfNeeded:(BOOL)needSync {
    if(needSync) {
        [self syncUploadCrashLogIfNeeded];
    } else {
        [self asyncUploadCrashLogIfNeeded];
    }
}

- (void)syncUploadCrashLogIfNeeded {
    dispatch_sync(self.uploadQueue, ^{
        [self _uploadCrashLogIfNeeded];
    });
}

- (void)asyncUploadCrashLogIfNeeded {
    dispatch_async(self.uploadQueue, ^{
        [self _uploadCrashLogIfNeeded];
    });
}

- (void)_uploadCrashLogIfNeeded {
#if !RANGERSAPM
    if (HMD_IS_DEBUG) return;
    
    HMDStopUpload crashStopUpload = [HMDInjectedInfo defaultInfo].crashStopUpload;
    if (crashStopUpload && crashStopUpload()) {
        return;
    }
#endif
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self.crashPath]) {
        return;
    }
    
    NSEnumerator *filesEnumerator = [[fileManager contentsOfDirectoryAtPath:self.crashPath error:nil] objectEnumerator];
    NSString *fileName;
    
    while ((fileName = [filesEnumerator nextObject]) != nil) {
        
        NSString *filePath = [self.crashPath stringByAppendingPathComponent:fileName];
        
        if (![HMDInjectedInfo defaultInfo].useTTNetUploadCrash) {
            [self createBackgroundSessionManagerIfNeed];
        }
        if ([self.uploadingFileNames containsObject:fileName]) {//uploading
            continue;
        }
        
        [self _uploadCrashLogForPath:filePath];
    }
}

- (void)_uploadCrashLogForFileName:(NSString *)fileName {
    NSString *filePath = [self.crashPath stringByAppendingPathComponent:fileName];
    [self _uploadCrashLogForPath:filePath];
}

- (void)_uploadCrashLogForPath:(NSString *)filePath {
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSAssert(NO, @"crashlog does not exists!!!");
        return;
    }
    
    [HMDDebugLogger printLog:@"Crash log is uploading..."];
    if (!hmd_is_server_available(HMDReporterCrash)) {
        return;
    }
    
#if RANGERSAPM
    NSString *appID = [filePath pathExtension];
    
    NSMutableDictionary *crashQueryDic = [NSMutableDictionary dictionaryWithDictionary:[RangersAPMUploadHelper headerInfoForAppID:appID]];
    
    BOOL useTTNetUploadCrash = NO;
#else
    NSString *appID = nil;
    BOOL useTTNetUploadCrash = [HMDInjectedInfo defaultInfo].useTTNetUploadCrash;
    if (useTTNetUploadCrash && !self.ttnetReady) {
        return;
    }
    
    NSMutableDictionary *crashQueryDic = [NSMutableDictionary dictionaryWithDictionary:[HMDUploadHelper sharedInstance].headerInfo];
    id maybeDictionary = [HMDInjectedInfo defaultInfo].commonParams;
    if (!HMDIsEmptyDictionary(maybeDictionary)) {
        [crashQueryDic addEntriesFromDictionary:[HMDInjectedInfo defaultInfo].commonParams];
    }
#endif
    NSString *crashURL = [HMDURLManager URLWithHostProvider:HMDSharedCrashKit.networkProvider pathProvider:self forAppID:appID];
    if (crashURL == nil) {
        return;
    }
    
    NSString *fileName = [filePath lastPathComponent];
    if (fileName) {
        [self.uploadingFileNames addObject:fileName];
    }
    
    BOOL isGzip = [fileName containsString:@".g"];
    BOOL isEncrypted = [fileName containsString:@".e"];
    BOOL isDump = [fileName containsString:@".d"];
    
    if (isEncrypted) {
        [crashQueryDic setObject:@"true" forKey:@"encrypt"];
    }
    if (isDump) {
        [crashQueryDic setObject:@"true" forKey:@"have_dump"];
    } else {
        [crashQueryDic setObject:@"false" forKey:@"have_dump"];
    }
    
    NSString *queryString = [crashQueryDic hmd_queryString];
    crashURL = [NSString stringWithFormat:@"%@?%@", crashURL, queryString];
    
    if (useTTNetUploadCrash || [[HMDNetworkManager sharedInstance] useCustomNetworkManager]) {
        NSMutableDictionary *headerField = [NSMutableDictionary dictionary];
        [headerField setValue:@"application/json" forKey:@"Accept"];
        [headerField setValue:@"0" forKey:@"Background-Session"];
        if (isGzip) {
            [headerField setValue:@"gzip" forKey:@"Content-Encoding"];
        }
        [headerField setValue:[NSString stringWithFormat:@"multipart/form-data;boundary=%@",HMD_CRASH_FILE_BOUNDARY] forKey:@"Content-Type"];
        
        HMDNetworkUploadModel *uploadModel = [HMDNetworkUploadModel new];
        uploadModel.uploadURL = crashURL;
        uploadModel.data = [NSData dataWithContentsOfFile:filePath];
        uploadModel.headerField = headerField;
        
        [[HMDNetworkManager sharedInstance] uploadWithModel:uploadModel callBackWithResponse:^(NSError *error, id data, NSURLResponse *response) {
            NSMutableDictionary *responseObject = [NSMutableDictionary dictionary];
            if ([response isKindOfClass:NSHTTPURLResponse.class]) {
                [responseObject setObject:@([(NSHTTPURLResponse *)response statusCode]) forKey:@"status_code"];
                NSDictionary *header = [(NSHTTPURLResponse *)response allHeaderFields];
                if (header && [header hmd_hasKey:@"Alog_quota"]) {
                    [responseObject setObject:[header hmd_stringForKey:@"Alog_quota"] forKey:@"Alog_quota"];
                }
            }
            if (response) {
                [responseObject setValue:@YES forKey:@"has_response"];
            }
            if (data) {
                NSError *jsonError = nil;
                id jsonObj = [data hmd_jsonObject:&jsonError];
                if (jsonError && !error) {
                    error = jsonError;
                }
                [responseObject hmd_setObject:jsonObj forKey:@"result"];
            }
            
            dispatch_async(self.uploadQueue, ^{
                [self handleCrashlogUpload:fileName didCompleteWithResponseObject:responseObject error:error isBackgroundSession:NO];
            });
        }];
    } else {
        NSURL *uploadURL = [NSURL URLWithString:crashURL];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:uploadURL];
        request.timeoutInterval = 60;
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setValue:@"1" forHTTPHeaderField:@"Background-Session"];
        if (isGzip) {
            [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
        }
        [request setValue:[NSString stringWithFormat:@"multipart/form-data;boundary=%@",HMD_CRASH_FILE_BOUNDARY] forHTTPHeaderField:@"Content-Type"];
#if RANGERSAPM
        NSDictionary<NSString *, NSString *> *headerDic = [RangersAPMUploadHelper headerFieldsForAppID:appID];
        [headerDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            if (!HMDIsEmptyString(key) && !HMDIsEmptyString(obj)) {
                [request setValue:obj forHTTPHeaderField:key];
            }
        }];
#endif
        request.HTTPMethod = @"POST";
        
        BOOL useBackgroundSession = self.backgroundSessionManager && !self.isBackgroundSessionInvalid && ![UIApplication hmd_isAppExtension];
        if (useBackgroundSession) {
            NSURLSessionUploadTask *task = [self.backgroundSessionManager uploadWithRequest:request filePath:filePath];
            task.taskDescription = fileName;
            return;
        }
        
        void(^defaultUploadBlock)(void) = ^{
            [[[NSURLSession sharedSession] uploadTaskWithRequest:request fromFile:[NSURL fileURLWithPath:filePath] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                NSMutableDictionary *responseObject = [NSMutableDictionary dictionary];
                if ([response isKindOfClass:NSHTTPURLResponse.class]) {
                    [responseObject setObject:@([(NSHTTPURLResponse *)response statusCode]) forKey:@"status_code"];
                    NSDictionary *header = [(NSHTTPURLResponse *)response allHeaderFields];
                    if (header && [header hmd_hasKey:@"Alog_quota"]) {
                        [responseObject setObject:[header hmd_stringForKey:@"Alog_quota"] forKey:@"Alog_quota"];
                    }
                }
                if (response) {
                    [responseObject setValue:@YES forKey:@"has_response"];
                }
                if (data) {
                    NSError *jsonError = nil;
                    id jsonObj = [data hmd_jsonObject:&jsonError];
                    if (jsonError && !error) {
                        error = jsonError;
                    }
                    [responseObject hmd_setObject:jsonObj forKey:@"result"];
                }
                
                dispatch_async(self.uploadQueue, ^{
                    [self handleCrashlogUpload:fileName didCompleteWithResponseObject:responseObject error:error isBackgroundSession:NO];
                });
            }] resume];
        };
        if ([NSThread isMainThread]) {
            dispatch_async(self.uploadQueue, defaultUploadBlock);
        }else{
            defaultUploadBlock();
        }
    }
}

- (void)handleCrashlogUpload:(NSString *)sessionID didCompleteWithResponseObject:(id)responseObject error:(NSError *)error {
    [self handleCrashlogUpload:sessionID didCompleteWithResponseObject:responseObject error:error isBackgroundSession:NO];
}

- (void)handleCrashlogUpload:(NSString *)fileName didCompleteWithResponseObject:(id)responseObject error:(NSError *)error isBackgroundSession:(BOOL)isBackgroundSession {
    if (fileName.length == 0) {
        return;
    }
    dispatch_async(self.uploadQueue, ^{
        NSString *crashlogPath = [self.crashPath stringByAppendingPathComponent:fileName];
        
        //parse response
        BOOL retryUpload = YES; //if log upload success or dropdata or dropalldata, retryUpload = NO
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *result = [(NSDictionary *)responseObject hmd_dictForKey:@"result"];
            NSString *message = [result hmd_stringForKey:@"message"];
            NSInteger statusCode = [(NSDictionary *)responseObject hmd_intForKey:@"status_code"];
            //更新容灾策略
            HMDServerState serverState = hmd_update_server_checker(HMDReporterCrash, result, statusCode);
            BOOL isDropAllData = (serverState & HMDServerStateDropAllData) == HMDServerStateDropAllData;
            if ([message isEqualToString:@"success"] || isDropAllData) {
                retryUpload = NO;
                [[NSFileManager defaultManager] removeItemAtPath:crashlogPath error:nil];
                [HMDDebugLogger printLog:@"Crash log is uploaded successfully!"];
                SDKLog("crash file upload success or DropData.");
            }
            if ((serverState & HMDServerStateDropAllData) == HMDServerStateDropData) {
                retryUpload = NO;
            }
            
            //更新Alog quota状态
            NSString *alogQuota = [(NSDictionary *)responseObject hmd_stringForKey:@"Alog_quota"];
            if (alogQuota) {
                if ([alogQuota isEqualToString:@""]) alogQuota = @"success";
                hmd_update_server_checker(HMDReporterALog, @{@"message": alogQuota}, 200);
            }
            //upload the latest alog file before Crash
            CFTimeInterval crashTime = self.lastCrashTimestamp;
            
            BOOL shouldUpload = DC_IS(DC_OB(DC_CL(HMDLogUploader, sharedInstance), shouldUploadAlogIfCrashed), NSNumber).boolValue;
            if (shouldUpload && crashTime > 0) {
                DC_OB(DC_CL(HMDLogUploader, sharedInstance), crashALogUploadWithEndTime:, crashTime);
            }
        }
        [self.uploadingFileNames removeObject:fileName];
        
        //针对刚刚启动就回调失败的case，重试一次
        if (retryUpload) {
            if ([self.previousUploadFileNames containsObject:fileName]) {
                [self _uploadCrashLogForFileName:fileName];
            }
            SDKLog("crash file upload fail.");
        }
        [self.previousUploadFileNames removeObject:fileName];
        
        if (self.uploadingFileNames.count == 0 && ![HMDInjectedInfo defaultInfo].useTTNetUploadCrash) {
            [HMDSimpleBackgroundTask endBackgroundTaskWithName:hmd_crash_uploader_background_task];
        }
#if !RANGERSAPM
        [HMDCrashEventLogger logUploadEvent:crashlogPath error:error backgroundSession:isBackgroundSession];
#endif
    });
}

#pragma mark - BackgroundSession

- (void)createBackgroundSessionManagerIfNeed {
    if (self.backgroundSessionManager || [HMDInjectedInfo defaultInfo].useTTNetUploadCrash || [[HMDNetworkManager sharedInstance] useCustomNetworkManager]) {
        return;
    }
    NSURLSessionConfiguration *backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:hmd_crash_uploader_background_session];
    backgroundConfiguration.sessionSendsLaunchEvents = NO; //disable launch event because we can't hanle it in AppDelegate
    self.backgroundSessionManager = [[HMDURLBackgrounSessionManager alloc] initWithDelegate:self configuration:backgroundConfiguration];
    NSArray *uploadTasks = [self.backgroundSessionManager getAllUploadTasks];
    if (uploadTasks.count) {
        if (!self.previousUploadFileNames) {
            self.previousUploadFileNames = [NSMutableSet set];
        }
    }
    [uploadTasks enumerateObjectsUsingBlock:^(NSURLSessionTask *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.taskDescription) {
            [self.previousUploadFileNames addObject:obj.taskDescription];
            [self.uploadingFileNames addObject:obj.taskDescription];
        }
    }];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithResponseObject:(id)responseObject error:(NSError *)error {
    NSString *fileName = task.taskDescription;
    [self handleCrashlogUpload:fileName didCompleteWithResponseObject:responseObject error:error isBackgroundSession:YES];
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    dispatch_async(self.uploadQueue, ^{
        self.isBackgroundSessionInvalid = YES;
    });
}

#pragma mark - application state

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    [self asyncUploadCrashLogIfNeeded];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    if ([HMDInjectedInfo defaultInfo].useTTNetUploadCrash) {
        [self asyncUploadCrashLogIfNeeded];
    } else {
        @weakify(self);
        [HMDSimpleBackgroundTask detachBackgroundTaskWithName:hmd_crash_uploader_background_task task:^(void (^ _Nonnull completeHandle)(void)) {
            @strongify(self);
            [self asyncUploadCrashLogIfNeeded];
            dispatch_async(self.uploadQueue, ^{
                @strongify(self);
                if (self.uploadingFileNames.count == 0) {
                    [HMDSimpleBackgroundTask endBackgroundTaskWithName:hmd_crash_uploader_background_task];
                } else {
                    //handle in upload call back
                }
            });
        }];
    }
}

@end
