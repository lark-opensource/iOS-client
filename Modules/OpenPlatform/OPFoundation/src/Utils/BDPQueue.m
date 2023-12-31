//
//  BDPQueue.m
//  Timor
//
//  Created by 傅翔 on 2019/1/24.
//

#import "BDPQueue.h"

@interface BDPQueue ()

// Double Stack Queue 换成RingBuffer + 动态拓容?
@property (nonatomic, strong) NSMutableArray *enqueueStack;
@property (nonatomic, strong) NSMutableArray *dequeueStack;

@end

@implementation BDPQueue

- (void)enqueueObject:(id)object {
    if (object) {
        [self.enqueueStack addObject:object];
    }
}

- (id)dequeueObject {
    if (!_dequeueStack.count && _enqueueStack.count) {
        [self mergeEnqueueStackIfNotEmpty];
    }
    id object = _dequeueStack.lastObject;
    if (object) {
        [_dequeueStack removeLastObject];
    }
    return object;
}

- (void)insertObjectToHead:(id)object {
    if (object) {
        [self.dequeueStack addObject:object];
    }
}

- (void)insertObjectsToHead:(NSArray *)objects {
    if (objects.count) {
        [self.dequeueStack addObjectsFromArray:objects.reverseObjectEnumerator.allObjects];
    }
}

- (void)insertObject:(id)object toIndex:(NSUInteger)index {
    if (!object) {
        return;
    }
    if (_dequeueStack.count) {
        [self mergeEnqueueStackIfNotEmpty];
        if (index < self.dequeueStack.count) {
            [self.dequeueStack insertObject:object atIndex:self.dequeueStack.count - index];
        } else {
            [self enqueueObject:object];
        }
    } else if (_enqueueStack.count) {
        if (index < self.enqueueStack.count) {
            [self.enqueueStack insertObject:object atIndex:index];
        } else {
            [self enqueueObject:object];
        }
    } else {
        [self enqueueObject:object];
    }
}

- (void)removeObject:(id)object {
    if (!object) {
        return;
    }
    if (_enqueueStack.count) {
        [_enqueueStack removeObject:object];
    }
    if (_dequeueStack.count) {
        [_dequeueStack removeObject:object];
    }
}

- (id)removeLastObject {
    id removedObject = nil;
    if (_enqueueStack.count) {
        removedObject = _enqueueStack.lastObject;
        [_enqueueStack removeLastObject];
    } else if (_dequeueStack.count) {
        removedObject = _dequeueStack.firstObject;
        [_dequeueStack removeObjectAtIndex:0];
    }
    return removedObject;
}

- (void)enqueueObjectsFromArray:(NSArray *)array {
    if (array.count) {
        [self.enqueueStack addObjectsFromArray:array];
    }
}

- (void)emptyQueue {
    [_enqueueStack removeAllObjects];
    [_dequeueStack removeAllObjects];
}

#pragma mark - Accessor
- (NSUInteger)count {
    return _dequeueStack.count + _enqueueStack.count;
}

- (NSArray *)allObjects {
    if (!self.count) {
        return nil;
    }
    [self mergeEnqueueStackIfNotEmpty];
    return _dequeueStack.reverseObjectEnumerator.allObjects;
}

- (id)firstObject {
    return _dequeueStack.lastObject ?: _enqueueStack.firstObject;
}

- (id)lastObject {
    return _enqueueStack.lastObject ?: _dequeueStack.firstObject;
}

#pragma mark - Index Access
- (id)objectAtIndexedSubscript:(NSUInteger)index {
    NSUInteger count = self.count;
    if (count && index < self.count) {
        [self mergeEnqueueStackIfNotEmpty];
        return self.dequeueStack[count - index - 1];
    }
    return nil;
}

- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)index {
    NSUInteger count = self.count;
    if (obj) {
        if (!count && !index) {
            [self enqueueObject:obj];
        } else if (count > 0 && index < count) {
            [self mergeEnqueueStackIfNotEmpty];
            self.dequeueStack[count - index - 1] = obj;
        }
    }
}

#pragma mark -
- (void)mergeEnqueueStackIfNotEmpty {
    if (_enqueueStack.count) {
        if (_dequeueStack.count) {
            [self.dequeueStack insertObjects:self.enqueueStack.reverseObjectEnumerator.allObjects
                                   atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.enqueueStack.count)]];
        } else {
            [self.dequeueStack addObjectsFromArray:self.enqueueStack.reverseObjectEnumerator.allObjects];
        }
        [self.enqueueStack removeAllObjects];
    }
}

#pragma mark - LazyLoading
- (NSMutableArray *)dequeueStack {
    if (!_dequeueStack) {
        _dequeueStack = [[NSMutableArray alloc] init];
    }
    return _dequeueStack;
}

- (NSMutableArray *)enqueueStack {
    if (!_enqueueStack) {
        _enqueueStack = [[NSMutableArray alloc] init];
    }
    return _enqueueStack;
}
@end
