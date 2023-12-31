//
//  ACCASCommonBindMusicSectionHeaderView.m
//  AWEStudio-iOS8.0
//
//  Created by songxiangwu on 2019/3/4.
//

#import "ACCASCommonBindMusicSectionHeaderView.h"

#import <CreativeKit/UIColor+CameraClientResource.h>

@interface ACCASCommonBindMusicSectionHeaderView ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *rightLabel;

@end

@implementation ACCASCommonBindMusicSectionHeaderView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        [self.contentView addSubview:self.topLineView];
        [self.contentView addSubview:self.titleLabel];
        [self.contentView addSubview:self.rightLabel];
    }
    return self;
}

- (void)configWithTitle:(NSString *)title rightContent:(NSString *)rightContent cellWidth:(CGFloat)cellWidth
{
    self.titleLabel.text = title;
    self.rightLabel.text = rightContent;
    if (rightContent.length) {
        [self.rightLabel sizeToFit];
    } else {
        self.rightLabel.frame = CGRectZero;
    }
    CGSize size = [self.titleLabel sizeThatFits:CGSizeMake(cellWidth - 16 * 2 - 8 * 2 - self.rightLabel.bounds.size.width, CGFLOAT_MAX)];
    self.titleLabel.frame = CGRectMake(0, 0, size.width, size.height);
}

+ (CGFloat)recommendHeight
{
    return 38 + 16;
}

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width - 16 * 2;
    self.topLineView.frame = CGRectMake(16, 0, w, 1.f/[UIScreen mainScreen].scale);
    CGRect frame = self.titleLabel.frame;
    frame.size.height = 18;
    frame.origin.x = 24;
    frame.origin.y = 8 + 16;
    self.titleLabel.frame = frame;
    frame = self.rightLabel.frame;
    frame.size.height = 18;
    frame.origin.x = CGRectGetMaxX(self.titleLabel.frame);
    frame.origin.y = 8 + 16;
    self.rightLabel.frame = frame;
}

- (UIView *)topLineView
{
    if (!_topLineView) {
        _topLineView = [[UIView alloc] init];
        _topLineView.backgroundColor = ACCResourceColor(ACCUIColorConstLinePrimary);
    }
    return _topLineView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = ACCResourceColor(ACCUIColorConstTextPrimary);
        _titleLabel.font = [UIFont boldSystemFontOfSize:15];
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _titleLabel.numberOfLines = 0;
    }
    return _titleLabel;
}

- (UILabel *)rightLabel
{
    if (!_rightLabel) {
        _rightLabel = [[UILabel alloc] init];
        _rightLabel.textColor = ACCResourceColor(ACCUIColorConstTextTertiary); 
        _rightLabel.font = [UIFont systemFontOfSize:13];
    }
    return _rightLabel;
}

@end
