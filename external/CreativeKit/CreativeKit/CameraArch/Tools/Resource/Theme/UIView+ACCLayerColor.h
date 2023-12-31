//
//  UIView+ACCLayerColor.h
//  CreativeKit-Pods-Aweme
//
//  Created by xiangpeng on 2021/9/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (ACCLayerColor)

///Set the bordercolor of the layer to support hot switch
@property (nonatomic, strong) UIColor *acc_layerBorderColor;

/// Set the backgroundColor of the layer to support hot switch
@property (nonatomic, strong) UIColor *acc_layerBackgroundColor;

@end

NS_ASSUME_NONNULL_END
