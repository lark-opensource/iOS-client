//
//  IESLiveResouceBundle+Hooks.m
//  Pods
//
//  Created by Zeus on 2016/12/26.
//
//

#import "IESLiveResouceBundle+Hooker.h"
#import <objc/runtime.h>

@implementation IESLiveResouceBundle (Hooker)

+ (void)load
{
    method_exchangeImplementations(class_getInstanceMethod([self class],@selector(objectForKey:type:)),class_getInstanceMethod([self class], @selector(hook_objectForKey:type:)));
}

- (id)hook_objectForKey:(NSString *)key type:(NSString *)type {
    if ([self.hookers count] > 0 || [[[self class] hookersForCategory:self.category] count] > 0) {
        id value = nil;
        IESLiveResouceBundlePreHookBlock preHook = self.preHookers;
        if (preHook) {
            value = preHook(key, type, self.category);
            if (value) {
                return value;
            }
        }
        value = [self hook_objectForKey:key type:type];
        IESLiveResouceBundlePostHookBlock postHook = self.postHookers;
        if (postHook) {
            value = postHook(key, type, self.category, value);
        }
        return value;
    }
    return [self hook_objectForKey:key type:type];
}

- (void)addHooker:(id<IESLiveResouceBundleHookerProtocol>)hooker {
    if (hooker) {
        NSArray *hookers = self.hookers;
        if (!hookers) {
            self.hookers = @[hooker];
        }
        else {
            NSMutableArray *newHookersArray = [NSMutableArray arrayWithArray:hookers];
            [newHookersArray addObject:hooker];
            self.hookers = newHookersArray;
        }
    }
}

- (void)addPreHook:(IESLiveResouceBundlePreHookBlock)preHookBlock {
    [self addHooker:[[IESLiveResouceBundleHooker alloc] initWithPreHook:preHookBlock postHook:nil]];
}

- (void)addPostHook:(IESLiveResouceBundlePostHookBlock)postHookBlock {
    [self addHooker:[[IESLiveResouceBundleHooker alloc] initWithPreHook:nil postHook:postHookBlock]];
}

- (void)removeHooker:(id<IESLiveResouceBundleHookerProtocol>)hooker {
    NSMutableArray *hookers = [self.hookers mutableCopy];
    [hookers removeObject:hooker];
    self.hookers = hookers;
}

- (void)removeAllHookers {
    self.hookers = nil;
}

#pragma mark property hookers
- (NSArray *)hookers {
    return objc_getAssociatedObject(self, @selector(hookers));
}

- (void)setHookers:(NSArray *)hookers {
    objc_setAssociatedObject(self, @selector(hookers), hookers, OBJC_ASSOCIATION_COPY);
}

- (IESLiveResouceBundlePreHookBlock)preHookers {
    IESLiveResouceBundlePreHookBlock preHook = objc_getAssociatedObject(self, @selector(preHookers));
    if (preHook) {
        return preHook;
    }
    __weak typeof(self) weakSelf = self;
    preHook = ^(NSString *key, NSString *type, NSString *category){
        __block id newValue = nil;
        void (^block)(id<IESLiveResouceBundleHookerProtocol>, NSUInteger, BOOL *) = ^(id<IESLiveResouceBundleHookerProtocol> hooker, NSUInteger idx, BOOL * stop) {
            if ([hooker respondsToSelector:@selector(preHook)]) {
                IESLiveResouceBundlePreHookBlock preHook = hooker.preHook;
                if (preHook) {
                    id value = preHook(key,type,category);
                    if (value) {
                        newValue = value;
                        *stop = YES;
                    }
                }
            }
        };
        [weakSelf.hookers enumerateObjectsUsingBlock:block];
        if (!newValue) {
            [[[weakSelf class] hookersForCategory:category] enumerateObjectsUsingBlock:block];
        }
        return newValue;
    };
    objc_setAssociatedObject(self, @selector(preHookers), preHook, OBJC_ASSOCIATION_COPY);
    return preHook;
}

- (IESLiveResouceBundlePostHookBlock)postHookers {
    IESLiveResouceBundlePostHookBlock postHook = objc_getAssociatedObject(self, @selector(postHookers));
    if (postHook) {
        return postHook;
    }
    __weak typeof(self) weakSelf = self;
    postHook = ^(NSString *key, NSString *type, NSString *category, id originValue){
        __block id newValue = originValue;
        __block BOOL hasNewValue = NO;
        void (^block)(id<IESLiveResouceBundleHookerProtocol>, NSUInteger, BOOL *) = ^(id<IESLiveResouceBundleHookerProtocol> hooker, NSUInteger idx, BOOL * stop) {
            if ([hooker respondsToSelector:@selector(postHook)]) {
                IESLiveResouceBundlePostHookBlock postHook = hooker.postHook;
                if (postHook) {
                    id value = postHook(key, type, category, originValue);
                    if (value) {
                        newValue = value;
                        *stop = YES;
                        hasNewValue = YES;
                    }
                }
            }
        };
        [weakSelf.hookers enumerateObjectsUsingBlock:block];
        if (!hasNewValue) {
            [[[weakSelf class] hookersForCategory:category] enumerateObjectsUsingBlock:block];
        }
        return newValue;
    };
    objc_setAssociatedObject(self, @selector(postHookers), postHook, OBJC_ASSOCIATION_COPY);
    return postHook;
}

static NSMutableDictionary<NSString *,NSArray<id<IESLiveResouceBundleHookerProtocol>> *> *IESLiveResouceBundleHookers = nil;
+ (void)addHooker:(id<IESLiveResouceBundleHookerProtocol>)hooker forCategory:(NSString *)category {
    if (category) {
        if (!IESLiveResouceBundleHookers) {
            IESLiveResouceBundleHookers = [NSMutableDictionary dictionary];
        }
        NSMutableArray<id<IESLiveResouceBundleHookerProtocol>> *hookers = [[IESLiveResouceBundleHookers objectForKey:category] mutableCopy] ? : [NSMutableArray array];
        [hookers addObject:hooker];
        [IESLiveResouceBundleHookers setObject:[hookers copy] forKey:category];
    }
}

+ (void)addPreHook:(IESLiveResouceBundlePreHookBlock)preHookBlock forCategory:(NSString *)category{
    [self addHooker:[[IESLiveResouceBundleHooker alloc] initWithPreHook:preHookBlock postHook:nil] forCategory:category];
}

+ (void)addPostHook:(IESLiveResouceBundlePostHookBlock)postHookBlock forCategory:(NSString *)category {
    [self addHooker:[[IESLiveResouceBundleHooker alloc] initWithPreHook:nil postHook:postHookBlock] forCategory:category];
}

+ (void)removeHooker:(id<IESLiveResouceBundleHookerProtocol>)hooker forCategory:(NSString *)category {
    if (category) {
        NSMutableArray<id<IESLiveResouceBundleHookerProtocol>> *hookers = [[IESLiveResouceBundleHookers objectForKey:category] mutableCopy];
        [hookers removeObject:hooker];
        [IESLiveResouceBundleHookers setObject:[hookers copy] forKey:category];
    }
}

+ (void)removeAllHookersForCategory:(NSString *)category {
    if (category) {
        [IESLiveResouceBundleHookers removeObjectForKey:category];
    }
}

+ (NSArray<id<IESLiveResouceBundleHookerProtocol>> *)hookersForCategory:(NSString *)category {
    return category ? [IESLiveResouceBundleHookers objectForKey:category] : nil;
}

@end

@implementation IESLiveResouceBundleHooker

- (instancetype)initWithPreHook:(IESLiveResouceBundlePreHookBlock)preHook postHook:(IESLiveResouceBundlePostHookBlock)postHook {
    self = [super init];
    if (self) {
        self.preHook = preHook;
        self.postHook = postHook;
    }
    return self;
}

@end
