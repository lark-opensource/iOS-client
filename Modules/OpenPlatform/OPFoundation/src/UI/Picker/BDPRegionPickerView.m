//
//  BDPRegionPickerView.m
//  TTMicroApp-Example
//
//  Created by 刘相鑫 on 2019/1/16.
//  Copyright © 2019 Bytedance.com. All rights reserved.
//

#import "BDPRegionPickerView.h"
#import <OPFoundation/BDPI18n.h>
#import "BDPRegionPickerDelegate.h"
#import <OPFoundation/UIColor+EMA.h>
#import <OPFoundation/BDPAddressPluginModel.h>
#import <OPFoundation/UIView+BDPExtension.h>
#import <Masonry/Masonry.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>

@interface BDPRegionPickerView ()

@property (nonatomic, strong) UIView *background;
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIPickerView *picker;

@property (nonatomic, strong, readwrite) BDPRegionPickerPluginModel *model;

@property (nonatomic, strong) BDPRegionPickerDelegate *pickerDelegate;
@property (nonatomic, assign, readwrite) BDPRegionPickerViewStyle style;

@end

@implementation BDPRegionPickerView

#pragma mark - init

- (instancetype)initWithFrame:(CGRect)frame model:(BDPRegionPickerPluginModel *)model
{
    return [self initWithFrame:frame model:model style:BDPRegionPickerViewStylePicker];
}

- (instancetype)initWithFrame:(CGRect)frame model:(BDPRegionPickerPluginModel *)model style:(BDPRegionPickerViewStyle)style
{
    self = [super initWithFrame:frame];
    if (self) {
        _model = model;
        _style = style;
        [self setupSubviews];
        [self setupDataSource];
        [self.pickerDelegate selectCurrent];
    }
    return self;
}

#pragma mark - UI

- (void)setupSubviews
{
    [self setupBackground];
    [self setupPicker];
    [self setupToolBar];
}

- (void)setupBackground
{
    _background = [[UIView alloc] initWithFrame:self.bounds];
    _background.backgroundColor = UDOCColor.bgMask;
    _background.alpha = 0.f;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionCancel:)];
    [_background addGestureRecognizer:tap];
    [self addSubview:_background];
    [_background mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self);
    }];

}

- (void)setupToolBar
{
    _toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.bdp_bottom, self.bdp_width, 40)];
    _toolbar.translucent = NO;
    _toolbar.barTintColor = UDOCColor.bgBody;
    UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithTitle:BDPI18n.cancel style:UIBarButtonItemStylePlain target:self action:@selector(actionCancel:)];
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithTitle:BDPI18n.confirm style:UIBarButtonItemStylePlain target:self action:@selector(actionConfirm:)];
    [left setTintColor:UDOCColor.primaryPri500];
    [right setTintColor:UDOCColor.primaryPri500];
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    if (_style == BDPRegionPickerViewStyleAlert) {
        UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        fixedSpace.width = 20;
        [_toolbar setItems:@[fixedSpace,
                             left,
                             space,
                             right,
                             fixedSpace]];
    } else {
        [_toolbar setItems:@[left,
                             space,
                             right]];
    }
    [self addSubview:_toolbar];
    
}

- (void)setupPicker
{
    _picker = [[UIPickerView alloc] initWithFrame:CGRectZero];
    _picker.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _picker.backgroundColor = UDOCColor.bgBody;

    [_picker sizeToFit];
    _picker.bdp_top = self.bdp_bottom;
    _picker.bdp_width = self.bdp_width;

    [self addSubview:_picker];
    
}

- (void)showInView:(UIView *)view
{
    self.style = BDPRegionPickerViewStylePicker;
    [view addSubview:self];
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(view);
    }];
    [UIView animateWithDuration:0.25f animations:^{
        self.background.alpha = 1;
        // 此处逻辑由原始frame布局迁移为autolayout, 布局遵循原始frame布局不变
        [_toolbar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.width.mas_equalTo(self);
            make.height.mas_equalTo(40.0);
        }];
        [_picker mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.mas_equalTo(self);
            make.width.centerX.mas_equalTo(self);
            make.top.mas_equalTo(_toolbar.mas_bottom);
        }];
        // 改用autolayout后，需要调用一次layoutIfNeeded以在动画过程中立即生效
        [self layoutIfNeeded];
    }];
}

- (void)showAlertInView:(UIView *)view
{
    self.style = BDPRegionPickerViewStyleAlert;
    [_toolbar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.width.mas_equalTo(self);
        make.height.mas_equalTo(40.0);
    }];
    [_picker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self).offset(20);
        make.width.centerX.mas_equalTo(self);
        make.top.mas_equalTo(_toolbar.mas_bottom);
    }];
    [self layoutIfNeeded];

}

- (void)dismiss
{
    if (self.style == BDPRegionPickerViewStyleAlert) {
        [self removeFromSuperview];
        return;
    }

    [UIView animateWithDuration:0.25f animations:^{
        self.background.alpha = 0.f;
        // 此处逻辑由原始frame布局迁移为autolayout, 布局遵循原始frame布局不变
        [_toolbar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.width.mas_equalTo(self);
            make.height.mas_equalTo(40.0);
            make.top.mas_equalTo(self.mas_bottom);
        }];
        [_picker mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(_toolbar.mas_bottom);
            make.width.centerX.mas_equalTo(self);
        }];
        // 改用autolayout后，需要调用一次layoutIfNeeded以在动画过程中立即生效
        [self layoutIfNeeded];

    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        self.cancelBlock = nil;
        self.confirmBlock = nil;
    }];

}

#pragma mark - Data

- (void)setupDataSource
{
    _pickerDelegate = [[BDPRegionPickerDelegate alloc] initWithModel:self.model pickerView:self.picker];
}

#pragma mark - Action

- (void)actionCancel:(id)sender
{
    if (self.cancelBlock) {
        self.cancelBlock();
    } if ([self.delegate respondsToSelector:@selector(regionPickerViewDidCancel:)]) {
        [self.delegate regionPickerViewDidCancel:self];
    }
    
    [self dismiss];
}

- (void)actionConfirm:(id)sender
{
    BDPAddressPluginModel *address = [self.pickerDelegate currentAddress];
    if (self.confirmBlock) {
        self.confirmBlock(address);
    } else if ([self.delegate respondsToSelector:@selector(regionPickerView:didConfirmAddress:)]) {
        [self.delegate regionPickerView:self didConfirmAddress:address];
    }
    
    [self dismiss];
}

@end
