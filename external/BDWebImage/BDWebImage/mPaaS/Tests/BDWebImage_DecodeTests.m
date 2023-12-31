//
//  BDWebImage_DecodeTests.m
//  BDWebImageTestTests
//
//  Created by zhangtianfu on 2018/12/17.
//  Copyright © 2018 zhangtianfu. All rights reserved.
//

#import "BaseTestCase.h"
#import <BDWebImage/BDWebImage.h>
#import <BDWebImageUtil.h>

@interface BDWebImage_DecodeTests : BaseTestCase

@end

@implementation BDWebImage_DecodeTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [[BDWebImageManager sharedManager].imageCache.diskCache removeAllData];
    [[BDWebImageManager sharedManager].imageCache.memoryCache removeAllObjects];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)test_01_DecodedImageWithNilImageReturnsNil {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness" // -Wno-nullability-completeness
    XCTAssertNil([BDImage imageNamed:nil]);
    XCTAssertNil([BDImage imageWithData:nil]);
    XCTAssertNil([BDImage imageWithContentsOfFile:nil]);
    XCTAssertNil([BDImage imageWithData:nil scale:0 decodeForDisplay:true error:nil]);
#pragma clang diagnostic pop

}

- (void)test_02_JPG {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:testImagePath];
    BDImage *decoderImage = [BDImage imageWithContentsOfFile:testImagePath];
    XCTAssertNotNil(image);
    XCTAssertNotNil(decoderImage);
    XCTAssertNotEqual(image, decoderImage);
    XCTAssertEqual(image.size.width * image.scale, decoderImage.size.width * decoderImage.scale);
    XCTAssertEqual(image.size.height * image.scale, decoderImage.size.height * decoderImage.scale);
    XCTAssertEqual(decoderImage.codeType, BDImageCodeTypeJPEG);
}

- (void)test_03_GIF {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"gif"];
    UIImage *image = [UIImage imageWithContentsOfFile:testImagePath];
    BDImage *animatedImage = [BDImage imageWithContentsOfFile:testImagePath];
    XCTAssertNotNil(image);
    XCTAssertNotNil(animatedImage);
    XCTAssertNotEqual(image, animatedImage);
    XCTAssertEqual(animatedImage.codeType, BDImageCodeTypeGIF);
    XCTAssertTrue(animatedImage.isAnimateImage);
}

- (void)test_04_PNG {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"png"];
    UIImage *image = [UIImage imageWithContentsOfFile:testImagePath];
    BDImage *decoderImage = [BDImage imageWithContentsOfFile:testImagePath];
    XCTAssertNotNil(image);
    XCTAssertNotNil(decoderImage);
    XCTAssertNotEqual(image, decoderImage);
    XCTAssertEqual(image.size.width * image.scale, decoderImage.size.width * decoderImage.scale);
    XCTAssertEqual(image.size.height * image.scale, decoderImage.size.height * decoderImage.scale);
    XCTAssertEqual(decoderImage.codeType, BDImageCodeTypePNG);
    
    /*
     * 测试decodeForDisplay为NO
     */
    NSData *data = [NSData dataWithContentsOfFile:testImagePath];
    BDImage *undecoderImage = [BDImage imageWithData:data scale:BDScaledFactorForKey(testImagePath) decodeForDisplay:NO error:nil];
    XCTAssertNotNil(undecoderImage);
    XCTAssertEqual(undecoderImage.codeType, BDImageCodeTypePNG);
}

- (void)test_05_MonochromeImage {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"MonochromeTestImage" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:testImagePath];
    BDImage *decoderImage = [BDImage imageWithContentsOfFile:testImagePath];
    XCTAssertNotNil(image);
    XCTAssertNotNil(decoderImage);
    XCTAssertNotEqual(image, decoderImage);
    XCTAssertEqual(image.size.width * image.scale, decoderImage.size.width * decoderImage.scale);
    XCTAssertEqual(image.size.height * image.scale, decoderImage.size.height * decoderImage.scale);
    XCTAssertEqual(decoderImage.codeType, BDImageCodeTypeJPEG);
}

- (void)test_06_DecodeAndScaleDownImage {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImageLarge" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:testImagePath];
    BDImage *decoderImage = [BDImage imageWithContentsOfFile:testImagePath];
    XCTAssertNotNil(image);
    XCTAssertNotNil(decoderImage);
    XCTAssertNotEqual(image, decoderImage);
    XCTAssertEqual(image.size.width * image.scale, decoderImage.size.width * decoderImage.scale);
    XCTAssertEqual(image.size.height * image.scale, decoderImage.size.height * decoderImage.scale);
    XCTAssertEqual(decoderImage.codeType, BDImageCodeTypeJPEG);
//    XCTAssertEqual(decoderImage.size.width * decoderImage.size.height, 60*1024*1024/4);
}

- (void)test_07_WEBP {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImageStatic" ofType:@"webp"];
    UIImage *image = [UIImage imageWithContentsOfFile:testImagePath];
    BDImage *decoderImage = [BDImage imageWithContentsOfFile:testImagePath];
    if (@available(iOS 14.0, *)) {
        XCTAssertNotNil(image);
    } else {
        XCTAssertNil(image);
    }
    XCTAssertNotNil(decoderImage);
    XCTAssertNotEqual(image, decoderImage);
    XCTAssertEqual(decoderImage.codeType, BDImageCodeTypeWebP);
    
    /*
     * 测试decodeForDisplay为NO
     */
    NSData *data = [NSData dataWithContentsOfFile:testImagePath];
    BDImage *undecoderImage = [BDImage imageWithData:data scale:BDScaledFactorForKey(testImagePath) decodeForDisplay:NO error:nil];
    XCTAssertNotNil(undecoderImage);
    XCTAssertEqual(undecoderImage.codeType, BDImageCodeTypeWebP);
}

- (void)test_08_WEBP_GIF {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImageAnimated" ofType:@"webp"];
    UIImage *image = [UIImage imageWithContentsOfFile:testImagePath];
    BDImage *decoderImage = [BDImage imageWithContentsOfFile:testImagePath];
    if (@available(iOS 14.0, *)) {
        XCTAssertNotNil(image);
    } else {
        XCTAssertNil(image);
    }
    XCTAssertNotNil(decoderImage);
    XCTAssertNotEqual(image, decoderImage);
    XCTAssertEqual(decoderImage.codeType, BDImageCodeTypeWebP);
}

- (void)test_09_scale_and_setScale {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    NSData *data = [NSData dataWithContentsOfFile:testImagePath];
    BDImage *decoderImage1 = [BDImage imageWithData:data scale:1];
    XCTAssertEqual(decoderImage1.scale, 1);
    
    BDImage *decoderImage2 = [BDImage imageWithData:data scale:2];
    XCTAssertEqual(decoderImage2.scale, 2);
    
    BDImage *decoderImage3 = [BDImage imageWithData:data scale:3];
    XCTAssertEqual(decoderImage3.scale, 3);
    
    BDImage *decoderImage4 = [BDImage imageWithData:data scale:0];
    XCTAssertEqual(decoderImage4.scale, 1);
    
    BDImage *decoderImage5 = [BDImage imageWithData:data];
    XCTAssertEqual(decoderImage5.scale, 1);
}

- (void)test_10_gifdata_to_image {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"gif"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    UIImage *image = [UIImage bd_imageWithData:data];
    
    BDImageRequestKey *requestKey = [[BDImageRequestKey alloc] initWithURL:path];
    UIImage *memoryImage = [[BDImageCache sharedImageCache] imageFromMemoryCacheForKey:requestKey.targetkey];
    
    XCTAssertNotNil(image);
    XCTAssertNil(memoryImage);
    
    XCTAssertLessThan(image.duration, 1); //this number is stable
    
    XCTAssertEqual(image.images.count, 5); //this number is stable
}

- (void)test_10_1_gifdata_to_image {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"gif"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    UIImage *image = [UIImage bd_imageWithData:data downsampleSize:CGSizeMake(10, 10)];
    
    BDImageRequestKey *requestKey = [[BDImageRequestKey alloc] initWithURL:path];
    UIImage *memoryImage = [[BDImageCache sharedImageCache] imageFromMemoryCacheForKey:requestKey.targetkey];
    
    XCTAssertNotNil(image);
    XCTAssertNil(memoryImage);
    
    XCTAssertLessThan(image.duration, 1); //this number is stable
    
    XCTAssertEqual(image.images.count, 5); //this number is stable
    
    XCTAssertEqual(image.size.height, 10 * UIScreen.mainScreen.scale);
    XCTAssertEqual(image.size.width, 10 * UIScreen.mainScreen.scale);
}

- (void)test_10_2_gifdata_to_image {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"gif"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    UIImage *image = [UIImage bd_imageWithData:data url:path isCache:YES downsampleSize:CGSizeMake(10, 10)];
    
    BDImageRequestKey *requestKey = [[BDImageRequestKey alloc] initWithURL:path downsampleSize:CGSizeMake(10, 10) cropRect:CGRectZero transfromName:@"" smartCrop:NO];
    UIImage *memoryImage = [[BDImageCache sharedImageCache] imageFromMemoryCacheForKey:requestKey.targetkey];
    
    XCTAssertNotNil(image);
    XCTAssertNotNil(memoryImage);
    
    XCTAssertLessThan(image.duration, 1); //this number is stable
    
    XCTAssertEqual(image.images.count, 5); //this number is stable
    
    XCTAssertEqual(image.size.height, 10 * UIScreen.mainScreen.scale);
    XCTAssertEqual(image.size.width, 10 * UIScreen.mainScreen.scale);
}


- (void)test_11_gcdarray {
    int a[10] = {34,232,231,2131,323132,232,121,585,3324,1231};
    int b[5]  = {5,5,5,5,100000};
    int c[1] = {300};
    int d[2] = {INT_MAX / 2 - 3,INT_MAX};
    int e[0];
    int f[3] = {-3, 23, -90};
    int g[3] = {0, 0, 0};
    
    XCTAssertEqual(gcdArray(10, a), 1);
    XCTAssertEqual(gcdArray(5, b), 5);
    XCTAssertEqual(gcdArray(1, c), 300);
    XCTAssertEqual(gcdArray(2, d), 1);
    XCTAssertEqual(gcdArray(0, e), 0);
    XCTAssertEqual(gcdArray(3, f), 1);
    XCTAssertEqual(gcdArray(3, g), 0);
}

@end

