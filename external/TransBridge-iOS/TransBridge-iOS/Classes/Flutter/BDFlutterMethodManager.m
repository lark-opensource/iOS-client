//
//  FLTMethodManager.m
//  FlutterIntergation
//
//  Created by bytedance on 2020/4/6.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import "BDFlutterMethodManager.h"
#import "BDMethodProtocol.h"
#import "BDMethodAuthProtocol.h"
#import "BDFLTBResponse.h"
#import "BDChannelJsonUtil.h"

@interface BDFlutterMethodManager()

@property (strong , nonatomic) NSMutableDictionary<NSString *, id<BDBridgeMethod>> *registedMethods;
@property (strong , nonatomic) NSMutableDictionary<NSString *, id<BDBridgeMethod>> *hookMethods;
@property (strong , nonatomic) NSMutableDictionary<NSString *, Class> *registedClasses;
@property (strong , nonatomic) NSMutableDictionary<NSString *, AnonymousFunction> *registedFunctions;
@property (strong , nonatomic) NSMutableArray<id<BDMethodAuth>> *authenticators;
@property (strong , nonatomic) NSLock *lock;

@end


@implementation BDFlutterMethodManager

- (instancetype)init {
    if (self = [super init]) {
        _authenticators = [[NSMutableArray alloc] init];
        _registedMethods = [[NSMutableDictionary alloc] init];
        _registedClasses = [[NSMutableDictionary alloc] init];
        _registedFunctions = [[NSMutableDictionary alloc] init];
        _hookMethods = [[NSMutableDictionary alloc] init];
        _lock = [[NSLock alloc] init];
    }
    return self;
}

+ (instancetype)sharedManager {
    static BDFlutterMethodManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[BDFlutterMethodManager alloc] init];
    });
    return manager;
}

- (void)callMethod:(NSString *)name argument:(id)argument callback:(FLTBResponseCallback)callback inContext:(id<BDBridgeContext>)context {
    
    NSArray *methodParts = [name componentsSeparatedByString:@"."];
    NSAssert(methodParts.count <= 2, @"Invalid methodName Call");
    
    FLTBResponseCallback exitCallback = ^(id<FLTBResponseProtocol> ret) {
        if ([ret conformsToProtocol:@protocol(FLTBResponseProtocol)]) {
            BDFLTBResponse *response = [[BDFLTBResponse alloc] initWithCode:ret.code message:ret.message data:ret.data];
            id responseJson = [BDChannelJsonUtil parseToJsonObject:response];
            callback(responseJson);
        } else {
            BDFLTBResponse *response = [BDFLTBResponse successResponseWithData:ret];
            id responseJson = [BDChannelJsonUtil parseToJsonObject:response];
            callback(responseJson);
        }
    };
    
    NSString *kClsRegist = methodParts.firstObject;
    NSString *funcName = methodParts.lastObject? : kClsRegist;
    
    BOOL exist = [self isMethodExist:kClsRegist];
    if (!exist) {
        BDFLTBResponse *resp = [BDFLTBResponse notImplementResponseWithName:name];
        exitCallback(resp);
        return;
    }
    
    id<BDBridgeMethod> method = [self methodInstanceByName:kClsRegist];
    BOOL authorized = [self isAuthorized:method inContext:context];
    if (!authorized) {
        BDFLTBResponse *resp = [BDFLTBResponse notImplementResponseWithName:name];
        exitCallback(resp);
        return;
    }

    NSString *invokeMethodName = @"call:callback:";
    if (methodParts.count == 2) {
        invokeMethodName = [NSString stringWithFormat:@"%@:callback:", funcName];
    }
    SEL selector = NSSelectorFromString(invokeMethodName);
    if (![method respondsToSelector:selector]) {
        AnonymousFunction function = self.registedFunctions[kClsRegist];
        if (function) {
            function(name, argument, callback);
        } else {
            BDFLTBResponse *resp = [BDFLTBResponse notImplementResponseWithName:name];
            exitCallback(resp);
        }
    } else {
        NSMutableDictionary *assembleArgs = [NSMutableDictionary dictionary];
        [assembleArgs addEntriesFromDictionary:argument];
        assembleArgs[@"__method_name"] = name;
        assembleArgs[@"__method_context"] = context;
        IMP imp = [method.class instanceMethodForSelector:NSSelectorFromString(invokeMethodName)];
        ((void (*)(id, SEL, NSDictionary *, FLTBResponseCallback))imp)(method, selector, assembleArgs, exitCallback);
    }
}

#pragma mark - MethodRegist && cancelRegist

- (BOOL)isMethodExist:(NSString *)name {
    if (name.length > 0) {
        BOOL hooked = self.hookMethods[name];
        BOOL registed = self.registedMethods[name];
        BOOL preseted = self.registedClasses[name];
        BOOL funcReg = self.registedFunctions[name] ? YES : NO;
        return (registed || preseted || hooked || funcReg);
    }
    return NO;
}

- (id<BDBridgeMethod>)methodInstanceByName:(NSString *)name {
    id<BDBridgeMethod> method = self.hookMethods[name];
    if (method) {
        return method;
    }
    method = self.registedMethods[name];
    if (method) {
        return method;
    }
    Class clazz = self.registedClasses[name];
    if (clazz) {
        method = [[clazz alloc] init];
        [self registMethod:method forName:name];
        return method;
    }
    return nil;
}

- (void)registClass:(Class)className forName:(NSString *)name {
    
    NSArray *nameParts = [name componentsSeparatedByString:@"."];
    NSAssert(nameParts.count <= 2, @"Invalid name to be registed");
    
    NSString *registName = nameParts.firstObject;
    
    if (className && registName.length > 0) {
        [self.lock lock];
        self.registedClasses[name] = className;
        [self.lock unlock];
    }
}

- (void)registMethod:(id<BDBridgeMethod>)method forName:(NSString *)name {
    BOOL nameValid = name.length > 0;
    if (nameValid && method) {
        [self.lock lock];
        self.registedMethods[name] = method;
        [self.lock unlock];
    }
}

- (void)registFunction:(AnonymousFunction)func forName:(NSString *)name {
    if (name.length > 0) {
        [self.lock lock];
        self.registedFunctions[name] = func;
        [self.lock unlock];
    }
}

- (void)cancelRegistName:(NSString *)name {
    if (name.length > 0) {
        [self.lock lock];
        [self.hookMethods removeObjectForKey:name];
        [self.registedMethods removeObjectForKey:name];
        [self.registedClasses removeObjectForKey:name];
        [self.registedFunctions removeObjectForKey:name];
        [self.lock unlock];
    }
}

#pragma mark - GetSpecificInstance

- (id<BDBridgeMethod>)registedMethodInstanceForName:(NSString *)name {
    if (name.length > 0) {
        return self.registedMethods[name];
    }
    return nil;
}

#pragma mark - Hook

- (void)hookMethod:(id<BDBridgeMethod>)method forName:(NSString *)name {
    BOOL nameValid = name.length > 0;
    if (nameValid && method) {
        [self.lock lock];
        self.hookMethods[name] = method;
        [self.lock unlock];
    }
}

#pragma mark - Authorization

- (BOOL)isAuthorized:(id<BDBridgeMethod>)method inContext:(id<BDBridgeContext>)context {
    if (self.authenticators.count == 0) {
        return YES;
    }
    for (id<BDMethodAuth> authorizer in self.authenticators) {
        if ([authorizer isAuthorizedMethod:method inContext:context]) {
            return NO;
        }
    }
    return YES;
}

- (void)addAuthenticator:(id<BDMethodAuth>)authenticator {
    if (authenticator) {
        [self.lock lock];
        [self.authenticators addObject:authenticator];
        [self.lock unlock];
    }
}

- (void)removeAuthenticator:(id<BDMethodAuth>)authenticator {
    if (authenticator) {
        [self.lock lock];
        [self.authenticators removeObject:authenticator];
        [self.lock unlock];
    }
}

@end
