//
//  ACCSocialStickerEditToolbarItemView.m
//  CameraClient-Pods-Aweme
//
//  Created by qiuhang on 2020/8/11.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCSocialStickerEditToolbarItemView.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <Masonry/Masonry.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import "UIImage+ACCUIKit.h"

#define kSocialItemViewLoadingPlaceholderColor [[UIColor whiteColor] colorWithAlphaComponent:0.15]

static const CGFloat kMentionItemCellAvatarSize        = 40.f;
static const CGFloat kMentionItemCellAvatarBottomInset = 33.f;

@interface ACCSocialStickerEditToobarMentionItemCell ()

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *userNameLabel;
@property (nonatomic, strong) UIView  *loadingLabelFakeView;
@property (nonatomic, strong) UIView  *loadingImageFakeView;
@property (nonatomic, strong) UIImage *placeholderImage;

@end

@implementation ACCSocialStickerEditToobarMentionItemCell

#pragma mark - setter
- (void)configWithUser:(id<ACCUserModelProtocol>)userModel isSelected:(BOOL)isSelected {
    
    void (^resetUILoadingStatus)(BOOL) = ^(BOOL isLoading) {
        
        self.avatarImageView.hidden      = isLoading;
        self.userNameLabel.hidden        = isLoading;
        self.loadingLabelFakeView.hidden = !isLoading;
        self.loadingImageFakeView.hidden = !isLoading;
    };

    if (userModel) {
        
        resetUILoadingStatus(NO);
        
        if (!ACC_isEmptyArray(userModel.avatarThumb.URLList)) {
            [ACCWebImage() imageView:self.avatarImageView
                setImageWithURLArray:userModel.avatarThumb.URLList
                         placeholder:self.placeholderImage];
        } else {
            [ACCWebImage() cancelImageViewRequest:self.avatarImageView];
            self.avatarImageView.image = self.placeholderImage;
        }
        
        // PM : show nickname for list, use username for sticker
        self.userNameLabel.text = userModel.socialName ? : @"";

        if (isSelected) {
            UIColor *selectTintColor = ACCResourceColor(ACCUIColorConstPrimary);
            self.avatarImageView.layer.borderColor = selectTintColor.CGColor;
            self.avatarImageView.layer.borderWidth = 2.f;
            self.userNameLabel.textColor = selectTintColor;
        } else {
            self.avatarImageView.layer.borderColor = [UIColor clearColor].CGColor;
            self.avatarImageView.layer.borderWidth = 0.f;
            self.userNameLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
        }
        
    } else { /* loading status */
        resetUILoadingStatus(YES);
    }
}

#pragma mark - getter
+ (CGSize)sizeWithUser:(id<ACCUserModelProtocol>)userModel {
    return [self maxContentDisplaySize];
}

+ (CGSize)maxContentDisplaySize {
    return CGSizeMake(60.f, kMentionItemCellAvatarSize + kMentionItemCellAvatarBottomInset);
}

#pragma mark - setup
- (void)setup {
    
    [super setup];
    
    const CGFloat imageViewSize = 40.f;
    
    self.avatarImageView = ({

        UIImageView *imageView = [UIImageView new];
        [self.contentView addSubview:imageView];
        ACCMasMaker(imageView, {
            make.size.mas_equalTo(CGSizeMake(imageViewSize, imageViewSize));
            make.centerX.top.equalTo(self);
        });
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.layer.cornerRadius = imageViewSize / 2.f;
        imageView.layer.masksToBounds = YES;
        imageView;
    });
    
    self.loadingImageFakeView = ({
        
        UIView *view = [UIView new];
        [self.contentView addSubview:view];
        ACCMasMaker(view, {
            make.left.right.top.bottom.equalTo(self.avatarImageView);
        });
        view.backgroundColor = kSocialItemViewLoadingPlaceholderColor;
        view.layer.cornerRadius = imageViewSize / 2.f;
        view.layer.masksToBounds = YES;
        view;
    });
    
    self.userNameLabel = ({
        
        UILabel *label = [UILabel new];
        [self.contentView addSubview:label];
        ACCMasMaker(label, {
            make.left.right.equalTo(self);
            make.top.equalTo(self.avatarImageView.mas_bottom).inset(8.f);
        });
        label.font = [ACCFont() systemFontOfSize:11.f];
        label.textAlignment = NSTextAlignmentCenter;
        label;
    });
    
    self.loadingLabelFakeView = ({
        
        UIView *view = [UIView new];
        [self.contentView addSubview:view];
        ACCMasMaker(view, {
            make.left.right.equalTo(self).inset(3);
            make.top.equalTo(self.avatarImageView.mas_bottom).inset(8.f);
            make.height.mas_equalTo(12.f);
        });
        view.backgroundColor = kSocialItemViewLoadingPlaceholderColor;
        view.layer.cornerRadius = 2.f;
        view;
    });
}

- (UIImage *)placeholderImage {
    if (!_placeholderImage) {
        _placeholderImage = [UIImage acc_imageWithColor:kSocialItemViewLoadingPlaceholderColor size:CGSizeMake(1, 1)];
    }
    return _placeholderImage;
}

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return [self.userNameLabel.text stringByReplacingOccurrencesOfString:@"@" withString:@""];
}

@end

static const CGFloat kHashTagLabelHoriPadding   = 8.f;
static const CGFloat kHashTagContentHeight      = 36.f;
static const CGFloat kHashTagContentBottomInset = 12.f;

#define kHashTagLabelFont [ACCFont() systemFontOfSize:14.f weight:ACCFontWeightMedium]

@interface ACCSocialStickerEditToolbarHashTagItemCell ()

@property (nonatomic, strong) UIView  *bgView;
@property (nonatomic, strong) UILabel *hashTagLabel;
@property (nonatomic, strong) UIView  *loadingLabelFakeView;

@end
@implementation ACCSocialStickerEditToolbarHashTagItemCell: ACCSocialStickerEditToolbarBaseItemCell

#pragma mark - setter
- (void)configWithHashTag:(id<ACCChallengeModelProtocol>)hashTagModel {
    
    void (^resetUILoadingStatus)(BOOL) = ^(BOOL isLoading) {
        self.bgView.hidden       = isLoading;
        self.hashTagLabel.hidden = isLoading;
        self.loadingLabelFakeView.hidden = !isLoading;
    };
    
    if (hashTagModel) {
        resetUILoadingStatus(NO);
        self.hashTagLabel.text = [[self class] realDisplayHashTagStringWithModel:hashTagModel];
    } else {
        /* loading status */
        resetUILoadingStatus(YES);
    }
}

#pragma mark - getter
+ (CGSize)sizeWithHashTag:(id<ACCChallengeModelProtocol>)hashTagModel {
    
    if (!hashTagModel) {
        return [self maxContentDisplaySize];
    }
    
    NSString *realDisplayHashTagString = [self realDisplayHashTagStringWithModel:hashTagModel];
    
    CGFloat width = 2 * kHashTagLabelHoriPadding + [realDisplayHashTagString acc_widthWithFont:kHashTagLabelFont height:kHashTagLabelFont.lineHeight];
    width = ceilf(width);
    return CGSizeMake(width, [self maxContentDisplaySize].height);
}

+ (CGSize)maxContentDisplaySize {
    return CGSizeMake(93.f, kHashTagContentHeight + kHashTagContentBottomInset);
}

+ (NSString *)realDisplayHashTagStringWithModel:(id<ACCChallengeModelProtocol>)hashTagModel {
    return [NSString stringWithFormat:@"# %@", hashTagModel.challengeName];
}

#pragma mark - setup
- (void)setup {
    
    [super setup];
    
    self.clipsToBounds = YES;
    
    const CGFloat cornerRadius = 4.f;
    
    self.bgView = ({
        
        UIView *view = [UIView new];
        [self.contentView addSubview:view];
        ACCMasUpdate(view, {
            make.left.right.top.equalTo(self);
            make.height.mas_equalTo (kHashTagContentHeight);
        });
        view.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.15];
        view.layer.cornerRadius = cornerRadius;
        view.clipsToBounds = YES;
        view;
    });
    
    self.hashTagLabel = ({
        
        UILabel *label = [UILabel new];
        [self.contentView addSubview:label];
        ACCMasMaker(label, {
            make.center.equalTo(self.bgView);
        });
        label.font = kHashTagLabelFont;
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        label;
    });
    
    self.loadingLabelFakeView = ({
        
        UIView *view = [UIView new];
        [self.contentView addSubview:view];
        ACCMasMaker(view, {
            make.edges.equalTo(self.bgView);
        });
        view.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.15];
        view.layer.cornerRadius = cornerRadius;
        view;
    });
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    self.bgView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:highlighted?0.34f:0.15f];
}

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return [self.hashTagLabel.text stringByReplacingOccurrencesOfString:@"#" withString:@""];
}

@end


@implementation ACCSocialStickerEditToolbarBaseItemCell: UICollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

+ (CGSize)maxContentDisplaySize {
    return CGSizeZero;
}

- (void)setup {
    self.contentView.backgroundColor = [UIColor clearColor];
}

@end
