//
//  BDPMessagePermissoinContentView.m
//  Timor
//
//  Created by 刘相鑫 on 2019/6/14.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

static const CGFloat kMessageLabelOffsetTop = 8.f;
static const CGFloat kMessageLabelOffsetBottom = 72.f;
static const CGFloat kTitleLabelOffsetTop = 36.f;
static const CGFloat kTitleLabelOffsetTopNewStyle = 20.f;
static const CGFloat kTitleLabelHeight = 24.f;

#import "BDPMessagePermissoinContentView.h"
#import <OPFoundation/UIColor+BDPExtension.h>
#import <OPFoundation/UIFont+BDPExtension.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>

@interface BDPMessagePermissoinContentView ()

@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *message;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UILabel *messageLabel;
@property (nonatomic, assign) BOOL enableNewStyle;

@end

@implementation BDPMessagePermissoinContentView

#pragma mark - init

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message  isNewStyle:(BOOL)enableNewStyle
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _title = title.copy;
        _message = message.copy;
        _enableNewStyle = enableNewStyle;
        [self setupUI];
    }
    return self;
}

#pragma mark - UI

- (void)setupUI
{
    [self setupTitleLabel];
    [self setupMessageLabel];
}

- (void)setupTitleLabel
{
    UILabel *label = [UILabel new];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:label];
    self.titleLabel = label;
    label.textColor = UDOCColor.textTitle;
    label.font = [UIFont bdp_pingFongSCWithWeight:UIFontWeightMedium size:_enableNewStyle ? 16.0 : 18.f];
    label.text = self.title;
    [label.leftAnchor constraintEqualToAnchor:self.leftAnchor].active = YES;
    CGFloat top = _enableNewStyle ? kTitleLabelOffsetTopNewStyle : kTitleLabelOffsetTop;
    [label.topAnchor constraintEqualToAnchor:self.topAnchor constant:top].active = YES;
    [label.heightAnchor constraintEqualToConstant:kTitleLabelHeight].active = YES;
    [label.rightAnchor constraintEqualToAnchor:self.rightAnchor].active = YES;
    [label sizeToFit];
}

- (void)setupMessageLabel
{
    UILabel *label = [UILabel new];
    label.numberOfLines = 0;
    [self addSubview:label];
    self.messageLabel = label;
    
    label.textColor = UDOCColor.textTitle;
    label.font = [UIFont bdp_pingFongSCWithWeight:UIFontWeightRegular size:14.f];
    label.text = self.message;
    
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [label.leftAnchor constraintEqualToAnchor:self.leftAnchor].active = YES;
    [label.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:kMessageLabelOffsetTop].active = YES;
    CGFloat bottom = _enableNewStyle ? -kTitleLabelOffsetTopNewStyle : -kMessageLabelOffsetBottom;
    [label.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:bottom].active = YES;
    [label.rightAnchor constraintEqualToAnchor:self.rightAnchor].active = YES;

    [label sizeToFit];
}

//- (CGSize)intrinsicContentSize
//{
//    return CGSizeMake(0, 104.f);
//}

@end
