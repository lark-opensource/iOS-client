//
//  TTVideoEngineActionManager.m
//  TTVideoEngine
//
//  Created by shen chen on 2021/7/8.
//

#import "TTVideoEngineActionManager.h"

@interface TTVideoEngineActionManager()

@property(nonatomic, strong) NSMapTable *objRegisterDic;
@property (nonatomic, strong) NSMapTable *classRegisterDic;


@end

@implementation TTVideoEngineActionManager

+ (instancetype)shareInstance {
    static TTVideoEngineActionManager *instance;
        static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self) {
        _objRegisterDic = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:0];
        _classRegisterDic = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:0];
    }
    return self;
}

- (void)registerActionObj:(id)obj forProtocol:(Protocol *)protocol {
    if ([obj conformsToProtocol:protocol]) {
        [_objRegisterDic setObject:obj forKey:protocol];
    }
}

- (void)registerActionClass:(Class)class forProtocol:(Protocol *)protocol {
    if ([_classRegisterDic.objectEnumerator.allObjects containsObject:class]) {
        return;
    }
    if ([class conformsToProtocol:protocol]) {
        [_classRegisterDic setObject:class forKey:protocol];
    }
}

- (id)actionObjWithProtocal:(Protocol *)protocol {
    if (protocol == nil) {
        return nil;
    }
    return [_objRegisterDic objectForKey:protocol];
}

- (Class)actionClassWithProtocal:(Protocol *)protocol {
    if (protocol == nil) {
        return nil;
    }
    return [_classRegisterDic objectForKey:protocol];
}

- (void)removeActionClass:(Class)class forProtocol:(Protocol *)protocol {
    if (![_classRegisterDic.objectEnumerator.allObjects containsObject:class]) {
        return;
    }
    if ([_classRegisterDic conformsToProtocol:protocol]) {
        [_classRegisterDic removeObjectForKey:protocol];
    }
}

- (void)removeActionObj:(id)obj forProtocol:(Protocol *)protocol {
    if (![_objRegisterDic.objectEnumerator.allObjects containsObject:obj]) {
        return;
    }
    if ([obj conformsToProtocol:protocol]) {
        [_objRegisterDic removeObjectForKey:protocol];
    }
}

@end
