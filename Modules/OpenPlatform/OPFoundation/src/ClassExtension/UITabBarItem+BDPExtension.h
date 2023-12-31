//
//  UITabBarItem+BDPExtension.h
//  Timor
//
//  Created by yinyuan on 2021/1/10.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITabBarItem (BDPExtension)

/// 设置 Title 最大宽度，超出宽度使用 ... 展示
/// @param maxWidth 最大宽度
/// @param attributes 仅参与计算，不会实际应用
- (void)bdp_applyTitleMaxWidth:(CGFloat)maxWidth attributes:(NSDictionary<NSAttributedStringKey,id> *)attributes;

/// image 是否已经被 API 设置过（如果设置过，就不会再自动响应 Dark Mode 的配置）
@property(nonatomic, assign) BOOL bdp_hasSetImageByAPI;

/// selectedImage 是否已经被 API 设置过（如果设置过，就不会再自动响应 Dark Mode 的配置）
@property(nonatomic, assign) BOOL bdp_hasSetSelectedImageByAPI;

/// 是否是使用addTabBarItem这个API添加的tabBarItem（如果是，那么内部调用setTabBarItem的时候不会讲上面了两个置YES）
@property(nonatomic, assign) BOOL bdp_itemAddedByAPI;

/// 原始title
@property(nonatomic, strong) NSString *originalTitle;


@end

NS_ASSUME_NONNULL_END
