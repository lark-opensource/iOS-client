//
//  UIColor+AlbumKit.m
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/8.
//

#import "UIColor+AlbumKit.h"
#import "CAKServiceLocator.h"
#import "CAKResourceUnion.h"
#import <CreativeKit/ACCMacros.h>
#import "CAKResourceBundleProtocol.h"
#import <IESLiveResourcesButler/IESLiveResouceBundle+Color.h>

@interface IESLiveResouceBundle (Template)

- (NSString * (^)(NSString *key))colorTemplate;

@end

@implementation IESLiveResouceBundle (Template)

- (NSString * (^)(NSString *key))colorTemplate {
    return ^(NSString * key) {
        NSString *hex = [self objectForKey:key type:@"color"];
        if ([hex hasPrefix:@"@color/"]) {
            return [hex substringFromIndex:7];
        }
        return @"";
    };
}

@end

@implementation UIColor (AlbumKit)

+ (UIColor *)cak_colorWithColorName:(NSString *)colorName
{
    if (ACC_isEmptyString(colorName)) {
        return nil;
    }
    UIColor *color = [CAKResourceUnion albumResourceBundle].color(colorName);
    
    NSAssert(color != nil, @"CreativeAlbumKit does not find color:%@", colorName);
    return color ? color : [UIColor whiteColor];
}

@end
