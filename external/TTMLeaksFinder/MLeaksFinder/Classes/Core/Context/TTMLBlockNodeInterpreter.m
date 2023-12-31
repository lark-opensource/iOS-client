//
//  TTMLBlockInterpreter.m
//  TTMLeaksFinder-Pods-Aweme
//
//  Created by maruipu on 2020/12/9.
//

#import "TTMLBlockNodeInterpreter.h"
#import "TTMLLeakCycle.h"
#import <FBRetainCycleDetector/FBBlockInterface.h>

NSString * const TTMLBlockNodeAddressKey = @"TTMLBlockNodeAddressKey";
NSString * const TTMLBlockNodeNameKey = @"TTMLBlockNodeNameKey";

@interface TTMLBlockNodeInterpreter ()

@end

@implementation TTMLBlockNodeInterpreter
//block符号化
- (void)interpretCycleNode:(TTMLLeakCycleNode *)node withObject:(id)object {
    if (!node.isBlock) {
        return;
    }
    struct BlockLiteral *blockLiteral = (__bridge struct BlockLiteral *)(object);
    uint64_t address = (uint64_t *)blockLiteral->invoke;
    [node.extra addEntriesFromDictionary: @{
        TTMLBlockNodeAddressKey: @(address),
        TTMLBlockNodeNameKey: [NSString stringWithFormat:@"%lu - %@", node.index, node.className]
    }];
}

@end
