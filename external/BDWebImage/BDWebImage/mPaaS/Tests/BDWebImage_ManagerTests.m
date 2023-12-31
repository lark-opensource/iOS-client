//
//  BDWebImage_ManagerTests.m
//  BDWebImageTestTests
//
//  Created by zhangtianfu on 2018/12/18.
//  Copyright © 2018 zhangtianfu. All rights reserved.
//

#import "BaseTestCase.h"
#import <BDWebImage/BDWebImage.h>
#import <BDWebImage/BDWebImageRequest.h>
#import <YYImage/YYImageCoder.h>

@interface BDWebImage_ManagerTests : BaseTestCase

@end

@implementation BDWebImage_ManagerTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [[BDWebImageManager sharedManager].imageCache.diskCache removeAllData];
    [[BDWebImageManager sharedManager].imageCache.memoryCache removeAllObjects];
    
    [super setUp];
}

- (void)test_01_instance {
    BDWebImageManager *manager = [[BDWebImageManager alloc] init];
    XCTAssertNotEqual(manager, [BDWebImageManager sharedManager]);
}

- (void)test_02_success_download {
    XCTestExpectation *expectation = [self expectationWithDescription:@"correct download"];
    NSURL *imageURL = [NSURL URLWithString:kTestJpegURL];
    
    [self removeImageCache:imageURL];
    
    [[BDWebImageManager sharedManager] requestImage:imageURL options:0 complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNotNil(image);
        XCTAssertNotNil(data);
        XCTAssertNil(error);
        XCTAssertEqual(from, BDWebImageResultFromDownloading);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_03_fail_download {
    XCTestExpectation *expectation = [self expectationWithDescription:@"error download"];
    NSURL *imageURL =  [NSURL URLWithString:@"http://static2.dmcdn.net/static/video/656/177/44771656:jpeg_preview_small.png"];
    
    [self removeImageCache:imageURL];
    
    [[BDWebImageManager sharedManager] requestImage:imageURL options:0 complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNil(image);
        XCTAssertNil(data);
        XCTAssertNotNil(error);
        XCTAssertEqual(from, BDWebImageResultFromNone);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_04_webp_encode {
    XCTestExpectation *expectation = [self expectationWithDescription:@"correct download"];
    NSURL *imageURL = [NSURL URLWithString:kTestLargeWebPURL];
    
    [self removeImageCache:imageURL];
    
    [[BDWebImageManager sharedManager] requestImage:imageURL options:0 complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNotNil(image);
        XCTAssertNotNil(data);
        XCTAssertNil(error);
        XCTAssertEqual(from, BDWebImageResultFromDownloading);
        NSData *encodeData = [image bd_encodeWithImageType:BDImageCodeTypeWebP];
        NSData *encodeData2 = [image bd_encodeWithImageTypeAndQuality:BDImageCodeTypeWebP qualityFactor:100];
        YYImageEncoder *encoder = [[YYImageEncoder alloc] initWithType:YYImageTypeWebP];
        [encoder addImage:image duration:0];
        NSData *encodeData1 = [encoder encode];
        XCTAssertEqual(BDImageDetectType((__bridge CFDataRef)encodeData), BDImageDetectType((__bridge CFDataRef)data));
//        XCTAssertEqual(encodeData.length, data.length);// webp 可能编码后大小不一致
        XCTAssertEqual(encodeData.length, encodeData1.length);
        XCTAssertLessThan(encodeData.length, encodeData2.length);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_05_jepg_encode {
    XCTestExpectation *expectation = [self expectationWithDescription:@"correct download"];
    NSURL *imageURL = [NSURL URLWithString:kTestLargeImgURL];
    
    [self removeImageCache:imageURL];
    
    [[BDWebImageManager sharedManager] requestImage:imageURL options:0 complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNotNil(image);
        XCTAssertNotNil(data);
        XCTAssertNil(error);
        XCTAssertEqual(from, BDWebImageResultFromDownloading);
        NSData *encodeData = [image bd_encodeWithImageType:BDImageCodeTypeJPEG];
        XCTAssertEqual(BDImageDetectType((__bridge CFDataRef)encodeData), BDImageDetectType((__bridge CFDataRef)data));
//        XCTAssertEqual(encodeData.length, data.length);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_06_cancel_in_multi_threads {
    NSInteger testSize = 4000;
    NSMutableArray<NSString *> *arr = [NSMutableArray arrayWithCapacity:testSize];
    for (int i=1; i<=testSize; i++) {//http://qzonestyle.gtimg.cn/qzone/app/weishi/client/testimage/1024/4799.jpg
        NSString *imageURL = [NSString stringWithFormat:@"%@/%ld.jpg", @"http://qzonestyle.gtimg.cn/qzone/app/weishi/client/testimage/1024", (long)i];
        [arr addObject:imageURL];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i=0; i<testSize; i++) {
            NSURL *url = [NSURL URLWithString:arr[i]];
            for (int j=0; j<3; j++) {
//                dispatch_async(dispatch_get_main_queue(), ^{
                    [[BDWebImageManager sharedManager] requestImage:url options:0 complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {}];
//                });
            }
            [NSThread sleepForTimeInterval:0.0000001];
        }
    });
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i=0; i<500; i++) {
            [[BDWebImageManager sharedManager] cancelAll];
            [NSThread sleepForTimeInterval:0.0000001];
        }
//    });
    sleep(5);
}

- (void)test_07_queryCache {
    XCTestExpectation *expectation = [self expectationWithDescription:@"correct download"];
    NSURL *imageURL = [NSURL URLWithString:kTestLargeImgURL];
    
    [self removeImageCache:imageURL];
    
    [[BDWebImageManager sharedManager] requestImage:imageURL options:0 complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertTrue([[BDImageCache sharedImageCache].memoryCache containsObjectForKey:kTestLargeImgURL]);
        XCTAssertTrue([[BDImageCache sharedImageCache].diskCache containsDataForKey:kTestLargeImgURL]);
        XCTAssertNotNil(image);
        XCTAssertNotNil(data);
        XCTAssertNil(error);
        XCTAssertEqual(from, BDWebImageResultFromDownloading);
        [[BDWebImageManager sharedManager] requestImage:imageURL options:BDImageRequestNeedCachePath complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            XCTAssertNotNil(image);
            XCTAssertNotNil(data);
            XCTAssertEqual(from, BDWebImageResultFromDiskCache);
        }];
        [[BDWebImageManager sharedManager] requestImage:imageURL options:BDImageRequestNeedCachePath|BDImageRequestIgnoreImage complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            XCTAssertNil(image);
            XCTAssertNotNil(data);
            XCTAssertEqual(from, BDWebImageResultFromDiskCache);
        }];
        [[BDWebImageManager sharedManager] requestImage:imageURL options:BDImageRequestNeedCachePath|BDImageRequestIgnoreMemoryCache complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            XCTAssertNotNil(image);
            XCTAssertNotNil(data);
            XCTAssertEqual(from, BDWebImageResultFromDiskCache);
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

@end

