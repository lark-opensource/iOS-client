//
//  UIImage+CameraClientResource.m
//  CameraClient
//
//  Created by Liu Deping on 2019/11/1.
//

#import "ACCResourceHeaders.h"
#import "ACCMacros.h"
#import "ACCResourceUnion.h"
#import <IESLiveResourcesButler/IESLiveResouceBundle+Image.h>

UIImage *ACCResourceImage(NSString *name)
{
    return [UIImage acc_imageWithName:name];
}

@implementation UIImage (CameraClientResource)

+ (UIImage *)acc_imageWithName:(NSString *)name
{
    if (ACC_isEmptyString(name)) {
        return nil;
    }
    
    UIImage *image = ACCResourceUnion.cameraResourceBundle.image(name);
    if (!image) {
        image = [UIImage imageNamed:name inBundle:ACCResourceUnion.cameraResourceBundle.bundle compatibleWithTraitCollection:nil];
    }
    
    return image;
}

@end
