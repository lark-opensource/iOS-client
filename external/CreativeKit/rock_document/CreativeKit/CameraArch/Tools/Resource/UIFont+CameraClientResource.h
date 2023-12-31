//
//  UIFont+CameraClientResource.h
//  CameraClient
//
//  Created by Liu Deping on 2020/4/8.
//

#import <UIKit/UIKit.h>
#import "ACCResourceFontConfigKeys.h"

NS_ASSUME_NONNULL_BEGIN

extern UIFont *ACCResourceFont(NSString *name);
extern UIFont *ACCResourceFontSize(NSString *name, CGFloat size);

@interface UIFont (CameraClientResource)

+ (UIFont *)acc_bundleFontWithName:(NSString *)name;

+ (UIFont *)acc_bundleFontWithName:(NSString *)name size:(CGFloat)size;

@end

NS_ASSUME_NONNULL_END
