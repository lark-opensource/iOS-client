//
//  ACCRecognitionCategoryCell.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/18.
//

#import "ACCRecognitionSpeciesCell.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <SmartScan/SSRecognizeResult.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CameraClient/UIImage+ACCUIKit.h>

@interface ACCRecognitionSpeciesCell ()

@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIImage *placeholderImage;
@property (nonatomic, strong) UILabel *speciesNameLabel;
@property (nonatomic, strong) UILabel *categoryNameLabel;
@property (nonatomic, strong) UILabel *aliasNameLabel;
@property (nonatomic, strong) UILabel *similarityLabel;
@property (nonatomic, strong) UIImageView *tagImageView;

@end

@implementation ACCRecognitionSpeciesCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return  self;
}

#pragma mark - Public Methods
- (void)configWithData:(SSRecognizeResult *)data at:(NSInteger)index
{
    if (!ACC_isEmptyArray(data.imageLinks)) {
        [ACCWebImage() imageView:self.tagImageView
            setImageWithURLArray:[data.imageLinks copy]
                     placeholder:self.placeholderImage];
    } else {
        NSDictionary *configDict = ACCConfigDict(kConfigString_dynamic_groot_placeholder_image_url);
        NSArray *placeholdersArray = [configDict acc_arrayValueForKey:@"species_placeholder" defaultValue:@[]];
        [ACCWebImage() cancelImageViewRequest:self.tagImageView];
        [ACCWebImage() imageView:self.tagImageView setImageWithURLArray:placeholdersArray placeholder:self.placeholderImage];
    }
    
    self.speciesNameLabel.text = data.chnName ? : @"";
    NSString *categoryName = data.clsSys;
    if (!ACC_isEmptyString(categoryName)) {
        self.categoryNameLabel.hidden = NO;
        self.categoryNameLabel.text = categoryName;
        CGRect categoryNameRect = [categoryName boundingRectWithSize:CGSizeMake(200, 20) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [ACCFont() systemFontOfSize:12 weight:ACCFontWeightRegular]} context:nil];
        ACCMasUpdate(self.categoryNameLabel, {
            make.width.mas_equalTo(categoryNameRect.size.width + 8);
            make.right.lessThanOrEqualTo(self.contentView.mas_right).priorityHigh();
        });
    } else {
        self.categoryNameLabel.hidden = YES;
    }
    
    NSString *aliasName = data.aliasName;
    if (!ACC_isEmptyString(aliasName)) {
        self.aliasNameLabel.hidden = NO;
        self.aliasNameLabel.text = aliasName;
        CGRect aliasNameLabelRect = [aliasName boundingRectWithSize:CGSizeMake(200, 20) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [ACCFont() systemFontOfSize:12 weight:ACCFontWeightRegular]} context:nil];
        ACCMasUpdate(self.aliasNameLabel, {
            make.width.mas_equalTo(aliasNameLabelRect.size.width + 8);
            make.right.lessThanOrEqualTo(self.contentView.mas_right).priorityHigh();
        });
    } else {
        self.aliasNameLabel.hidden = YES;
    }

    if (data.score > 0) {
        self.similarityLabel.hidden = NO;
        double similarity = data.score * 100;
        NSString *similarityString = [NSString stringWithFormat:@"相似度 %.1f%%", similarity];
        self.similarityLabel.text = similarityString;
    } else {
        self.similarityLabel.hidden = YES;
    }
}

#pragma mark - Private Methods

- (void)setupUI
{
    self.contentView.userInteractionEnabled = YES;
    self.contentView.layer.cornerRadius = 12.f;
    self.contentView.layer.masksToBounds = YES;
    self.contentView.backgroundColor = [UIColor whiteColor];
    
    self.tagImageView = ({
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.layer.cornerRadius = 8.f;
        imageView.layer.masksToBounds = YES;
        [self.contentView addSubview:imageView];
        ACCMasMaker(imageView, {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(3, 3, 3, 3));
        });
        imageView;
    });
        
    self.gradientLayer = ({
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.colors = @[
        (__bridge id)[UIColor blackColor].CGColor,
        (__bridge id)[UIColor clearColor].CGColor];
        gradientLayer.startPoint = CGPointMake(0, 1);
        gradientLayer.endPoint = CGPointMake(0, 0);
        [self.tagImageView.layer addSublayer:gradientLayer];
        gradientLayer;
    });
    
    self.speciesNameLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.font = [ACCFont() systemFontOfSize:17 weight:ACCFontWeightMedium];
        label.adjustsFontSizeToFitWidth = YES;
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
        [self.contentView addSubview:label];
        ACCMasMaker(label, {
            make.left.equalTo(@17.5);
            make.right.equalTo(self.contentView.mas_right).inset(17.5);
            make.height.equalTo(@24);
            make.bottom.equalTo(self.contentView.mas_bottom).inset(58);
        });
        label;
    });
    
    self.categoryNameLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.font = [ACCFont() systemFontOfSize:12 weight:ACCFontWeightRegular];
        label.adjustsFontSizeToFitWidth = YES;
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
        label.layer.cornerRadius = 3.0f;
        label.layer.masksToBounds = YES;
        [label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        label.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
        [self.contentView addSubview:label];
        ACCMasMaker(label, {
            make.left.equalTo(@17.5);
            make.height.equalTo(@20);
            make.top.equalTo(self.speciesNameLabel.mas_bottom).offset(2);
        });
        label;
    });
    
    self.aliasNameLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.adjustsFontSizeToFitWidth = YES;
        label.font = [ACCFont() systemFontOfSize:12 weight:ACCFontWeightRegular];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
        label.layer.cornerRadius = 3.0f;
        label.layer.masksToBounds = YES;
        label.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
        [self.contentView addSubview:label];
        ACCMasMaker(label, {
            make.left.equalTo(self.categoryNameLabel.mas_right).offset(4);
            make.height.equalTo(@20);
            make.top.equalTo(self.speciesNameLabel.mas_bottom).offset(2);
        });
        label;
    });
    
    self.similarityLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.font = [ACCFont() systemFontOfSize:12 weight:ACCFontWeightRegular];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [ACCResourceColor(ACCUIColorConstTextInverse) colorWithAlphaComponent:0.5];
        [self.contentView addSubview:label];
        ACCMasMaker(label, {
            make.left.equalTo(@17.5);
            make.right.equalTo(self.contentView).inset(5);
            make.height.equalTo(@14);
            make.top.equalTo(self.speciesNameLabel.mas_bottom).offset(25);
        });
        label;
    });
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.contentView.acc_height >= 151) {
        self.gradientLayer.frame = CGRectMake(0,
                                              self.contentView.acc_height - 151,
                                              self.contentView.acc_width, 150);
    } else {
        self.gradientLayer.frame = CGRectZero;
    }
}

#pragma mark - Getter

- (UIImage *)placeholderImage
{
    if (!_placeholderImage) {
        _placeholderImage = [UIImage acc_imageWithColor:[[UIColor blackColor] colorWithAlphaComponent:0.15] size:CGSizeMake(1, 1)];
    }
    return _placeholderImage;
}

#pragma mark - Setter
- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if (selected) {
        self.contentView.layer.borderWidth = 2.0;
        self.contentView.layer.borderColor = ACCResourceColor(ACCColorPrimary).CGColor;
    } else {
        self.contentView.layer.borderWidth = 0;
        self.contentView.layer.borderColor = [UIColor clearColor].CGColor;
    }
}

@end
