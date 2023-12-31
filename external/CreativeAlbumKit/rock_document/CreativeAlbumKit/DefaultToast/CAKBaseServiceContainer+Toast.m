//
//  CAKBaseServiceContainer+Toast.m
//  CreativeAlbumKit
//
//  Created by yuanchang on 2021/1/8.
//

#import "CAKBaseServiceContainer+Toast.h"
#import "CAKToastImpl.h"

@implementation CAKBaseServiceContainer (Toast)

IESProvides(CAKToastProtocol)
{
    return [[CAKToastImpl alloc] init];
}

@end
