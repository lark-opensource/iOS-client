//
//  CAKBaseServiceContainer+Bundle.m
//  CreativeAlbumKit
//
//  Created by yuanchang on 2021/1/8.
//

#import "CAKBaseServiceContainer+Bundle.h"
#import "CAKResourceBundleImpl.h"

@implementation CAKBaseServiceContainer (Bundle)

IESProvidesSingleton(CAKResourceBundleProtocol)
{
    return [[CAKResourceBundleImpl alloc] init];
}

@end
