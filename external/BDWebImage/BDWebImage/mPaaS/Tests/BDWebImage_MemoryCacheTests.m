//
//  BDWebImage_MemoryCacheTests.m
//  BDWebImage_Tests
//
//  Created by 陈奕 on 2019/10/11.
//  Copyright © 2019 Bytedance.com. All rights reserved.
//

#import <XCTest/XCTest.h>
//#import <BDMemoryYYCache.h>
#import <BDImageNSCache.h>

@interface BDWebImage_MemoryCacheTests : XCTestCase

//@property (nonatomic, strong) BDMemoryYYCache *yy;
@property (nonatomic, strong) BDImageNSCache *ns;
@property (nonatomic, strong) NSMutableArray *keys;
@property (nonatomic, strong) NSMutableArray *values;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, assign) NSUInteger length;

@end

@implementation BDWebImage_MemoryCacheTests

- (void)setUp {
    BDImageCacheConfig *config = [BDImageCacheConfig new];
    config.clearMemoryOnMemoryWarning = NO;
    config.memorySizeLimit = 50 * 1024;
    config.memoryAgeLimit = 12 * 60 * 60;
//    self.yy = [[BDMemoryYYCache alloc] initWithConfig:config];
    self.ns = [[BDImageNSCache alloc] initWithConfig:config];

    self.keys = [NSMutableArray new];
    self.values = [NSMutableArray new];
    self.count = 1000;
    self.length = 200;
    for (int i = 0; i < self.count; i++) {
        NSObject *key;
//        key = @(i).description;
        key = @(i);
        void *buffer = malloc(self.length);
        NSData *value = [NSData dataWithBytes:buffer length:self.length];
        free(buffer);
        [self.keys addObject:key];
        [self.values addObject:value];
    }
}

//- (void)testYYCacheWithoutLimit {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//        @autoreleasepool {
//            for (int i = 0; i < self->_count; i++) {
//                [self->_yy setObject:self->_values[i] forKey:self->_keys[i]];
//            }
//        }
//        [self->_yy removeAllObjects];
//    }];
//}

- (void)testNSCacheWithoutLimit {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        @autoreleasepool {
            for (int i = 0; i < self->_count; i++) {
                [self->_ns setObject:self->_values[i] forKey:self->_keys[i]];
            }
        }
        [self->_ns removeAllObjects];
    }];
}

//- (void)testYYCacheWithSizeLimit {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//        @autoreleasepool {
//            for (int i = 0; i < self->_count; i++) {
//                [self->_yy setObject:self->_values[i] forKey:self->_keys[i] cost:self->_length];
//            }
//        }
//        [self->_yy removeAllObjects];
//    }];
//}

- (void)testNSCacheWithSizeLimit {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        @autoreleasepool {
            for (int i = 0; i < self->_count; i++) {
                [self->_ns setObject:self->_values[i] forKey:self->_keys[i] cost:self->_length];
            }
        }
        [self->_ns removeAllObjects];
    }];
}

//- (void)testBenchmark {
//    [self memoryCacheBenchmark];
//}
//
//- (void)memoryCacheBenchmark {
//    NSCache *ns = [NSCache new];
//    ns.countLimit = NSIntegerMax;
//    ns.totalCostLimit = 50 * 1024 * 1024;
//    YYMemoryCache *yy = [YYMemoryCache new];
////    yy.releaseAsynchronously = NO;
////    yy.releaseOnMainThread = YES;
//    yy.countLimit = NSIntegerMax;
//    yy.costLimit = 50 * 1024 * 1024;
//
//    NSMutableArray *keys = [NSMutableArray new];
//    NSMutableArray *values = [NSMutableArray new];
//    int count = 100000;
//    size_t length = 1000;
//    for (int i = 0; i < count; i++) {
//        NSObject *key;
////        key = @(i); // avoid string compare
//        key = @(i).description; // it will slow down NSCache...
////        key = [NSUUID UUID].UUIDString;
//        void *buffer = malloc(length);
//        NSData *value = [NSData dataWithBytes:buffer length:length];
//        free(buffer);
//        [keys addObject:key];
//        [values addObject:value];
//    }
//
//    NSTimeInterval begin, end, time;
//
//    printf("\n===========================\n");
//    printf("Memory cache set 200000 key-value pairs\n");
//
//    begin = CACurrentMediaTime();
//    @autoreleasepool {
//        for (int i = 0; i < count; i++) {
//            [yy setObject:values[i] forKey:keys[i]];
//        }
//    }
//    end = CACurrentMediaTime();
//    time = end - begin;
//    printf("Write(without limit) —— YYMemoryCache:  %8.2f\n", time * 1000);
//
//    begin = CACurrentMediaTime();
//    @autoreleasepool {
//        for (int i = 0; i < count; i++) {
//            [ns setObject:values[i] forKey:keys[i]];
//        }
//    }
//    end = CACurrentMediaTime();
//    time = end - begin;
//    printf("Write(without limit) —— NSCache:        %8.2f\n", time * 1000);
//
//    [yy removeAllObjects];
//    [ns removeAllObjects];
//    yy.countLimit = 5000;
//    ns.countLimit = 5000;
//
//    begin = CACurrentMediaTime();
//    @autoreleasepool {
//        for (int i = 0; i < count; i++) {
//            [yy setObject:values[i] forKey:keys[i]];
//        }
//    }
//    end = CACurrentMediaTime();
//    time = end - begin;
//    printf("Write(count) —— YYMemoryCache:  %8.2f\n", time * 1000);
//
//    begin = CACurrentMediaTime();
//    @autoreleasepool {
//        for (int i = 0; i < count; i++) {
//            [ns setObject:values[i] forKey:keys[i]];
//        }
//    }
//    end = CACurrentMediaTime();
//    time = end - begin;
//    printf("Write(count) —— NSCache:        %8.2f\n", time * 1000);
//
//    [yy removeAllObjects];
//    [ns removeAllObjects];
//    yy.countLimit = NSIntegerMax;
//    ns.countLimit = NSIntegerMax;
//
//    begin = CACurrentMediaTime();
//    @autoreleasepool {
//        for (int i = 0; i < count; i++) {
//            [yy setObject:values[i] forKey:keys[i] withCost:length];
//        }
//    }
//    end = CACurrentMediaTime();
//    time = end - begin;
//    printf("Write(cost) —— YYMemoryCache:  %8.2f\n", time * 1000);
//
//    begin = CACurrentMediaTime();
//    @autoreleasepool {
//        for (int i = 0; i < count; i++) {
//            [ns setObject:values[i] forKey:keys[i] cost:length];
//        }
//    }
//    end = CACurrentMediaTime();
//    time = end - begin;
//    printf("Write(cost) —— NSCache:        %8.2f\n", time * 1000);
//
//    begin = CACurrentMediaTime();
//    @autoreleasepool {
//        for (int i = 0; i < count; i++) {
//            [yy objectForKey:keys[i]];
//        }
//    }
//    end = CACurrentMediaTime();
//    time = end - begin;
//    printf("Read —— YYMemoryCache:  %8.2f\n", time * 1000);
//
//    begin = CACurrentMediaTime();
//    @autoreleasepool {
//        for (int i = 0; i < count; i++) {
//            [ns objectForKey:keys[i]];
//        }
//    }
//    end = CACurrentMediaTime();
//    time = end - begin;
//    printf("Read —— NSCache:        %8.2f\n", time * 1000);
//}

- (void)testNSCacheWeakCache {
    BDImageCacheConfig *config = [BDImageCacheConfig new];
    config.shouldUseWeakMemoryCache = NO;
    config.clearMemoryOnMemoryWarning = YES;
    config.memorySizeLimit = 10;
    config.memoryCountLimit = 1;
    
    // 不使用weak cache
    BDImageNSCache *memoryCache = [[BDImageNSCache alloc] initWithConfig:config];
    XCTAssertEqual(memoryCache.countLimit, 1);
    XCTAssertEqual(memoryCache.totalCostLimit, 10);
    NSObject *obj = [NSObject new];
    [memoryCache setObject:obj forKey:@"1"];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    NSObject *cacheObj = [memoryCache objectForKey:@"1"];
    XCTAssertNil(cacheObj);
    
    // 使用weak cache
    config.shouldUseWeakMemoryCache = YES;
    BDImageNSCache *memoryCache1 = [[BDImageNSCache alloc] initWithConfig:config];
    XCTAssertEqual(memoryCache1.countLimit, 1);
    XCTAssertEqual(memoryCache1.totalCostLimit, 10);
    [memoryCache1 setObject:obj forKey:@"1"];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    // 从weakCache中取出对象
    cacheObj = [memoryCache1 objectForKey:@"1"];
    XCTAssertNotNil(cacheObj);
}

@end
