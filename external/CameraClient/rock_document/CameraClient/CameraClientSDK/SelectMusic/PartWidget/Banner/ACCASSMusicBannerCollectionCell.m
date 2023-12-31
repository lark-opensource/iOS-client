//
//  ACCASSMusicBannerCollectionCell.m
//  AWEStudio
//
//  Created by 旭旭 on 2018/8/31.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "ACCASSMusicBannerCollectionCell.h"

#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCWebImageProtocol.h>


@interface ACCASSMusicBannerCollectionCell ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, copy) id<ACCBannerModelProtocol> model;

@end

@implementation ACCASSMusicBannerCollectionCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _imageView = [[UIImageView alloc] init];
        _imageView.backgroundColor = ACCResourceColor(ACCUIColorConstBGInput);
        [self.contentView addSubview:_imageView];
    }
    return self;
}

- (void)refreshWithModel:(id<ACCBannerModelProtocol>)model
{
    _model = model;
    [ACCWebImage() imageView:self.imageView setImageWithURLArray:model.bannerURL.URLList
                                   options:ACCWebImageOptionsSetImageWithFadeAnimation];
}

- (void)refreshWithPlaceholderModel:(id<ACCBannerModelProtocol>)model
{
    _model = model;
    _imageView.image = nil;
}

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _imageView.frame = self.contentView.bounds;
}

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return [NSString stringWithFormat:@"%@", self.model.title];
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitNone;
}

@end
