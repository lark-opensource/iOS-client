//
//  AWECameraContainerToolButtonWrapView.m
//  AWEStudio
//
//Created by Hao Yipeng on June 14, 2018
//  Copyright  ©  Byedance. All rights reserved, 2018
//

#import "AWECameraContainerToolButtonWrapView.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCResourceHeaders.h>

static NSString * const kAWEToolButtonWrapViewNeedAddWidth = @"awe_tool_button_wrap_view_need_add_width";

@interface AWECameraContainerToolButtonWrapView ()

@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) UILabel *label;

@end

@implementation AWECameraContainerToolButtonWrapView

@synthesize imageName = _imageName;
@synthesize selectedImageName = _selectedImageName;
@synthesize needShow;
@synthesize barItemButton;
@synthesize itemViewDidClicked;

- (instancetype)initWithButton:(UIButton *)button label:(UILabel *)label {
    self = [super init];
    if (self) {
        [self setupWithButton:button label:label];
    }
    return self;
}

- (instancetype)initWithButton:(UIButton *)button label:(UILabel *)label itemID:(void *)itemID
{
    self = [super init];
    if (self) {
        self.itemID = itemID;
        [self setupWithButton:button label:label];
    }
    return self;
}

- (void)setupWithButton:(UIButton *)button label:(UILabel *)label
{
    CGFloat featureViewWidth = 52;
    CGFloat featureViewHeight = 48;

    self.acc_width = featureViewWidth;
    self.acc_height = featureViewHeight;

    [button addTarget:self action:@selector(onButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.button = button;
    self.button.acc_size = CGSizeMake(32, 32);
    self.button.acc_top = 0;
    self.button.acc_centerX = self.acc_width / 2;
    self.barItemButton = button;
    [self addSubview:button];
        
    self.label = label;
    CGSize labelSize = [self.label sizeThatFits:CGSizeMake(self.acc_width, CGFLOAT_MAX)];
    label.frame = CGRectMake(0, self.button.acc_bottom + 2.0, labelSize.width, labelSize.height);
    label.acc_centerX = button.acc_centerX;
    [self addSubview:label];
    [self bringSubviewToFront:button];
}

- (void)setImageName:(NSString *)imageName
{
    _imageName = imageName;
    [self.button setImage:ACCResourceImage(imageName) forState:UIControlStateNormal];
}

- (void)setSelectedImageName:(NSString *)selectedImageName
{
    _selectedImageName = selectedImageName;
    [self.button setImage:ACCResourceImage(selectedImageName) forState:UIControlStateSelected];
}

- (NSString *)imageName
{
    return _imageName;
}

- (NSString *)selectedImageName
{
    return _selectedImageName;
}

- (void)setTitle:(NSString *)title
{
    if (self.label) {
        self.label.text = title;
    }
}

- (NSString *)title
{
    if (self.label) {
        return self.label.text;
    }
    return nil;
}

- (void)setEnabled:(BOOL)enabled
{
    self.button.enabled = enabled;
}

- (BOOL)enabled
{
    return self.button.enabled;
}

- (void)setAlpha:(CGFloat)alpha
{
    self.button.alpha = alpha;
    self.label.alpha = alpha;
}

- (CGFloat)alpha
{
    return self.button.alpha;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    //No label
    if (!self.label) {
        return;
    }

    CGFloat bottomLabelY = CGRectGetMaxY(self.label.frame);
    CGFloat bottom = bottomLabelY - CGRectGetMaxY(self.button.frame);
    if (bottom > 0) {
        self.button.acc_hitTestEdgeInsets = UIEdgeInsetsMake(0, 0, -1 * bottom, 0);
    }
}

#pragma mark - Action

- (void)onButtonClicked:(UIButton *)button {
    ACCBLOCK_INVOKE(self.itemViewDidClicked, button);
}

@end
