//
//  BDPAppearance.h
//  Timor
//
//  Created by liuxiangxin on 2019/5/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDPAppearance <NSObject>

@required

/// 样式类别
///
/// 样式类别定义了一组UI样式组合，如背景色以及圆角的样式组合。
/// 含有相同的样式类别的控件具有相同的样式组合的值，
/// 如两个控件含有相同的上述样式类别，它们的背景色和圆角值都会相同
/// 如果一个控件上多个样式组合含有相同的样式，那么，按照数组中定义的顺序，后面的样式会覆盖前面的样式
@property (nonatomic, copy) NSArray<NSString *> *bdp_styleCategories;

/// 获取样式类别下的代理实例
/// @param category 样式类别
+ (instancetype)bdp_styleForCategory:(NSString *)category;

@end

NS_ASSUME_NONNULL_END
