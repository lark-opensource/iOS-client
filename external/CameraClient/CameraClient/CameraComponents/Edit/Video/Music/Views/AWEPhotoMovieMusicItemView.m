//
//  AWEPhotoMovieMusicItemView.m
//  AWEStudio
//
//  Created by 黄鸿森 on 2018/3/23.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEPhotoMovieMusicItemView.h"
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

@implementation AWEPhotoMovieMusicItemCircleView
- (void)drawRect:(CGRect)rect
{
    UIBezierPath *circle = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(rect, 1, 1) cornerRadius:_cornerRadius];
    circle.lineWidth = 2;
    [ACCResourceColor(ACCColorPrimary) setStroke];
    [circle stroke];
}
@end

@interface AWEPhotoMovieMusicItemView()
@property (nonatomic, strong) UIImageView *musicImageView;
@property (nonatomic, assign) CGSize imageSize;
@property (nonatomic, strong) AWEPhotoMovieMusicItemCircleView *circleView;
@property (nonatomic, strong) UIImageView *gradientImageView;
@property (nonatomic, strong) UILabel *durationLabel;
@end

@implementation AWEPhotoMovieMusicItemView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];

        _musicImageView = [[UIImageView alloc] init];
        //此处需要将M判断改为[AWEUIInterface isLightUIStyle]
        _musicImageView.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainer7);
        [self addSubview:_musicImageView];

        _circleView = [[AWEPhotoMovieMusicItemCircleView alloc] init];
        _circleView.backgroundColor = [UIColor clearColor];
        [self addSubview:_circleView];
    }
    return self;
}

- (instancetype)initWithImageSize:(CGSize)size {
    self = [self initWithFrame:CGRectZero];

    if (self) {
        _circleView.cornerRadius = size.width / 2.f;
        _imageSize = size;
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(size.width / 2, size.height / 2)
                                                                radius:size.width / 2.f
                                                            startAngle:0
                                                              endAngle:M_PI * 2
                                                             clockwise:YES];
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.path = maskPath.CGPath;
        maskLayer.frame = CGRectMake(0, 0, size.width, size.height);
        _musicImageView.layer.mask = maskLayer;
        ACCMasMaker(_circleView, {
            make.edges.equalTo(self);
        });

        ACCMasMaker(_musicImageView, {
            make.width.equalTo(@(size.width));
            make.height.equalTo(@(size.height));
            make.center.equalTo(self);
        });
    }
    return self;
}

- (instancetype)initWithRectangleImageSize:(CGSize)size circleViewOffset:(CGFloat)offset radius:(CGFloat)radius {
    self = [self initWithFrame:CGRectZero];

    if (self) {
        _imageSize = size;
        _circleView.cornerRadius = radius;
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size.width, size.height) cornerRadius:radius];
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.path = maskPath.CGPath;
        maskLayer.frame = CGRectMake(0, 0, size.width, size.height);
        _musicImageView.layer.mask = maskLayer;
        _musicImageView.layer.cornerRadius = radius;
        ACCMasMaker(_circleView, {
            make.width.equalTo(@(size.width + offset));
            make.height.equalTo(@(size.height + offset));
            make.center.equalTo(self);
        });

        ACCMasMaker(_musicImageView, {
            make.width.equalTo(@(size.width));
            make.height.equalTo(@(size.height));
            make.center.equalTo(self);
        });
    }
    return self;
}

- (instancetype)initWithRectangleImageSize:(CGSize)size radius:(CGFloat)radius {
    self = [self initWithFrame:CGRectZero];

    if (self) {
        _imageSize = size;
        _circleView.cornerRadius = radius - 1.0f;
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size.width, size.height) cornerRadius:radius];
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.path = maskPath.CGPath;
        maskLayer.frame = CGRectMake(0, 0, size.width, size.height);
        _musicImageView.layer.mask = maskLayer;
        _musicImageView.layer.cornerRadius = radius;
        ACCMasMaker(_circleView, {
            make.edges.equalTo(self);
        });

        ACCMasMaker(_musicImageView, {
            make.width.equalTo(@(size.width));
            make.height.equalTo(@(size.height));
            make.center.equalTo(self);
        });
    }
    return self;
}

- (void)setMusicThumbnailURLList:(NSArray *)thumbnailURLList
{
    [self setMusicThumbnailURLList:thumbnailURLList placeholder:nil];
}

- (void)setMusicThumbnailURLList:(NSArray *)thumbnailURLList placeholder:(UIImage *)placeholder
{
    @weakify(self);
    [ACCWebImage() imageView:self.musicImageView setImageWithURLArray:thumbnailURLList placeholder:placeholder options:ACCWebImageOptionsIgnoreAnimatedImage | ACCWebImageOptionsSetImageWithFadeAnimation completion:^(UIImage *image, NSURL *url, NSError *error) {
        @strongify(self);
        if ([thumbnailURLList containsObject:[url absoluteString]]) {
            if (image != nil) {
                self.musicImageView.image = image;
            }
        } else {
            self.musicImageView.image = ACCResourceImage(@"background_music_mask");
        }
    }];
    [self setNeedsLayout];
}

- (void)setMusicBackgroundColor:(UIColor *)backgroundColor
{
    self.musicImageView.backgroundColor = backgroundColor;
}

- (void)setImage:(UIImage *)image
{
    self.musicImageView.image = image;
    [self setNeedsLayout];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if (selected) {
        self.circleView.alpha = 1.f;
    } else {
        self.circleView.alpha = 0.f;
    }
    [self setNeedsLayout];
}

- (void)setDuration:(NSTimeInterval)duration show:(BOOL)show
{
    if (show) {
        if (self.gradientImageView.superview == nil) {
            [self addSubview:self.gradientImageView];
        }
        if (self.durationLabel.superview == nil) {
            [self addSubview:self.durationLabel];
            ACCMasMaker(self.durationLabel, {
                make.bottom.equalTo(self).offset(-3);
                make.right.equalTo(self).offset(-4);
            });
        }
        self.gradientImageView.hidden = NO;
        self.durationLabel.hidden = NO;
        self.gradientImageView.frame = self.bounds;
        self.durationLabel.text = [self p_timeStringWithDuration:duration];
    } else {
        _gradientImageView.hidden = YES;
        _durationLabel.hidden = YES;
    }
}

- (UIImageView *)gradientImageView
{
    if (_gradientImageView == nil) {
        _gradientImageView = [[UIImageView alloc] initWithImage:ACCResourceImage(@"cover_gradient_mask")];
        _gradientImageView.frame = self.bounds;
    }
    return _gradientImageView;
}

- (UILabel *)durationLabel
{
    if (_durationLabel == nil) {
        _durationLabel = [[UILabel alloc] init];
        _durationLabel.numberOfLines = 1;
        _durationLabel.font = [ACCFont() systemFontOfSize:9.6 weight:ACCFontWeightSemibold];
        _durationLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
        _durationLabel.textAlignment = NSTextAlignmentRight;
        _durationLabel.backgroundColor = [UIColor clearColor];
        _durationLabel.shadowOffset = CGSizeMake(0, 1);
        _durationLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.15];
    }
    return _durationLabel;
}

- (NSString *)p_timeStringWithDuration:(NSTimeInterval)duration
{
    NSInteger seconds = (NSInteger)duration;
    NSInteger second = seconds % 60;
    NSInteger minute = seconds / 60;
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)minute, (long)second];
}

@end
