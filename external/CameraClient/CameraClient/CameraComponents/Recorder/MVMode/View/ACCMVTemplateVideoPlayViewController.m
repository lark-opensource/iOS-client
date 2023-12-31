//
//  ACCMVTemplateVideoPlayViewController.m
//  CameraClient
//
//  Created by long.chen on 2020/3/9.
//

#import "ACCMVTemplateVideoPlayViewController.h"
#import <CreationKitInfra/UIView+ACCRTL.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/UIDevice+ACCHardware.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

#import <TTVideoEngine/TTVideoEngine+Options.h>
#import <TTVideoEngine/TTVideoEngine+Preload.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCMVTemplateModelProtocol.h>
#import <CreationKitArch/ACCRepoContextModel.h>

NSString *const ACCMVTemplateDidFinishVideoDataDownloadNotification = @"ACCMVTemplateDidFinishVideoDataDownloadNotification";

NSString *const ACCMVTemplateDidFinishVideoDataDownloadIDKey = @"ACCMVTemplateDidFinishVideoDataDownloadIDKey";

@interface ACCMVTemplateVideoPlayViewController () <TTVideoEngineDelegate, TTVideoEngineInternalDelegate>

@property (nonatomic, strong) UIImageView *loadingPlaceholder;
@property (nonatomic, strong) TTVideoEngine *playerController;
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UIImageView *playIconImageView;

@property (nonatomic, assign) BOOL pauseByTap;
@property (nonatomic, assign) BOOL hasTrackedPlayEvent;

@end

@implementation ACCMVTemplateVideoPlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self p_setupUI];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.playerController.playerView.frame = self.view.bounds;
    self.loadingPlaceholder.bounds = CGRectMake(0, 0, 120, 120);
    self.loadingPlaceholder.center = self.view.center;
    self.coverImageView.frame = self.view.bounds;
    self.playIconImageView.bounds = CGRectMake(0, 0, 70, 78);
    self.playIconImageView.center = self.view.center;
}

- (void)p_setupUI
{
    self.view.backgroundColor = ACCResourceColor(ACCColorBGView);
    
    // player
    self.playerController = [[TTVideoEngine alloc] initWithOwnPlayer:YES];
    self.playerController.looping = YES;
    self.playerController.cacheEnable = YES;
    self.playerController.delegate = self;
    self.playerController.internalDelegate = self;
    self.playerController.hardwareDecode = YES;
    self.playerController.proxyServerEnable = YES; 
    [self.playerController configResolution:TTVideoEngineResolutionTypeHD];
    [self.playerController setOptions:@{VEKKEY(VEKKeyPlayerAsyncInit_BOOL):@(YES)}];
    [self.playerController setOptionForKey:VEKKeyPlayerOpenTimeOut_NSInteger value:@(15)];
    [self.playerController setOptions:@{VEKKEY(VEKKeyViewEnhancementType_ENUM):@(TTVideoEngineEnhancementTypeNone)}];
    [self.playerController setOptions:@{VEKKEY(VEKKeyViewImageLayoutType_ENUM):@(TTVideoEngineLayoutTypeAspectFit)}];
    [self.playerController setOptions:@{VEKKEY(VEKKeyViewScaleMode_ENUM):@(TTVideoEngineScalingModeAspectFit)}];
    if ([TTVideoEngine isSupportMetal]) {
        [self.playerController setOptions:@{VEKKEY(VEKKeyViewRenderEngine_ENUM):@(TTVideoEngineRenderEngineMetal)}];
    } else {
        [self.playerController setOptions:@{VEKKEY(VEKKeyViewRenderEngine_ENUM):@(TTVideoEngineRenderEngineOpenGLES)}];
    }
    self.playerController.playerView.accrtl_viewType = ACCRTLViewTypeNormal;
    [self.view addSubview:self.playerController.playerView];
    [self.view addSubview:self.loadingPlaceholder];
    [self.view addSubview:self.coverImageView];
    [self.view addSubview:self.playIconImageView];
}

- (void)setTemplateModel:(id<ACCMVTemplateModelProtocol>)templateModel
{
    _templateModel = templateModel;
    [ACCWebImage() imageView:self.coverImageView setImageWithURLArray:templateModel.templateDynamicCoverURL.count > 0 ? templateModel.templateDynamicCoverURL : templateModel.templateCoverURL];
    
    [self.interactionDelegate playLoadingAnimation];
    self.loadingPlaceholder.hidden = NO;
    self.loadingPlaceholder.image = ACCResourceImage(@"img_mv_cell_loading");
    
    if (templateModel.video.playURL) {
        self.playerController.playerView.hidden = NO;
        [self.playerController ls_setDirectURLs:templateModel.video.playURL.URLList
                                            key:templateModel.video.playURL.URI];
        [self.playerController prepareToPlay];
    } else if (templateModel.templateVideoURL) {
        self.playerController.playerView.hidden = NO;
        [self.playerController setDirectPlayURLs:templateModel.templateVideoURL];
        [self.playerController prepareToPlay];
    } else {
        [self.interactionDelegate stopLoadingAnimation];
        self.loadingPlaceholder.image = ACCResourceImage(@"img_mv_cell_damage");
    }
    
    // adjust ratio
    BOOL needClip = NO;
    CGFloat ratio = 16.0 / 9.0;
    if (templateModel.video.width.integerValue != 0 && templateModel.video.height.integerValue != 0) {
        ratio = templateModel.video.height.floatValue / templateModel.video.width.floatValue;
    }
    if ([UIDevice acc_isIPhoneX] && ratio >= (16.0 / 9.0)) {
        needClip = YES;
    }
    if (needClip) {
        self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.playerController setOptions:@{VEKKEY(VEKKeyViewScaleMode_ENUM):@(TTVideoEngineScalingModeAspectFill)}];
    } else {
        self.coverImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.playerController setOptions:@{VEKKEY(VEKKeyViewScaleMode_ENUM):@(TTVideoEngineScalingModeAspectFit)}];
    }
    
}

- (void)play
{
    if ((self.playIconImageView.hidden || self.pauseByTap) && self.templateModel.templateVideoURL) {
        [self.playerController play];
        self.pauseByTap = NO;
    }
}

- (void)pause
{
    [self.playerController pause];
}

- (void)stop
{
    [self.playerController stop];
}

- (void)reset
{
    self.coverImageView.image = nil;
    self.coverImageView.hidden = NO;
    self.playIconImageView.hidden = YES;
    [self.playerController close];
    self.playerController.playerView.hidden = YES;
    self.hasTrackedPlayEvent = NO;
}

#pragma mark - TTVideoEngineDelegate

- (void)videoEngine:(TTVideoEngine *)videoEngine playbackStateDidChanged:(TTVideoEnginePlaybackState)playbackState
{
    if (playbackState == TTVideoEnginePlaybackStatePlaying) {
        [self.interactionDelegate stopLoadingAnimation];
        if (!self.hasTrackedPlayEvent) {
            [ACCTracker() trackEvent:@"mv_play"
                               params:@{
                                   @"mv_id" : @(self.templateModel.templateID),
                                   @"enter_from" : @"mv_card",
                                   @"shoot_way" : self.publishModel.repoTrack.referString ?: @"",
                                   @"creation_id" : self.publishModel.repoContext.createId ?: @"",
                                   @"content_type" : self.templateModel.accTemplateType == ACCMVTemplateTypeClassic ? @"mv" : @"jianying_mv",
                                   @"mv_recommend" : @"1",
                               }
                      needStagingFlag:NO];
            self.hasTrackedPlayEvent = YES;
        }
    } else if (playbackState == TTVideoEnginePlaybackStateError) {
        [self.interactionDelegate stopLoadingAnimation];
        self.loadingPlaceholder.hidden = NO;
        self.loadingPlaceholder.image = ACCResourceImage(@"img_mv_cell_damage");
    }
}

- (void)videoEngine:(TTVideoEngine *)videoEngine loadStateDidChanged:(TTVideoEngineLoadState)loadState
{
    if (loadState == TTVideoEngineLoadStatePlayable) {
        [self.interactionDelegate stopLoadingAnimation];
    } else if (loadState == TTVideoEngineLoadStateStalled) {
        [self.interactionDelegate playLoadingAnimation];
    } else if (loadState == TTVideoEngineLoadStateError) {
        [self.interactionDelegate stopLoadingAnimation];
        self.loadingPlaceholder.hidden = NO;
        self.loadingPlaceholder.image = ACCResourceImage(@"img_mv_cell_damage");
    }
}

- (void)videoEngineReadyToDisPlay:(TTVideoEngine *)videoEngine
{
    self.loadingPlaceholder.hidden = YES;
    self.coverImageView.hidden = YES;
    [self.interactionDelegate stopLoadingAnimation];
}

- (void)videoEngineReadyToPlay:(TTVideoEngine *)videoEngine
{
    self.loadingPlaceholder.hidden = YES;
    self.coverImageView.hidden = YES;
    [self.interactionDelegate stopLoadingAnimation];
}

- (void)videoEngine:(TTVideoEngine *)videoEngine retryForError:(NSError *)error
{
    if (error) {
        [self.interactionDelegate stopLoadingAnimation];
        self.loadingPlaceholder.hidden = NO;
        self.loadingPlaceholder.image = ACCResourceImage(@"img_mv_cell_damage");
    }
}

- (void)videoEngineUserStopped:(TTVideoEngine *)videoEngine
{
     
}

- (void)videoEngineDidFinish:(TTVideoEngine *)videoEngine error:(NSError *)error
{
    if (error) {
        [self.interactionDelegate stopLoadingAnimation];
        self.loadingPlaceholder.hidden = NO;
        self.loadingPlaceholder.image = ACCResourceImage(@"img_mv_cell_damage");
    }
}

- (void)videoEngineStalledExcludeSeek:(TTVideoEngine *)videoEngine
{
    [self.interactionDelegate playLoadingAnimation];
}

- (void)videoEngineDidFinish:(TTVideoEngine *)videoEngine videoStatusException:(NSInteger)status
{
    
}

- (void)videoEngineCloseAysncFinish:(TTVideoEngine *)videoEngine
{
    
}

- (void)videoEngine:(nonnull TTVideoEngine *)videoEngine switchMediaInfoCompleted:(NSInteger)infoId {
    
}

#pragma mark - TTVideoEngineInternalDelegate

- (void)didFinishVideoDataDownloadForKey:(NSString *)key
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ACCMVTemplateDidFinishVideoDataDownloadNotification
                                                        object:self
                                                      userInfo:@{
                                                          ACCMVTemplateDidFinishVideoDataDownloadIDKey : @(self.templateModel.templateID),
                                                      }];
}

- (void)noVideoDataToDownloadForKey:(NSString *)key
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ACCMVTemplateDidFinishVideoDataDownloadNotification
                                                        object:self
                                                      userInfo:@{
                                                          ACCMVTemplateDidFinishVideoDataDownloadIDKey : @(self.templateModel.templateID),
                                                      }];
}

#pragma mark - ACCMVTemplateVideoPlayProtocol

- (void)playWithAnimation
{
    self.pauseByTap = YES;
    [UIView animateWithDuration:0.15
                     animations:^{
        self.playIconImageView.transform = CGAffineTransformIdentity;
        self.playIconImageView.alpha = 0;
    } completion:^(BOOL finished) {
        self.playIconImageView.hidden = YES;
    }];
    [self play];
}

- (void)pauseWithAnimation
{
    self.playIconImageView.hidden = NO;
    self.playIconImageView.transform = CGAffineTransformMakeScale(2, 2);
    [UIView animateWithDuration:0.15
                     animations:^{
        self.playIconImageView.transform = CGAffineTransformIdentity;
        self.playIconImageView.alpha = 1.0;
    }];
    [self pause];
}

#pragma mark - Getters

- (UIImageView *)loadingPlaceholder
{
    if (!_loadingPlaceholder) {
        _loadingPlaceholder = [UIImageView new];
        _loadingPlaceholder.image = ACCResourceImage(@"img_mv_cell_loading");
    }
    return _loadingPlaceholder;
}

- (UIImageView *)coverImageView
{
    if (!_coverImageView) {
        _coverImageView = [UIImageView new];
        _coverImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _coverImageView;
}

- (UIImageView *)playIconImageView
{
    if (!_playIconImageView) {
        _playIconImageView = [UIImageView new];
        _playIconImageView.image = ACCResourceImage(@"icon_mv_pause");
        _playIconImageView.hidden = YES;
    }
    return _playIconImageView;
}

@end
