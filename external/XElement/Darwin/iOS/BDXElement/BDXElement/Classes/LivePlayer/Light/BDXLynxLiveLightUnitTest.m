//  Copyright 2023 The Lynx Authors. All rights reserved.

#import <XCTest/XCTest.h>
#import "BDXLynxLiveLight.h"
#import <Lynx/LynxUI.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import <Lynx/LynxPropsProcessor.h>
#import <IESLivePlayer/IESLivePlayerLynxController.h>

@interface BDXLynxLiveLight (Test)
- (void)play:(NSDictionary *)params withResult:(LynxUIMethodCallbackBlock)callback;
- (void)stop:(NSDictionary *)params withResult:(LynxUIMethodCallbackBlock)callback;
- (void)enterLiveRoom:(NSDictionary *)params withResult:(LynxUIMethodCallbackBlock)callback;
- (IESLivePlayerControllerConfig *)liveConfig;
- (IESLivePlayerLynxController *)innerPlayer;
@end

@interface BDXLynxLiveLightUnitTest : XCTestCase
@property (nonatomic, strong) BDXLynxLiveLight *liveLite;
@end

@implementation BDXLynxLiveLightUnitTest

- (void)setUp {
  self.liveLite = [[BDXLynxLiveLight alloc] init];
  [self.liveLite updateFrame:UIScreen.mainScreen.bounds
                      withPadding:UIEdgeInsetsZero
                           border:UIEdgeInsetsZero
              withLayoutAnimation:NO];
  [self.liveLite propsDidUpdate];
  [self.liveLite layoutDidFinished];
  [self.liveLite finishLayoutOperation];
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
}

- (void)testProps {
  XCTAssertNotNil(self.liveLite.view);
  [LynxPropsProcessor updateProp:@"123" withKey:@"stream-data" forUI:self.liveLite];
  [LynxPropsProcessor updateProp:@YES withKey:@"mute" forUI:self.liveLite];
  [LynxPropsProcessor updateProp:@"contain" withKey:@"objectfit" forUI:self.liveLite];
  [LynxPropsProcessor updateProp:@"origin" withKey:@"qualities" forUI:self.liveLite];
  [LynxPropsProcessor updateProp:@"123" withKey:@"room-id" forUI:self.liveLite];
  [LynxPropsProcessor updateProp:@"biz-domain" withKey:@"biz-domain" forUI:self.liveLite];
  [LynxPropsProcessor updateProp:@"page" withKey:@"page" forUI:self.liveLite];
  [LynxPropsProcessor updateProp:@"block" withKey:@"block" forUI:self.liveLite];
  [LynxPropsProcessor updateProp:@"index" withKey:@"index" forUI:self.liveLite];
  [LynxPropsProcessor updateProp:@NO withKey:@"in-list" forUI:self.liveLite];
  [self.liveLite propsDidUpdate];
  XCTAssert([self.liveLite.liveConfig.streamData isEqualToString:@"123"]);
  XCTAssert(self.liveLite.liveConfig.muted);
  XCTAssert(self.liveLite.liveConfig.scaleType == IESLivePlayerScaleTypeAspectFit);
  XCTAssert([self.liveLite.liveConfig.sdkKey isEqualToString:@"origin"]);
  XCTAssert([self.liveLite.liveConfig.roomID isEqual:@(123)]);
  XCTAssert([self.liveLite.liveConfig.trackerConfig.stainedTrackInfo.bizDomain isEqualToString:@"biz-domain"]);
  XCTAssert([self.liveLite.liveConfig.trackerConfig.stainedTrackInfo.pageName isEqualToString:@"page"]);
  XCTAssert([self.liveLite.liveConfig.trackerConfig.stainedTrackInfo.blockName isEqualToString:@"block"]);
  XCTAssert([self.liveLite.liveConfig.trackerConfig.stainedTrackInfo.index isEqualToString:@"index"]);

//  UICollectionView *liteView = [self.viewPagerLite performSelector:@selector(viewpager)];
//  XCTAssert(liteView.contentOffset.x == 0);
//  XCTestExpectation *expectation =
//       [self expectationWithDescription:@"Testing select tab works correctly"];
//  [self.viewPagerLite selectTab:@{
//    @"index" : @(2),
//    @"smooth" : @(YES),
//  } withResult:^(int code, id  _Nullable data) {
//    XCTAssert(liteView.contentOffset.x == 2 * UIScreen.mainScreen.bounds.size.width);
//    dispatch_async(dispatch_get_main_queue(), ^{
//      [self.viewPagerLite selectTab:@{
//        @"index" : @(0),
//        @"smooth" : @(NO),
//      } withResult:^(int code, id  _Nullable data) {
//        [expectation fulfill];
//      }];
//    });
//  }];
//  XCTAssertNotNil(self.viewPagerLite.view);
//
//  [self waitForExpectationsWithTimeout:3
//                                handler:^(NSError *_Nullable error) {
//                                  XCTAssert(liteView.contentOffset.x == 0);
//                                }];
}

- (void)testMethod {
  [self.liveLite play:nil withResult:^(int code, id  _Nullable data) {
    XCTAssert(code == 0);
  }];
  [self.liveLite stop:nil withResult:^(int code, id  _Nullable data) {
    XCTAssert(code == 0);
  }];
  [self.liveLite enterLiveRoom:nil withResult:^(int code, id  _Nullable data) {
    XCTAssert(code != 0);
  }];
}

@end

