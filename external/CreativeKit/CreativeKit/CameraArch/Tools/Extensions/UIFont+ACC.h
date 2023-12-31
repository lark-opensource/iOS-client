//
//  UIFont+ACC.h
//  CameraClient
//
//  Created by luochaojing on 2019/12/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIFont (ACC)

+ (UIFont *)acc_pingFangRegular:(CGFloat)size;

+ (UIFont *)acc_pingFangMedium:(CGFloat)size;

+ (UIFont *)acc_pingFangSemibold:(CGFloat)size;

+ (UIFont *)acc_fontWithName:(NSString *)fontName size:(CGFloat)fontSize;

@end

NS_ASSUME_NONNULL_END
