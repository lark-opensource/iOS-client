//
//  DVEStepSlider.h
//  TTVideoEditorDemo
//
//  Created by bytedance on 2020/12/20
//  Copyright © 2021 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DVEBaseSlider.h"

typedef struct DVEFloatRang {
    CGFloat location;
    CGFloat length;
} DVEFloatRang;

CG_INLINE DVEFloatRang DVEMakeFloatRang (CGFloat location,CGFloat length)
{
    DVEFloatRang veRang;
    veRang.location = location;
    veRang.length = length;
    
    return veRang;
}

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, DVEStepSliderValueType) {
    DVEStepSliderValueTypeNone, //整数，无单位
    DVEStepSliderValueTypePercent, //整数，百分比
    DVEStepSliderValueTypeSecond, //小数，单位s
};

@interface DVEStepSlider : UIControl<DVESBaseSliderProtocol>

/// 数值类型
@property (nonatomic, assign) DVEStepSliderValueType valueType;
/// 最小值
@property (nonatomic, assign) float minimumValue;
/// 最大值
@property (nonatomic, assign) float maximumValue;
/// 当前滑竿值
@property (nonatomic, assign) float value;
/// 滑竿覆盖颜色
@property (nonatomic, strong) UIColor *minimumTrackTintColor;
/// 滑竿背景颜色
@property (nonatomic, strong) UIColor *maximumTrackTintColor;
/// 滑竿高度（不算游标）
@property (nonatomic, assign) CGFloat sliderHeight;
@property (nonatomic, strong) DVEBaseSlider *slider;
@property (nonatomic, assign, readonly) DVEFloatRang valueRange;
/// 滑竿布局的水平偏移
@property (nonatomic, assign) float horizontalInset;

- (instancetype)initWithStep:(float)step
                defaultValue:(float)defaultvalue
                       frame:(CGRect)frame;

- (void)setValueRange:(DVEFloatRang)rang defaultProgress:(float)progress;

@end

NS_ASSUME_NONNULL_END
