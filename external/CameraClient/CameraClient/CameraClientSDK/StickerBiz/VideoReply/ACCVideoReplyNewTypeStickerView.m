//  视频回复视频贴纸样式优化
//  ACCVideoReplyNewTypeStickerView.m
//  CameraClient-Pods-Aweme
//  
//  Created by lixuan on 2021/11/15.
//

#import "ACCVideoReplyNewTypeStickerView.h"
#import "AWEInteractionVideoReplyStickerModel.h"
#import "ACCIMModuleServiceProtocol.h"

#import <AWEBaseModel/AWEURLModel.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/UIColor+ACC.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <YYText/YYLabel.h>
#import <YYText/NSAttributedString+YYText.h>
#import <BDXServiceCenter/NSString+BDXAdditions.h>

@interface ACCVideoReplyNewTypeStickerView ()

@property (nonatomic, strong, readwrite) ACCVideoReplyModel *videoReplyModel;
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UIButton *videoIconButton;
@property (nonatomic, strong) UIView *commentBgView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *userNameLabel;
@property (nonatomic, strong) YYLabel *titleLabel;

// 视频不可播放时显示的信息
@property (nonatomic, strong) UIImageView *unplayableImageView;
@property (nonatomic, strong) UILabel *unplayableLabel;
@end

static const NSUInteger kMaxNumberOfLines = 3;
static const CGFloat kStickerViewWidth = 110.f;
static const CGFloat kCoverImageHeight = 116.f;
static const CGFloat kUserNameLabelHeight = 17.f;
static const CGFloat kTitleLabelWidth = 97.f;

@implementation ACCVideoReplyNewTypeStickerView

@synthesize stickerContainer, coordinateDidChange;
@synthesize transparent = _transparent;
@synthesize stickerId = _stickerId;

#pragma mark - Public
- (instancetype)initWithModel:(ACCVideoReplyModel *)model
{
    CGSize frameSize = [ACCVideoReplyNewTypeStickerView p_frameSizeWithModel:model];
    self = [super initWithFrame:CGRectMake(0, 0, frameSize.width, frameSize.height)];
    if (self) {
        _videoReplyModel = [model copy];
        [self p_setupUI];
        [self p_downloadImageAndRefreshLabelWithModel:self.videoReplyModel];
        
    }
    return self;
}

- (instancetype)initWithStickerModel:(AWEInteractionStickerModel *)model
{
    if (![model isKindOfClass:[AWEInteractionVideoReplyStickerModel class]]) {
        return nil;
    }
    ACCVideoReplyModel *videoReplyModel = ((AWEInteractionVideoReplyStickerModel *)model).videoReplyUserInfo;
    if (videoReplyModel == nil) {
        return nil;
    }
    
    self = [self initWithModel:videoReplyModel];
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self p_setupMaskLayer];
}

#pragma mark - Private
+ (CGSize)p_frameSizeWithModel:(ACCVideoReplyModel *)model
{
    // init
    CGFloat stickerViewWidth = kStickerViewWidth;
    CGFloat stickerViewHeight = 0;
    
    // cover image
    stickerViewHeight += kCoverImageHeight;
    
    // username label & offset
    CGFloat userNameLabelTopOffset = 8.f;
    stickerViewHeight += (kUserNameLabelHeight + userNameLabelTopOffset);
    
    // title label & offset
    NSString *titleWithoutLineBreak = [model.title bdx_stringByRemoveAllCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    CGFloat titleLabelHeight = [ACCVideoReplyNewTypeStickerView p_getTitleLabelHeightWithString:titleWithoutLineBreak].textBoundingSize.height;
    CGFloat titleLabelTopOffset = 4.f;
    CGFloat titleLabelBottomOffset = 12.f;
    if (!titleLabelHeight) {
        titleLabelBottomOffset = 8.f;
    }
    stickerViewHeight += (titleLabelHeight + titleLabelTopOffset + titleLabelBottomOffset);
    
    return CGSizeMake(stickerViewWidth, stickerViewHeight);
}

+ (YYTextLayout *)p_getTitleLabelHeightWithString:(NSString *)string
{
    YYTextContainer *container = [YYTextContainer containerWithSize:CGSizeMake(kTitleLabelWidth, CGFLOAT_MAX)];
    container.maximumNumberOfRows = kMaxNumberOfLines;
    container.truncationType = YYTextTruncationTypeEnd;
    YYTextLayout *titleLabelLayout = [YYTextLayout layoutWithContainer:container text:[ACCVideoReplyNewTypeStickerView p_getTitleLabelAttributedStringWithString:string]];

    return titleLabelLayout;
}

+ (NSMutableAttributedString *)p_getTitleLabelAttributedStringWithString:(NSString *)string
{
    UIFont *titleFont = [ACCFont() acc_systemFontOfSize:12 weight:ACCFontWeightMedium];
    NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc] initWithString:string ?: @""];
    [IESAutoInline(ACCBaseServiceProvider(), ACCIMModuleServiceProtocol) replaceEmotionIconTextInAttributedString:attributedStr font:titleFont];
    attributedStr.yy_lineSpacing = 4.f;
    attributedStr.yy_font = titleFont;
    attributedStr.yy_color = [UIColor whiteColor];
    
    return attributedStr;
}

- (void)p_setupUI
{
    self.backgroundColor = [UIColor clearColor];
    // cover image
    [self addSubview:self.coverImageView];
    ACCMasMaker(self.coverImageView, {
        make.left.top.right.equalTo(self);
        make.height.mas_equalTo(kCoverImageHeight);
    });
    
    // unplayable image
    [self addSubview:self.unplayableImageView];
    ACCMasMaker(self.unplayableImageView, {
        make.centerX.equalTo(self);
        make.top.equalTo(self).offset(29.f);
    });
    
    // unplayable label
    [self addSubview:self.unplayableLabel];
    ACCMasMaker(self.unplayableLabel, {
        make.centerX.equalTo(self);
        make.top.equalTo(self.unplayableImageView.mas_bottom);
    });
    
    // video icon
    [self addSubview:self.videoIconButton];
    ACCMasMaker(self.videoIconButton, {
        make.left.equalTo(self).offset(8.f);
        make.top.equalTo(self).offset(8.f);
        make.size.mas_equalTo(CGSizeMake(46.f, 16.f));
    });
    
    // comment background view
    [self addSubview:self.commentBgView];
    ACCMasMaker(self.commentBgView, {
        make.left.bottom.right.equalTo(self);
        make.top.equalTo(self).offset(kCoverImageHeight);
    });
    
    // avartar image
    [self.commentBgView addSubview:self.avatarImageView];
    ACCMasMaker(self.avatarImageView, {
        make.left.equalTo(self.commentBgView).offset(6.f);
        make.top.equalTo(self.commentBgView).offset(8.f);
        make.size.mas_equalTo(CGSizeMake(16.f, 16.f));
    });
    
    // username label
    [self.commentBgView addSubview:self.userNameLabel];
    ACCMasMaker(self.userNameLabel, {
        make.left.equalTo(self.avatarImageView.mas_right).offset(4.f);
        make.top.equalTo(self.commentBgView).offset(8.f);
        make.width.mas_equalTo(76.f);
        make.height.mas_equalTo(17.f);
    });
    
    // title label
    [self.commentBgView addSubview:self.titleLabel];
    ACCMasMaker(self.titleLabel, {
        make.left.equalTo(self).offset(6.f);
        make.top.equalTo(self.commentBgView).offset(29.f);
        make.right.equalTo(self).offset(-4.f);
    });
}

- (void)p_downloadImageAndRefreshLabelWithModel:(ACCVideoReplyModel *)model
{
    
    // download cover image
    [ACCWebImage() imageView:self.coverImageView
        setImageWithURLArray:[model.coverModel URLList]
                 placeholder:ACCResourceImage(@"bg_video_reply_video_sticker_loading")
                     options:ACCWebImageOptionsIgnoreAnimatedImage | ACCWebImageOptionsSetImageWithFadeAnimation
                  completion:^(UIImage *image, NSURL *url, NSError *error) {
        if (error) {
            AWELogToolError2(@"video_reply_sticker", AWELogToolTagRecord | AWELogToolTagEdit, @"ACCVideoReplyNewTypeStickerView downloading cover image failed: %@", error);
        }
    }];
    
    // download avatar image
    [ACCWebImage() imageView:self.avatarImageView
        setImageWithURLArray:[model.userAvatarModel URLList]
                 placeholder:nil
                     options:ACCWebImageOptionsIgnoreAnimatedImage | ACCWebImageOptionsSetImageWithFadeAnimation
                  completion:^(UIImage *image, NSURL *url, NSError *error) {
        if (error || !image) {
            self.avatarImageView.image = ACCResourceImage(@"ic_video_reply_comment_sticker_avatar_failed_black");
        }
        if (error) {
            AWELogToolError2(@"video_reply_sticker", AWELogToolTagRecord | AWELogToolTagEdit, @"ACCVideoReplyNewTypeStickerView downloading avatar image failed: %@",error);
        }
    }];
    
    // refresh username label
    self.userNameLabel.text = model.username ?: @"username";
    
    // refresh title label
    NSString *titleWithoutLineBreak = [model.title bdx_stringByRemoveAllCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    self.titleLabel.attributedText = [ACCVideoReplyNewTypeStickerView p_getTitleLabelAttributedStringWithString:titleWithoutLineBreak];
    if (self.titleLabel.attributedText.length == 0) {
        self.titleLabel.hidden = YES;
    }
    self.titleLabel.textLayout = [ACCVideoReplyNewTypeStickerView p_getTitleLabelHeightWithString:titleWithoutLineBreak];
}

- (void)p_setupMaskLayer
{
    [self acc_setupBorderWithTopLeftRadius:CGSizeMake(12.f, 12.f)
                            topRightRadius:CGSizeMake(12.f, 12.f)
                          bottomLeftRadius:CGSizeMake(12.f, 12.f)
                         bottomRightRadius:CGSizeMake(2.f, 2.f)];
}

#pragma mark - ACCStickerCopyingProtocol

- (instancetype)copyForContext:(id)contextId
{
    ACCVideoReplyNewTypeStickerView *copyView = [[ACCVideoReplyNewTypeStickerView alloc] initWithModel:self.videoReplyModel];
    
    return copyView;
}

#pragma mark Getters
- (UIImageView *)unplayableImageView
{
    if (!_unplayableImageView) {
        _unplayableImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        _unplayableImageView.image = ACCResourceImage(@"ic_video_damage");
        _unplayableImageView.contentMode = UIViewContentModeScaleAspectFit;
        _unplayableImageView.hidden = self.videoReplyModel.isAvailable;
    }
    return _unplayableImageView;
}

- (UILabel *)unplayableLabel
{
    if (!_unplayableLabel) {
        _unplayableLabel = [[UILabel alloc] init];
        _unplayableLabel.textAlignment = NSTextAlignmentCenter;
        _unplayableLabel.textColor = ACCResourceColor(ACCColorConstTextInverse4);
        _unplayableLabel.font = [ACCFont() acc_systemFontOfSize:10];
        _unplayableLabel.text = @"原视频无法播放";
        [_unplayableLabel sizeToFit];
        _unplayableLabel.hidden = self.videoReplyModel.isAvailable;
    }
    return _unplayableLabel;
}

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
        _videoIconButton.backgroundColor = [UIColor acc_colorWithHex:@"#292929" alpha:0.34];
        _videoIconButton.enabled = NO;
        _videoIconButton.layer.cornerRadius = 2.f;
        [_videoIconButton setImage:ACCResourceImage(@"ic_video_comment_sticker_video") forState:UIControlStateDisabled];
        [_videoIconButton setTitle:@"原视频" forState:UIControlStateDisabled];
        [_videoIconButton setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
        _videoIconButton.titleLabel.font = [ACCFont() acc_systemFontOfSize:10 weight:ACCFontWeightMedium];
        _videoIconButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _videoIconButton.hidden = !self.videoReplyModel.isAvailable;
    }
    return _videoIconButton;
}

- (UIView *)commentBgView
{
    if (!_commentBgView) {
        _commentBgView = [[UIView alloc] init];
        _commentBgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    }
    return _commentBgView;
}

- (UIImageView *)avatarImageView
{
    if (!_avatarImageView) {
        _avatarImageView = [[UIImageView alloc] init];
        _avatarImageView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.06];
        _avatarImageView.layer.cornerRadius = 8.f;
        _avatarImageView.layer.borderWidth = 0.5;
        _avatarImageView.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.08].CGColor;
        _avatarImageView.layer.masksToBounds = YES;
    }
    return _avatarImageView;
}

- (UILabel *)userNameLabel
{
    if (!_userNameLabel) {
        _userNameLabel = [[UILabel alloc] init];
        _userNameLabel.backgroundColor = [UIColor clearColor];
        _userNameLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.75];
        _userNameLabel.font = [ACCFont() acc_systemFontOfSize:12 weight:ACCFontWeightMedium];
        _userNameLabel.textAlignment = NSTextAlignmentLeft;
        _userNameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _userNameLabel;
}

- (YYLabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[YYLabel alloc] init];
        _titleLabel.displaysAsynchronously = NO;
        _titleLabel.preferredMaxLayoutWidth = kTitleLabelWidth;
    }
    return _titleLabel;
}

@end


