//
//  TestJSON.m
//  BDTuring_Tests
//
//  Created by bob on 2019/9/18.
//  Copyright © 2019 bob. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <BDTuring/NSObject+BDTuring.h>
#import <BDTuring/NSData+BDTuring.h>
#import <BDTuring/NSString+BDTuring.h>

@interface TestJSON : XCTestCase

@end

@implementation TestJSON

- (void)testJSON {
    NSDictionary *param = @{@"test":@"test"};
    NSString *json = [param turing_JSONRepresentation];
    XCTAssertNotNil(json);
    XCTAssertNotNil([param turing_JSONRepresentationForJS]);
    XCTAssertEqualObjects(json, [param turing_JSONRepresentation]);

    id object = [json turing_dictionaryFromJSONString];
    XCTAssertNotNil(object);
    XCTAssertEqualObjects(object, param);

    XCTAssertNil([@"" turing_JSONRepresentation]);
    XCTAssertNil([@{@(1):@"test"} turing_JSONRepresentation]);

    XCTAssertNil([@"" turing_dictionaryFromJSONString]);
}

@end
