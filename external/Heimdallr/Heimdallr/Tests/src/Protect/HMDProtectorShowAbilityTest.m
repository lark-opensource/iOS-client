//
//  HMDProtectorShowAbilityTest.m
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

@interface MYObserver: NSObject @end
@implementation MYObserver @end
@interface MYObservee : NSObject
@property (nonatomic, assign) int count;
@end
@implementation MYObservee @end

@interface HMDProtectorShowAbilityTest : XCTestCase
@end @implementation HMDProtectorShowAbilityTest

+ (void)setUp {
    HMD_mockClassTreeForClassMethod(HeimdallrUtilities, canFindDebuggerAttached, ^(Class aClass){return NO;});
    HMDProtectTestEnvironment = YES;
    [HMDProtector.sharedProtector turnProtectionsOn:HMDProtectionTypeAll];
    [HMDProtector.sharedProtector enableNanoCrashProtect];
    // [HMDProtector.sharedProtector enableQosOverCommitProtect];
    [HMDProtector.sharedProtector enableAssertProtect];
    HMDProtector.sharedProtector.ignoreTryCatch = NO;
}

+ (void)tearDown {
    HMDProtectTestEnvironment = NO;
    [HMDProtector.sharedProtector turnProtectionOff:HMDProtectionTypeAll];
    [HMDProtector.sharedProtector disableAssertProtect];
    HMDProtector.sharedProtector.ignoreTryCatch = YES;
}

#pragma mark - 前言 (向业务方展示安全气垫功能)

/*
        [ Heimdallr 安全气垫 ]
 
          对于常见的 Objective-C 基础类型 和 常见系统类的方法进行防护
          检测传入参数的正确与否, 防止直接执行系统实现引起的崩溃
 
          对于回引起崩溃的方法调用, 例如数组下标越界:
          会直接拦截该调用, 不会调用对应的原实现方法

          对于非法 KVC 访问, 或者没有移除的 KVO 回调防护
          对于 unrecognized selector 防护
 
          对于有参数返回的方法调用,
          如果因为传入参数问题被拦截, 会返回 nil 返回值
          如果当前传入参数正常, 那么就会返回 正常 返回值
 
        [ 当前安全气垫防护的方法 ]
 
        [1] Number 类型
 
          -[NSNumber compare:]
          -[NSNumber isEqualToNumber]
 
        [2] String 类型
 
          -[NSString characterAtIndex:]
          -[NSString substringFromIndex:]
          -[NSString substringToIndex:]
          -[NSString substringWithRange:]
          -[NSString stringByReplacingCharactersInRange:withString:]
          -[NSString stringByAppendingString:]
          -[NSMutableString appendString:]
          -[NSMutableString replaceCharactersInRange:withString:]
          -[NSMutableString insertString:atIndex:]
          -[NSMutableString deleteCharactersInRange:]
          -[NSAttributeString initWithString:]
          -[NSAttributeString initWithString:attributes:]
          -[NSAttributeString attributedSubstringFromRange:]
          -[NSAttributeString enumerateAttribute:inRange:options:usingBlock:]
          -[NSAttributeString enumerateAttributesInRange:options:usingBlock:]
          -[NSAttributeString dataFromRange:documentAttributes:error:]
          -[NSAttributeString fileWrapperFromRange:documentAttributes:error:]
          -[NSAttributeString containsAttachmentsInRange:]
          -[NSMutableAttributedString replaceCharactersInRange:withString:]
          -[NSMutableAttributedString deleteCharactersInRange:]
          -[NSMutableAttributedString setAttributes:range:]
          -[NSMutableAttributedString addAttribute:value:range:]
          -[NSMutableAttributedString addAttributes:range:]
          -[NSMutableAttributedString removeAttribute:range:]
          -[NSMutableAttributedString insertAttributedString:atIndex:]
          -[NSMutableAttributedString replaceCharactersInRange:withAttributedString:]
          -[NSMutableAttributedString fixAttributesInRange:]
 
        [3] Array 类型
 
          +[NSArray arrayWithObjects:count:]
          -[NSArray objectsAtIndexes:]
          -[NSArray objectAtIndex]
          -[NSArray objectAtIndexedSubscript:]
          -[NSArray subarrayWithRange:]
          -[NSMutableArray removeObjectAtIndex:]
          -[NSMutableArray removeObjectsInRange:]
          -[NSMutableArray removeObjectsAtIndexes:]
          -[NSMutableArray insertObject:atIndex:]
          -[NSMutableArray insertObjects:atIndexes:]
          -[NSMutableArray replaceObjectAtIndex:withObject:]
          -[NSMutableArray replaceObjectsAtIndexes:withObjects:]
          -[NSMutableArray replaceObjectsInRange:withObjectsFromArray:]
          -[NSMutableArray replaceObjectsInRange:withObjectsFromArray:range:]
          -[NSMutableArray setObject:atIndexedSubscript:]
 
        [4] Dictionary 类型
 
          +[NSDictionary dictionaryWithObjects:forKeys:]
          +[NSDictionary dictionaryWithObjects:forKeys:count]
          -[NSMutableDictionary setObject:forKey:]
          -[NSMutableDictionary setValue:forKey:]
          -[NSMutableDictionary removeObjectForKey]
          -[NSMutableDictionary setObject:forKeyedSubscript:]
 
        [5] Set 类型
 
          -[NSSet intersectsSet:]
          -[NSSet isEqualToSet:]
          -[NSSet isSubsetOfSet:]
          -[NSMutableSet addObject:]
          -[NSMutableSet removeObject:]
          -[NSMutableSet addObjectsFromArray:]
          -[NSMutableSet unionSet:]
          -[NSMutableSet intersectSet:]
          -[NSMutableSet minusSet:]
          -[NSMutableSet setSet:]
          -[NSOrderedSet objectAtIndex:]
          -[NSOrderedSet objectsAtIndexes:]
          -[NSOrderedSet getObjects:range:]
          -[NSOrderedSet setObject:]
          -[NSMutableOrderedSet setObject:atIndex:]
          -[NSMutableOrderedSet addObject:]
          -[NSMutableOrderedSet addObjects:count:]
          -[NSMutableOrderedSet insertObject:atIndex:]
          -[NSMutableOrderedSet insertObjects:atIndexes:]
          -[NSMutableOrderedSet exchangeObjectAtIndex:withObjectAtIndex:]
          -[NSMutableOrderedSet moveObjectsAtIndexes:toIndex:]
          -[NSMutableOrderedSet replaceObjectAtIndex:withObject:]
          -[NSMutableOrderedSet replaceObjectsInRange:withObjects:count:]
          -[NSMutableOrderedSet replaceObjectsAtIndexes:withObjects:]
          -[NSMutableOrderedSet removeObjectAtIndex:]
          -[NSMutableOrderedSet removeObject:]
          -[NSMutableOrderedSet removeObjectsInRange:]
          -[NSMutableOrderedSet removeObjectsAtIndexes:]
          -[NSMutableOrderedSet removeObjectsInArray:]
 
        [6] URL 类型
 
          -[NSURL initFileURLWithPath:]
          -[NSURL initFileURLWithPath:isDirectory:]
          -[NSURL initFileURLWithPath:relativeToURL:]
          -[NSURL initFileURLWithPath:isDirectory:]
          -[NSURL initFileURLWithFileSystemRepresentation:isDirectory:relativeToURL:]
          -[NSURL initWithString:]
          -[NSURL initWithString:relativeToURL:]
          -[NSURL initAbsoluteURLWithDataRepresentation:relativeToURL:]
          -[NSURL initWithDataRepresentation:relativeToURL:]
 
        [7] Layer 类型
 
          -[CALayer setPosition:]
 
        [8] KVC 类型
 
          -[NSObject valueForKey:]
          -[NSObject valueForKeyPath:]
          -[NSObject valueForUndefinedKey:]
          -[NSObject setValue:forKey:]
          -[NSObject setValue:forKeyPath:]
          -[NSObject setValue:forUndefinedKey:]
          -[NSObject setValuesForKeysWithDictionary:]
          -[NSObject valueForKey:]
          -[NSObject valueForKey:]
 
        [9] KVO 类型
 
          -[NSObject addObserver:forKeyPath:options:context:]
          -[NSObject removeObserver:forKeyPath:]
          -[NSObject removeObserver:forKeyPath:context:]
 
        [10] Notification 类型
 
          -[NSNotificationCenter addObserver:selector:name:object:]
          -[NSNotificationCenter removeObserver:]
          -[NSNotificationCenter removeObserver:name:object:]
 
        [11] Assert 类型
 
            NSAssert(...)
           NSCAssert(...)
 
        [12] USEL 类型
 
          -[NSObject forwardingTargetForSelector:]
          +[NSObject forwardingTargetForSelector:]
          -[NSObject doesNotRecognizeSelector:]
 
        [13] UserDefaults 类型
 
          -[NSUserDefaults setObject:forKey:]
          -[_CFXPreferences copyAppValueForKey:identifier:container:configurationURL:]
 
 */

#pragma mark - Number 方法的防护

- (void)test_Number_exception {
    
    NSNumber *number;
    
    // [1] Number 比较的时刻
    // 传入nil 参数, 可以防护异常
    // 现在默认返回为: NSOrderedDescending & NO
    
    number = @(100);
    
    id nilObject = nil;
    [number compare:nilObject];
    
    BOOL value = [number isEqualToNumber:nilObject];
    XCTAssert(value == NO);
}

#pragma mark - String 方法的防护

- (void)test_String_exception {
    
    NSString *string;
    NSMutableString *mutableString;
    
    // [1] String 访问下标越界
    // 可以防护异常, 并且返回为 nil (0) 参数

    string = @"012";
    unichar character = [string characterAtIndex:3];
    XCTAssert(character == 0);
    
    id value = [string substringFromIndex:100];
    XCTAssert(value == nil);
    
    value = [string substringToIndex:100];
    XCTAssert(value == nil);
    
    // [2] String 方法传入参数不正确
    // 可以防护异常, 并且无效化操作
    
    string = @"012";
    mutableString = [NSMutableString stringWithString:string];
    
    id aNumber = @(1);
    [mutableString appendString:aNumber];
    
    id nilObject = nil;
    [mutableString insertString:nilObject atIndex:0];
}


#pragma mark - Array 方法的防护

- (void)test_Array_exception {
    
    NSArray *array;
    
    // [1] Array 访问下标越界
    // 可以防护异常, 并且返回为 nil 参数
    
    array = @[@0, @1, @2];
    id value = array[3];
    XCTAssert(value == nil);
    
    
    // [2] Array @[...] 语法糖创建的时刻
    // 传递 nil 元素, 创建 array 失败返回 nil
    
    id nilObject = nil;
    array = @[@0, @1, nilObject];
    XCTAssert(array == nil);
    
    // [3] Array 一些常见的方法也可以防护,
    // 将操作变为无效, 返回类型为 nil
    // 例如:
    // +[NSArray arrayWithObjects:count:]
    // -[NSArray objectsAtIndexes:]
    // -[NSArray objectAtIndex]
    // ....
    
    id objects[] = {@0, nil, @2};
    array = [NSArray arrayWithObjects:objects count:3];
    XCTAssert(array == nil);
    
    array = @[@0, @1, @2];
    id indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 4)];
    value = [array objectsAtIndexes:indexSet];
    XCTAssert(value == nil);
    
    array = @[@0, @1, @2];
    value = [array objectAtIndex:3];
    XCTAssert(value == nil);
    
    // NSMutableArray 下标操作
    // 传递 nil 元素或越界，不改变原 NSMutableArray
    NSMutableArray *mutableArray = array.mutableCopy;
    mutableArray[mutableArray.count+1] = nil;
    mutableArray[mutableArray.count+1] = @(6);
    mutableArray[-1] = @(7);
    mutableArray[0] = nil;
    XCTAssert([array isEqualToArray:mutableArray]);
}

#pragma mark - Dictionary 方法的防护

- (void)test_Dictionary_exception {
    
    NSDictionary<NSString *, NSString *> *dictionary;
    NSMutableDictionary<NSString *, NSString *> *mutableDictionary;

    // [1] Dictionary 创建的时刻
    // 有传入参数为 nil 的情况
    // 会忽略有 nil 的 key-value 键对
    
    id nilObject = nil;
    dictionary = @{@"key1": @"value1", @"key2": nilObject};
    
    XCTAssert(dictionary != nil);
    XCTAssert([[dictionary valueForKey:@"key1"] isEqualToString:@"value1"]);
    XCTAssert([dictionary valueForKey:@"key2"] == nil);

    // [2] Dictionary 添加/删除键对的时刻
    // 有传入参数为 nil 的情况
    // 会忽略有 nil 的 key-value 键对
    
    dictionary = @{@"key1": @"value1", @"key2": @"value2"};
    mutableDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    
    nilObject = nil;
    [mutableDictionary setObject:nilObject forKey:@"key3"];
    [mutableDictionary setValue:@"value4" forKey:nilObject];
    [mutableDictionary removeObjectForKey:nilObject];
}

#pragma mark - Set 方法的防护

- (void)test_Set_exception {
    
    NSSet *set = [NSSet setWithArray:@[@0, @1, @2]];
    NSMutableOrderedSet *orderSet = [NSMutableOrderedSet orderedSetWithSet:set];
    
    // [1] Set 访问下标越界
    // 可以防护异常, 并且返回为 nil 参数
    
    id value = [orderSet objectAtIndex:3];
    XCTAssert(value == nil);
    
    // [2] Set 对于传入参数为 nil
    //     会不执行该处的方法
    
    id nilObject = nil;
    [orderSet setObject:nilObject atIndex:0];
    [orderSet insertObject:nilObject atIndex:0];
}

#pragma mark - URL

- (void)test_URL_exception {
    
    NSURL *url;
    
    // [1] 对于传入参数检查
    // 可以防护异常, 并且返回为 nil 参数
    
    id nilObject = nil;
    
    url = [[NSURL alloc] initFileURLWithPath:nilObject];
    XCTAssert(url == nil);
    
    url = [[NSURL alloc] initWithString:nilObject];
    XCTAssert(url == nil);
    
    url = [[NSURL alloc] initWithString:nilObject relativeToURL:nil];
    XCTAssert(url == nil);
}

#pragma mark - KVC 类型

- (void)test_KVC_exception {
    
    NSObject *object = [NSObject new];
    
    // [1] 对于传入不存在的键值
    // 可以防护异常, 并且不会产生崩溃
    
    [object setValue:@"数据" forKey:@"不存在的KEY"];
    
    // [2] 对于获取不存在的键值
    // 可以防护异常, 并且返回 nil

    id value = [object valueForKey:@"不存在的KEY"];
    XCTAssert(value == nil);
}

#pragma mark - KVO 类型

//- (void)test_KVO_observer_dealloc_exception {
//
//    MYObservee *observee = [MYObservee new];
//    MYObserver *observer = [MYObserver new];
//
//    // [1] Observer 在销毁时未移除 KVO，之后 observee 被监听属性发生变化
//    // 系统行为：EXC_BAD_ACCESS
//    // 安全气垫行为：忽略 observee 变化的回调信息
//
//    [observee addObserver:observer
//           forKeyPath:@"bounds"
//              options:NSKeyValueObservingOptionNew
//              context:nil];
//
//    observer = nil;  // 释放 object
//    observee.count = 1; // 产生 KVO 回调
//}

- (void)test_KVO_observee_dealloc_exception {
    // [2] Observee 在销毁时未移除 KVO，iOS < 11.3 时防护崩溃
    // 系统行为：抛出 NSException 异常，An instance <> of class <> was deallocated while key value observers were still registered with it
    // 防护行为：在 Observee dealloc 中移除 KVO
    
    MYObserver *observer = [MYObserver new];
    MYObservee *observee = [MYObservee new];
    [observee addObserver:observer
               forKeyPath:@"count"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
    observee = nil;
}

- (void)test_KVO_remove_unregistered_observer_exception {
    // [3] 对未注册的 observer 调用 [removeObserver:forKeyPath:]
    // 系统行为：抛出 NSException 异常 Cannot remove an observer <MYObserver 0x100f0f3d0> for the key path \"count\" from <MYObservee 0x100f1a530> because it is not registered as an observer.
    // 防护行为：catch 住这种异常
    MYObserver *observer = [MYObserver new];
    MYObservee *observee = [MYObservee new];
    [observee removeObserver:observer forKeyPath:@"count"];
}

//- (void)test_KVO_bad_keypath {
//    // [4] 传入类型不符合预期的 keyPath
//    // 系统行为：抛出 NSException 异常 -[NSObject characterAtIndex:]: unrecognized selector sent to instance 0x132311840
//    // 防护行为：catch 住这种异常
//    MYObserver *observer = [MYObserver new];
//    MYObservee *observee = [MYObservee new];
//    [observee addObserver:observer
//               forKeyPath:[NSObject new]
//                  options:NSKeyValueObservingOptionNew
//                  context:nil];
//}

#pragma mark - Assert 类型

- (void)test_Assert_exception {
    
    // [1] 对于误带上线的 NSAssert NSCAssert 函数
    // 并不会崩溃, 而是自动屏蔽该回调消息
    
    NSAssert(NO, @"崩溃");
}

#pragma mark - Unrecognized SELector 防护

- (void)test_USEL_exception {
    NSObject *object = [NSObject new];
    
    NSString *notString = (id)object;
    
    id value = [notString stringByAppendingString:@"添加字符串"];
    XCTAssert(value == nil);
}

@end
