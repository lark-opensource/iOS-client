//
//  BDAuoTrackEventBlock.m
//  RangersAppLog
//
//  Created by bytedance on 2022/8/19.
//

#import <Foundation/Foundation.h>
#import "BDAutoTrackDefaults.h"
#import "BDAuoTrackEventBlock.h"

static NSString * const kBDAutoTrackEventBlockListKey          = @"block_list";

@interface BDAuoTrackEventBlock()

@property (nonatomic, strong) NSMutableSet *blockSet;
@property (nonatomic, strong) BDAutoTrackDefaults *defaults;

@end

@implementation BDAuoTrackEventBlock

- (instancetype)initWithAppID:(NSString *)appID {
    if (self) {
        self.appID = appID;
        self.defaults = [BDAutoTrackDefaults defaultsWithAppID:appID];
        self.blockSet = [self createBlockSet];
    }
    return self;
}

- (NSMutableSet *)createBlockSet {
    NSMutableSet *blockSet = [NSMutableSet new];
    NSArray *blockList = [self.defaults arrayValueForKey:kBDAutoTrackEventBlockListKey];
//    NSLog(@"read >>> %@", blockList);
    if (blockList) {
        [blockSet addObjectsFromArray:blockList];
    }
    return blockSet;
}

- (void)updateBlockList:(NSArray *)blockList {
    @synchronized (self) {
        [self.blockSet removeAllObjects];
        [self.blockSet addObjectsFromArray:blockList];
        [self.defaults setValue:self.blockSet.allObjects forKey:kBDAutoTrackEventBlockListKey];
//        NSLog(@"save >>> %@", self.blockSet.allObjects);
    }
}

- (BOOL)hasEvent:(NSString *)event {
    @synchronized (self) {
        if (!self.blockSet) {
            return NO;
        }
        return [self.blockSet containsObject:event];
    }
}

//- (void)testAsync {
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//
//        while (true) {
//            [self updateBlockList:@[@"123123",@"23213123"]];
//        }
//
//      });
//
//
//      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//
//        while (true) {
//          if ([self hasEvent:@"23213"]) {
//            NSLog(@"123");
//          }
//        }
//      });
//}

@end
