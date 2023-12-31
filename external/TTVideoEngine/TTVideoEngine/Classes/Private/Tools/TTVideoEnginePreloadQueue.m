//
//  TTVideoEnginePreloadQueue.m
//  TTVideoEngine
//
//  Created by 黄清 on 2018/11/30.
//

#import "TTVideoEnginePreloadQueue.h"
#import <pthread.h>


@interface TTVideoEnginePreloadQueue(){
    pthread_mutex_t _lock;
    NSMutableArray *_itemArray;
}

@end

@implementation TTVideoEnginePreloadQueue

- (void)dealloc{
    [_itemArray removeAllObjects];
    _itemArray = nil;
    pthread_mutex_destroy(&_lock);
}

- (NSInteger)count{
    pthread_mutex_lock(&_lock);
    NSInteger count = _itemArray.count;
    pthread_mutex_unlock(&_lock);
    return count;
}

- (instancetype)init{
    if (self = [super init]) {
        pthread_mutex_init(&_lock, NULL);
        _itemArray = [NSMutableArray array];
    }
    return self;
}

- (nullable id<TTVideoEnginePreloadQueueItem>)frontItem {
    pthread_mutex_lock(&_lock);
    if (_itemArray.count == 0) {
         pthread_mutex_unlock(&_lock);
        return nil;
    }
    id<TTVideoEnginePreloadQueueItem> item = [_itemArray firstObject];
    pthread_mutex_unlock(&_lock);
    return item;
}

- (nullable id<TTVideoEnginePreloadQueueItem>)popFrontItem {
    pthread_mutex_lock(&_lock);
    if (_itemArray.count == 0) {
        pthread_mutex_unlock(&_lock);
        return nil;
    }
    id<TTVideoEnginePreloadQueueItem> item = [_itemArray firstObject];
    [_itemArray removeObject:item];
    pthread_mutex_unlock(&_lock);
    return item;
}

- (nullable id<TTVideoEnginePreloadQueueItem>)backItem {
    pthread_mutex_lock(&_lock);
    if (_itemArray.count == 0) {
        pthread_mutex_unlock(&_lock);
        return nil;
    }
    id<TTVideoEnginePreloadQueueItem> item = [_itemArray lastObject];
    pthread_mutex_unlock(&_lock);
    return item;
}

- (nullable id<TTVideoEnginePreloadQueueItem>)popBackItem {
    pthread_mutex_lock(&_lock);
    if (_itemArray.count == 0) {
        pthread_mutex_unlock(&_lock);
        return nil;
    }
    id<TTVideoEnginePreloadQueueItem> item = [_itemArray lastObject];
    [_itemArray removeLastObject];
    pthread_mutex_unlock(&_lock);
    return item;
}

- (BOOL)enqueueItem:(id<TTVideoEnginePreloadQueueItem>)item {
    if (item == nil) {
        return NO;
    }
    if (![item respondsToSelector:@selector(itemKey)] || [item itemKey] == nil || [item itemKey].length == 0) {
        return NO;
    }
    
    BOOL result = NO;
    pthread_mutex_lock(&_lock);
    if ([self _enoughItems]) {
        result = NO;
    }else{
        [_itemArray addObject:item];
        result = YES;
    }
    pthread_mutex_unlock(&_lock);
    return result;
}

- (BOOL)containItem:(id<TTVideoEnginePreloadQueueItem>)item {
    NSParameterAssert(item != nil);
    if (item == nil) {
        return NO;
    }
    BOOL result = NO;
    pthread_mutex_lock(&_lock);
    result = [_itemArray containsObject:item];
    pthread_mutex_unlock(&_lock);
    return result;
}

- (BOOL)containItemForKey:(NSString *)key {
    NSParameterAssert(key && key.length > 0);
    if (key == nil || key.length == 0) {
        return NO;
    }
    
    __block BOOL result = NO;
    pthread_mutex_lock(&_lock);
    [_itemArray enumerateObjectsUsingBlock:^(id<TTVideoEnginePreloadQueueItem> obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[obj itemKey] isEqualToString:key]) {
            result = YES;
            *stop = YES;
        }
    }];
    pthread_mutex_unlock(&_lock);
    return result;
}

- (id<TTVideoEnginePreloadQueueItem>)popItemForKey:(NSString *)key {
    if (key == nil || key.length == 0) {
        return nil;
    }
    
    __block id<TTVideoEnginePreloadQueueItem> item = nil;
    pthread_mutex_lock(&_lock);
    [_itemArray enumerateObjectsUsingBlock:^(id<TTVideoEnginePreloadQueueItem> obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[obj itemKey] isEqualToString:key]) {
            item = obj;
            *stop = YES;
        }
    }];
    
    if (item) {
        [_itemArray removeObject:item];
    }
    pthread_mutex_unlock(&_lock);
    return item;
}

- (nullable id<TTVideoEnginePreloadQueueItem>)itemForKey:(NSString *)key {
    if (key == nil || key.length == 0) {
        return nil;
    }
    
    __block id<TTVideoEnginePreloadQueueItem> item = nil;
    pthread_mutex_lock(&_lock);
    [_itemArray enumerateObjectsUsingBlock:^(id<TTVideoEnginePreloadQueueItem> obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[obj itemKey] isEqualToString:key]) {
            item = obj;
            *stop = YES;
        }
    }];
    pthread_mutex_unlock(&_lock);
    return item;
}

- (void)popAllItems {
    pthread_mutex_lock(&_lock);
    [_itemArray removeAllObjects];
    pthread_mutex_unlock(&_lock);
}

- (NSArray *)itemsForKey:(NSString *)key {
    if (key == nil || key.length == 0) {
        return nil;
    }
    
    NSMutableArray *resultArray = [NSMutableArray array];
    pthread_mutex_lock(&_lock);
    [_itemArray enumerateObjectsUsingBlock:^(id<TTVideoEnginePreloadQueueItem> obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[obj itemKey] isEqualToString:key]) {
            [resultArray addObject:obj];
        }
    }];
    pthread_mutex_unlock(&_lock);
    return resultArray.copy;
}

- (void)popItem:(id<TTVideoEnginePreloadQueueItem>)item {
    NSParameterAssert(item != nil);
    if (item == nil) {
        return;
    }
    //
    pthread_mutex_lock(&_lock);
    [_itemArray removeObject:item];
    pthread_mutex_unlock(&_lock);
}

- (NSArray *)customCopyAllItems {
    NSMutableArray *temArray = nil;
    pthread_mutex_lock(&_lock);
    temArray = _itemArray.copy;
    pthread_mutex_unlock(&_lock);
    return temArray;
}

- (BOOL)_enoughItems {
    if (_maxCount >= 1) {
        return _itemArray.count >= _maxCount;
    }else{
        return NO;
    }
}

@end
