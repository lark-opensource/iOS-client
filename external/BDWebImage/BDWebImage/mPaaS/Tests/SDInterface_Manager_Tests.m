//
//  SDInterface_Manager_Tests.m
//  BDWebImage_Tests
//
//  Created by 陈奕 on 2020/1/6.
//  Copyright © 2020 Bytedance.com. All rights reserved.
//

#import "BaseTestCase.h"
#import <SDInterface.h>

@interface SDInterface_Manager_Tests : BaseTestCase

@end

@implementation SDInterface_Manager_Tests

- (void)setUp {
    [[BDWebImageManager sharedManager].imageCache.diskCache removeAllData];
    [[BDWebImageManager sharedManager].imageCache.memoryCache removeAllObjects];
    
    [super setUp];
}

#pragma mark  ------------- Manager -------------

- (void)test_02_load_image {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Manager load iamge"];

    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];

    [[SDInterface sharedInterface] loadImageWithURL:originalImageURL
                                                options:0
                                               progress:nil
                                              completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                                                  XCTAssertNotNil(image);
                                                  XCTAssertNil(error);
                                                  XCTAssertEqual(originalImageURL, imageURL);
                                                  XCTAssertTrue(finished);
                                                  [expectation fulfill];
                                               }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_03_cancel_load_image{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Manager cancel load iamge"];
    
    [[SDInterface sharedInterface] clearMemory];
    
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    BDWebImageRequest *request = [[SDInterface sharedInterface] loadImageWithURL:originalImageURL
                                                                                                 options:0
                                                                                                progress:nil
                                                                                               completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                                                                                                   XCTFail(@"something is wrong");
                                                                                               }];
    [request cancel];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithCommonTimeout];
}


#pragma mark  ------------- Downloader -------------

- (void)test_04_download_image {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Manager cancel download iamge"];
    
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    
    [[SDInterface sharedInterface] clearMemory];
    [[SDInterface sharedInterface] clearDiskOnCompletion:^{
        [[SDInterface sharedInterface] downloadImageWithURL:originalImageURL
                                                        options:0
                                                       progress:nil
                                                      completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
                                                          XCTAssertNotNil(image);
                                                          XCTAssertNotNil(data);
                                                          XCTAssertNil(error);
                                                          XCTAssertTrue(finished);
                                                          [expectation fulfill];
                                                      }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_05_cancel_download_image {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Manager canel download iamge"];
    
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    
    [[SDInterface sharedInterface] clearMemory];
    [[SDInterface sharedInterface] clearDiskOnCompletion:^{
        id token = [[SDInterface sharedInterface] downloadImageWithURL:originalImageURL
                                                        options:0
                                                       progress:nil
                                                      completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
                                                          XCTFail(@"something is wrong");
                                                      }];
        XCTAssertNotNil(token);
        [[SDInterface sharedInterface] cancel:token];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
            UIImage *image = [[SDInterface sharedInterface] imageFromCacheForKey:[[SDInterface sharedInterface] cacheKeyForURL:originalImageURL]];
            XCTAssertNil(image);
            [expectation fulfill];
        });
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

//- (void)test_06_cancel_all_download_image {
//    XCTestExpectation *expectation = [self expectationWithDescription:@"Manager canel all download iamge"];
//
//    [[SDInterface sharedInterface] clearMemory];
//    [[SDInterface sharedInterface] clearDiskOnCompletion:^{
//        NSURL *jpgURL = [NSURL URLWithString:kTestJpegURL];
//        NSURL *pngURL = [NSURL URLWithString:kTestPNGURL];
//        [[SDInterface sharedInterface] downloadImageWithURL:jpgURL
//                                                        options:0
//                                                       progress:nil
//                                                      completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
//                                                          XCTFail(@"something is wrong");
//                                                      }];
//        [[SDInterface sharedInterface] downloadImageWithURL:pngURL
//                                                        options:0
//                                                       progress:nil
//                                                      completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
//                                                          XCTFail(@"something is wrong");
//                                                      }];
//        [[SDInterface sharedInterface] cancelAllDownloads];
//
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
//            UIImage *jpgImage = [[SDInterface sharedInterface] imageFromCacheForKey:[[SDInterface sharedInterface] cacheKeyForURL:jpgURL]];
//            XCTAssertNil(jpgImage);
//            UIImage *pngImage = [[SDInterface sharedInterface] imageFromCacheForKey:[[SDInterface sharedInterface] cacheKeyForURL:pngURL]];
//            XCTAssertNil(pngImage);
//            [expectation fulfill];
//        });
//    }];
//
//    [self waitForExpectationsWithCommonTimeout];
//}

#pragma mark  ------------- Prefetcher -------------

- (void)test_07_prefetch_URLs {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Manager prefetch urls"];
    
    NSURL *jpgURL = [NSURL URLWithString:kTestJpegURL];
    NSURL *pngURL = [NSURL URLWithString:kTestPNGURL];
    NSArray *imageURLs = @[jpgURL, pngURL];
    
    __block NSUInteger numberOfPrefetched = 0;
    
    [[SDInterface sharedInterface] clearDiskOnCompletion:^{
        [[SDInterface sharedInterface] prefetchURLs:imageURLs
                                               progress:^(NSUInteger noOfFinishedUrls, NSUInteger noOfTotalUrls) {
                                                   numberOfPrefetched += 1;
                                                   XCTAssertEqual(numberOfPrefetched, noOfFinishedUrls);
                                                   XCTAssertLessThanOrEqual(noOfFinishedUrls, noOfTotalUrls);
                                                   XCTAssertEqual(noOfTotalUrls, imageURLs.count);
                                               } completed:^(NSUInteger noOfFinishedUrls, NSUInteger noOfSkippedUrls) {
                                                   XCTAssertEqual(numberOfPrefetched, noOfFinishedUrls);
                                                   XCTAssertEqual(noOfFinishedUrls, imageURLs.count);
                                                   XCTAssertEqual(noOfSkippedUrls, 0);
                                                   [expectation fulfill];
                                               }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

// 不能同步取消
//- (void)test_08_cancel_prefetch_URLs {
//    XCTestExpectation *expectation = [self expectationWithDescription:@"Manager cancel prefetch urls"];
//
//    NSURL *jpgURL = [NSURL URLWithString:kTestJpegURL];
//    NSURL *pngURL = [NSURL URLWithString:kTestPNGURL];
//    NSArray *imageURLs = @[jpgURL, pngURL];
//
//    [[SDInterface sharedInterface] clearMemory];
//    [[SDInterface sharedInterface] clearDiskOnCompletion:^{
//        [[SDInterface sharedInterface] prefetchURLs:imageURLs
//                                               progress:^(NSUInteger noOfFinishedUrls, NSUInteger noOfTotalUrls) {
//                                                   XCTFail(@"something is wrong");
//                                               } completed:^(NSUInteger noOfFinishedUrls, NSUInteger noOfSkippedUrls) {
//                                                   XCTFail(@"something is wrong");
//                                               }];
//        [[SDInterface sharedInterface] cancelPrefetching];
//
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
//            UIImage *jpgImage = [[SDInterface sharedInterface] imageFromCacheForKey:[[SDInterface sharedInterface] cacheKeyForURL:jpgURL]];
//            XCTAssertNil(jpgImage);
//            UIImage *pngImage = [[SDInterface sharedInterface] imageFromCacheForKey:[[SDInterface sharedInterface] cacheKeyForURL:pngURL]];
//            XCTAssertNil(pngImage);
//            [expectation fulfill];
//        });
//    }];
//
//    [self waitForExpectationsWithCommonTimeout];
//}


#pragma mark  ------------- Cache -------------

- (void)test_09_store_image_disk_YES {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Manager store image disk YES"];
    
    NSString *testJPEGImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *testJPEGImage = [UIImage imageWithContentsOfFile:testJPEGImagePath];
    XCTAssertNotNil(testJPEGImage);
    
    NSString *key = @"testJPEGImageYES";
    
    [[SDInterface sharedInterface] clearMemory];
    [[SDInterface sharedInterface] clearDiskOnCompletion:^{
        XCTAssertNil([[SDInterface sharedInterface] imageFromMemoryCacheForKey:key]);
        XCTAssertNil([[SDInterface sharedInterface] imageFromDiskCacheForKey:key]);
        
        [[SDInterface sharedInterface] storeImage:testJPEGImage forKey:key toDisk:YES completion:^{
            XCTAssertNotNil([[SDInterface sharedInterface] imageFromMemoryCacheForKey:key]);
            XCTAssertNotNil([[SDInterface sharedInterface] imageFromDiskCacheForKey:key]);
            
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_10_store_image_disk_NO {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Manager store image disk NO"];
    
    NSString *testJPEGImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *testJPEGImage = [UIImage imageWithContentsOfFile:testJPEGImagePath];
    XCTAssertNotNil(testJPEGImage);
    
    NSString *key = @"testJPEGImageNO";
    
    [[SDInterface sharedInterface] clearMemory];
    [[SDInterface sharedInterface] clearDiskOnCompletion:^{
        XCTAssertNil([[SDInterface sharedInterface] imageFromMemoryCacheForKey:key]);
        XCTAssertNil([[SDInterface sharedInterface] imageFromDiskCacheForKey:key]);
        
        [[SDInterface sharedInterface] storeImage:testJPEGImage forKey:key toDisk:NO completion:^{
            XCTAssertNotNil([[SDInterface sharedInterface] imageFromMemoryCacheForKey:key]);
            XCTAssertNil([[SDInterface sharedInterface] imageFromDiskCacheForKey:key]);
            
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_11_store_image_imageData_disk_YES {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Manager store image_imageData disk YES"];
    
    NSString *testJPEGImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *testJPEGImage = [UIImage imageWithContentsOfFile:testJPEGImagePath];
    NSData *data = UIImageJPEGRepresentation(testJPEGImage, 0.5);
    XCTAssertNotNil(data);
    
    NSString *key = @"testJPEGImageDataYES";
   
    [[SDInterface sharedInterface] clearMemory];
    [[SDInterface sharedInterface] clearDiskOnCompletion:^{
        XCTAssertNil([[SDInterface sharedInterface] imageFromMemoryCacheForKey:key]);
        XCTAssertNil([[SDInterface sharedInterface] imageFromDiskCacheForKey:key]);
        [[SDInterface sharedInterface] storeImage:testJPEGImage
                                            imageData:data
                                               forKey:key
                                               toDisk:YES
                                           completion:^{
                                               XCTAssertNotNil([[SDInterface sharedInterface] imageFromMemoryCacheForKey:key]);
                                               XCTAssertNotNil([[SDInterface sharedInterface] imageFromDiskCacheForKey:key]);
                                               
                                               NSString *cachePath = [[SDInterface sharedInterface] defaultCachePathForKey:key];
                                               NSData *newData = [NSData dataWithContentsOfFile:cachePath];
                                               XCTAssertEqual(newData.length, data.length);
                                               [expectation fulfill];
                                           }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_12_store_image_imageData_disk_NO {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Manager store image_imageData disk NO"];
    
    NSString *testJPEGImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *testJPEGImage = [UIImage imageWithContentsOfFile:testJPEGImagePath];
    NSData *data = UIImageJPEGRepresentation(testJPEGImage, 0.5);
    XCTAssertNotNil(data);
    
    NSString *key = @"testJPEGImageDataYES";
    
    [[SDInterface sharedInterface] clearMemory];
    [[SDInterface sharedInterface] clearDiskOnCompletion:^{
        XCTAssertNil([[SDInterface sharedInterface] imageFromMemoryCacheForKey:key]);
        XCTAssertNil([[SDInterface sharedInterface] imageFromDiskCacheForKey:key]);
        [[SDInterface sharedInterface] storeImage:testJPEGImage
                                            imageData:data
                                               forKey:key
                                               toDisk:NO
                                           completion:^{
                                               XCTAssertNotNil([[SDInterface sharedInterface] imageFromMemoryCacheForKey:key]);
                                               XCTAssertNil([[SDInterface sharedInterface] imageFromDiskCacheForKey:key]);
                                               
                                               NSString *cachePath = [[SDInterface sharedInterface] defaultCachePathForKey:key];
                                               XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:cachePath]);
                                               [expectation fulfill];
                                           }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_13_store_imageData_disk {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Manager store imageData disk"];
    
    NSString *testJPEGImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *testJPEGImage = [UIImage imageWithContentsOfFile:testJPEGImagePath];
    NSData *data = UIImageJPEGRepresentation(testJPEGImage, 0.5);
    XCTAssertNotNil(data);
    
    NSString *key = @"testJPEGImageDataYES";
    
    [[SDInterface sharedInterface] clearDiskOnCompletion:^{
        XCTAssertNil([[SDInterface sharedInterface] imageFromDiskCacheForKey:key]);
        [[SDInterface sharedInterface] storeImageDataToDisk:data forKey:key];
        XCTAssertNotNil([[SDInterface sharedInterface] imageFromDiskCacheForKey:key]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_14_sava_image_to_cache {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Manager save image to cache"];
    
    NSString *testJPEGImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *testJPEGImage = [UIImage imageWithContentsOfFile:testJPEGImagePath];
    
    NSURL *url = [NSURL URLWithString:@"https://www.toutiao.com"];
    [[SDInterface sharedInterface] clearMemory];
    [[SDInterface sharedInterface] clearDiskOnCompletion:^{
        [[SDInterface sharedInterface] saveImageToCache:testJPEGImage forURL:url];
        NSString *key = [[SDInterface sharedInterface] cacheKeyForURL:url];
        // 异步保存
        XCTAssertNil([[SDInterface sharedInterface] imageFromCacheForKey:key]);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_15_disk_exist {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Manager disk if exist"];
    
    NSString *testJPEGImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *testJPEGImage = [UIImage imageWithContentsOfFile:testJPEGImagePath];
    
    [[SDInterface sharedInterface] clearMemory];
    [[SDInterface sharedInterface] clearDiskOnCompletion:^{
        NSString *key = @"testJPEGImageDataYES";
        
        XCTAssertNil([[SDInterface sharedInterface] imageFromMemoryCacheForKey:key]);
        XCTAssertNil([[SDInterface sharedInterface] imageFromDiskCacheForKey:key]);
        [[SDInterface sharedInterface] storeImage:testJPEGImage
                                            imageData:nil
                                               forKey:key
                                               toDisk:YES
                                           completion:^{
                                               XCTAssertTrue([[SDInterface sharedInterface] diskImageExistsWithKey:key]);
                                               [[SDInterface sharedInterface] diskImageExistsWithKey:key completion:^(BOOL isInCache) {
                                                   XCTAssertTrue(isInCache);
                                                   [expectation fulfill];
                                               }];
                                           }];
    }];
    
    
    [self waitForExpectationsWithCommonTimeout];
}

@end
