//
//  UIImage+BulletX.m
//  Bullet
//
//  Created by 王丹阳 on 2020/11/25.
//

#import <ByteDanceKit/BTDMacros.h>

@implementation UIImage (BDXContainer)

+ (nullable UIImage *)page_imageNamed:(NSString *)imageName
{
    if (BTD_isEmptyString(imageName)) {
        return nil;
    }

    NSURL *resURL = [[NSBundle mainBundle] URLForResource:@"pageResource" withExtension:@"bundle"];

    if (!resURL) {
        return nil;
    }
    NSBundle *bundle = [NSBundle bundleWithURL:resURL];
    UIImage *image = [[UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    return image ?: [UIImage imageNamed:imageName];
}

@end
