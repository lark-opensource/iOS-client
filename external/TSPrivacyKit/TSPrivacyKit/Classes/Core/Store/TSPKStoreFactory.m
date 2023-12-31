//
//  TSPKStoreFactory.m
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/26.
//

#import "TSPKStoreFactory.h"

#import "TSPKRelationObjectCacheStore.h"

@implementation TSPKStoreFactory

+ (id<TSPKStore>)storeWithType:(TSPKStoreType)storeType
{
    if (storeType == TSPKStoreTypeRelationObjectCache) {
        return [TSPKRelationObjectCacheStore new];
    }
    return nil;
}

@end
