//
//  SDInterface_Extention_Tests.m
//  BDWebImage_Tests
//
//  Created by 陈奕 on 2020/1/6.
//  Copyright © 2020 Bytedance.com. All rights reserved.
//

#import "BaseTestCase.h"
#import <SDInterface.h>
#import <UIImageView+SDInterface.h>
#import <UIButton+SDInterface.h>

@interface SDInterface_Extention_Tests : BaseTestCase

@end

@implementation SDInterface_Extention_Tests

- (void)setUp {
    [[BDWebImageManager sharedManager].imageCache.diskCache removeAllData];
    [[BDWebImageManager sharedManager].imageCache.memoryCache removeAllObjects];
    [super setUp];
}

#pragma mark ------------- UIImageView --------------------

- (void)test_01_imageView_setImageURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView setImageWithURL"];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    [self sdadapter_removeImageCache:originalImageURL completion:^{
        [imageView sdi_setImageWithURL:originalImageURL
                             completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                 XCTAssertNotNil(image);
                                 XCTAssertNil(error);
                                 XCTAssertEqual(cacheType, BDImageCacheTypeNone);
                                 XCTAssertEqual(originalImageURL, imageURL);
                                 
                                 UIImageView *imageView2 = [[UIImageView alloc] init];
                                 [imageView2 sdi_setImageWithURL:originalImageURL
                                                       completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                                           XCTAssertNotNil(image);
                                                           XCTAssertNil(error);
                                                           XCTAssertEqual(cacheType, BDImageCacheTypeMemory);
                                                           XCTAssertEqual(originalImageURL, imageURL);
                                                           [expectation fulfill];
                                                       }];
                             }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_02_imageView_placeHolder_success {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView placeHolder success"];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"png"];
    UIImage *placeHolder = [UIImage imageWithContentsOfFile:testImagePath];
    XCTAssertNotNil(placeHolder);
    
    [imageView sdi_setImageWithURL:originalImageURL
                  placeholderImage:placeHolder
                         completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                             XCTAssertNotNil(image);
                             XCTAssertNil(error);
                             XCTAssertEqual(imageView.image, image);
                             XCTAssertNotEqual(imageView.image, placeHolder);
                             [expectation fulfill];
                         }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_03_imageView_placeHolder_fail {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView placeHolder fail"];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:@"https://abc"];
    
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"png"];
    UIImage *placeHolder = [UIImage imageWithContentsOfFile:testImagePath];
    XCTAssertNotNil(placeHolder);
    
    [imageView sdi_setImageWithURL:originalImageURL
                  placeholderImage:placeHolder
                         completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                             XCTAssertNil(image);
                             XCTAssertNotNil(error);
                             XCTAssertEqual(imageView.image, placeHolder);
                             [expectation fulfill];
                         }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_04_imageView_png {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView setImageWithURL png"];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestPNGURL];
    [self sdadapter_removeImageCache:originalImageURL completion:^{
        [imageView sdi_setImageWithURL:originalImageURL
                             completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                 XCTAssertNotNil(image);
                                 XCTAssertNil(error);
                                 XCTAssertEqual(originalImageURL, imageURL);
                                 
                                 [expectation fulfill];
                             }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_05_imageView_gif {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView setImageWithURL gif"];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestGIFURL];
    [self sdadapter_removeImageCache:originalImageURL completion:^{
        [imageView sdi_setImageWithURL:originalImageURL
                             completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                 XCTAssertNotNil(image);
                                 XCTAssertNil(error);
                                 XCTAssertEqual(originalImageURL, imageURL);
                                 
                                 [expectation fulfill];
                             }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_06_imageView_webp {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView setImageWithURL webp"];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestWebPURL];
    [self sdadapter_removeImageCache:originalImageURL completion:^{
        [imageView sdi_setImageWithURL:originalImageURL
                             completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                 XCTAssertNotNil(image);
                                 XCTAssertNil(error);
                                 XCTAssertEqual(originalImageURL, imageURL);
                                 
                                 [expectation fulfill];
                             }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_07_image_cancel_image_from_download {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView cancel image from download"];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestPNGURL];
    [self sdadapter_removeImageCache:originalImageURL completion:^{
        [imageView sdi_setImageWithURL:originalImageURL
                             completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                 XCTFail(@"something is wrong");
                             }];
        
        [imageView sdi_cancelCurrentImageLoad];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
            XCTAssertNil(imageView.image);
            [expectation fulfill];
        });
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_08_image_cancel_image_from_memory {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView cancel image from memory"];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestPNGURL];
    [imageView sdi_setImageWithURL:originalImageURL
                         completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                             XCTAssertNotNil(image);
                             XCTAssertNotNil([[SDInterface sharedInterface] imageFromMemoryCacheForKey:[[SDInterface sharedInterface] cacheKeyForURL:originalImageURL]]);
                             
                             UIImageView *imageView2 = [[UIImageView alloc] init];
                             [imageView2 sdi_setImageWithURL:originalImageURL
                                                   completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                                       XCTAssertNotNil(image);
                                                   }];
                             [imageView2 sdi_cancelCurrentImageLoad];
                             
                             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
                                 XCTAssertNotNil(imageView2.image);
                                 [expectation fulfill];
                             });
                         }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_09_image_cancel_image_from_disk {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView cancel image from disk"];
    
    [[SDInterface sharedInterface] clearMemory];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestPNGURL];
    [imageView sdi_setImageWithURL:originalImageURL
                         completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                             XCTFail(@"something is wrong");
                         }];
    
    [imageView sdi_cancelCurrentImageLoad];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
        XCTAssertNil(imageView.image);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithCommonTimeout];
}

#pragma mark ------------- UIButton --------------------

- (void)test_10_button_setImageURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton setImageWithURL"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    [self sdadapter_removeImageCache:originalImageURL completion:^{
        [button sdi_setImageWithURL:originalImageURL
                           forState:UIControlStateNormal
                          completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                              XCTAssertNotNil(image);
                              XCTAssertNil(error);
                              XCTAssertEqual(cacheType, BDImageCacheTypeNone);
                              XCTAssertEqual(originalImageURL, imageURL);
                              
                              UIButton *button2 = [[UIButton alloc] init];
                              [button2 sdi_setImageWithURL:originalImageURL
                                                  forState:UIControlStateNormal
                                                 completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                                     XCTAssertNotNil(image);
                                                     XCTAssertNil(error);
                                                     XCTAssertEqual(cacheType, BDImageCacheTypeMemory);
                                                     XCTAssertEqual(originalImageURL, imageURL);
                                                     [expectation fulfill];
                                                 }];
                          }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_11_button_setHighlingtImageURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton setHighlightImageWithURL"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    
    [button sdi_setImageWithURL:originalImageURL
                       forState:UIControlStateHighlighted
                      completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                          XCTAssertNotNil(image);
                          XCTAssertNil(error);
                          XCTAssertEqual(originalImageURL, imageURL);
                          XCTAssertEqual(image, [button imageForState:UIControlStateHighlighted]);
                          [expectation fulfill];
                      }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_12_button_setBackgroudImageURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton setBackgroundImageWithURL"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    [self sdadapter_removeImageCache:originalImageURL completion:^{
        [button sdi_setBackgroundImageWithURL:originalImageURL
                                     forState:UIControlStateNormal
                                    completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                        XCTAssertNotNil(image);
                                        XCTAssertNil(error);
                                        XCTAssertEqual(originalImageURL, imageURL);
                                        XCTAssertEqual(image, [button backgroundImageForState:UIControlStateNormal]);
                                        [expectation fulfill];
                                    }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_13_button_setHighlingtBackgroudImageURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton setHighlightBackgroundImageWithURL"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    
    [button sdi_setBackgroundImageWithURL:originalImageURL
                                 forState:UIControlStateHighlighted
                         placeholderImage:nil
                                completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                    XCTAssertNotNil(image);
                                    XCTAssertNil(error);
                                    XCTAssertEqual(originalImageURL, imageURL);
                                    XCTAssertEqual(image, [button backgroundImageForState:UIControlStateHighlighted]);
                                    [expectation fulfill];
                                }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_14_button_placeHolder_success {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton placeHolder success"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    [self sdadapter_removeImageCache:originalImageURL completion:^{
        NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"png"];
        UIImage *placeHolder = [UIImage imageWithContentsOfFile:testImagePath];
        XCTAssertNotNil(placeHolder);
        
        [button sdi_setImageWithURL:originalImageURL
                           forState:UIControlStateNormal
                   placeholderImage:placeHolder
                          completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                              XCTAssertNotNil(image);
                              XCTAssertNil(error);
                              XCTAssertEqual(image, [button imageForState:UIControlStateNormal]);
                              XCTAssertNotEqual(image, placeHolder);
                              [expectation fulfill];
                          }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_15_button_placeHolder_fail {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton placeHolder fail"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:@"https://abc"];
    [self sdadapter_removeImageCache:originalImageURL completion:^{
        NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"png"];
        UIImage *placeHolder = [UIImage imageWithContentsOfFile:testImagePath];
        XCTAssertNotNil(placeHolder);
        
        [button sdi_setImageWithURL:originalImageURL
                           forState:UIControlStateNormal
                   placeholderImage:placeHolder
                          completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                              XCTAssertNil(image);
                              XCTAssertNotNil(error);
                              XCTAssertEqual(placeHolder, [button imageForState:UIControlStateNormal]);
                              [expectation fulfill];
                          }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_16_button_cancel_image_from_download {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton cancel image from download"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestPNGURL];
    [self sdadapter_removeImageCache:originalImageURL completion:^{
        [button sdi_setImageWithURL:originalImageURL
                           forState:UIControlStateNormal
                          completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                              XCTFail(@"something is wrong");
                          }];
        
        [button sdi_cancelImageLoadForState:UIControlStateNormal];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
            XCTAssertNil([button imageForState:UIControlStateNormal]);
            [expectation fulfill];
        });
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_17_button_cancel_image_from_memory {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton cancel image from memory"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestPNGURL];
    
    [button sdi_setImageWithURL:originalImageURL
                       forState:UIControlStateNormal
                      completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                          XCTAssertNotNil(image);
                          XCTAssertNotNil([[SDInterface sharedInterface] imageFromMemoryCacheForKey:[[SDInterface sharedInterface] cacheKeyForURL:originalImageURL]]);
                          UIButton *tmpButton = [[UIButton alloc] init];
                          [tmpButton sdi_setImageWithURL:originalImageURL
                                                forState:UIControlStateNormal
                                               completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                                   XCTAssertNotNil(image);
                                               }];
                          
                          [tmpButton sdi_cancelImageLoadForState:UIControlStateNormal];
                          
                          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
                              XCTAssertNotNil([button imageForState:UIControlStateNormal]);
                              [expectation fulfill];
                          });
                      }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_18_button_cancel_image_from_disk {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton cancel image from disk"];
    
    [[SDInterface sharedInterface] clearMemory];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestPNGURL];
    
    [button sdi_setImageWithURL:originalImageURL
                       forState:UIControlStateNormal
                      completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                          XCTFail(@"something is wrong");
                      }];
    
    [button sdi_cancelImageLoadForState:UIControlStateNormal];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
        XCTAssertNil([button imageForState:UIControlStateNormal]);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_19_button_cancel_backgroudImage_from_download {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton cancel backgroudImage from download"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestPNGURL];
    [self sdadapter_removeImageCache:originalImageURL completion:^{
        [button sdi_setBackgroundImageWithURL:originalImageURL
                                     forState:UIControlStateNormal
                                    completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                        XCTFail(@"something is wrong");
                                    }];
        
        [button sdi_cancelBackgroundImageLoadForState:UIControlStateNormal];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
            XCTAssertNil([button backgroundImageForState:UIControlStateNormal]);
            [expectation fulfill];
        });
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_20_button_cancel_backgroudImage_from_memory {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton cancel backgroudImage from memory"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestPNGURL];
    
    [button sdi_setBackgroundImageWithURL:originalImageURL
                                 forState:UIControlStateNormal
                                completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                    XCTAssertNotNil(image);
                                    XCTAssertNotNil([[SDInterface sharedInterface] imageFromMemoryCacheForKey:[[SDInterface sharedInterface] cacheKeyForURL:originalImageURL]]);
                                    UIButton *tmpButton = [[UIButton alloc] init];
                                    [tmpButton sdi_setBackgroundImageWithURL:originalImageURL
                                                                    forState:UIControlStateNormal
                                                                   completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                                                       XCTAssertNotNil(image);
                                                                   }];
                                    
                                    [tmpButton sdi_cancelBackgroundImageLoadForState:UIControlStateNormal];
                                    
                                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
                                        XCTAssertNotNil([button backgroundImageForState:UIControlStateNormal]);
                                        [expectation fulfill];
                                    });
                                }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_21_button_cancel_backgroudImage_from_disk {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton cancel backgroudImage from disk"];
    
    [[SDInterface sharedInterface] clearMemory];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestPNGURL];
    
    [button sdi_setBackgroundImageWithURL:originalImageURL
                                 forState:UIControlStateNormal
                                completed:^(UIImage * _Nullable image, NSError * _Nullable error, BDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                    XCTFail(@"something is wrong");
                                }];
    
    [button sdi_cancelBackgroundImageLoadForState:UIControlStateNormal];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
        XCTAssertNil([button backgroundImageForState:UIControlStateNormal]);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithCommonTimeout];
}




@end
