//
//  CAKAlbumSelectedAssetsViewConfig.m
//  CreativeAlbumKit-Pods-Aweme
//
//  Created by yuanchang on 2020/12/21.
//

#import "CAKAlbumSelectedAssetsViewConfig.h"

@implementation CAKAlbumSelectedAssetsViewConfig

- (instancetype)init
{
    if (self = [super init]) {
        _shouldHideSelectedAssetsViewWhenNotSelect = YES;
        
        _enableSelectedAssetsViewForPreviewPage = NO;
        _shouldHideSelectedAssetsViewWhenNotSelectForPreviewPage = YES;
        _enableDragToMoveForSelectedAssetsView = YES;
        _enableDragToMoveForSelectedAssetsViewInPreviewPage = YES;
    }
    return self;
}

@end
