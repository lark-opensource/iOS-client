//
//  UIFont+DVE.h
//  DVEFoundationKit
//
//  Created by bytedance on 2021/11/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIFont (DVE)

+ (UIFont *)dve_systemFontOfSize:(CGFloat)size;

+ (UIFont *)dve_systemFontOfSize:(CGFloat)size weight:(UIFontWeight)weight;

+ (UIFont *)dve_boldSystemFontOfSize:(CGFloat)size;

+ (UIFont *)dve_pingFangRegular:(CGFloat)size;

+ (UIFont *)dve_pingFangMedium:(CGFloat)size;

+ (UIFont *)dve_pingFangSemibold:(CGFloat)size;

+ (UIFont *)dve_helveticaBold:(CGFloat)size;

+ (UIFont *)dve_fontWithName:(NSString *)fontName size:(CGFloat)fontSize;

@end

NS_ASSUME_NONNULL_END
