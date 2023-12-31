//
//  UIImage+DYCResources.m
//  BDDynamically
//
//  Created by zuopengliu on 29/8/2018.
//

#import "UIImage+DYCResources.h"
#import "BDDYCUtils.h"
#import "BDDYCResourceManager.h"



@implementation UIImage (DYCResources)

+ (void)load
{
    /*
    BDDYCSwapClassMethods(self,
                          @selector(imageNamed:),
                          @selector(bddyc_imageNamed:));
    BDDYCSwapClassMethods(self,
                          @selector(imageNamed:inBundle:compatibleWithTraitCollection:),
                          @selector(bddyc_imageNamed:inBundle:compatibleWithTraitCollection:));
     */
}

+ (UIImage *)bddyc_imageNamed:(NSString *)name
{
    UIImage *aImage = [self bddyc_imageNamed:name];
    if (aImage) return aImage;
    
    // TODO:
    return aImage;
}

+ (UIImage *)bddyc_imageNamed:(NSString *)name inBundle:(NSBundle *)bundle compatibleWithTraitCollection:(UITraitCollection *)traitCollection
{
    UIImage *aImage = [self bddyc_imageNamed:name
                                    inBundle:bundle
               compatibleWithTraitCollection:traitCollection];
    if (aImage) return aImage;
    
    // TODO:
    return aImage;
}

@end
