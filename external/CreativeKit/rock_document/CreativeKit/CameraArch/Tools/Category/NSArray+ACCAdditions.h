//
//  NSArray+ACCAdditions.h
//  Pods
//
//  Created by chengfei xiao on 2019/9/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/****************    Immutable Array        ****************/
@interface NSArray<__covariant ObjectType> (ACCAdditions)

/**
 return value if index is valid, return nil if others.
 */
- (ObjectType)acc_objectAtIndex:(NSUInteger)index;

/**
 return @"" if value is nil or NSNull; return value if NSString or NSNumber class; return nil if others
 */
- (NSString *)acc_stringWithIndex:(NSUInteger)index;

/**
 return nil if value is nil or NSNull; return NSDictionary if value is NSDictionary; return nil if others.
 */
- (NSDictionary *)acc_dictionaryWithIndex:(NSUInteger)index;


- (NSArray *)acc_mapObjectsUsingBlock:(id(^)(id obj, NSUInteger idex))block;
/**
 * return any item matched by matcher
 * return nil if no item matched
 */
- (_Nullable ObjectType)acc_match:(BOOL (^)(ObjectType item))matcher;

/**
 * return a new array of items applied by filter
 */
- (NSArray *)acc_filter:(BOOL (^)(ObjectType item))filter;

- (id)acc_safeJsonObject;

#pragma mark - High Order Functions

- (NSArray *)acc_map:(id (^)(ObjectType obj))transform;
- (NSArray *)acc_compactMap:(nullable id (^)(ObjectType obj))transform;
- (NSArray *)acc_flatMap:(NSArray* (^)(ObjectType obj))transform;
- (void)acc_forEach:(void (^)(ObjectType obj))block;
- (void)acc_forEachWithIndex:(void (^)(ObjectType obj, NSUInteger index))block;
- (id)acc_reduce:(id)initial reducer:(id (^)(id preValue, ObjectType next))reducer;
- (BOOL)acc_all:(BOOL (^)(ObjectType obj))condition;
- (BOOL)acc_allWithIndex:(BOOL (^)(ObjectType obj, NSInteger index))condition;
- (BOOL)acc_any:(BOOL (^)(ObjectType obj))condition;
- (NSInteger)acc_indexOf:(BOOL (^)(ObjectType obj))condition;

@end

/****************    Mutable Array        ****************/
@interface NSMutableArray <ObjectType> (ACCAdditions)

#pragma mark - Safe Operation

/**
 Add object if object is not nil. Add object if object is [NSNull null]. Do nothing if object is nil.
 */
- (void)acc_addObject:(id)anObject;

- (void)acc_removeObject:(ObjectType)anObject;

/**
 * Move object in array from fromIndex to toIndex safely
 * After moved, toIndex is the real index of the object
 */
- (void)acc_moveObjectFromIndex:(NSUInteger)fromIndex
                        toIndex:(NSUInteger)toIndex;

/**
 Adds the objects contained in otherArray to the end of the receiving array’s content. If array is empty or if array is nil, do nothing.
 */
- (void)acc_addObjectsFromArray:(NSArray<ObjectType> *)otherArray;

/**
 Insert object at index if object is not nil and if index exists. Insert object at index if object is [NSNull null]. Do nothing if object is nil.
 */
- (void)acc_insertObject:(ObjectType)anObject atIndex:(NSUInteger)index;

/**
 Replace object at index if object is not nil. Replace object at index if object is [NSNull null]. Do nothing if object is nil.
 */
- (void)acc_replaceObjectAtIndex:(NSUInteger)index withObject:(ObjectType)anObject;

/**
 Remove object if object is not nil. Remove object if object is [NSNull null]. Do nothing if object is nil.
 */
- (void)acc_removeObjectAtIndex:(NSUInteger)index;

@end


@interface NSArray (ACCJSONString)

- (NSString *)acc_JSONString;

- (NSString *)acc_JSONStringWithOptions:(NSJSONWritingOptions)opt;

@end


NS_ASSUME_NONNULL_END
