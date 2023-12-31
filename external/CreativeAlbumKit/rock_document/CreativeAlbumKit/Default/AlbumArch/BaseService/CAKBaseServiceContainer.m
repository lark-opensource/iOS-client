//
//  CAKBaseServiceContainer.m
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/8.
//

#import "CAKBaseServiceContainer.h"

@implementation CAKBaseServiceContainer

+ (instancetype)sharedContainer
{
    static dispatch_once_t onceToken;
    static CAKBaseServiceContainer *baseServiceContainer = nil;
    dispatch_once(&onceToken, ^{
        baseServiceContainer = [[self alloc] init];
    });
    return baseServiceContainer;
}

@end

IESContainer* CAKBaseContainer() {
    return [CAKBaseServiceContainer sharedContainer];
}

IESServiceProvider* CAKBaseServiceProvider()
{
    static IESServiceProvider *baseProvider = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        baseProvider = [[IESServiceProvider alloc] initWithContainer:CAKBaseContainer()];
        
    });
    return baseProvider;
}
