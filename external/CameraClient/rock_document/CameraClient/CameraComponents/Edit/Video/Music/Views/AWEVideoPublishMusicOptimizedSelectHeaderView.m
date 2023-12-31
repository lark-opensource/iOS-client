//
//  AWEVideoPublishMusicOptimizedSelectHeaderView.m
//  Pods
//
//  Created by resober on 2019/5/23.
//

#import "AWEVideoPublishMusicOptimizedSelectHeaderView.h"
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCLanguageProtocol.h>

static const CGFloat kImageViewSideLength = 56.f;
static const CGFloat kImageAndLabelVerticalGap = 8.f;

@interface AWEVideoPublishMusicOptimizedSelectHeaderView ()
@property (nonatomic, strong) UIImageView *innerImageView;
@end

@implementation AWEVideoPublishMusicOptimizedSelectHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUIOptimization];
    }
    return self;
}

- (void)setupUIOptimization {
    // 因为实现新的UI，父类的imageView不展示image了，当做有背景色的container
    self.imageView.frame = CGRectMake(0, 0, 56.f, 56.f);
    self.imageView.image = nil;
    self.imageView.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainerInverse);
    self.imageView.layer.masksToBounds = YES;
    self.imageView.layer.cornerRadius = 2;

    [self.imageView addSubview:self.innerImageView];
    self.innerImageView.frame = CGRectMake(14, 14, 28, 28);
    self.label.text = ACCLocalizedString(@"creation_music_panel_more_music", @"creation_music_panel_more_music");

    self.label.font = [UIFont systemFontOfSize:12];
    self.label.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
    self.label.numberOfLines = 0;
    CGSize calcedSize = [self.label sizeThatFits:CGSizeMake(kImageViewSideLength, CGFLOAT_MAX)];
    self.label.frame = CGRectMake(0,
                                  self.imageView.frame.origin.y + self.imageView.frame.size.height + kImageAndLabelVerticalGap,
                                  kImageViewSideLength,
                                  MIN(30.f, calcedSize.height)); // 30.f = 15.f * 2(最多两行)

    self.dotSeparatorView.hidden = YES;
}

- (UIImageView *)innerImageView {
    if (!_innerImageView) {
        _innerImageView = [[UIImageView alloc] initWithImage:ACCResourceImage(@"icon_edit_music_panel_opt_more")];
    }
    return _innerImageView;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(kImageViewSideLength,
                      kImageViewSideLength + kImageAndLabelVerticalGap + self.label.frame.size.height);
}
@end
