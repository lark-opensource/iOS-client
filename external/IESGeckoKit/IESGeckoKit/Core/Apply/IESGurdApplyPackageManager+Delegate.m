//
//  IESGurdApplyPackageManager+Delegate.m
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/7/22.
//

#import "IESGurdApplyPackageManager.h"

#import "IESGurdCacheCleanerManager.h"

@interface IESGurdApplyPackageManager (Delegate) <IESGurdApplyPackageManagerDelegate>

@end

@implementation IESGurdApplyPackageManager (Delegate)

- (id<IESGurdApplyPackageManagerDelegate>)delegate
{
    return self;
}

#pragma mark - IESGurdApplyPackageManagerDelegate

- (void)applyPackageManager:(IESGurdApplyPackageManager *)manager
didApplyPackageForAccessKey:(NSString *)accessKey
                    channel:(NSString *)channel
{
    IESGurdCacheCleanerManager *cacheCleanerManager = [IESGurdCacheCleanerManager sharedManager];
    if ([cacheCleanerManager isChannelInWhitelist:channel accessKey:accessKey]) {
        return;
    }
    
    id<IESGurdCacheCleaner> cleaner = [cacheCleanerManager cleanerForAccessKey:accessKey];
    if ([cleaner respondsToSelector:@selector(gurdDidApplyPackageForChannel:)]) {
        [cleaner gurdDidApplyPackageForChannel:channel];
    }
}

@end
