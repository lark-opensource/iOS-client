//
//  CommonDefine.m
//  BDWebImageTestTests
//
//  Created by zhangtianfu on 2018/12/14.
//  Copyright © 2018 zhangtianfu. All rights reserved.
//

#import "BaseTestCase.h"
#import <BDWebImage/BDWebImage.h>

#import <TTNetworkManager/TTNetworkManager.h>
#import <OHHTTPStubs/OHHTTPStubs.h>


@interface BDWebImageManager(DownloadTests)

- (id<BDWebImageDownloader>)downloadManagerFromOption:(BDImageRequestOptions)option;

@end

@interface BDWebImageRequest(DownloadTests)

+ (NSMutableArray *)defaultRetryErrorCodes;
+ (BOOL)needRetryByHttps:(NSInteger)code;

@end

@interface BDWebImage_DownloaderTests : BaseTestCase

@end

@implementation BDWebImage_DownloaderTests

- (void)setUp {
    [[BDWebImageManager sharedManager].imageCache.diskCache removeAllData];
    [[BDWebImageManager sharedManager].imageCache.memoryCache removeAllObjects];

    [super setUp];
}

- (void)test_01_checkDownloaderManager {
    [TTNetworkManager setLibraryImpl:TTNetworkManagerImplTypeLibChromium];
    NSObject *manager = [[BDWebImageManager sharedManager] downloadManagerFromOption:BDImageRequestDefaultPriority];
    
#if BDWEBIMAGE_APP_EXTENSIONS == 1
    XCTAssertTrue([NSStringFromClass([manager class]) isEqualToString:@"BDDownloadURLSessionManager"]);
#else
    XCTAssertTrue([NSStringFromClass([manager class]) isEqualToString:@"BDDownloadManager"]);
#endif

    NSObject *manager2 = [[BDWebImageManager sharedManager] downloadManagerFromOption:BDImageProgressiveDownload];
    XCTAssertTrue([NSStringFromClass([manager2 class]) isEqualToString:@"BDDownloadManager"]);
    
    [TTNetworkManager setLibraryImpl:TTNetworkManagerImplTypeAFNetworking];
    NSObject *manager3 = [[BDWebImageManager sharedManager] downloadManagerFromOption:BDImageProgressiveDownload];
    XCTAssertTrue([NSStringFromClass([manager3 class]) isEqualToString:@"BDDownloadURLSessionManager"]);
}

- (void)test_02_SimpleDownloadWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple download"];
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

- (void)test_03_SetAndGetMaxConcurrentDownloadsWorks {
    BDDownloadManager *downloadManager = [[BDWebImageManager sharedManager] downloadManagerFromOption:BDImageRequestDefaultPriority];
    
    NSInteger initialValue = downloadManager.maxConcurrentTaskCount;
    downloadManager.maxConcurrentTaskCount = 3;
    XCTAssertEqual(downloadManager.maxConcurrentTaskCount, 3);
    
    downloadManager.maxConcurrentTaskCount = initialValue;
}

- (void)test_04_UsingACustomDownloaderOperationWorks {
    BDDownloadManager *downloadManager = [[BDWebImageManager sharedManager] downloadManagerFromOption:BDImageRequestDefaultPriority];

    NSString *className = NSStringFromClass([downloadManager class]);
    if ([className isEqualToString:@"BDDownloadManager"]) {
        XCTAssertTrue([NSStringFromClass(downloadManager.downloadTaskClass) isEqualToString:@"BDDownloadChromiumTask"]);
    } else {
        XCTAssertTrue([NSStringFromClass(downloadManager.downloadTaskClass) isEqualToString:@"BDDownloadURLSessionTask"]);
    }
}

- (void)test_05_DownloadImageWithNilURLCallsCompletionWithNils {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion is called with nils"];
    [[BDWebImageManager sharedManager] requestImage:nil options:0 complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNil(image);
        XCTAssertNil(data);
        XCTAssertNotNil(error);
        XCTAssertEqual(from, BDWebImageResultFromNone);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_06_ProgressiveJPEGWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Progressive JPEG download"];
    NSURL *imageURL = [NSURL URLWithString:kTestJpegURL];
    [self removeImageCache:imageURL];

    [[BDWebImageManager sharedManager] requestImage:imageURL options:BDImageStaticImageProgressiveDownload complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNotNil(image);
        XCTAssertNotNil(data);
        XCTAssertNil(error);
        XCTAssertEqual(from, BDWebImageResultFromDownloading);
        if (request.finished) {
            [expectation fulfill];
        }
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_07_404CaseCallsCompletionWithError {
    NSURL *imageURL = [NSURL URLWithString:@"http://static2.dmcdn.net/static/video/656/177/44771656:jpeg_preview_small.jpg?20120509154705"];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"404"];
    [[BDWebImageManager sharedManager] requestImage:imageURL options:BDImageProgressiveDownload complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        if (!image && !data && error) {
            [expectation fulfill];
        } else {
            XCTFail(@"Something went wrong");
        }
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_08_CancelWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Cancel"];
    
    NSURL *imageURL = [NSURL URLWithString:kTestJpegURL];

    [[BDImageCache sharedImageCache] clearMemory];
    [[BDImageCache sharedImageCache] clearDiskWithBlock:^{
        BDWebImageRequest *request = [[BDWebImageManager sharedManager] requestImage:imageURL options:0 complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            XCTFail(@"Should not get here");
        }];
        
        // 需要进入下载才会添加任务，所以无法同步得到刚出发loadimage的任务，得到为0
        BDDownloadManager *downloadManager = [[BDWebImageManager sharedManager] downloadManagerFromOption:BDImageRequestDefaultPriority];
//        XCTAssertEqual(downloadManager.allTasks.count, 1);
        
        [request cancel];
        
        // doesn't cancel immediately - since it uses dispatch async
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kMinDelayNanosecond), dispatch_get_main_queue(), ^{
            XCTAssertEqual(downloadManager.allTasks.count, 0);
            [expectation fulfill];
        });
    }];

    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_09_DownloadCanContinueWhenTheAppEntersBackground {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple download entersBackgroud"];
    NSURL *imageURL = [NSURL URLWithString:kTestJpegURL];
    [self removeImageCache:imageURL];
    [[BDWebImageManager sharedManager] requestImage:imageURL options:BDImageRequestContinueInBackground complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNotNil(image);
        XCTAssertNotNil(data);
        XCTAssertNil(error);
        XCTAssertEqual(from, BDWebImageResultFromDownloading);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_10_PNG {
    XCTestExpectation *expectation = [self expectationWithDescription:@"PNG"];
    NSURL *imageURL = [NSURL URLWithString:kTestPNGURL];
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

- (void)test_11_WEBP {
    XCTestExpectation *expectation = [self expectationWithDescription:@"WEBP"];
    NSURL *imageURL = [NSURL URLWithString:kTestWebPURL];
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

- (void)test_12_WEBP_Progressive {
    XCTestExpectation *expectation = [self expectationWithDescription:@"WEBP Progressive"];
    NSURL *imageURL = [NSURL URLWithString:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test9.webp"];
    [self removeImageCache:imageURL];
    [[BDWebImageManager sharedManager] requestImage:imageURL options:BDImageProgressiveDownload complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNotNil(image);
        XCTAssertNotNil(data);
        XCTAssertNil(error);
        XCTAssertEqual(from, BDWebImageResultFromDownloading);
        if (request.isFinished) {
            [expectation fulfill];
        }
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_13_DownloadingSameURLTwiceAndCancellingFirstWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Correct image downloads"];
    NSURL *imageURL = [NSURL URLWithString:kTestJpegURL];
    [self removeImageCache:imageURL];
    
    BDWebImageRequest *request1 = [[BDWebImageManager sharedManager] requestImage:imageURL options:0 complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTFail(@"Shouldn't have completed here.");
    }];
    XCTAssertNotNil(request1);
    
    BDWebImageRequest *request2 = [[BDWebImageManager sharedManager] requestImage:imageURL options:0 complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNotNil(image);
        XCTAssertNotNil(data);
        XCTAssertNil(error);
        XCTAssertEqual(from, BDWebImageResultFromDownloading);
        [expectation fulfill];
    }];
    XCTAssertNotNil(request2);
    
    [request1 cancel];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_14_CancelingDownloadThenRequestingAgainWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Correct image downloads"];
    NSURL *imageURL = [NSURL URLWithString:kTestJpegURL];
    [self removeImageCache:imageURL];
    
    BDWebImageRequest *request1 = [[BDWebImageManager sharedManager] requestImage:imageURL options:0 complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTFail(@"Shouldn't have completed here.");
    }];
    XCTAssertNotNil(request1);
    [request1 cancel];
    
    BDWebImageRequest *request2 = [[BDWebImageManager sharedManager] requestImage:imageURL options:0 complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNotNil(image);
        XCTAssertNotNil(data);
        XCTAssertNil(error);
        XCTAssertEqual(from, BDWebImageResultFromDownloading);
        [expectation fulfill];
    }];
    XCTAssertNotNil(request2);
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_15_GetDataAndIgnoreImageWithoutCache {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Correct image downloads"];
    NSURL *imageURL = [NSURL URLWithString:kTestJpegURL];
    [self removeImageCache:imageURL];
    
    BDWebImageRequest *request1 = [[BDWebImageManager sharedManager] requestImage:imageURL options:BDImageRequestIgnoreImage complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNil(image);
        XCTAssertNotNil(data);
        XCTAssertNil(error);
        XCTAssertEqual(from, BDWebImageResultFromDownloading);
        [expectation fulfill];
    }];
    XCTAssertNotNil(request1);
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_16_GetDataAndIgnoreImageWithCache {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Correct image downloads"];
    NSURL *imageURL = [NSURL URLWithString:kTestJpegURL];
    [self removeImageCache:imageURL];
    
    BDWebImageRequest *request1 = [[BDWebImageManager sharedManager] requestImage:imageURL options:0 complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNotNil(image);
        XCTAssertNotNil(data);
        XCTAssertNil(error);
        XCTAssertEqual(from, BDWebImageResultFromDownloading);
        BDWebImageRequest *request2 = [[BDWebImageManager sharedManager] requestImage:imageURL options:BDImageRequestIgnoreImage complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            XCTAssertNil(image);
            XCTAssertNotNil(data);
            XCTAssertNil(error);
            XCTAssertEqual(from, BDWebImageResultFromDownloading);
            [expectation fulfill];
        }];
        XCTAssertNotNil(request2);
        
    }];
    XCTAssertNotNil(request1);
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_17_GetDataPathAndIgnoreImageWithoutCache {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Correct image downloads"];
    NSURL *imageURL = [NSURL URLWithString:kTestJpegURL];
    [self removeImageCache:imageURL];
    
    BDWebImageRequest *request1 = [[BDWebImageManager sharedManager] requestImage:imageURL options:BDImageRequestIgnoreImage|BDImageRequestNeedCachePath complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNil(image);
        XCTAssertNotNil(data);
        XCTAssertNotNil(request.cachePath);
        XCTAssertNil(error);
        XCTAssertEqual(from, BDWebImageResultFromDownloading);
        [expectation fulfill];
    }];
    XCTAssertNotNil(request1);
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_18_GetDataPathAndIgnoreImageWithCache {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Correct image downloads"];
    NSURL *imageURL = [NSURL URLWithString:kTestJpegURL];
    [self removeImageCache:imageURL];
    
    BDWebImageRequest *request1 = [[BDWebImageManager sharedManager] requestImage:imageURL options:0 complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNotNil(image);
        XCTAssertNotNil(data);
        XCTAssertNil(error);
        XCTAssertEqual(from, BDWebImageResultFromDownloading);
        BDWebImageRequest *request2 = [[BDWebImageManager sharedManager] requestImage:imageURL options:BDImageRequestIgnoreImage|BDImageRequestNeedCachePath complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            XCTAssertNil(image);
            XCTAssertNotNil(data);
            XCTAssertNotNil(request.cachePath);
            XCTAssertNil(error);
            XCTAssertEqual(from, BDWebImageResultFromDiskCache);
            [expectation fulfill];
        }];
        XCTAssertNotNil(request2);
        
    }];
    XCTAssertNotNil(request1);
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_19_DownloadWithTimeoutInternalAndNoRetry{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Timeout correctly"];
    NSURL *imageURL = [NSURL URLWithString:kTestFailURL];
    [self removeImageCache:imageURL];
    
    int timeout = 5;
    
    BDWebImageRequest *request = [[BDWebImageManager sharedManager] requestImage:imageURL
                                                                  alternativeURLs:nil
                                                                          options:BDImageNoRetry
                                                                  timeoutInterval:timeout
                                                                        cacheName:nil
                                                                      transformer:nil
                                                                         progress:nil complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNil(image);
        XCTAssertNil(data);
        XCTAssertNotNil(error);
        XCTAssertFalse([request performSelector:@selector(canRetryWithError:) withObject:error]);
        [expectation fulfill];
    }];
    XCTAssertNotNil(request);
    
    [self waitForExpectations:@[expectation] timeout:timeout + 1];
}

- (void)test_20_GetDataAndIgnoreImageWithoutMemoryCache {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Correct image downloads"];
    NSURL *imageURL = [NSURL URLWithString:kTestJpegURL];
    [self removeImageCache:imageURL];
    
    BDWebImageRequest *request1 = [[BDWebImageManager sharedManager] requestImage:imageURL options:0 complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNotNil(image);
        XCTAssertNotNil(data);
        XCTAssertNil(error);
        XCTAssertEqual(from, BDWebImageResultFromDownloading);
        BDWebImageRequest *request2 = [[BDWebImageManager sharedManager] requestImage:imageURL options:BDImageRequestNeedCachePath | BDImageRequestIgnoreImage complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            XCTAssertNil(image);
            XCTAssertNotNil(data);
            XCTAssertNil(error);
            XCTAssertEqual(from, BDWebImageResultFromDiskCache);
            [expectation fulfill];
        }];
        XCTAssertNotNil(request2);
        
    }];
    XCTAssertNotNil(request1);
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_21_GetDataAndIgnoreImageWithCache {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Correct image downloads"];
    NSURL *imageURL = [NSURL URLWithString:kTestJpegURL];
    [self removeImageCache:imageURL];
    
    BDWebImageRequest *request1 = [[BDWebImageManager sharedManager] requestImage:imageURL options:0 complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNotNil(image);
        XCTAssertNotNil(data);
        XCTAssertNil(error);
        XCTAssertEqual(from, BDWebImageResultFromDownloading);
        [[BDImageCache sharedImageCache].memoryCache removeAllObjects];
        BDWebImageRequest *request2 = [[BDWebImageManager sharedManager] requestImage:imageURL options:BDImageRequestIgnoreDiskCache complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            XCTAssertNotNil(image);
            XCTAssertNotNil(data);
            XCTAssertNil(error);
            XCTAssertEqual(from, BDWebImageResultFromDownloading);
            XCTAssert([[BDImageCache sharedImageCache].memoryCache containsObjectForKey:request.requestKey]);
            [expectation fulfill];
        }];
        XCTAssertNotNil(request2);
        
    }];
    XCTAssertNotNil(request1);
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_22_DownloadCheckType {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Correct image downloads"];
    NSURL *imageURL = [NSURL URLWithString:kTestHeicURL];
    [self removeImageCache:imageURL];
    [BDWebImageManager sharedManager].checkMimeType = YES;
    BDWebImageRequest *request1 = [[BDWebImageManager sharedManager] requestImage:imageURL options:0 complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertTrue([request.currentRequestURL.absoluteString hasPrefix:@"https://"]);
        [expectation fulfill];
    }];
    XCTAssertNotNil(request1);
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_23_DownloadCheckType {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Correct image downloads"];
    NSURL *imageURL = [NSURL URLWithString:kTestHeicURL];
    [self removeImageCache:imageURL];
    [BDWebImageManager sharedManager].checkMimeType = NO;
    BDWebImageRequest *request1 = [[BDWebImageManager sharedManager] requestImage:imageURL options:0 complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertTrue([request.currentRequestURL.absoluteString hasPrefix:@"http://"]);
        [expectation fulfill];
    }];
    XCTAssertNotNil(request1);
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_24_ErrorCodeRetry {
    NSArray *codes = [BDWebImageRequest defaultRetryErrorCodes];
    XCTAssertTrue([codes containsObject:@(900007)]);
    XCTAssertTrue([codes containsObject:@(-324)]);
    XCTAssertTrue([codes containsObject:@(-324)]);
    XCTAssertTrue([codes containsObject:@(-102)]);
    [BDWebImageRequest addRetryErrorCode:-10000];
    [BDWebImageRequest addRetryErrorCode:-10000];
    XCTAssertTrue([BDWebImageRequest needRetryByHttps:-10000]);
    XCTAssertTrue([BDWebImageRequest needRetryByHttps:NSURLErrorZeroByteResource]);
    [BDWebImageRequest removeRetryErrorCode:-10000];
    [BDWebImageRequest removeRetryErrorCode:11];
    XCTAssertTrue([BDWebImageRequest needRetryByHttps:BDWebImageCheckTypeError]);
    XCTAssertFalse([BDWebImageRequest needRetryByHttps:-10000]);
}

- (void)test_25_DownloadCheckDataLength {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Correct image downloads"];
    NSURL *imageURL = [NSURL URLWithString:kTestDataLengthURL];
    [self removeImageCache:imageURL];
    [BDWebImageManager sharedManager].checkDataLength = YES;
    BDWebImageRequest *request1 = [[BDWebImageManager sharedManager] requestImage:imageURL options:0 complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertTrue([request.currentRequestURL.absoluteString hasPrefix:@"https://"]);
        [expectation fulfill];
    }];
    XCTAssertNotNil(request1);
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_26_DownloadCheckDataLength {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Correct image downloads"];
    NSURL *imageURL = [NSURL URLWithString:kTestDataLengthURL];
    [self removeImageCache:imageURL];
    [BDWebImageManager sharedManager].checkDataLength = NO;
    BDWebImageRequest *request1 = [[BDWebImageManager sharedManager] requestImage:imageURL options:0 complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertTrue([request.currentRequestURL.absoluteString hasPrefix:@"http://"]);
        [expectation fulfill];
    }];
    XCTAssertNotNil(request1);
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_27_downloadCount {
    BDDownloadManager *manager = [[BDWebImageManager sharedManager] downloadManagerFromOption:BDImageRequestIgnoreCache];
    [BDWebImageManager sharedManager].maxConcurrentTaskCount = 2;
    [@[kTestPNGURL, kTestGIFURL, kTestJpegURL, kTestPNGURL] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [[BDWebImageManager sharedManager] requestImage:[NSURL URLWithString:obj] options:BDImageRequestIgnoreCache complete:nil];
    }];
    XCTAssertTrue(manager.allTasks.count == 3);
    NSInteger exeCount = 0;
    for (BDDownloadTask *task in manager.allTasks) {
        if (task.isExecuting) {
            exeCount++;
        }
    }
    XCTAssertTrue(exeCount == 2);
}

- (void)test_28_downloadCountCancel {
    BDDownloadManager *manager = [[BDWebImageManager sharedManager] downloadManagerFromOption:BDImageRequestIgnoreCache];
    [BDWebImageManager sharedManager].maxConcurrentTaskCount = 2;

    NSMutableArray *requests = [NSMutableArray array];
    [@[kTestPNGURL, kTestGIFURL, kTestJpegURL, kTestWebPURL] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [requests addObject:[[BDWebImageManager sharedManager] requestImage:[NSURL URLWithString:obj] options:BDImageRequestIgnoreCache complete:nil]];
    }];
    [[BDWebImageManager sharedManager] requestImage:[NSURL URLWithString:kTestWebPURL] options:BDImageRequestIgnoreCache|BDImageAnimatedImageProgressiveDownload complete:nil];
    XCTAssertTrue(manager.allTasks.count == 4);
    for (BDWebImageRequest *request in requests) {
        NSString *url = request.currentRequestURL.absoluteString;
        if ([url isEqualToString:kTestPNGURL] || [url isEqualToString:kTestJpegURL]) {
            [request cancel];
        }
    }
    [[BDWebImageManager sharedManager] requestImage:[NSURL URLWithString:kTestPNGURL] options:BDImageRequestIgnoreCache complete:nil];
    [[BDWebImageManager sharedManager] requestImage:[NSURL URLWithString:kTestGIFURL] options:BDImageRequestIgnoreCache|BDImageAnimatedImageProgressiveDownload complete:nil];
    XCTAssertTrue(manager.allTasks.count == 3);
    
    NSMutableArray *exeTasks = [NSMutableArray array];
    for (BDDownloadTask *task in manager.allTasks) {
        if (task.isExecuting) {
            [exeTasks addObject:task.url.absoluteString];
        }
        if ([task.url.absoluteString isEqualToString:kTestGIFURL]) {
            XCTAssertFalse(task.isProgressiveDownload);
        }
        if ([task.url.absoluteString isEqualToString:kTestWebPURL]) {
            XCTAssertTrue(task.isProgressiveDownload);
        }
    }
    XCTAssertTrue(exeTasks.count == 2);
    XCTAssertTrue([exeTasks containsObject:kTestGIFURL]);
    XCTAssertTrue([exeTasks containsObject:kTestWebPURL]);
}

- (void)test_29_downloadCancelAll {
    BDDownloadManager *manager = [[BDWebImageManager sharedManager] downloadManagerFromOption:BDImageRequestIgnoreCache];
    [BDWebImageManager sharedManager].maxConcurrentTaskCount = 2;
    [@[kTestPNGURL, kTestGIFURL, kTestJpegURL, kTestPNGURL] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [[BDWebImageManager sharedManager] requestImage:[NSURL URLWithString:obj] options:BDImageRequestIgnoreCache complete:nil];
    }];
    XCTAssertTrue(manager.allTasks.count == 3);
    [[BDWebImageManager sharedManager] cancelAll];
    NSInteger exeCount = 0;
    for (BDDownloadTask *task in manager.allTasks) {
        if (task.isExecuting) {
            exeCount++;
        }
    }
    XCTAssertTrue(manager.allTasks.count == 0);
    XCTAssertTrue(exeCount == 0);
}

- (void)test_30_downloadFinish {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Correct image downloads"];
    
    BDDownloadManager *manager = [[BDWebImageManager sharedManager] downloadManagerFromOption:BDImageRequestIgnoreCache];
    [BDWebImageManager sharedManager].maxConcurrentTaskCount = 1;
    [[BDWebImageManager sharedManager] requestImage:[NSURL URLWithString:kTestPNGURL] options:BDImageRequestIgnoreCache complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertTrue(manager.allTasks.count == 2);
        NSMutableArray *exeTasks = [NSMutableArray array];
        for (BDDownloadTask *task in manager.allTasks) {
            if (task.isExecuting) {
                [exeTasks addObject:task.url.absoluteString];
            }
        }
        XCTAssertTrue(exeTasks.count == 1);
        XCTAssertTrue([exeTasks containsObject:kTestLargeImgURL]);
        [BDWebImageManager sharedManager].maxConcurrentTaskCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
        [expectation fulfill];
    }];
    [@[kTestLargeImgURL, kTestJpegURL, kTestPNGURL] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [[BDWebImageManager sharedManager] requestImage:[NSURL URLWithString:obj] options:BDImageRequestIgnoreCache|BDImageRequestLowPriority complete:nil];
    }];
    XCTAssertTrue(manager.allTasks.count == 3);
    NSInteger exeCount = 0;
    for (BDDownloadTask *task in manager.allTasks) {
        if (task.isExecuting) {
            exeCount++;
        }
    }
    XCTAssertTrue(exeCount == 1);
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_DisableDecodeForDisplay {
    XCTestExpectation *expectation = [self expectationWithDescription:@"PNG"];
    NSURL *imageURL = [NSURL URLWithString:kTestPNGURL];
    [self removeImageCache:imageURL];
    [[BDWebImageManager sharedManager] requestImage:imageURL options:BDImageNotDecoderForDisplay complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNotNil(image);
        XCTAssertNotNil(data);
        XCTAssertNil(error);
        XCTAssertEqual(from, BDWebImageResultFromDownloading);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_ScaleDownLargeJPEG {
    XCTestExpectation *expectation = [self expectationWithDescription:@"correct download"];
    NSURL *imageURL = [NSURL URLWithString:kTestLargeImgURL];
    
    [self removeImageCache:imageURL];
    
    [[BDWebImageManager sharedManager] requestImage:imageURL options:BDImageScaleDownLargeImages complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNotNil(image);
        XCTAssertTrue(image.bd_isDidScaleDown);
        XCTAssertNotNil(data);
        XCTAssertNil(error);
        XCTAssertEqual(from, BDWebImageResultFromDownloading);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_fileSchemeImage {
    XCTestExpectation *expectation = [self expectationWithDescription:@"data scheme"];
    NSString *path = [[NSBundle bundleForClass:self.class] pathForResource:@"TestImage" ofType:@"gif"];

    [[BDWebImageManager sharedManager] requestImage:[NSURL fileURLWithPath:path] options:0 complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNotNil(image);
        XCTAssertNotNil(data);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test_dataSchemeImage {
    XCTestExpectation *expectation = [self expectationWithDescription:@"data scheme"];
    NSString *URLString = @"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==";
    [[BDWebImageManager sharedManager] requestImage:[NSURL URLWithString:URLString] options:0 complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNotNil(image);
        XCTAssertNotNil(data);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

-(void)test_multiTransformReqs {
    XCTestExpectation *expectation = [self expectationWithDescription:@"multi transform reqs"];
    expectation.expectedFulfillmentCount = 3;
    BDRoundCornerTransformer *transform = [BDRoundCornerTransformer transformerWithImageSize:BDRoundCornerImageSize16];
    NSURL *imageURL = [NSURL URLWithString:kTestPNGURL];
    [[BDWebImageManager sharedManager] requestImage:imageURL alternativeURLs:nil options:0 cacheName:nil transformer:transform progress:nil complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNotNil(image);
        XCTAssertNotNil(data);
        XCTAssertTrue(image.size.height == 16);
        if (image.size.height == 16) {
            [expectation fulfill];
        }
    }];
    BDRoundCornerTransformer *transform2 = [BDRoundCornerTransformer transformerWithImageSize:BDRoundCornerImageSize30];
    [[BDWebImageManager sharedManager] requestImage:imageURL alternativeURLs:nil options:0 cacheName:nil transformer:transform2 progress:nil complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNotNil(image);
        XCTAssertNotNil(data);
        XCTAssertTrue(image.size.height == 30);
        if (image.size.height == 30) {
            [expectation fulfill];
        }
    }];
    BDRoundCornerTransformer *transform3 = [BDRoundCornerTransformer transformerWithImageSize:BDRoundCornerImageSize40];
    [[BDWebImageManager sharedManager] requestImage:imageURL alternativeURLs:nil options:0 cacheName:nil transformer:transform3 progress:nil complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        XCTAssertNotNil(image);
        XCTAssertNotNil(data);
        XCTAssertTrue(image.size.height == 40);
        if (image.size.height == 40) {
            [expectation fulfill];
        }
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

/*

- (void)test22ThatCustomDecoderWorksForImageDownload {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Custom decoder for SDWebImageDownloader not works"];
    SDWebImageDownloader *downloader = [[SDWebImageDownloader alloc] init];
    SDWebImageTestDecoder *testDecoder = [[SDWebImageTestDecoder alloc] init];
    [[SDWebImageCodersManager sharedInstance] addCoder:testDecoder];
    NSURL * testImageURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImage" withExtension:@"png"];
    
    // Decoded result is JPEG
    NSString *testJPEGImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *testJPEGImage = [UIImage imageWithContentsOfFile:testJPEGImagePath];
    
    [downloader downloadImageWithURL:testImageURL options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        NSData *data1 = UIImagePNGRepresentation(testJPEGImage);
        NSData *data2 = UIImagePNGRepresentation(image);
        if (![data1 isEqualToData:data2]) {
            XCTFail(@"The image data is not equal to cutom decoder, check -[SDWebImageTestDecoder decodedImageWithData:]");
        }
        NSString *str1 = @"TestDecompress";
        NSString *str2 = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (![str1 isEqualToString:str2]) {
            XCTFail(@"The image data is not modified by the custom decoder, check -[SDWebImageTestDecoder decompressedImageWithImage:data:options:]");
        }
        [[SDWebImageCodersManager sharedInstance] removeCoder:testDecoder];
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
    [downloader invalidateSessionAndCancel:YES];
}
*/

@end

