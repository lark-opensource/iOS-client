//
//  IESServiceBindingEntry.m
//  IESInject
//
//  Created by bytedance on 2020/2/10.
//

#import "IESServiceBindingEntry.h"

@interface IESServiceBindingEntry ()
{
    id _instance;
}
@end

@implementation IESServiceBindingEntry

- (instancetype)initWithInstance:(id)instance
{
    if (self = [super init]) {
        _instance = instance;
    }
    return self;
}

- (void)dealloc
{
    _instance = nil;
}

- (IESInjectScopeType)scopeType
{
    return IESInjectScopeTypeSingleton;
}

- (id)extractObject
{
    return _instance;
}

@end
