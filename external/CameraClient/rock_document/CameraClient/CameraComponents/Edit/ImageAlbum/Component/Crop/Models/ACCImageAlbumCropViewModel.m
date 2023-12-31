//
//  ACCImageAlbumCropViewModel.m
//  Indexer
//
//  Created by admin on 2021/11/11.
//

#import "ACCImageAlbumCropViewModel.h"
#import <CameraClient/ACCConfigKeyDefines.h>
#import <ByteDanceKit/BTDMacros.h>

const CGFloat ACCImageAlbumCropControlViewHeight = 204.0;
const CGFloat ACCImageAlbumCropControlViewCornerRadius = 12.0;

@interface ACCImageAlbumCropViewModel ()

@property (nonatomic, copy) NSString *cropTitle;

@end

@implementation ACCImageAlbumCropViewModel

- (NSString *)cropTitle
{
    return [self.class cropTitle];
}

+ (NSString *)cropTitle
{
    NSString *title = ACCConfigString(kConfigString_image_multi_crop_title);
    if (BTD_isEmptyString(title)) {
        title = @"调整";
    }
    return title;
}

@end
