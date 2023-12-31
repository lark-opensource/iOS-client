//
//  AWEASMusicCategoryCollectionViewCell.m
//  AWEStudio
//
//  Created by 李茂琦 on 2018/9/4.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "AWEASMusicCategoryCollectionViewCell.h"
#import "ACCVideoMusicCategoryModel.h"

#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCMacrosTool.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCWebImageProtocol.h>


const CGFloat AWEASMusicCategoryCollectionViewCellLogoSideLength = 32.f;
const CGFloat AWEASMusicCategoryCollectionViewCellPadding = 12.f;

@interface AWEASMusicCategoryCollectionViewCell ()

@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) UILabel *categoryNameLabel;

@end

@implementation AWEASMusicCategoryCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

+ (CGFloat)recommendedHeight
{
    return AWEASMusicCategoryCollectionViewCellLogoSideLength;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView
{
    [self.contentView addSubview:self.logoImageView];
    [self.contentView addSubview:self.categoryNameLabel];
}

#pragma mark - Getter

- (UIImageView *)logoImageView
{
    if (!_logoImageView) {
        _logoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, AWEASMusicCategoryCollectionViewCellLogoSideLength, AWEASMusicCategoryCollectionViewCellLogoSideLength)];
    }
    return _logoImageView;
}

- (UILabel *)categoryNameLabel
{
    if (!_categoryNameLabel) {
        CGFloat width = self.acc_width - AWEASMusicCategoryCollectionViewCellLogoSideLength - AWEASMusicCategoryCollectionViewCellPadding;
        CGFloat height = 18.f;
        _categoryNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        _categoryNameLabel.acc_left = self.logoImageView.acc_right + 12.f;
        _categoryNameLabel.acc_centerY = self.logoImageView.acc_centerY;
        _categoryNameLabel.font = [ACCFont() acc_systemFontOfSize:15.f weight:ACCFontWeightRegular];
    }
    return _categoryNameLabel;
}

#pragma mark - Public

- (void)configWithMusicCategoryModel:(ACCVideoMusicCategoryModel *)model
{
    self.categoryNameLabel.text = model.name;
    NSArray *urlArray = model.awemeCover.URLList;
    if (ACC_isEmptyArray(urlArray)) {
        urlArray = model.cover.URLList;
    }
    [ACCWebImage() imageView:self.logoImageView setImageWithURLArray:urlArray];
}

#pragma mark - UIAccessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return self.categoryNameLabel.text;
}

@end
