//
//  ACCEditVideoSmallPreviewController.m
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2021/1/28.
//

#import "ACCEditVideoSmallPreviewController.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/UIColor+CameraClientResource.h>

@interface ACCEditVideoSmallPreviewController()<ACCEditPreviewMessageProtocol>

@property (nonatomic, assign) CGFloat containerScale;
@property (nonatomic, assign) CGPoint containerCenter;
@property (nonatomic, assign) CGRect originalPlayerRect;
@property (nonatomic, strong, readwrite) UIView *playerContainer;
@property (nonatomic, strong, readwrite) UIButton *stopAndPlayBtn;
@property (nonatomic, strong) UIImageView *stopAndPlayImageView;
@property (nonatomic, strong) ACCStickerContainerView *stickerContainerView;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, assign) CGSize previewSize;

@end

@implementation ACCEditVideoSmallPreviewController

- (instancetype)initWithEditService:(id<ACCEditServiceProtocol>)editService
               stickerContainerView:(ACCStickerContainerView *)stickerContainerView
                        previewSize:(CGSize)previewSize
{
    self = [super init];
    if (self) {
        _editService = editService;
        _originalPlayerRect = editService.mediaContainerView.frame;
        _stickerContainerView = stickerContainerView;
        _previewSize = previewSize;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupUI];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.editService.preview resetPlayerWithViews:@[self.playerContainer]];
}

- (void)setupUI
{
    self.view.backgroundColor = ACCResourceColor(ACCColorBGCreation);
    self.playerContainer.frame = [self mediaSmallMediaContainerFrame];
    self.playerContainer.userInteractionEnabled = NO;

    [self configStickerContainerView];

    [self.editService.preview addSubscriber:self];

    [self.view addSubview:self.playerContainer];
    [self.view addSubview:self.stopAndPlayBtn];
    [self.stopAndPlayBtn addSubview:self.stopAndPlayImageView];
    
    ACCMasMaker(self.playerContainer, {
        make.edges.equalTo(self.view);
    });

    ACCMasMaker(self.stopAndPlayBtn, {
        make.center.equalTo(self.playerContainer);
        make.width.height.equalTo(self.playerContainer);
    });
    
    ACCMasMaker(self.stopAndPlayImageView, {
        make.left.top.right.bottom.equalTo(self.stopAndPlayBtn);
    });
}

- (UIView *)playerContainer
{
    if (!_playerContainer) {
        _playerContainer = [UIView new];
        _playerContainer.layer.cornerRadius = 2;
        _playerContainer.layer.masksToBounds = YES;
    }
    return _playerContainer;
}

- (void)configStickerContainerView
{
    if (self.stickerContainerView) {
        [self configScale];
        [self.playerContainer addSubview:self.stickerContainerView];
        self.stickerContainerView.transform = CGAffineTransformMakeScale(self.containerScale, self.containerScale);
        self.stickerContainerView.center = self.containerCenter;
        [self makeMaskLayerForContainerView:self.stickerContainerView];
    }
}

- (void)configScale
{
    self.containerScale = 1.0;
    
    CGFloat standScale = 9.0 / 16.0;
    CGFloat currentWidth = self.previewSize.width;
    CGFloat currentHeight = self.previewSize.height;
    CGRect oldFrame = self.originalPlayerRect;
    CGFloat oldWidth = CGRectGetWidth(oldFrame);
    CGFloat oldHeight = CGRectGetHeight(oldFrame);
    
    if (currentHeight > 0 && oldWidth > 0 && oldHeight > 0 ) {
        if (fabs(currentWidth / currentHeight - standScale) < 0.01) {
            self.containerScale = currentWidth / oldWidth;
        }
        
        if (currentWidth / currentHeight - standScale > 0.01) {
            self.containerScale = currentWidth / oldWidth;
        }
        
        if (currentWidth / currentHeight - standScale < -0.01) {
            self.containerScale = currentHeight / oldHeight;
        }
    }
    
    self.containerCenter = CGPointMake(self.playerContainer.center.x - self.playerContainer.frame.origin.x, self.playerContainer.center.y - self.playerContainer.frame.origin.y);
}

- (void)makeMaskLayerForContainerView:(UIView *)view
{
    CGRect frame = [self.view convertRect:self.playerContainer.frame toView:view];
    CAShapeLayer *layer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:frame];

    layer.path = path.CGPath;
    view.layer.mask = layer;
}

- (CGRect)mediaSmallMediaContainerFrame
{
    CGFloat playerHeight = self.previewSize.height;
    CGFloat playerWidth = self.previewSize.width;
    CGFloat playerX = (self.view.bounds.size.width - playerWidth) / 2;
    
    return CGRectMake(playerX, 0, playerWidth, playerHeight);
}

#pragma mark - Action

- (void)didClickStopAndPlay
{
    if (self.editService.preview.status == HTSPlayerStatusPlaying) {
         //pause
        [self.editService.preview seekToTime:CMTimeMakeWithSeconds(self.editService.preview.currentPlayerTime, 1000000) completionHandler:nil];
        self.editService.preview.stickerEditMode = YES;
        [self updateUIForIsPlaying:NO];
    } else {
        //进入播放状态
        self.editService.preview.stickerEditMode = NO;
        self.editService.preview.autoRepeatPlay = YES;
        [self.editService.preview play];
        [self updateUIForIsPlaying:YES];
    }
}


#pragma mark - Getter & Setter

- (UIButton *)stopAndPlayBtn
{
    if (!_stopAndPlayBtn) {
        _stopAndPlayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_stopAndPlayBtn addTarget:self action:@selector(didClickStopAndPlay) forControlEvents:UIControlEventTouchUpInside];
        _stopAndPlayBtn.accessibilityLabel = _stopAndPlayBtn.isSelected ? @"暂停" : @"播放";
        _stopAndPlayBtn.accessibilityTraits = UIAccessibilityTraitButton;
    }
    return _stopAndPlayBtn;
}

- (UIImageView *)stopAndPlayImageView
{
    if (_stopAndPlayImageView == nil) {
        _stopAndPlayImageView = [[UIImageView alloc] initWithImage:ACCResourceImage(@"iconBigplaymusic")];
        _stopAndPlayImageView.contentMode = UIViewContentModeCenter;
    }
    return _stopAndPlayImageView;
}


#pragma mark - ACCEditPreviewMessageProtocol

- (void)playerCurrentPlayTimeChanged:(NSTimeInterval)currentTime
{
    for (NSArray <ACCStickerViewType> *sticker in self.stickerContainerView.allStickerViews) {
        if ([sticker conformsToProtocol:@protocol(ACCPlaybackResponsibleProtocol)]) {
            [(id<ACCPlaybackResponsibleProtocol>)sticker updateWithCurrentPlayerTime:currentTime];
        }
    }
}


#pragma mark - Private

- (void)updateUIForIsPlaying:(BOOL)isPlaying
{
    [self.stopAndPlayImageView.layer removeAllAnimations];
    
    if (isPlaying) {
        CABasicAnimation *opacityAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacityAnim.fromValue = @(1);
        opacityAnim.toValue = @(0);
        opacityAnim.duration = 0.2;
        opacityAnim.fillMode = kCAFillModeForwards;
        opacityAnim.removedOnCompletion = NO;
        [self.stopAndPlayImageView.layer addAnimation:opacityAnim forKey:@"notshow"];
        [self.stopAndPlayBtn setSelected:YES];
        self.stopAndPlayBtn.accessibilityLabel = @"暂停";
        self.stopAndPlayBtn.accessibilityTraits = UIAccessibilityTraitButton;
    } else {
        CABasicAnimation *opacityAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacityAnim.fromValue = @(0);
        opacityAnim.toValue = @(1);
        opacityAnim.duration = 0.2;
        opacityAnim.fillMode = kCAFillModeForwards;
        opacityAnim.removedOnCompletion = NO;
        [self.stopAndPlayImageView.layer addAnimation:opacityAnim forKey:@"show"];
        [self.stopAndPlayBtn setSelected:NO];
        self.stopAndPlayBtn.accessibilityLabel = @"播放";
        self.stopAndPlayBtn.accessibilityTraits = UIAccessibilityTraitButton;
    }
}

@end
