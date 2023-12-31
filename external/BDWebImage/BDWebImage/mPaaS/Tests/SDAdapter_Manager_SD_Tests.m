//
//  SDAdapter_Manager_SD_Tests.m
//  BDWebImageTestTests
//
//  Created by zhangtianfu on 2018/12/21.
//  Copyright © 2018 zhangtianfu. All rights reserved.
//

#import "BaseTestCase.h"
#import <BDWebImage/BDWebImage.h>
#import <BDWebImage/SDWebImageAdapter.h>

@interface SDAdapter_Manager_SD_Tests : BaseTestCase

@end

@implementation SDAdapter_Manager_SD_Tests

- (void)setUp {
    [SDWebImageAdapter setUseBDWebImage:NO];
    [[SDWebImageManager sharedManager].imageCache clearMemory];
    [[SDWebImageManager sharedManager].imageCache clearDiskOnCompletion:^{
    }];
    sleep(0.3);
    
    [super setUp];
}

- (void)test_01_useBDWebImage {
    [SDWebImageAdapter setUseBDWebImage:YES];
    XCTAssertTrue([SDWebImageAdapter useBDWebImage]);
    
    [SDWebImageAdapter setUseBDWebImage:NO];
    XCTAssertFalse([SDWebImageAdapter useBDWebImage]);
}

#pragma mark  ------------- Manager -------------

- (void)test_02_load_image {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Manager load iamge"];

    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];

    [[SDWebImageAdapter sharedAdapter] loadImageWithURL:originalImageURL
                                                options:0
                                               progress:nil
                                              completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
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

    [[SDWebImageAdapter sharedAdapter] clearMemory];
    
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    [[SDWebImageAdapter sharedAdapter] loadImageWithURL:originalImageURL
                                                options:0
                                               progress:nil
                                              completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                                                  XCTFail(@"something is wrong");
                                              }];
    [[SDWebImageAdapter sharedAdapter] cancelAll];
                               
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithCommonTimeout];
}


#pragma mark  ------------- Downloader -------------

- (void)test_04_download_image {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Manager cancel download iamge"];
    
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    
    [[SDWebImageAdapter sharedAdapter] clearMemory];
    [[SDWebImageAdapter sharedAdapter] clearDiskOnCompletion:^{
        [[SDWebImageAdapter sharedAdapter] downloadImageWithURL:originalImageURL
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
    
    [[SDWebImageAdapter sharedAdapter] clearMemory];
    [[SDWebImageAdapter sharedAdapter] clearDiskOnCompletion:^{
        id token = [[SDWebImageAdapter sharedAdapter] downloadImageWithURL:originalImageURL
                                                        options:0
                                                       progress:nil
                                                      completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
                                                          XCTFail(@"something is wrong");
                                                      }];
        XCTAssertNotNil(token);
        [[SDWebImageAdapter sharedAdapter] cancel:token];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
            UIImage *image = [[SDWebImageAdapter sharedAdapter] imageFromCacheForKey:[[SDWebImageAdapter sharedAdapter] cacheKeyForURL:originalImageURL]];
            XCTAssertNil(image);
            [expectation fulfill];
        });
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_06_cancel_all_download_image {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Manager canel all download iamge"];
    
    NSURL *jpgURL = [NSURL URLWithString:kTestJpegURL];
    NSURL *pngURL = [NSURL URLWithString:kTestPNGURL];
    [[SDWebImageAdapter sharedAdapter] downloadImageWithURL:jpgURL
                                                    options:0
                                                   progress:nil
                                                  completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
                                                      XCTFail(@"something is wrong");
                                                  }];
    [[SDWebImageAdapter sharedAdapter] downloadImageWithURL:pngURL
                                                    options:0
                                                   progress:nil
                                                  completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
                                                      XCTFail(@"something is wrong");
                                                  }];
    [[SDWebImageAdapter sharedAdapter] cancelAllDownloads];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
        UIImage *jpgImage = [[SDWebImageAdapter sharedAdapter] imageFromCacheForKey:[[SDWebImageAdapter sharedAdapter] cacheKeyForURL:jpgURL]];
        XCTAssertNil(jpgImage);
        UIImage *pngImage = [[SDWebImageAdapter sharedAdapter] imageFromCacheForKey:[[SDWebImageAdapter sharedAdapter] cacheKeyForURL:pngURL]];
        XCTAssertNil(pngImage);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithCommonTimeout];
}

#pragma mark  ------------- Prefetcher -------------

- (void)test_07_prefetch_URLs {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Manager prefetch urls"];
    
    NSURL *jpgURL = [NSURL URLWithString:kTestJpegURL];
    NSURL *pngURL = [NSURL URLWithString:kTestPNGURL];
    NSArray *imageURLs = @[jpgURL, pngURL];
    
    __block NSUInteger numberOfPrefetched = 0;
    
    [[SDWebImageAdapter sharedAdapter] clearDiskOnCompletion:^{
        [[SDWebImageAdapter sharedAdapter] prefetchURLs:imageURLs
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

- (void)test_08_cancel_prefetch_URLs {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Manager cancel prefetch urls"];
    
    NSURL *jpgURL = [NSURL URLWithString:kTestJpegURL];
    NSURL *pngURL = [NSURL URLWithString:kTestPNGURL];
    NSArray *imageURLs = @[jpgURL, pngURL];
    
    [[SDWebImageAdapter sharedAdapter] clearMemory];
    [[SDWebImageAdapter sharedAdapter] clearDiskOnCompletion:^{
        [[SDWebImageAdapter sharedAdapter] prefetchURLs:imageURLs
                                               progress:^(NSUInteger noOfFinishedUrls, NSUInteger noOfTotalUrls) {
                                                   XCTFail(@"something is wrong");
                                               } completed:^(NSUInteger noOfFinishedUrls, NSUInteger noOfSkippedUrls) {
                                                   XCTFail(@"something is wrong");
                                               }];
        [[SDWebImageAdapter sharedAdapter] cancelPrefetching];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
            UIImage *jpgImage = [[SDWebImageAdapter sharedAdapter] imageFromCacheForKey:[[SDWebImageAdapter sharedAdapter] cacheKeyForURL:jpgURL]];
            XCTAssertNil(jpgImage);
            UIImage *pngImage = [[SDWebImageAdapter sharedAdapter] imageFromCacheForKey:[[SDWebImageAdapter sharedAdapter] cacheKeyForURL:pngURL]];
            XCTAssertNil(pngImage);
            [expectation fulfill];
        });
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}


#pragma mark  ------------- Cache -------------

- (void)test_09_store_image_disk_YES {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Manager store image disk YES"];
    
    NSString *testJPEGImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *testJPEGImage = [UIImage imageWithContentsOfFile:testJPEGImagePath];
    XCTAssertNotNil(testJPEGImage);
    
    NSString *key = @"testJPEGImageYES";
    
    [[SDWebImageAdapter sharedAdapter] clearMemory];
    [[SDWebImageAdapter sharedAdapter] clearDiskOnCompletion:^{
        XCTAssertNil([[SDWebImageAdapter sharedAdapter] imageFromMemoryCacheForKey:key]);
        XCTAssertNil([[SDWebImageAdapter sharedAdapter] imageFromDiskCacheForKey:key]);
        
        [[SDWebImageAdapter sharedAdapter] storeImage:testJPEGImage forKey:key toDisk:YES completion:^{
            XCTAssertNotNil([[SDWebImageAdapter sharedAdapter] imageFromMemoryCacheForKey:key]);
            XCTAssertNotNil([[SDWebImageAdapter sharedAdapter] imageFromDiskCacheForKey:key]);
            
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
    
    [[SDWebImageAdapter sharedAdapter] clearMemory];
    [[SDWebImageAdapter sharedAdapter] clearDiskOnCompletion:^{
        XCTAssertNil([[SDWebImageAdapter sharedAdapter] imageFromMemoryCacheForKey:key]);
        XCTAssertNil([[SDWebImageAdapter sharedAdapter] imageFromDiskCacheForKey:key]);
        
        [[SDWebImageAdapter sharedAdapter] storeImage:testJPEGImage forKey:key toDisk:NO completion:^{
            XCTAssertNotNil([[SDWebImageAdapter sharedAdapter] imageFromMemoryCacheForKey:key]);
            XCTAssertNil([[SDWebImageAdapter sharedAdapter] imageFromDiskCacheForKey:key]);
            
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
   
    [[SDWebImageAdapter sharedAdapter] clearMemory];
    [[SDWebImageAdapter sharedAdapter] clearDiskOnCompletion:^{
        XCTAssertNil([[SDWebImageAdapter sharedAdapter] imageFromMemoryCacheForKey:key]);
        XCTAssertNil([[SDWebImageAdapter sharedAdapter] imageFromDiskCacheForKey:key]);
        [[SDWebImageAdapter sharedAdapter] storeImage:testJPEGImage
                                            imageData:data
                                               forKey:key
                                               toDisk:YES
                                           completion:^{
                                               XCTAssertNotNil([[SDWebImageAdapter sharedAdapter] imageFromMemoryCacheForKey:key]);
                                               XCTAssertNotNil([[SDWebImageAdapter sharedAdapter] imageFromDiskCacheForKey:key]);
                                               
                                               NSString *cachePath = [[SDWebImageAdapter sharedAdapter] defaultCachePathForKey:key];
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
    
    [[SDWebImageAdapter sharedAdapter] clearMemory];
    [[SDWebImageAdapter sharedAdapter] clearDiskOnCompletion:^{
        XCTAssertNil([[SDWebImageAdapter sharedAdapter] imageFromMemoryCacheForKey:key]);
        XCTAssertNil([[SDWebImageAdapter sharedAdapter] imageFromDiskCacheForKey:key]);
        [[SDWebImageAdapter sharedAdapter] storeImage:testJPEGImage
                                            imageData:data
                                               forKey:key
                                               toDisk:NO
                                           completion:^{
                                               XCTAssertNotNil([[SDWebImageAdapter sharedAdapter] imageFromMemoryCacheForKey:key]);
                                               XCTAssertNil([[SDWebImageAdapter sharedAdapter] imageFromDiskCacheForKey:key]);
                                               
                                               NSString *cachePath = [[SDWebImageAdapter sharedAdapter] defaultCachePathForKey:key];
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
    
    [[SDWebImageAdapter sharedAdapter] clearDiskOnCompletion:^{
        XCTAssertNil([[SDWebImageAdapter sharedAdapter] imageFromDiskCacheForKey:key]);
        [[SDWebImageAdapter sharedAdapter] storeImageDataToDisk:data forKey:key];
        XCTAssertNotNil([[SDWebImageAdapter sharedAdapter] imageFromDiskCacheForKey:key]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_14_sava_image_to_cache {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Manager save image to cache"];
    
    NSString *testJPEGImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *testJPEGImage = [UIImage imageWithContentsOfFile:testJPEGImagePath];
    
    NSURL *url = [NSURL URLWithString:@"https://www.toutiao.com"];
    [[SDWebImageAdapter sharedAdapter] clearMemory];
    [[SDWebImageAdapter sharedAdapter] clearDiskOnCompletion:^{
        [[SDWebImageAdapter sharedAdapter] saveImageToCache:testJPEGImage forURL:url];
        NSString *key = [[SDWebImageAdapter sharedAdapter] cacheKeyForURL:url];
        XCTAssertNotNil([[SDWebImageAdapter sharedAdapter] imageFromCacheForKey:key]);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_15_disk_exist {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Manager disk if exist"];
    
    NSString *testJPEGImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *testJPEGImage = [UIImage imageWithContentsOfFile:testJPEGImagePath];
    
    NSString *key = @"testJPEGImageDataYES";
    
    XCTAssertNil([[SDWebImageAdapter sharedAdapter] imageFromMemoryCacheForKey:key]);
    XCTAssertNil([[SDWebImageAdapter sharedAdapter] imageFromDiskCacheForKey:key]);
    [[SDWebImageAdapter sharedAdapter] storeImage:testJPEGImage
                                        imageData:nil
                                           forKey:key
                                           toDisk:YES
                                       completion:^{
                                           XCTAssertTrue([[SDWebImageAdapter sharedAdapter] diskImageExistsWithKey:key]);
                                           [[SDWebImageAdapter sharedAdapter] diskImageExistsWithKey:key completion:^(BOOL isInCache) {
                                               XCTAssertTrue(isInCache);
                                               [expectation fulfill];
                                           }];
                                       }];
    [self waitForExpectationsWithCommonTimeout];
}

@end
