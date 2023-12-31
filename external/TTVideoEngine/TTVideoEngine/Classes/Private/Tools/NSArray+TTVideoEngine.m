//
//  NSArray+TTVideoEngine.m
//  Pods
//
//  Created by 钟少奋 on 2017/5/18.
//
//

#import "NSArray+TTVideoEngine.h"
#import "TTVideoEngineUtil.h"
#import "TTVideoEngineUtilPrivate.h"

@implementation NSArray (TTVideoEngine)

- (NSArray *)ttVideoEngine_map:(id(^)(id obj, NSUInteger idx))block{
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [result addObject:block(obj, idx)];
    }];
    return [result copy];
}

- (id)ttvideoengine_objectAtIndex:(NSInteger)index{
    if (index < 0 || index >= self.count) {
        return nil;
    }
    id value = [self objectAtIndex:index];
    
    return value;
}

- (id)ttvideoengine_objectAtIndex:(NSInteger)index class:(Class)aClass{
    id value = [self ttvideoengine_objectAtIndex:index];
    
    if ([value isKindOfClass:aClass]) {
        return value;
    }
    TTVideoEngineLog(@"ttvideo_objectAtIndex:class: error [need class:%@  real class:%@]",aClass, [value class]);
    return nil;
}

@end

@implementation NSMutableArray (TTVideoEngine)

- (void)ttvideoengine_addObject:(id)anObject{
    if (!anObject) {
        TTVideoEngineLog(@"ttvideo_addObject: error [anObject = nil]");
        return;
    }
    
    [self addObject:anObject];
}

- (void)ttvideoengine_insertObject:(id)anObject atIndex:(NSInteger )index{
    if (index >= 0 && anObject && index <= self.count) {
        [self insertObject:anObject atIndex:index];
    }else{
        TTVideoEngineLog(@"ttvideo_insertObject: atIndex, error [anObject=nil || index > self.count]");
    }
}

- (void)ttvideoengine_replaceObjectAtIndex:(NSInteger)index withObject:(id)anObject{
    if (index >= 0 && anObject && index < self.count) {
        [self replaceObjectAtIndex:index withObject:anObject];
    }else{
        TTVideoEngineLog(@"ttvideo_replaceObjectAtIndex: withObject,  error [anObject=nil || index >= self.count]");
    }
}

- (void)ttvideoengine_removeObjectAtIndex:(NSInteger)index{
    if (index >= 0 &&  index < self.count) {
        [self removeObjectAtIndex:index];
    }else{
        TTVideoEngineLog(@"ttvideo_removeObjectAtIndex:  error [index >= array.count]");
    }
}

- (void)ttvideoengine_removeObject:(id)anObject{
    if (anObject) {
        [self removeObject:anObject];
    }else{
        TTVideoEngineLog(@"ttvideo_removeObject:  error [anObject = nil]");
    }
}

@end

