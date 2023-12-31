//
//  IESServiceProviderEntry.m
//  IESInject
//
//  Created by bytedance on 2020/2/10.
//

#import "IESServiceProviderEntry.h"
#import <objc/runtime.h>

@interface IESServiceWeakObject<T> : NSObject

@property (nonatomic, weak) T object;

@end

@implementation IESServiceWeakObject

@end

@interface IESServiceProviderEntry ()
{
    IESContainerProvider _provider;
    IESInjectScopeType _scopeType;
    id _singleCache;
    Class _aClass;
    IESServiceWeakObject *_weakObject;
}

@end

@implementation IESServiceProviderEntry

- (instancetype)initWithProvider:(IESContainerProvider)provider scopeType:(IESInjectScopeType)scopeType
{
    if (self = [super init]) {
        _provider = provider;
        _weakObject = [IESServiceWeakObject new];
        _scopeType = scopeType;
    }
    return self;
}

- (instancetype)initWithClass:(Class)aClass scopeType:(IESInjectScopeType)scopeType
{
    if (self = [super init]) {
        _aClass = aClass;
        _weakObject = [IESServiceWeakObject new];
        _scopeType = scopeType;
    }
    return self;
}

- (void)dealloc
{
    _singleCache = nil;
}

- (id)extractObject
{
    id object;
    
    if (!_singleCache) {
        if (_scopeType == IESInjectScopeTypeWeak && _weakObject.object != nil) {
            return _weakObject.object;
        }
        if (_aClass) {
            object = [[_aClass alloc] init];
        } else if (_provider) {
            object = _provider();
        }
        if (_scopeType == IESInjectScopeTypeWeak) {
            _weakObject.object = object;
        } else if (_scopeType == IESInjectScopeTypeSingleton) {
            _singleCache = object;
        }
        return object;
    }
    
    return _singleCache;
}

@end
