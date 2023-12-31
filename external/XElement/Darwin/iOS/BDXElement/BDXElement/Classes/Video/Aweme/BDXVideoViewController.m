//
//  BDXVideoViewController.m
//  BDXElement
//
//  Created by bill on 2020/3/25.
//

#import "BDXVideoViewController.h"
#import "BDXVideoPlayer.h"
#import "BDXVideoPlayerVideoModel.h"
#import "BDXVideoPlayerConfiguration.h"
#import "BDXVideoManager.h"
#import <ByteDanceKit/UIDevice+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/BTDResponder.h>
#import <ByteDanceKit/UIView+BTDAdditions.h>
#import <BDWebImage/BDWebImage.h>
#import <Masonry/Masonry.h>
#import <HTSServiceKit/HTSAppContext.h>

@interface BDXVideoCloseButton : UIButton

@end

@implementation BDXVideoCloseButton

- (void)drawRect:(CGRect)rect {
    // Drawing code
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect))];
    CGContextAddPath(ctx, path.CGPath);

    UIBezierPath *path1 = [UIBezierPath bezierPath];
    [path1 moveToPoint:CGPointMake(0, CGRectGetMaxY(rect))];
    [path1 addLineToPoint:CGPointMake(CGRectGetMaxX(rect), 0)];
    CGContextAddPath(ctx, path1.CGPath);
    
    [[UIColor lightGrayColor] set];
    CGContextSetLineWidth(ctx, 3);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    
    CGContextStrokePath(ctx);
}

@end

@interface BDXVideoViewController () <BDXVideoCorePlayerDelegate>

@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, assign) NSTimeInterval playTime;
@property (nonatomic,   copy) NSString *imageURL;

@property (nonatomic, assign) BOOL shouldResumePlay;
@property (nonatomic, assign) UIInterfaceOrientationMask restoreOrientation;

@end

@implementation BDXVideoViewController
@synthesize dismissBlock;
@synthesize playerView = _playerView;

- (instancetype)initWithCoverImageURL:(NSString *)url
{
    self = [super init];
    if (self) {
        self.imageURL = url;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}

- (instancetype)initWithCoverImage:(UIImage *)image
{
    self = [super init];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupUI];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerBecomeActive) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerEnterBackground) name: UIApplicationDidEnterBackgroundNotification object:nil];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad) {
        self.restoreOrientation = HTSCurrentContext().appDelegate.supportOrientation;
        HTSCurrentContext().appDelegate.supportOrientation = [self supportedInterfaceOrientations];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.playerView.frame = self.view.bounds;
    
    self.closeButton.hidden = NO;
    [self.closeButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            make.top.equalTo(self.view).offset(28.0);
            make.left.equalTo(self.view.mas_left).offset([UIDevice btd_isIPhoneXSeries] ? 77.0 : 16.0);
        } else {
            make.top.equalTo(self.view).offset([UIDevice btd_isIPhoneXSeries] ? 89.0 : 28.0);
            make.left.equalTo(self.view.mas_left).offset(16.0);
        }
        make.size.mas_equalTo(CGSizeMake(20, 20));
    }];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    BOOL isAPPHorizonal = UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation);
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad || isAPPHorizonal) {
        return [super supportedInterfaceOrientations];
    } else {
        return UIInterfaceOrientationMaskLandscapeRight;
    }
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationLandscapeRight;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)setupUI
{
    [self.view addSubview:self.playerView];
    self.playerView.frame = self.view.bounds;
    
    [self.view addSubview:self.closeButton];
    self.closeButton.hidden = YES;
}

- (void)dismiss
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad) {
        HTSCurrentContext().appDelegate.supportOrientation = self.restoreOrientation;
    }
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        if (self.dismissBlock) {
            self.dismissBlock();
        }
    }];
}

- (void)show:(void (^)(void))completion
{
    [[BTDResponder topViewController] presentViewController:self animated:YES completion:^{
        !completion ?: completion();
    }];
}

- (BOOL)play {
    return YES;
}

- (BOOL)pause {
    return YES;
}

#pragma mark - BDXVideoCorePlayerDelegate

- (void)bdx_playerDidReadyForDisplay:(id<BDXVideoCorePlayerProtocol>)player
{

}

- (void)bdx_player:(id<BDXVideoCorePlayerProtocol>)player didChangePlaybackStateWithAction:(BDXVideoPlaybackAction)action
{
    
}

- (void)bdx_player:(id<BDXVideoCorePlayerProtocol>)player playbackFailedWithError:(NSError *)error
{
    
}

#pragma mark - Notification

- (void)playerBecomeActive
{

}

- (void)playerEnterBackground
{

}

#pragma mark - Setters & Getters

- (BOOL)repeated
{
    return NO;
}

- (void)setRepeated:(BOOL)repeated
{
    
}

- (void)setInitPlayTime:(NSTimeInterval)initPlayTime
{
    
}

- (UIButton *)closeButton
{
    if (!_closeButton) {
        _closeButton = [BDXVideoCloseButton buttonWithType:UIButtonTypeCustom];
        [_closeButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    }

    return _closeButton;
}

@end
