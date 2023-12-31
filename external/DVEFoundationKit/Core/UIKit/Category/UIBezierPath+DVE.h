//
//  UIBezierPath+DVE.h
//  DVEFoundationKit
//
//  Created by bytedance on 2021/4/12.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIBezierPath (DVE)

+ (instancetype)dve_bezierPathWithRoundedRect:(CGRect)roundedRect
                                topLeftRadius:(CGFloat)topLeftRadius
                               topRightRadius:(CGFloat)topRightRadius
                             bottomLeftRadius:(CGFloat)bottomLeftRadius
                            bottomRightRadius:(CGFloat)bottomRightRadius;

@end

NS_ASSUME_NONNULL_END
