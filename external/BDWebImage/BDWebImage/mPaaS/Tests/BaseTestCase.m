//
//  CommonDefine.h
//  BDWebImageTestTests
//
//  Created by zhangtianfu on 2018/12/14.
//  Copyright © 2018 zhangtianfu. All rights reserved.
//

#import "BaseTestCase.h"
#import <BDWebImage/BDWebImage.h>
#import <BDWebImage/SDWebImageAdapter.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import <OHHTTPStubs/OHHTTPStubs.h>

const int64_t kAsyncTestTimeout = 5;
const int64_t kMinDelayNanosecond = NSEC_PER_MSEC * 100; // 0.1s
NSString *const kTestJpegURL = @"http://via.placeholder.com/50x50.jpg";
NSString *const kTestPNGURL = @"http://via.placeholder.com/50x50.png";
NSString *const kTestGIFURL = @"https://media.giphy.com/media/UEsrLdv7ugRTq/giphy.gif";
NSString *const kTestWebPURL = @"http://littlesvr.ca/apng/images/SteamEngine.webp";
NSString *const kTestWebPStaticURL = @"http://littlesvr.ca/apng/images/SteamEngineStatic.webp";
NSString *const kTestFailURL = @"http://littlesvr.ca/apng/images/xxxxxx.webp";
NSString *const kTestLargeImgURL = @"https://p11.douyinpic.com/img/douyin-admin-obj/a67f70f5b8c681b25e768cf5ecde0b9b~noop.jpeg?from=1551292344";
NSString *const kTestSchemeURL = @"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==";
NSString *const kTestLargeWebPURL = @"http://www.ioncannon.net/wp-content/uploads/2011/06/test9.webp";
NSString *const kTestHeicURL = @"http://p1-dy.byteimg.com/img/tos-cn-i-0000/724f79fa839711e986b00cc47af43c90~tplv-tt-cs0:300:196.heic";
NSString *const kTestDataLengthURL = @"http://p9-tt.byteimg.com/img/pgc-image/Rk83ad932FnQb8~tplv-tt-cs0:300:196.webp";

static NSMutableDictionary *mockURLs = nil;

@implementation BaseTestCase

+ (void)initialize
{
    if (self == [BaseTestCase class]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            mockURLs = [NSMutableDictionary dictionaryWithCapacity:13];
            [mockURLs setObject:@{@"res": @"TestImage", @"type": @"jpg", @"Content-Type": @"image/jpeg"} forKey:kTestJpegURL];
            [mockURLs setObject:@{@"res": @"TestImage", @"type": @"png", @"Content-Type": @"image/png"} forKey:kTestPNGURL];
            [mockURLs setObject:@{@"res": @"TestImage", @"type": @"gif", @"Content-Type": @"image/gif"} forKey:kTestGIFURL];
            [mockURLs setObject:@{@"res": @"TestImageStatic", @"type": @"webp", @"Content-Type": @"image/webp"} forKey:kTestWebPStaticURL];
            [mockURLs setObject:@{@"res": @"TestImageAnimated", @"type": @"webp", @"Content-Type": @"image/webp"} forKey:kTestWebPURL];
            [mockURLs setObject:@{@"res": @"TestImageLarge", @"type": @"jpg", @"Content-Type": @"image/jpeg"} forKey:kTestLargeImgURL];
            [mockURLs setObject:@{@"res": @"TestImage", @"type": @"png", @"Content-Type": @"image/png"} forKey:kTestSchemeURL];
            [mockURLs setObject:@{@"res": @"testWebPLarge", @"type": @"webp", @"Content-Type": @"image/webp"} forKey:kTestLargeWebPURL];
            [mockURLs setObject:@{@"res": @"404", @"type": @"htm", @"Content-Type": @"text/html", @"X-Md5": @"123"} forKey:kTestHeicURL];
            [mockURLs setObject:@{@"res": @"TestImage", @"type": @"png", @"Content-Type": @"image/png", @"X-Length": @"123"} forKey:kTestDataLengthURL];
        });
    }
}

- (void)setUp {
    [TTNetworkManager setLibraryImpl:TTNetworkManagerImplTypeAFNetworking];
    [self createImageStub];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [OHHTTPStubs removeAllStubs];
    [[BDWebImageManager sharedManager] cancelAll];
}

/**
 *  创建Image的stub
 */
- (void)createImageStub{
    static id<OHHTTPStubsDescriptor> imageStub = nil;
    
    imageStub=[OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        BOOL filter = NO;
        NSMutableArray *urls = [mockURLs.allKeys mutableCopy];
        [urls addObjectsFromArray:@[TEST_URL_1, TEST_URL_2, TEST_URL_3, TEST_URL_4, TEST_URL_5, TEST_URL_6]];
        for (NSString *url in urls) {
            if ([request.URL.absoluteString isEqualToString:url]) {
                filter = YES;
            }
        }
        return filter;
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSDictionary *dataInfo = [mockURLs objectForKey:request.URL.absoluteString] ?: @{@"res": @"TestImage", @"type": @"jpg", @"Content-Type": @"image/jpeg"};
        NSLog(@"url = %@, res = %@.%@ content-type = %@", request.URL.absoluteString, [dataInfo objectForKey:@"res"], [dataInfo objectForKey:@"type"], [dataInfo objectForKey:@"Content-Type"]);
        NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:[dataInfo objectForKey:@"res"] ofType:[dataInfo objectForKey:@"type"]];
        NSMutableDictionary *headers = [NSMutableDictionary dictionary];
        [headers setObject:[dataInfo objectForKey:@"Content-Type"] forKey:@"Content-Type"];
        if ([dataInfo objectForKey:@"X-Md5"]) {
            [headers setObject:[dataInfo objectForKey:@"X-Md5"] forKey:@"X-Md5"];
        }
        if ([dataInfo objectForKey:@"X-Length"]) {
            [headers setObject:[dataInfo objectForKey:@"X-Length"] forKey:@"X-Length"];
        }
        return [OHHTTPStubsResponse responseWithFileAtPath:filePath statusCode:200 headers:headers];
    }];
    
    imageStub.name=@"Image stub";
}

- (void)waitForExpectationsWithCommonTimeout {
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

- (void)waitForExpectationsWithCommonTimeoutUsingHandler:(XCWaitCompletionHandler)handler {
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout handler:handler];
}

- (void)removeImageCache:(NSURL*)imageURL {
    NSString *key = [[BDWebImageManager sharedManager] requestKeyWithURL:imageURL];
    [[BDImageCache sharedImageCache] removeImageForKey:key];
}

///清除URL对应图片缓存

- (void)sdadapter_removeImageCache:(NSURL*)imageURL completion:(void(^)(void))completion { ///这个地方的代码块写法不是很明白，待弄懂
    NSString *key = [[SDWebImageAdapter sharedAdapter] cacheKeyForURL:imageURL];
    [[SDWebImageAdapter sharedAdapter] removeImageForKey:key fromDisk:YES withCompletion:^{
        if (completion != nil) {
            completion();
        }
    }];
}


@end
