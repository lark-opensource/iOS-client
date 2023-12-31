//
//  BDXContext.m
//  AAWELaunchOptimization
//
//  Created by duanefaith on 2019/10/21.
//

#import "BDXContext.h"

#ifndef BDX_MAPTABLE_HAS_KEY
#define BDX_MAPTABLE_HAS_KEY(TABLE, KEY) [(TABLE).keyEnumerator.allObjects containsObject:(KEY)]
#endif

#ifndef BDX_MERGE_MAPTABLE
#define BDX_MERGE_MAPTABLE(SRC, DST)                           \
    for (NSString * key in (SRC).keyEnumerator.allObjects) {   \
        [(DST) setObject:[(SRC) objectForKey:key] forKey:key]; \
    }
#endif

@interface BDXContext ()

@property (nonatomic, copy) NSMapTable<NSString *, id> *weakObjHolder;
@property (nonatomic, copy) NSMapTable<NSString *, id> *strongObjHolder;
@property (nonatomic, copy) NSMapTable<NSString *, id<NSCopying>> *dupObjHolder;

@property (nonatomic, strong) id extraInfo;

@end


@implementation BDXContext

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.weakObjHolder = [NSMapTable strongToWeakObjectsMapTable];
        self.strongObjHolder = [NSMapTable strongToStrongObjectsMapTable];
        self.dupObjHolder = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsCopyIn];

        [self registerCopyObj:[[NSUUID UUID] UUIDString] forKey:@"__sessionId"];
    }
    return self;
}

- (void)registerWeakObj:(id)obj forType:(Class)aClass
{
    [self.weakObjHolder setObject:obj forKey:NSStringFromClass(aClass)];
}

- (void)registerStrongObj:(id)obj forType:(Class)aClass
{
    [self.strongObjHolder setObject:obj forKey:NSStringFromClass(aClass)];
}

- (void)registerCopyObj:(id<NSCopying>)obj forType:(Class)aClass
{
    [self.dupObjHolder setObject:obj forKey:NSStringFromClass(aClass)];
}

- (void)registerWeakObj:(nullable id)obj forKey:(NSString *)key
{
    if (key) {
        [self.weakObjHolder setObject:obj forKey:key];
    }
}

- (void)registerStrongObj:(nullable id)obj forKey:(NSString *)key
{
    if (key) {
        [self.strongObjHolder setObject:obj forKey:key];
    }
}

- (void)registerCopyObj:(nullable id<NSCopying>)obj forKey:(NSString *)key
{
    if (key) {
        [self.dupObjHolder setObject:obj forKey:key];
    }
}

- (id)getObjForType:(Class)aClass
{
    return [self getObjForKey:NSStringFromClass(aClass)];
}

- (nullable id)getObjForKey:(NSString *)key
{
    if (key) {
        if (BDX_MAPTABLE_HAS_KEY(self.weakObjHolder, key)) {
            return [self.weakObjHolder objectForKey:key];
        }
        if (BDX_MAPTABLE_HAS_KEY(self.strongObjHolder, key)) {
            return [self.strongObjHolder objectForKey:key];
        }
        if (BDX_MAPTABLE_HAS_KEY(self.dupObjHolder, key)) {
            return [self.dupObjHolder objectForKey:key];
        }
    }
    return nil;
}

- (BOOL)isWeakObjForKey:(NSString *)key
{
    return BDX_MAPTABLE_HAS_KEY(self.weakObjHolder, key);
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    BDXContext *copy = [[self.class allocWithZone:zone] init];
    if (copy) {
        copy.weakObjHolder = [self.weakObjHolder copy];
        copy.strongObjHolder = [self.strongObjHolder copy];
        copy.dupObjHolder = [self.dupObjHolder copy];
    }
    return copy;
}

- (void)mergeContext:(BDXContext *)context
{
    if (context) {
        BDX_MERGE_MAPTABLE(context.weakObjHolder, self.weakObjHolder)
        BDX_MERGE_MAPTABLE(context.strongObjHolder, self.strongObjHolder)
        BDX_MERGE_MAPTABLE(context.dupObjHolder, self.dupObjHolder)
    }
}

@end
