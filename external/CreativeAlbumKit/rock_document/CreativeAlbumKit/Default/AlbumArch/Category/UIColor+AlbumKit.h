//
//  UIColor+AlbumKit.h
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/8.
//

#import <UIKit/UIKit.h>
#import <CreativeKit/ACCColorNameDefines.h>

#define CAKResourceColor(name)  [UIColor cak_colorWithColorName:name]

@interface UIColor (AlbumKit)

+ (UIColor * _Nullable)cak_colorWithColorName:(NSString * _Nullable)colorName;

@end

