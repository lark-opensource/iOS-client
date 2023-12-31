//
//  IESFalconGurdInterceptor.m
//  Pods
//
//  Created by 陈煜钏 on 2019/9/19.
//

#if __has_include(<IESGeckoKit/IESGeckoKit.h>)

#import "IESFalconGurdInterceptor.h"

#import <IESGeckoKit/IESGeckoKit.h>

#import "NSString+IESFalconConvenience.h"
#import "IESFalconHelper.h"
#import "IESFalconDebugLogger.h"
#import "BDWebKitUtil.h"

@interface IESFalconGurdMetaData : NSObject<IESFalconMetaData>
@property (nonatomic, copy) NSArray *filePaths;
@end
@implementation IESFalconGurdMetaData
@synthesize falconData = _falconData;
@synthesize statModel = _statModel;
@end

@interface IESFalconGurdInterceptor ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *accessKeyPatternDictionary;

@end

@implementation IESFalconGurdInterceptor

#pragma mark - Public

- (void)registerPattern:(NSString *)pattern forGurdAccessKey:(NSString *)accessKey
{
    NSCParameterAssert(pattern);
    NSCParameterAssert(accessKey);
    
    @synchronized (self) {
        IESFalconDebugLog(@"Register【pattern => %@】for【AccessKey => %@】", pattern, accessKey);
        self.accessKeyPatternDictionary[pattern] = accessKey;
    }
}

- (void)registerPatterns:(NSArray <NSString *> *)patterns forGurdAccessKey:(NSString *)accessKey
{
    NSCParameterAssert(patterns);
    NSCParameterAssert(accessKey);
    
    @synchronized (self) {
        [patterns enumerateObjectsUsingBlock:^(NSString * _Nonnull pattern, NSUInteger idx, BOOL * _Nonnull stop) {
            IESFalconDebugLog(@"Register【pattern => %@】for【AccessKey => %@】", pattern, accessKey);
            self.accessKeyPatternDictionary[pattern] = accessKey;
        }];
    }
}

- (void)unregisterPatterns:(NSArray <NSString *> *)patterns
{
    @synchronized (self) {
        [patterns enumerateObjectsUsingBlock:^(NSString * _Nonnull pattern, NSUInteger idx, BOOL * _Nonnull stop) {
            IESFalconDebugLog(@"Unregister【pattern => %@】", pattern);
            self.accessKeyPatternDictionary[pattern] = nil;
        }];
    }
}

#pragma mark - IESFalconCustomInterceptor

- (id<IESFalconMetaData> _Nullable)falconMetaDataForURLRequest:(NSURLRequest *)request
{
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    IESFalconGurdMetaData *metaData = [self _gurdMetaDataWithURLString:request.URL.absoluteString];
    if (!metaData) {
        //没有匹配上
        return nil;
    }
    
    NSArray *filePaths = metaData.filePaths;
    if (filePaths.count > 0) {
        NSError *error = nil;
        metaData.falconData = IESFalconGetDataFromLocalFilePaths(filePaths, &error);
        NSInteger falconDataLength = metaData.falconData.length;
        
        IESFalconStatModel *statModel = metaData.statModel;
        statModel.offlineStatus = (falconDataLength > 0) ? 1 : 0;
        if (error) {
            statModel.errorCode = error.code;
            statModel.errorMessage = error.localizedDescription;
        } else if (falconDataLength == 0) {
            statModel.errorCode = 100;
        }
        statModel.falconDataLength = falconDataLength;
    }
    metaData.statModel.readDuration = CFAbsoluteTimeGetCurrent() - startTime;
    return metaData;
}

#pragma mark - Private

- (IESFalconGurdMetaData * _Nullable)_gurdMetaDataWithURLString:(NSString *)urlString
{
    @synchronized (self) {
        __block IESFalconGurdMetaData *metaData = nil;
        [self.accessKeyPatternDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *regex, NSString *accessKey, BOOL *stop) {
            NSString *prefix = [BDWebKitUtil prefixMatchesInString:urlString withPattern:regex];
            if (prefix.length > 0) {
                metaData = [self _gurdMetaDataWithURLString:urlString
                                               ignorePrefix:prefix
                                                  accessKey:accessKey
                                                      regex:regex];
                *stop = (metaData.filePaths.count > 0);
            }
        }];
        return metaData;
    }
}

- (IESFalconGurdMetaData * _Nullable)_gurdMetaDataWithURLString:(NSString *)urlString
                                                   ignorePrefix:(NSString *)prefix
                                                      accessKey:(NSString *)accessKey
                                                          regex:(NSString *)regex
{
    NSCParameterAssert([NSURL URLWithString:urlString] && accessKey && prefix);
    if (prefix.length == 0 || prefix.length == urlString.length) {
        return nil;
    }
    
    if (prefix.length > urlString.length) {
        return nil;
    }
    
    IESFalconDebugLog(@"Gecko Match【pattern => %@】【URL => %@】", regex, urlString);
    
    // ignore prefix
    NSString *absolutePath = [urlString substringWithRange:NSMakeRange(prefix.length, urlString.length - prefix.length)];
    absolutePath = [absolutePath stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    
    NSArray <NSString *>* comboPaths = absolutePath.ies_comboPaths;
    if (comboPaths.count == 0) {
        return nil;
    }
    
    NSString *channel = absolutePath.pathComponents.firstObject;
    NSString *geckoChannelPath = [IESGurdKit rootDirForAccessKey:accessKey channel:channel];
    
    NSMutableArray *filePaths = [NSMutableArray array];
    NSMutableArray *mimeTypes = [NSMutableArray array];
    NSMutableArray *bundles = [NSMutableArray array];
    BOOL (^addFilePath)(NSString *, NSString *) = ^(NSString *filePath, NSString *resourcePath) {
        if (filePath && [IESGurdKit hasCacheForPath:resourcePath accessKey:accessKey channel:channel]) {
            [filePaths addObject:filePath];
            [mimeTypes addObject:(filePath.pathExtension ? : @"unknown")];
            [bundles addObject:resourcePath];
            return YES;
        }
        return NO;
    };
    [comboPaths enumerateObjectsUsingBlock:^(NSString * _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
        if (path.length <= channel.length) {
            return;
        }
        
        NSString *searchPath = [path substringWithRange:NSMakeRange(channel.length, path.length - channel.length)];
        NSString *filePath = [geckoChannelPath stringByAppendingPathComponent:searchPath];
        if (addFilePath(filePath, searchPath)) {
            return;
        }
        
        NSString *removedFragmentPath = filePath.ies_removeFragment;
        NSString *removedFragmentPathWithoutChannelPath = [removedFragmentPath stringByReplacingOccurrencesOfString:geckoChannelPath withString:@""];
        if (addFilePath(removedFragmentPath, removedFragmentPathWithoutChannelPath)) {
            return;
        }
        
        NSString *removedQueryPath = filePath.ies_removeQuery;
        NSString *removedQueryPathWithoutChannelPath = [removedQueryPath stringByReplacingOccurrencesOfString:geckoChannelPath withString:@""];
        addFilePath(removedQueryPath, removedQueryPathWithoutChannelPath);
    }];
    
    IESFalconStatModel *statModel = [[IESFalconStatModel alloc] init];
    statModel.accessKey = accessKey;
    statModel.channel = channel;
    statModel.offlineRule = regex;
    statModel.bundles = [bundles copy];
    statModel.mimeType = [mimeTypes componentsJoinedByString:@"+"];
    statModel.packageVersion = [IESGurdKit packageVersionForAccessKey:accessKey channel:channel];
    
    IESFalconGurdMetaData *metaData = [[IESFalconGurdMetaData alloc] init];
    metaData.statModel = statModel;
    
    if (filePaths.count == comboPaths.count) {
        metaData.filePaths = [filePaths copy];
    }
    return metaData;
}


- (BOOL)shouldInterceptForRequest:(NSURLRequest*)request {
    __block BOOL result = NO;
    NSString* urlString = request.URL.absoluteString;
    [self.accessKeyPatternDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull regex, NSString * _Nonnull accessKey, BOOL * _Nonnull stop) {
        NSString *prefix = [BDWebKitUtil prefixMatchesInString:urlString withPattern:regex];
        if(prefix){
            result = YES;
            *stop = YES;
        }
    }];
    return result;
}
#pragma mark - Getter

- (NSMutableDictionary<NSString *, NSString *> *)accessKeyPatternDictionary
{
    if (!_accessKeyPatternDictionary) {
        _accessKeyPatternDictionary = [NSMutableDictionary dictionary];
    }
    return _accessKeyPatternDictionary;
}

@end

#endif
