//
//  ACCVideoReplyCommentWithoutCoverStickerView.m
//  Indexer
//
//  Created by bytedance on 2021/10/8.
//

#import "ACCVideoReplyCommentWithoutCoverStickerView.h"
#import "AWEInteractionVideoReplyCommentStickerModel.h"
#import "ACCIMModuleServiceProtocol.h"

#import <AWEBaseModel/AWEURLModel.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/UIColor+ACC.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <YYText/YYLabel.h>
#import <YYText/NSAttributedString+YYText.h>

static const CGFloat kStickerViewWidth = 175.f;
static const CGFloat kAvatarWidth = 16.f;
static const CGFloat kVideoBgViewHeight = 24.f;
static const CGFloat kCommentTopSpace = 37.f;
static const CGFloat kCommentLeftSpace = 12.f;
static const CGFloat kCommentRightSpace = 19.f;
static const CGFloat kCommentSpace = 4.f;
static const CGFloat kCommentAndVideoBGSpace = 8.f;
static const CGFloat kVideoBGBottomSpace = 12.f;
static const CGFloat kVideoBGMinRightSpace = 12.f;
static const CGFloat kCommentLabelWidth = kStickerViewWidth - kCommentLeftSpace - kCommentRightSpace;

@interface ACCVideoReplyCommentWithoutCoverStickerView()

@property (nonatomic, strong) UIVisualEffectView *bgBlurView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIStackView *commentStackView;
@property (nonatomic, strong) YYLabel *commentLabel;
@property (nonatomic, strong) UIImageView *emojiImageView;
@property (nonatomic, strong) UIImageView *arrowImageview;

@property (nonatomic, strong) UIView *videoBgView;
@property (nonatomic, strong) UILabel *videoTipLabel;
@property (nonatomic, strong) UIImageView *videoArrowImageView;
@property (nonatomic, strong) UILabel *videoTitleLabel;

@property (nonatomic, assign) CGFloat videoBgViewRightOffset;

@end
@implementation ACCVideoReplyCommentWithoutCoverStickerView

@synthesize stickerContainer, coordinateDidChange;
@synthesize stickerId = _stickerId;
@synthesize transparent = _transparent;

- (instancetype)initWithModel:(ACCVideoReplyCommentModel *)model
{
    CGSize frameSize = [ACCVideoReplyCommentWithoutCoverStickerView frameSizeWithModel:model];
    self = [super initWithFrame:CGRectMake(0, 0, frameSize.width, frameSize.height)];
    if (self) {
        _videoReplyCommentModel = [model copy];
        [self _setupVideoBgViewWidth];
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
    CGFloat commentHeight = 0;
    
    if (model.commentText.length > 0) {
        commentHeight += [self _commentLabelLayoutWithString:model.commentText].textBoundingSize.height;
    }
    
    if (model.commentText.length > 0 && model.commentSticker.URLList.count > 0) {
        commentHeight += kCommentSpace;
    }
    
    if (model.commentSticker.URLList.count > 0) {
        commentHeight += 64.f;
    }
    
    commentHeight += kCommentTopSpace;
    commentHeight += kCommentAndVideoBGSpace;
    commentHeight += kVideoBgViewHeight;
    commentHeight += kVideoBGBottomSpace;
    
    return CGSizeMake(kStickerViewWidth, commentHeight);
}

#pragma mark - UI

- (void)_setupVideoBgViewWidth
{
    // “来自原视频”部分的长度与视频标题长度有关
    CGFloat videoBgViewMaxWidth = 151.f;
    CGFloat videoArrowWidth = 12.f;
    CGFloat labelTotalWidth = 0;
    UILabel *sizeTitleLabel = [[UILabel alloc] init];
    UILabel *sizeTipLabel = [[UILabel alloc] init];
    
    sizeTitleLabel.font = [ACCFont() acc_systemFontOfSize:11.f];
    sizeTitleLabel.text = self.videoReplyCommentModel.awemeTitle;
    CGSize titleSize = [sizeTitleLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    sizeTipLabel.font = [ACCFont() acc_systemFontOfSize:11.f];
    sizeTipLabel.text = @"来自原视频";
    CGSize tipSize = [sizeTipLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    
    // 计算视频标题完全展示的BgView的宽度
    labelTotalWidth += (8.f + 4.f + 8.f);
    labelTotalWidth += (tipSize.width + videoArrowWidth + titleSize.width);
    
    self.videoBgViewRightOffset = kVideoBGMinRightSpace + videoBgViewMaxWidth - MIN(videoBgViewMaxWidth, labelTotalWidth);
}

- (void)_setupUI
{
    self.backgroundColor = [UIColor clearColor];
    
    [self addSubview:self.bgBlurView];
    ACCMasMaker(self.bgBlurView, {
        make.edges.equalTo(self);
    });
    
    [self addSubview:self.avatarImageView];
    ACCMasMaker(self.avatarImageView, {
        make.left.equalTo(self).mas_offset(12.f);
        make.top.equalTo(self).mas_offset(12.f);
        make.width.height.mas_equalTo(kAvatarWidth);
    });
    
    [self addSubview:self.nameLabel];
    ACCMasMaker(self.nameLabel, {
        make.left.equalTo(self.avatarImageView.mas_right).offset(4.f);
        make.right.equalTo(self).offset(-4.f);
        make.centerY.equalTo(self.avatarImageView);
    });
    
    [self addSubview:self.commentStackView];
    ACCMasMaker(self.commentStackView, {
        make.top.equalTo(self).mas_offset(kCommentTopSpace);
        make.left.equalTo(self).mas_offset(kCommentLeftSpace);
        make.right.equalTo(self).mas_offset(-kCommentRightSpace);
    });
    
    [self.commentStackView addArrangedSubview:self.commentLabel];
    ACCMasMaker(self.commentLabel, {
        make.width.equalTo(self.commentStackView);
    });
    [self.commentStackView addArrangedSubview:self.emojiImageView];
    ACCMasMaker(self.emojiImageView, {
        make.width.height.mas_equalTo(64.f);
    });
    
    [self addSubview:self.arrowImageview];
    ACCMasMaker(self.arrowImageview, {
        make.left.equalTo(self.commentStackView.mas_right).offset(1.f);
        make.centerY.equalTo(self.commentStackView);
    });
    
    [self addSubview:self.videoBgView];
    ACCMasMaker(self.videoBgView, {
        make.height.mas_equalTo(kVideoBgViewHeight);
        make.left.equalTo(self).offset(12.f);
        make.bottom.equalTo(self).offset(-12.f);
        make.right.equalTo(self).offset(-self.videoBgViewRightOffset);
    });
    
    [self.videoBgView addSubview:self.videoTipLabel];
    ACCMasMaker(self.videoTipLabel, {
        make.left.equalTo(self.videoBgView).offset(8.f);
        make.centerY.equalTo(self.videoBgView);
    });
    
    [self.videoBgView addSubview:self.videoArrowImageView];
    ACCMasMaker(self.videoArrowImageView, {
        make.left.equalTo(self.videoTipLabel.mas_right).offset(4.f);
        make.centerY.equalTo(self.videoTipLabel);
    });
    
    [self.videoBgView addSubview:self.videoTitleLabel];
    ACCMasMaker(self.videoTitleLabel, {
        make.left.equalTo(self.videoArrowImageView.mas_right);
        make.right.equalTo(self.videoBgView).offset(-8.f);
        make.centerY.equalTo(self.videoBgView);
    });
}

- (void)_refreshWithReplyModel:(ACCVideoReplyCommentModel *)model
{
    // avatar
    [ACCWebImage() imageView:self.avatarImageView
        setImageWithURLArray:[model.commentAuthorAvatar URLList]
                 placeholder:nil
                     options:ACCWebImageOptionsIgnoreAnimatedImage | ACCWebImageOptionsSetImageWithFadeAnimation
                  completion:^(UIImage *image, NSURL *url, NSError *error) {
        if (error || !image) {
            self.avatarImageView.image = ACCResourceImage(@"ic_video_reply_comment_sticker_avatar_failed_white");
        }
        if (error) {
            AWELogToolError2(@"video_reply_comment_sticker", AWELogToolTagRecord | AWELogToolTagEdit, @"ACCVideoReplyCommentWithoutCoverStickerView downloading avatar image failed: %@",error);
        }
    }];
    
    self.nameLabel.text = [NSString stringWithFormat:@"%@ 的评论：", model.commentAuthorNickname];
    self.commentLabel.attributedText = [[self class] _commentAttributedTextWithString:model.commentText];
    self.commentLabel.hidden = model.commentText.length == 0;
    self.commentLabel.textLayout = [[self class] _commentLabelLayoutWithString:model.commentText];
    
    self.emojiImageView.hidden = model.commentSticker.URLList.count == 0;
    if (model.commentSticker.URLList.count > 0) {
        [ACCWebImage() imageView:self.emojiImageView
            setImageWithURLArray:[model.commentSticker URLList]
                     placeholder:nil
                         options:ACCWebImageOptionsSetImageWithFadeAnimation
                      completion:^(UIImage *image, NSURL *url, NSError *error) {
            if (error || !image) {
                self.emojiImageView.image = ACCResourceImage(@"ic_video_reply_comment_sticker_emoji_failed");
            }
            if (error) {
                AWELogToolError2(@"video_reply_comment_sticker", AWELogToolTagRecord | AWELogToolTagEdit, @"ACCVideoReplyCommentWithoutCoverStickerView downloading emoji image failed: %@",error);
            }
        }];
    }
    
    self.videoTitleLabel.text = model.awemeTitle;
}

#pragma mark - Private

+ (YYTextLayout *)_commentLabelLayoutWithString:(NSString *)string
{
    CGSize size = CGSizeMake(kCommentLabelWidth, CGFLOAT_MAX);
    YYTextContainer *container = [YYTextContainer containerWithSize:size];
    container.insets = UIEdgeInsetsMake(1, 0, 1, 0);
    return [YYTextLayout layoutWithContainer:container text:[self _commentAttributedTextWithString:string]];
}

+ (NSAttributedString *)_commentAttributedTextWithString:(NSString *)string
{
    UIFont *font = [ACCFont() acc_systemFontOfSize:13.f weight:ACCFontWeightMedium];
    NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc] initWithString:string ?: @""];
    [IESAutoInline(ACCBaseServiceProvider(), ACCIMModuleServiceProtocol) replaceEmotionIconTextInAttributedString:attributedStr font:font emojiSize:CGSizeMake(11.f, 11.f)];
    attributedStr.yy_lineSpacing = 3.f;
    attributedStr.yy_font = font;
    attributedStr.yy_color = [UIColor acc_colorWithHex:@"#161823" alpha:0.75];
    return attributedStr.copy;
}

- (void)_setupMaskLayer
{
    [self acc_setupBorderWithTopLeftRadius:CGSizeMake(24.f, 24.f)
                            topRightRadius:CGSizeMake(24.f, 24.f)
                          bottomLeftRadius:CGSizeMake(4.f, 4.f)
                         bottomRightRadius:CGSizeMake(24.f, 24.f)];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // refresh mask
    [self _setupMaskLayer];
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
    ACCVideoReplyCommentWithoutCoverStickerView *copyView = [[ACCVideoReplyCommentWithoutCoverStickerView alloc] initWithModel:self.videoReplyCommentModel];
    return copyView;
}

#pragma mark - Properties

- (UIImageView *)avatarImageView
{
    if (!_avatarImageView) {
        _avatarImageView = [[UIImageView alloc] init];
        _avatarImageView.backgroundColor = [UIColor acc_colorWithHex:@"#161823" alpha:0.05];
        _avatarImageView.layer.cornerRadius = kAvatarWidth / 2.f;
        _avatarImageView.layer.borderWidth = 0.5;
        _avatarImageView.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.08].CGColor;
        _avatarImageView.layer.masksToBounds = YES;
    }
    return _avatarImageView;
}

- (UIVisualEffectView *)bgBlurView
{
    if (!_bgBlurView) {
        _bgBlurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
        _bgBlurView.backgroundColor = [UIColor whiteColor];
        _bgBlurView.alpha = 0.8;
    }
    return _bgBlurView;
}

- (UILabel *)nameLabel
{
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [ACCFont() acc_systemFontOfSize:12.f];
        _nameLabel.textColor = [UIColor acc_colorWithHex:@"#161823" alpha:0.6];
        _nameLabel.textAlignment = NSTextAlignmentLeft;
        _nameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    return _nameLabel;
}

- (UIStackView *)commentStackView
{
    if (!_commentStackView) {
        _commentStackView = [[UIStackView alloc] init];
        _commentStackView.spacing = kCommentSpace;
        _commentStackView.axis = UILayoutConstraintAxisVertical;
        _commentStackView.alignment = UIStackViewAlignmentLeading;
    }
    return _commentStackView;
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

- (UIImageView *)emojiImageView
{
    if (!_emojiImageView) {
        _emojiImageView = [ACCWebImage() animatedImageView];
        _emojiImageView.contentMode = UIViewContentModeScaleAspectFill;
        _emojiImageView.backgroundColor = [UIColor acc_colorWithHex:@"#161823" alpha:0.05];
        _emojiImageView.layer.cornerRadius = 2.f;
        _emojiImageView.clipsToBounds = YES;
    }
    return _emojiImageView;
}

- (UIImageView *)arrowImageview
{
    if (!_arrowImageview) {
        _arrowImageview = [[UIImageView alloc] init];
        _arrowImageview.image = ACCResourceImage(@"ic_video_reply_comment_sticker_light_right_arrow");
    }
    return _arrowImageview;
}

- (UIView *)videoBgView
{
    if (!_videoBgView) {
        _videoBgView = [[UIView alloc] init];
        _videoBgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.04];
        _videoBgView.clipsToBounds = YES;
        _videoBgView.layer.cornerRadius = kVideoBgViewHeight / 2.f;
    }
    return _videoBgView;
}

- (UILabel *)videoTipLabel
{
    if (!_videoTipLabel) {
        _videoTipLabel = [[UILabel alloc] init];
        _videoTipLabel.font = [ACCFont() acc_systemFontOfSize:11.f];
        _videoTipLabel.textColor = [UIColor acc_colorWithHex:@"#161823" alpha:0.6];
        _videoTipLabel.text = @"来自原视频";
    }
    return _videoTipLabel;
}

- (UIImageView *)videoArrowImageView
{
    if (!_videoArrowImageView) {
        _videoArrowImageView = [[UIImageView alloc] init];
        _videoArrowImageView.image = ACCResourceImage(@"ic_video_reply_comment_sticker_right_arrow");
    }
    return _videoArrowImageView;
}

- (UILabel *)videoTitleLabel
{
    if (!_videoTitleLabel) {
        _videoTitleLabel = [[UILabel alloc] init];
        _videoTitleLabel.font = [ACCFont() acc_systemFontOfSize:11.f];
        _videoTitleLabel.textColor = [UIColor acc_colorWithHex:@"#161823" alpha:0.6];
        _videoTitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _videoTitleLabel;
}

@end
