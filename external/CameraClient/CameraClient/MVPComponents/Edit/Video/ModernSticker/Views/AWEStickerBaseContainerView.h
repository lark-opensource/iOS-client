//
//  AWEStickerBaseContainerView.h
//  AAWELaunchMainPlaceholder-iOS8.0
//
//  Created by li xingdong on 2019/5/22.
//

#import <UIKit/UIKit.h>

@interface AWEStickerBaseContainerView : UIView

@property (nonatomic, strong) UIView *maskViewOne;
@property (nonatomic, strong) UIView *maskViewTwo;
@property (nonatomic, strong) UIView *maskViewThree;    // 支持全面屏适配
@property (nonatomic, strong) UIView *maskViewFour;     // 支持全面屏适配

- (void)makeMaskLayerForMaskViewOneWithRadius:(CGFloat)radius;

- (void)makeMaskLayerForMaskViewTwoWithRadius:(CGFloat)radius;

@end
