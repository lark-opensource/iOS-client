//
//  ACCImageAlbumDotPageControlCollectionViewCell.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/10/13.
//

#import "ACCImageAlbumDotPageControlCollectionViewCell.h"

@interface ACCImageAlbumDotPageControlCollectionViewCell ()

@property (nonatomic, strong, nullable) UIView *dotView;

@property (nonatomic, strong, nullable) CAGradientLayer *gradientLayer;

@end

@implementation ACCImageAlbumDotPageControlCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.dotView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    self.dotView.layer.cornerRadius = self.contentView.frame.size.width / 2.f;
    self.gradientLayer.frame = self.dotView.bounds;
    self.gradientLayer.cornerRadius = self.contentView.frame.size.width / 2.f;
}

#pragma mark - Private Methods

- (void)p_setupUI
{
    [self.contentView addSubview:self.dotView];
}

#pragma mark - Getters

- (UIView *)dotView
{
    if (!_dotView) {
        _dotView = [[UIView alloc] init];
        _dotView.layer.cornerRadius = self.contentView.frame.size.width / 2.f;
        _dotView.backgroundColor = [UIColor colorWithWhite:1.f alpha:.5f];
        _dotView.layer.borderWidth = .5f;
        _dotView.layer.borderColor = [UIColor colorWithWhite:0.f alpha:.12f].CGColor;
    }
    return _dotView;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if (selected) {
        self.dotView.backgroundColor = [UIColor colorWithWhite:1.f alpha:1.f];
    } else {
        self.dotView.backgroundColor = [UIColor colorWithWhite:1.f alpha:.5f];
    }
}

- (CAGradientLayer *)gradientLayer
{
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.startPoint = CGPointMake(1, 0.5);
        _gradientLayer.endPoint = CGPointMake(0, 0.5);
        _gradientLayer.colors = @[
            (id)[UIColor colorWithWhite:1.f alpha:1.0f].CGColor,
            (id)[UIColor colorWithWhite:1.f alpha:0.1f].CGColor,
        ];
        _gradientLayer.locations = @[@0.0,
                                     @1.0];
    }
    return _gradientLayer;
}

@end
