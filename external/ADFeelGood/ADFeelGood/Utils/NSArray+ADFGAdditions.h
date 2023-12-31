//
//  NSArray+ADFGAdditions.h
//  ADFeelGood
//
//  Created by cuikeyi on 2021/1/15.
//

#import <Foundation/Foundation.h>

@interface NSArray (ADFGAdditions)

- (id)adfg_objectAtIndex:(NSUInteger)index kindOfClass:(Class)aClass;
- (id)adfg_objectAtIndex:(NSUInteger)index memberOfClass:(Class)aClass;
- (id)adfg_objectAtIndex:(NSUInteger)index defaultValue:(id)value;
- (id)adfg_objectAtIndex:(NSUInteger)index;

- (NSString *)adfg_stringAtIndex:(NSUInteger)index defaultValue:(NSString *)value;
- (NSNumber *)adfg_numberAtIndex:(NSUInteger)index defaultValue:(NSNumber *)value;
- (NSDictionary *)adfg_dictionaryAtIndex:(NSUInteger)index defaultValue:(NSDictionary *)value;
- (NSArray *)adfg_arrayAtIndex:(NSUInteger)index defaultValue:(NSArray *)value;
- (NSData *)adfg_dataAtIndex:(NSUInteger)index defaultValue:(NSData *)value;
- (NSDate *)adfg_dateAtIndex:(NSUInteger)index defaultValue:(NSDate *)value;
- (float)adfg_floatAtIndex:(NSUInteger)index defaultValue:(float)value;
- (double)adfg_doubleAtIndex:(NSUInteger)index defaultValue:(double)value;
- (NSInteger)adfg_integerAtIndex:(NSUInteger)index defaultValue:(NSInteger)value;
- (NSUInteger)adfg_unintegerAtIndex:(NSUInteger)index defaultValue:(NSUInteger)value;
- (BOOL)adfg_boolAtIndex:(NSUInteger)index defaultValue:(BOOL)value;

#pragma mark - Json
- (NSString *)adfg_jsonStringEncoded;
- (NSString *)adfg_jsonStringEncoded:(NSError *__autoreleasing *)error;

@end




@interface NSMutableArray (ADFGAdditions)

- (void)adfg_removeObjectAtIndexInBoundary:(NSUInteger)index;
- (void)adfg_insertObject:(id)anObject atIndexInBoundary:(NSUInteger)index;
- (void)adfg_replaceObjectAtInBoundaryIndex:(NSUInteger)index withObject:(id)anObject;

// 排除nil 和 NSNull
- (void)adfg_addObjectSafe:(id)anObject;

@end
