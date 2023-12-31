
/*!@file HMDCrashLoadBackgroundSession.m
   @author somebody
   @abstract crash load launch background session
 */

#import "HMDMacro.h"
#import "HMDCrashLoadLogger.h"
#import "NSDictionary+HMDJSON.h"
#import "HMDCrashLoadLogger+Path.h"
#import "HMDCrashLoadBackgroundSession.h"

#define CLOAD_BS_TIMEOUT 4.0

CLANG_ATTR_OBJC_DIRECT_MEMBERS
@interface HMDCrashLoadBackgroundSession () <NSURLSessionDataDelegate>

@property(direct, nonatomic, nullable) NSURL *uploadURL;
@property(direct, nonatomic, nullable) NSOperationQueue *queue;
@property(direct, nonatomic, nullable) NSURLSession *session;

#pragma mark - Access only in queue (init from main thread)

@property(direct, nonatomic, nullable) NSString *loadPrepared;

// (KEY, Data) KEY is the fileName, taskDescriptor associated with task
@property(direct, nonatomic, nullable)
    NSMutableDictionary<NSString *, NSMutableData *> *dataDictionary;

@property(direct, nonatomic) BOOL previousTaskQueried;

@property(direct, nonatomic, nullable) NSMutableArray *previousUploadingOnQueue;

@property(direct, nonatomic, nullable) NSMutableArray *retriedUploadingOnQueue;

#pragma mark - Synchronized between queue and main thread
#pragma mark   Access from main thread only if dispatch wait successfully

// 在 queue 创造
@property(direct, nonatomic, nullable) NSArray<NSString *> *previousUploadingAsync;

#pragma mark - Access only in main thread

// 上次启动上报的内容
@property(direct, nonatomic, nullable, readwrite) NSArray<NSString *> *previousUploading;

@end

@implementation HMDCrashLoadBackgroundSession

#pragma mark - initialization (main thread)

- (instancetype)initWithContext:(HMDCLoadContext *)context {
    
    if(unlikely((self = [super init]) == nil))
        DEBUG_RETURN(nil);
    
    self.loadPrepared = context.loadPrepared;
    self.uploadURL = context.uploadingURL;
    self.dataDictionary = NSMutableDictionary.dictionary;
    self.previousUploadingOnQueue = NSMutableArray.array;
    self.retriedUploadingOnQueue  = NSMutableArray.array;
    
    NSString *identifier = @"com.heimdallr.crash.loadLaunch";
     
    CLOAD_LOG("[Upload] create background session %s", identifier.UTF8String);
    
    NSURLSessionConfiguration *config =
        [NSURLSessionConfiguration
        backgroundSessionConfigurationWithIdentifier:identifier];
    
    // disable launch event because we can't handle it in AppDelegate
    config.sessionSendsLaunchEvents = NO;
    
    NSOperationQueue *queue = NSOperationQueue.alloc.init;
    queue.maxConcurrentOperationCount = 1;
    queue.name = @"com.heimdallr.crash.loadLaunch.backgroundSession";
    self.queue = queue;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config
                                                          delegate:self
                                                     delegateQueue:queue];
    self.session = session;
    
    queue.qualityOfService = NSQualityOfServiceUserInteractive;
    
    [self previousUploadingTask];
    
    queue.qualityOfService = NSQualityOfServiceDefault;
    
    return self;
}

+ (instancetype)sessionWithContext:(HMDCLoadContext *)context {
    return [[self alloc] initWithContext:context];
}

#pragma mark - Request (main thread or queue if retry)

- (NSURLRequest *)requestForFileName:(NSString *)fileName {
    NSURL *uploadURL = self.uploadURL;
    
    if(uploadURL == nil) DEBUG_RETURN(nil);
    
    BOOL isGzip = NO;
    if([fileName containsString:@".g"]) {
         isGzip = YES;
    }
    
    NSMutableURLRequest *request;
    request = [NSMutableURLRequest requestWithURL:uploadURL];
    
    request.timeoutInterval = 60;
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"1" forHTTPHeaderField:@"Background-Session"];
    if (isGzip) {
        [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
    }
    [request setValue:@"multipart/form-data;boundary=AaB03x"
    forHTTPHeaderField:@"Content-Type"];
    
    request.HTTPMethod = @"POST";
    
    return request;
}

#pragma mark - previous upload tasks (main thread)

- (void)previousUploadingTask {
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self.session getTasksWithCompletionHandler:
        ^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks,
          NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks,
          NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        
        DEBUG_ASSERT(!self.previousTaskQueried);
        
        for(NSURLSessionUploadTask *eachTask in uploadTasks) {
            NSString *fileName = eachTask.taskDescription;
            
            if(fileName == nil) {
                CLOAD_LOG("[Upload][Warning] unnamed previous uploading task");
                continue;
            }
            
            CLOAD_LOG("[Upload][Previous] %s", fileName.UTF8String);
            
            [self.previousUploadingOnQueue addObject:fileName];
        }
        
        self.previousUploadingAsync =
            [NSArray arrayWithArray:self.previousUploadingOnQueue];
        
        self.previousTaskQueried = YES;
        
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_time_t timeout =
        dispatch_time(DISPATCH_TIME_NOW,
                     (int64_t)(CLOAD_BS_TIMEOUT * NSEC_PER_SEC));

    
    intptr_t successFlag = dispatch_semaphore_wait(semaphore, timeout);
    
    if(likely(successFlag)) {
        
        DEVELOP_DEBUG_ASSERT(self.previousUploadingAsync != nil);
        self.previousUploading = self.previousUploadingAsync;
    }
}

#pragma mark - upload (main thread)

- (void)uploadPath:(NSString *)path name:(NSString *)name {
    DEBUG_ASSERT([path.lastPathComponent isEqual:name]);
    
    NSFileManager *manager = NSFileManager.defaultManager;
    
    BOOL isDirectory = NO;
    BOOL isExist = [manager fileExistsAtPath:path
                                 isDirectory:&isDirectory];
    
    if(unlikely(!isExist)) {
        CLOAD_LOG("[Upload] crash log not exist at path %s", path.UTF8String);
        
        DEBUG_RETURN_NONE;
    }
    
    if(unlikely(isDirectory)) {
        CLOAD_LOG("[Upload] crash log is directory at path %s", path.UTF8String);
        
        DEBUG_RETURN_NONE;
    }
    
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    
    if(fileURL == nil) {
        CLOAD_LOG("[Upload] failed to construct file URL at path %s",
                  path.UTF8String);
        
        DEBUG_RETURN_NONE;
    }
    
    NSURLRequest *request = [self requestForFileName:name];
    
    NSURLSessionUploadTask *task = nil;
    
    @try {
        // Crash: NSException Cannot read file at
        // file:///var/mobile/Containers/Data/Application/DEADA423-7691-4B46-8425-B4A13179081F/
        // Library/Heimdallr/CrashCapture/LoadLaunch/Prepared/22595461-C395-4799-9A18-35D4C0620EBB.gzip
        //
        // the user is a jailbreak user with two crashes. I don't know why it
        // can not read the file, since the file is verified as exisitng previously
        // and the file can only be delete by uploading inside this app life cycle
        task = [self.session uploadTaskWithRequest:request fromFile:fileURL];
        
    } @catch (NSException *exception) {
        
        // this is not an assert, bu act as a breakpoint
        DEBUG_ASSERT(exception == nil);
        
        CLOAD_LOG("[Upload][Crash] %s uploading file path %s",
                  exception.reason.UTF8String, CLOAD_PATH(path));
        
        CLOAD_LOG("[DIR] delete %s, uploading crashed",
                  CLOAD_PATH(path));
        
        [manager removeItemAtPath:path error:nil];
        
        DEBUG_RETURN_NONE;
    }
    
    task.taskDescription = name;
    
    CLOAD_LOG("[Upload][Task] %p %s start uploading", task, name.UTF8String);
    
    [task resume];
}

#pragma mark - callback (queue)

- (void)taskFinished:(NSURLSessionDataTask *)task
             success:(BOOL)successFlag
        responseData:(NSData *)responseData {
    DEBUG_ASSERT(NSOperationQueue.currentQueue == self.queue);
    
    BOOL isPrevious = [self logTaskReturnPrevious:task];
    
    if (successFlag) {
        successFlag = responseDataMeansSuccess(task, responseData);
    }
    
    if(successFlag) {
        [self uploadSuccess:task];
        return;
    }
    
    // give previous task a change to retry
    [self uploadFailed:task needRetry:isPrevious];
}

/*!@method logTaskReturnPrevious:
   @param task the task just finished on queue which is called with taskFinished
   @return wether this is previous uploading task
   @note previous uploading task means task not launched by this application during current life time
 */
- (BOOL)logTaskReturnPrevious:(NSURLSessionDataTask *)task {
    DEBUG_ASSERT(NSOperationQueue.currentQueue == self.queue);
    
    NSString *fileName = task.taskDescription;
    if(fileName == nil) DEBUG_RETURN(NO);
    
    if(likely(self.previousTaskQueried))
        return [self.previousUploadingOnQueue containsObject:fileName];
    
    if([self.retriedUploadingOnQueue containsObject:fileName])
        return NO;
    
    CLOAD_LOG("[Upload][Previous] %s", fileName.UTF8String);
    
    [self.previousUploadingOnQueue addObject:fileName];
    
    return YES;
}

static BOOL responseDataMeansSuccess(NSURLSessionDataTask *task,
                                     NSData *responseData) {
    if(responseData == nil) {
        CLOAD_LOG("[Upload] task %s response data is nil, which means "
                  "uploading failed", task.taskDescription.UTF8String);
        return NO;
    }
    
    id maybeDictionary =
    [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
    
    BOOL jsonFailed = ((maybeDictionary == nil) ||
                      ![maybeDictionary isKindOfClass:NSDictionary.class]);
    
    if(unlikely(jsonFailed)) {
        CLOAD_LOG("[Upload] crash upload %s response data JSON serialization "
                  "failed which means uploading failed",
                  task.taskDescription.UTF8String);
        return NO;
    }
    
    NSDictionary * _Nonnull dictionary = maybeDictionary;
    
    
    
    // 真实返回数据是:
    // {
    //     "magic_tag": "ss_app_log",
    //     "message": "success"
    // }
    //
    // 实际上 TTNet 会把返回数据包装成
    // {
    //     "result": {
    //         "message": "(string) xxx",    // maybe success
    //         "magic_tag": "ss_app_log"
    //     },
    //     "status_code": 200
    // }
    
    NSString *message = [dictionary hmd_stringForKey:@"message"];
    
    if([message isEqualToString:@"success"])
        return YES;
    
    CLOAD_LOG("[Upload] unable to find message-success for crash %s, "
              "try case compare", task.taskDescription.UTF8String);
    
    NSEnumerator<NSString *> *enumerator = dictionary.keyEnumerator;
    
    id maybeStringKey;
    
    while((maybeStringKey = enumerator.nextObject) != nil) {
        
        if(![maybeStringKey isKindOfClass:NSString.class])
            DEBUG_CONTINUE;
        
        NSString *stringKey = maybeStringKey;
        
        if([stringKey caseInsensitiveCompare:@"message"] != NSOrderedSame)
            continue;
        
        NSString *message = [dictionary hmd_stringForKey:stringKey];
        
        if(message == nil) continue;
        
        if([message caseInsensitiveCompare:@"success"] != NSOrderedSame)
            continue;
        
        CLOAD_LOG("[Upload] found case insensitive compare success for "
                  "crash %s", task.taskDescription.UTF8String);
        
        return YES;
    }
    
    CLOAD_LOG("[Upload] crash upload %s failed, message %s, code %u",
              task.taskDescription.UTF8String, message.UTF8String,
              [dictionary hmd_unsignedIntForKey:@"status_code"]);
    
    return NO;
}

#pragma mark - Result (queue)

- (void)uploadSuccess:(NSURLSessionDataTask *)task {
    DEBUG_ASSERT(NSOperationQueue.currentQueue == self.queue);
    
    NSString *fileName = task.taskDescription;
    
    CLOAD_LOG("[Upload] crash log %s successfully", fileName.UTF8String);
    
    if(fileName == nil) DEBUG_RETURN_NONE;
    if(fileName.length == 0) DEBUG_RETURN_NONE;
    
    NSString *filePath =
        [self.loadPrepared stringByAppendingPathComponent:fileName];
    
    NSFileManager *manager = NSFileManager.defaultManager;
    
    BOOL isDirectory = NO;
    BOOL isExist = [manager fileExistsAtPath:filePath
                                 isDirectory:&isDirectory];
    
    if(unlikely(!isExist)) {
        CLOAD_LOG("[Upload][Task] %p %s finish without file",
                  task, fileName.UTF8String);
        
        CLOAD_LOG("[Upload] crash log %s successfully, but crash file not exist "
                  "at path %s", fileName.UTF8String, CLOAD_PATH(filePath));
        DEVELOP_DEBUG_RETURN_NONE;
    }
    
    if(unlikely(isDirectory)) {
        CLOAD_LOG("[Upload] crash log %s successfully, but crash file is directory "
                  "at path %s", fileName.UTF8String, filePath.UTF8String);
        DEBUG_RETURN_NONE;
    }
    
    CLOAD_LOG("[DIR] delete %s, crash upload successfully",
              filePath.UTF8String);
    
    [manager removeItemAtPath:filePath error:nil];
}

- (void)uploadFailed:(NSURLSessionDataTask *)task
           needRetry:(BOOL)needRetry {
    DEBUG_ASSERT(NSOperationQueue.currentQueue == self.queue);
    
    NSString *name = task.taskDescription;
    CLOAD_LOG("[Upload] crash log %s failed", name.UTF8String);
    
    if(!needRetry) return;
    
    CLOAD_LOG("[Upload] retry for %s", name.UTF8String);
    
    NSString *path = [self.loadPrepared stringByAppendingPathComponent:name];
    
    NSFileManager *manager = NSFileManager.defaultManager;
    
    BOOL isDirectory = NO;
    BOOL isExist = [manager fileExistsAtPath:path
                                 isDirectory:&isDirectory];
    
    if(unlikely(!isExist)) {
        CLOAD_LOG("[Upload] retry crash log not exist at path %s", path.UTF8String);
        return;
    }
    
    if(unlikely(isDirectory)) {
        CLOAD_LOG("[Upload] retry crash log is directory at path %s", path.UTF8String);
        return;
    }
    
    [self.retriedUploadingOnQueue addObject:name];
    
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    
    NSURLRequest *request = [self requestForFileName:name];
    
    NSURLSessionUploadTask *retryTask;
    retryTask = [self.session uploadTaskWithRequest:request fromFile:fileURL];
    
    retryTask.taskDescription = name;
    
    CLOAD_LOG("[Upload][Task] %p %s retry uploading", retryTask, name.UTF8String);
    
    [retryTask resume];
}

#pragma mark - URLSession delegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    DEBUG_ASSERT(NSOperationQueue.currentQueue == self.queue);
    
    NSString *name = dataTask.taskDescription;
    if(name == nil) {
        CLOAD_LOG("[Upload][Warning] receive data from unnamed task");
        return;
    }
    
    NSMutableDictionary<NSString *, NSMutableData *> *dataDictionary;
    dataDictionary = self.dataDictionary;
    
    NSMutableData * _Nullable dataCollection;
    dataCollection = [dataDictionary objectForKey:name];
    
    if(dataCollection != nil) {
        [dataCollection appendData:data];
        
        CLOAD_LOG("[Upload] %s receive data %u (total %u)", name.UTF8String,
                  (unsigned)data.length, (unsigned)dataCollection.length);
        
        return;
    }
    
    dataCollection = [NSMutableData dataWithData:data];
    
    CLOAD_LOG("[Upload] %s receive data %u first time", name.UTF8String,
              (unsigned)data.length);
    
    [dataDictionary hmd_setObject:dataCollection forKey:name];
}

- (void)  URLSession:(NSURLSession *)session
                task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    DEBUG_ASSERT(NSOperationQueue.currentQueue == self.queue);
    
    if(unlikely(![task isKindOfClass:NSURLSessionDataTask.class]))
        DEBUG_RETURN_NONE;
    
    NSURLSessionDataTask *dataTask = (NSURLSessionDataTask *)task;
    
    NSString *name = dataTask.taskDescription;
    if(name == nil) {
        CLOAD_LOG("[Upload][Warning] unnamed task finished");
        return;
    }
    
    NSMutableDictionary<NSString *, NSMutableData *> *dataDictionary;
    dataDictionary = self.dataDictionary;
    
    NSMutableData * _Nullable dataCollection;
    dataCollection = [dataDictionary objectForKey:name];
    
    if(dataCollection != nil) {
        [dataDictionary removeObjectForKey:name];
    }
    
    [self taskFinished:dataTask success:YES responseData:dataCollection];
}

- (void)       URLSession:(NSURLSession *)session
didBecomeInvalidWithError:(NSError *)error {
    DEBUG_ASSERT(NSOperationQueue.currentQueue == self.queue);
    
    CLOAD_LOG("[Upload] background Session becomes invalid with error %s",
              error.localizedDescription.UTF8String);
}

@end
