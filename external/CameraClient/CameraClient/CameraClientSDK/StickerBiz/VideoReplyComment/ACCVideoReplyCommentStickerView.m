//  视频回复评论二期链路优化
//  ACCVideoReplyCommentStickerView.m
//  CameraClient-Pods-Aweme
//
//  Created by lixuan on 2021/9/30.
//

#import "ACCVideoReplyCommentStickerView.h"
#import "AWEInteractionVideoReplyCommentStickerModel.h"
#import "ACCIMModuleServiceProtocol.h"

#import <AWEBaseModel/AWEURLModel.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitArch/ACCAwemeModelProtocol.h>
#import <CreativeKitSticker/ACCStickerUtils.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreativeKit/ACCResourceBundleProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/ACCColorNameDefines.h>
#import <CreativeKit/UIColor+ACC.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <YYText/YYLabel.h>
#import <YYText/NSAttributedString+YYText.h>

static const CGFloat kCoverRatio = 116.f/110.f;
static const CGFloat kStickerViewWidth = 110.f;
static const CGFloat kCommentTopSpace = 29.f;
static const CGFloat kAvatarWidth = 16.f;
static const CGFloat kCommentLineHeight = 17.f;
static const CGFloat kCommentLeftSpace = 6.f;
static const CGFloat kCommentRightSpace = 4.f;
static const CGFloat kCommentHorizontalSpacing = 4.f;
static const CGFloat kCommentLabelWidth = kStickerViewWidth - kCommentLeftSpace - kCommentRightSpace;

@interface ACCVideoReplyCommentStickerView ()

@property (nonatomic, strong, readwrite) ACCVideoReplyCommentModel *videoReplyCommentModel;

// UI
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UIButton *videoIconButton;

@property (nonatomic, strong) UIView *commentBgView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIStackView *commentStackView;
@property (nonatomic, strong) YYLabel *commentLabel;
// 表情回复
@property (nonatomic, strong) UILabel *emojiLabel;

@end

@implementation ACCVideoReplyCommentStickerView

@synthesize stickerContainer, coordinateDidChange;
@synthesize stickerId = _stickerId;
@synthesize transparent = _transparent;

- (instancetype)initWithModel:(ACCVideoReplyCommentModel *)model
{
    CGSize frameSize = [ACCVideoReplyCommentStickerView frameSizeWithModel:model];
    self = [super initWithFrame:CGRectMake(0, 0, frameSize.width, frameSize.height)];
    if (self) {
        _videoReplyCommentModel = [model copy];
        [self _setupUI];
        [self _refreshWithReplyModel:model];
        [self _setAccessibilityElement];
    }
    return self;
}

// 消费端绘制贴纸UI
- (instancetype)initWithStickerModel:(AWEInteractionStickerModel *)model
{
    if (![model isKindOfClass:[AWEInteractionVideoReplyCommentStickerModel class]]) {
        return nil;
    }
    
    ACCVideoReplyCommentModel *videoReplyCommentModel = ((AWEInteractionVideoReplyCommentStickerModel *)model).videoReplyCommentInfo;
    
    if (videoReplyCommentModel == nil) {
        return  nil;
    }
    
    self = [self initWithModel:videoReplyCommentModel];
    return self;
}

#pragma mark - Public

+ (CGSize)frameSizeWithModel:(ACCVideoReplyCommentModel *)model
{
    CGFloat width = kStickerViewWidth;
    
    // cover image
    CGFloat coverHeight = width * kCoverRatio;
    
    // comment area
    CGFloat commentHeight = 0.f;
    CGFloat commentBottomSpace = 12.f;
    
    // has emoji
    if (model.commentSticker.URLList.count > 0) {
        if (model.commentText.length > 0) {
            commentHeight = kCommentLineHeight;
            commentHeight += kCommentHorizontalSpacing;
        }
        commentHeight += kCommentLineHeight;
        commentHeight += commentBottomSpace;
    } else {
        commentHeight = [[self class] _commentLabelLayoutWithString:model.commentText maxNumberOfLines:2].textBoundingSize.height;
        commentHeight += commentBottomSpace;
    }
    
    // total height
    CGFloat height = coverHeight + kCommentTopSpace + commentHeight;
    return CGSizeMake(width, height);
}

#pragma mark - UI

- (void)_setupUI
{
    self.backgroundColor = [UIColor clearColor];
    [self addSubview:self.coverImageView];
    ACCMasMaker(self.coverImageView, {
        make.left.right.top.equalTo(self);
        make.height.equalTo(self.coverImageView.mas_width).multipliedBy(kCoverRatio);
    });
    
    [self addSubview:self.videoIconButton];
    ACCMasMaker(self.videoIconButton, {
        make.left.equalTo(self).mas_offset(10.f);
        make.top.equalTo(self).mas_offset(8.f);
        make.size.mas_equalTo(CGSizeMake(46.f, 16.f));
    });
    
    [self addSubview:self.commentBgView];
    ACCMasMaker(self.commentBgView, {
        make.top.equalTo(self.coverImageView.mas_bottom);
        make.left.right.bottom.equalTo(self);
    });
    
    [self.commentBgView addSubview:self.avatarImageView];
    ACCMasMaker(self.avatarImageView, {
        make.top.equalTo(self.commentBgView).mas_offset(8.f);
        make.left.equalTo(self.commentBgView).mas_offset(6.f);
        make.size.mas_equalTo(CGSizeMake(kAvatarWidth, kAvatarWidth));
    });
    
    [self.commentBgView addSubview:self.nameLabel];
    ACCMasMaker(self.nameLabel, {
        make.centerY.equalTo(self.avatarImageView);
        make.left.equalTo(self.avatarImageView.mas_right).mas_offset(4.f);
        make.right.equalTo(self.commentBgView);
        make.height.mas_equalTo(17.f);
    });
    
    [self.commentBgView addSubview:self.commentStackView];
    ACCMasMaker(self.commentStackView, {
        make.left.equalTo(self.commentBgView).mas_offset(kCommentLeftSpace);
        make.right.equalTo(self.commentBgView).mas_offset(-kCommentRightSpace);
        make.top.equalTo(self.commentBgView).mas_offset(kCommentTopSpace);
    });
    
    [self.commentStackView addArrangedSubview:self.commentLabel];
    [self.commentStackView addArrangedSubview:self.emojiLabel];
    ACCMasMaker(self.emojiLabel, {
        make.height.mas_equalTo(kCommentLineHeight);
    });
}

- (void)_refreshWithReplyModel:(ACCVideoReplyCommentModel *)model
{
    // cover image
    [ACCWebImage() imageView:self.coverImageView
        setImageWithURLArray:[model.coverModel URLList]
                 placeholder:ACCResourceImage(@"bg_video_reply_comment_sticker_loading")
                     options:ACCWebImageOptionsIgnoreAnimatedImage | ACCWebImageOptionsSetImageWithFadeAnimation
                  completion:^(UIImage *image, NSURL *url, NSError *error) {
        if (error) {
            AWELogToolError2(@"video_reply_comment_sticker", AWELogToolTagRecord | AWELogToolTagEdit, @"ACCVideoReplyCommentStickerView downloading cover image failed: %@",error);
        }
    }];
    
    // avatar
    [ACCWebImage() imageView:self.avatarImageView
        setImageWithURLArray:[model.commentAuthorAvatar URLList]
                 placeholder:nil
                     options:ACCWebImageOptionsIgnoreAnimatedImage | ACCWebImageOptionsSetImageWithFadeAnimation
                  completion:^(UIImage *image, NSURL *url, NSError *error) {
        if (error || !image) {
            self.avatarImageView.image = ACCResourceImage(@"ic_video_reply_comment_sticker_avatar_failed_black");
        }
        if (error) {
            AWELogToolError2(@"video_reply_comment_sticker", AWELogToolTagRecord | AWELogToolTagEdit, @"ACCVideoReplyCommentStickerView downloading avatar image failed: %@",error);
        }
    }];
    
    // name label
    if ([ACCVideoReplyCommentStickerView _nameWidthWithName:model.commentAuthorNickname] > 34.f) {
        self.nameLabel.text = [NSString stringWithFormat:@"%@...的评论", model.commentAuthorNickname.length > 2 ? [model.commentAuthorNickname substringToIndex:2] : model.commentAuthorNickname];
    } else {
        self.nameLabel.text = [NSString stringWithFormat:@"%@的评论", model.commentAuthorNickname];
    }
    // comment label
    self.commentLabel.attributedText = [[self class] _commentAttributedTextWithString:model.commentText];
    self.commentLabel.hidden = model.commentText.length == 0;
    self.commentLabel.textLayout = [[self class] _commentLabelLayoutWithString:model.commentText maxNumberOfLines:model.commentSticker.URLList.count == 0 ? 2 : 1];
    // emoji label hidden
    self.emojiLabel.hidden = model.commentSticker.URLList.count == 0;
}

#pragma mark - Private

+ (YYTextLayout *)_commentLabelLayoutWithString:(NSString *)string maxNumberOfLines:(NSInteger)maxNumberOfLines
{
    CGSize size = CGSizeMake(kCommentLabelWidth, CGFLOAT_MAX);
    YYTextContainer *container = [YYTextContainer containerWithSize:size];
    container.maximumNumberOfRows = maxNumberOfLines;
    container.truncationType = YYTextTruncationTypeEnd;
    return [YYTextLayout layoutWithContainer:container text:[self _commentAttributedTextWithString:string]];
}

+ (NSAttributedString *)_commentAttributedTextWithString:(NSString *)string
{
    UIFont *font = [ACCFont() acc_systemFontOfSize:12.f weight:ACCFontWeightMedium];
    NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc] initWithString:string ?: @""];
    [IESAutoInline(ACCBaseServiceProvider(), ACCIMModuleServiceProtocol) replaceEmotionIconTextInAttributedString:attributedStr font:font emojiSize:CGSizeMake(10.f, 10.f)];
    attributedStr.yy_color = [UIColor whiteColor];
    attributedStr.yy_font = font;
    attributedStr.yy_lineSpacing = 4.f;
    return attributedStr.copy;
}

- (void)_setupMaskLayer
{
    [self acc_setupBorderWithTopLeftRadius:CGSizeMake(12.f, 12.f)
                            topRightRadius:CGSizeMake(12.f, 12.f)
                          bottomLeftRadius:CGSizeMake(12.f, 12.f)
                         bottomRightRadius:CGSizeMake(2.f, 2.f)];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // refresh mask
    [self _setupMaskLayer];
}

+ (CGFloat)_nameWidthWithName:(NSString *)name
{
    UILabel *sizeLabel = [[UILabel alloc] init];
    sizeLabel.font = [ACCFont() acc_systemFontOfSize:12.f weight:ACCFontWeightMedium];
    sizeLabel.text = name;
    CGSize nameSize = [sizeLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    return nameSize.width;
}

#pragma mark - AccessibilityElement

- (void) _setAccessibilityElement
{
    self.isAccessibilityElement = YES;
    self.accessibilityLabel = [NSString stringWithFormat:@"视频回复的评论内容：%@", self.videoReplyCommentModel.commentText];
    self.accessibilityTraits = UIAccessibilityTraitNone;
}

#pragma mark - ACCStickerCopyingProtocol

- (instancetype)copyForContext:(id)contextId
{
    ACCVideoReplyCommentStickerView *copyView = [[ACCVideoReplyCommentStickerView alloc] initWithModel:self.videoReplyCommentModel];
    
    return copyView;
}

#pragma mark - Properties

- (UIImageView *)coverImageView
{
    if (!_coverImageView) {
        _coverImageView = [[UIImageView alloc] init];
        _coverImageView.backgroundColor = [UIColor clearColor];
        _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        _coverImageView.layer.masksToBounds = YES;
    }
    return _coverImageView;
}

- (UIButton *)videoIconButton
{
    if (!_videoIconButton) {
        _videoIconButton = [[UIButton alloc] init];
        _videoIconButton.enabled = NO;
        _videoIconButton.layer.cornerRadius = 2.f;
        _videoIconButton.backgroundColor = [UIColor acc_colorWithHex:@"#292929" alpha:0.34];
        [_videoIconButton setImage:ACCResourceImage(@"ic_video_comment_sticker_video") forState:UIControlStateDisabled];
        [_videoIconButton setTitle:@"原视频" forState:UIControlStateDisabled];
        [_videoIconButton setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
        _videoIconButton.titleLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
        _videoIconButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    }
    return _videoIconButton;
}

- (UIView *)commentBgView
{
    if (!_commentBgView) {
        _commentBgView = [[UIView alloc] init];
        _commentBgView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    }
    return _commentBgView;
}

- (UIImageView *)avatarImageView
{
    if (!_avatarImageView) {
        _avatarImageView = [[UIImageView alloc] init];
        _avatarImageView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.06];
        _avatarImageView.layer.cornerRadius = kAvatarWidth / 2.f;
        _avatarImageView.layer.borderWidth = 0.5;
        _avatarImageView.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.08].CGColor;
        _avatarImageView.layer.masksToBounds = YES;
    }
    return _avatarImageView;
}

- (UILabel *)nameLabel
{
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [ACCFont() acc_systemFontOfSize:12.f weight:ACCFontWeightMedium];
        _nameLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.75];
        _nameLabel.textAlignment = NSTextAlignmentLeft;
        _nameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    return _nameLabel;
}

- (YYLabel *)commentLabel
{
    if (!_commentLabel) {
        _commentLabel = [[YYLabel alloc] init];
        _commentLabel.displaysAsynchronously = NO;
        _commentLabel.preferredMaxLayoutWidth = kCommentLabelWidth;
    }
    return _commentLabel;
}

- (UILabel *)emojiLabel
{
    if (!_emojiLabel) {
        _emojiLabel = [[UILabel alloc] init];
        _emojiLabel.font = [ACCFont() acc_systemFontOfSize:12.f weight:ACCFontWeightMedium];
        _emojiLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.75];
        _emojiLabel.text = @" [表情]";
    }
    return _emojiLabel;
}

- (UIStackView *)commentStackView
{
    if (!_commentStackView) {
        _commentStackView = [[UIStackView alloc] init];
        _commentStackView.spacing = kCommentHorizontalSpacing;
        _commentStackView.axis = UILayoutConstraintAxisVertical;
        _commentStackView.alignment = UIStackViewAlignmentLeading;
        _commentStackView.distribution = UIStackViewDistributionFill;
    }
    return _commentStackView;
}

@end
