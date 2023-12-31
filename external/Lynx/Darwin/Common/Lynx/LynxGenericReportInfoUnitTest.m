//  Copyright 2023 The Lynx Authors. All rights reserved.

#import <XCTest/XCTest.h>
#import "LynxGenericReportInfo.h"

@interface LynxGenericReportInfoUnitTest : XCTestCase

@end

@implementation LynxGenericReportInfoUnitTest

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the
  // class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
}

- (void)testToJSONObject {
  NSObject *target = [NSObject new];
  LynxGenericReportInfo *lynxGenericInfo = [LynxGenericReportInfo infoWithTarget:target];
  NSDictionary *data = [lynxGenericInfo toJson];
  XCTAssertGreaterThan([[data objectForKey:@"thread_mode"] integerValue], -1);
  XCTAssertNotNil([data objectForKey:@"lynx_sdk_version"]);
  XCTAssertNotNil([data objectForKey:@"lynx_session_id"]);
  XCTAssertNil([data objectForKey:@"url"]);
  XCTAssertNil([data objectForKey:@"relative_path"]);
  XCTAssertNil([data objectForKey:@"lynx_target_sdk_version"]);
  XCTAssertNil([data objectForKey:@"lynx_dsl"]);
  XCTAssertNil([data objectForKey:@"lynx_lepus_type"]);
  XCTAssertNil([data objectForKey:@"lynx_page_version"]);
}

- (void)testUpdatePropOptForKey {
  NSObject *target = [NSObject new];
  LynxGenericReportInfo *lynxGenericInfo = [LynxGenericReportInfo infoWithTarget:target];
  [lynxGenericInfo updatePropOpt:@"1.0.0" forKey:@"lynx_page_version"];
  [lynxGenericInfo updatePropOpt:@"2.9" forKey:@"lynx_target_sdk_version"];
  [lynxGenericInfo updateDSL:@"tt"];
  [lynxGenericInfo updateEnableLepusNG:YES];
  NSDictionary *data = [lynxGenericInfo toJson];
  XCTAssertGreaterThan([[data objectForKey:@"thread_mode"] integerValue], -1);
  XCTAssertNotNil([data objectForKey:@"lynx_sdk_version"]);
  XCTAssertNotNil([data objectForKey:@"lynx_session_id"]);
  XCTAssertNil([data objectForKey:@"url"]);
  XCTAssertNil([data objectForKey:@"relative_path"]);
  XCTAssertEqual([data objectForKey:@"lynx_target_sdk_version"], @"2.9");
  XCTAssertEqual([data objectForKey:@"lynx_dsl"], @"ttml");
  XCTAssertEqual([data objectForKey:@"lynx_lepus_type"], @"lepusNG");
  XCTAssertEqual([data objectForKey:@"lynx_page_version"], @"1.0.0");
}

- (void)testUpdateLynxUrl {
  NSObject *target = [NSObject new];
  LynxGenericReportInfo *lynxGenericInfo = [LynxGenericReportInfo infoWithTarget:target];
  [lynxGenericInfo updateLynxUrl:@"this is a lynx url"];
  NSDictionary *data = [lynxGenericInfo toJson];
  XCTAssertGreaterThan([[data objectForKey:@"thread_mode"] integerValue], -1);
  XCTAssertNotNil([data objectForKey:@"lynx_sdk_version"]);
  XCTAssertNotNil([data objectForKey:@"lynx_session_id"]);
  XCTAssertEqual([data objectForKey:@"url"], @"this is a lynx url");
  XCTAssertEqual([data objectForKey:@"relative_path"], @"this is a lynx url");
  XCTAssertNil([data objectForKey:@"lynx_target_sdk_version"]);
  XCTAssertNil([data objectForKey:@"lynx_dsl"]);
  XCTAssertNil([data objectForKey:@"lynx_lepus_type"]);
  XCTAssertNil([data objectForKey:@"lynx_page_version"]);
}

- (void)testUpdateThreadStrategy {
  NSObject *target = [NSObject new];
  LynxGenericReportInfo *lynxGenericInfo = [LynxGenericReportInfo infoWithTarget:target];
  [lynxGenericInfo updateThreadStrategy:4];
  NSDictionary *data = [lynxGenericInfo toJson];
  XCTAssertEqual([[data objectForKey:@"thread_mode"] integerValue], 4);
  XCTAssertNotNil([data objectForKey:@"lynx_sdk_version"]);
  XCTAssertNotNil([data objectForKey:@"lynx_session_id"]);
  XCTAssertNil([data objectForKey:@"url"]);
  XCTAssertNil([data objectForKey:@"relative_path"]);
  XCTAssertNil([data objectForKey:@"lynx_target_sdk_version"]);
  XCTAssertNil([data objectForKey:@"lynx_dsl"]);
  XCTAssertNil([data objectForKey:@"lynx_lepus_type"]);
  XCTAssertNil([data objectForKey:@"lynx_page_version"]);
}

- (void)testUpdateEnableLepusNG {
  NSObject *target = [NSObject new];
  LynxGenericReportInfo *lynxGenericInfo = [LynxGenericReportInfo infoWithTarget:target];
  [lynxGenericInfo updatePropOpt:@"1.0.0" forKey:@"lynx_page_version"];
  [lynxGenericInfo updatePropOpt:@"2.9" forKey:@"lynx_target_sdk_version"];
  [lynxGenericInfo updateDSL:@"tt"];
  [lynxGenericInfo updateEnableLepusNG:NO];
  NSDictionary *data = [lynxGenericInfo toJson];
  XCTAssertGreaterThan([[data objectForKey:@"thread_mode"] integerValue], -1);
  XCTAssertNotNil([data objectForKey:@"lynx_sdk_version"]);
  XCTAssertNotNil([data objectForKey:@"lynx_session_id"]);
  XCTAssertNil([data objectForKey:@"url"]);
  XCTAssertNil([data objectForKey:@"relative_path"]);
  XCTAssertEqual([data objectForKey:@"lynx_target_sdk_version"], @"2.9");
  XCTAssertEqual([data objectForKey:@"lynx_dsl"], @"ttml");
  XCTAssertEqual([data objectForKey:@"lynx_lepus_type"], @"lepus");
  XCTAssertEqual([data objectForKey:@"lynx_page_version"], @"1.0.0");
}

- (void)testUpdateDSL {
  NSObject *target = [NSObject new];
  LynxGenericReportInfo *lynxGenericInfo = [LynxGenericReportInfo infoWithTarget:target];
  [lynxGenericInfo updatePropOpt:@"1.0.0" forKey:@"lynx_page_version"];
  [lynxGenericInfo updatePropOpt:@"2.9" forKey:@"lynx_target_sdk_version"];
  [lynxGenericInfo updateDSL:@"react"];
  [lynxGenericInfo updateEnableLepusNG:NO];
  NSDictionary *data = [lynxGenericInfo toJson];
  XCTAssertGreaterThan([[data objectForKey:@"thread_mode"] integerValue], -1);
  XCTAssertNotNil([data objectForKey:@"lynx_sdk_version"]);
  XCTAssertNotNil([data objectForKey:@"lynx_session_id"]);
  XCTAssertNil([data objectForKey:@"url"]);
  XCTAssertNil([data objectForKey:@"relative_path"]);
  XCTAssertEqual([data objectForKey:@"lynx_target_sdk_version"], @"2.9");
  XCTAssertEqual([data objectForKey:@"lynx_dsl"], @"react");
  XCTAssertEqual([data objectForKey:@"lynx_lepus_type"], @"lepus");
  XCTAssertEqual([data objectForKey:@"lynx_page_version"], @"1.0.0");
}
@end
