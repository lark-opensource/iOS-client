//
//  IESServiceProvider.m
//  IESInject
//
//  Created by bytedance on 2020/2/10.
//

#import "IESServiceProvider.h"

@interface IESServiceProvider ()
{
    IESContainer *_container;
}
@end

@implementation IESServiceProvider

- (instancetype)initWithContainer:(IESContainer *)container
{
    if (self = [super init]) {
        _container = container;
    }
    return self;
}

- (id)resolveObject:(id)classOrProtocol
{
    return [_container resolveObject:classOrProtocol];
}

- (id)resolveCurrentContainerObject:(id)classOrProtocol
{
    return [_container resolveCurrentContainerObject:classOrProtocol];
}

- (id)resolveParentContainerObject:(id)classOrProtocol
{
    return [_container resolveParentContainerObject:classOrProtocol];
}

@end
