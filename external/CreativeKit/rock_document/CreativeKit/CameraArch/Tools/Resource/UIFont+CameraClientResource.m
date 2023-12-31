//
//  UIFont+CameraClientResource.m
//  CameraClient
//
//  Created by Liu Deping on 2020/4/8.
//

#import "UIFont+CameraClientResource.h"
#import "ACCResourceUnion.h"
#import <IESLiveResourcesButler/IESLiveResouceBundle+Style.h>
#import <IESLiveResourcesButler/IESLiveResouceStyleModel.h>

extern UIFont *ACCResourceFont(NSString *name)
{
    return [UIFont acc_bundleFontWithName:name];
}

extern UIFont *ACCResourceFontSize(NSString *name, CGFloat size)
{
    return [UIFont acc_bundleFontWithName:name size:size];
}

@implementation UIFont (CameraClientResource)

+ (UIFont *)acc_bundleFontWithName:(NSString *)name {
    UIFont *resultFont = ACCResourceUnion.cameraResourceBundle.style(name).font;
    NSAssert(resultFont != nil, @"CameraClient does not find font:%@", name);
    return resultFont;
}

+ (UIFont *)acc_bundleFontWithName:(NSString *)name size:(CGFloat)size {
    return [[self acc_bundleFontWithName:name] fontWithSize:size];
}

@end
