//
//  ACCPlayerEditBaseViewController.m
//  Pods
//
//  Created by Shen Chen on 2020/6/29.
//


#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <Masonry/Masonry.h>
#import "ACCPlayerEditBaseViewController.h"
#import "ACCViewControllerProtocol.h"
#import <CreativeKit/ACCResourceHeaders.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import "AWERepoVideoInfoModel.h"

@interface ACCPlayerEditBaseViewController () <ACCEditPreviewMessageProtocol>
@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;
@property (nonatomic, strong) ACCEditVideoData *videoData;
@property (nonatomic, strong) AWEVideoPublishViewModel *model;
@property (nonatomic, strong) UIView *playerContainer;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, assign) CGSize defaultVideoSize;
@property (nonatomic, strong) UIImageView *playIcon;
@property (nonatomic, assign) BOOL playerHasReset;
@property (nonatomic, assign) BOOL wasPlaying;
@end

@implementation ACCPlayerEditBaseViewController

- (instancetype)initWithEditService:(id<ACCEditServiceProtocol>)editService
                              model:(AWEVideoPublishViewModel *)model
{
    self = [super init];
    if (self) {
        self.editService = editService;
        self.videoData = model.repoVideoInfo.video;
        self.model = model;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

#pragma mark - Life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [ACCViewControllerService() viewController:self setDisableFullscreenPopTransition:YES];
    [ACCViewControllerService() viewController:self setPrefersNavigationBarHidden:YES];
    self.view.backgroundColor = ACCResourceColor(ACCColorBGCreation);
    [self setupPlayer];
    [self.view addSubview:self.bottomView];
    self.bottomView.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, [self bottomViewHeight]);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.playerHasReset) {
        [self.editService.preview resetPlayerWithViews:@[self.playerContainer]];
        [self.editService.preview seekToTime:kCMTimeZero];
        self.playerHasReset = YES;
    }
}

- (BOOL)prefersStatusBarHidden
{
    return ![UIDevice acc_isIPhoneX];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - Getter & Setter

- (UIView *)playerContainer
{
    if (!_playerContainer) {
        _playerContainer = [UIView new];
        _playerContainer.layer.cornerRadius = 2;
        _playerContainer.layer.masksToBounds = YES;
    }
    return _playerContainer;
}

- (UIImageView *)playIcon
{
    if (!_playIcon) {
        _playIcon = [[UIImageView alloc] initWithImage:ACCResourceImage(@"iconBigplaymusic")];
        _playIcon.contentMode = UIViewContentModeScaleAspectFit;
        _playIcon.alpha = 0;
    }
    return _playIcon;
}

- (UIView *)bottomView
{
    if (!_bottomView) {
        CGFloat y = self.view.bounds.size.height - [self bottomViewHeight];
        _bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, y, self.view.bounds.size.width, [self bottomViewHeight])];
        _bottomView.backgroundColor = ACCResourceColor(ACCColorBGCreation2);;
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, self.view.bounds.size.width, [self bottomViewHeight])
                                                   byRoundingCorners:UIRectCornerTopRight | UIRectCornerTopLeft
                                                         cornerRadii:CGSizeMake(12, 12)];
        maskLayer.path = path.CGPath;
        _bottomView.layer.mask = maskLayer;
    }
    return _bottomView;
}

#pragma mark - Public

- (CGFloat)playerContainerYoffset
{
    return 52 + ([UIDevice acc_isIPhoneX] ? 44 : 0); // to override
}

- (CGFloat)bottomViewHeight
{
    return 40 + ACC_IPHONE_X_BOTTOM_OFFSET; // to override
}

- (CGFloat)playerBottomSpace
{
    return 16; // to override
}

- (NSArray<UIView *> *)topViews
{
    return @[]; // to override
}

#pragma mark - ACCEditPreviewMessageProtocol

- (void)playerCurrentPlayTimeChanged:(NSTimeInterval)currentTime
{
    if ([self shouldUpdatePlayerIndicatorWhenPlay]) {
        [self movieDidChangePlaytime:currentTime];
    }
}

#pragma mark - Player

- (BOOL)isPlaying
{
    switch (self.editService.preview.status) {
        case HTSPlayerStatusPlaying:
        case HTSPlayerStatusWaitingProcess:
        case HTSPlayerStatusProcessing:
        case HTSPlayerStatusWaitingPlay:
            return YES;
        case HTSPlayerStatusIdle:
            return NO;
        default:
            return NO;
    }
}


- (void)moviePause
{
    self.wasPlaying = [self isPlaying];
    [self.editService.preview pause];
}

- (void)moviePlay
{
    [self.editService.preview play];
    [self showPlayIcon:NO animated:YES];
}

- (void)movieRestore
{
    if (self.wasPlaying) {
        [self moviePlay];
    } else {
        [self moviePause];
    }
}

- (void)movieSeekToTime:(CMTime)time
{
    [self.editService.preview seekToTime:time];
}

- (void)movieSeekToTime:(CMTime)time completion:(void (^)(BOOL finished))completionHandler
{
    [self.editService.preview seekToTime:time completionHandler:completionHandler];
}

- (void)movieDidChangePlaytime:(NSTimeInterval)playtime
{
    
}

#pragma mark - Actions

- (void)onPlayIconTapped:(id)sender
{
    if ([self isPlaying]) {
        [self moviePause];
        [self showPlayIcon:YES animated:YES];
    } else {
        [self moviePlay];
        [self showPlayIcon:NO animated:YES];
    }
}


#pragma mark - Private

- (void)setupPlayer
{
    [self.view addSubview: self.playerContainer];
    self.playerContainer.frame = [self playerFrame];
    
    [self.view addSubview:self.playIcon];
    ACCMasMaker(self.playIcon, {
        make.center.equalTo(self.playerContainer);
        make.size.mas_equalTo(CGSizeMake(45, 45));
    });
    [self showPlayIcon:YES animated:NO];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onPlayIconTapped:)];
    [self.playerContainer addGestureRecognizer:tap];
    [self.editService.preview addSubscriber:self];
}

- (void)showPlayIcon:(BOOL)show animated:(BOOL)animated
{
    NSTimeInterval duration = 0;
    if (animated) {
        duration = show ? 0.15 : 0.1;
    }
    if (animated) {
        if (show && self.playIcon.alpha == 1.0) {
            return;
        }
        if (!show && self.playIcon.alpha == 0.0) {
            return;
        }
        if (show) {
            self.playIcon.transform = CGAffineTransformMakeScale(2, 2);
        }
        [UIView animateWithDuration:duration animations:^{
            self.playIcon.transform = CGAffineTransformIdentity;
            self.playIcon.alpha = show ? 1 : 0;
        }];
    } else {
        self.playIcon.transform = CGAffineTransformIdentity;
        self.playIcon.alpha = show ? 1 : 0;
    }
}

- (BOOL)shouldUpdatePlayerIndicatorWhenPlay {
    return YES;
}

- (CGSize)defaultVideoSize
{
    AVAsset *asset = self.videoData.videoAssets.firstObject;
    AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    if (!videoTrack) {
        return CGSizeMake(540, 960);
    }
    CGSize naturalSize = videoTrack.naturalSize;
    CGSize temp = CGSizeApplyAffineTransform(naturalSize, videoTrack.preferredTransform);
    CGSize sourceSize = CGSizeMake(fabs(temp.width), fabs(temp.height));
    return sourceSize;
}

- (CGRect)playerFrame
{
    CGSize normalizedSize = self.videoData.normalizeSize;
    if (CGSizeEqualToSize(normalizedSize, CGSizeZero)) {
        normalizedSize = self.model.repoVideoInfo.playerFrame.size;
    }
    if (CGSizeEqualToSize(normalizedSize, CGSizeZero)) {
        normalizedSize = [self defaultVideoSize];
    }
    
    CGFloat playerY = [self playerContainerYoffset];
    CGFloat playerHeight = self.view.frame.size.height - playerY - [self playerBottomSpace] - [self bottomViewHeight];
    CGFloat playerWidth = self.view.frame.size.width;
    CGFloat playerX = 0;
    return AVMakeRectWithAspectRatioInsideRect(normalizedSize, CGRectMake(playerX, playerY, playerWidth, playerHeight));
}

#pragma mark - AWEMediaSmallAnimationProtocol

- (UIView *)mediaSmallMediaContainer
{
    return self.playerContainer;
}

- (UIView *)mediaSmallBottomView
{
    return self.bottomView;
}

- (CGRect)mediaSmallMediaContainerFrame
{
    return [self playerFrame];
}

- (NSArray<UIView *>*)displayTopViews
{
    return [self topViews];
}

@end
