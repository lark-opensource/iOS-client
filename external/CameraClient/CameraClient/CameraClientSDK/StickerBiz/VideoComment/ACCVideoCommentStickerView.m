//
//  ACCVideoCommentStickerView.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/18.
//

#import "ACCVideoCommentStickerView.h"

#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <YYText/YYLabel.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <YYText/NSAttributedString+YYText.h>
#import <CreativeKitSticker/ACCStickerUtils.h>
#import <CreationKitInfra/ACCLogHelper.h>

#import "ACCIMModuleServiceProtocol.h"

#pragma mark - BGView

/* --- BGView Start --- */

@interface BGView : UIView

@property (nonatomic, strong) UIVisualEffectView *blurredEffectView;

@end

@implementation BGView

- (instancetype)init
{
    self = [super init];
    if (self) {
        UIVisualEffect *blurEffect;
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        UIVisualEffectView *visualEffectView;
        visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        visualEffectView.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.9];
        
        visualEffectView.frame = self.bounds;
        [self addSubview:visualEffectView];
        self.blurredEffectView = visualEffectView;
        
        self.backgroundColor = UIColor.clearColor;
    }
    return self;
}

- (void)layoutSubviews
{
    UIBezierPath *bezierPath = [self p_createPath];
    CAShapeLayer *mask = [CAShapeLayer layer];
    mask.path = bezierPath.CGPath;
    
    self.blurredEffectView.frame = self.bounds;
    self.blurredEffectView.layer.mask = mask;
}

- (UIBezierPath *)p_createPath
{
    UIBezierPath *path = [[UIBezierPath alloc] init];
    [path moveToPoint:CGPointMake(7.f, 0.f)];
    [path addArcWithCenter:CGPointMake(7.f, 7.f)
                    radius:7.f
                startAngle:3*M_PI_2
                  endAngle:M_PI
                 clockwise:NO];
    [path addLineToPoint:CGPointMake(0, self.bounds.size.height - 11.f)];
    
    /* triangle */
    CGPoint triangleTopLeft = CGPointMake(0, self.bounds.size.height - 11.f);
    [path addLineToPoint:CGPointMake(0, triangleTopLeft.y + 1.4)];
    [path addCurveToPoint:CGPointMake(0.6, triangleTopLeft.y + 6.7)
            controlPoint1:CGPointMake(0, triangleTopLeft.y + 4.4)
            controlPoint2:CGPointMake(0, triangleTopLeft.y + 5.9)];
    [path addCurveToPoint:CGPointMake(2.9, triangleTopLeft.y + 7.8)
            controlPoint1:CGPointMake(1.2, triangleTopLeft.y + 7.4)
            controlPoint2:CGPointMake(2.f, triangleTopLeft.y + 7.8)];
    [path addCurveToPoint:CGPointMake(7.3, triangleTopLeft.y + 4.8)
            controlPoint1:CGPointMake(3.9, triangleTopLeft.y + 7.7)
            controlPoint2:CGPointMake(5.f, triangleTopLeft.y + 6.8)];
    [path addLineToPoint:CGPointMake(13.f, triangleTopLeft.y)];
    
    [path addLineToPoint:CGPointMake(self.bounds.size.width - 7.f, triangleTopLeft.y)];
    [path addArcWithCenter:CGPointMake(self.bounds.size.width - 7.f, triangleTopLeft.y - 7.f)
                    radius:7.f
                startAngle:M_PI_2
                  endAngle:0
                 clockwise:NO];
    [path addLineToPoint:CGPointMake(self.bounds.size.width, 7.f)];
    [path addArcWithCenter:CGPointMake(self.bounds.size.width - 7.f, 7.f)
                    radius:7.f
                startAngle:0
                  endAngle:3*M_PI_2
                 clockwise:NO];
    [path addLineToPoint:CGPointMake(7.f, 0)];
    [path closePath];
    
    return path;
}

@end

/* --- BGView End --- */

#pragma mark - ACCVideoCommentStickerView

/* --- ACCVideoCommentStickerView Start --- */

@interface ACCVideoCommentStickerView ()

@property (nonatomic, strong) UILabel *replierLabel;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) YYLabel *commentLabel;
@property (nonatomic, strong) UIImageView *emoIconImageView;
@property (nonatomic, strong) BGView *bgView;
@property (nonatomic, strong) ACCVideoCommentModel *videoCommentModel;

@end

@implementation ACCVideoCommentStickerView

@synthesize stickerContainer, coordinateDidChange;
@synthesize transparent = _transparent;
@synthesize stickerId = _stickerId;
@synthesize triggerDragDeleteCallback = _triggerDragDeleteCallback;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        [self p_setupUI];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    ACCBLOCK_INVOKE(self.coordinateDidChange); // Important! To resize gesture view's frame.
}

#pragma mark - ACCStickerCopyingProtocol

- (instancetype)copyForContext:(id)contextId
{
    ACCVideoCommentStickerView *copyView = [[ACCVideoCommentStickerView alloc] init];
    [copyView configWithModel:self.videoCommentModel completion:nil];
    return copyView;
}

#pragma mark - ACCStickerEditContentProtocol

- (void)setTransparent:(BOOL)transparent
{
    _transparent = transparent;
    self.alpha = transparent? 0.5: 1.0;
}

#pragma mark - ACCStickerContentProtocol
- (void)contentDidUpdateToScale:(CGFloat)scale {
    scale = MAX(1, scale);
    CGFloat contentScaleFactor = MIN(3, scale) * [UIScreen mainScreen].scale;
    self.replierLabel.contentScaleFactor = contentScaleFactor;
    self.commentLabel.contentScaleFactor = contentScaleFactor;
    [ACCStickerUtils applyScale:contentScaleFactor toLayer:self.replierLabel.layer];
    [ACCStickerUtils applyScale:contentScaleFactor toLayer:self.commentLabel.layer];
    
    CGSize size = CGSizeMake(188, CGFLOAT_MAX); // sticker's max width is 230, so comment label's max width is 188
    YYTextLayout *layout = [YYTextLayout layoutWithContainerSize:size
                                                            text:self.commentLabel.attributedText];
    // text layout display
    self.commentLabel.textLayout = layout;
}

#pragma mark - Public Methods

- (void)configWithModel:(ACCVideoCommentModel *)videoCommentModel completion:(nullable void (^)(void))completion
{
    self.videoCommentModel = videoCommentModel;
    
    UIFont *replierFont = [ACCFont() systemFontOfSize:12];
    UIFont *commentFont = [ACCFont() systemFontOfSize:12];
    CGFloat emoHeight = 60.f;
    NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc] initWithString:videoCommentModel.commentMsg ?: @""];
    [IESAutoInline(ACCBaseServiceProvider(), ACCIMModuleServiceProtocol) replaceEmotionIconTextInAttributedString:attributedStr font:commentFont];
    /* adjust font size according to the text length */
    if (attributedStr.length <= 52) {
        replierFont = [ACCFont() systemFontOfSize:12];
        commentFont = [ACCFont() systemFontOfSize:14];
        emoHeight = 60.f;
    } else if (attributedStr.length <= 78) {
        replierFont = [ACCFont() systemFontOfSize:11];
        commentFont = [ACCFont() systemFontOfSize:13];
        emoHeight = 60.f;
    } else if (attributedStr.length <= 100) {
        replierFont = [ACCFont() systemFontOfSize:11];
        commentFont = [ACCFont() systemFontOfSize:12];
        emoHeight = 50.f;
    } else {
        replierFont = [ACCFont() systemFontOfSize:11];
        commentFont = [ACCFont() systemFontOfSize:12];
        emoHeight = 50.f;
    }
    self.emoIconImageView.frame = CGRectMake(0, 0, emoHeight, emoHeight);

    self.replierLabel.text = [videoCommentModel.userName stringByAppendingString:@" 的评论"];
    self.replierLabel.font = replierFont;
    CGSize replierNewSize = [self.replierLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, 16)];
    self.replierLabel.frame = CGRectMake(0, 0, replierNewSize.width, replierNewSize.height);
    
    [IESAutoInline(ACCBaseServiceProvider(), ACCIMModuleServiceProtocol) replaceEmotionIconTextInAttributedString:attributedStr font:commentFont];
    if (attributedStr.length > 100) {
        attributedStr = [[attributedStr attributedSubstringFromRange:NSMakeRange(0, 100)] mutableCopy];
        [attributedStr appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"..."]];
    }
    attributedStr.yy_lineSpacing = 5;
    self.commentLabel.attributedText = [attributedStr copy];
    self.commentLabel.font = commentFont;
    CGSize size = CGSizeMake(188, CGFLOAT_MAX); // sticker's max width is 230, so comment label's max width is 188
    YYTextLayout *layout = [YYTextLayout layoutWithContainerSize:size
                                                            text:self.commentLabel.attributedText];
    // text layout display
    self.commentLabel.textLayout = layout;
    CGSize newCommentLblSize = layout.textBoundingSize; // get bounding size
    newCommentLblSize.width = MAX(newCommentLblSize.width, replierNewSize.width);
    newCommentLblSize.width = MAX(newCommentLblSize.width, 6.f);
    newCommentLblSize.height = MAX(newCommentLblSize.height, 20.f);
    self.commentLabel.frame = CGRectMake(0, 0, newCommentLblSize.width, newCommentLblSize.height);
    self.emoIconImageView.hidden = YES;
    [self p_updateUI];
    
    [ACCWebImage() imageView:self.avatarImageView setImageWithURLArray:videoCommentModel.avatarURLList
                 placeholder:ACCResourceImage(@"ic_video_comment_avatar_placeholder")
                     options:ACCWebImageOptionsIgnoreAnimatedImage | ACCWebImageOptionsSetImageWithFadeAnimation
                  completion:^(UIImage *image, NSURL *url, NSError *error) {
        if (error) {
            AWELogToolError2(@"video_comment_sticker", AWELogToolTagRecord | AWELogToolTagEdit, @"ACCVideoCommentStickerHandler download image failed: %@", error);
            return;
        }
    }];
    
    [ACCWebImage() imageView:self.emoIconImageView setImageWithURLArray:videoCommentModel.emojiURLList
                 placeholder:nil
                     options:ACCWebImageOptionsIgnoreAnimatedImage | ACCWebImageOptionsSetImageWithFadeAnimation
                  completion:^(UIImage *image, NSURL *url, NSError *error) {
        if (error) {
            AWELogToolError2(@"video_comment_sticker", AWELogToolTagRecord | AWELogToolTagEdit, @"ACCVideoCommentStickerHandler download image failed: %@", error);
            return;
        }
        if (image == nil) {
            return;
        }
        self.emoIconImageView.hidden = NO;
        // adjust emoji's width according to image's width/height ratio
        self.emoIconImageView.frame = CGRectMake(0, 0, image.size.width / image.size.height * emoHeight, emoHeight);
        [self p_updateUI];
        ACCBLOCK_INVOKE(completion);
    }];
}

#pragma mark - Private Methods

- (void)p_setupUI
{
    [self addSubview:self.bgView];
    [self addSubview:self.replierLabel];
    [self addSubview:self.avatarImageView];
    [self addSubview:self.commentLabel];
    [self addSubview:self.emoIconImageView];
}

- (void)p_updateUI
{
    CGFloat maxWidth = 0;
    CGFloat maxHeight = 0;
    
    /// update self's frame
    maxWidth = 8 + self.avatarImageView.frame.size.width + 6 + MAX(self.replierLabel.frame.size.width, self.commentLabel.frame.size.width) + 12;
    maxHeight = 12 + self.replierLabel.frame.size.height + 4 + self.commentLabel.frame.size.height + 12;
    if (!self.emoIconImageView.isHidden) {
        maxHeight += 4 + self.emoIconImageView.frame.size.height;
    }
    if (!self.emoIconImageView.isHidden) {
        maxWidth = 8 + self.avatarImageView.frame.size.width + 6 + MAX(MAX(self.replierLabel.frame.size.width, self.commentLabel.frame.size.width), self.emoIconImageView.frame.size.width) + 12;
        if (ACC_isEmptyString(self.videoCommentModel.commentMsg)) {
            maxHeight -= self.commentLabel.frame.size.height;
        }
    }
    CGRect newFrame = CGRectMake(self.frame.origin.x, self.frame.origin.y, maxWidth, maxHeight);
    self.frame = CGRectMake(newFrame.origin.x, newFrame.origin.y, newFrame.size.width, newFrame.size.height + 12);
    
    /// update subviews' frame
    self.avatarImageView.frame = CGRectMake(8, 32, self.avatarImageView.frame.size.width, self.avatarImageView.frame.size.height);
    self.replierLabel.frame = CGRectMake(34, 12, self.replierLabel.frame.size.width, self.replierLabel.frame.size.height);
    self.commentLabel.frame = CGRectMake(34, 32, self.commentLabel.frame.size.width, self.commentLabel.frame.size.height);
    if (!self.emoIconImageView.isHidden) {
        if (ACC_isEmptyString(self.videoCommentModel.commentMsg)) {
            self.commentLabel.frame = CGRectMake(self.commentLabel.frame.origin.x, self.commentLabel.frame.origin.y, self.commentLabel.frame.size.width, 0);
        }
        self.emoIconImageView.frame = CGRectMake(34, self.commentLabel.frame.origin.y + self.commentLabel.frame.size.height + 4, self.emoIconImageView.frame.size.width, self.emoIconImageView.frame.size.height);
    }
    self.bgView.frame = self.frame;
    [self.bgView setNeedsDisplay];
    
    ACCBLOCK_INVOKE(self.coordinateDidChange); // Important! To resize gesture view's frame.
}

#pragma mark - Getters and Setters

- (UILabel *)replierLabel
{
    if (!_replierLabel) {
        _replierLabel = [[UILabel alloc] init];
        _replierLabel.font = [ACCFont() systemFontOfSize:12];
        _replierLabel.textColor = ACCResourceColor(ACCColorTextReverse3);
    }
    return _replierLabel;
}

- (UIImageView *)avatarImageView
{
    if (!_avatarImageView) {
        _avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        _avatarImageView.layer.cornerRadius = 10;
        _avatarImageView.layer.masksToBounds = true;
        _avatarImageView.image = ACCResourceImage(@"ic_video_comment_avatar_placeholder");
    }
    return _avatarImageView;
}

- (YYLabel *)commentLabel
{
    if (!_commentLabel) {
        _commentLabel = [[YYLabel alloc] init];
        _commentLabel.font = [ACCFont() systemFontOfSize:14];
        _commentLabel.displaysAsynchronously = NO;
        _commentLabel.numberOfLines = 0;
        _commentLabel.textColor = ACCResourceColor(ACCColorTextPrimary);
    }
    return _commentLabel;
}

- (UIImageView *)emoIconImageView
{
    if (!_emoIconImageView) {
        _emoIconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    }
    return _emoIconImageView;
}

- (BGView *)bgView
{
    if (!_bgView) {
        _bgView = [[BGView alloc] init];
    }
    return _bgView;
}

@end

/* --- ACCVideoCommentStickerView End --- */
