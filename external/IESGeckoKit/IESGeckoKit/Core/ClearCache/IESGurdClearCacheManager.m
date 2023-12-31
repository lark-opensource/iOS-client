//
//  IESGurdClearCacheManager.m
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/7/20.
//

#import "IESGurdClearCacheManager.h"

#import "IESGeckoKit.h"
#import "IESGeckoDefines+Private.h"
#import "IESGurdProtocolDefines.h"
//manager
#import "IESGurdFileBusinessManager.h"
#import "IESGurdCacheCleanerManager.h"
#import "IESGurdDelegateDispatcherManager.h"

@interface IESGurdClearCacheManager () <IESGurdEventDelegate>

@end

@implementation IESGurdClearCacheManager

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [IESGurdKit registerEventDelegate:[self sharedManager]];
    });
}

+ (instancetype)sharedManager
{
    static IESGurdClearCacheManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

+ (void)clearCache
{
    [IESGurdFileBusinessManager clearCache];
}

+ (void)clearCacheExceptWhitelist
{
    [IESGurdFileBusinessManager clearCacheExceptWhitelist];
}

+ (void)clearCacheForAccessKey:(NSString *)accessKey
                       channel:(NSString *)channel
{
    [self clearCacheForAccessKey:accessKey
                         channel:channel
                          isSync:NO
                      completion:nil];
}

+ (void)clearCacheForAccessKey:(NSString *)accessKey
                       channel:(NSString *)channel
                    completion:(void (^ _Nullable)(BOOL succeed, NSDictionary *info, NSError *error))completion
{
    [self clearCacheForAccessKey:accessKey
                         channel:channel
                          isSync:NO
                      completion:completion];
}

+ (void)clearCacheForAccessKey:(NSString *)accessKey
                       channel:(NSString *)channel
                        isSync:(BOOL)isSync
                    completion:(void (^ _Nullable)(BOOL succeed, NSDictionary *info, NSError *error))completion
{
    if (accessKey.length == 0 || channel.length == 0) {
        !completion ? : completion(NO, nil, nil);
        return;
    }
    [IESGurdFileBusinessManager cleanCacheForAccessKey:accessKey
                                               channel:channel
                                                isSync:isSync
                                            completion:completion];
}

#pragma mark - IESGurdEventDelegate

- (void)gurdDidCleanCachePackageForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    id<IESGurdCacheCleaner> cleaner = [[IESGurdCacheCleanerManager sharedManager] cleanerForAccessKey:accessKey];
    if ([cleaner respondsToSelector:@selector(gurdDidCleanPackageForChannel:)]) {
        [cleaner gurdDidCleanPackageForChannel:channel];
    }
}

@end
