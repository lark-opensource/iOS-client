//
//  ACCEffectMessageDownloader.m
//  CameraClient-Pods-Aweme
//
//  Created by Chipengliu on 2020/11/19.
//

#import "ACCEffectMessageDownloader.h"

#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import "ACCEffectMessageDownloadOperation.h"

typedef void(^ACCEffectMessageDownloadCompletion)(NSURL * _Nullable filePath, NSError * _Nullable error);

static NSString * const kFilePathDirectoryPrefix = @"com.awe.creative-platform.effect";

@interface ACCEffectMessageDownloader ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, ACCEffectMessageDownloadOperation *> *URLOperations;

@property (nonatomic, strong) NSOperationQueue *downloadOperationQueue;

@end

@implementation ACCEffectMessageDownloader

+ (void)cleanCache
{
    NSError *error = nil;
    NSString *docmentDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *rootDir = [docmentDir stringByAppendingPathComponent:kFilePathDirectoryPrefix];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if ([fileManager fileExistsAtPath:rootDir isDirectory:nil]) {
        BOOL res = [fileManager removeItemAtPath:rootDir error:&error];
        AWELogToolInfo(AWELogToolTagNone,  @"remove items at path=%@|res=%d|error=%@", rootDir, res, error);
    }
}

+ (nonnull instancetype)sharedDownloader
{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        _downloadOperationQueue = [[NSOperationQueue alloc] init];
        _URLOperations = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc
{
    [self.downloadOperationQueue cancelAllOperations];
}

- (void)downloadWithUrlList:(NSArray<NSString *> *)urlList
                  needUpzip:(BOOL)needUpzip
                 completion:(void(^)(NSURL * _Nullable filePath, NSError * _Nullable error))completion
{
    NSAssert(urlList.count > 0, @"urlList is invalid!!!");
    AWELogToolInfo(AWELogToolTagNone, @"start download urlList=%@|needUpzip=%d", urlList, needUpzip);
    
    // 过滤无效 url
    NSMutableArray<NSString *> *filterUrlList = [NSMutableArray array];
    for (NSString *urlString in urlList) {
        // 中文字符转义
        NSString *encodeUrlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSURL *url = [NSURL URLWithString:encodeUrlString];
        if (url.path.length > 0 && url.scheme.length > 0) {
            [filterUrlList addObject:encodeUrlString];
        }
    }
    
    NSAssert(filterUrlList.count > 0, @"filterUrlList is invalid!! urlList=%@", urlList);
    if (filterUrlList.count == 0) {
        NSError *error = [NSError errorWithDomain:@"ACCEffectMessageDownloaderErrorDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey : @"urlList is invalid"}];
        AWELogToolError(AWELogToolTagNone, @"filterUrlList is invalid!!|error=%@", error);
        if (completion) {
            completion(nil, error);
        }
    } else {
        [self addDownloadOperationWithUrlList:filterUrlList needUpzip:needUpzip completion:completion];
    }
}

#pragma mark - Private

- (void)addDownloadOperationWithUrlList:(NSArray<NSString *> *)urlList
                              needUpzip:(BOOL)needUpzip
                             completion:(void(^)(NSURL * _Nullable filePath, NSError * _Nullable error))completion
{
    @synchronized (self.URLOperations) {
        NSString *key = [self downloadCallbackCacheKeyWithUrlList:urlList];
        NSAssert(key.length > 0, @"operation key is invalid!!");
        ACCEffectMessageDownloadOperation *existOperation = self.URLOperations[key];
        
        if (!existOperation || existOperation.isCancelled || existOperation.isFinished) {
            // 无相同的下载任务
            ACCEffectMessageDownloadOperation *operation = [[ACCEffectMessageDownloadOperation alloc] initWithUrlList:urlList
                                                                                                        rootDirectory:[self rootDirectory]
                                                                                                            needUpzip:needUpzip];
            [operation addHandlersForCompleted:completion];
            self.URLOperations[key] = operation;
            
            @weakify(self);
            operation.completionBlock = ^{
                AWELogToolInfo(AWELogToolTagNone, @"download operation complete, key=%@", key);
                @strongify(self);
                @synchronized (self.URLOperations) {
                    [self.URLOperations removeObjectForKey:key];
                }
            };
            
            AWELogToolDebug(AWELogToolTagNone, @"add operation, key=%@", key);
            [self.downloadOperationQueue addOperation:operation];
            
        } else {
            // 有正在进行的下载任务
            AWELogToolInfo(AWELogToolTagNone, @"download operation exist, key=%@", key);
            [existOperation addHandlersForCompleted:completion];
        }
    }
}

- (NSString *)downloadCallbackCacheKeyWithUrlList:(NSArray<NSString *> *)urlList
{
    NSAssert(urlList.count > 0 && urlList.firstObject.length > 0, @"uilList is invaliid!!!");
    NSURL *url = [NSURL URLWithString:urlList.firstObject];
    return url.path ?: @"";
}

- (NSString *)rootDirectory
{
    NSString *docmentDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *rootDir = [docmentDir stringByAppendingPathComponent:kFilePathDirectoryPrefix];
    return rootDir;
}

@end
