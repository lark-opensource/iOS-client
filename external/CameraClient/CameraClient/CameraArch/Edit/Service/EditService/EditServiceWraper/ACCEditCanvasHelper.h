//
//  ACCEditCanvasHelper.h
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/5/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCEditCanvasHelper : NSObject

+ (void)getTopColor:(UIColor **)topColor bottomColor:(UIColor **)bottomColor fromImage:(UIImage *)image;

+ (void)getMainColor:(UIColor **)mainColor fromImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
