//
//  ObjCTest.m
//  LarkContainerDevEEUnitTest
//
//  Created by SolaWing on 2023/4/3.
//

#import <XCTest/XCTest.h>
#import <LarkContainerDevEEUnitTest-Swift.h>
#import <LarkContainer/LarkContainer-Swift.h>

@interface ObjCTest : XCTestCase

@end

@implementation ObjCTest {
    LKUserResolver* _resolver;
}

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _resolver = [ContainerTest setupContainer];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    Class cls = [ObjcTypeA class];
    id value = [_resolver resolveAssert:cls];
    XCTAssertEqual(cls, [value class]); // valid resolve return value

    id<ObjcProp> v2 = [_resolver resolveAssert: @protocol(ObjcProp)];
    XCTAssertEqual([v2 class], cls); // valid resolve return value
    XCTAssertEqualObjects([v2 hello], @"hello");

    id<ObjcProp2> v3 = [_resolver resolveAssert: @protocol(ObjcProp2)];
    XCTAssertEqual([(id)v3 class], cls); // valid resolve return value
    XCTAssertEqualObjects([v3 hello2], @"hello");
    
    NSError* error = nil;
    id value2 = [_resolver resolveAssert:[ObjCTest class] name:nil error:&error];
    XCTAssertNil(value2); // invalid resolve return nil
    XCTAssertNotNil(error);
}

@end
