//
//  BDPQueue.h
//  Timor
//
//  Created by 傅翔 on 2019/1/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Double Stack Queue, 先进先出队列, 方法非线程安全!
 
 可使用数组下标访问, 读取或赋值时下标越界都不会crash
 */
@interface BDPQueue<__covariant ObjectType> : NSObject

@property (nonatomic, readonly, assign) NSUInteger count;
@property (nonatomic, nullable, readonly, copy) NSArray<ObjectType> *allObjects;
@property (nonatomic, nullable, readonly, strong) ObjectType firstObject;
@property (nonatomic, nullable, readonly, strong) ObjectType lastObject;

- (void)enqueueObject:(ObjectType)object;
- (nullable ObjectType)dequeueObject;

- (void)insertObjectToHead:(ObjectType)object;
- (void)insertObjectsToHead:(NSArray<ObjectType> *)objects;
- (void)insertObject:(ObjectType)object toIndex:(NSUInteger)index;

- (void)removeObject:(ObjectType)object;
- (nullable ObjectType)removeLastObject;

- (void)enqueueObjectsFromArray:(NSArray<ObjectType> *)array;
- (void)emptyQueue;

- (ObjectType)objectAtIndexedSubscript:(NSUInteger)index;
- (void)setObject:(ObjectType)obj atIndexedSubscript:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
