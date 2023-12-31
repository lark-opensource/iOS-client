//
//  CAKAlbumListTabConfig.m
//  CreativeAlbumKit-Pods-Aweme
//
//  Created by yuanchang on 2021/1/21.
//

#import "CAKAlbumListTabConfig.h"

@implementation CAKAlbumListTabConfig

- (instancetype)init
{
    if (self = [super init]) {
        _enableTab = YES;
        _enablePreview = YES;
        _enableMultiSelect = YES;
    }
    return self;
}

@end
