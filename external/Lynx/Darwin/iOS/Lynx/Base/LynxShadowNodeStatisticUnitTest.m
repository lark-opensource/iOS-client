//  Copyright 2023 The Lynx Authors. All rights reserved.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "LynxEnv.h"
#import "LynxShadowNodeOwner.h"
#import "LynxTemplateRender.h"
#import "LynxUIOwner.h"

@interface LynxShadowNodeStatisticUnitTest : XCTestCase

@end

@implementation LynxShadowNodeStatisticUnitTest

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the
  // class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
}

- (void)testShadowNodeStatistic {
  id templateRenderMock = OCMClassMock([LynxTemplateRender class]);
  LynxUIOwner* uiOwner = [[LynxUIOwner alloc] initWithContainerView:nil
                                                     templateRender:templateRenderMock
                                                  componentRegistry:nil
                                                      screenMetrics:nil];
  LynxShadowNodeOwner* nodeOwner = [[LynxShadowNodeOwner alloc] initWithUIOwner:uiOwner
                                                              componentRegistry:nil
                                                                     layoutTick:nil
                                                                  isAsyncRender:NO
                                                                        context:nil];

  id lynxEnvMock = OCMClassMock([LynxEnv class]);
  OCMStub([lynxEnvMock getBoolExperimentSettings:@"enable_shadownode_statistic_report"])
      .andReturn(YES);

  [nodeOwner shadowNodeStatistic:@"view"];
  sleep(1);
  // Reported only when the view is first created.
  OCMVerify(times(1), [templateRenderMock genericReportInfo]);

  [nodeOwner shadowNodeStatistic:@"text"];
  sleep(1);
  // Reported only when the text is first created.
  OCMVerify(times(2), [templateRenderMock genericReportInfo]);

  [nodeOwner shadowNodeStatistic:@"text"];
  sleep(1);
  // Because the text has already been created, it will not be reported.
  OCMVerify(times(2), [templateRenderMock genericReportInfo]);
}

@end
