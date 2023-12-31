//
//  CacheTests.m
//  IESPrefetch-Unit-Tests
//
//  Created by yuanyiyang on 2019/12/16.
//

#import <Specta/Specta.h>
#import <Expecta/Expecta.h>
#import <OCMock/OCMock.h>
#import <IESPrefetch/IESPrefetchCacheProvider.h>
#import <IESPrefetch/IESPrefetchCacheStorageProtocol.h>
#import <IESPrefetch/IESPrefetchCacheModel+RequestModel.h>
#import "MemoryTestCacheStorage.h"

SpecBegin(Cache)

describe(@"CacheProvider", ^{
         it(@"saveStorage", ^{
    MemoryCacheTestStorage *storage = [MemoryCacheTestStorage new];
    IESPrefetchCacheProvider *provider = [[IESPrefetchCacheProvider alloc] initWithCacheStorage:storage];
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    IESPrefetchCacheModel *cache = [IESPrefetchCacheModel modelWithData:@{@"key":@"value"} timeInterval:now expires:15];
    cache.requestDescription = @"request_description";
    [provider addCacheWithModel:cache forKey:@"1234"];
    IESPrefetchCacheModel *fetchedCache = [provider modelForKey:@"1234"];
    expect(fetchedCache.data[@"key"]).equal(@"value");
    expect(fetchedCache.timeInterval).equal(now);
    expect(fetchedCache.expires).equal(15);
    expect(provider.allCaches.count).equal(1);
    expect(fetchedCache.requestDescription).equal(@"request_description");
    
    
    storage = nil;
});
         it(@"expiredCache", ^{
    MemoryCacheTestStorage *storage = [MemoryCacheTestStorage new];
    IESPrefetchCacheProvider *provider = [[IESPrefetchCacheProvider alloc] initWithCacheStorage:storage];
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    IESPrefetchCacheModel *cache = [IESPrefetchCacheModel modelWithData:@{@"key":@"value"} timeInterval:now expires:2];
    cache.requestDescription = @"request_description";
    [provider addCacheWithModel:cache forKey:@"1234"];
    
    waitUntilTimeout(10, ^(DoneCallback done) {

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            IESPrefetchCacheModel *fetchedCache = [provider modelForKey:@"1234"];
            expect(fetchedCache).to.beNil();
            expect(provider.allCaches.count).equal(0);
            done();
        });
    });
});
         it(@"cleanExpiredCache", ^{
    MemoryCacheTestStorage *storage = [MemoryCacheTestStorage new];
    IESPrefetchCacheProvider *provider = [[IESPrefetchCacheProvider alloc] initWithCacheStorage:storage];
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    IESPrefetchCacheModel *cache1 = [IESPrefetchCacheModel modelWithData:@{@"key":@"value"} timeInterval:now expires:15];
    IESPrefetchCacheModel *cache2 = [IESPrefetchCacheModel modelWithData:@{@"key2":@"value2"} timeInterval:now expires:2];
    [provider addCacheWithModel:cache1 forKey:@"cache1"];
    [provider addCacheWithModel:cache2 forKey:@"cache2"];
    waitUntilTimeout(10, ^(DoneCallback done) {

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [provider cleanExpiredDataIfNeed];
            expect([provider modelForKey:@"cache2"]).to.beNil();
            expect([provider modelForKey:@"cache1"]).notTo.beNil();
            expect(provider.allCaches.count).equal(1);
            done();
        });
    });
});
});

SpecEnd
