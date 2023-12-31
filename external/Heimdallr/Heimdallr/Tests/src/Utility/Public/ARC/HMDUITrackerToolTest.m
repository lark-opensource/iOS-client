//
//  HeimdallrUtilitiesTest.m
//  Pods
//
//  Created by liuhan on 2021/10/13.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <Heimdallr/HeimdallrUtilities.h>
#import "HMDUITrackerTool.h"

@interface HMDUITrackerToolTest : XCTestCase

@end

@implementation HMDUITrackerToolTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testSceneBasedSupport {
    XCTAssert(!HMDUITrackerTool.sceneBasedSupport);
}

- (void)testApplicationKeyWindow {
    fprintf(stdout, "[keyWindow] %s\n", HMDUITrackerTool.keyWindow.description.UTF8String);
    XCTAssert(HMDUITrackerTool.keyWindow == UIApplication.sharedApplication.keyWindow);
}

@end
