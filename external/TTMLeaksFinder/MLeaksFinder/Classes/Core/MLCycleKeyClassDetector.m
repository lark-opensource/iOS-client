 //
//  MLCycleKeyClassDetector.m
//  Pods
//
//  Created by xushuangqing on 2020/2/24.
//

#import "MLCycleKeyClassDetector.h"
#import "TTMLUtils.h"
#import <FBRetainCycleDetector/FBObjectiveCGraphElement.h>
#import <FBRetainCycleDetector/FBBlockStrongLayout.h>

@implementation MLCycleKeyClassDetector
//需要返回 index，给计算大小使用
+ (cyle_key_class)keyClassNameForRetainCycle:(NSArray *)retainCycle {
    cyle_key_class keyClassInfo;
    
    keyClassInfo = [self keyClassNameForKeyFeatureInRetainCycle:retainCycle];
    if (keyClassInfo.keyClassName) {
        return keyClassInfo;
    }
    
    keyClassInfo = [self keyClassNameForSubviewInRetainCycle:retainCycle];
    if (keyClassInfo.keyClassName ) {
        return  keyClassInfo;
    }
    
    keyClassInfo = [self keyClassNameForNonSystemInRetainCycle:retainCycle];
    if (keyClassInfo.keyClassName ) {
        return  keyClassInfo;
    }
    
    //Todo：兼容swift（闭包）@langminglang
    
    keyClassInfo.index = 0; // 此处仍然获取一个keyClass是避免RetainCycle中均为系统库，导致无keyClass.
    FBObjectiveCGraphElement *element = [retainCycle objectAtIndex:0];
    keyClassInfo.keyClassName = [element classNameOrNull];

    return keyClassInfo;
}

+ (cyle_key_class)keyClassNameForKeyFeatureInRetainCycle:(NSArray *)retainCycle {
    
    __block cyle_key_class keyClassInfo;
    
    NSInteger retainCycleCount = [retainCycle count];
    NSMutableArray<NSNumber *> *featureIndexes = [[NSMutableArray alloc] init];
    NSMutableArray<NSNumber *> *elementOffsets = [[NSMutableArray alloc] init]; // 从 feature 找到指定 keyClass 的偏移量

    // 注意：下面这几条规则没有写在同一个循环中，是为了保证keyClass查找规则的优先级
    // 如果写在同一个循环中，可能出现低优先级规则的keyClass被先放入队列中处理，而高优先级的keyClass反而无法被找到
    // 由于目前retainCycle的环长、规则数目均不是很大，因此直接对retainCycle遍历多次
    // 后续如果规则数很多或retainCycle很长，可以考虑用排序代替多次遍历
    for (NSInteger i = 0; i < retainCycleCount; i++) {
        FBObjectiveCGraphElement *element = [retainCycle objectAtIndex:i];
        NSString *className = [element classNameOrNull];
        if ([className isEqualToString:@"__NSMallocBlock__"]) { // 特征1: block
            [featureIndexes addObject:@(i)];
            [elementOffsets addObject:@(1)]; // 查找 block 的持有对象（offset = 1)
        }
    }
    
    for (NSInteger i = 0; i < retainCycleCount; i++) {
        FBObjectiveCGraphElement *element = [retainCycle objectAtIndex:i];
        NSString *className = [element classNameOrNull];
        if ([className isEqualToString:@"__NSCFTimer"]) { // 特征2: timer
            [featureIndexes addObject:@(i)];
            [elementOffsets addObject:@(1)]; // 查找 timer 的 target (offset = 1)
        }
    }
    
    for (NSInteger i = 0; i < retainCycleCount; i++) {
        FBObjectiveCGraphElement *element = [retainCycle objectAtIndex:i];
        NSString *className = [element classNameOrNull];
        if ([className isEqualToString:@"FBKVOController"]) { // 特征3: KVO controller
            [featureIndexes addObject:@(i)];
            [elementOffsets addObject:@(retainCycleCount - 1)]; // 查找 KVO 的 observer (offset = -1)
        }
    }
    
    for (NSInteger i = 0; i < retainCycleCount; i++) {
        FBObjectiveCGraphElement *element = [retainCycle objectAtIndex:i];
        if (element.namePath) {
            NSString *namePath = [element.namePath componentsJoinedByString:@" -> "];
            if ([namePath containsString:@"__associated_object"]) { // 特征4: 关联对象
                [featureIndexes addObject:@(i)];
                [elementOffsets addObject:@(retainCycleCount - 1)]; // 查找触发关联对象的实例 (offset = -1)
            }
        }
    }
    
    if ([featureIndexes count] == 0) {
        return keyClassInfo;
    }
    else {
        [featureIndexes enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSNumber class]]) {
                NSNumber *indexNumber = (NSNumber *)obj;
                NSNumber *elementOffset = elementOffsets[idx];
                // 这里再加一个retainCycleCount是防止后续修改时，有人误将offset设为负数导致潜在的数组下标越界。
                NSInteger index = ([indexNumber integerValue] + [elementOffset integerValue] + retainCycleCount) % retainCycleCount;
                FBObjectiveCGraphElement *element = [retainCycle objectAtIndex:index]; //取被 feature 持有的对象
                if (element.object == nil || object_getClass(element.object) == nil) {
                    //pass
                }
                else if ([TTMLUtil objectIsSystemClass:[element object]]) {
                    // pass
                }
                else if (FBObjectIsBlock((__bridge void *)[element object])) {
                    // pass
                }
                else if ([[element classNameOrNull] hasPrefix:@"RAC"]) {
                    // pass
                }
                else {
                    keyClassInfo.keyClassName = [element classNameOrNull];
                    keyClassInfo.index = index;
                    *stop = YES;
                }
            }
        }];
        return keyClassInfo;
    }
}

+ (cyle_key_class)keyClassNameForSubviewInRetainCycle:(NSArray *)retainCycle {
    cyle_key_class keyClassInfo;
    
    NSInteger retainCycleCount = [retainCycle count];
    NSInteger firstSubviewIdx = NSNotFound;
    for (NSInteger i = 0; i < retainCycleCount; i++) {
        FBObjectiveCGraphElement *element = [retainCycle objectAtIndex:i];
        if (element.namePath) {
            NSString *namePath = [element.namePath componentsJoinedByString:@" -> "];
            if ([namePath containsString:@"_subviewCache"]) {
                firstSubviewIdx = i;
                break;
            }
        }
    }
    
    if (firstSubviewIdx == NSNotFound) {
        return keyClassInfo;
    }
    else {
        NSString *subviewClassName = nil;
        NSInteger firstNotSubviewIdx = NSNotFound;
        for (NSInteger i = 0; i < retainCycleCount; i = i + 2) {
            NSInteger idx = (firstSubviewIdx + i) % retainCycleCount;
            FBObjectiveCGraphElement *element = [retainCycle objectAtIndex:idx];
            if (element.namePath) {
                NSString *namePath = [element.namePath componentsJoinedByString:@" -> "];
                if (![namePath containsString:@"_subviewCache"]) {
                    firstNotSubviewIdx = idx;
                    break;
                }
            }
            else {
                firstSubviewIdx = idx;
                break;
            }
        }
        if (firstNotSubviewIdx != NSNotFound) {
            NSInteger idx = (firstNotSubviewIdx + retainCycleCount - 1) % retainCycleCount;
            FBObjectiveCGraphElement *element = [retainCycle objectAtIndex:idx];
            subviewClassName = [element classNameOrNull];
            if (element.object == nil || object_getClass(element.object) == nil) {
                //pass
            }
            else if ([TTMLUtil objectIsSystemClass:[element object]]) {
                // pass
            }
            else if (FBObjectIsBlock((__bridge void *)[element object])) {
                // pass
            }
            else if ([[element classNameOrNull] hasPrefix:@"RAC"]) {
                // pass
            }
            else {
                keyClassInfo.index = idx;
                keyClassInfo.keyClassName = [element classNameOrNull];
            }
        }
        return keyClassInfo;
    }
}


// 兜底策略：查找RetainCycle中的非系统库
+ (cyle_key_class)keyClassNameForNonSystemInRetainCycle:(NSArray *)retainCycle {
    cyle_key_class keyClassInfo;
    
    NSInteger retainCycleCount = [retainCycle count];
    for (NSInteger i = 0; i < retainCycleCount; i++) {
        FBObjectiveCGraphElement *element = [retainCycle objectAtIndex:i];
        if (element.object == nil || object_getClass(element.object) == nil) {
            //pass
        }
        else if ([TTMLUtil objectIsSystemClass:[element object]]) {
            // pass
        }
        else {
            keyClassInfo.index = i;
            keyClassInfo.keyClassName = [element classNameOrNull];
        }
    }
    
    return keyClassInfo;
}

@end
