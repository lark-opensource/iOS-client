//
//  HMDAttributesTests.m
//  Heimdallr-Unit-Tests
//
//  Created by Nickyo on 2023/6/8.
//

#import <XCTest/XCTest.h>
#import "NSObject+HMDAttributes.h"

@interface HMDAttributesTestClass2 : NSObject

@property (nonatomic, assign) BOOL enableTest;
@property (nonatomic, assign) NSInteger integerObj;

@end

@implementation HMDAttributesTestClass2

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(enableTest, enable_test, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(integerObj, integer_obj, @(180), @(180))
    };
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    HMDAttributesTestClass2 *obj = (HMDAttributesTestClass2 *)object;
    return self.enableTest == obj.enableTest
    && self.integerObj == obj.integerObj;
}

@end

@interface HMDAttributesTestClass : NSObject

@property (nonatomic, assign) BOOL enableTest;
@property (nonatomic, assign) NSInteger integerObj;
@property (nonatomic, strong) HMDAttributesTestClass2 *testCls;
@property (nonatomic, copy) NSArray<HMDAttributesTestClass2 *> *testArray;

@end

@implementation HMDAttributesTestClass

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(enableTest, enable_test, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(integerObj, integer_obj, @(80), @(80))
        HMD_ATTR_MAP_CLASS(testCls, test_cls, HMDAttributesTestClass2)
        HMD_ATTR_MAP_CLASS(testArray, test_arr, HMDAttributesTestClass2)
    };
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    HMDAttributesTestClass *obj = (HMDAttributesTestClass *)object;
    return self.enableTest == obj.enableTest
    && self.integerObj == obj.integerObj
    && ((self.testCls == nil && obj.testCls == nil) || [self.testCls isEqual:obj.testCls])
    && ((self.testArray == nil && obj.testArray == nil) || [self.testArray isEqualToArray:obj.testArray]);
}

@end

@interface HMDAttributesTests : XCTestCase

@end

@implementation HMDAttributesTests

- (void)testAllTypeAttributes {
    NSDictionary *dict = @{
        @"enable_test": @(YES),
        @"integer_obj": @"999",
        @"test_cls": @{
            @"integer_obj": @(100),
        },
        @"test_arr": @[
            @{
                @"integer_obj": @(10),
            },
            @{
                @"enable_test": @(YES),
            }
        ]
    };
    HMDAttributesTestClass *source = [HMDAttributesTestClass hmd_objectWithDictionary:dict];
    
    HMDAttributesTestClass2 *testCls = [[HMDAttributesTestClass2 alloc] init];
    testCls.integerObj = 100;
    
    HMDAttributesTestClass2 *testArrObj1 = [[HMDAttributesTestClass2 alloc] init];
    testArrObj1.integerObj = 10;
    
    HMDAttributesTestClass2 *testArrObj2 = [[HMDAttributesTestClass2 alloc] init];
    testArrObj2.enableTest = YES;
    testArrObj2.integerObj = 180;
    
    HMDAttributesTestClass *target = [[HMDAttributesTestClass alloc] init];
    target.enableTest = YES;
    target.integerObj = 999;
    target.testCls = testCls;
    target.testArray = @[testArrObj1, testArrObj2];
    
    XCTAssert([target isEqual:source]);
}

@end
