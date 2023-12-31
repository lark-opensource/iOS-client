//
//  CrashSanitizerTest.m
//  LarkCrashSanitizerDevEEUnitTest
//
//  Created by huangjianming on 2020/2/19.
//

#import <XCTest/XCTest.h>
#import "NSObject+WKBackGroundCrash.h"
#import <objc/runtime.h>
#import <LarkFoundation/LKEncryptionTool.h>
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVFAudio.h>
#import <QuartzCore/QuartzCore.h>
#import <LarkCrashSanitizer/LarkCrashSanitizer-Swift.h>

static NSString * const notifyAdjust = @"_oqwmk\"Hls\"~#rrR\"\")x%,_(.~1_($a*$2,+";
@interface CrashSanitizerTest : XCTestCase

@end

@implementation CrashSanitizerTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testInitFix {
    Class instanceClass = NSClassFromString(@"WKTaskManager");
    XCTAssertNoThrow([[instanceClass alloc] init], @"异常");
}

- (void)testSwiftKVO {
    XCTAssertNoThrow([[WMFSwiftKVOCrashWorkaround new] performWorkaround], @"异常");
}

- (void)testExample {

    SEL sel = NSSelectorFromString([LKEncryptionTool decryptString:notifyAdjust]);
    UIScrollView *scrollView = [UIScrollView new];
    [scrollView performSelector:sel];
}

- (void)testSetBounds {
    CALayer *layer = [CALayer layer];
    XCTAssertNoThrow([layer setBounds: CGRectZero], @"异常");
}

- (void)testAVPlayer {
    AVPlayer *player = [AVPlayer new];
    XCTAssertNoThrow([player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL], @"异常");
}

- (void)testAVPlayerItem {
    AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:@""]];
    XCTAssertNoThrow([item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL], @"异常");
}

- (void)testUIViewController{
    UIViewController *vc = [[UIViewController alloc]init];
    XCTAssertNoThrow([vc viewDidAppear:YES], @"异常");
    XCTAssertNoThrow([vc viewDidDisappear:YES], @"异常");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
