//
//  ACCVideoReplyStickerView.m
//  CameraClient-Pods-Aweme
//
//  视频评论视频
//
//  Created by Daniel on 2021/7/27.
//

#import "ACCVideoReplyStickerView.h"
#import "AWEInteractionVideoReplyStickerModel.h"
#import "ACCDUXProtocl.h"

#import <AWEBaseModel/AWEURLModel.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreationKitArch/ACCAwemeModelProtocol.h>
#import <CreativeKitSticker/ACCStickerUtils.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <lottie-ios/Lottie/LOTAnimationView.h>
#import <CreativeKit/ACCResourceBundleProtocol.h>

static CGFloat const vCornerRadius = 4.f;

@interface ACCVideoReplyStickerView ()

@property (nonatomic, strong) UIImageView *videoCovcerImageView;
@property (nonatomic, strong) UILabel *usernameLbl;
@property (nonatomic, strong) UILabel *titleLbl;
@property (nonatomic, strong) UIImageView *typeImageView;
@property (nonatomic, strong) CAGradientLayer *contentGradientLayer;
@property (nonatomic, strong) UIView *loadingContainerView;
@property (nonatomic, strong) CAGradientLayer *loadingGradientLayer;
@property (nonatomic, strong) LOTAnimationView *loadingLottieView;
@property (nonatomic, strong, readwrite) ACCVideoReplyModel *videoReplyModel;
@property (nonatomic, strong, nullable) UIImage *videoCoverImage;

// 视频不可播放时显示的信息
@property (nonatomic, strong) UIImageView *unplayableImageView;
@property (nonatomic, strong) UILabel *unplayableLabel;

@end

@implementation ACCVideoReplyStickerView

@synthesize stickerContainer, coordinateDidChange;
@synthesize transparent = _transparent;
@synthesize stickerId = _stickerId;
@synthesize triggerDragDeleteCallback = _triggerDragDeleteCallback;

- (instancetype)initWithModel:(ACCVideoReplyModel *)model
{
    self = [super init];
    if (self) {
        self.videoReplyModel = [model copy];
        [self p_updateUIAndDownloadImage:self.videoReplyModel];
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

- (void)setFrame:(CGRect)frame
{
    CGRect oldFrame = self.frame;
    [super setFrame:frame];
    if (!CGSizeEqualToSize(frame.size, oldFrame.size)) {
        [self p_updateUIWithModel:self.videoReplyModel];
    }
}

#pragma mark - Private Methods

- (void)p_updateUIAndDownloadImage:(ACCVideoReplyModel *)videoReplyModel
{
    self.videoCoverImage = nil;
    [self p_updateUIWithModel:videoReplyModel];
    BOOL isAvailable = videoReplyModel.isAvailable;
    if (!isAvailable) {
        return;
    }
    @weakify(self);
    [ACCWebImage() imageView:self.videoCovcerImageView
        setImageWithURLArray:[videoReplyModel.coverModel URLList]
                 placeholder:nil
                     options:ACCWebImageOptionsIgnoreAnimatedImage | ACCWebImageOptionsSetImageWithFadeAnimation
                  completion:^(UIImage *image, NSURL *url, NSError *error) {
        @strongify(self);
        if (error) {
            AWELogToolError2(@"video_reply_sticker", AWELogToolTagRecord | AWELogToolTagEdit, @"ACCVideoReplyStickerView downloading cover image failed: %@", error);
            return;
        } else {
            self.videoCoverImage = image;
            [self p_updateUIWithModel:self.videoReplyModel];
            [self p_removeLottieView];
        }
    }];
}

- (void)p_updateUIWithModel:(ACCVideoReplyModel *)videoReplyModel
{
    self.layer.shadowColor = UIColor.blackColor.CGColor;
    self.layer.shadowOffset = CGSizeZero;
    self.layer.shadowRadius = 6.f;
    self.layer.shadowOpacity = 0.3f;
    
    // 1. get new frame
    CGRect newFrame = [self p_generateNewFrameWithImage:videoReplyModel.isAvailable ? self.videoCoverImage : nil];
    self.frame = newFrame;
    
    // video cover
    [self addSubview:self.videoCovcerImageView];
    self.videoCovcerImageView.frame = newFrame;
    
    if (videoReplyModel.isAvailable) {
        [self p_removeUnplayableIndicators];
    } else {
        [self p_addUnplayableIndicators];
    }
    
    // loading view (lottie)
    if (videoReplyModel.isAvailable && self.videoCoverImage == nil) {
        [self p_addLottieView:newFrame];
    } else {
        [self p_removeLottieView];
    }
    
    CGFloat gradientHeight = 0.f;
    // username & video title
    CGFloat labelMaxWidth = newFrame.size.width - 6.f * 2;
    NSString *username = videoReplyModel.username ?: @"username";
    if (ACC_isEmptyString(videoReplyModel.title)) {
        [self addSubview:self.usernameLbl];
        self.usernameLbl.text = [NSString stringWithFormat:@"@%@", username];
        CGSize newUserNameSize = [self.usernameLbl sizeThatFits:CGSizeMake(labelMaxWidth, CGFLOAT_MAX)];
        self.usernameLbl.frame = CGRectMake(6.f,
                                            newFrame.size.height - 6.f - newUserNameSize.height,
                                            newFrame.size.width - 6.f * 2,
                                            newUserNameSize.height);
        gradientHeight = newUserNameSize.height * 2.f;
    } else {
        [self addSubview:self.titleLbl];
        self.titleLbl.text = videoReplyModel.title;
        CGSize newTitleSize = [self.titleLbl sizeThatFits:CGSizeMake(labelMaxWidth, CGFLOAT_MAX)];
        self.titleLbl.frame = CGRectMake(6.f,
                                         newFrame.size.height - 6.f - newTitleSize.height,
                                         newFrame.size.width - 6.f * 2,
                                         newTitleSize.height);
        
        [self addSubview:self.usernameLbl];
        self.usernameLbl.text = [NSString stringWithFormat:@"@%@", username];
        CGSize newUserNameSize = [self.usernameLbl sizeThatFits:CGSizeMake(labelMaxWidth, CGFLOAT_MAX)];
        self.usernameLbl.frame = CGRectMake(6.f,
                                            self.titleLbl.frame.origin.y - newUserNameSize.height - 2.f,
                                            newFrame.size.width - 6.f * 2,
                                            newUserNameSize.height);
        
        gradientHeight = newTitleSize.height + newTitleSize.height;
        gradientHeight *= 2;
    }
    
    // gradient
    [self.contentGradientLayer removeFromSuperlayer];
    self.contentGradientLayer.frame = CGRectMake(0, newFrame.size.height - gradientHeight, newFrame.size.width, gradientHeight);
    [self.videoCovcerImageView.layer addSublayer:self.contentGradientLayer];
    
    // icon
    if (videoReplyModel.isAvailable) {
        [self addSubview:self.typeImageView];
        NSString *typeImageName = @"ic_video_reply_playnow";
        if (videoReplyModel.awemeType == ACCFeedTypeImageAlbum) {
            typeImageName = @"ic_video_reply_album";
        }
        NSString *typeImageFullName = [NSString stringWithFormat:@"file/svg/%@", typeImageName];
        CGSize newTypeImageViewSize = CGSizeMake(14.f, 14.f);
        let bundleService = IESAutoInline(ACCBaseServiceProvider(), ACCResourceBundleProtocol);
        NSString *bundleName = [bundleService currentResourceBundleName];
        NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:bundleName ofType:@"bundle"]];
        UIImage *image = [ACCDUX() generateIconImage:typeImageFullName
                                           imageSize:CGSizeMake(newTypeImageViewSize.width * 3, newTypeImageViewSize.height * 3)
                                          imageColor:UIColor.whiteColor
                                              bundle:bundle];
        self.typeImageView.image = image;
        
        self.typeImageView.frame = CGRectMake(newFrame.size.width - 6.f - newTypeImageViewSize.width,
                                              6.f,
                                              newTypeImageViewSize.width,
                                              newTypeImageViewSize.height);
    }
    
    ACCBLOCK_INVOKE(self.coordinateDidChange); // Important! To resize gesture view's frame.
}

- (void)p_addUnplayableIndicators
{
    self.videoCoverImage = nil;
    self.videoCovcerImageView.image = nil;
    
    CGFloat containerWidth = self.frame.size.width;
    CGFloat containerHeight = self.frame.size.height;
    CGFloat labelHeight = self.unplayableLabel.frame.size.height;
    CGFloat imageViewHeight = self.unplayableImageView.frame.size.height;
    
    [self addSubview:self.unplayableLabel];
    self.unplayableLabel.center = CGPointMake(containerWidth / 2.f, containerHeight / 2.f + labelHeight / 2.f);
    [self addSubview:self.unplayableImageView];
    self.unplayableImageView.center = CGPointMake(containerWidth / 2.f, containerHeight / 2.f - imageViewHeight / 2.f);
}

- (void)p_removeUnplayableIndicators
{
    [self.unplayableImageView removeFromSuperview];
    self.unplayableImageView = nil;
    [self.unplayableLabel removeFromSuperview];
    self.unplayableLabel = nil;
}

/// loading view (lottie)
/// @param frame container's frame
- (void)p_addLottieView:(CGRect)frame
{
    [self addSubview:self.loadingContainerView];
    self.loadingContainerView.frame = frame;
    [self.loadingGradientLayer removeFromSuperlayer];
    [self.loadingContainerView.layer addSublayer:self.loadingGradientLayer];
    self.loadingGradientLayer.frame = frame;
    NSBundle *feedbundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"AWEFeed" ofType:@"bundle"]];
    NSString *path = [feedbundle pathForResource:@"album_browser_loading" ofType:@"json"];
    BOOL isFileExisted = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (!isFileExisted) {
        AWELogToolError2(@"ACCVideoReplyStickerView", AWELogToolTagEdit, @"lottie file does NOT exist");
    }
    self.loadingLottieView = [LOTAnimationView animationWithFilePath:path];
    self.loadingLottieView.hidden = NO;
    self.loadingLottieView.loopAnimation = YES;
    [self.loadingContainerView addSubview:self.loadingLottieView];
    self.loadingLottieView.frame = CGRectMake(0, 0, 44.f, 44.f);
    self.loadingLottieView.center = self.center;
    [self.loadingLottieView play];
}

- (void)p_removeLottieView
{
    [self.loadingLottieView stop];
    [self.loadingLottieView removeFromSuperview];
    _loadingLottieView = nil;
    [self.loadingContainerView removeFromSuperview];
    _loadingContainerView = nil;
}

- (CGRect)p_generateNewFrameWithImage:(UIImage *)coverImage
{
    CGFloat width = 104;
    CGFloat height = 140;
    
    // adjust frame size according to the image's ratio
    if (coverImage != nil) {
        CGFloat imageWidth = coverImage.size.width;
        CGFloat imageHeight = coverImage.size.height;
        if (imageWidth > imageHeight) {
            self.videoCovcerImageView.contentMode = UIViewContentModeScaleAspectFit;
        } else {
            self.videoCovcerImageView.contentMode = UIViewContentModeScaleAspectFill;
        }
    }
    
    CGRect newFrame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, height);
    return newFrame;
}

#pragma mark - Getters

- (UIImageView *)unplayableImageView
{
    if (!_unplayableImageView) {
        _unplayableImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        _unplayableImageView.image = ACCResourceImage(@"ic_video_damage");
        _unplayableImageView.contentMode = UIViewContentModeScaleAspectFit;
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
    }
    return _unplayableLabel;
}

- (UIImageView *)videoCovcerImageView
{
    if (!_videoCovcerImageView) {
        _videoCovcerImageView = [[UIImageView alloc] init];
        _videoCovcerImageView.layer.cornerRadius = vCornerRadius;
        _videoCovcerImageView.backgroundColor = ACCResourceColor(ACCColorTextReverse);
        _videoCovcerImageView.contentMode = UIViewContentModeScaleAspectFit;
        _videoCovcerImageView.layer.cornerRadius = vCornerRadius;
        _videoCovcerImageView.clipsToBounds = YES;
    }
    return _videoCovcerImageView;
}

- (UIImageView *)typeImageView
{
    if (!_typeImageView) {
        _typeImageView = [[UIImageView alloc] init];
        _typeImageView.layer.cornerRadius = vCornerRadius;
        _typeImageView.contentMode = UIViewContentModeScaleAspectFit;
        _typeImageView.layer.magnificationFilter = @"nearest";
    }
    return _typeImageView;
}

- (UILabel *)usernameLbl
{
    if (!_usernameLbl) {
        _usernameLbl = [[UILabel alloc] init];
        _usernameLbl.lineBreakMode = NSLineBreakByTruncatingTail;
        _usernameLbl.textColor = ACCResourceColor(ACCColorConstTextInverse);
        _usernameLbl.font = [ACCFont() acc_systemFontOfSize:11.f weight:ACCFontWeightMedium];
        _usernameLbl.numberOfLines = 1;
    }
    return _usernameLbl;
}

- (UILabel *)titleLbl
{
    if (!_titleLbl) {
        _titleLbl = [[UILabel alloc] init];
        _titleLbl.lineBreakMode = NSLineBreakByTruncatingTail;
        _titleLbl.textColor = ACCResourceColor(ACCColorConstTextInverse2);
        _titleLbl.font = [ACCFont() acc_systemFontOfSize:10.f weight:ACCFontWeightRegular];
        _titleLbl.numberOfLines = 1;
    }
    return _titleLbl;
}

- (CAGradientLayer *)contentGradientLayer
{
    if (!_contentGradientLayer) {
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.startPoint = CGPointMake(0.5, 0);
        gradientLayer.endPoint = CGPointMake(0.5, 1);
        gradientLayer.colors = @[(__bridge id)[UIColor clearColor].CGColor,
                                 (__bridge id)[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4].CGColor];
        gradientLayer.cornerRadius = vCornerRadius;
        _contentGradientLayer = gradientLayer;
    }
    return _contentGradientLayer;
}

- (UIView *)loadingContainerView
{
    if (!_loadingContainerView) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = ACCUIColorFromRGBA(0x161823, 1.0);
        view.layer.cornerRadius = vCornerRadius;
        _loadingContainerView = view;
    }
    return _loadingContainerView;
}

- (CAGradientLayer *)loadingGradientLayer
{
    if (!_loadingGradientLayer) {
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.cornerRadius = vCornerRadius;
        gradientLayer.startPoint = CGPointMake(0, 0.5f);
        gradientLayer.endPoint = CGPointMake(1, 0.5f);
        gradientLayer.colors = @[(__bridge id)ACCUIColorFromRGBA(0x31151C, 1.0).CGColor,
                                 (__bridge id)ACCUIColorFromRGBA(0x181722, 1.0).CGColor];
        _loadingGradientLayer = gradientLayer;
    }
    return _loadingGradientLayer;
}

#pragma mark - ACCStickerCopyingProtocol

- (instancetype)copyForContext:(id)contextId
{
    ACCVideoReplyStickerView *copyView = [[ACCVideoReplyStickerView alloc] initWithModel:self.videoReplyModel];
    [copyView.loadingLottieView stop];
    [copyView p_removeLottieView];
    return copyView;
}

#pragma mark - ACCStickerEditContentProtocol

- (void)setTransparent:(BOOL)transparent
{
    _transparent = transparent;
    self.alpha = transparent? 0.5: 1.0;
}

#pragma mark - ACCStickerContentProtocol

- (void)contentDidUpdateToScale:(CGFloat)scale
{
    scale = MAX(1, scale);
    CGFloat contentScaleFactor = MIN(3, scale) * [UIScreen mainScreen].scale;
    self.videoCovcerImageView.contentScaleFactor = contentScaleFactor;
    self.usernameLbl.contentScaleFactor = contentScaleFactor;
    self.titleLbl.contentScaleFactor = contentScaleFactor;
    self.typeImageView.contentScaleFactor = contentScaleFactor;
    self.contentGradientLayer.contentsScale = contentScaleFactor;
    [ACCStickerUtils applyScale:contentScaleFactor toLayer:self.videoCovcerImageView.layer];
    [ACCStickerUtils applyScale:contentScaleFactor toLayer:self.usernameLbl.layer];
    [ACCStickerUtils applyScale:contentScaleFactor toLayer:self.titleLbl.layer];
    [ACCStickerUtils applyScale:contentScaleFactor toLayer:self.typeImageView.layer];
    [ACCStickerUtils applyScale:contentScaleFactor toLayer:self.contentGradientLayer];
}

@end
