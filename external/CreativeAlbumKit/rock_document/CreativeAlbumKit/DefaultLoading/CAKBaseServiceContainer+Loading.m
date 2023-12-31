//
//  CAKBaseServiceContainer+Loading.m
//  CreativeAlbumKit
//
//  Created by yuanchang on 2021/1/8.
//

#import "CAKBaseServiceContainer+Loading.h"
#import "CAKLoadingImpl.h"

@implementation CAKBaseServiceContainer (Loading)

IESProvides(CAKLoadingProtocol)
{
    return [[CAKLoadingImpl alloc] init];
}

@end
