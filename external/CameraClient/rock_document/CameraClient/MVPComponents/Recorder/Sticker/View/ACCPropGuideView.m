//
//  ACCPropGuideView.m
//  CameraClient-Pods-Aweme
//
//  Created by Chipengliu on 2020/12/1.
//

#import "ACCPropGuideView.h"

#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIDevice+ACCHardware.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <TTVideoEngine/TTVideoEnginePlayer.h>
#import <CreationKitInfra/ACCLogProtocol.h>

static BOOL AWEPropGuideViewIsShowing = NO;

@interface ACCPropGuideView ()<TTVideoPlayerStateProtocol>

@property (nonatomic, strong) UIButton *skipBtn;

@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UIView *playerContentView;

@property (nonatomic, strong) TTVideoEnginePlayer *player;
@property (nonatomic, assign, readwrite) NSInteger loopTimes;

@property (nonatomic, copy, nullable) void(^completionBlock)(void);

@end

@implementation ACCPropGuideView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = ACCResourceColor(ACCUIColorConstSDPrimary);
        [self setupSubviews];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)startVideoWithURL:(NSURL *)URL cover:(nullable NSArray *)coverURLList completion:(void(^)(void))completion
{
    AWEPropGuideViewIsShowing = YES;
    [self.player stop];
    [self.player close];
    self.loopTimes = 0;
    
    NSAssert(URL, @"URL is invalid!!!");
    self.completionBlock = completion;
    
    if (coverURLList) {
        self.coverImageView.hidden = NO;
        [ACCWebImage() imageView:self.coverImageView setImageWithURLArray:coverURLList];
    } else {
        self.coverImageView.hidden = YES;
    }
    
    [self.player setContentURL:URL];
    [self.player prepareToPlay];
    [self.player play];
}

- (void)onDidBecomeActive
{
    AWELogToolDebug(AWELogToolTagNone, @"onDidBecomeActive");
    [self.player play];
}

- (void)onWillResignActive
{
    AWELogToolDebug(AWELogToolTagNone, @"onWillResignActive");
    [self.player pause];
}

- (void)closePlay
{
    [self.player stop];
    [self.player close];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat width = CGRectGetWidth(self.bounds);
    BOOL isIPhone5 = [UIDevice acc_screenWidthCategory] == ACCScreenWidthCategoryiPhone5;
    CGFloat hwRatio = 476.f/268.f;
    CGFloat playerW = isIPhone5 ? 215.f : (width - 2 * 54);
    CGFloat playerH = isIPhone5 ? 382.f : (hwRatio * playerW);
    CGFloat btnW = 108.f;
    CGFloat btnH = 40.f;
    CGFloat margin = 23.f;
    
    CGFloat playerX = (width - playerW) / 2;
    CGFloat statusBarHeight = CGRectGetHeight([[UIApplication sharedApplication] statusBarFrame]);
    CGFloat playerY = (statusBarHeight + 96) * CGRectGetHeight([UIScreen mainScreen].bounds) / 811.f;
    if (isIPhone5) {
        playerY = 64.f;
    }
    
    // 如果高度超过屏幕范围，高度取屏幕的68%
    if ([UIDevice acc_isIPad] && (playerY + playerH) >= CGRectGetHeight(UIScreen.mainScreen.bounds)) {
        playerH = CGRectGetHeight(UIScreen.mainScreen.bounds) * 0.68;
        playerW = playerH / hwRatio;
        playerX = (width - playerW) / 2;
    }
    
    self.playerContentView.frame = CGRectMake(playerX, playerY, playerW, playerH);
    self.player.view.frame = self.playerContentView.bounds;
    
    self.coverImageView.frame = self.playerContentView.bounds;
    
    CGFloat btnX = (width - btnW) / 2;
    CGFloat btnY = CGRectGetMaxY(self.playerContentView.frame) + margin;
    self.skipBtn.frame = CGRectMake(btnX, btnY, btnW, btnH);
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self.skipBtn) {
        return view;
    }
    
    return self;
}

#pragma mark - Getter
- (NSTimeInterval)currentPlayTime
{
    return self.player.currentPlaybackTime;
}

- (NSTimeInterval)videoDuration
{
    return self.player.duration;
}

#pragma mark - private

- (void)setupPlayer
{
    self.player = [[TTVideoEnginePlayer alloc] initWithOwnPlayer:YES];
    self.player.delegate = self;
    self.player.looping = YES;
    self.player.scalingMode = TTVideoEngineScalingModeAspectFill;
    [self.playerContentView addSubview:self.player.view];
}

- (void)setupSubviews
{
    self.playerContentView = [[UIView alloc] init];
    [self addSubview:self.playerContentView];
    self.playerContentView.layer.cornerRadius = 6.f;
    self.playerContentView.layer.masksToBounds = YES;
    self.playerContentView.layer.borderColor = UIColor.whiteColor.CGColor;
    self.playerContentView.layer.borderWidth = 3.f;
    
    self.skipBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self addSubview:self.skipBtn];
    self.skipBtn.backgroundColor = ACCResourceColor(ACCColorConstLineInverse);
    [self.skipBtn setTitleColor:ACCResourceColor(ACCUIColorConstTextInverse) forState:UIControlStateNormal];
    self.skipBtn.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:15];
    [self.skipBtn setTitle:@"跳过教学" forState:UIControlStateNormal];
    [self.skipBtn addTarget:self action:@selector(skipBtnDidClick) forControlEvents:UIControlEventTouchUpInside];
    self.skipBtn.layer.cornerRadius = 20.f;
    
    [self setupPlayer];
    
    self.coverImageView = [[UIImageView alloc] initWithFrame:self.playerContentView.bounds];
    self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.playerContentView addSubview:self.coverImageView];
}

- (void)skipBtnDidClick
{
    if (self.completionBlock) {
        self.completionBlock();
    }
}

#pragma mark - Show
- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    if (newSuperview) {
        AWEPropGuideViewIsShowing = YES;
    }
}

- (void)removeFromSuperview
{
    [super removeFromSuperview];
    AWEPropGuideViewIsShowing = NO;
}

+ (BOOL)isShowing
{
    return AWEPropGuideViewIsShowing;
}

#pragma mark - TTVideoPlayerStateProtocol
- (void)playbackStateDidChange:(TTVideoEnginePlaybackState)state
{
    AWELogToolInfo(AWELogToolTagRecord, @"propGuideView, playbackStateDidChange, state: %@", @(state));
    if (state == TTVideoEnginePlaybackStateStopped) {
        self.loopTimes += 1;
        if (self.delegate && [self.delegate respondsToSelector:@selector(propGuideViewVideoDidStopPlay)]) {
            [self.delegate propGuideViewVideoDidStopPlay];
        }
    } else if (state == TTVideoEnginePlaybackStatePlaying) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(propGuideViewVideoDidStartPlay)]) {
            [self.delegate propGuideViewVideoDidStartPlay];
        }
    }
}
- (void)loadStateDidChange:(TTVideoEngineLoadState)state stallReason:(TTVideoEngineStallReason)reason
{
    AWELogToolInfo(AWELogToolTagRecord, @"propGuideView, loadStateDidChange, state: %@, reason: %@", @(state), @(reason));
    if (state == TTVideoEngineLoadStatePlayable) {
        self.coverImageView.hidden = YES;
    }
}
- (void)playableDurationUpdate:(NSTimeInterval)playableDuration
{
}
- (void)playbackDidFinish:(NSDictionary *)reason
{
    AWELogToolInfo(AWELogToolTagRecord, @"propGuideView, didFinish %@", reason[TTVideoEnginePlaybackDidFinishReasonUserInfoKey]);
}
- (void)playerIsPrepared
{
    
}
- (void)playerIsReadyToPlay
{
    
}
- (void)playerVideoSizeChange
{
    
}
- (void)playerVideoBitrateChanged:(NSInteger)bitrate
{
    
}
- (void)playerReadyToDisplay
{
    
}
- (void)playerAudioRenderStart
{
    
}
- (void)playerDeviceOpened:(TTVideoEngineStreamType)streamType
{
    
}
- (void)playerViewWillRemove
{
    
}
- (void)playerPreBuffering:(NSInteger)type
{
}
- (void)playerOutleterPaused:(TTVideoEngineStreamType)streamType
{
}
- (void)playerBarrageMaskInfoCompleted:(NSInteger)code
{
}
- (void)playerAVOutsyncStateChange:(NSInteger)type pts:(NSInteger)pts
{
}
- (void)playerNOVARenderStateChange:(TTVideoEngineNOVARenderStateType)stateType noRenderType:(int)noRenderType
{
}
- (void)playerDidCreateKernelPlayer
{
}
- (void)playerStartTimeNoVideoFrame:(int)streamDuration
{
}
- (void)playerMediaInfoDidChanged:(NSInteger)infoId
{
}

@end
