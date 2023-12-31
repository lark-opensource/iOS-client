//
//  AWEMusicTitleControl.m
//  AWEStudio
//
//  Created by 李彦松 on 2018/9/19.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWEMusicTitleControl.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>

#import <CreativeKit/ACCFontProtocol.h>
#import <Masonry/View+MASAdditions.h>

@interface AWEMusicTitleControl ()

@property (nonatomic, strong, readwrite) UILabel *aweTitleLabel;
@property (nonatomic, strong, readwrite) UIView *backgroundColorView;

@end

@implementation AWEMusicTitleControl

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _paddings = UIEdgeInsetsZero;
        [self setupUI];
    }
    return self;
}

- (void)setPaddings:(UIEdgeInsets)paddings
{
    if (UIEdgeInsetsEqualToEdgeInsets(paddings, self.paddings)) {
        return;
    }
    _paddings = paddings;
    ACCMasUpdate(self.aweTitleLabel, {
        make.top.equalTo(self).equalTo(@(self.paddings.top));
        make.leading.equalTo(self).equalTo(@(self.paddings.left));
        make.bottom.equalTo(self).equalTo(@(-self.paddings.bottom));
        make.trailing.equalTo(self).equalTo(@(-self.paddings.right));
    });
}

- (void)setupUI
{
    [self addSubview:self.backgroundColorView];
    ACCMasMaker(self.backgroundColorView, {
        make.top.leading.bottom.trailing.equalTo(self);
    });
    
    [self addSubview:self.aweTitleLabel];
    ACCMasMaker(self.aweTitleLabel, {
        make.top.equalTo(self).equalTo(@(self.paddings.top));
        make.leading.equalTo(self).equalTo(@(self.paddings.left));
        make.bottom.equalTo(self).equalTo(@(-self.paddings.bottom));
        make.trailing.equalTo(self).equalTo(@(-self.paddings.right));
    });
}

- (UILabel *)aweTitleLabel
{
    if (!_aweTitleLabel) {
        _aweTitleLabel = [[UILabel alloc] init];
        _aweTitleLabel.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightSemibold];
        [_aweTitleLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_aweTitleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                          forAxis:UILayoutConstraintAxisHorizontal];
        _aweTitleLabel.userInteractionEnabled = NO;
    }
    return _aweTitleLabel;
}

- (UIView *)backgroundColorView
{
    if (!_backgroundColorView) {
        _backgroundColorView = [[UIView alloc] init];
        _backgroundColorView.userInteractionEnabled = NO;
    }
    return _backgroundColorView;
}

@end
