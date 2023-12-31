//
//  ACCASMusicCategoryTableViewCell.m
//  CameraClient
//
//  Created by 李茂琦 on 2018/9/5.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "ACCASMusicCategoryTableViewCell.h"
#import "ACCVideoMusicCategoryModel.h"

#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>

#import <CreativeKit/ACCMacrosTool.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>


const CGFloat ACCASMusicCategoryTableViewCellVerticalPadding = 10.f;
const CGFloat ACCASMusicCategoryTableViewCellContentHeight = 32.f;
const CGFloat ACCASMusicCategoryTableViewCellHorizontalPadding = 12.f;
const CGFloat ACCASMusicCategoryTableViewCellContentMargin = 16.f;

@interface ACCASMusicCategoryTableViewCell ()

@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) UILabel *categoryNameLabel;

@end

@implementation ACCASMusicCategoryTableViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

+ (CGFloat)recommendedHeight
{
    return ACCASMusicCategoryTableViewCellContentHeight + 2 * ACCASMusicCategoryTableViewCellVerticalPadding;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.contentView addSubview:self.logoImageView];
    [self.contentView addSubview:self.categoryNameLabel];
}

- (UIImageView *)logoImageView
{
    if (!_logoImageView) {
        CGFloat left = ACCASMusicCategoryTableViewCellContentMargin;
        CGFloat top = ACCASMusicCategoryTableViewCellVerticalPadding;
        CGFloat width = ACCASMusicCategoryTableViewCellContentHeight;
        CGFloat height = ACCASMusicCategoryTableViewCellContentHeight;
        _logoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(left, top, width, height)];
    }
    return _logoImageView;
}

- (UILabel *)categoryNameLabel
{
    if (!_categoryNameLabel) {
        CGFloat left = self.logoImageView.acc_right + ACCASMusicCategoryTableViewCellHorizontalPadding;
        CGFloat top = ACCASMusicCategoryTableViewCellVerticalPadding;
        CGFloat width = self.acc_width - left - ACCASMusicCategoryTableViewCellContentMargin;
        CGFloat height = ACCASMusicCategoryTableViewCellContentHeight;
        _categoryNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(left, top, width, height)];
        _categoryNameLabel.font = [ACCFont() systemFontOfSize:15.f weight:ACCFontWeightRegular];
        [ACCLanguage() disableLocalizationsOfObj:_categoryNameLabel];
    }
    return _categoryNameLabel;
}

- (void)configWithMusicCategoryModel:(ACCVideoMusicCategoryModel *)model
{
    self.categoryNameLabel.text = model.name;
    NSArray *urlArray = model.awemeCover.URLList;
    if (ACC_isEmptyArray(urlArray)) {
        urlArray = model.cover.URLList;
    }
    [ACCWebImage() imageView:self.logoImageView setImageWithURLArray:urlArray];
}

@end
