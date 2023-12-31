//
//  NSArray+TTVideoEngine.h
//  Pods
//
//  Created by 钟少奋 on 2017/5/18.
//
//

#import <Foundation/Foundation.h>

@interface NSArray (TTVideoEngine)

- (NSArray *)ttVideoEngine_map:(id(^)(id obj, NSUInteger idx))block;

/// safe objectAtIndex:
- (id)ttvideoengine_objectAtIndex:(NSInteger)index;

/// safe objectAtIndex:class:
- (id)ttvideoengine_objectAtIndex:(NSInteger)index class:(Class)aClass;

@end


@interface NSMutableArray (TTVideoEngine)

/// safe addObject:
- (void)ttvideoengine_addObject:(id)anObject;

/// safe insertObject:atIndex:
- (void)ttvideoengine_insertObject:(id)anObject atIndex:(NSInteger)index;

/// safe replaceObjectAtIndex:withObject:
- (void)ttvideoengine_replaceObjectAtIndex:(NSInteger)index withObject:(id)anObject;

/// safe removeObjectAtIndex:
- (void)ttvideoengine_removeObjectAtIndex:(NSUInteger)index;

/// safe removeObject:
- (void)ttvideoengine_removeObject:(id)anObject;

@end
