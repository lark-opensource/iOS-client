//
//  IESGurdLRUCacheLinkedList.m
//  Pods
//
//  Created by 陈煜钏 on 2019/8/20.
//

#import "IESGurdLRUCacheLinkedList.h"

#import "IESGurdLRUCacheLinkedNode.h"

@interface IESGurdLRUCacheLinkedList ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, IESGurdLRUCacheLinkedNode *> *linkedNodeDictionary;

@property (nonatomic, weak) IESGurdLRUCacheLinkedNode *headLinkedNode;

@property (nonatomic, weak) IESGurdLRUCacheLinkedNode *tailLinkedNode;

@end

@implementation IESGurdLRUCacheLinkedList

#pragma mark - Public

- (NSArray<NSString *> *)allChannels
{
    @synchronized (self) {
        NSMutableArray<NSString *> *channels = [NSMutableArray array];
        IESGurdLRUCacheLinkedNode *linkedNode = self.headLinkedNode;
        while (linkedNode) {
            [channels addObject:linkedNode.channel];
            linkedNode = linkedNode.nextLinkedNode;
        }
        return [channels copy];
    }
}

- (void)appendLinkedNodeForChannel:(NSString *)channel
{
    if (channel.length == 0) {
        return;
    }
    IESGurdLRUCacheLinkedNode *linkedNode = [IESGurdLRUCacheLinkedNode nodeWithChannel:channel];
    @synchronized (self) {
        if (!self.linkedNodeDictionary[channel]) {
            self.linkedNodeDictionary[channel] = linkedNode;
            
            if (self.tailLinkedNode) {
                self.tailLinkedNode.nextLinkedNode = linkedNode;
                linkedNode.preLinkedNode = self.tailLinkedNode;
            }
            self.tailLinkedNode = linkedNode;
            
            if (!self.headLinkedNode) {
                self.headLinkedNode = linkedNode;
            }
        }
    }
}

- (void)bringLinkedNodeToHeadForChannel:(NSString *)channel
{
    @synchronized (self) {
        IESGurdLRUCacheLinkedNode *linkedNode = self.linkedNodeDictionary[channel];
        if (!linkedNode) {
            return;
        }
        if (self.headLinkedNode == linkedNode) {
            return;
        }
        
        linkedNode.preLinkedNode.nextLinkedNode = linkedNode.nextLinkedNode;
        linkedNode.nextLinkedNode.preLinkedNode = linkedNode.preLinkedNode;
        
        if (self.tailLinkedNode == linkedNode) {
            self.tailLinkedNode = linkedNode.preLinkedNode;
        }
        
        if (self.headLinkedNode) {
            linkedNode.nextLinkedNode = self.headLinkedNode;
            self.headLinkedNode.preLinkedNode = linkedNode;
        }
        
        self.headLinkedNode = linkedNode;
        linkedNode.preLinkedNode = nil;
    }
}

- (NSArray<NSString *> *)channelsToBeDelete
{
    __block NSMutableArray *channels = nil;
    @synchronized (self) {
        NSInteger removeCount = self.linkedNodeDictionary.count - self.capacity;
        if (removeCount <= 0) {
            return channels;
        }
        
        channels = [NSMutableArray array];
        IESGurdLRUCacheLinkedNode *tailLinkNode = self.tailLinkedNode;
        while (removeCount > 0) {
            [channels addObject:tailLinkNode.channel];
            
            tailLinkNode = tailLinkNode.preLinkedNode;
            removeCount--;
        }
    }
    return [channels copy];
}

- (void)deleteLinkedNodeForChannel:(NSString *)channel
{
    if (channel.length == 0) {
        return;
    }
    @synchronized (self) {
        IESGurdLRUCacheLinkedNode *linkedNode = self.linkedNodeDictionary[channel];
        if (!linkedNode) {
            return;
        }
        [self.linkedNodeDictionary removeObjectForKey:channel];
        
        if (self.headLinkedNode == linkedNode) {
            self.headLinkedNode = linkedNode.nextLinkedNode;
        } else if (self.tailLinkedNode == linkedNode) {
            self.tailLinkedNode = linkedNode.preLinkedNode;
        }
        
        linkedNode.nextLinkedNode.preLinkedNode = linkedNode.preLinkedNode;
        linkedNode.preLinkedNode.nextLinkedNode = linkedNode.nextLinkedNode;
        
    }
}

#pragma mark - Private

- (NSString *)description
{
    __block NSMutableString *description = nil;
    @synchronized (self) {
        if (self.linkedNodeDictionary.count == 0) {
            return @"Empty list";
        }
        description = [NSMutableString string];
        IESGurdLRUCacheLinkedNode *currentNode = self.headLinkedNode;
        while (currentNode) {
            [description appendFormat:@"%@", currentNode.channel];
            if (currentNode.nextLinkedNode) {
                [description appendString:@"->"];
            }
            currentNode = currentNode.nextLinkedNode;
        }
    }
    return [description copy];
}

#pragma mark - Getter

- (NSMutableDictionary<NSString *, IESGurdLRUCacheLinkedNode *> *)linkedNodeDictionary
{
    if (!_linkedNodeDictionary) {
        _linkedNodeDictionary = [NSMutableDictionary dictionary];
    }
    return _linkedNodeDictionary;
}

@end
