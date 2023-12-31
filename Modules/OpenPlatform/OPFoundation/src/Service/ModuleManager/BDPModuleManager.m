
//
//  BDPModuleManager.m
//  Timor
//
//  Created by houjihu on 2020/1/19.
//  Copyright © 2020 houjihu. All rights reserved.
//

#import "BDPModuleManager.h"
#import "BDPModuleProtocol.h"
#import <Objection/Objection.h>
#import <OPFoundation/OPFoundation-Swift.h>

@interface BDPModuleManager ()

/// 应用类型
@property(nonatomic, assign, readwrite) BDPType type;

/// 依赖注入绑定类
@property (nonatomic, strong) JSObjectionModule *module;
/// 依赖注入查找类
@property (nonatomic, strong) JSObjectionInjector *injector;

@property (nonatomic, strong) NSLock * lockForModule;
@property (nonatomic, strong) NSLock * lockForInjector;
@end

@implementation BDPModuleManager

#pragma mark - life cycle

+ (NSMutableDictionary<NSNumber *, BDPModuleManager *> *)sharedManagers {
    static NSMutableDictionary<NSNumber *, BDPModuleManager *> *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NSMutableDictionary<NSNumber *, BDPModuleManager *> alloc] init];
    });
    return instance;
}

/// 获取模块管理类实例
/// @param type 应用类型
+ (instancetype)moduleManagerOfType:(BDPType)type {
    BDPModuleManager *moduleManager = nil;
    @synchronized (self) {
        moduleManager = [self sharedManagers][@(type)];
        if (!moduleManager) {
            moduleManager = [[self alloc] initWithType:type];
            [self sharedManagers][@(type)] = moduleManager;
        }
    }
    return moduleManager;
}

/// 模块管理类初始化
/// @param type 应用类型
- (instancetype)initWithType:(BDPType)type {
    if (self = [super init]) {
        self.type = type;
        self.lockForInjector = [NSLock new];
        self.lockForModule = [NSLock new];
    }
    return self;
}

#pragma mark - register & resolve

/// 注册模块
/// @param protocol 模块对外暴露的协议
/// @param handler 模块实现类初始化block
- (void)registerModuleWithProtocol:(Protocol *)protocol handler:(id<BDPModuleProtocol> (^)(BDPModuleManager *))handler {
    [self registerModuleWithProtocol:protocol class:nil handler:handler];
}

/// 注册模块，自动调用模块实现类的init方法，并在模块注册完成后发送通知
/// @param protocol 模块对外暴露的协议
/// @param cls 模块实现类
- (void)registerModuleWithProtocol:(Protocol *)protocol class:(Class<BDPModuleProtocol>)cls {
    [self registerModuleWithProtocol:protocol class:cls handler:nil];
}

/// 注册模块，并在模块注册完成后发送通知
/// @param protocol 模块对外暴露的协议
/// @param cls 模块实现类
/// @param handler 模块实现类初始化block
- (void)registerModuleWithProtocol:(Protocol *)protocol class:(Class<BDPModuleProtocol>)cls handler:(id<BDPModuleProtocol> (^)(BDPModuleManager *))handler {
    // 先注册服务
    // 再使用服务实体
    BOOL checkProtocol = (protocol_conformsToProtocol(protocol, @protocol(BDPModuleProtocol)));
    BOOL checkClass = !cls || (class_conformsToProtocol(cls, protocol));
    NSAssert(checkProtocol && checkClass, @"register module with wrong protocol: %@, class: %@", NSStringFromProtocol(protocol), NSStringFromClass(cls));
    NSAssert(cls || handler, @"register module with empty handler, protocol: %@, class: %@", NSStringFromProtocol(protocol), NSStringFromClass(cls));
    NSString *typeName = [[self class] nameForType:self.type];
    __weak typeof(self) weakSelf = self;
    // 对于同一种应用形态，以单例形式初始化模块
    [self.module bindBlock:^id(JSObjectionInjector *context) {
        __strong typeof(weakSelf) self = weakSelf;
        Class moduleCls = cls;
        id<BDPModuleProtocol> moduleInstance = handler ? handler(self) : [[moduleCls alloc] init];
        if ([moduleInstance respondsToSelector:@selector(moduleManager)]) {
            moduleInstance.moduleManager = self;
        }
        return moduleInstance;
    } toProtocol:protocol inScope:JSObjectionScopeSingleton named:typeName];

    if ([cls respondsToSelector:@selector(moduleDidLoadWithManager:)]) {
        [cls moduleDidLoadWithManager:self];
    }
}

/// 查找模块
/// @param protocol 模块对外暴露的协议
/// @return 模块实现类对象
- (id<BDPModuleProtocol>)resolveModuleWithProtocol:(Protocol *)protocol {
    NSString *typeName = [[self class] nameForType:self.type];
    id module = [self.injector getObject:protocol named:typeName];
    NSAssert(module, @"resolved module is empty with protocol: %@", NSStringFromProtocol(protocol));
    NSAssert([module conformsToProtocol:@protocol(BDPModuleProtocol)], @"resolved module (%@) dose not conform to protocol (%@)", module, NSStringFromProtocol(protocol));
    return module;
}

#pragma mark - property

- (JSObjectionInjector *)injector {
    [self.lockForInjector lock];
    if (!_injector) {
        _injector = [JSObjection createInjector:self.module];
    }
    [self.lockForInjector unlock];
    return _injector;
}

- (JSObjectionModule *)module {
    [self.lockForModule lock];
    if (!_module) {
        _module = [[JSObjectionModule alloc] init];
    }
    [self.lockForModule unlock];
    return _module;
}

+ (NSString *)nameForType:(BDPType)type {
    return [NSString stringWithFormat:@"type%@", @(type)];
}

@end
