//
//  ACCToolBarItemsModel.m
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/6/4.
//

#import "ACCToolBarItemsModel.h"

@interface ACCToolBarItemsModel ()
@property (nonatomic, strong) NSMutableArray<ACCBarItem *> *array;
@property (nonatomic, strong) NSMutableDictionary<NSValue *, ACCBarItem *> *dictionary;
@end

@implementation ACCToolBarItemsModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.array = [NSMutableArray array];
        self.dictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL)addBarItem:(ACCBarItem *)item
{
    NSValue *barItemKey = [NSValue valueWithPointer:item.itemId];
    if (![self.dictionary.allKeys containsObject:barItemKey]) {
        [self.dictionary setObject:item forKey:barItemKey];
        [self.array addObject:item];
        return YES;
    }
    return NO;
}

- (void)removeBarItem:(void *)itemId
{
    NSValue *barItemKey = [NSValue valueWithPointer:itemId];
    if ([self.dictionary.allKeys containsObject:barItemKey]) {
        ACCBarItem *item = [self.dictionary objectForKey:barItemKey];
        [self.array removeObject:item];
        [self.dictionary removeObjectForKey:barItemKey];
    }
}

- (ACCBarItem *)barItemWithItemId:(void *)itemId
{
    NSValue *barItemKey = [NSValue valueWithPointer:itemId];
    if ([self.dictionary.allKeys containsObject:barItemKey]) {
        return [self.dictionary objectForKey:barItemKey];
    }
    return nil;
}

- (NSArray<ACCBarItem *> *)barItems
{
    return [self.array copy];
}

@end
