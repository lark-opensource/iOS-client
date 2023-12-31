//
//  IESGurdResourceManager.m
//  IESGurdKit
//
//  Created by 01 on 17/6/30.
//

#import "IESGeckoResourceManager.h"
#import "IESGeckoResourceModel.h"
#import "IESGeckoDefines+Private.h"
#import "IESGeckoAPI.h"
#import "IESGeckoKit.h"
#import "IESGeckoKit+Private.h"
#import "IESGurdEventTraceManager+Network.h"
#import "IESGurdFileBusinessManager.h"
#import "IESGurdKitUtil.h"
#import "IESGurdKit+Experiment.h"
#import "IESGurdDownloadInfoModel.h"
#import "IESGurdExpiredCacheManager.h"

#import <IESGeckoEncrypt/IESGurdEncrypt.h>

NSString *IESGurdDownloadInfoDurationKey = @"download_duration";
NSString *IESGurdDownloadInfoURLKey = @"download_url";

/**
 拼接参数到URL
 */
static NSString * IESGurdURLByAppendingQueryItems (NSString *URLString, NSDictionary *params);

@interface IESGurdDefaultNetworkDelegate : NSObject <IESGurdNetworkDelegate>

@property (nonatomic, strong) NSURLSessionDownloadTask *currentDownloadTask;

@property (nonatomic, copy) NSString *currentDownloadIdentity;

@end

@interface IESGurdResourceManager ()

@property (nonatomic, strong) IESGurdDefaultNetworkDelegate *defaultNetworkDelegate;

@end

@implementation IESGurdResourceManager

#pragma mark - Public

+ (void)downloadPackageWithDownloadInfoModel:(IESGurdDownloadInfoModel *)downloadInfoModel
                                  completion:(IESGurdDownloadResourceCompletion)completion
{
    NSArray<NSString *> *URLStrings = downloadInfoModel.allDownloadURLStrings;
    NSCParameterAssert([URLStrings isKindOfClass:NSArray.class]);
    if (URLStrings.count == 0) {
        !completion ? : completion(nil, @{}, NULL);
        return;
    }
    
    NSMutableDictionary *downloadInfo = [NSMutableDictionary dictionary];
    downloadInfo[@"download_type"] = @(IESGurdDownloadTypeOriginal);
    
    __block NSUInteger index = 0;
    __block NSInteger totalDuration = 0;
    __block dispatch_block_t retryDownloadBlock = ^{
        NSString *packageURLString = URLStrings[index++] ? : @"";
        NSCParameterAssert([packageURLString isKindOfClass:NSString.class]);
        
        downloadInfoModel.currentDownloadURLString = packageURLString;
        
        id<IESGurdNetworkDelegate> networkDelegate = [self networkDelegateForDownload];
        NSDate *startDownloadDate = [NSDate date];
        [networkDelegate downloadPackageWithDownloadInfoModel:downloadInfoModel completion:^(NSURL *pathURL, NSError *error) {
            NSInteger downloadDuration = (NSInteger)([[NSDate date] timeIntervalSinceDate:startDownloadDate] * 1000);
            totalDuration += downloadDuration;
            
            if (!pathURL) {
                // -18 & 28: ttnet 抛出的空间不足的 code
                // 只在第一次重试的时候清理过期缓存（一期试验先不开启）
//                NSString *errorMessage = error.localizedDescription;
//                BOOL isDiskUnavailable = ((error.code == -999) && [errorMessage containsString:@"error: -18"]);
//                if (isDiskUnavailable && index == 0) {
//                    [[IESGurdExpiredCacheManager sharedManager] clearCache:nil];
//                }
                
                NSString *reason = [NSString stringWithFormat:@"【%zd】%@", error.code, error.localizedDescription];
                downloadInfo[@"err_msg"] = reason;
                downloadInfo[@"download_failed_times"] = @(index - 1);
                
                // 如果是被取消的请求则不重试
                if (index < URLStrings.count && error.code != -999) {
                    retryDownloadBlock();
                    return;
                }
            } else {
                downloadInfo[IESGurdDownloadInfoDurationKey] = @(downloadDuration);
                NSString *packageFilePath = [IESGurdFileBusinessManager downloadTempFilePath];
                NSURL *packageFileURL = [NSURL fileURLWithPath:packageFilePath];
                [[NSFileManager defaultManager] moveItemAtURL:pathURL toURL:packageFileURL error:NULL];
                pathURL = packageFileURL;
            }
            
            downloadInfo[IESGurdDownloadInfoURLKey] = packageURLString;
            downloadInfo[@"total_duration"] = @(totalDuration);
            !completion ? : completion(pathURL, [downloadInfo copy], error);
            
            retryDownloadBlock = nil;
        }];
    };
    retryDownloadBlock();
}

+ (void)GETWithURLString:(NSString * _Nonnull)URLString
                  params:(NSDictionary * _Nullable)params
              completion:(IESGurdHTTPRequestCompletion)completion
{
    [self innerRequestWithMethod:@"GET"
                       URLString:URLString
                          params:params
                      completion:completion];
}

+ (void)POSTWithURLString:(NSString * _Nonnull)URLString
                   params:(NSDictionary * _Nullable)params
               completion:(nullable IESGurdHTTPRequestCompletion)completion
{
    [self innerRequestWithMethod:@"POST"
                       URLString:URLString
                          params:params
                      completion:completion];
}

+ (void)cancelDownloadWithIdentity:(NSString *)identity
{
    [[self networkDelegateForDownload] cancelDownloadWithIdentity:identity];
}

#pragma mark - Private

+ (IESGurdResourceManager *)sharedManager
{
    static IESGurdResourceManager *s_manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_manager = [IESGurdResourceManager new];
    });
    return s_manager;
}

+ (void)innerRequestWithMethod:(NSString * _Nonnull)method
                     URLString:(NSString * _Nonnull)URLString
                        params:(NSDictionary * _Nullable)params
                    completion:(IESGurdHTTPRequestCompletion)completion
{
    NSMutableDictionary *finalParams = [NSMutableDictionary dictionary];
    [finalParams addEntriesFromDictionary:params];
    finalParams[kIESGurdNetworkCommonKey] = IESGurdClientCommonParams();
    
    if (IESGurdKit.enableEncrypt) {
        IESGurdEncryptRequest(method, URLString, finalParams, completion);
    } else {
        [self realRequestWithMethod:method URLString:URLString params:[finalParams copy] completion:completion];
    }
}

+ (void)realRequestWithMethod:(NSString * _Nonnull)method
                    URLString:(NSString * _Nonnull)URLString
                       params:(NSDictionary * _Nullable)params
                   completion:(IESGurdHTTPRequestCompletion)completion
{
    IESGurdTraceNetworkInfo *networkInfo = nil;
    if (IESGurdEventTraceManager.isEnabled) {
        networkInfo = [IESGurdTraceNetworkInfo infoWithMethod:method
                                                    URLString:URLString
                                                       params:params];
    }
    id<IESGurdNetworkDelegate> networkDelegate = [self networkDelegateForRequest];
    networkInfo.startDate = [NSDate date];
    [networkDelegate requestWithMethod:method URLString:URLString params:params completion:^(IESGurdNetworkResponse * _Nonnull response) {
        networkInfo.endDate = [NSDate date];
        networkInfo.responseObject = response.responseObject;
        networkInfo.error = response.error;
        [IESGurdEventTraceManager traceNetworkWithInfo:networkInfo];
        
        response.requestURLString = URLString;
        response.requestParams = params;
        !completion ? : completion(response);
    }];
}

+ (id<IESGurdNetworkDelegate>)networkDelegateForDownload
{
    id<IESGurdNetworkDelegate> networkDelegate = IESGurdKitInstance.networkDelegate ? : [self sharedManager].defaultNetworkDelegate;
    NSAssert([networkDelegate respondsToSelector:@selector(downloadPackageWithDownloadInfoModel:completion:)],
             @"Gurd networkDelegate should respond to downloadPackageWithDownloadInfoModel:completion:");
    NSAssert([networkDelegate respondsToSelector:@selector(cancelDownloadWithIdentity:)],
             @"Gurd networkDelegate should respond to cancelDownloadWithIdentity:");
    return networkDelegate;
}

+ (id<IESGurdNetworkDelegate>)networkDelegateForRequest
{
    id<IESGurdNetworkDelegate> networkDelegate = IESGurdKitInstance.networkDelegate ? : [self sharedManager].defaultNetworkDelegate;
    NSAssert([networkDelegate respondsToSelector:@selector(requestWithMethod:URLString:params:completion:)],
             @"Gurd networkDelegate should respond to requestWithMethod:URLString:params:completion:");
    return networkDelegate;
}

#pragma mark - Getter

- (IESGurdDefaultNetworkDelegate *)defaultNetworkDelegate
{
    @synchronized (self) {
        if (!_defaultNetworkDelegate) {
            _defaultNetworkDelegate = [[IESGurdDefaultNetworkDelegate alloc] init];
        }
        return _defaultNetworkDelegate;
    }
}

@end

@implementation IESGurdDefaultNetworkDelegate

#pragma mark - IESGurdNetworkDelegate

- (void)downloadPackageWithDownloadInfoModel:(IESGurdDownloadInfoModel *)model
                                  completion:(IESGurdNetworkDelegateDownloadCompletion)completion
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *downloadSession = [NSURLSession sessionWithConfiguration:configuration];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:model.currentDownloadURLString]];
    
    NSURLSessionDownloadTask *downloadTask = [downloadSession downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        @synchronized (self) {
            self.currentDownloadTask = nil;
            self.currentDownloadIdentity = nil;
        }
        
        !completion ?: completion(location, error);
    }];
    
    @synchronized (self) {
        self.currentDownloadTask = downloadTask;
        self.currentDownloadIdentity = model.identity;
    }
    
    [downloadTask resume];
}

- (void)requestWithMethod:(NSString *)method
                URLString:(NSString *)URLString
                   params:(NSDictionary *)params
               completion:(void (^)(IESGurdNetworkResponse *response))completion
{
    NSString *updatedURLString = URLString;
    if ([method isEqualToString:@"GET"]) {
        updatedURLString = IESGurdURLByAppendingQueryItems(URLString, params);
    } else if ([method isEqualToString:@"POST"]) {
        // do nothing
    } else {
        GurdLog(@"Invalid HTTP method: %@", method);
        return;
    }
    
    NSURL *URL = [NSURL URLWithString:updatedURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setHTTPMethod:method];
    if ([method isEqualToString:@"POST"]) {
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:params options:0 error:NULL];
    }
    if (IESGurdKitInstance.requestHeaderFieldBlock) {
        NSDictionary<NSString *, NSString *> *headerField = IESGurdKitInstance.requestHeaderFieldBlock();
        [headerField enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
    }
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        IESGurdNetworkResponse *networkResponse = [[IESGurdNetworkResponse alloc] init];
        networkResponse.responseObject = data;
        networkResponse.error = error;
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
            networkResponse.statusCode = HTTPResponse.statusCode;
            networkResponse.allHeaderFields = HTTPResponse.allHeaderFields;
        }
        
        !completion ? : completion(networkResponse);
    }];
    
    [task resume];
}

- (void)cancelDownloadWithIdentity:(NSString *)identity
{
    __block NSURLSessionDownloadTask *cancelTask = nil;
    @synchronized (self) {
        if ([self.currentDownloadIdentity isEqualToString:identity]) {
            cancelTask = self.currentDownloadTask;
        }
    }
    if (cancelTask) {
        GurdLog(@"Cancel download task with identity: %@", identity);
        [cancelTask cancel];
    }
}

@end

static NSString * IESGurdURLByAppendingQueryItems (NSString *URLString, NSDictionary *params) {
    if (params.count == 0) {
        return URLString;
    }
    NSMutableArray *paramStringArray = [NSMutableArray array];
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [paramStringArray addObject:[NSString stringWithFormat:@"%@=%@", key, obj]];
    }];
    NSString *updatedURLString = URLString;
    NSString *paramsString = [paramStringArray componentsJoinedByString:@"&"];
    if ([URLString rangeOfString:@"?"].location == NSNotFound) {
        updatedURLString = [NSString stringWithFormat:@"%@?%@", URLString, paramsString];
    } else {
        updatedURLString = [NSString stringWithFormat:@"%@&%@", URLString, paramsString];
    }
    return updatedURLString;
}
