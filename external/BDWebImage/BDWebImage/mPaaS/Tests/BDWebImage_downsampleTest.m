//
//  BDWebImage_downsampleTest.m
//  BDWebImage_Tests
//
//  Created by 陈奕 on 2020/3/16.
//  Copyright © 2020 Bytedance.com. All rights reserved.
//

#import "BaseTestCase.h"
#import <BDWebImage/BDWebImage.h>
#import <BDWebImage/BDWebImageRequest+Private.h>

@interface BDWebImage_downsampleTest : BaseTestCase

@end

@implementation BDWebImage_downsampleTest

- (void)setUp {
    [[BDWebImageManager sharedManager].imageCache.diskCache removeAllData];
    [[BDWebImageManager sharedManager].imageCache.memoryCache removeAllObjects];
    [super setUp];
}

- (void)tearDown {
    
}

- (void)test_01_jpg_downsample {
    XCTestExpectation *expectation = [self expectationWithDescription:@"correct download"];
    NSURL *imageURL = [NSURL URLWithString:kTestJpegURL];
    
    [self removeImageCache:imageURL];
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
    imgView.bd_isOpenDownsample = YES;
    [imgView bd_setImageWithURL:imageURL placeholder:nil options:0 completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        CGFloat height = imgView.bounds.size.height * UIScreen.mainScreen.scale;
        CGFloat width = imgView.bounds.size.width * UIScreen.mainScreen.scale;
        XCTAssertTrue(image.size.height >= height && image.size.width >= width);
        XCTAssertTrue(((BDImage *)image).hasDownsampled);
        XCTAssertTrue(BDImageDetectType((__bridge CFDataRef)data) == BDImageCodeTypeJPEG);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_02_jpg_no_downsample {
    XCTestExpectation *expectation = [self expectationWithDescription:@"correct download"];
    NSURL *imageURL = [NSURL URLWithString:kTestJpegURL];
    
    [self removeImageCache:imageURL];
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    imgView.bd_isOpenDownsample = YES;
    [imgView bd_setImageWithURL:imageURL placeholder:nil options:0 completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        CGFloat height = imgView.bounds.size.height * UIScreen.mainScreen.scale;
        CGFloat width = imgView.bounds.size.width * UIScreen.mainScreen.scale;
        XCTAssertTrue(image.size.height != height && image.size.width != width);
        XCTAssertFalse(((BDImage *)image).hasDownsampled);
        XCTAssertTrue(BDImageDetectType((__bridge CFDataRef)data) == BDImageCodeTypeJPEG);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_03_png_downsample {
    XCTestExpectation *expectation = [self expectationWithDescription:@"correct download"];
    NSURL *imageURL = [NSURL URLWithString:kTestPNGURL];
    
    [self removeImageCache:imageURL];
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
    imgView.bd_isOpenDownsample = YES;
    [imgView bd_setImageWithURL:imageURL placeholder:nil options:0 completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        CGFloat height = imgView.bounds.size.height * UIScreen.mainScreen.scale;
        CGFloat width = imgView.bounds.size.width * UIScreen.mainScreen.scale;
        XCTAssertTrue(image.size.height >= height && image.size.width >= width);
        XCTAssertTrue(((BDImage *)image).hasDownsampled);
        XCTAssertTrue(BDImageDetectType((__bridge CFDataRef)data) == BDImageCodeTypePNG);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_04_png_no_downsample {
    XCTestExpectation *expectation = [self expectationWithDescription:@"correct download"];
    NSURL *imageURL = [NSURL URLWithString:kTestPNGURL];
    
    [self removeImageCache:imageURL];
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    imgView.bd_isOpenDownsample = YES;
    [imgView bd_setImageWithURL:imageURL placeholder:nil options:0 completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        CGFloat height = imgView.bounds.size.height * UIScreen.mainScreen.scale;
        CGFloat width = imgView.bounds.size.width * UIScreen.mainScreen.scale;
        XCTAssertTrue(image.size.height != height && image.size.width != width);
        XCTAssertFalse(((BDImage *)image).hasDownsampled);
        XCTAssertTrue(BDImageDetectType((__bridge CFDataRef)data) == BDImageCodeTypePNG);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_05_awebp_no_downsample {
    XCTestExpectation *expectation = [self expectationWithDescription:@"correct download"];
    NSURL *imageURL = [NSURL URLWithString:kTestWebPURL];
    
    [self removeImageCache:imageURL];
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
    imgView.bd_isOpenDownsample = NO;
    [imgView bd_setImageWithURL:imageURL placeholder:nil options:0 completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        CGFloat height = imgView.bounds.size.height;
        CGFloat width = imgView.bounds.size.width;
        XCTAssertTrue(image.size.height != height && image.size.width != width);
        XCTAssertFalse(((BDImage *)image).hasDownsampled);
        XCTAssertTrue(BDImageDetectType((__bridge CFDataRef)data) == BDImageCodeTypeWebP);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_06_webp_downsample {
    XCTestExpectation *expectation = [self expectationWithDescription:@"correct download"];
    NSURL *imageURL = [NSURL URLWithString:kTestWebPStaticURL];
    
    [self removeImageCache:imageURL];
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
    imgView.bd_isOpenDownsample = YES;
    [imgView bd_setImageWithURL:imageURL placeholder:nil options:0 completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        CGFloat height = imgView.bounds.size.height * UIScreen.mainScreen.scale;
        CGFloat width = imgView.bounds.size.width * UIScreen.mainScreen.scale;
        XCTAssertTrue(image.size.height >= height && image.size.width >= width);
        XCTAssertTrue(((BDImage *)image).hasDownsampled);
        XCTAssertTrue(BDImageDetectType((__bridge CFDataRef)data) == BDImageCodeTypeWebP);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_07_gif_no_downsample {
    XCTestExpectation *expectation = [self expectationWithDescription:@"correct download"];
    NSURL *imageURL = [NSURL URLWithString:kTestGIFURL];
    
    [self removeImageCache:imageURL];
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
    imgView.bd_isOpenDownsample = NO;
    [imgView bd_setImageWithURL:imageURL placeholder:nil options:0 completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        CGFloat height = imgView.bounds.size.height;
        CGFloat width = imgView.bounds.size.width;
        XCTAssertTrue(image.size.height != height && image.size.width != width);
        XCTAssertFalse(((BDImage *)image).hasDownsampled);
        XCTAssertTrue(BDImageDetectType((__bridge CFDataRef)data) == BDImageCodeTypeGIF);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_08_downsample_cache {
    XCTestExpectation *expectation = [self expectationWithDescription:@"correct download"];
    __block NSURL *imageURL = [NSURL URLWithString:kTestWebPStaticURL];
    
    [self removeImageCache:imageURL];
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
    imgView.bd_isOpenDownsample = YES;
    [imgView bd_setImageWithURL:imageURL placeholder:nil options:0 completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        BDImageCacheType type = BDImageCacheTypeMemory;
        XCTAssertNotNil([[BDImageCache sharedImageCache] imageFromMemoryCacheForKey:request.originalKey.targetkey]);
        XCTAssertNotNil([[BDImageCache sharedImageCache] imageForKey:kTestWebPStaticURL withType:&type options:0 size:CGSizeMake(5, 5)]);
        [imgView bd_setImageWithURL:imageURL placeholder:nil options:0 completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            XCTAssertNotNil(image);
            XCTAssertTrue(from == BDWebImageResultFromMemoryCache);
        }];
        [[BDWebImageManager sharedManager] requestImage:imageURL options:0 complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            XCTAssertTrue(image.size.height == 368 && image.size.width == 550);
            XCTAssertFalse(((BDImage *)image).hasDownsampled);
            XCTAssertTrue(from == BDWebImageResultFromDiskCache);
            UIImage *img = [[BDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestWebPStaticURL];
            XCTAssertNotNil(img);
            XCTAssertTrue(img.size.height == 368 && img.size.width == 550);
            
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_downsample_switch {
    XCTestExpectation *expectation = [self expectationWithDescription:@"correct download"];
    NSURL *imageURL = [NSURL URLWithString:kTestWebPStaticURL];

    [self removeImageCache:imageURL];
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
    [imgView bd_setImageWithURL:imageURL placeholder:nil options:0 completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        CGFloat height = imgView.bounds.size.height * UIScreen.mainScreen.scale;
        CGFloat width = imgView.bounds.size.width * UIScreen.mainScreen.scale;
        XCTAssertTrue(image.size.height != height && image.size.width != width);
        XCTAssertFalse(((BDImage *)image).hasDownsampled);
        XCTAssertTrue(BDImageDetectType((__bridge CFDataRef)data) == BDImageCodeTypeWebP);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_downsample_options {
    XCTestExpectation *expectation = [self expectationWithDescription:@"correct download"];
    NSURL *imageURL = [NSURL URLWithString:kTestWebPStaticURL];

    [self removeImageCache:imageURL];
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
    imgView.bd_isOpenDownsample = YES;
    [imgView bd_setImageWithURL:imageURL placeholder:nil options:BDImageNotDownsample completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        CGFloat height = imgView.bounds.size.height * UIScreen.mainScreen.scale;
        CGFloat width = imgView.bounds.size.width * UIScreen.mainScreen.scale;
        XCTAssertTrue(image.size.height != height && image.size.width != width);
        XCTAssertFalse(((BDImage *)image).hasDownsampled);
        XCTAssertTrue(BDImageDetectType((__bridge CFDataRef)data) == BDImageCodeTypeWebP);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_global_downsample_size {
    XCTestExpectation *expectation = [self expectationWithDescription:@"global downsample size"];
    NSURL *imageURL = [NSURL URLWithString:kTestWebPStaticURL];

    [self removeImageCache:imageURL];
    UIImageView *imgView = [[UIImageView alloc] init];
    [BDWebImageManager sharedManager].enableAllImageDownsample = YES;
    [BDWebImageManager sharedManager].allImageDownsampleSize = CGSizeMake(6, 6);
    [imgView bd_setImageWithURL:imageURL
                    placeholder:nil
                        options:0
                     completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        CGFloat height = [BDWebImageManager sharedManager].allImageDownsampleSize.height * UIScreen.mainScreen.scale;
        CGFloat width = [BDWebImageManager sharedManager].allImageDownsampleSize.width * UIScreen.mainScreen.scale;
        XCTAssertTrue(image.size.height >= height && image.size.width >= width);
        XCTAssertTrue(((BDImage *)image).hasDownsampled);
        XCTAssertTrue(BDImageDetectType((__bridge CFDataRef)data) == BDImageCodeTypeWebP);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}


@end
