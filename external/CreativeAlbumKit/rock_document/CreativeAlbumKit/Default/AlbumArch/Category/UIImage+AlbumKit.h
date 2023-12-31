//
//  UIImage+AlbumKit.h
//  Pods
//
//  Created by yuanchang on 2020/12/4.
//

#import <UIKit/UIKit.h>

#define CAKResourceImage(name)  [UIImage cak_imageWithName:name]

@interface UIImage (AlbumKit)

+ (UIImage * _Nullable)cak_imageWithName:(NSString * _Nullable)name;

@end
