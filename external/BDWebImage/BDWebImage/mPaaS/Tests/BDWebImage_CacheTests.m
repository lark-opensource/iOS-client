//
//  BDWebImage_CacheTests.m
//  BDWebImageTestTests
//
//  Created by zhangtianfu on 2018/12/18.
//  Copyright © 2018 zhangtianfu. All rights reserved.
//

#import "BaseTestCase.h"
#import <BDWebImage/BDWebImage.h>

NSString *kImageTestKey = @"TestImageKey.jpg";

@interface BDWebImage_CacheTests : BaseTestCase

@end

@implementation BDWebImage_CacheTests

- (UIImage *)imageForTesting{
    static UIImage *reusableImage = nil;
    if (!reusableImage) {
        reusableImage = [UIImage imageWithContentsOfFile:[self testImagePath]];
    }
    return reusableImage;
}

- (NSString *)testImagePath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"jpg"];
}

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [[BDWebImageManager sharedManager].imageCache.diskCache removeAllData];
    [[BDWebImageManager sharedManager].imageCache.memoryCache removeAllObjects];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)test_01_instance {
    XCTAssertNotNil([BDImageCache sharedImageCache]);
    XCTAssertNotEqual([BDImageCache sharedImageCache], [BDImageCache new]);
    XCTAssertEqual([BDImageCache sharedImageCache], [BDImageCache sharedImageCache]);
}

- (void)test_02_clear_disk_cache {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Clear disk cache"];
    
    [[BDImageCache sharedImageCache] setImage:[self imageForTesting] forKey:kImageTestKey];
    
    [[BDImageCache sharedImageCache] clearDiskWithBlock:^{
        XCTAssertEqual([[BDImageCache sharedImageCache] imageFromMemoryCacheForKey:kImageTestKey], [self imageForTesting]);
        
        XCTAssertNil([[BDImageCache sharedImageCache] imageFromDiskCacheForKey:kImageTestKey]);
        XCTAssertEqual([[BDImageCache sharedImageCache] totalDiskSize], 0);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_03_clear_memory_cache {
    [[BDImageCache sharedImageCache] setImage:[self imageForTesting] forKey:kImageTestKey];
    
    XCTAssertNotNil([[BDImageCache sharedImageCache] imageFromMemoryCacheForKey:kImageTestKey]);
    [[BDImageCache sharedImageCache] clearMemory];
    XCTAssertNil([[BDImageCache sharedImageCache] imageFromMemoryCacheForKey:kImageTestKey]);
}

- (void)test_04_set_image {
    XCTestExpectation *expectation = [self expectationWithDescription:@"set image for key"];
    
    UIImage *image = [self imageForTesting];
    [[BDImageCache sharedImageCache] setImage:image forKey:kImageTestKey];
    XCTAssertEqual([[BDImageCache sharedImageCache] imageFromMemoryCacheForKey:kImageTestKey], image);
    [[BDImageCache sharedImageCache] imageForKey:kImageTestKey withType:BDImageCacheTypeDisk withBlock:^(UIImage *image, BDImageCacheType type) {
        XCTAssertNotNil(image);
        XCTAssertEqual(type, BDImageCacheTypeDisk);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_05_save_to_disk {
    XCTestExpectation *expectation = [self expectationWithDescription:@"set image to disk"];
    
    UIImage *image = [self imageForTesting];
    [[BDImageCache sharedImageCache] saveImageToDisk:image data:nil forKey:kImageTestKey];

    [[BDImageCache sharedImageCache] imageForKey:kImageTestKey withType:BDImageCacheTypeDisk withBlock:^(UIImage *image, BDImageCacheType type) {
        XCTAssertNotNil(image);
        XCTAssertEqual(type, BDImageCacheTypeDisk);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_06_query_image_from_memory {
    XCTestExpectation *expectation = [self expectationWithDescription:@"query image from memory"];
    UIImage *image = [self imageForTesting];
    [[BDImageCache sharedImageCache] setImage:image forKey:kImageTestKey];
    [[BDImageCache sharedImageCache] imageForKey:kImageTestKey withType:BDImageCacheTypeMemory withBlock:^(UIImage *image, BDImageCacheType type) {
        XCTAssertNotNil(image);
        XCTAssertEqual(type, BDImageCacheTypeMemory);
        [[BDImageCache sharedImageCache] removeImageForKey:kImageTestKey];
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_07_query_image_from_disk {
    XCTestExpectation *expectation = [self expectationWithDescription:@"query image from disk"];
    UIImage *image = [self imageForTesting];
    [[BDImageCache sharedImageCache] setImage:image forKey:kImageTestKey];
    [[BDImageCache sharedImageCache] imageForKey:kImageTestKey withType:BDImageCacheTypeDisk withBlock:^(UIImage *image, BDImageCacheType type) {
        XCTAssertNotNil(image);
        XCTAssertEqual(type, BDImageCacheTypeDisk);
        [[BDImageCache sharedImageCache] removeImageForKey:kImageTestKey];
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_08_remove_image_from_all {
    XCTestExpectation *expectation = [self expectationWithDescription:@"remove image from all"];
    UIImage *image = [self imageForTesting];
    [[BDImageCache sharedImageCache] setImage:image forKey:kImageTestKey];
    XCTAssertNotNil([[BDImageCache sharedImageCache] imageFromMemoryCacheForKey:kImageTestKey]);
    XCTAssertNotNil([[BDImageCache sharedImageCache] imageFromDiskCacheForKey:kImageTestKey]);
    [[BDImageCache sharedImageCache] removeImageForKey:kImageTestKey];
    XCTAssertNil([[BDImageCache sharedImageCache] imageFromMemoryCacheForKey:kImageTestKey]);
    XCTAssertNil([[BDImageCache sharedImageCache] imageFromDiskCacheForKey:kImageTestKey]);
    [expectation fulfill];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_09_initailConfig {
    BDImageCacheConfig *config = [BDImageCache sharedImageCache].config;
    XCTAssertTrue(config.clearMemoryOnMemoryWarning);
    XCTAssertTrue(config.clearMemoryWhenEnteringBackground);
    XCTAssertEqual(config.memoryCountLimit, NSUIntegerMax);
    XCTAssertEqual(config.memorySizeLimit, 256 * 1024 * 1024);
    XCTAssertEqual(config.memoryAgeLimit, 12 * 60 * 60);
    XCTAssertTrue(config.trimDiskWhenEnteringBackground);
    XCTAssertEqual(config.diskCountLimit, NSUIntegerMax);
    XCTAssertEqual(config.diskSizeLimit, 256 * 1024 * 1024);
    XCTAssertEqual(config.diskAgeLimit, 7 * 24 * 60 * 60);
}

- (void)test_10_check_cache_exist {
    UIImage *image = [self imageForTesting];
    XCTAssertEqual([[BDImageCache sharedImageCache] containsImageForKey:kImageTestKey], BDImageCacheTypeNone);
    [[BDImageCache sharedImageCache] setImage:image imageData:nil forKey:kImageTestKey withType:BDImageCacheTypeMemory];
    XCTAssertEqual([[BDImageCache sharedImageCache] containsImageForKey:kImageTestKey], BDImageCacheTypeMemory);
    [[BDImageCache sharedImageCache] removeImageForKey:kImageTestKey];
    [[BDImageCache sharedImageCache] setImage:image imageData:nil forKey:kImageTestKey withType:BDImageCacheTypeDisk];
    XCTAssertEqual([[BDImageCache sharedImageCache] containsImageForKey:kImageTestKey], BDImageCacheTypeDisk);
    [[BDImageCache sharedImageCache] removeImageForKey:kImageTestKey];
}

- (void)test_11_check_cache_path {
    UIImage *image = [self imageForTesting];
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[[BDImageCache sharedImageCache] cachePathForKey:kImageTestKey]]);
    [[BDImageCache sharedImageCache] setImage:image imageData:nil forKey:kImageTestKey withType:BDImageCacheTypeMemory];
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[[BDImageCache sharedImageCache] cachePathForKey:kImageTestKey]]);
    [[BDImageCache sharedImageCache] setImage:image imageData:nil forKey:kImageTestKey withType:BDImageCacheTypeDisk];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[[BDImageCache sharedImageCache] cachePathForKey:kImageTestKey]]);
}

- (void)test_12_check_cache_name {
    NSString *normalKey = [[BDWebImageManager sharedManager] requestKeyWithURL:[NSURL URLWithString:kTestJpegURL]];
    XCTAssertEqual(normalKey, kTestJpegURL);
    XCTAssertGreaterThan(normalKey.length, 0);
    
    NSString *noExtentionURL = @"https://maps.googleapis.com/maps/api/staticmap?center=48.8566,2.3522&format=png&maptype=roadmap&scale=2&size=375x200&zoom=15";
    NSString *noExtentionKey = [[BDWebImageManager sharedManager] requestKeyWithURL:[NSURL URLWithString:noExtentionURL]];
    XCTAssertEqual(noExtentionKey, noExtentionURL);
    
    NSString *qureryParamesURL = @"https://imggen.alicdn.com/3b11cea896a9438329d85abfb07b30a8.jpg?aid=tanx&tid=1166&m=%7B%22img_url%22%3A%22https%3A%2F%2Fgma.alicdn.com%2Fbao%2Fuploaded%2Fi4%2F1695306010722305097%2FTB2S2KjkHtlpuFjSspoXXbcDpXa_%21%210-saturn_solar.jpg_sum.jpg%22%2C%22title%22%3A%22%E6%A4%8D%E7%89%A9%E8%94%B7%E8%96%87%E7%8E%AB%E7%91%B0%E8%8A%B1%22%2C%22promot_name%22%3A%22%22%2C%22itemid%22%3A%22546038044448%22%7D&e=cb88dab197bfaa19804f6ec796ca906dab536b88fe6d4475795c7ee661a7ede1&size=640x246";
    NSString *qureryParamesKey = [[BDWebImageManager sharedManager] requestKeyWithURL:[NSURL URLWithString:qureryParamesURL]];
    XCTAssertEqual(qureryParamesKey, qureryParamesURL);
    
    NSString *tooLongURL = @"https://imggen.alicdn.com/3b11cea896a9438329d85abfb07b30a8.jpgasaaaaaaaaaaaaaaaaaaaajjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjaaaaaaaaaaaaaaaaajjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj";
    NSString *tooLongKey = [[BDWebImageManager sharedManager] requestKeyWithURL:[NSURL URLWithString:tooLongURL]];
    XCTAssertEqual(tooLongKey, tooLongURL);
}

- (void)test_13_insertion_of_imageData
{
    [[BDImageCache sharedImageCache] clearMemory];
    UIImage *image = [UIImage imageWithContentsOfFile:[self testImagePath]];
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    [[BDImageCache sharedImageCache] saveImageToDisk:image data:imageData forKey:kImageTestKey];
    
    UIImage *storedImageFromMemory = [[BDImageCache sharedImageCache] imageFromMemoryCacheForKey:kImageTestKey];
    XCTAssertNil(storedImageFromMemory);
    
    NSString *cachePath = [[BDImageCache sharedImageCache] cachePathForKey:kImageTestKey];
    UIImage *cachedImage = [UIImage imageWithContentsOfFile:cachePath];
    NSData *storedImageData = UIImageJPEGRepresentation(cachedImage, 1.0);
    XCTAssertGreaterThan(storedImageData.length, 0);
    XCTAssertTrue(cachedImage.size.width * cachedImage.scale == image.size.width * image.scale);
    XCTAssertTrue(cachedImage.size.height * cachedImage.scale == image.size.height * image.scale);

    BDImageCacheType type = [[BDImageCache sharedImageCache] containsImageForKey:kImageTestKey type:BDImageCacheTypeDisk];
    XCTAssertEqual(type, BDImageCacheTypeDisk);
    [[BDImageCache sharedImageCache] removeImageForKey:kImageTestKey];
}

- (void)test_14_total_disk_cache_size {
    XCTestExpectation *expectation = [self expectationWithDescription:@"clear all disk"];

    [[BDImageCache sharedImageCache] clearDiskWithBlock:^{
        UIImage *jpgImage = [UIImage imageWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"]];
        UIImage *pngImage = [UIImage imageWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"png"]];
        NSData *jpgData = UIImageJPEGRepresentation(jpgImage, 1);
        NSData *pngData = UIImagePNGRepresentation(pngImage);
        XCTAssertGreaterThan(jpgData.length, 0);
        XCTAssertGreaterThan(pngData.length, 0);
        [[BDImageCache sharedImageCache] saveImageToDisk:jpgImage data:jpgData forKey:@"test1"];
        [[BDImageCache sharedImageCache] saveImageToDisk:pngImage data:pngData forKey:@"test2"];
        
        NSUInteger totalDiskSize = [[BDImageCache sharedImageCache] totalDiskSize];
        XCTAssertEqual(totalDiskSize, jpgData.length+pngData.length);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}



@end

