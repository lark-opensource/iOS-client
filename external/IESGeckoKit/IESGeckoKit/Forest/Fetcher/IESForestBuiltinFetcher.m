// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestBuiltinFetcher.h"

#import "IESForestDefines.h"
#import "IESForestResponse.h"
#import "IESForestRequest.h"
#import "IESForestError.h"

#import <IESGeckoKit/IESGeckoKit.h>
#import <IESGeckoKit/IESGurdLogProxy.h>
#import <IESGeckoKit/IESGurdKit+InternalPackages.h>
#import <ByteDanceKit/BTDMacros.h>

@implementation IESForestBuiltinFetcher

+ (NSString *)fetcherName
{
    return @"Builtin";
}

- (NSString *)name
{
    return @"Builtin";
}

- (void)fetchResourceWithRequest:(IESForestRequest *)request
                      completion:(IESForestFetcherCompletionHandler)completion
{
    NSAssert(completion != nil, @"Completion in Fetcher should not be nil");
    request.metrics.builtinStart = [[NSDate date] timeIntervalSince1970] * 1000;
    IESForestFetcherCompletionHandler wrapCompletion = ^(id<IESForestResponseProtocol> response, NSError *error) {
        request.metrics.builtinFinish = [[NSDate date] timeIntervalSince1970] * 1000;
        if (self.isCanceled) {
            return;
        }
        if (error) {
            self.request.builtinError = [error localizedDescription];
        }
        completion(response, error);
    };

    if (!self.request.hasValidGeckoInfo) {
        NSError *error = [IESForestError errorWithCode:IESForestErrorBuiltinParameterInvalid message:@"AccessKey/Channel/Bundle invalid"];
        wrapCompletion(nil, error);
        return;
    }
    
    NSString *dirName = [IESGurdKit internalRootDirectoryForAccessKey:[self.request accessKey] channel:[self.request channel]];
    NSString *pathFormat = [[self.request bundle] hasPrefix:@"/"] ? @"%@%@" : @"%@/%@";
    NSString *path = [NSString stringWithFormat:pathFormat, dirName, [self.request bundle]];

    if ([path containsString:@"../"]) {
        NSError *error = [IESForestError errorWithCode:IESForestErrorBuiltinPathInvalid message:@"Path contains ../"];
        wrapCompletion(nil, error);
        return;
    }

    NSData *builtinData = nil;
    BOOL isDirectory = NO;
    BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    if (fileExist && !isDirectory) {
        if ([self.request onlyPath]) {
            builtinData = [[NSData alloc] init];
        } else {
            builtinData = [NSData dataWithContentsOfFile:path];
            if (builtinData.length == 0) {
                builtinData = nil;
            }
        }
    }
    
    if (!builtinData) {
        NSError *error = [IESForestError errorWithCode:IESForestErrorBuiltinFileNotFound message:@"File Not Found"];
        wrapCompletion(nil, error);
        return;
    }

    IESForestResponse *response = [[IESForestResponse alloc] initWithRequest:request];
    response.data = builtinData;
    response.sourceType = IESForestDataSourceTypeBuiltin;
    response.absolutePath = path;
    response.fetcher = [[self class] fetcherName];
    wrapCompletion(response, nil);
}

- (void)cancelFetch
{
    self.isCanceled = YES;
}

@end
