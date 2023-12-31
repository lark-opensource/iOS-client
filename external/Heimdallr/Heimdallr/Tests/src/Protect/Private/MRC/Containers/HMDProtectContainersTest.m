//
//  HeimdallrProtectContainerTest.m
//  HeimdallrDemoTests
//
//  Created by bytedance on 2020/8/4.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "HMDProtector.h"
#import "HMDDynamicCall.h"
#import "HMDSwizzle.h"
#import "HMDProtect_Private.h"

#pragma mark 该单测还留有 BUG 没修 (详细见 pragma 注释)

@interface NSArray (HMDCompleteEqual)
- (BOOL)isCompleteEqualToArray:(NSArray *)otherArray;
@end

@implementation NSArray (HMDCompleteEqual)
- (BOOL)isCompleteEqualToArray:(NSArray *)otherArray {
    if(self.count != otherArray.count) DEBUG_RETURN(NO);
    for(NSUInteger index = 0; index < self.count; index++) {
        if([self[index] isKindOfClass:NSNumber.class] && [otherArray[index] isKindOfClass:NSNumber.class]) {
            NSNumber *number1 = self[index];
            NSNumber *number2 = otherArray[index];
            if(![number1 isEqualToNumber:number2]) DEBUG_RETURN(NO);
        }
        else if(![self[index] isEqual:otherArray[index]]) DEBUG_RETURN(NO);
    }
    return YES;
}
@end

@interface HeimdallrProtectContainerTest : XCTestCase

@end

@implementation HeimdallrProtectContainerTest

+ (void)setUp {
    HMDProtectTestEnvironment = YES;
    [HMDProtector.sharedProtector turnProtectionsOn:HMDProtectionTypeContainers];
    HMDProtector.sharedProtector.ignoreTryCatch = NO;
}

+ (void)tearDown {
    HMDProtectTestEnvironment = NO;
    HMDProtector.sharedProtector.ignoreTryCatch = YES;
}

- (void)setUp {
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

#pragma mark - NSNumber

- (void)test_HMDProtectContainers_NSNumber_compare {
    NSNumber *aNumber = [NSNumber numberWithInt:6];
    [aNumber compare:(NSNumber *)@""];
    [aNumber compare:nil];
    XCTAssert(NSOrderedSame == [aNumber compare:[NSNumber numberWithInt:6]]);
}

- (void)test_HMDProtectContainers_NSNumber_isEqualToNumber {
    NSNumber *aNumber = [NSNumber numberWithInt:6];
    [aNumber isEqualToNumber:(NSNumber *)[NSObject new]];
    [aNumber isEqualToNumber:nil];
    XCTAssert([aNumber isEqualToNumber:[NSNumber numberWithInt:6]]);
}

#pragma mark - NSString

- (void)test_HMDProtectContainers_NSString_characterAtIndex {
    NSString *string = [NSString stringWithFormat:@"My age is %d\n", 18];
    [string characterAtIndex:0];
    [string characterAtIndex:100];
    [string characterAtIndex:1000];
    [string characterAtIndex:NSUIntegerMax / 2];
    [string characterAtIndex:NSUIntegerMax / 4];
    [string characterAtIndex:NSUIntegerMax];
    XCTAssert([string characterAtIndex:2] == (unichar)' ');
}

- (void)test_HMDProtectContainers_NSString_substringFromIndex {
    NSString *string = [NSString stringWithUTF8String:"12342536761234567"];
    [string substringFromIndex:0];
    [string substringFromIndex:100];
    [string substringFromIndex:1000];
    [string substringFromIndex:NSUIntegerMax / 2];
    [string substringFromIndex:NSUIntegerMax / 4];
    [string substringFromIndex:NSUIntegerMax];
    XCTAssert([[string substringFromIndex:3] isEqualToString:@"42536761234567"]);
}

- (void)test_HMDProtectContainers_NSString_substringToIndex {
    NSString *fromString = @"uyirweuiyewruewruyierw";
    NSString *string = [NSString stringWithString:fromString];
    [string substringToIndex:0];
    [string substringToIndex:100];
    [string substringToIndex:1000];
    [string substringToIndex:NSUIntegerMax / 2];
    [string substringToIndex:NSUIntegerMax / 4];
    [string substringToIndex:NSUIntegerMax];
    XCTAssert([[string substringToIndex:3] isEqualToString:@"uyi"]);
}

- (void)test_HMDProtectContainers_NSString_substringWithRange {
    NSString *fromString = @"fasdjlidflkjaf23";
    NSString *string = [NSString stringWithString:fromString];
    [string substringWithRange:NSMakeRange(0, 0)];
    [string substringWithRange:NSMakeRange(NSUIntegerMax, NSUIntegerMax)];
    [string substringWithRange:NSMakeRange(0, NSUIntegerMax)];
    [string substringWithRange:NSMakeRange(NSUIntegerMax/2, NSUIntegerMax/2)];
    
    NSMutableString *content = [NSMutableString stringWithString:@"1"];
    NSString *taggedPointer = [NSString stringWithString:content];
    [taggedPointer substringWithRange:NSMakeRange(2, NSUIntegerMax)];
}

- (void)test_HMDProtectContainers_NSBigMutableString_substringWithRange {
    NSMutableString *commonString = [NSMutableString stringWithString:@"good"];
    id rt = [commonString substringWithRange:NSMakeRange(4ul, 18446744073709551612ul)];
    XCTAssert(rt == nil);
    NSString *bigMutableString = DC_ET(DC_CL(NSBigMutableString, stringWithString:, @"good"), NSBigMutableString);
    rt = [bigMutableString substringWithRange:NSMakeRange(4ul, 18446744073709551612ul)];
    XCTAssert(rt == nil);
}

- (void)test_HMDProtectContainers_NSString_stringByReplacingCharactersInRange_withString {
    NSString *fromString = @"fasdjlidflkjaf23";
    NSString *string = [NSString stringWithString:fromString];
    [string stringByReplacingCharactersInRange:NSMakeRange(0, 2) withString:nil];
    [string stringByReplacingCharactersInRange:NSMakeRange(NSUIntegerMax, NSUIntegerMax) withString:@"fskd"];
    [string stringByReplacingCharactersInRange:NSMakeRange(0, NSUIntegerMax) withString:@"fskd"];
    [string stringByReplacingCharactersInRange:NSMakeRange(0, 0) withString:@"fskd"];
    XCTAssert([[string stringByReplacingCharactersInRange:NSMakeRange(2, 2) withString:@"1"] isEqualToString:@"fa1jlidflkjaf23"]);
}

- (void)test_HMDProtectContainers_NSString_stringByAppendingString {
    NSString *fromString = @"123456789";
    [fromString stringByAppendingString:nil];
    [fromString stringByAppendingString:@(1)];
    fromString = @"123456789";
    fromString = [fromString stringByAppendingString:@"123456789"];
    XCTAssert([fromString isEqualToString:@"123456789123456789"]);
}

#pragma mark - NSMutableString

- (void)test_HMDProtectContainers_NSMutableString_appendString {
    NSMutableString *fromString = [NSMutableString stringWithString:@"123456789"];
    [fromString appendString:nil];
    [fromString appendString:@(1)];
    fromString = [NSMutableString stringWithString:@"123456789"];
    [fromString appendString:@"good"];
    XCTAssert([fromString isEqualToString:@"123456789good"]);
}

- (void)test_HMDProtectContainers_NSMutableString_replaceCharactersInRange_withString {
    NSMutableString *fromString = [NSMutableString stringWithString:@"123456789"];
    [fromString replaceCharactersInRange:NSMakeRange(0, 1) withString:nil];
    [fromString replaceCharactersInRange:NSMakeRange(0, 1) withString:@(1)];
    [fromString replaceCharactersInRange:NSMakeRange(NSUIntegerMax, NSUIntegerMax) withString:@"1234"];
    [fromString replaceCharactersInRange:NSMakeRange(0, NSUIntegerMax) withString:@"1234"];
    fromString = [NSMutableString stringWithString:@"123456789"];
    [fromString replaceCharactersInRange:NSMakeRange(0, 3) withString:@"5"];
    XCTAssert([fromString isEqualToString:@"5456789"]);
}

- (void)test_HMDProtectContainers_NSMutableString_insertString_atIndex {
    NSMutableString *fromString = [NSMutableString stringWithString:@"123456789"];
    [fromString insertString:nil atIndex:0];
    [fromString insertString:@(1) atIndex:0];
    [fromString insertString:@"..." atIndex:NSUIntegerMax];
    [fromString insertString:@"..." atIndex:20];
    fromString = [NSMutableString stringWithString:@"123456789"];
    [fromString insertString:@"55" atIndex:5];
    XCTAssert([fromString isEqualToString:@"12345556789"]);
}

- (void)test_HMDProtectContainers_NSMutableString_deleteCharactersInRange {
    NSMutableString *fromString = [NSMutableString stringWithString:@"123456789"];
    [fromString deleteCharactersInRange:NSMakeRange(NSUIntegerMax, NSUIntegerMax)];
    [fromString deleteCharactersInRange:NSMakeRange(3, 50)];
    fromString = [NSMutableString stringWithString:@"123456789"];
    [fromString deleteCharactersInRange:NSMakeRange(2, 3)];
    XCTAssert([fromString isEqualToString:@"126789"]);
}

#pragma mark - NSAttributeString

- (void)test_HMDProtectContainers_NSAttributeString_initWithString {
    [[NSAttributedString alloc] initWithString:nil];
    [[NSAttributedString alloc] initWithString:@(1)];
    XCTAssert([[[NSAttributedString alloc] initWithString:@"good"].string isEqualToString:@"good"]);
}

- (void)test_HMDProtectContainers_NSAttributeString_initWithString_attributes {
    [[NSAttributedString alloc] initWithString:nil attributes:nil];
    [[NSAttributedString alloc] initWithString:@(1) attributes:nil];
    XCTAssert([[[NSAttributedString alloc] initWithString:@"good" attributes:nil].string isEqualToString:@"good"]);
}

- (void)test_HMDProtectContainers_NSAttributeString_attributedSubstringFromRange {
    NSAttributedString *fromString = [[NSAttributedString alloc] initWithString:@"good"];
    [fromString attributedSubstringFromRange:NSMakeRange(0, NSUIntegerMax)];
    [fromString attributedSubstringFromRange:NSMakeRange(NSUIntegerMax, 0)];
    [fromString attributedSubstringFromRange:NSMakeRange(NSUIntegerMax, NSUIntegerMax)];
    NSString *aString = [fromString attributedSubstringFromRange:NSMakeRange(1, 2)].string;
    XCTAssert([aString isEqualToString:@"oo"]);
}

- (void)test_HMDProtectContainers_NSAttributeString_enumerateAttribute_inRange {
    NSAttributedString *fromString = [[NSAttributedString alloc] initWithString:@"good"];
    [fromString enumerateAttribute:NSForegroundColorAttributeName inRange:NSMakeRange(NSUIntegerMax, NSUIntegerMax) options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
    }];
    [fromString enumerateAttribute:NSForegroundColorAttributeName inRange:NSMakeRange(0, 4) options:0 usingBlock:nil];
    
    __block BOOL called = NO;
    [fromString enumerateAttribute:NSForegroundColorAttributeName inRange:NSMakeRange(0, 4) options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        called = YES;
    }];
    XCTAssert(called);
}

- (void)test_HMDProtectContainers_NSAttributeString_enumerateAttributes_inRange {
    NSAttributedString *fromString = [[NSAttributedString alloc] initWithString:@"good"];
    [fromString enumerateAttributesInRange:NSMakeRange(NSUIntegerMax, NSUIntegerMax) options:0 usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
    }];
    [fromString enumerateAttributesInRange:NSMakeRange(0, 1) options:0 usingBlock:nil];
    
    __block BOOL called = NO;
    [fromString enumerateAttributesInRange:NSMakeRange(0, 4) options:0 usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
        called = YES;
    }];
    XCTAssert(called);
}

- (void)test_HMDProtectContainers_NSAttributeString_dataFromRange {
    NSAttributedString *fromString = [[NSAttributedString alloc] initWithString:@"good"];
    id value = [fromString dataFromRange:NSMakeRange(NSUIntegerMax, NSUIntegerMax) documentAttributes:@{} error:nil];
    XCTAssert(value == nil);
}

- (void)test_HMDProtectContainers_NSAttributeString_fileWrapperFromRange {
    NSAttributedString *fromString = [[NSAttributedString alloc] initWithString:@"good"];
    id value = [fromString fileWrapperFromRange:NSMakeRange(NSUIntegerMax, NSUIntegerMax) documentAttributes:@{} error:nil];
    XCTAssert(value == nil);
}

- (void)test_HMDProtectContainers_NSAttributeString_containsAttachmentsInRange {
    NSAttributedString *fromString = [[NSAttributedString alloc] initWithString:@"good"];
    BOOL contain = [fromString containsAttachmentsInRange:NSMakeRange(NSUIntegerMax, NSUIntegerMax)];
    XCTAssert(!contain);
}

// NSAttributedString 下 -[attributesAtIndex:effectiveRange:] 没有 out of range 崩溃
- (void)test_HMDProtectContainers_NSAttributedString_attributesAtIndex_effectiveRange {
    NSString *rawString = @"happy";
    NSAttributedString *fromString = [[NSAttributedString alloc] initWithString:rawString];
    NSDictionary *dic = [fromString attributesAtIndex:5 effectiveRange:NULL];
    XCTAssert(dic != nil);
    dic = [fromString attributesAtIndex:4 effectiveRange:NULL];
    XCTAssert(dic != nil);
    return;
}

#pragma mark - NSMutableAttributedString

// NSAttributedString 下 -[attributesAtIndex:effectiveRange:] 会 out of range 崩溃
- (void)test_HMDProtectContainers_NSMutableAttributedString_attributesAtIndex_effectiveRange {
    NSString *rawString = @"happy";
    NSMutableAttributedString *fromString = [[NSMutableAttributedString alloc] initWithString:rawString];
    NSDictionary *dic = [fromString attributesAtIndex:5 effectiveRange:NULL];
    XCTAssert(dic == nil); // 保护成功是 返回安全 nil 的说
    dic = [fromString attributesAtIndex:4 effectiveRange:NULL];
    XCTAssert(dic != nil);
    return;
}

- (void)test_HMDProtectContainers_NSMutableAttributedString_replaceCharactersInRange {
    NSMutableAttributedString *fromString = [[NSMutableAttributedString alloc] initWithString:@"good"];
    [fromString replaceCharactersInRange:NSMakeRange(NSUIntegerMax, NSUIntegerMax) withString:@"good"];
    [fromString replaceCharactersInRange:NSMakeRange(0, 1) withString:nil];
    [fromString replaceCharactersInRange:NSMakeRange(0, 1) withString:@(1)];
    fromString = [[NSMutableAttributedString alloc] initWithString:@"good"];
    [fromString replaceCharactersInRange:NSMakeRange(0, 1) withString:@"f"];
    XCTAssert([fromString.string isEqualToString:@"food"]);
}

- (void)test_HMDProtectContainers_NSMutableAttributedString_deleteCharactersInRange {
    NSMutableAttributedString *string;
    string = [[NSMutableAttributedString alloc] initWithString:@"good"];
    [string deleteCharactersInRange:NSMakeRange(NSUIntegerMax, NSUIntegerMax)];
    [string deleteCharactersInRange:NSMakeRange(0, 5)];
    XCTAssert([string.string isEqualToString:@"good"]);
    [string deleteCharactersInRange:NSMakeRange(0, 4)];
    XCTAssert([string.string isEqualToString:@""]);
    string = [[NSMutableAttributedString alloc] initWithString:@"good"];
    [string deleteCharactersInRange:NSMakeRange(3, 1)];
    XCTAssert([string.string isEqualToString:@"goo"]);
    string = [[NSMutableAttributedString alloc] initWithString:@"good"];
    [string deleteCharactersInRange:NSMakeRange(1, 2)];
    XCTAssert([string.string isEqualToString:@"gd"]);
}

- (void)test_HMDProtectContainers_NSMutableAttributedString_setAttributes_range {
    NSMutableAttributedString *string;
    string = [[NSMutableAttributedString alloc] initWithString:@"good"];
    NSDictionary *attributes = @{NSForegroundColorAttributeName: UIColor.redColor};
    [string setAttributes:attributes range:NSMakeRange(NSUIntegerMax, NSUIntegerMax)];
}

- (void)test_HMDProtectContainers_NSMutableAttributedString_addAttribute_value_range {
    NSMutableAttributedString *string;
    string = [[NSMutableAttributedString alloc] initWithString:@"good"];
    [string addAttribute:NSForegroundColorAttributeName value:UIColor.redColor range:NSMakeRange(NSUIntegerMax, NSUIntegerMax)];
    [string addAttribute:NSForegroundColorAttributeName value:nil range:NSMakeRange(2, 1)];
    [string addAttribute:nil value:UIColor.redColor range:NSMakeRange(2, 1)];
}

- (void)test_HMDProtectContainers_NSMutableAttributedString_addAttributes_range {
    NSMutableAttributedString *string;
    string = [[NSMutableAttributedString alloc] initWithString:@"good"];
    NSDictionary *attributes = @{NSForegroundColorAttributeName: UIColor.redColor};
    [string addAttributes:attributes range:NSMakeRange(NSUIntegerMax, NSUIntegerMax)];
}

- (void)test_HMDProtectContainers_NSMutableAttributedString_removeAttribute_range {
    NSMutableAttributedString *string;
    string = [[NSMutableAttributedString alloc] initWithString:@"good"];
    [string removeAttribute:NSForegroundColorAttributeName range:NSMakeRange(NSUIntegerMax, NSUIntegerMax)];
}

- (void)test_HMDProtectContainers_NSMutableAttributedString_insertAttributedString_atIndex {
    NSMutableAttributedString *string, *anotherString;
    string = [[NSMutableAttributedString alloc] initWithString:@"good"];
    [string insertAttributedString:nil atIndex:0];
    anotherString = [[NSMutableAttributedString alloc] initWithString:@"another"];
    [string insertAttributedString:anotherString atIndex:NSUIntegerMax];
    XCTAssert([string.string isEqualToString:@"good"]);
}

- (void)test_HMDProtectContainers_NSMutableAttributedString_replaceCharactersInRange_withAttributedString {
    NSMutableAttributedString *string, *anotherString;
    string = [[NSMutableAttributedString alloc] initWithString:@"good"];
    anotherString = [[NSMutableAttributedString alloc] initWithString:@"another"];
    [string replaceCharactersInRange:NSMakeRange(NSUIntegerMax, NSUIntegerMax) withAttributedString:anotherString];
    [string replaceCharactersInRange:NSMakeRange(1, 2) withAttributedString:nil];
    XCTAssert([string.string isEqualToString:@"good"]);
}

- (void)test_HMDProtectContainers_NSMutableAttributedString_fixAttributesInRange {
    NSMutableAttributedString *string, *anotherString;
    string = [[NSMutableAttributedString alloc] initWithString:@"good"];
    anotherString = [[NSMutableAttributedString alloc] initWithString:@"another"];
    [string fixAttributesInRange:NSMakeRange(NSUIntegerMax, NSUIntegerMax)];
    [anotherString fixAttributesInRange:NSMakeRange(0, 2)];
}

#pragma mark - NSArray

- (void)test_HMDProtectContainers_NSArray_arrayWithObjects_count {
    id nilObject = nil;
    id value = @[@0, @1, @2, nilObject, @4, @5];
    XCTAssert(value == nil);
}

- (void)test_HMDProtectContainers_NSArray_objectsAtIndexes {
    NSArray *array = @[@0, @1, @2, @3, @4, @5];
    NSIndexSet *set = [[NSIndexSet alloc] initWithIndex:6];
    id value = [array objectsAtIndexes:set];
    XCTAssert(value == nil);
    NSMutableIndexSet *mutableSet = [[NSMutableIndexSet alloc] initWithIndex:2];
    [mutableSet addIndex:3];
    NSArray *anotherArray = [array objectsAtIndexes:mutableSet];
    XCTAssert([anotherArray isKindOfClass:NSArray.class]);
    XCTAssert(anotherArray.count == 2);
    XCTAssert([anotherArray containsObject:@2]);
    XCTAssert([anotherArray containsObject:@3]);
}

- (void)test_HMDProtectContainers_NSArray_objectAtIndex {
    NSArray *array = @[@0, @1, @2, @3, @4, @5];
    id value = [array objectAtIndex:6];
    XCTAssert(value == nil);
    value = [array objectAtIndex:2];
    XCTAssert([@2 isEqualToNumber:value]);
}

- (void)test_HMDProtectContainers_NSArray_objectAtIndexedSubscript {
    NSArray *array = @[@0, @1, @2, @3, @4, @5];
    id value = [array objectAtIndexedSubscript:6];
    XCTAssert(value == nil);
    value = [array objectAtIndexedSubscript:2];
    XCTAssert([@2 isEqualToNumber:value]);
}

- (void)test_HMDProtectContainers_NSArray_subarrayWithRange {
    NSArray *array = @[@0, @1, @2, @3, @4, @5];
    id value = [array subarrayWithRange:NSMakeRange(NSUIntegerMax, NSUIntegerMax)];
    XCTAssert(value == nil);
    NSArray *anotherArray = [array subarrayWithRange:NSMakeRange(2, 2)];
    BOOL result = [anotherArray isEqualToArray:@[@2, @3]];
    XCTAssert(result);
}

#pragma mark - NSMutableArray

- (void)test_HMDProtectContainers_NSMutableArray_removeObjectAtIndex {
    NSArray *array = @[@0, @1, @2, @3, @4, @5];
    NSMutableArray *mutableArray = array.mutableCopy;
    
    [mutableArray removeObjectAtIndex:6];
    XCTAssert([mutableArray isEqualToArray:array]);
    
    [mutableArray removeObjectAtIndex:NSUIntegerMax];
    XCTAssert([mutableArray isEqualToArray:array]);
    
    [mutableArray removeObjectAtIndex:NSUIntegerMax/2];
    XCTAssert([mutableArray isEqualToArray:array]);
    
    [mutableArray removeObjectAtIndex:3];
    NSArray *removedArray = @[@0, @1, @2, @4, @5];
    XCTAssert([mutableArray isEqualToArray:removedArray]);
}

- (void)test_HMDProtectContainers_NSMutableArray_removeObjectsInRange {
    NSArray *array = @[@0, @1, @2, @3, @4, @5];
    NSMutableArray *mutableArray = array.mutableCopy;
    
    [mutableArray removeObjectsInRange:NSMakeRange(4, 3)];
    XCTAssert([mutableArray isCompleteEqualToArray:array]);
    
    [mutableArray removeObjectsInRange:NSMakeRange(6, 1)];
    XCTAssert([mutableArray isCompleteEqualToArray:array]);
    
    [mutableArray removeObjectsInRange:NSMakeRange(NSUIntegerMax, 1)];
    XCTAssert([mutableArray isCompleteEqualToArray:array]);
    
    [mutableArray removeObjectsInRange:NSMakeRange(0, NSUIntegerMax)];
    XCTAssert([mutableArray isCompleteEqualToArray:array]);
    
    [mutableArray removeObjectsInRange:NSMakeRange(0, 1)];
    NSArray *removedArray = @[@1, @2, @3, @4, @5];
    XCTAssert([mutableArray isCompleteEqualToArray:removedArray]);
    
    mutableArray = array.mutableCopy;
    removedArray = @[@0, @1, @5];
    [mutableArray removeObjectsInRange:NSMakeRange(2, 3)];
    XCTAssert([mutableArray isCompleteEqualToArray:removedArray]);
}

- (void)test_HMDProtectContainers_NSMutableArray_removeObjectsAtIndexes {
    NSArray *array = @[@0, @1, @2, @3, @4, @5];
    NSMutableArray *mutableArray = array.mutableCopy;
    
    NSMutableIndexSet *mutableSet = [[NSMutableIndexSet alloc] init];
    [mutableSet addIndex:6];
    [mutableSet addIndex:3];
    
    [mutableArray removeObjectsAtIndexes:mutableSet];
    XCTAssert([mutableArray isEqualToArray:array]);
    
    mutableSet = [[NSMutableIndexSet alloc] init];
    [mutableSet addIndex:NSUIntegerMax];
    [mutableSet addIndex:0];
    
    /* 发现了一个有趣的故事
        1. NSMutableIndexSet 允许添加 index 范围是
            [0, (NSNotFound - 1)] 和 NSUIntegerMax
        2. NSMutableIndexSet enumerate 只会显示 [0, (NSNotFound - 1)] 的数据
        3. 使用 NSMutableIndexSet 数据的系统类，例如
            [NSMutableArray removeObjectsAtIndexes:(NSMutableIndexSet)]
            就会读出 "隐藏" 数据，然后崩溃 */
    
#pragma mark 这里有个 BUG
#warning fixme BUG here
//    [mutableArray removeObjectsAtIndexes:mutableSet];
//    XCTAssert([mutableArray isEqualToArray:array]);
    
    mutableSet = [[NSMutableIndexSet alloc] init];
    [mutableSet addIndex:2];
    [mutableSet addIndex:5];
    
    NSArray *removedArray = @[@0, @1, @3, @4];
    [mutableArray removeObjectsAtIndexes:mutableSet];
    XCTAssert([mutableArray isEqualToArray:removedArray]);
}


- (void)test_HMDProtectContainers_NSMutableArray_insertObject_atIndex {
    NSArray<NSNumber *> *array = @[@0, @1, @2, @3, @4, @5];
    NSMutableArray<NSNumber *> *mutableArray = array.mutableCopy;
    
    [mutableArray insertObject:@10086 atIndex:7];
    XCTAssert([mutableArray isCompleteEqualToArray:array]);
    
    [mutableArray insertObject:@10086 atIndex:NSUIntegerMax];
    XCTAssert([mutableArray isCompleteEqualToArray:array]);
    
    [mutableArray insertObject:@10086 atIndex:NSUIntegerMax/2];
    XCTAssert([mutableArray isCompleteEqualToArray:array]);
    
    [mutableArray insertObject:@6 atIndex:6];
    NSArray *changedArray = @[@0, @1, @2, @3, @4, @5, @6];
    XCTAssert([mutableArray isCompleteEqualToArray:changedArray]);
    
    mutableArray = array.mutableCopy;
    changedArray = @[@0, @1, @10086, @2, @3, @4, @5];
    [mutableArray insertObject:@10086 atIndex:2];
    XCTAssert([mutableArray isCompleteEqualToArray:changedArray]);
}

- (void)test_HMDProtectContainers_NSMutableArray_insertObjects_atIndexes {
    NSArray<NSNumber *> *array = @[@0, @1, @2, @3, @4, @5];
    NSMutableArray<NSNumber *> *mutableArray = array.mutableCopy;
    
    NSArray *insertObjects = @[@10086, @10086, @10086];
    NSMutableIndexSet *mutableSet = [[NSMutableIndexSet alloc] init];
    [mutableSet addIndex:0];
    [mutableSet addIndex:2];
    
    [mutableArray insertObjects:insertObjects atIndexes:mutableSet];
    XCTAssert([mutableArray isCompleteEqualToArray:array]);
    
    insertObjects = @[@10086, @10086, @10086];
    mutableSet = [[NSMutableIndexSet alloc] init];
    [mutableSet addIndex:0];
    [mutableSet addIndex:2];
    [mutableSet addIndex:7];
    NSArray *changedArray = @[@10086, @0, @10086, @1, @2, @3, @4, @10086, @5];
    
    [mutableArray insertObjects:insertObjects atIndexes:mutableSet];
    XCTAssert([mutableArray isCompleteEqualToArray:changedArray]);
    
    mutableArray = array.mutableCopy;
    insertObjects = @[@10086, @10086, @10086];
    mutableSet = [[NSMutableIndexSet alloc] init];
    [mutableSet addIndex:0];
    [mutableSet addIndex:2];
    [mutableSet addIndex:3];
    changedArray = @[@10086, @0, @10086, @10086, @1, @2, @3, @4, @5];
    
    [mutableArray insertObjects:insertObjects atIndexes:mutableSet];
    XCTAssert([mutableArray isCompleteEqualToArray:changedArray]);
}

- (void)test_HMDProtectContainers_NSMutableArray_replaceObjectAtIndex_withObject {
    NSArray<NSNumber *> *array = @[@0, @1, @2, @3, @4, @5];
    NSMutableArray<NSNumber *> *mutableArray = array.mutableCopy;
    
    [mutableArray replaceObjectAtIndex:6 withObject:@10086];
    XCTAssert([mutableArray isCompleteEqualToArray:array]);
    
    [mutableArray replaceObjectAtIndex:NSUIntegerMax withObject:@10086];
    XCTAssert([mutableArray isCompleteEqualToArray:array]);
    
    [mutableArray replaceObjectAtIndex:5 withObject:@10086];
    NSArray *changedArray = @[@0, @1, @2, @3, @4, @10086];
    XCTAssert([mutableArray isCompleteEqualToArray:changedArray]);
    
    mutableArray = array.mutableCopy;
    [mutableArray replaceObjectAtIndex:3 withObject:@10086];
    changedArray = @[@0, @1, @2, @10086, @4, @5];
    XCTAssert([mutableArray isCompleteEqualToArray:changedArray]);
    
    mutableArray = array.mutableCopy;
    [mutableArray replaceObjectAtIndex:0 withObject:@10086];
    changedArray = @[@10086, @1, @2, @3, @4, @5];
    XCTAssert([mutableArray isCompleteEqualToArray:changedArray]);
}

- (void)test_HMDProtectContainers_NSMutableArray_replaceObjectsAtIndexes_withObjects {
    NSArray<NSNumber *> *array = @[@0, @1, @2, @3, @4, @5];
    NSMutableArray<NSNumber *> *mutableArray = array.mutableCopy;
    
    NSMutableIndexSet *mutableSet = [[NSMutableIndexSet alloc] init];
    [mutableSet addIndex:0];
    [mutableSet addIndex:6];
    NSArray *replacedObjects = @[@10086, @10086];
    
    [mutableArray replaceObjectsAtIndexes:mutableSet withObjects:replacedObjects];
    XCTAssert([mutableArray isCompleteEqualToArray:array]);
    
    mutableSet = [[NSMutableIndexSet alloc] init];
    [mutableSet addIndex:0];
    [mutableSet addIndex:1];
    replacedObjects = @[@10086, @10086, @10086];
    
    [mutableArray replaceObjectsAtIndexes:mutableSet withObjects:replacedObjects];
    XCTAssert([mutableArray isCompleteEqualToArray:array]);
    
    mutableSet = [[NSMutableIndexSet alloc] init];
    [mutableSet addIndex:0];
    [mutableSet addIndex:1];
    [mutableSet addIndex:2];
    replacedObjects = @[@10086, @10086];
    
    [mutableArray replaceObjectsAtIndexes:mutableSet withObjects:replacedObjects];
    XCTAssert([mutableArray isCompleteEqualToArray:array]);
    
    mutableSet = [[NSMutableIndexSet alloc] init];
    [mutableSet addIndex:0];
    [mutableSet addIndex:5];
    replacedObjects = @[@10086, @10086];
    NSArray *changedArray = @[@10086, @1, @2, @3, @4, @10086];
    
    [mutableArray replaceObjectsAtIndexes:mutableSet withObjects:replacedObjects];
    XCTAssert([mutableArray isCompleteEqualToArray:changedArray]);
    
    mutableArray = array.mutableCopy;
    mutableSet = [[NSMutableIndexSet alloc] init];
    [mutableSet addIndex:1];
    [mutableSet addIndex:4];
    replacedObjects = @[@10086, @10086];
    changedArray = @[@0, @10086, @2, @3, @10086, @5];
    
    [mutableArray replaceObjectsAtIndexes:mutableSet withObjects:replacedObjects];
    XCTAssert([mutableArray isCompleteEqualToArray:changedArray]);
    
    mutableArray = array.mutableCopy;
    mutableSet = [[NSMutableIndexSet alloc] init];
    [mutableSet addIndex:0];
    [mutableSet addIndex:1];
    [mutableSet addIndex:2];
    [mutableSet addIndex:3];
    [mutableSet addIndex:4];
    [mutableSet addIndex:5];
    replacedObjects = @[@10086, @10086, @10086, @10086, @10086, @10086];
    changedArray = @[@10086, @10086, @10086, @10086, @10086, @10086];
    
    [mutableArray replaceObjectsAtIndexes:mutableSet withObjects:replacedObjects];
    XCTAssert([mutableArray isCompleteEqualToArray:changedArray]);
}

- (void)test_HMDProtectContainers_NSMutableArray_replaceObjectsInRange_withObjectsFromArray {
    NSArray<NSNumber *> *array = @[@0, @1, @2, @3, @4, @5];
    NSMutableArray<NSNumber *> *mutableArray = array.mutableCopy;
    
    NSRange range = NSMakeRange(0, 7);
    NSArray *fromArray = @[@10086, @10086, @10086];
    [mutableArray replaceObjectsInRange:range withObjectsFromArray:fromArray];
    XCTAssert([mutableArray isCompleteEqualToArray:array]);
    
    range = NSMakeRange(6, 1);
    fromArray = @[@10086, @10086, @10086];
    [mutableArray replaceObjectsInRange:range withObjectsFromArray:fromArray];
    XCTAssert([mutableArray isCompleteEqualToArray:array]);
    
    range = NSMakeRange(NSUIntegerMax, 1);
    fromArray = @[@10086, @10086, @10086];
    [mutableArray replaceObjectsInRange:range withObjectsFromArray:fromArray];
    XCTAssert([mutableArray isCompleteEqualToArray:array]);
    
    range = NSMakeRange(3, NSUIntegerMax);
    fromArray = @[@10086, @10086, @10086];
    [mutableArray replaceObjectsInRange:range withObjectsFromArray:fromArray];
    XCTAssert([mutableArray isCompleteEqualToArray:array]);
    
    range = NSMakeRange(1, 0);
    fromArray = @[@10086, @10086, @10086];
    NSArray *changedArray = @[@0, @10086, @10086, @10086, @1, @2, @3, @4, @5];
    [mutableArray replaceObjectsInRange:range withObjectsFromArray:fromArray];
    XCTAssert([mutableArray isCompleteEqualToArray:changedArray]);
    
    mutableArray = array.mutableCopy;
    range = NSMakeRange(5, 1);
    fromArray = @[@10086, @10086];
    changedArray = @[@0, @1, @2, @3, @4, @10086, @10086];
    [mutableArray replaceObjectsInRange:range withObjectsFromArray:fromArray];
    XCTAssert([mutableArray isCompleteEqualToArray:changedArray]);
}

- (void)test_HMDProtectContainers_NSMutableArray_replaceObjectsInRange_withObjectsFromArray_range {
    NSArray<NSNumber *> *array = @[@0, @1, @2, @3, @4, @5];
    NSMutableArray<NSNumber *> *mutableArray = array.mutableCopy;
    
    NSRange range = NSMakeRange(0, 7);
    NSRange fromRange = NSMakeRange(0, 1);
    NSArray *fromArray = @[@10086, @10086, @10086];
    [mutableArray replaceObjectsInRange:range withObjectsFromArray:fromArray range:fromRange];
    XCTAssert([mutableArray isCompleteEqualToArray:array]);
    
    range = NSMakeRange(1, 2);
    fromRange = NSMakeRange(1, 3);
    fromArray = @[@10086, @10086, @10086];
    [mutableArray replaceObjectsInRange:range withObjectsFromArray:fromArray range:fromRange];
    XCTAssert([mutableArray isCompleteEqualToArray:array]);
    
    range = NSMakeRange(1, 2);
    fromRange = NSMakeRange(0, 1);
    fromArray = @[@10086, @10086, @10086];
    NSArray *changedArray = @[@0, @10086, @3, @4, @5];
    [mutableArray replaceObjectsInRange:range withObjectsFromArray:fromArray range:fromRange];
    XCTAssert([mutableArray isCompleteEqualToArray:changedArray]);
    
    mutableArray = array.mutableCopy;
    range = NSMakeRange(0, 6);
    fromRange = NSMakeRange(0, 3);
    fromArray = @[@10086, @10086, @10086];
    changedArray = @[@10086, @10086, @10086];
    [mutableArray replaceObjectsInRange:range withObjectsFromArray:fromArray range:fromRange];
    XCTAssert([mutableArray isCompleteEqualToArray:changedArray]);
}

- (void)test_HMDProtectContainers_NSMutableArray_setObject_atIndexedSubscript {
    NSMutableArray *array = @[@0, @1, @2, @3, @4, @5].mutableCopy;
    NSMutableArray *copiedArray = [array copy];
    array[array.count+1] = nil;
    array[array.count+1] = @(6);
    array[-1] = @(7);
    array[0] = nil;
    XCTAssert([array isEqualToArray:copiedArray]);
    array[array.count] = @(6);
    XCTAssert(array.count == copiedArray.count + 1);
}

#pragma mark - NSDictionary

- (void)test_HMDProtectContainers_NSDictionary_dictionaryWithObjects_forKeys {
    NSArray *objects = @[];
    NSArray *keys = @[];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects
                                                           forKeys:keys];
    XCTAssert(dictionary != nil);
    XCTAssert(dictionary.count == 0);
    
    objects = @[@1, @2, @3];
    keys = @[@"1", @"2", @"3", @"4"];
    dictionary = [NSDictionary dictionaryWithObjects:objects
                                             forKeys:keys];
    XCTAssert(dictionary == nil);
    
    objects = @[@1, @2, @3, @4];
    keys = @[@"1", @"2", @"3"];
    dictionary = [NSDictionary dictionaryWithObjects:objects
                                             forKeys:keys];
    XCTAssert(dictionary == nil);
    
    objects = @[@1, @2, @3];
    keys = @[@"1", @"2", @"3"];
    dictionary = [NSDictionary dictionaryWithObjects:objects
                                             forKeys:keys];
    XCTAssert(dictionary != nil);
    XCTAssert(dictionary.count == 3);
}

- (void)test_HMDProtectContainers_NSDictionary_dictionaryWithObjects_forKeys_count {
    id objects1[] = {@1, @2, @3};
    id keys1[] = {@"1", @"2", @"3"};
    NSUInteger count = 3;
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects1
                                                           forKeys:keys1
                                                             count:count];
    XCTAssert(dictionary.count == 3);
    
    id objects2[] = {@1, nil, @3};
    id keys2[] = {@"1", @"2", @"3"};
    count = 3;
    dictionary = [NSDictionary dictionaryWithObjects:objects2
                                             forKeys:keys2
                                               count:count];
    XCTAssert(dictionary.count == 2);
    XCTAssert([dictionary[@"1"] isKindOfClass:NSNumber.class]);
    XCTAssert([@1 isEqualToNumber:dictionary[@"1"]]);
    XCTAssert([dictionary[@"3"] isKindOfClass:NSNumber.class]);
    XCTAssert([@3 isEqualToNumber:dictionary[@"3"]]);
    
    id objects3[] = {@1, @2, @3};
    id keys3[] = {@"1", nil, @"3"};
    count = 3;
    dictionary = [NSDictionary dictionaryWithObjects:objects3
                                             forKeys:keys3
                                               count:count];
    XCTAssert(dictionary.count == 2);
    XCTAssert([dictionary[@"1"] isKindOfClass:NSNumber.class]);
    XCTAssert([@1 isEqualToNumber:dictionary[@"1"]]);
    XCTAssert([dictionary[@"3"] isKindOfClass:NSNumber.class]);
    XCTAssert([@3 isEqualToNumber:dictionary[@"3"]]);
}

#pragma mark - NSMutableDictionary

- (void)test_HMDProtectContainers_NSMutableDictionary_setObject_forKey {
    NSDictionary *dictionary = @{
        @"1": @1,
    };
    NSMutableDictionary *mutableDictionary = dictionary.mutableCopy;
    
    [mutableDictionary setObject:nil forKey:@"2"];
    XCTAssert([mutableDictionary isEqualToDictionary:dictionary]);
    
    [mutableDictionary setObject:@2 forKey:nil];
    XCTAssert([mutableDictionary isEqualToDictionary:dictionary]);
    
    NSDictionary *changedDictionary = @{
        @"1": @1,
        @"2": @2,
    };
    [mutableDictionary setObject:@2 forKey:@"2"];
    XCTAssert([mutableDictionary isEqualToDictionary:changedDictionary]);
}

- (void)test_HMDProtectContainers_NSMutableDictionary_setValue_forKey {
    NSDictionary *dictionary = @{
        @"1": @1,
    };
    NSMutableDictionary *mutableDictionary = dictionary.mutableCopy;
    
    [mutableDictionary setValue:nil forKey:@"2"];
    XCTAssert([mutableDictionary isEqualToDictionary:dictionary]);
    
    [mutableDictionary setValue:@2 forKey:nil];
    XCTAssert([mutableDictionary isEqualToDictionary:dictionary]);
    
    NSDictionary *changedDictionary = @{
    };
    [mutableDictionary setValue:nil forKey:@"1"];
    XCTAssert([mutableDictionary isEqualToDictionary:changedDictionary]);
    
    mutableDictionary = dictionary.mutableCopy;
    changedDictionary = @{
        @"1": @1,
        @"2": @2,
    };
    [mutableDictionary setValue:@2 forKey:@"2"];
    XCTAssert([mutableDictionary isEqualToDictionary:changedDictionary]);
}

- (void)test_HMDProtectContainers_NSMutableDictionary_removeObjectForKey {
    NSDictionary *dictionary = @{
        @"1": @1,
    };
    NSMutableDictionary *mutableDictionary = dictionary.mutableCopy;
    
    [mutableDictionary removeObjectForKey:@"2"];
    XCTAssert([mutableDictionary isEqualToDictionary:dictionary]);
    
    [mutableDictionary removeObjectForKey:nil];
    XCTAssert([mutableDictionary isEqualToDictionary:dictionary]);
    
    NSDictionary *changedDictionary = @{
    };
    [mutableDictionary removeObjectForKey:@"1"];
    XCTAssert([mutableDictionary isEqualToDictionary:changedDictionary]);
}

- (void)test_HMDProtectContainers_NSMutableDictionary_setObject_forKeyedSubscript {
    NSDictionary *dictionary = @{
        @"1": @1,
    };
    NSMutableDictionary *mutableDictionary = dictionary.mutableCopy;
    
    [mutableDictionary setObject:nil forKeyedSubscript:@"2"];
    XCTAssert([mutableDictionary isEqualToDictionary:dictionary]);
    
    [mutableDictionary setObject:@2 forKeyedSubscript:nil];
    XCTAssert([mutableDictionary isEqualToDictionary:dictionary]);
    
    NSDictionary *changedDictionary = @{
    };
    [mutableDictionary setObject:nil forKeyedSubscript:@"1"];
    XCTAssert([mutableDictionary isEqualToDictionary:changedDictionary]);
    
    mutableDictionary = dictionary.mutableCopy;
    changedDictionary = @{
        @"1": @1,
        @"2": @2,
    };
    [mutableDictionary setObject:@2 forKeyedSubscript:@"2"];
    XCTAssert([mutableDictionary isEqualToDictionary:changedDictionary]);
}

#pragma mark - NSSet

- (void)test_HMDProtectContainers_NSSet_intersectsSet {
    NSSet *aSet = [NSSet set];
    NSObject *anObject = [[NSObject alloc] init];
    [aSet intersectsSet:anObject];
}

- (void)test_HMDProtectContainers_NSSet_isEqualToSet {
    NSSet *aSet = [NSSet set];
    NSObject *anObject = [[NSObject alloc] init];
    [aSet isEqualToSet:anObject];
}

- (void)test_HMDProtectContainers_NSSet_isSubsetOfSet {
    NSSet *aSet = [NSSet set];
    NSObject *anObject = [[NSObject alloc] init];
    [aSet isSubsetOfSet:anObject];
}

#pragma mark - NSMutableSet

- (void)test_HMDProtectContainers_NSMutableSet_addObject {
    NSMutableSet *mutableSet = [NSMutableSet set];
    [mutableSet addObject:nil];
}

- (void)test_HMDProtectContainers_NSMutableSet_removeObject {
    NSMutableSet *mutableSet = [NSMutableSet set];
    [mutableSet removeObject:nil];
}

- (void)test_HMDProtectContainers_NSMutableSet_addObjectsFromArray {
    NSMutableSet *mutableSet = [NSMutableSet set];
    NSObject *anObject = [[NSObject alloc] init];
    [mutableSet addObjectsFromArray:anObject];
}

- (void)test_HMDProtectContainers_NSMutableSet_unionSet {
    NSMutableSet *mutableSet = [NSMutableSet set];
    NSObject *anObject = [[NSObject alloc] init];
    [mutableSet unionSet:anObject];
}

- (void)test_HMDProtectContainers_NSMutableSet_intersectSet {
    NSMutableSet *mutableSet = [NSMutableSet set];
    NSObject *anObject = [[NSObject alloc] init];
    [mutableSet intersectsSet:anObject];
}

- (void)test_HMDProtectContainers_NSMutableSet_minusSet {
    NSMutableSet *mutableSet = [NSMutableSet set];
    NSObject *anObject = [[NSObject alloc] init];
    [mutableSet minusSet:anObject];
}

- (void)test_HMDProtectContainers_NSMutableSet_setSet {
    NSMutableSet *mutableSet = [NSMutableSet set];
    NSObject *anObject = [[NSObject alloc] init];
    [mutableSet setSet:anObject];
}

#pragma mark - NSOrderedSet

- (void)test_HMDProtectContainers_NSOrderedSet_objectAtIndex {
    NSMutableOrderedSet *orderSet = [[NSMutableOrderedSet alloc] init];
    id value = [orderSet objectAtIndex:0];
    XCTAssert(value == nil);
    value = [orderSet objectAtIndex:1];
    XCTAssert(value == nil);
    
    [orderSet addObject:@0];
    [orderSet addObject:@1];
    [orderSet addObject:@2];
    [orderSet addObject:@3];
    value = [orderSet objectAtIndex:0];
    XCTAssert([@0 isEqual:value]);
    value = [orderSet objectAtIndex:1];
    XCTAssert([@1 isEqual:value]);
}

- (void)test_HMDProtectContainers_NSOrderedSet_objectsAtIndexes {
    NSMutableOrderedSet *orderSet = [[NSMutableOrderedSet alloc] init];
    NSMutableIndexSet *mutableSet = [[NSMutableIndexSet alloc] init];
    [mutableSet addIndex:0];
    [mutableSet addIndex:1];
    NSArray *value = [orderSet objectsAtIndexes:mutableSet];
    XCTAssert(value == nil);
    
    [orderSet addObject:@0];
    [orderSet addObject:@1];
    [orderSet addObject:@2];
    [orderSet addObject:@3];
    
    value = [orderSet objectsAtIndexes:mutableSet];
    NSArray *changedArray = @[@0, @1];
    XCTAssert([value isEqualToArray:changedArray]);
}

- (void)test_HMDProtectContainers_NSOrderedSet_getObjects_range {
    NSMutableOrderedSet *orderSet = [[NSMutableOrderedSet alloc] init];
    [orderSet addObject:@0];
    [orderSet addObject:@1];
    [orderSet addObject:@2];
    [orderSet addObject:@3];
    
    id __unsafe_unretained objects1[2];
    NSRange range = NSMakeRange(3, 2);
    [orderSet getObjects:objects1 range:range];
    XCTAssert(objects1[0] == nil);
    XCTAssert(objects1[1] == nil);
    
    id __unsafe_unretained objects2[4];
    range = NSMakeRange(0, 4);
    [orderSet getObjects:objects2 range:range];
    XCTAssert([@0 isEqual:objects2[0]]);
    XCTAssert([@1 isEqual:objects2[1]]);
    XCTAssert([@2 isEqual:objects2[2]]);
    XCTAssert([@3 isEqual:objects2[3]]);
}

#pragma mark - NSMutableOrderedSet

- (void)test_HMDProtectContainers_NSMutableOrderedSet_setObject_atIndex {
    NSMutableOrderedSet *mutableSet = [[NSMutableOrderedSet alloc] init];
    [mutableSet addObject:@0];
    [mutableSet addObject:@1];
    [mutableSet addObject:@2];
    [mutableSet addObject:@3];
    [mutableSet addObject:@4];
    [mutableSet addObject:@5];
    NSOrderedSet *solidSet = mutableSet.copy;
    
    [mutableSet setObject:nil atIndex:0];
    XCTAssert([mutableSet isEqualToOrderedSet:solidSet]);
    
    [mutableSet setObject:@7 atIndex:7];
    XCTAssert([mutableSet isEqualToOrderedSet:solidSet]);
    
    NSMutableOrderedSet *changedSet = solidSet.mutableCopy;
    [changedSet addObject:@6];
    [mutableSet setObject:@6 atIndex:6];
    XCTAssert([mutableSet isEqualToOrderedSet:changedSet]);
}

- (void)test_HMDProtectContainers_NSMutableOrderedSet_addObject {
    NSMutableOrderedSet *mutableSet = [[NSMutableOrderedSet alloc] init];
    [mutableSet addObject:@0];
    [mutableSet addObject:@1];
    [mutableSet addObject:@2];
    [mutableSet addObject:@3];
    [mutableSet addObject:@4];
    [mutableSet addObject:@5];
    NSOrderedSet *solidSet = mutableSet.copy;
    
    [mutableSet addObject:nil];
    XCTAssert([mutableSet isEqualToOrderedSet:solidSet]);
    
    NSMutableOrderedSet *changedSet = solidSet.mutableCopy;
    [changedSet addObject:@6];
    [mutableSet addObject:@6];
    XCTAssert([mutableSet isEqualToOrderedSet:changedSet]);
}

- (void)test_HMDProtectContainers_NSMutableOrderedSet_addObjects_count {
    NSMutableOrderedSet *mutableSet = [[NSMutableOrderedSet alloc] init];
    [mutableSet addObject:@0];
    [mutableSet addObject:@1];
    [mutableSet addObject:@2];
    [mutableSet addObject:@3];
    [mutableSet addObject:@4];
    [mutableSet addObject:@5];
    NSOrderedSet *solidSet = mutableSet.copy;
    
    id __unsafe_unretained objects1[] = {@0, nil, @2};
    NSUInteger count = 3;
    [mutableSet addObjects:objects1 count:3];
    XCTAssert([mutableSet isEqualToOrderedSet:solidSet]);
    
    
    NSMutableOrderedSet *changedSet = solidSet.mutableCopy;
    [changedSet addObject:@0];
    [mutableSet addObject:@1];
    [mutableSet addObject:@2];
    
    id __unsafe_unretained objects2[] = {@0, @1, @2};
    count = 3;
    [mutableSet addObjects:objects2 count:3];
    XCTAssert([mutableSet isEqualToOrderedSet:changedSet]);
}

//- (void)test_HMDProtectContainers_<#ClassName#>_<#methodName#> {
//    
//}


@end
