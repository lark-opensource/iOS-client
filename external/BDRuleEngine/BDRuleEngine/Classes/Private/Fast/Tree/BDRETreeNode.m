//
//  BDRETreeNode.m
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/12.
//

#import "BDRETreeNode.h"
#import "BDRECommand.h"

@implementation BDRETreeNode

- (instancetype)initWithCommand:(BDRECommand *)command children:(NSArray<BDRETreeNode *> *)children
{
    if (self = [super init]) {
        _command = command;
        _children = children;
    }
    return self;
}

@end
