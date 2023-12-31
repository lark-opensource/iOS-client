//
//  ACCEffectMessageDownloadOperation.m
//  CameraClient-Pods-Aweme
//
//  Created by Chipengliu on 2020/11/26.
//

#import "ACCEffectMessageDownloadOperation.h"

#import <CreationKitInfra/ACCLogProtocol.h>

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCNetServiceProtocol.h>
#import <SSZipArchive/SSZipArchive.h>

@interface ACCEffectMessageDownloadOperation ()

@property (nonatomic, copy) NSArray<NSString *> *urlStringList;

@property (nonatomic, strong) NSMutableArray<ACCEffectMessageDownloaderCompletedBlock> *completionCallbackArray;

@property (nonatomic, copy) NSString *rootDirectory;

@property (nonatomic, assign) BOOL needUpzip;

@property (nonatomic, assign, getter = isExecuting) BOOL executing;
@property (nonatomic, assign, getter = isFinished) BOOL finished;
@property (nonatomic, strong) NSRecursiveLock *lock;

@end

@implementation ACCEffectMessageDownloadOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)initWithUrlList:(NSArray<NSString *> *)urlStringList
                  rootDirectory:(NSString *)rootDirectory
                      needUpzip:(BOOL)needUpzip
{
    if (self = [super init]) {
        _executing = NO;
        _finished = NO;
        _urlStringList = [urlStringList copy];
        _rootDirectory = [rootDirectory copy];
        _completionCallbackArray = [NSMutableArray array];
        _needUpzip = needUpzip;
        _lock = [[NSRecursiveLock alloc] init];
        self.qualityOfService = NSOperationQualityOfServiceUtility;
    }
    return self;
}

- (void)dealloc {
    AWELogToolDebug(AWELogToolTagNone, @"%s", __func__);
}

- (void)addHandlersForCompleted:(ACCEffectMessageDownloaderCompletedBlock)completedBlock {
    @synchronized (self.completionCallbackArray) {
        if (completedBlock) {
            [self.completionCallbackArray addObject:completedBlock];
        }
    }
}

- (BOOL)isAsynchronous
{
    return YES;
}

- (void)start {
    if (self.isCancelled) {
        AWELogToolWarn(AWELogToolTagNone, @"cancel download can not start cuz operation is cancel");
        NSError *error = [NSError errorWithDomain:@"ACCEffectMessageDownloaderErrorDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey : @"Operation cancelled by user before sending the request"}];
        [self handleCallbackWithUrlList:self.urlStringList filePath:nil error:error];
        return;
    }
    
    self.executing = YES;
    [self downloadWithUrlList:self.urlStringList urlIndex:0];
}

- (void)cancel
{
    @synchronized (self) {
        [self cancelInternal];
    }
}

#pragma mark - Private

- (BOOL)isFinished
{
    [_lock lock];
    BOOL finished = _finished;
    [_lock unlock];
    return finished;
}


- (BOOL)isExecuting
{
    [_lock lock];
    BOOL executing = _executing;
    [_lock unlock];
    return executing;
}

- (void)setFinished:(BOOL)finished
{
    [_lock lock];
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
    [_lock unlock];
}

- (void)setExecuting:(BOOL)executing
{
    [_lock lock];
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
    [_lock unlock];
}

- (void)done
{    
    self.executing = NO;
    self.finished = YES;
}

- (void)cancelInternal
{
    if (self.isFinished) return;
    [super cancel];
    
    AWELogToolWarn(AWELogToolTagNone, @"cancel download can not start cuz operation is cancel");
    NSError *error = [NSError errorWithDomain:@"ACCEffectMessageDownloaderErrorDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey : @"Operation cancelled by user before sending the request"}];
    [self handleCallbackWithUrlList:self.urlStringList filePath:nil error:error];
}

- (void)downloadWithUrlList:(NSArray<NSString *> *)urlList
                   urlIndex:(NSInteger)urlIndex
{
    NSAssert(urlIndex < urlList.count, @"params is invalid!!! urlIndex=%zi|urlList=%@", urlIndex, urlList);
    
    NSString *urlString = nil;
    if (urlIndex < urlList.count) {
        urlString = urlList[urlIndex];
    }
        
    // 本地缓存查找
    NSString *cacheFilePath = nil;
    NSURL *url = [NSURL URLWithString:urlString];
    cacheFilePath = [self diskPathForUrlPath:url];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if (cacheFilePath.length > 0 && [fileManager fileExistsAtPath:cacheFilePath]) {
        AWELogToolInfo(AWELogToolTagNone, @"find cache file path|cacheFilePath=%@|urlString=%@", cacheFilePath, urlString);
        NSURL *filePath = [NSURL fileURLWithPath:cacheFilePath];
        [self handleCallbackWithUrlList:urlList filePath:filePath error:nil];
        return;
    }
    
    // 文件没有缓存，开始下载
    NSURL *requestUrl = [NSURL URLWithString:urlString];
    NSAssert(requestUrl, @"invalid request URL!!!");
    NSString *targetPath = [self downloadDiskCacheWithUrlPath:requestUrl.path];
    NSString *targetDir = [targetPath stringByDeletingLastPathComponent];
    
    // 下载前创建好文件夹
    BOOL dirExists = [[NSFileManager defaultManager] fileExistsAtPath:targetDir isDirectory:nil];
    if (!dirExists) {
        NSError *error = nil;
        
        [[NSFileManager defaultManager] createDirectoryAtPath:targetDir withIntermediateDirectories:YES attributes:nil error:&error];
        NSAssert(!error, @"create directory failed, targetDir=%@|error=%@", targetDir, error);
        if (error) {
            AWELogToolError(AWELogToolTagNone, @"create directory error=%@", error);
            [self handleCallbackWithUrlList:urlList filePath:nil error:error];
            return;
        }
        
        // 设置不备份
        NSURL *targetDirURL = [NSURL fileURLWithPath:targetDir];
        [targetDirURL setResourceValue:[NSNumber numberWithBool:YES]
                                forKey:NSURLIsExcludedFromBackupKey error:&error];
        if (error) {
            AWELogToolError(AWELogToolTagNone, @"setResourceValue error=%@", error);
        }
    }
    
    @weakify(self);
    [ACCNetService() downloadWithModel:^(ACCRequestModel * _Nullable requestModel) {
        requestModel.urlString = urlString;
        requestModel.targetPath = targetPath;
    } progressBlock:^(CGFloat progress) {
        AWELogToolDebug(AWELogToolTagNone, @"download progress=%f|urlString=%@", progress, urlString);
    } completion:^(NSURLResponse * _Nullable response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        @strongify(self);
        
        if (error) {
            AWELogToolError(AWELogToolTagNone, @"download failed, urlList=%@|urlIndex=%zi|error=%@", urlList, urlIndex, error);
            if (urlIndex == (urlList.count-1)) {
                [self handleCallbackWithUrlList:urlList filePath:filePath error:error];
            } else {
                AWELogToolWarn(AWELogToolTagNone, @"download next url, urlList=%@|urlIndex=%zi", urlList, urlIndex);
                
                // 使用下一个 url 进行重试下载
                [self downloadWithUrlList:urlList urlIndex:urlIndex+1];
            }
        } else {
            // 下载成功判断是否需要解压
            if (self.needUpzip) {
                [self unzipWithFilePath:filePath urlList:urlList urlIndex:urlIndex];
            } else {
                [self handleCallbackWithUrlList:urlList filePath:filePath error:error];
            }
        }
    }];
}

/// 解压下载文件
/// @param filePath 下载文件的路径
- (void)unzipWithFilePath:(NSURL *)filePath urlList:(NSArray<NSString *> *)urlList urlIndex:(NSInteger)urlIndex
{
    NSString *destinationFilePath = [self unzipDestinationURLPathWithFileURL:filePath];
    
    AWELogToolInfo(AWELogToolTagNone, @"start unzip file at path=%@|destinationFilePath=%@", filePath.path, destinationFilePath);
    
    [SSZipArchive unzipFileAtPath:filePath.path
                    toDestination:destinationFilePath
                  progressHandler:nil
                completionHandler:^(NSString * _Nonnull path, BOOL succeeded, NSError * _Nullable error) {
        
        NSURL *callbackUnzipURL = [NSURL fileURLWithPath:destinationFilePath];
        // 无论解压是否失败，删除未解压文件
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        if ([fileManager fileExistsAtPath:filePath.path]) {
            NSError *deleteFileError = nil;
            BOOL ret = [fileManager removeItemAtPath:filePath.path error:&deleteFileError];
            NSAssert(deleteFileError == nil, @"remove file failed, error=%@", error);
            if (!ret || deleteFileError) {
                AWELogToolError(AWELogToolTagNone, @"remove file failed, filePath=%@|ret=%d|error=%@", filePath, ret, deleteFileError);
            }
        }
        
        if (succeeded && !error) {
            AWELogToolInfo(AWELogToolTagNone, @"download and unzip success|path=%@", path);
            [self handleCallbackWithUrlList:urlList filePath:callbackUnzipURL error:error];
        } else {
            AWELogToolError(AWELogToolTagNone, @"unzip failed, urlIndex=%zi|count=%zi|error=%@", urlIndex, urlList.count, error);
            if (urlIndex == (urlList.count-1)) {
                [self handleCallbackWithUrlList:urlList filePath:callbackUnzipURL error:error];
            } else {
                AWELogToolWarn(AWELogToolTagNone, @"download next url, urlList=%@|urlIndex=%zi", urlList, urlIndex);
                
                // 使用下一个 url 进行重试下载
                [self downloadWithUrlList:urlList urlIndex:urlIndex+1];
            }
        }
    }];
}

- (void)handleCallbackWithUrlList:(NSArray<NSString *> *)urlList filePath:(NSURL *)filePath error:(NSError *)error
{
    AWELogToolDebug(AWELogToolTagNone, @"handleCallbackWithUrlList|filePath=%@|error=%@", filePath, error);
    @synchronized (self.completionCallbackArray) {
        for (ACCEffectMessageDownloaderCompletedBlock callback in self.completionCallbackArray) {
            callback(filePath, error);
        }
        
        [self.completionCallbackArray removeAllObjects];
        
    }
    [self done];
}

- (NSString *)diskPathForUrlPath:(NSURL *)url
{
    NSString *urlPath = url.path;
    if (self.needUpzip) {
        NSString *destinationFilePath = [self unzipDestinationURLPathWithFileURL:url];
        urlPath = destinationFilePath;
    }
    
    NSString *targetPath = [self.rootDirectory stringByAppendingPathComponent:urlPath];
    targetPath = [targetPath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    return targetPath;
}

- (NSString *)downloadDiskCacheWithUrlPath:(NSString *)urlPath
{
    NSString *targetPath = [self.rootDirectory stringByAppendingPathComponent:urlPath ?: @""];
    targetPath = [targetPath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    return targetPath;
}

- (NSString *)unzipDestinationURLPathWithFileURL:(NSURL *)url
{
    NSString *lastComponent = [url lastPathComponent];
    lastComponent = [@"unzip_" stringByAppendingString:lastComponent ?: @""];
    NSURL *unzipFileURL = [url URLByDeletingLastPathComponent];
    NSString *destinationFilePath = [unzipFileURL.path stringByAppendingPathComponent:lastComponent];
    return destinationFilePath;
}

@end
