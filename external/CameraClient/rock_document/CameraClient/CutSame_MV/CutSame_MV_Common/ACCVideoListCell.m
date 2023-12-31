//
//  AWEVideoListCell.m
//  AWEStudio
//
//  Created by lixingdong on 2018/5/22.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCVideoListCell.h"
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

static NSString *const ACCVideoListCellCoverImageFadeAnimationKey = @"ACCVideoListCellCoverImageFadeAnimationKey";

@interface ACCVideoListCell ()

@property (nonatomic, strong) UIImageView *coverImageView;

@end

@implementation ACCVideoListCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.coverImageView];
        [self.contentView addSubview:self.timeLabel];
        
        ACCMasMaker(self.coverImageView, {
            make.edges.equalTo(self.contentView);
        });
        ACCMasMaker(self.timeLabel, {
            make.centerX.equalTo(self.contentView.mas_centerX);
            make.centerY.equalTo(self.contentView.mas_centerY);
        });
    }
    return self;
}

- (UIImageView *)coverImageView
{
    if (!_coverImageView) {
        _coverImageView = [[UIImageView alloc] init];
        _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        _coverImageView.clipsToBounds = YES;
        _coverImageView.layer.cornerRadius = 2;
        _coverImageView.alpha = 1.0;
    }
    return _coverImageView;
}

- (UILabel *)timeLabel
{
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        _timeLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
        _timeLabel.layer.shadowColor = ACCResourceColor(ACCColorSDSecondary).CGColor;
        _timeLabel.layer.shadowOffset = CGSizeMake(0, 2);
        _timeLabel.layer.shadowOpacity = 1.0;
        _timeLabel.layer.shadowRadius = 1.5f;
    }
    return _timeLabel;
}

- (void)setCoverImage:(UIImage *)coverImage animated:(BOOL)animated
{
    self.coverImage = coverImage;
    if (animated) {
        [self.coverImageView.layer removeAnimationForKey:ACCVideoListCellCoverImageFadeAnimationKey];

        CATransition *transition = [CATransition animation];
        transition.duration = 0.3;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionFade;
        [self.coverImageView.layer addAnimation:transition forKey:ACCVideoListCellCoverImageFadeAnimationKey];
        self.coverImageView.image = coverImage;
    } else {
        self.coverImageView.image = coverImage;
    }
}

@end
