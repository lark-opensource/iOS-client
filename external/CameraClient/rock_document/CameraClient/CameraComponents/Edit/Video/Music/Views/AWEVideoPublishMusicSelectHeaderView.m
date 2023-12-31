//
//  AWEVideoPublishMusicSelectHeaderView.m
//  AWEStudio
//
//  Created by Nero Li on 2019/1/20.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import "AWEVideoPublishMusicSelectHeaderView.h"
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>

@interface AWEVideoPublishMusicSelectHeaderView()
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) AWEMusicEditorCollectionHeaderView *dotSeparatorView;
@end

@implementation AWEVideoPublishMusicSelectHeaderView
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 4, 54, 49)];
        imageView.image = ACCResourceImage(@"iconMusicLibrary_ai");
        [self addSubview:imageView];
        self.imageView = imageView;
        imageView.isAccessibilityElement = YES;
        imageView.accessibilityLabel = @"更多音乐";
        imageView.accessibilityTraits = UIAccessibilityTraitButton;
        imageView.accessibilityViewIsModal = YES;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(imageView.frame) + 8, 56, 15)];
        label.text = ACCLocalizedCurrentString(@"com_mig_music_library");
        label.font = [ACCFont() systemFontOfSize:11 weight:ACCFontWeightRegular];
        label.textColor = ACCResourceColor(ACCUIColorConstTextInverse3);
        label.textAlignment = NSTextAlignmentCenter;
        label.center = CGPointMake(imageView.center.x, label.center.y);
        self.label = label;
        [self addSubview:label];
        
        AWEMusicEditorCollectionHeaderView *dotSeparatorView = [[AWEMusicEditorCollectionHeaderView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(imageView.frame), 0, 30, 80)];
        [dotSeparatorView updateDotTop:25.f];
        [self addSubview:dotSeparatorView];
        self.dotSeparatorView = dotSeparatorView;
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
        [self addGestureRecognizer:tapGesture];
    }
    return self;
}

- (void)updateImage:(UIImage *)image
{
    self.imageView.image = image;
}

- (void)tapped:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(musicLibraryIconDidTapped)]) {
        [self.delegate musicLibraryIconDidTapped];
    }
}

@end
