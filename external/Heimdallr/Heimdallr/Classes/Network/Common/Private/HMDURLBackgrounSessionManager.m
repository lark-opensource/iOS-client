//
//  HMDURLBackgrounSessionManager.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/5/14.
//

#import "HMDURLBackgrounSessionManager.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDJSON.h"
@interface HMDURLBackgrounSessionManager ()<NSURLSessionDataDelegate>
@property (nonatomic,strong) NSURLSession *session;
@property (nonatomic,strong) NSMutableDictionary *responseDataDict;
@end

@implementation HMDURLBackgrounSessionManager

- (instancetype)init
{
    return nil;
}

- (instancetype)initWithDelegate:(id<HMDURLBackgrounSessionManagerDelegate>)delegate
                   configuration:(NSURLSessionConfiguration *)configuration
{
    if (self = [super init]) {
        self.responseDataDict = [NSMutableDictionary dictionary];
        self.delegate = delegate; //先设置delegate，再创建BackgroundSession，保证第一次回调能正常执行。
        NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
        operationQueue.maxConcurrentOperationCount = 1;
        operationQueue.name = @"com.heimdallr.backgroundsession.callback";
        self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:operationQueue];
    }
    return self;
}

- (NSURLSessionUploadTask * _Nullable)uploadWithRequest:(NSURLRequest *)request filePath:(NSString *)filePath
{
    if (filePath && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        NSURLSessionUploadTask *task = [self.session uploadTaskWithRequest:request fromFile:fileURL];
        [task resume];
        return task;
    }
    return nil;
}

- (void)queryAllUploadTasks:(void(^)(NSArray *tasks))completion
{
    [self.session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        if (completion) {
            completion(uploadTasks);
        }
    }];
}

- (NSArray *)getAllUploadTasks
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSArray *result = nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self queryAllUploadTasks:^(NSArray * _Nonnull tasks) {
            result = [tasks copy];
            dispatch_semaphore_signal(semaphore);
        }];
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return result;
}

#pragma mark - urlsession delegate

- (NSMutableData *)responseDataWithTask:(NSURLSessionTask *)task
{
    if (!task) {
        return nil;
    }
    NSMutableData *data = [self.responseDataDict objectForKey:@(task.taskIdentifier)];
    if (!data) {
        data = [NSMutableData data];
        [self.responseDataDict setObject:data forKey:@(task.taskIdentifier)];
    }
    return data;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    NSMutableData *responseData = [self responseDataWithTask:dataTask];
    [responseData appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (self.delegate) {
        NSMutableDictionary *responseObject = [NSMutableDictionary dictionary];
        if ([task.response isKindOfClass:NSHTTPURLResponse.class]) {
            [responseObject setObject:@([(NSHTTPURLResponse *)task.response statusCode]) forKey:@"status_code"];
            NSDictionary *header = [(NSHTTPURLResponse *)task.response allHeaderFields];
            if (header && [header hmd_hasKey:@"Alog_quota"]) {
                [responseObject setObject:[header hmd_stringForKey:@"Alog_quota"] forKey:@"Alog_quota"];
            }
        }
        if (task.response) {
            [responseObject setValue:@YES forKey:@"has_response"];
        }
        NSMutableData *responseData = [self responseDataWithTask:task];
        if (responseData) {
            NSError *jsonError = nil;
            id jsonObj = [responseData hmd_jsonObject:&jsonError];
            if (jsonError && !error) {
                error = jsonError;
            }
            [responseObject hmd_setObject:jsonObj forKey:@"result"];
        }
        [self.delegate URLSession:session task:task didCompleteWithResponseObject:responseObject error:error];
    }
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(URLSession:didBecomeInvalidWithError:)]) {
        [self.delegate URLSession:session didBecomeInvalidWithError:error];
    }
}

@end
