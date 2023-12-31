//
//  CAKServiceLocator.m
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/8.
//

#import "CAKServiceLocator.h"

IESContainer* __attribute__((weak)) CAKBaseContainer()
{
    // Caution: Should provide your own implementation!
    assert(NO);
    return nil;
}

IESServiceProvider* __attribute__((weak)) CAKBaseServiceProvider()
{
    // Caution: Should provide your own implementation!
    assert(NO);
    return nil;
}
