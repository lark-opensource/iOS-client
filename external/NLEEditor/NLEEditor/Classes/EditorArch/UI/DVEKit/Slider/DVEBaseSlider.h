//
//  DVEBaseSlider.h
//  TTVideoEditorDemo
//
//  Created by bytedance on 2020/12/20
//  Copyright © 2021 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Masonry/MASConstraint.h>

NS_ASSUME_NONNULL_BEGIN

@class DVEBaseSlider;

@protocol DVESBaseSliderProtocol <NSObject>

- (void)touchesSliderBegan:(DVEBaseSlider *)slider;
- (void)touchesSliderEnd:(DVEBaseSlider *)slider;
- (void)touchesSliderValueChange:(DVEBaseSlider *)slider;

@end

@interface DVEBaseSlider : UIView

/// 最小值
@property (nonatomic, assign) float minimumValue;
/// 最大值
@property (nonatomic, assign) float maximumValue;
/// 滑竿布局的水平偏移
@property (nonatomic, assign) float horizontalInset;
/// 滑竿高度（不算游标）
@property (nonatomic, assign) CGFloat sliderHeight;
/// 代理
@property (nonatomic, weak) id<DVESBaseSliderProtocol> delegate;
/// 滑竿游标的 Image
@property (nonatomic, strong) UIImage *imageCursor;
/// 滑竿覆盖颜色
@property (nonatomic, strong) UIColor *silderStrokeColor;
/// 滑竿中间竖线颜色（目前设置为隐藏）
@property (nonatomic, strong) UIColor *centralLineColor;
/// 滑竿背景颜色
@property (nonatomic, strong) UIColor *backLayerBackgroundColor;
/// 滑竿值
@property (nonatomic, assign) float value;
/// 滑竿游标文案
@property (nonatomic, strong) UILabel *label;
/// 文案和游标之间的间距
@property (nonatomic, assign) CGFloat textOffset;
/// 滑竿覆盖 Layer
@property (nonatomic, strong) CAShapeLayer *tintLayer;
/// 滑竿背景 Layer
@property (nonatomic, strong) CALayer *backLayer;
/// 滑竿游标的 Size
@property (nonatomic, assign) CGSize cursorSize;
/// 是否在默认值的位置展示标记
@property (nonatomic, assign) BOOL defaultMarkShow;
/// 默认值位置的标记 Image
@property (nonatomic, copy) NSString *markImageName;

- (instancetype)initWithStep:(float)step
                defaultValue:(float)defaultvalue
                       frame:(CGRect)frame;

@end

NS_ASSUME_NONNULL_END
