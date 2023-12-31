//
//  AWEStoryToolBar.m
//  AWEStudio
//
//  Created by hanxu on 2018/11/19.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEStoryToolBar.h"
#import <CreationKitArch/AWEEditGradientView.h>
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <Masonry/View+MASAdditions.h>

@interface AWEStoryToolBar ()

@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) AWEEditGradientView *gradientView;
@property (nonatomic, assign) AWEStoryToolBarType type;

@end

@implementation AWEStoryToolBar

- (instancetype)initWithType:(AWEStoryToolBarType)type
{
    self = [super init];
    
    if (self) {
        _type = type;
        [self setupUI];
    }
    
    return self;
}

/// ******************
/// 布局太繁琐...
/// @todo @qiuhang 如果新样式的toolbar不能全量，那把这里用stackView重构下
/// ******************
- (void)setupUI
{
    [self addSubview:self.gradientView];
    ACCMasMaker(self.gradientView, {
        make.left.top.right.equalTo(self);
        make.bottom.equalTo(self.mas_bottom).offset(ACC_IPHONE_X_BOTTOM_OFFSET);
    });
    
    if (self.type == AWEStoryToolBarTypeColorAndFontWithOutAlign) {
        [self setupChooseColorAndFontWithoutAlignUI];
    } else if (self.type == AWEStoryToolBarTypeColorAndFont) {
        [self setupChooseColorAndFontUI];
    } else if (self.type == AWEStoryToolBarTypeColorFontAndTextReader) {
        [self setupChooseColorFontAndTextReaderUI];
    } else {
        [self setupChooseColorUI];
    }
}

- (void)setupChooseColorUI
{
    [self addSubview:self.leftButton];
    [self addSubview:self.lineView];
    [self addSubview:self.colorChooseView];
    
    ACCMasMaker(self.leftButton, {
        make.height.width.equalTo(@44);
        make.centerY.equalTo(self.mas_centerY);
        make.leading.equalTo(@6);
    });
    
    ACCMasMaker(self.lineView, {
        make.leading.equalTo(self.leftButton.mas_trailing).offset(7.5);
        make.centerY.equalTo(self.mas_centerY);
        make.size.mas_equalTo(CGSizeMake(0.5, 24));
    });
    
    ACCMasMaker(self.colorChooseView, {
        make.leading.equalTo(self.lineView.mas_trailing).offset(0);
        make.trailing.equalTo(self.mas_trailing);
        make.centerY.equalTo(self.mas_centerY);
        make.height.equalTo(self.mas_height);
    });
}

- (void)setupChooseColorAndFontUI
{
    [self addSubview:self.leftButton];
    [self addSubview:self.alignmentButton];
    [self addSubview:self.lineView];
    [self addSubview:self.fontChooseView];
    [self addSubview:self.colorChooseView];
    
    ACCMasMaker(self.leftButton, {
        make.leading.equalTo(@6);
        make.top.equalTo(self.mas_top).offset(4);
        make.height.width.equalTo(@44);
    });
    
    ACCMasMaker(self.alignmentButton, {
        make.leading.equalTo(self.leftButton.mas_trailing);
        make.centerY.equalTo(self.leftButton.mas_centerY);
        make.height.width.equalTo(@44);
    });
    
    ACCMasMaker(self.lineView, {
        make.leading.equalTo(self.alignmentButton.mas_trailing).offset(10);
        make.centerY.equalTo(self.leftButton.mas_centerY);
        make.size.mas_equalTo(CGSizeMake(0.5, 24));
    });
    
    ACCMasMaker(self.fontChooseView, {
        make.leading.equalTo(self.lineView.mas_trailing).offset(0);
        make.trailing.equalTo(self.mas_trailing);
        make.centerY.equalTo(self.leftButton.mas_centerY);
        make.height.mas_equalTo(52);
    });
    
    ACCMasMaker(self.colorChooseView, {
        make.leading.equalTo(self.mas_leading).offset(0);
        make.trailing.equalTo(self);
        make.top.equalTo(self.mas_top).offset(52);
        make.height.mas_equalTo(52);
    });
}

- (void)setupChooseColorFontAndTextReaderUI
{
    [self addSubview:self.leftButton];
    [self addSubview:self.alignmentButton];
    [self addSubview:self.textReaderButton];
    [self addSubview:self.lineView];
    [self addSubview:self.fontChooseView];
    [self addSubview:self.colorChooseView];
    
    ACCMasMaker(self.leftButton, {
        make.leading.equalTo(@6);
        make.top.equalTo(self.mas_top).offset(4);
        make.height.width.equalTo(@44);
    });
    
    ACCMasMaker(self.alignmentButton, {
        make.leading.equalTo(self.leftButton.mas_trailing);
        make.centerY.equalTo(self.leftButton.mas_centerY);
        make.height.width.equalTo(@44);
    });
    
    ACCMasMaker(self.textReaderButton, {
        make.leading.equalTo(self.alignmentButton.mas_trailing);
        make.centerY.equalTo(self.leftButton.mas_centerY);
        make.height.width.equalTo(@44);
    });
    
    ACCMasMaker(self.lineView, {
        make.leading.equalTo(self.textReaderButton.mas_trailing).offset(10);
        make.centerY.equalTo(self.leftButton.mas_centerY);
        make.size.mas_equalTo(CGSizeMake(0.5, 24));
    });
    
    ACCMasMaker(self.fontChooseView, {
        make.leading.equalTo(self.lineView.mas_trailing).offset(0);
        make.trailing.equalTo(self.mas_trailing);
        make.centerY.equalTo(self.leftButton.mas_centerY);
        make.height.mas_equalTo(52);
    });
    
    ACCMasMaker(self.colorChooseView, {
        make.leading.equalTo(self.mas_leading).offset(0);
        make.trailing.equalTo(self);
        make.top.equalTo(self.mas_top).offset(52);
        make.height.mas_equalTo(52);
    });
}

- (void)setupChooseColorAndFontWithoutAlignUI
{
    [self addSubview:self.leftButton];
    [self addSubview:self.lineView];
    [self addSubview:self.fontChooseView];
    [self addSubview:self.colorChooseView];
    
    self.gradientView.hidden = YES;
    
    ACCMasMaker(self.leftButton, {
        make.leading.equalTo(@6);
        make.centerY.equalTo(self.fontChooseView.mas_centerY);
        make.height.width.equalTo(@44);
    });
    
    ACCMasMaker(self.lineView, {
        make.leading.equalTo(self.leftButton.mas_trailing).offset(10);
        make.centerY.equalTo(self.leftButton.mas_centerY);
        make.size.mas_equalTo(CGSizeMake(0.5, 24));
    });
    
    ACCMasMaker(self.fontChooseView, {
        make.top.equalTo(self.mas_top);
        make.leading.equalTo(self.lineView.mas_trailing).offset(0);
        make.trailing.equalTo(self.mas_trailing);
        make.height.mas_equalTo(52);
    });
    
    ACCMasMaker(self.colorChooseView, {
        make.leading.equalTo(self.mas_leading).offset(0);
        make.trailing.equalTo(self);
        make.top.equalTo(self.fontChooseView.mas_bottom).offset(8);
        make.height.mas_equalTo(52);
    });
}

#pragma mark - getter

- (UIButton *)leftButton
{
    if (!_leftButton) {
        _leftButton = [[ACCAnimatedButton alloc] init];
    }
    return _leftButton;
}

- (UIButton *)alignmentButton
{
    if (!_alignmentButton) {
        _alignmentButton = [[ACCAnimatedButton alloc] init];
    }
    
    return _alignmentButton;
}

- (UIButton *)textReaderButton
{
    if (!_textReaderButton) {
        _textReaderButton = [[ACCAnimatedButton alloc] init];
    }
    return _textReaderButton;
}

- (UIView *)lineView
{
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = ACCResourceColor(ACCUIColorConstLineInverse);
    }
    
    return _lineView;
}

- (AWEStoryFontChooseView *)fontChooseView
{
    if (!_fontChooseView) {
        _fontChooseView = [[AWEStoryFontChooseView alloc] init];
        _fontChooseView.collectionView.contentInset = UIEdgeInsetsMake(0, 20, 0, 10);
        [_fontChooseView acc_edgeFading];
    }
    
    return _fontChooseView;
}

- (AWEStoryColorChooseView *)colorChooseView
{
    if (!_colorChooseView) {
        _colorChooseView = [[AWEStoryColorChooseView alloc] init];
        _colorChooseView.collectionView.contentInset = UIEdgeInsetsMake(0, 10, 0, 10);
        [_colorChooseView acc_edgeFading];
    }
    return _colorChooseView;
}

- (AWEEditGradientView *)gradientView
{
    if (!_gradientView) {
        _gradientView = [[AWEEditGradientView alloc] initWithFrame:CGRectZero topColor:[[UIColor blackColor] colorWithAlphaComponent:0.0] bottomColor:[[UIColor blackColor] colorWithAlphaComponent:0.5]];
        _gradientView.alpha = 0.5;
    }
    return _gradientView;
}

+ (CGFloat)barHeight
{
    return 104.f;
}

@end
