//
//  CommonDefine.h
//  BDWebImageTestTests
//
//  Created by zhangtianfu on 2018/12/14.
//  Copyright © 2018 zhangtianfu. All rights reserved.
//

#import <XCTest/XCTest.h>

FOUNDATION_EXPORT const int64_t kAsyncTestTimeout;  // 5s
FOUNDATION_EXPORT const int64_t kMinDelayNanosecond;// 0.1
FOUNDATION_EXPORT NSString * _Nonnull const kTestJpegURL;
FOUNDATION_EXPORT NSString * _Nonnull const kTestPNGURL;
FOUNDATION_EXPORT NSString * _Nonnull const kTestGIFURL;
FOUNDATION_EXPORT NSString * _Nonnull const kTestWebPURL;
FOUNDATION_EXPORT NSString * _Nonnull const kTestFailURL;
FOUNDATION_EXPORT NSString * _Nonnull const kTestLargeImgURL;
FOUNDATION_EXPORT NSString * _Nonnull const kTestHeicURL;
FOUNDATION_EXPORT NSString * _Nonnull const kTestDataLengthURL;
FOUNDATION_EXPORT NSString * _Nonnull const kTestLargeWebPURL;
FOUNDATION_EXPORT NSString * _Nonnull const kTestWebPStaticURL;

#define TEST_URL_1 @"http://via.placeholder.com/20x20.jpg"
#define TEST_URL_2 @"http://via.placeholder.com/30x30.jpg"
#define TEST_URL_3 @"http://via.placeholder.com/40x40.jpg"
#define TEST_URL_4 @"http://via.placeholder.com/50x50.jpg"
#define TEST_URL_5 @"http://via.placeholder.com/60x60.jpg"
#define TEST_URL_6 @"http://via.placeholder.com/70x70.jpg"

@interface BaseTestCase : XCTestCase

- (void)waitForExpectationsWithCommonTimeout;
- (void)waitForExpectationsWithCommonTimeoutUsingHandler:(nullable XCWaitCompletionHandler)handler;

- (void)removeImageCache:(NSURL *_Nullable)imageURL;
- (void)sdadapter_removeImageCache:(NSURL *_Nullable)imageURL completion:(void(^ _Nullable)(void))completion;

@end
