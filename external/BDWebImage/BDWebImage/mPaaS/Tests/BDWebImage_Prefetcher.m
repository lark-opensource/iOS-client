//
//  BDWebImage_Prefetcher.m
//  BDWebImageTestTests
//
//  Created by zhangtianfu on 2018/12/18.
//  Copyright © 2018 zhangtianfu. All rights reserved.
//

#import "BaseTestCase.h"
#import <BDWebImage/BDWebImage.h>

#import <OHHTTPStubs/OHHTTPStubs.h>

#define PREFETCHER_CACHE_NAME @"prefetcher.test"

@interface BDWebImage_Prefetcher : BaseTestCase

@end

@implementation BDWebImage_Prefetcher

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [[BDWebImageManager sharedManager].imageCache.diskCache removeAllData];
    [[BDWebImageManager sharedManager].imageCache.memoryCache removeAllObjects];
    
    [[BDWebImageManager sharedManager] registCache:[[BDImageCache alloc] initWithName:PREFETCHER_CACHE_NAME] forKey:PREFETCHER_CACHE_NAME];
    [[[BDWebImageManager sharedManager] cacheForKey:PREFETCHER_CACHE_NAME].diskCache removeAllData];
    [[[BDWebImageManager sharedManager] cacheForKey:PREFETCHER_CACHE_NAME].memoryCache removeAllObjects];
    
    [super setUp];
}

- (void)tearDown {
    [[BDWebImageManager sharedManager] cancelAll];
    [super tearDown];
}

- (void)test_01_single_image {
    XCTestExpectation *expectation = [self expectationWithDescription:@"prefetch single image"];
    BDWebImageRequest *reqeust = [[BDWebImageManager sharedManager] prefetchImageWithURL:[NSURL URLWithString:TEST_URL_1] category:@"test" options:1];
    reqeust.completedBlock = ^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNotNil(image);
        XCTAssertNotNil(data);
        XCTAssertNil(error);
        [expectation fulfill];
    };
    XCTAssertEqual(@"test", reqeust.category);
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_02_multi_image_urls {
    [[BDWebImageManager sharedManager] cancelAllPrefetchs];

    NSArray *urls = @[[NSURL URLWithString:TEST_URL_1],
                      [NSURL URLWithString:TEST_URL_2],
                      [NSURL URLWithString:TEST_URL_3]];
    for (NSURL *url in urls) {
        [self removeImageCache:url];
    }
    NSArray *reqeusts = [[BDWebImageManager sharedManager] prefetchImagesWithURLs:urls category:@"test" options:0];
    XCTAssertEqual(urls.count, reqeusts.count);
//    XCTAssertEqual(urls.count, [BDWebImageManager sharedManager].allPrefetchs.count);
    NSArray *reqs = [[BDWebImageManager sharedManager] requestsWithCategory:@"test"];
    NSMutableArray *tmpArray = [NSMutableArray arrayWithArray:reqs];
    [tmpArray removeObjectsInArray:reqeusts];
    XCTAssertEqual(tmpArray.count, 0);
}

- (void)test_03_multi_image_strings {
    [[BDWebImageManager sharedManager] cancelAllPrefetchs];

    NSArray *urls = @[TEST_URL_1, TEST_URL_2, TEST_URL_3];
    for (NSString *url in urls) {
        [self removeImageCache:[NSURL URLWithString:url]];
    }

    NSArray *reqeusts = [[BDWebImageManager sharedManager] prefetchImagesWithURLs:urls category:@"test" options:0];
    XCTAssertEqual(urls.count, reqeusts.count);
//    XCTAssertEqual(urls.count, [BDWebImageManager sharedManager].allPrefetchs.count);
}

- (void)test_04_multi_image {
    [[BDWebImageManager sharedManager] cancelAllPrefetchs];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Prefetch urls array"];

    __block NSUInteger numberOfPrefetched = 0;
    
    NSArray *urls = @[[NSURL URLWithString:TEST_URL_1],
                      [NSURL URLWithString:TEST_URL_2],
                      [NSURL URLWithString:TEST_URL_3]];
    for (NSURL *url in urls) {
        [self removeImageCache:url];
    }

    NSArray *reqeusts = [[BDWebImageManager sharedManager] prefetchImagesWithURLs:urls category:@"test" options:0];
    for (BDWebImageRequest *request in reqeusts) {
        request.completedBlock = ^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            XCTAssertNotNil(image);
            XCTAssertNotNil(data);
            XCTAssertNil(error);
            numberOfPrefetched++;
            if (numberOfPrefetched == urls.count) {
                [expectation fulfill];
            }
        };
    }
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_05_cancel_prefetcher {
    NSArray *urls = @[[NSURL URLWithString:TEST_URL_4],
                      [NSURL URLWithString:TEST_URL_5],
                      [NSURL URLWithString:TEST_URL_6]];
    for (NSURL *url in urls) {
        [self removeImageCache:url];
    }
    NSArray *reqeusts = [[BDWebImageManager sharedManager] prefetchImagesWithURLs:urls category:@"test" options:0];
    for (BDWebImageRequest *request in reqeusts) {
        request.completedBlock = ^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            XCTFail(@"something is wrong");
        };
    }
    
    [[BDWebImageManager sharedManager] cancelAllPrefetchs];
    
//    XCTAssertEqual([[BDWebImageManager sharedManager] allPrefetchs].count, 0);
}

- (void)test_06_empty_prefetcher {
    NSArray *urls = @[];
    NSArray *reqeusts = [[BDWebImageManager sharedManager] prefetchImagesWithURLs:urls category:@"test" options:0];
    XCTAssertEqual(reqeusts.count, 0);
//    XCTAssertEqual([[BDWebImageManager sharedManager] allPrefetchs].count, 0);
}

- (void)test_07_prefetch_url_with_cache {
    XCTestExpectation *expectation = [self expectationWithDescription:@"prefetch single image with url"];
    [self removeImageCache:[NSURL URLWithString:TEST_URL_1]];
    BDWebImageRequest *reqeust = [[BDWebImageManager sharedManager] prefetchImageWithURL:[NSURL URLWithString:TEST_URL_1]
                                                                               cacheName:PREFETCHER_CACHE_NAME
                                                                                category:@"test"
                                                                                 options:1];
    reqeust.completedBlock = ^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNotNil(image);
        XCTAssertNotNil(data);
        XCTAssertNil(error);
        XCTAssertEqual(PREFETCHER_CACHE_NAME, request.cacheName);
        XCTAssertTrue([[[BDWebImageManager sharedManager] cacheForKey:PREFETCHER_CACHE_NAME] containsImageForKey:request.requestKey]);
        [expectation fulfill];
    };
    XCTAssertEqual(@"test", reqeust.category);
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_08_prefetch_urls_with_cache {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Prefetch urls array"];
    
    __block NSUInteger numberOfPrefetched = 0;
    
    NSArray *urls = @[[NSURL URLWithString:TEST_URL_1],
                      [NSURL URLWithString:TEST_URL_2],
                      [NSURL URLWithString:TEST_URL_3]];
    for (NSURL *url in urls) {
        [self removeImageCache:url];
    }
    
    NSArray *reqeusts = [[BDWebImageManager sharedManager] prefetchImagesWithURLs:urls
                                                                        cacheName:PREFETCHER_CACHE_NAME
                                                                         category:@"test"
                                                                          options:0];
    for (BDWebImageRequest *request in reqeusts) {
        request.completedBlock = ^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            XCTAssertNotNil(image);
            XCTAssertNotNil(data);
            XCTAssertNil(error);
            XCTAssertEqual(PREFETCHER_CACHE_NAME, request.cacheName);
            XCTAssertTrue([[[BDWebImageManager sharedManager] cacheForKey:PREFETCHER_CACHE_NAME] containsImageForKey:request.requestKey]);
            numberOfPrefetched++;
            if (numberOfPrefetched == urls.count) {
                [expectation fulfill];
            }
        };
    }
    
    [self waitForExpectationsWithCommonTimeout];
}

@end

