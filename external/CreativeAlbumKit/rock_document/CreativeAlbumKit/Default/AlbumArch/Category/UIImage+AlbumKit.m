//
//  UIImage+AlbumKit.m
//  Pods
//
//  Created by yuanchang on 2020/12/4.
//

#import "UIImage+AlbumKit.h"
#import <CreativeKit/ACCMacros.h>
#import "CAKResourceUnion.h"
#import <IESLiveResourcesButler/IESLiveResouceBundle+Image.h>

@implementation UIImage (AlbumKit)

+ (UIImage *)cak_imageWithName:(NSString *)name
{
    if (ACC_isEmptyString(name)) {
        return nil;
    }
    
    UIImage *image = CAKResourceUnion.albumResourceBundle.image(name);
    if (!image) {
        image = [UIImage imageNamed:name inBundle:CAKResourceUnion.albumResourceBundle.bundle compatibleWithTraitCollection:nil];
    }
    NSAssert(image != nil, @"CreativeAlbumKit does not find image:%@", name);
    
    return image;
}

@end
