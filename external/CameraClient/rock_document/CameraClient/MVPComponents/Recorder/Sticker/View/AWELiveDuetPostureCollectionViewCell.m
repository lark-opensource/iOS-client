//
//  AWELiveDuetPostureCollectionViewCell.m
//  CameraClient-Pods-Aweme
//
//  Created by Syenny on 2021/1/14.
//

#import "AWELiveDuetPostureCollectionViewCell.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>

#import <QuartzCore/QuartzCore.h>
#import <CreativeKit/UIColor+CameraClientResource.h>

@interface AWELiveDuetPostureCollectionViewCell ()

@property (nonatomic, strong) UIImageView *iconImageView;

@property (nonatomic, strong) UIView *selectedIndicatorView;

@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

@property (nonatomic, assign, readwrite) BOOL isCellSelected;

@end

@implementation AWELiveDuetPostureCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = 5;
        self.contentView.layer.cornerRadius = 5;
        self.contentView.backgroundColor = [UIColor clearColor];

        [self addSubviews];

        [self.contentView addGestureRecognizer:self.tapGesture];
    }
    return self;
}

- (void)addSubviews
{
    [self.contentView addSubview:self.iconImageView];
    ACCMasMaker(self.iconImageView, {
        make.edges.equalTo(self.contentView);
    });

    [self.contentView addSubview:self.selectedIndicatorView];
    ACCMasMaker(self.selectedIndicatorView, {
        make.edges.equalTo(self.contentView);
    });
}

#pragma mark - Download Image

- (void)updateIconImage:(UIImage *)image
{
    [self.iconImageView setImage:image];
}

#pragma mark - Select / Unselect Cell

- (void)updateSelectedStatus:(BOOL)selected {
    if (selected) {
        [self indicatorAppear];
    } else {
        [self indicatorDisappear];
    }
}

- (void)indicatorAppear
{
    [UIView animateWithDuration:0.15
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                        self.isCellSelected = YES;
                        self.selectedIndicatorView.alpha = 1.0f;
                     }
                     completion:nil];
}

- (void)indicatorDisappear {
    [UIView animateWithDuration:0.15
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                        self.isCellSelected = NO;
                        self.selectedIndicatorView.alpha = 0.0f;
                     }
                     completion:nil];
}

#pragma mark - UI

- (UITapGestureRecognizer *)tapGesture
{
    if (!_tapGesture) {
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAnimation)];
        _tapGesture.cancelsTouchesInView = NO;
    }
    return _tapGesture;
}

- (void)tapAnimation
{
    [UIView animateWithDuration:0.1 animations:^{
        self.layer.transform = CATransform3DMakeScale(1.1, 1.1, 1.1);
    } completion:^(BOOL finished) {
        if (finished) {
            [UIView animateWithDuration:0.1 animations:^{
                self.layer.transform = CATransform3DIdentity;
            }];
        }
    }];
}

- (UIImageView *)iconImageView
{
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.layer.cornerRadius = 4;
        _iconImageView.clipsToBounds = YES;
        _iconImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _iconImageView;
}

- (UIView *)selectedIndicatorView
{
    if (!_selectedIndicatorView) {
        _selectedIndicatorView = [[UIView alloc] init];
        _selectedIndicatorView.backgroundColor = [UIColor clearColor];
        _selectedIndicatorView.layer.cornerRadius = 4;
        _selectedIndicatorView.layer.borderColor = ACCResourceColor(ACCColorPrimary).CGColor;
        _selectedIndicatorView.layer.borderWidth = 2;
        _selectedIndicatorView.alpha = 0.0f;
    }
    return _selectedIndicatorView;
}

@end
