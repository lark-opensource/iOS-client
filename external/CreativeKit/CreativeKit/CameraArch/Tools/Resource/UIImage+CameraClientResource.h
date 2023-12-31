//
//  UIImage+CameraClientResource.h
//  CameraClient
//
//  Created by Liu Deping on 2019/11/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern UIImage *ACCResourceImage(NSString *name);

@interface UIImage (CameraClientResource)

+ (UIImage *)acc_imageWithName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
