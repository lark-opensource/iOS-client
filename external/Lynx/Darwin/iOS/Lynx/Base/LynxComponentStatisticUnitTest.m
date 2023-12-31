//  Copyright 2023 The Lynx Authors. All rights reserved.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "LynxEnv.h"
#import "LynxTemplateRender.h"
#import "LynxUIOwner.h"

@interface LynxComponentStatisticUnitTest : XCTestCase

@end

@implementation LynxComponentStatisticUnitTest

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the
  // class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
}

- (void)testComponentStatistic {
  id templateRenderMock = OCMClassMock([LynxTemplateRender class]);
  LynxUIOwner* uiOwner = [[LynxUIOwner alloc] initWithContainerView:nil
                                                     templateRender:templateRenderMock
                                                  componentRegistry:nil
                                                      screenMetrics:nil];

  id lynxEnvMock = OCMClassMock([LynxEnv class]);
  OCMStub([lynxEnvMock getBoolExperimentSettings:@"enable_component_statistic_report"])
      .andReturn(YES);

  [uiOwner componentStatistic:@"view"];
  sleep(1);
  // Reported only when the view is first created.
  OCMVerify(times(1), [templateRenderMock genericReportInfo]);

  [uiOwner componentStatistic:@"text"];
  sleep(1);
  // Reported only when the text is first created.
  OCMVerify(times(2), [templateRenderMock genericReportInfo]);

  [uiOwner componentStatistic:@"text"];
  sleep(1);
  // Because the text has already been created, it will not be reported.
  OCMVerify(times(2), [templateRenderMock genericReportInfo]);
}

@end
