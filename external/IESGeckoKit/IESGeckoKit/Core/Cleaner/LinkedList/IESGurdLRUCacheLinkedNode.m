//
//  IESGurdLRUCacheLinkedNode.m
//  Pods
//
//  Created by 陈煜钏 on 2019/8/20.
//

#import "IESGurdLRUCacheLinkedNode.h"

@implementation IESGurdLRUCacheLinkedNode

+ (instancetype)nodeWithChannel:(NSString *)channel
{
    IESGurdLRUCacheLinkedNode *node = [[self alloc] init];
    node.channel = channel;
    return node;
}

@end
