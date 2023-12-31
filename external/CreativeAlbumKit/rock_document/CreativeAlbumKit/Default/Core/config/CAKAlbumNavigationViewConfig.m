//
//  CAKAlbumNavigationViewConfig.m
//  CreativeAlbumKit_Example
//
//  Created by yuanchang on 2020/12/1.
//  Copyright © 2020 lixingdong. All rights reserved.
//

#import "CAKAlbumNavigationViewConfig.h"
#import "CAKLanguageManager.h"

@implementation CAKAlbumNavigationViewConfig

- (instancetype)init
{
    if (self = [super init]) {
        _enableChooseAlbum = YES;
        _hiddenCancelButton = NO;
        _titleText = CAKLocalizedString(@"im_all_photos", @"All photos");
    }
    return self;
}

@end
