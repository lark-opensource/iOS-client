//  Copyright 2023 The Lynx Authors. All rights reserved.

#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxUI.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import <XCTest/XCTest.h>
#import "BDLynxTTAudioUI.h"

@interface BDLynxTTAudioUI (Test)

- (void)setPauseOnHide:(BOOL)isPauseHide;

- (BOOL)pauseOnHide;

- (BOOL)stopLoopAfterPlayFinished;

- (void)onEnterBackground;

@end

@interface BDLynxTTAudioUnitTest : XCTestCase
@property(nonatomic, strong) BDLynxTTAudioUI *audioTT;
@end

@implementation BDLynxTTAudioUnitTest

- (void)setUp {
  self.audioTT = [[BDLynxTTAudioUI alloc] init];
  [self.audioTT updateFrame:UIScreen.mainScreen.bounds
                withPadding:UIEdgeInsetsZero
                     border:UIEdgeInsetsZero
        withLayoutAnimation:NO];
  [self.audioTT propsDidUpdate];
  [self.audioTT layoutDidFinished];
  [self.audioTT finishLayoutOperation];
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
}

- (void)testPauseOnHide {
  [LynxPropsProcessor updateProp:@YES withKey:@"pause-on-hide" forUI:self.audioTT];
  BOOL isHide = [self.audioTT pauseOnHide];
  XCTAssert(isHide == YES);
  XCTAssert(self.audioTT.stopLoopAfterPlayFinished == NO);
  [self.audioTT onEnterBackground];
  XCTAssert(self.audioTT.stopLoopAfterPlayFinished == YES);
}

@end
