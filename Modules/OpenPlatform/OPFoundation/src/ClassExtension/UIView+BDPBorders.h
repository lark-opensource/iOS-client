//
//  UIView+BDPBorders.h
//  Timor
//
//  Created by liuxiangxin on 2019/3/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (BDPBorders)

@property (nonatomic, strong, nullable) UIView *bdp_topBorder;
@property (nonatomic, strong, nullable) UIView *bdp_leftBorder;
@property (nonatomic, strong, nullable) UIView *bdp_bottomBorder;
@property (nonatomic, strong, nullable) UIView *bdp_rightBorder;

- (void)bdp_addBorderForEdges:(UIRectEdge)edges width:(CGFloat)width color:(UIColor *)color;

@end

@interface UITabBar (BDPBorders)

@end

NS_ASSUME_NONNULL_END
