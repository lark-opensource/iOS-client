//
//  IESFalconFileInterceptor.m
//  Pods
//
//  Created by 陈煜钏 on 2019/9/19.
//

#import "IESFalconFileInterceptor.h"

#import "NSString+IESFalconConvenience.h"
#import "IESFalconHelper.h"
#import "IESFalconDebugLogger.h"
#import "BDWebKitUtil.h"

@interface IESFalconFileMetaData : NSObject<IESFalconMetaData>
@end
@implementation IESFalconFileMetaData
@synthesize falconData = _falconData;
@synthesize statModel = _statModel;
@end

@interface IESFalconFileInterceptor ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *fileSearchPathPatternDictionary;

@end

@implementation IESFalconFileInterceptor

#pragma mark - Public

- (void)registerPattern:(NSString *)pattern forSearchPath:(NSString *)searchPath
{
    NSCParameterAssert(pattern);
    NSCParameterAssert(searchPath);
    
    @synchronized (self) {
        IESFalconDebugLog(@"Register【pattern => %@】for【FilePath => %@】", pattern, searchPath);
        self.fileSearchPathPatternDictionary[pattern] = searchPath;
    }
}

- (void)registerPatterns:(NSArray <NSString *> *)patterns forSearchPath:(NSString *)searchPath
{
    NSCParameterAssert(patterns);
    NSCParameterAssert(searchPath);
    
    @synchronized (self) {
        [patterns enumerateObjectsUsingBlock:^(NSString * _Nonnull pattern, NSUInteger idx, BOOL * _Nonnull stop) {
            IESFalconDebugLog(@"Register【pattern => %@】for【FilePath => %@】", pattern, searchPath);
            self.fileSearchPathPatternDictionary[pattern] = searchPath;
        }];
    }
}

- (void)unregisterPatterns:(NSArray <NSString *> *)patterns
{
    @synchronized (self) {
        [patterns enumerateObjectsUsingBlock:^(NSString * _Nonnull pattern, NSUInteger idx, BOOL * _Nonnull stop) {
            IESFalconDebugLog(@"Unregister【pattern => %@】", pattern);
            self.fileSearchPathPatternDictionary[pattern] = nil;
        }];
    }
}

#pragma mark - IESFalconCustomInterceptor

- (id<IESFalconMetaData> _Nullable)falconMetaDataForURLRequest:(NSURLRequest *)request
{
    NSArray<NSString *> *customPaths = [self _customPathsWithURLString:request.URL.absoluteString];
    if (customPaths.count == 0) {
        return nil;
    }
    IESFalconFileMetaData *metaData = [[IESFalconFileMetaData alloc] init];
    NSError *error;
    metaData.falconData = IESFalconGetDataFromLocalFilePaths(customPaths, &error);
    return metaData;
}

#pragma mark - Private

- (NSArray<NSString *> * _Nullable)_customPathsWithURLString:(NSString *)urlString
{
    @synchronized (self) {
        __block NSArray *filePaths = nil;
        [self.fileSearchPathPatternDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *regex, NSString *customPath, BOOL *stop) {
            NSString *prefix = [BDWebKitUtil prefixMatchesInString:urlString withPattern:regex];
            if (prefix) {
                IESFalconDebugLog(@"File Match【pattern => %@】【URL => %@】", regex, urlString);
                filePaths = [self _customPathsWithURLString:urlString ignorePrefix:prefix searchPath:customPath];
                *stop = (filePaths.count > 0);
            }
        }];
        return filePaths;
    }
}

- (NSArray<NSString *> * _Nullable )_customPathsWithURLString:(NSString *)urlString
                                                 ignorePrefix:(NSString *)prefix
                                                   searchPath:(NSString *)searchPath
{
    NSCParameterAssert([NSURL URLWithString:urlString]);
    NSCParameterAssert(prefix);
    NSCParameterAssert(searchPath);
    
    if (prefix.length == 0 || prefix.length == urlString.length) {
        return nil;
    }
    
    if (prefix.length > urlString.length) {
        return nil;
    }
    
    // ignore prefix
    NSString *absolutePath = [urlString substringWithRange:NSMakeRange(prefix.length, urlString.length - prefix.length)];
    
    NSArray <NSString *>* comboPaths = absolutePath.ies_comboPaths;
    NSString *rootPath = searchPath;
    
    BOOL (^fileExistBlock)(NSString *path) = ^BOOL (NSString *filePath) {
        BOOL isDirectory = NO;
        BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
        return (!isDirectory && fileExist);
    };
    
    __block NSMutableArray *filePaths = [NSMutableArray array];
    [comboPaths enumerateObjectsUsingBlock:^(NSString * _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *filePath = [rootPath stringByAppendingPathComponent:path];
        if (fileExistBlock(filePath)) {
            [filePaths addObject:filePath];
            return;
        }
        
        NSString *removedFragmentPath = filePath.ies_removeFragment;
        if (![filePath isEqualToString:removedFragmentPath] && fileExistBlock(removedFragmentPath)) {
            [filePaths addObject:removedFragmentPath];
            return;
        }
        
        NSString *removedQueryPath = filePath.ies_removeQuery;
        if (![filePath isEqualToString:removedQueryPath] && fileExistBlock(removedQueryPath)) {
            [filePaths addObject:removedQueryPath];
        }
    }];
    
    if (filePaths.count == comboPaths.count) {
        return filePaths;
    }
    
    return nil;
}

#pragma mark - Getter

- (NSMutableDictionary<NSString *, NSString *> *)fileSearchPathPatternDictionary
{
    if (!_fileSearchPathPatternDictionary) {
        _fileSearchPathPatternDictionary = [NSMutableDictionary dictionary];
    }
    return _fileSearchPathPatternDictionary;
}

@end
