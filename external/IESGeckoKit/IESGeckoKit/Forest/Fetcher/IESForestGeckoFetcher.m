// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestGeckoFetcher.h"

#import "IESForestKit.h"
#import "IESForestKit+private.h"
#import "IESForestResponse.h"
#import "IESForestMemoryCache.h"
#import "IESForestGeckoUtil.h"
#import "IESForestError.h"

#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import <IESGeckoKit/IESGeckoKit.h>
#import <IESGeckoKit/IESGurdLogProxy.h>
#import <IESGeckoKit/IESGurdInternalPackagesManager.h>
#import <ByteDanceKit/BTDMacros.h>

@implementation IESForestGeckoFetcher

+ (NSString *)fetcherName
{
    return @"Gecko";
}

- (NSString *)name
{
    return @"Gecko";
}

- (void)fetchResourceWithRequest:(IESForestRequest *)request
                      completion:(IESForestFetcherCompletionHandler)completion
{
    NSAssert(completion != nil, @"Completion in Fetcher should not be nil");
    request.metrics.geckoStart = [[NSDate date] timeIntervalSince1970]* 1000;

    @weakify(self);
    void (^resolve)(id<IESForestResponseProtocol> response) = ^(IESForestResponse* response) {
        @strongify(self);
        if (!self.isCanceled) {
            request.metrics.geckoFinish = [[NSDate date] timeIntervalSince1970]* 1000;
            response.fetcher = [[self class] fetcherName];
//            IESGurdLogInfo(@"Forest - Gecko: request [%@] success", self.request.url);
            completion(response, nil);
        }
    };
    void (^reject)(IESForestErrorCode code, NSString *message) = ^(IESForestErrorCode code, NSString *message) {
        @strongify(self);
        if (!self.isCanceled) {
            request.metrics.geckoFinish = [[NSDate date] timeIntervalSince1970]* 1000;
            request.geckoError = message;
            request.geckoErrorCode = code;
            IESGurdLogInfo(@"Forest - Gecko: request [%@] error: %@", self.request.url, message);
            completion(nil, [IESForestError errorWithCode:code message:message]);
        }
    };

    if (!self.request.hasValidGeckoInfo) {
        if (BTD_isEmptyString(self.request.accessKey)) {
            reject(IESForestErrorGeckoAccessKeyEmpty, @"Gecko accessKey invalid");
        } else {
            reject(IESForestErrorGeckoChannelBundleEmpty, @"Gecko channel/bundle invalid");
        }
        return;
    }

    if ([[self.request channel] containsString:@"../"] || [[self.request bundle] containsString:@"../"]) {
        reject(IESForestErrorGeckoChannelBundleInvalid, @"Channel/bundle path contains ../");
        return;
    }
    
    if (self.request.waitGeckoUpdate && !self.request.onlyLocal) {
        IESForestResponse *response = [self fetchGeckoLocalData];
        if (response.data) {
            // Get local resource, trigger lazy sync
            [self lockSessionWithRequest:request];
            resolve(response);
            [IESForestGeckoUtil syncChannel:self.request.channel accessKey:self.request.accessKey];
        } else {
            // No local resource available, trigger normal sync
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self syncChannel:self.request.channel accessKey:self.request.accessKey resolve:resolve reject:reject];
            });
        }
    } else {
        IESForestResponse *response = [self fetchGeckoLocalData];
        if (response.data) {
            // Get local resource, trigger lazy sync
            [self lockSessionWithRequest:request];
            resolve(response);
            [IESForestGeckoUtil syncChannel:self.request.channel accessKey:self.request.accessKey];
        } else {
            reject(IESForestErrorGeckoLocalFileNotFound, @"Gecko local file not found");
            [IESForestGeckoUtil syncChannel:self.request.channel accessKey:self.request.accessKey];
        }
    }
}

- (IESForestResponse *)fetchGeckoLocalData
{
    NSString *accessKey = self.request.accessKey;
    NSString *channelName = self.request.channel;
    NSString *bundleName = self.request.bundle;
    NSData *resourceData = nil;
    
    if (self.request.onlyPath) {
        NSString *dirName = [IESGurdKit rootDirForAccessKey:accessKey channel:channelName];
        if ([bundleName hasPrefix:@"/"]) {
            dirName = [NSString stringWithFormat:@"%@%@", dirName, bundleName];
        } else {
            dirName = [NSString stringWithFormat:@"%@/%@", dirName, bundleName];
        }
        if ([[NSFileManager defaultManager] fileExistsAtPath:dirName]) {
            // Don't read actual data, construct a non-empty data object
            resourceData = [[NSData alloc] init];
        }
    } else {
        resourceData = [IESGeckoKit offlineDataForPath:bundleName accessKey:accessKey channel:channelName];
    }
    
    IESForestResponse *response = [[IESForestResponse alloc] initWithRequest:self.request];
    response.data = resourceData;
    response.absolutePath = [[IESGurdKit rootDirForAccessKey:accessKey channel:channelName] stringByAppendingPathComponent:bundleName];
    response.sourceType = IESForestDataSourceTypeGeckoLocal;
    response.version = [IESGeckoKit packageVersionForAccessKey:accessKey channel:channelName];
    return response;
}

- (void)cancelFetch
{
    self.isCanceled = YES;
}

#pragma mark - private

- (void)syncChannel:(NSString *)channel
          accessKey:(NSString *)accessKey
            resolve:(void (^)(id<IESForestResponseProtocol> response))resolve
             reject:(void (^)(IESForestErrorCode code, NSString *message))reject
{
    self.request.metrics.geckoUpdateStart = [[NSDate date] timeIntervalSince1970] * 1000;
    @weakify(self);
    IESGurdSyncStatusDictionaryBlock completion = ^(BOOL succeed, IESGurdSyncStatusDict dict) {
        @strongify(self);
        self.request.metrics.geckoUpdateFinish = [[NSDate date] timeIntervalSince1970] * 1000;
        if (succeed) {
            IESForestResponse *response = [self fetchGeckoLocalData];
            if (response.data) {
                self.request.geckoError = @"";
                response.sourceType = IESForestDataSourceTypeGeckoUpdate;
                [self lockSessionWithRequest:self.request];
                resolve(response);
            } else {
                reject(IESForestErrorGeckoUpdatedButLocalFileNotFound, @"Gecko update success, but can't find local file");
            }
        } else {
            reject(IESForestErrorGeckoUpdateFailed, @"Gecko update failed");
        }
//        IESGurdLogInfo(@"Forest - Sync Resources %@", succeed ? @"Successfully" : @"Failed");
    };

    [IESGurdKit syncResourcesWithParamsBlock:^(IESGurdFetchResourcesParams *_Nonnull params) {
        params.accessKey = accessKey;
        params.channels = @[channel];
        params.forceRequest = YES;
        params.requestWhenHasLocalVersion = NO;
        params.downloadPriority = IESGurdDownloadPriorityUserInteraction;
        params.pollingPriority = IESGurdPollingPriorityLevel1;
     } completion:completion];
}

- (NSString *)lockSessionWithRequest:(IESForestRequest *)request
{
    if (BTD_isEmptyString(request.sessionId) || BTD_isEmptyString(request.channel) || BTD_isEmptyString(request.accessKey) || [self.forestKit containsChannelInChannelListWithSessionID:request.sessionId andAccessKey:request.accessKey andChannel:request.channel]) {
        return request.sessionId;
    }
    
    [IESGurdKit lockChannel:request.accessKey channel:request.channel];
    [self.forestKit addChannelToChannelListWithSessionID:request.sessionId andAccessKey:request.accessKey andChannel:request.channel];
    return request.sessionId;
}

@end
