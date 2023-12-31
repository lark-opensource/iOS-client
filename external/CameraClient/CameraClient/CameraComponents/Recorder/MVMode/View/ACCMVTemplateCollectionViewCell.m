//
//  ACCMVTemplateCollectionViewCell.m
//  CameraClient
//
//  Created by long.chen on 2020/3/2.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCMVTemplateCollectionViewCell.h"
#import <CreationKitArch/ACCMVTemplateModelProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "ACCMvAmountView.h"

#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

@interface ACCMVTemplateCollectionViewCell ()

@property (nonatomic, strong) id<ACCMVTemplateModelProtocol> templateModel;

@property (nonatomic, strong) ACCMvAmountView *amountView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;

@end

@implementation ACCMVTemplateCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI
{
    self.contentView.layer.cornerRadius = 2;
    self.contentView.layer.masksToBounds = YES;
    self.contentView.backgroundColor = ACCResourceColor(ACCColorLineSecondary);
    
    [self.contentView addSubview:self.coverImageView];
    ACCMasMaker(self.coverImageView, {
        make.left.top.right.equalTo(self.contentView);
    });
    
    [self.contentView addSubview:self.amountView];
    ACCMasMaker(self.amountView, {
        make.left.equalTo(self.coverImageView).offset(8);
        make.bottom.equalTo(self.coverImageView).offset(-8);
    });
    
    [self.contentView addSubview:self.titleLabel];
    ACCMasMaker(self.titleLabel, {
        make.top.equalTo(self.coverImageView.mas_bottom).offset(8);
        make.left.equalTo(self.contentView).offset(8);
        make.right.equalTo(self.contentView).offset(-8);
    });
    
    [self.contentView addSubview:self.descLabel];
    ACCMasMaker(self.descLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(4);
        make.left.right.equalTo(self.titleLabel);
    });
}

+ (CGFloat)p_coverImageRatioWithTemplateModel:(id<ACCMVTemplateModelProtocol>)templateModel;
{
    if (templateModel.video.width.integerValue == 0 || templateModel.video.height.integerValue == 0) {
        return 16.f / 9.f;
    }
    CGFloat ratio = templateModel.video.height.floatValue / templateModel.video.width.floatValue; 
    ratio = MIN(16.f / 9.f, MAX(ratio, 9.f / 16.f));
    return ratio;
}

#pragma mark - Public

+ (NSString *)cellIdentifier
{
    return NSStringFromClass(self.class);
}

+ (CGFloat)cellHeightForModel:(id<ACCMVTemplateModelProtocol>)templateModel withWidth:(CGFloat)width
{
    CGFloat coverHeight = [self p_coverImageRatioWithTemplateModel:templateModel] * width;
    CGFloat titleHeight = [templateModel.title boundingRectWithSize:CGSizeMake(width - 16, 54)
                                                            options:NSStringDrawingUsesLineFragmentOrigin
                                                         attributes:@{
                                                             NSFontAttributeName : [ACCFont() acc_systemFontOfSize:13],
                                                         } context:nil].size.height;
    return coverHeight + titleHeight + 41;
}

- (void)updateWithTemplateModel:(id<ACCMVTemplateModelProtocol>)templateModel
{
    self.templateModel = templateModel;
    
    CGFloat imageViewHeight = self.contentView.acc_width * [self.class p_coverImageRatioWithTemplateModel:self.templateModel];
    ACCMasUpdate(self.coverImageView, {
        make.height.equalTo(@(imageViewHeight));
    });
    
    if (templateModel.usageAmount > 0) {
        self.amountView.hidden = NO;
        self.amountView.text = [ACCMvAmountView usageAmountString:templateModel.usageAmount];
    } else {
        self.amountView.hidden = YES;
    }

    [ACCWebImage() imageView:self.coverImageView setImageWithURLArray:templateModel.templateDynamicCoverURL.count > 0 ? templateModel.templateDynamicCoverURL : templateModel.templateCoverURL];
    self.titleLabel.text = templateModel.title;
    self.descLabel.text = templateModel.hintLabel;
}

#pragma mark - Getters

- (UIImageView *)coverImageView
{
    if (!_coverImageView) {
        _coverImageView = [ACCWebImage() animatedImageView];
        _coverImageView.backgroundColor = ACCResourceColor(ACCColorBGInput2);
        _coverImageView.clipsToBounds = YES;
        _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _coverImageView;
}

- (ACCMvAmountView *)amountView
{
    if (!_amountView) {
        _amountView = [[ACCMvAmountView alloc] initWithFrame:CGRectZero];
    }
    return _amountView;
}


- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.numberOfLines = 3;
        _titleLabel.font = [ACCFont() acc_systemFontOfSize:15 weight:ACCFontWeightMedium];
        _titleLabel.textColor = ACCResourceColor(ACCColorConstTextInverse2);
    }
    return _titleLabel;
}

- (UILabel *)descLabel
{
    if (!_descLabel) {
        _descLabel = [[UILabel alloc] init];
        _descLabel.font = [ACCFont() acc_systemFontOfSize:12];
        _descLabel.textColor = ACCResourceColor(ACCColorConstTextInverse4);
    }
    return _descLabel;
}

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    if (!self.templateModel) {
        return @"";
    }

    if (self.templateModel.usageAmount > 0) {
        NSString *amountViewDescription = [ACCMvAmountView usageAmountString:self.templateModel.usageAmount];
        return [NSString stringWithFormat:@"%@,%@,%@", amountViewDescription, self.templateModel.title, self.templateModel.hintLabel];
    }

    return [NSString stringWithFormat:@"%@,%@", self.templateModel.title, self.templateModel.hintLabel];
}


@end
