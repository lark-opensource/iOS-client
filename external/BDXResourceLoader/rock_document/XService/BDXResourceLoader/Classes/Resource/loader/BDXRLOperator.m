//
//  BDXResourceLoaderAdvancedOperator.m
//  BDXResourceLoader
//
//  Created by David on 2021/3/16.
//

#import "BDXRLOperator.h"

#import "BDXGurdService.h"
#import "BDXGurdSyncManager.h"
#import "BDXGurdSyncTask.h"
#import "BDXResourceLoader.h"
#import "NSError+BDXRL.h"
#import <BDXServiceCenter/BDXServiceRegister.h>
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>

@interface BDXRLOperator ()

@property(nonatomic, strong) NSMutableDictionary *falconPrefixList;

@end

@implementation BDXRLOperator

- (void)syncChannelIfNeeded:(NSString *)channel accessKey:(NSString *)accessKey completion:(BDXGeckoCompletionHandler)completion
{
    [self __syncChannels:@[channel] accessKey:accessKey options:BDXGurdSyncResourcesOptionsNone completion:completion];
}

- (void)syncChannelIfNeeded:(NSString *)channel accessKey:(NSString *)accessKey
{
    [self __syncChannels:@[channel] accessKey:accessKey options:BDXGurdSyncResourcesOptionsNone completion:nil];
}

- (void)__syncChannels:(NSArray<NSString *> *)channels accessKey:(NSString *)accessKey options:(BDXGurdSyncResourcesOptions)options completion:(BDXGeckoCompletionHandler)completion
{
    if (channels.count == 0) {
        if (completion) {
            completion(NO, [NSError errorWithCode:BDXRLErrorCodeEmptyParam message:@"channels empty"]);
        }
        return;
    }
    if (accessKey.length == 0) {
        if (completion) {
            completion(NO, [NSError errorWithCode:BDXRLErrorCodeEmptyParam message:@"channels empty"]);
        }
        return;
    }
    BDXGurdSyncTask *task = [BDXGurdSyncTask taskWithAccessKey:accessKey groupName:nil channelsArray:channels completion:^(BDXGurdSyncResourcesResult *result) {
        if (completion) {
            completion(result.successfully, nil);
        }
    }];
    task.options = options;
    task.disableThrottle = self.resourceLoader.loaderConfig.disableGurdThrottle;
    task.downloadPriority = self.resourceLoader.loaderConfig.gurdDownloadPrority;

    if (task.disableThrottle) {
        task.options |= BDXGurdSyncResourcesOptionsDisableThrottle;
    } else {
        task.options &= ~BDXGurdSyncResourcesOptionsDisableThrottle;
    }
    [BDXGurdSyncManager enqueueSyncResourcesTask:task];
}

- (void)registeDefaultAccessKey:(NSString *)accessKey
{
    [BDXGurdService registerAccessKey:accessKey];
}

- (NSString *)getDefaultAccessKey
{
    return [BDXGurdService accessKey];
}

- (void)registeAccessKey:(NSString *)accessKey withPrefixList:(NSArray *)prefixList;
{
    if (BTD_isEmptyString(accessKey)) {
        return;
    }

    [self registeDefaultAccessKey:accessKey];

    if (BTD_isEmptyArray(prefixList)) {
        return;
    }

    if (!self.falconPrefixList) {
        self.falconPrefixList = [[NSMutableDictionary alloc] init];
    }

    [self.falconPrefixList setValue:prefixList forKey:accessKey];
}

- (void)registeAccessKey:(NSString *__nonnull)accessKey appendPrefixList:(NSArray *)prefixList
{
    if (BTD_isEmptyString(accessKey)) {
        return;
    }

    [self registeDefaultAccessKey:accessKey];

    if (BTD_isEmptyArray(prefixList)) {
        return;
    }

    [self appendPrefixList:prefixList withAccessKey:accessKey];
}

- (void)appendPrefixList:(NSArray *)prefixList withAccessKey:(NSString *__nonnull)accessKey
{
    if (BTD_isEmptyString(accessKey) || BTD_isEmptyArray(prefixList)) {
        return;
    }

    if (!self.falconPrefixList) {
        self.falconPrefixList = [[NSMutableDictionary alloc] init];
    }

    NSMutableArray *temp = [NSMutableArray arrayWithArray:[self.falconPrefixList btd_arrayValueForKey:accessKey] ?: @[]];
    for (id object in prefixList) {
        if (![temp containsObject:object]) {
            [temp addObject:object];
        }
    }
    [self.falconPrefixList setValue:[temp copy] forKey:accessKey];
}


@end
