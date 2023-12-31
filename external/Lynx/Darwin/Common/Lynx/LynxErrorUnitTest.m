//  Copyright © 2023 Lynx. All rights reserved.
#import <Lynx/LynxError.h>
#import <XCTest/XCTest.h>

NSString* testErrorMessage = @"some error occurred";
NSString* testErrorFixSuggestion = @"some fix suggestion of this error";

@interface LynxErrorUnitTest : XCTestCase

@end
@implementation LynxErrorUnitTest {
  LynxError* _error;
}

- (void)setUp {
  NSDictionary* customInfo = [NSDictionary
      dictionaryWithObjectsAndKeys:@"some info1", @"info1", @"some info2", @"info2", nil];
  _error = [LynxError lynxErrorWithCode:301
                                message:testErrorMessage
                          fixSuggestion:testErrorFixSuggestion
                                  level:LynxErrorLevelWarn
                             customInfo:customInfo];
}

- (void)tearDown {
}

- (void)testIsValid {
  // test valid error
  XCTAssertTrue([_error isValid]);

  // test invalid error
  LynxError* error2 = [LynxError lynxErrorWithCode:301
                                           message:@""
                                     fixSuggestion:testErrorFixSuggestion
                                             level:LynxErrorLevelWarn
                                        customInfo:nil];
  XCTAssertFalse([error2 isValid]);
}

- (void)testGenerateJsonStr {
  // test override NSError's userInfo
  NSError* nsError = _error;

  NSString* errorJson = [[nsError userInfo] objectForKey:LynxErrorUserInfoKeyMessage];
  NSError* parseError = nil;
  id jsonObject =
      [NSJSONSerialization JSONObjectWithData:[errorJson dataUsingEncoding:NSUTF8StringEncoding]
                                      options:kNilOptions
                                        error:&parseError];

  // test generate json string with base error info
  if ([jsonObject isKindOfClass:[NSDictionary class]]) {
    NSDictionary* dictionary = (NSDictionary*)jsonObject;
    XCTAssertTrue([[dictionary objectForKey:@"error"] isEqualToString:testErrorMessage]);
    XCTAssertTrue([[dictionary objectForKey:@"error_code"] isEqualToNumber:@301]);
    XCTAssertTrue(
        [[dictionary objectForKey:@"fix_suggestion"] isEqualToString:testErrorFixSuggestion]);
    XCTAssertTrue([[dictionary objectForKey:@"info1"] isEqualToString:@"some info1"]);
    XCTAssertTrue([[dictionary objectForKey:@"info2"] isEqualToString:@"some info2"]);
    XCTAssertTrue([[dictionary objectForKey:@"level"] isEqualToString:@"warn"]);
  } else {
    XCTFail(@"Failed to parse error message to json");
  }

  // test regenereate error message after append additional info
  _error.templateUrl = @"template url";
  _error.cardVersion = @"0.0.1";
  _error.callStack = @"call stack";
  [_error addCustomInfo:@"some new info" forKey:@"info3"];
  NSString* errorJson2 = [[nsError userInfo] objectForKey:LynxErrorUserInfoKeyMessage];
  NSError* parseError2 = nil;
  id jsonObject2 =
      [NSJSONSerialization JSONObjectWithData:[errorJson2 dataUsingEncoding:NSUTF8StringEncoding]
                                      options:kNilOptions
                                        error:&parseError2];
  if ([jsonObject2 isKindOfClass:[NSDictionary class]]) {
    NSDictionary* dictionary2 = (NSDictionary*)jsonObject2;
    XCTAssertTrue([[dictionary2 objectForKey:@"url"] isEqualToString:@"template url"]);
    XCTAssertTrue([[dictionary2 objectForKey:@"card_version"] isEqualToString:@"0.0.1"]);
    XCTAssertTrue([[dictionary2 objectForKey:@"error_stack"] isEqualToString:@"call stack"]);
    XCTAssertTrue([[dictionary2 objectForKey:@"info3"] isEqualToString:@"some new info"]);
  } else {
    XCTFail(@"Failed to parse error message to json");
  }
}

- (void)testCompatibilityWithOldInterface {
  LynxError* error = [LynxError lynxErrorWithCode:601 message:testErrorMessage];
  NSError* nsError = error;
  NSString* errorMessage = [[nsError userInfo] objectForKey:LynxErrorUserInfoKeyMessage];
  XCTAssertTrue([errorMessage isEqualToString:testErrorMessage]);
}

@end
