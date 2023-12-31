//  Copyright 2023 The Lynx Authors. All rights reserved.

#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxUI.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import <XCTest/XCTest.h>
#import "BDXAlphaVideoLynxUI.h"
#import "BDXAlphaVideoUI.h"

@interface BDXAlphaVideoLynxUI (Test)
@property (nonatomic) BDXAlphaVideoUI *videoUI;
- (void)seek:(NSDictionary *)params withResult:(LynxUIMethodCallbackBlock)callback;
LYNX_PROP_DEFINE("ios-async-render", iosAsyncRender, BOOL);
@end

@interface BDXAlphaVideoUI (Test)
@property (nonatomic) BOOL enableAsyncRender;
@end

@interface BDXAlphaVideoLynxUIUnitTest : XCTestCase
@property(nonatomic, strong) BDXAlphaVideoLynxUI *alphaVideo;
@end

@implementation BDXAlphaVideoLynxUIUnitTest

- (void)setUp {
  self.alphaVideo = [[BDXAlphaVideoLynxUI alloc] init];
  [self.alphaVideo updateFrame:UIScreen.mainScreen.bounds
                withPadding:UIEdgeInsetsZero
                     border:UIEdgeInsetsZero
        withLayoutAnimation:NO];
  [self.alphaVideo propsDidUpdate];
  [self.alphaVideo layoutDidFinished];
  [self.alphaVideo finishLayoutOperation];
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
}

- (void)testSeek {
  XCTAssertNotNil(self.alphaVideo.view);
  [self.alphaVideo seek:nil withResult:^(int code, id  _Nullable data) {
    XCTAssertEqual(code, kUIMethodParamInvalid);
  }];
  NSDictionary *dictionary = @{
      @"key": @400
  };
  [self.alphaVideo seek:dictionary withResult:^(int code, id  _Nullable data) {
    XCTAssertEqual(code, kUIMethodParamInvalid);
  }];
  NSDictionary *dictionary1 = @{
      @"ms": @400
  };
  [self.alphaVideo seek:dictionary1 withResult:^(int code, id  _Nullable data) {
    XCTAssertEqual(code, kUIMethodSuccess);
  }];
}

- (void)testAsyncRender {
  XCTAssertFalse(self.alphaVideo.videoUI.enableAsyncRender);
  [self.alphaVideo iosAsyncRender:YES requestReset:YES];
  XCTAssertTrue(self.alphaVideo.videoUI.enableAsyncRender);
}

@end
