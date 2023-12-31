//
//  BDWebImage_Category.m
//  BDWebImageTestTests
//
//  Created by zhangtianfu on 2018/12/20.
//  Copyright © 2018 zhangtianfu. All rights reserved.
//

#import "BaseTestCase.h"
#import <BDWebImage/BDWebImage.h>

@interface BDWebImage_Extension : BaseTestCase

@end

@implementation BDWebImage_Extension

- (void)setUp {
    [[BDWebImageManager sharedManager].imageCache.diskCache removeAllData];
    [[BDWebImageManager sharedManager].imageCache.memoryCache removeAllObjects];
    
    [super setUp];
}

#pragma mark ------------ imageView ----------------------------

- (void)test_01_imageView_setImageURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView setImageWithURL"];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    [self removeImageCache:originalImageURL];
    
    [imageView bd_setImageWithURL:originalImageURL
                      placeholder:nil
                          options:0
                       completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                           XCTAssertNotNil(request);
                           XCTAssertNotNil(image);
                           XCTAssertNotNil(data);
                           XCTAssertNil(error);
                           XCTAssertEqual(imageView.image, image);
                           [expectation fulfill];
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
    
    [imageView bd_setImageWithURL:originalImageURL
                      placeholder:placeHolder
                          options:0
                       completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                           XCTAssertNotNil(request);
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
    
    [imageView bd_setImageWithURL:originalImageURL
                      placeholder:placeHolder
                          options:0
                       completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                           XCTAssertNotNil(request);
                           XCTAssertNil(image);
                           XCTAssertNotNil(error);
                           XCTAssertEqual(imageView.image, placeHolder);
                           [expectation fulfill];
                       }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_04_imageView_progress {
        XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView progress"];
    
        UIImageView *imageView = [[UIImageView alloc] init];
        NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
        [self removeImageCache:originalImageURL];
    
        NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"png"];
        UIImage *placeHolder = [UIImage imageWithContentsOfFile:testImagePath];
        XCTAssertNotNil(placeHolder);
    
        [imageView bd_setImageWithURL:originalImageURL placeholder:placeHolder options:0 cacheName:nil progress:^(BDWebImageRequest *request, NSInteger receivedSize, NSInteger expectedSize) {
            XCTAssertGreaterThanOrEqual(receivedSize, 0);
            XCTAssertGreaterThan(expectedSize, 0);
            XCTAssertLessThanOrEqual(receivedSize, expectedSize);
//            if (receivedSize == expectedSize) {
//                [expectation fulfill];
//            }
        } completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            XCTAssertNotNil(request);
            XCTAssertNotNil(image);
            XCTAssertNil(error);
            XCTAssertEqual(imageView.image, image);
            XCTAssertNotEqual(imageView.image, placeHolder);
            [expectation fulfill];
        }];
        [self waitForExpectationsWithCommonTimeout];
}

- (void)test_05_imageView_alterNativeURLs {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView alterNativeURLs"];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    
    NSURL *invalidURL = [NSURL URLWithString:@"https://abc"];
    NSURL *validURL = [NSURL URLWithString:kTestWebPURL];
    
    [imageView bd_setImageWithURL:invalidURL alternativeURLs:@[invalidURL, validURL] placeholder:nil
                          options:0 cacheName:nil
                      transformer:nil
                         progress:nil
                       completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                           XCTAssertNotNil(request);
                           XCTAssertNotNil(image);
                           XCTAssertNil(error);
                           XCTAssertEqual(request.currentRequestURL, validURL);
                           [expectation fulfill];
                       }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_06_imageView_transformer_round {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView transformer_round"];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    
    [imageView bd_setImageWithURL:originalImageURL
                      placeholder:nil
                          options:0 completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                              XCTAssertNotNil(image);
                              
                              UIImage *originalImage = image;
                              
                              BDRoundCornerTransformer *transformaer = [BDRoundCornerTransformer transformerWithImageSize:BDRoundCornerImageSize30];
                              [imageView bd_setImageWithURL:originalImageURL
                                                placeholder:nil
                                                    options:0
                                                transformer:transformaer
                                                   progress:nil completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                                                       XCTAssertNotNil(image);
                                                       XCTAssertNotEqual(image, originalImage);
                                                       [expectation fulfill];
                                                   }];
                          }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_07_imageView_transformer_block {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView transformer_block"];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    
    [imageView bd_setImageWithURL:originalImageURL
                      placeholder:nil
                          options:0
                       completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                           XCTAssertNotNil(image);
                           
                           BDBlockTransformer *transformaer = [BDBlockTransformer transformWithBlock:^UIImage * _Nullable(UIImage * _Nullable image) {
                               return [image bd_imageByResizeToSize:CGSizeMake(100, 200)];
                           }];
                           [imageView bd_setImageWithURL:originalImageURL
                                             placeholder:nil
                                                 options:0
                                             transformer:transformaer
                                                progress:nil completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                                                    XCTAssertNotNil(image);
                                                    XCTAssertTrue(CGSizeEqualToSize(image.size, CGSizeMake(100, 200)));
                                                    [expectation fulfill];
                                                }];
                       }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_08_imageView_animations {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView animations"];
    BDImageView *imageView = [[BDImageView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestGIFURL];
    [self removeImageCache:originalImageURL];
    
    [imageView bd_setImageWithURL:originalImageURL
                      placeholder:nil
                          options:0
                       completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                           XCTAssertNotNil(request);
                           XCTAssertNotNil(image);
                           XCTAssertNotNil(data);
                           XCTAssertNil(error);
                           [expectation fulfill];
                       }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_09_imageView_cancel_image_from_download {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView cancel image from download"];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestPNGURL];
    [self removeImageCache:originalImageURL];
    [imageView bd_setImageWithURL:originalImageURL
                      placeholder:nil
                          options:0
                       completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                           XCTFail(@"something is wrong");
                       }];
    [imageView bd_cancelImageLoad];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
        XCTAssertNil(imageView.image);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_10_imageView_cancel_image_from_memory {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView cancel image from memory"];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestPNGURL];
    [imageView bd_setImageWithURL:originalImageURL
                      placeholder:nil
                          options:0
                       completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                           XCTAssertNotNil(image);
                           BDImageCacheType type = [[BDImageCache sharedImageCache] containsImageForKey:[[BDWebImageManager sharedManager] requestKeyWithURL:originalImageURL] type:BDImageCacheTypeMemory];
                           XCTAssertTrue(type & BDImageCacheTypeMemory);
                           
                           UIImageView *imageView2 = [[UIImageView alloc] init];
                           [imageView2 bd_setImageWithURL:originalImageURL
                                              placeholder:nil
                                                  options:0
                                               completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                                                   XCTAssertNotNil(image);
                                               }];
                           [imageView2 bd_cancelImageLoad];
                           
                           dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
                               XCTAssertNotNil(imageView2.image);
                               [expectation fulfill];
                           });
                       }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_11_imageView_cancel_image_from_disk {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView cancel image from disk"];
    
    [[BDImageCache sharedImageCache] clearMemory];
    
    NSURL *originalImageURL = [NSURL URLWithString:kTestPNGURL];
    UIImageView *imageView = [[UIImageView alloc] init];
    [imageView bd_setImageWithURL:originalImageURL
                      placeholder:nil
                          options:0
                       completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                           XCTFail(@"something is wrong");
                       }];
    [imageView bd_cancelImageLoad];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
        XCTAssertNil(imageView.image);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_12_imageView_url_is_nil_completeBlock {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView set image and url is nil"];
    
    NSURL *originalImageURL = [NSURL URLWithString:@""];
    UIImageView *imageView = [[UIImageView alloc] init];
    [imageView bd_setImageWithURL:originalImageURL
                      placeholder:nil
                          options:0
                       completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                            XCTAssertNotNil(request);
                            XCTAssertNil(image);
                            XCTAssertNil(data);
                            XCTAssertNotNil(error);
                            [expectation fulfill];
                       }];

    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_13_imageView_urls_are_nil_completeBlock {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView set image and urls are nil"];
    
    NSArray *urls = [NSArray array];
    UIImageView *imageView = [[UIImageView alloc] init];
    [imageView bd_setImageWithURLs:urls
                       placeholder:nil
                           options:0
                       transformer:nil
                          progress:nil
                        completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            XCTAssertNil(request);
            XCTAssertNil(image);
            XCTAssertNil(data);
            XCTAssertNotNil(error);
            [expectation fulfill];
    }];

    
    [self waitForExpectationsWithCommonTimeout];
}


#pragma mark ------------ button ----------------------------

- (void)test_12_button_setImageURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton setImageWithURL"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    [self removeImageCache:originalImageURL];
    
    [button bd_setImageWithURL:originalImageURL
                      forState:UIControlStateNormal
              placeholderImage:nil
                     completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                         XCTAssertNotNil(request);
                         XCTAssertNotNil(image);
                         XCTAssertNotNil(data);
                         XCTAssertNil(error);
                         XCTAssertEqual(originalImageURL, request.currentRequestURL);
                         XCTAssertEqual(image, [button imageForState:UIControlStateNormal]);
                         [expectation fulfill];
                     }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_13_button_setHighlingtImageURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton setHighlightImageWithURL"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    
    [button bd_setImageWithURL:originalImageURL
                      forState:UIControlStateHighlighted
              placeholderImage:nil
                     completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                         XCTAssertNotNil(image);
                         XCTAssertNil(error);
                         XCTAssertEqual(originalImageURL, request.currentRequestURL);
                         XCTAssertEqual(image, [button imageForState:UIControlStateHighlighted]);
                         [expectation fulfill];
                     }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_14_button_setBackgroudImageURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton setBackgroundImageWithURL"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    [self removeImageCache:originalImageURL];
    
    [button bd_setBackgroundImageWithURL:originalImageURL
                                forState:UIControlStateNormal
                        placeholderImage:nil
                               completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                                   XCTAssertNotNil(request);
                                   XCTAssertNotNil(image);
                                   XCTAssertNotNil(data);
                                   XCTAssertNil(error);
                                   XCTAssertEqual(originalImageURL, request.currentRequestURL);
                                   XCTAssertEqual(image, [button backgroundImageForState:UIControlStateNormal]);
                                   [expectation fulfill];
                               }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_15_button_setHighlingtBackgroudImageURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton setHighlightBackgroundImageWithURL"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    
    [button bd_setBackgroundImageWithURL:originalImageURL forState:UIControlStateHighlighted placeholderImage:nil completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNotNil(image);
        XCTAssertNil(error);
        XCTAssertEqual(originalImageURL, request.currentRequestURL);
        XCTAssertEqual(image, [button backgroundImageForState:UIControlStateHighlighted]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_16_button_placeHolder_success {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton placeHolder success"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    [self removeImageCache:originalImageURL];
    
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"png"];
    UIImage *placeHolder = [UIImage imageWithContentsOfFile:testImagePath];
    XCTAssertNotNil(placeHolder);
    
    [button bd_setImageWithURL:originalImageURL
                      forState:UIControlStateNormal
              placeholderImage:placeHolder
                     completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                         XCTAssertNotNil(request);
                         XCTAssertNotNil(image);
                         XCTAssertNotNil(data);
                         XCTAssertNil(error);
                         XCTAssertEqual(image, [button imageForState:UIControlStateNormal]);
                         XCTAssertNotEqual(image, placeHolder);
                         [expectation fulfill];
                     }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_17_button_placeHolder_fail {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton placeHolder fail"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:@"https://abc"];
    [self removeImageCache:originalImageURL];
    
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"png"];
    UIImage *placeHolder = [UIImage imageWithContentsOfFile:testImagePath];
    XCTAssertNotNil(placeHolder);
    
    [button bd_setImageWithURL:originalImageURL
                      forState:UIControlStateNormal
              placeholderImage:placeHolder
                     completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                         XCTAssertNotNil(request);
                         XCTAssertNil(image);
                         XCTAssertNotNil(error);
                         XCTAssertEqual(placeHolder, [button imageForState:UIControlStateNormal]);
                         [expectation fulfill];
                     }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_18_button_progress {
    //    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton progress"];
    //
    //    UIButton *button = [[UIButton alloc] init];
    //    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    //    [self removeImageCache:originalImageURL];
    //
    //    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"png"];
    //    UIImage *placeHolder = [UIImage imageWithContentsOfFile:testImagePath];
    //    XCTAssertNotNil(placeHolder);
    //
    //    [button bd_setImageWithURL:originalImageURL
    //                      forState:UIControlStateNormal
    //              placeholderImage:placeHolder
    //                       options:0 cacheName:nil
    //                      progress:^(BDWebImageRequest *request, NSInteger receivedSize, NSInteger expectedSize) {
    //                          XCTAssertGreaterThanOrEqual(receivedSize, 0);
    //                          XCTAssertGreaterThan(expectedSize, 0);
    //                          XCTAssertLessThanOrEqual(receivedSize, expectedSize);
    //                          if (receivedSize == expectedSize) {
    //                              [expectation fulfill];
    //                          }
    //                      } completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
    //                          XCTAssertNotNil(request);
    //                          XCTAssertNotNil(image);
    //                          XCTAssertNil(error);
    //                          [expectation fulfill];
    //                      }];
    //
    //    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_19_button_alterNativeURLs {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton alterNativeURLs"];
    
    UIButton *button = [[UIButton alloc] init];
    
    NSURL *invalidURL = [NSURL URLWithString:@"https://abc"];
    NSURL *validURL = [NSURL URLWithString:kTestWebPURL];
    
    [button bd_setImageWithURL:invalidURL
               alternativeURLs:@[invalidURL, validURL]
                      forState:UIControlStateNormal
              placeholderImage:nil
                       options:0
                     cacheName:nil
                   transformer:nil
                      progress:nil
                     completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                         XCTAssertNotNil(request);
                         XCTAssertNotNil(image);
                         XCTAssertNil(error);
                         XCTAssertEqual(request.currentRequestURL, validURL);
                         [expectation fulfill];
                     }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_20_button_transformer_round {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton transformer_round"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    
    [button bd_setImageWithURL:originalImageURL
                      forState:UIControlStateNormal
              placeholderImage:nil
                     completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                         XCTAssertNotNil(image);
                         UIImage *originalImage = image;
                         
                         BDRoundCornerTransformer *transformaer = [BDRoundCornerTransformer transformerWithImageSize:BDRoundCornerImageSize30];
                         
                         UIButton *button2 = [[UIButton alloc] init];
                         [button2 bd_setImageWithURL:originalImageURL
                                    alternativeURLs:@[]
                                           forState:UIControlStateNormal
                                   placeholderImage:nil
                                            options:0
                                          cacheName:nil
                                        transformer:transformaer
                                           progress:nil
                                          completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                                              XCTAssertNotNil(image);
                                              XCTAssertNotEqual(image, originalImage);
                                          }];
                            [expectation fulfill];
                     }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_21_button_transformer_round {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton transformer_block"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    
    [button bd_setImageWithURL:originalImageURL
                      forState:UIControlStateNormal
              placeholderImage:nil
                     completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                         XCTAssertNotNil(image);
                         UIImage *originalImage = image;
                         
                         BDBlockTransformer *transformaer = [BDBlockTransformer transformWithBlock:^UIImage * _Nullable(UIImage * _Nullable image) {
                             return [image bd_imageByResizeToSize:CGSizeMake(100, 200)];
                         }];
                         
                         UIButton *button2 = [[UIButton alloc] init];
                         [button2 bd_setImageWithURL:originalImageURL
                                    alternativeURLs:@[]
                                           forState:UIControlStateNormal
                                   placeholderImage:nil
                                            options:0
                                          cacheName:nil
                                        transformer:transformaer
                                           progress:nil
                                          completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                                              XCTAssertNotNil(image);
                                              XCTAssertNotEqual(image, originalImage);
                                          }];
                            [expectation fulfill];
                     }];
    
    [self waitForExpectationsWithCommonTimeout];
}


- (void)test_22_button_cancel_image_from_download {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton cancel image from download"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestPNGURL];
    [self removeImageCache:originalImageURL];
    [button bd_setImageWithURL:originalImageURL
                      forState:UIControlStateNormal
              placeholderImage:nil
                     completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                         XCTFail(@"something is wrong");
                     }];
    [button bd_cancelImageLoadForState:UIControlStateNormal];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
        XCTAssertNil([button imageForState:UIControlStateNormal]);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_23_button_cancel_image_from_memory {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton cancel image from memory"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestPNGURL];
    
    [button bd_setImageWithURL:originalImageURL
                      forState:UIControlStateNormal
              placeholderImage:nil
                     completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                         XCTAssertNotNil(image);
                         BDImageCacheType type = [[BDImageCache sharedImageCache] containsImageForKey:[[BDWebImageManager sharedManager] requestKeyWithURL:originalImageURL] type:BDImageCacheTypeMemory];
                         XCTAssertTrue(type & BDImageCacheTypeMemory);
                         
                         UIButton *button2 = [[UIButton alloc] init];
                         [button2 bd_setImageWithURL:originalImageURL
                                            forState:UIControlStateNormal
                                    placeholderImage:nil
                                           completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                                               XCTAssertNotNil(image);
                                           }];
                         
                         [button2 bd_cancelImageLoadForState:UIControlStateNormal];
                         
                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
                             XCTAssertNotNil([button2 imageForState:UIControlStateNormal]);
                             [expectation fulfill];
                         });
                     }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_24_button_cancel_image_from_disk {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton cancel image from disk"];
    
    [[BDImageCache sharedImageCache] clearMemory];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestPNGURL];
    
    [button bd_setImageWithURL:originalImageURL
                      forState:UIControlStateNormal
              placeholderImage:nil
                     completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                         XCTFail(@"something is wrong");
                     }];
    [button bd_cancelImageLoadForState:UIControlStateNormal];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
        XCTAssertNil([button imageForState:UIControlStateNormal]);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_25_button_cancel_backgroudImage_from_download {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton cancel backgroundImage from download"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestPNGURL];
    [self removeImageCache:originalImageURL];
    [button bd_setBackgroundImageWithURL:originalImageURL
                                forState:UIControlStateNormal
                        placeholderImage:nil
                               completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                                   XCTFail(@"something is wrong");
                               }];
    [button bd_cancelBackgroundImageLoadForState:UIControlStateNormal];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
        XCTAssertNil([button imageForState:UIControlStateNormal]);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_26_button_cancel_backgroudImage_from_memory {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton cancel backgroundImage from memory"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestPNGURL];
    
    [button bd_setBackgroundImageWithURL:originalImageURL
                                forState:UIControlStateNormal
                        placeholderImage:nil
                               completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                                   XCTAssertNotNil(image);
                                   BDImageCacheType type = [[BDImageCache sharedImageCache] containsImageForKey:[[BDWebImageManager sharedManager] requestKeyWithURL:originalImageURL] type:BDImageCacheTypeMemory];
                                   XCTAssertTrue(type & BDImageCacheTypeMemory);
                                   
                                   UIButton *button2 = [[UIButton alloc] init];
                                   [button2 bd_setBackgroundImageWithURL:originalImageURL
                                                                forState:UIControlStateNormal
                                                        placeholderImage:nil
                                                               completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                                                                   XCTAssertNotNil(image);
                                                               }];
                                   
                                   [button2 bd_cancelBackgroundImageLoadForState:UIControlStateNormal];
                                   
                                   dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
                                       XCTAssertNotNil([button2 backgroundImageForState:UIControlStateNormal]);
                                       [expectation fulfill];
                                   });
                               }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_27_button_cancel_backgroudImage_from_disk {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton cancel backgroundImage from disk"];
    
    [[BDImageCache sharedImageCache] clearMemory];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestPNGURL];
    
    [button bd_setBackgroundImageWithURL:originalImageURL
                                forState:UIControlStateNormal
                        placeholderImage:nil
                               completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                                   XCTFail(@"something is wrong");
                               }];
    [button bd_cancelBackgroundImageLoadForState:UIControlStateNormal];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMinDelayNanosecond)), dispatch_get_main_queue(), ^{
        XCTAssertNil([button imageForState:UIControlStateNormal]);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_SetBDImageViewImangeNil {
    XCTestExpectation *expectation = [self expectationWithDescription:@"correct set nil"];
    NSURL *imageURL = [NSURL URLWithString:kTestJpegURL];
    BDImageView *view = [[BDImageView alloc] init];
    [view bd_setImageWithURL:imageURL placeholder:nil options:0 completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNotNil(view.image);
        view.image = nil;
        XCTAssertNil(view.image);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_URLs_have_NSNull {
    XCTestExpectation *expectation = [self expectationWithDescription:@"URLs contain NSNull"];
    NSArray *urls = @[[NSNull null], kTestPNGURL];
    BDImageView *view = [[BDImageView alloc] init];
    [view bd_setImageWithURLs:urls
                  placeholder:nil
                      options:0
                  transformer:nil
                     progress:nil
                   completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNil(view.image);
        XCTAssertNil(image);
        XCTAssertNil(data);
        XCTAssertNotNil(error);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

@end
