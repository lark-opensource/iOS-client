//
//  IESServiceEntry.m
//  IESInject
//
//  Created by bytedance on 2020/2/5.
//

#import "IESServiceEntry.h"
#import "IESContainer.h"

@implementation IESServiceEntry

@synthesize scopeType;

- (id)extractObject
{
    return nil;
}

 - (IESInjectScopeType)scopeType
{
    return IESInjectScopeTypeNone;
}

@end
