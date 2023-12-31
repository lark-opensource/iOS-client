//
//  BDWebImage_MonitorTest.m
//  BDWebImage_Tests
//
//  Created by 陈奕 on 2020/4/13.
//  Copyright © 2020 Bytedance.com. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BaseTestCase.h"
#import <BDWebImage/BDWebImage.h>
#import <BDWebImage/BDImageLargeSizeMonitor.h>
#import <OCMock/OCMock.h>

@interface BDImageLargeSizeMonitor (BDWebImage_MonitorTest)

- (NSString *)bd_getViewPath:(UIView *)view;

@end

@interface BDWebImage_MonitorTest : BaseTestCase

@end

@implementation BDWebImage_MonitorTest

- (void)setUp {
    [[BDWebImageManager sharedManager].imageCache clearMemory];
    [[BDWebImageManager sharedManager].imageCache clearDiskWithBlock:nil];
    [[BDWebImageManager sharedManager] cancelAll];

}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)test_01_largeImageMonitorSetting {
    BDWebImageRequest *request = [[BDWebImageManager sharedManager] requestImage:[NSURL URLWithString:kTestPNGURL] options:0 complete:NULL];
    XCTAssertTrue(request.largeImageMonitor.fileSizeLimit == 20 * 1024 * 1024);
    XCTAssertTrue(request.largeImageMonitor.memoryLimit == [[UIScreen mainScreen] bounds].size.width * UIScreen.mainScreen.scale * [[UIScreen mainScreen] bounds].size.height * UIScreen.mainScreen.scale * 4);
    XCTAssertFalse(request.largeImageMonitor.monitorEnable);
    
    BDWebImageRequest.isMonitorLargeImage = YES;
    BDWebImageRequest.largeImageFileSizeLimit = 10 * 1024 * 1024;
    BDWebImageRequest.largeImageMemoryLimit = 1440 * 810 * 4;
    request = [[BDWebImageManager sharedManager] requestImage:[NSURL URLWithString:kTestPNGURL] options:0 complete:NULL];
    XCTAssertTrue(request.largeImageMonitor.fileSizeLimit == 10 * 1024 * 1024);
    XCTAssertTrue(request.largeImageMonitor.memoryLimit == 1440 * 810 * 4);
    XCTAssertTrue(request.largeImageMonitor.monitorEnable);
}

- (void)test_02_viewInfo {
    UIButton *button = [UIButton new];
    UIViewController *vc = [UIViewController new];
    [vc.view addSubview:button];
    UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:vc];
    NSLog(@"child vc count = %ld", nvc.childViewControllers.count);
    
    BDImageLargeSizeMonitor *monitor = [BDImageLargeSizeMonitor new];
    NSString *viewInfo = [monitor bd_getViewPath:button.imageView];
    XCTAssertTrue([@"UIViewController/UIView[0]/UIButton[0]/UIImageView[0]" isEqualToString:viewInfo]);
}

- (void)test_03_trackLargeImage {
    BDWebImageRequest.isMonitorLargeImage = YES;
    XCTestExpectation *expectation = [self expectationWithDescription:@"correct download"];
    id monitorMock = OCMClassMock([BDImageMonitorManager class]);
    OCMStub([monitorMock trackData:[OCMArg any] logTypeStr:@"image_monitor_exceed_limit_v2"]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });;
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:(CGRect){0, 0, 10000, 10000}];
    [imageView bd_setImageWithURL:[NSURL URLWithString:kTestLargeImgURL]];
    [self waitForExpectationsWithCommonTimeout];
}



@end
