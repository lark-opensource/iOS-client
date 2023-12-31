//
//  AWEVoiceChangerItemView.m
//  Pods
//
//  Created by chengfei xiao on 2019/5/24.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEVoiceChangerItemView.h"
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <Masonry/View+MASAdditions.h>

@interface AWEVoiceChangerItemCircleView : UIView
@end


@implementation AWEVoiceChangerItemCircleView
- (void)drawRect:(CGRect)rect
{
    UIBezierPath *circle = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(rect, 1, 1) cornerRadius:rect.size.width / 2];
    circle.lineWidth = 2;
    [ACCResourceColor(ACCColorPrimary) setStroke];
    [circle stroke];
}
@end

@interface AWEVoiceChangerItemView ()
@property (nonatomic, strong) UIView *coverView;
@property (nonatomic, strong) AWEVoiceChangerItemCircleView *circleView;
@property (nonatomic, assign) CGSize imageSize;
@property (nonatomic, strong) UIImageView *centerImageView;//原声或占位图
@property (nonatomic, assign) BOOL useLocalImage;
@property (nonatomic, strong) UIImage *localImage;
@property (nonatomic, assign) CGSize localImageSize;
@end

@implementation AWEVoiceChangerItemView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:self.circleView];
        [self addSubview:self.coverView];
        
        [self makeSubviewConstraints];
        self.imageSize = CGSizeMake(52, 52);
    }
    return self;
}

#pragma mark -

- (AWEVoiceChangerItemCircleView *)circleView
{
    if (!_circleView) {
        _circleView = [[AWEVoiceChangerItemCircleView alloc] init];
        _circleView.backgroundColor = [UIColor clearColor];
    }
    return _circleView;
}

- (UIView *)coverView
{
    if (!_coverView) {
        _coverView = [[UIImageView alloc] init];
        _coverView.backgroundColor = ACCUIColorFromRGBA(0xffffff, 0.15f);
        
        _centerImageView = [[UIImageView alloc] init];
        [self->_coverView addSubview:_centerImageView];
        ACCMasMaker(_centerImageView, {
            make.center.equalTo(self->_coverView);
            make.size.mas_equalTo(CGSizeZero);
        });
    }
    return _coverView;
}

#pragma mark - Constraints

- (void)makeSubviewConstraints
{
    ACCMasMaker(_circleView, {
        make.edges.equalTo(self).insets(UIEdgeInsetsMake(-2, -2, -2, -2));
        make.center.equalTo(self);
    });
    
    ACCMasMaker(_coverView, {
        make.width.mas_equalTo(52);
        make.height.mas_equalTo(52);
        make.center.equalTo(self);
    });
}

#pragma mark -

- (void)setImageSize:(CGSize)imageSize
{
    _imageSize = imageSize;
    
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(imageSize.width / 2, imageSize.height / 2)
                                                            radius:imageSize.width / 2
                                                        startAngle:0
                                                          endAngle:M_PI * 2
                                                         clockwise:YES];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = maskPath.CGPath;
    maskLayer.frame = CGRectMake(0, 0, imageSize.width, imageSize.height);
    _coverView.layer.mask = maskLayer;
    
    ACCMasUpdate(_coverView, {
        make.width.mas_equalTo(imageSize.width);
        make.height.mas_equalTo(imageSize.height);
        make.center.equalTo(self);
    });
}

- (void)setCenterImage:(UIImage *)img size:(CGSize)size
{
    acc_dispatch_main_async_safe(^{
        self.useLocalImage = YES;
        self.localImage = img;
        self.localImageSize = size;
        [self setIconImage:img size:size];
    });
}

- (void)setIconImage:(UIImage *)img size:(CGSize)size
{
    self.centerImageView.image = img;
    ACCMasUpdate(self.centerImageView, {
        make.size.mas_equalTo(size);
    });
}

- (void)setThumbnailURLList:(NSArray *)thumbnailURLList
{
    [self setThumbnailURLList:thumbnailURLList placeholder:nil];
}

- (void)setThumbnailURLList:(NSArray *)thumbnailURLList placeholder:(UIImage *)placeholder
{
    self.useLocalImage = NO;
    @weakify(self);
    [ACCWebImage() imageView:self.centerImageView setImageWithURLArray:thumbnailURLList
                                        placeholder:placeholder
                                            options:ACCWebImageOptionsIgnoreAnimatedImage | ACCWebImageOptionsSetImageWithFadeAnimation
                                         completion:^(UIImage *image, NSURL *url, NSError *error) {
        @strongify(self);
        if ([thumbnailURLList containsObject:[url absoluteString]]) {
            if (image != nil) {
                acc_dispatch_main_async_safe(^{
                    if (!self.useLocalImage) {
                        [self setIconImage:image size:CGSizeMake(32, 32)];
                        [self setNeedsLayout];
                    } else {
                        [self setIconImage:self.localImage size:self.localImageSize];
                    }
                });
            }
        }
    }];
}

- (void)setCoverBackgroundColor:(UIColor *)backgroundColor
{
    self.coverView.backgroundColor = backgroundColor;
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

@end
