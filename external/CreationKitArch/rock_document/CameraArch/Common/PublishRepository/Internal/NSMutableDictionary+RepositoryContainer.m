//
//  NSMutableDictionary+RepositoryContainer.m
//  CameraClient-Pods-Aweme
//
//  Created by Charles on 2020/8/19.
//

#import "NSMutableDictionary+RepositoryContainer.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreativeKit/ACCMacros.h>

@implementation NSMutableDictionary (RepositoryContainer)

- (BOOL)acc_setExtensionModelByClass:(id)extensionModel
{
    @synchronized (self) {
        if (!extensionModel) {
            ACCAssert(0, @"extensionModel must not be nil!");
            return NO;
        }
        NSString *key = NSStringFromClass([extensionModel class]);
        [self setObject:extensionModel forKey:key];
        return YES;
    }
}

- (void)acc_removeExtensionModel:(Class)modelClass
{
    @synchronized (self) {
        [self removeObjectForKey:NSStringFromClass(modelClass)];
    }
}

- (id)acc_extensionModelOfClass:(Class)modelClass
{
    @synchronized (self) {
        return [self objectForKey:NSStringFromClass(modelClass)];
    }
}

- (id)acc_extensionModelOfProtocol:(Protocol *)protocol
{
    __block id target = nil;
    [self acc_enumerateExtensionModels:YES requireProtocol:protocol requireSelector:nil block:^(NSString *clzStr, id model, BOOL *stop) {
        target = model;
        *stop = YES;
    }];
    return target;
}

- (NSMutableDictionary *)acc_deepCopyExtensionModels
{
    NSMutableDictionary *copyDict = nil;
    @synchronized (self) {
        copyDict = [self copy];
    }
    
    NSMutableDictionary *extensionModels = [NSMutableDictionary new];
    NSMutableArray *modelsArray = @[].mutableCopy;
    [copyDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [modelsArray addObject:[obj copy]];
    }];
    
    [modelsArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [extensionModels setObject:obj forKey:NSStringFromClass([obj class])];
    }];
    
    return extensionModels;
}

- (void)acc_enumerateExtensionModels:(BOOL)needCopy requireProtocol:(Protocol *)protocol requireSelector:(SEL)sel block:(void (^)(NSString *, id, BOOL *))block
{
    NSDictionary *extensionModels = nil;
    @synchronized (self) {
        extensionModels = [self copy];
    }
    
    [extensionModels enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (sel && ![obj respondsToSelector:sel]) {
            return;
        }
        if (protocol && ![obj conformsToProtocol:protocol]) {
            return;
        }
        block(key, obj, stop);
    }];
}

@end
