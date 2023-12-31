//
//  NSArray+NLE.h
//  NLEPlatform
//
//  Created by zhangyuanming on 2021/10/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray <ObjectType> (NLE)

- (id)nle_objectAtIndex:(NSUInteger)index;

- (NSString *)nle_stringAtIndex:(NSUInteger)index;

- (NSNumber *)nle_numberAtIndex:(NSUInteger)index;

@end

@interface NSMutableArray <ObjectType> (NLE)

- (void)nle_addObject:(id)anObject;

- (void)nle_removeObject:(ObjectType)anObject;

/**
 * Move object in array from fromIndex to toIndex safely
 * After moved, toIndex is the real index of the object
 */
- (void)nle_moveObjectFromIndex:(NSUInteger)fromIndex
                        toIndex:(NSUInteger)toIndex;

/**
 Adds the objects contained in otherArray to the end of the receiving array’s content. If array is empty or if array is nil, do nothing.
 */
- (void)nle_addObjectsFromArray:(NSArray<ObjectType> *)otherArray;

/**
 Insert object at index if object is not nil and if index exists. Insert object at index if object is [NSNull null]. Do nothing if object is nil.
 */
- (void)nle_insertObject:(ObjectType)anObject atIndex:(NSUInteger)index;

/**
 Replace object at index if object is not nil. Replace object at index if object is [NSNull null]. Do nothing if object is nil.
 */
- (void)nle_replaceObjectAtIndex:(NSUInteger)index withObject:(ObjectType)anObject;

/**
 Remove object if object is not nil. Remove object if object is [NSNull null]. Do nothing if object is nil.
 */
- (void)nle_removeObjectAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
