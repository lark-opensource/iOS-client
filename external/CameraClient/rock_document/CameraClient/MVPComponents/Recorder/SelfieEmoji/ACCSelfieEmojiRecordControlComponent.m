//
//  ACCSelfieEmojiRecordControlComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by liujingchuan on 2021/8/29.
//

#import <Masonry/Masonry.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIFont+ACCAdditions.h>
#import "ACCSelfieEmojiRecordControlComponent.h"
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CameraClient/AWECameraPreviewContainerView.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <TTVideoEditor/IESMMAlgorithmResultData.h>
#import <TTReachability/TTReachability.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <ByteDanceKit/NSSet+BTDAdditions.h>
#import "ACCSelfieImageProcessAndUploadService.h"
#import <ByteDanceKit/NSTimer+BTDAdditions.h>
#import "ACCSelfieCloseComponentService.h"
#import <BDWebImage/BDImageCache.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CameraClient/ACCIMModuleServiceProtocol.h>
#import <CameraClient/ACCAPPSettingsProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>

#define kSelfieMemeFaceViewWidth 240.f
#define kSelfieMemeFaceViewHeight 300.f

NSString *const kACCSelfieLastImageCacheKeyPrefix = @"kSelfieLastImageCacheKeyPrefix";
NSString *const KACCXmojiIsGeneratingKey = @"KACCXmojiIsGeneratingKey";

///页面状态
typedef NS_ENUM(NSUInteger, ACCSelfieEmojiPageStage) {
    ACCSelfieEmojiPageStageRecordDisable,
    ACCSelfieEmojiPageRecordEnable,
    ACCSelfieEmojiPageStageDidTapShoot,
    ACCSelfieEmojiPageStageRetry,
    ACCSelfieEmojiPageStageGenerating
};

///表情生成进度
typedef NS_ENUM(NSUInteger, ACCSelfieEmojiProcessState) {
    ///初始状态
    ACCSelfieEmojiProcessUploadUndefined,
    ///上传失败
    ACCSelfieEmojiProcessUploadFailed,
    ///上传成功
    ACCSelfieEmojiProcessUploadSucceed,
    ///审核失败
    ACCSelfieEmojiProcessReviewFailed,
    ///上传成功后，生成失败
    ACCSelfieEmojiProcessGenerateFailed,
    ///上传成功，生成也成功
    ACCSelfieEmojiProcessGeneratesucceed
};

typedef NS_ENUM(NSInteger, ACCSelfieMemeCameraViewTipsLabelStateType) {
    ///满足拍照条件
    ACCSelfieMemeCameraViewTipsLabelStateTypeNormal,
    ///框内未识别到人脸
    ACCSelfieMemeCameraViewTipsLabelStateTypeHasNoFace,
    ///脸部不完全在取景框有效区域内
    ACCSelfieMemeCameraViewTipsLabelStateTypeOutsideCorrectFaceArea,
    ///角度置信度小于0.95
    ACCSelfieMemeCameraViewTipsLabelStateTypeFaceLowScore,
    ///人脸高度小于圆形半径的 1/2
    ACCSelfieMemeCameraViewTipsLabelStateTypeShotDistanceTooFar
};

@interface ACCSelfieEmojiRecordControlComponent() <ACCAlgorithmEvent, ACCCameraLifeCircleEvent, ACCSelfieCloseComponentService>

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCSelfieImageProcessAndUploadProtocol> imageProcesser;
@property (nonatomic, strong) UIImageView *faceImageView;
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) UIButton *recordBtn;
@property (nonatomic, strong) UIButton *usePhotoBtn;
@property (nonatomic, strong) UIControl *backControl;
@property (nonatomic, strong) UIButton *retryBtn;
@property (nonatomic, strong) UILabel *errorLabel;
@property (nonatomic, strong) UIProgressView *progressLine;
@property (nonatomic, strong) UILabel *generatingLabel;
@property (nonatomic, assign) ACCSelfieEmojiPageStage currentPageStage;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, assign) CGRect correctFaceAreaFrameRect;
@property (nonatomic, strong) NSMutableSet<NSString *> *tipsLabelTextSet;
@property (nonatomic, strong) UIImageView *previewImageView;
@property (nonatomic, strong) UIImage *photo;
@property (nonatomic, assign) BOOL didClickShoot;
@property (nonatomic, assign) BOOL fakeProgressCompleted;
@property (nonatomic, assign) BOOL isDidEnterBackground;
@property (nonatomic, assign) ACCSelfieEmojiProcessState generateState;
@property (nonatomic, assign) BOOL isGenerating;//是否正在生成过程中（上传中，或者拉取中）
@property (nonatomic, strong) NSTimer *waitingTimer;

@end

@implementation ACCSelfieEmojiRecordControlComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService);


- (void)componentDidMount {
    [self setupUI];
    [self p_addObservers];
    self.imageProcesser = [[ACCSelfieImageProcessAndUploadService alloc] init];
    self.tipsLabelTextSet = [[NSMutableSet alloc] init];
    self.currentPageStage = ACCSelfieEmojiPageStageRecordDisable;
}

- (void)componentDidUnmount {
    [self p_stopWaitingTimer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)componentDidAppear {
    [self p_restoreLastStatusIfNeeded];
}

/// 恢复之前的状态，如果上次是被取消的话
- (void)p_restoreLastStatusIfNeeded {
    if ([ACCCache() boolForKey:KACCXmojiIsGeneratingKey]) {
        self.photo = [[BDImageCache sharedImageCache] imageForKey:kACCSelfieLastImageCacheKeyPrefix];
        if (self.photo) {
            ACCLog(@"【Xmoji-Generate】有图，恢复之前的状态");
            self.didClickShoot = YES;
            self.previewImageView.image = self.photo;
            [self.cameraService.cameraControl stopVideoCapture];
            [self useThisImageAction:nil];
        }
    }
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase {
    return ACCFeatureComponentLoadPhaseEager;
}

- (NSArray<ACCServiceBinding *> *)serviceBindingArray {
    return @[ACCCreateServiceBinding(@protocol(ACCSelfieCloseComponentService), self)];
}

- (void)p_addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_enterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_enterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)p_enterBackground:(NSNotification *)notification {
    self.isDidEnterBackground = YES;
    [self.cameraService.cameraControl pauseCameraCapture];
}

- (void)p_enterForeground:(NSNotification *)notification {
    [self.cameraService.cameraControl startVideoCapture];
    if (self.isDidEnterBackground && self.generateState == ACCSelfieEmojiProcessGeneratesucceed) {
        self.progressLine.progress = 1.f;
        [UIView animateWithDuration:1 delay:0.2 options:UIViewAnimationOptionCurveLinear animations:^{
            [self.progressLine layoutIfNeeded];
        } completion:^(BOOL finished) {
            [ACCToast() show:@"已更新全部自拍表情"];
            [self.controller close];
        }];
        self.isDidEnterBackground = NO;
    }
}

- (void)setupUI {
    UIView *container = self.viewContainer.interactionView;
    self.previewImageView = [[UIImageView alloc] init];
    self.previewImageView.contentMode = UIViewContentModeScaleAspectFill;
    [container addSubview:self.previewImageView];
    [self.previewImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.cameraService.cameraPreviewView);
    }];
    [self p_addGradient];

    self.faceImageView = [[UIImageView alloc] init];
    self.faceImageView.image = ACCResourceImage(@"ic_selfie_emoji_record_disabled");
    self.faceImageView.contentMode = UIViewContentModeScaleAspectFit;
    [container addSubview:self.faceImageView];
    [self.faceImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(kSelfieMemeFaceViewWidth);
        make.height.mas_equalTo(kSelfieMemeFaceViewHeight);
        make.centerX.mas_equalTo(container);
        make.top.mas_equalTo(0.18 * [UIScreen mainScreen].bounds.size.height);
    }];

    self.recordBtn = [[UIButton alloc] init];
    [self.recordBtn setImage:ACCResourceImage(@"btn_selfie_record_enable") forState:UIControlStateNormal];
    [self.recordBtn setImage:ACCResourceImage(@"btn_selfie_record_disable") forState:UIControlStateDisabled];
    self.recordBtn.enabled = NO;
    [self.recordBtn addTarget:self action:@selector(recordBtnDidClick:) forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:self.recordBtn];
    [self.recordBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(96);
        make.bottom.mas_equalTo(self.cameraService.cameraPreviewView.mas_bottom).mas_offset(-40);
        make.centerX.mas_equalTo(container);
    }];

    self.tipsLabel = [[UILabel alloc] init];
    self.tipsLabel.font = [UIFont acc_systemFontOfSize:17];
    self.tipsLabel.text = @"未检测到人脸";
    self.tipsLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
    self.tipsLabel.textAlignment = NSTextAlignmentCenter;
    [container addSubview:self.tipsLabel];
    [self.tipsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(container);
        make.left.right.mas_equalTo(container);
        make.bottom.mas_equalTo(self.recordBtn.mas_top).mas_offset(-12);
    }];

    self.usePhotoBtn = [[UIButton alloc] init];
    [self.usePhotoBtn setTitle:@"使用此照片" forState:UIControlStateNormal];
    self.usePhotoBtn.backgroundColor = ACCResourceColor(ACCColorPrimary);
    self.usePhotoBtn.titleLabel.font = [UIFont acc_systemFontOfSize:15];
    [self.usePhotoBtn setTitleColor:ACCResourceColor(ACCColorConstTextInverse) forState:UIControlStateNormal];
    [self.usePhotoBtn addTarget:self action:@selector(useThisImageAction:) forControlEvents:UIControlEventTouchUpInside];
    self.usePhotoBtn.layer.cornerRadius = 2;
    self.usePhotoBtn.clipsToBounds = YES;
    [container addSubview:self.usePhotoBtn];
    [self.usePhotoBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(44);
        make.left.mas_equalTo(16);
        make.right.mas_equalTo(-16);
        make.bottom.mas_equalTo(self.cameraService.cameraPreviewView.mas_bottom).mas_offset(-77);
    }];

    self.backControl = [[UIControl alloc] init];
    [self.backControl addTarget:self action:@selector(retryAction:) forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:self.backControl];
    [self.backControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(44);
        make.width.mas_equalTo(148);
        make.centerX.mas_equalTo(container);
        make.top.mas_equalTo(self.usePhotoBtn.mas_bottom).mas_offset(12);
    }];

    UIImageView *backImgView = [[UIImageView alloc] init];
    backImgView.image = ACCResourceImage(@"ic_edit_withdraw");
    [self.backControl addSubview:backImgView];
    [backImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(20);
        make.centerY.mas_equalTo(self.backControl);
        make.left.mas_equalTo(29);
    }];

    UILabel *backLabel = [[UILabel alloc] init];
    backLabel.font = [UIFont acc_systemFontOfSize:15];
    backLabel.text = @"重新拍摄";
    backLabel.textAlignment = NSTextAlignmentCenter;
    backLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
    [self.backControl addSubview:backLabel];
    [backLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.backControl);
        make.left.mas_equalTo(backImgView.mas_right).mas_offset(8);
    }];

    self.retryBtn = [[UIButton alloc] init];
    [self.retryBtn setBackgroundColor:ACCResourceColor(ACCColorConstBGContainer5)];
    [self.retryBtn setTitle:@"返回重拍" forState:UIControlStateNormal];
    [self.retryBtn.titleLabel setFont:[UIFont acc_systemFontOfSize:15]];
    self.retryBtn.layer.cornerRadius = 2;
    self.retryBtn.clipsToBounds = YES;
    [self.retryBtn addTarget:self action:@selector(retryAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.retryBtn setTitleColor:ACCResourceColor(ACCColorConstTextInverse) forState:UIControlStateNormal];
    [container addSubview:self.retryBtn];
    [self.retryBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(44);
        make.width.mas_equalTo(343);
        make.centerX.mas_equalTo(container);
        make.bottom.mas_equalTo(self.cameraService.cameraPreviewView.mas_bottom).mas_offset(-77);
    }];

    self.errorLabel = [[UILabel alloc] init];
    self.errorLabel.font = [UIFont acc_systemFontOfSize:15];
    self.errorLabel.text = @"未通过校验，请重新拍摄";
    self.errorLabel.textAlignment = NSTextAlignmentCenter;
    self.errorLabel.textColor = ACCResourceColor(ACCColorConstTextInverse3);
    [container addSubview:self.errorLabel];
    [self.errorLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(container);
        make.left.right.mas_equalTo(container);
        make.top.mas_equalTo(self.retryBtn.mas_bottom).mas_offset(24);
    }];

    self.progressLine = [[UIProgressView alloc] init];
    self.progressLine.progressTintColor = ACCResourceColor(ACCColorConstTextInverse);
    self.progressLine.trackTintColor = ACCResourceColor(ACCColorConstLineInverse);
    self.progressLine.progress = 0.f;
    self.progressLine.layer.cornerRadius = 3.f;
    self.progressLine.layer.masksToBounds = YES;
    [container addSubview:self.progressLine];
    [self.progressLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(6);
        make.left.mas_equalTo(16);
        make.right.mas_equalTo(-16);
        make.top.mas_equalTo(self.faceImageView.mas_bottom).mas_offset(200);
    }];

    self.generatingLabel = [[UILabel alloc] init];
    self.generatingLabel.text = @"正在生成表情...";
    self.generatingLabel.font = [UIFont acc_systemFontOfSize:15];
    self.generatingLabel.textAlignment = NSTextAlignmentCenter;
    self.generatingLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
    [container addSubview:self.generatingLabel];
    [self.generatingLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(container);
        make.left.right.mas_equalTo(container);
        make.top.mas_equalTo(self.progressLine.mas_bottom).mas_offset(24);
    }];

}

- (void)p_addGradient {
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.frame = CGRectMake(0, CGRectGetMaxY(self.cameraService.cameraPreviewView.frame) - 240, ACC_SCREEN_WIDTH, 240);
    self.gradientLayer.colors = @[(__bridge id)[UIColor colorWithRed:0 green:0 blue:0 alpha:0].CGColor,
                                  (__bridge id)[UIColor colorWithRed:0 green:0 blue:0 alpha:0.75].CGColor];
    self.gradientLayer.startPoint = CGPointMake(0.5, 0);
    self.gradientLayer.endPoint = CGPointMake(0.5, 1);
    self.gradientLayer.locations = @[@0, @1];
    [self.viewContainer.interactionView.layer addSublayer:self.gradientLayer];
    [self.viewContainer.interactionView.layer insertSublayer:self.gradientLayer above:self.cameraService.cameraPreviewView.layer];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.cameraService addSubscriber:self];
    [self.cameraService.algorithm appendAlgorithm:0x02 * 0x1000000000 | IESMMAlgorithm_AgeAndGenderAndHumanDetect | IESMMAlgorithm_FaceDetect];
    [self.cameraService.algorithm addSubscriber:self];
}

- (void)p_startWaitingTimer {
    NSTimeInterval duration = [ACCAPPSettings() xmojiGeneratePollTimeoutDuration];
    @weakify(self);
    _waitingTimer = [NSTimer btd_scheduledTimerWithTimeInterval:duration repeats:NO block:^(NSTimer * _Nonnull timer) {
        @strongify(self);
        if (self.generateState != ACCSelfieEmojiProcessGeneratesucceed) {
            [ACCToast() show:@"网络状况不佳，请等待"];
        }
    }];
}

- (void)p_stopWaitingTimer {
    [self.waitingTimer invalidate];
    self.waitingTimer = nil;
}

///手动点击关闭，取消
- (void)didClickCloseBtn:(UIButton *)btn {
    ACCLog(@"【Xmoji-Generate】点击关闭");
    [ACCTracker() trackEvent:@"xmoji_shoot" params:@{@"action_type" : @"close"}];
    [self p_stopWaitingTimer];
    ///还在上传过程中，或者在生成过程中
    if (self.isGenerating) {
        [ACCToast() show:@"表情包继续生成..."];
        ///存图片到本地，下次打开直接使用
        [[BDImageCache sharedImageCache] setImage:self.photo forKey:kACCSelfieLastImageCacheKeyPrefix];
        [ACCCache() setBool:YES forKey:KACCXmojiIsGeneratingKey];
    }
}

#pragma mark - ACCAlgorithmEvent

- (void)onExternalAlgorithmCallback:(NSArray<IESMMAlgorithmResultData *> *)result type:(IESMMAlgorithm)type {
    if (self.didClickShoot) {
        return;
    }
    self.correctFaceAreaFrameRect = self.faceImageView.frame;
    CGFloat cameraViewWidth = self.cameraService.cameraPreviewView.bounds.size.width;
    CGFloat cameraViewHeight = self.cameraService.cameraPreviewView.bounds.size.height;
    if (type == IESMMAlgorithm_FaceDetect) {
        if (result.count == 0) {
            [self updateCurrentTipLable:ACCSelfieMemeCameraViewTipsLabelStateTypeHasNoFace];
        } else {
            for (IESMMAlgorithmResultData *data in result) {
                IESMMFaceDetectResultData *faceInfoData = ACCDynamicCast(data, IESMMFaceDetectResultData);
                if (faceInfoData) {
                    //置信度
                    if (faceInfoData.score < 0.95) {
                        [self updateCurrentTipLable:ACCSelfieMemeCameraViewTipsLabelStateTypeFaceLowScore];
                    } else {
                        [self removeCurrentTipLable:ACCSelfieMemeCameraViewTipsLabelStateTypeFaceLowScore];
                    }
                    CGRect facePositionFrame = CGRectMake(faceInfoData.originX / faceInfoData.bufferWidth * cameraViewWidth,
                                                          faceInfoData.originY / faceInfoData.bufferHeight * cameraViewHeight,
                                                          faceInfoData.width / faceInfoData.bufferWidth * cameraViewWidth,
                                                          faceInfoData.height / faceInfoData.bufferHeight * cameraViewHeight);

                    //人脸区域面积
                    CGFloat faceAreaSquare = facePositionFrame.size.width * facePositionFrame.size.height;
                    //人脸高度是否小于取景框一半
                    if (facePositionFrame.size.height < kSelfieMemeFaceViewHeight / 2) {
                        [self updateCurrentTipLable:ACCSelfieMemeCameraViewTipsLabelStateTypeShotDistanceTooFar];
                    } else {
                        [self removeCurrentTipLable:ACCSelfieMemeCameraViewTipsLabelStateTypeShotDistanceTooFar];
                    }
                    //框内是否有人脸
                    if (!CGRectIntersectsRect(facePositionFrame, self.correctFaceAreaFrameRect)) {
                        //人脸区域和取景框有效区域没有交集
                        [self updateCurrentTipLable:ACCSelfieMemeCameraViewTipsLabelStateTypeHasNoFace];
                    } else {
                        //有相交区域，计算相交区域矩形和面积
                        CGRect chongheRect = CGRectIntersection(facePositionFrame, self.correctFaceAreaFrameRect);
                        CGFloat IntersectionArea = chongheRect.size.width * chongheRect.size.height;
                        CGFloat IntersectionAreaRatio = IntersectionArea / faceAreaSquare;
                        [self removeCurrentTipLable:ACCSelfieMemeCameraViewTipsLabelStateTypeHasNoFace];
                        if (IntersectionAreaRatio < 0.85) {
                            [self updateCurrentTipLable:ACCSelfieMemeCameraViewTipsLabelStateTypeOutsideCorrectFaceArea];
                        } else {
                            [self removeCurrentTipLable:ACCSelfieMemeCameraViewTipsLabelStateTypeOutsideCorrectFaceArea];
                        }
                    }
                }
            }
        }
    }
}

- (void)updateCurrentTipLable:(ACCSelfieMemeCameraViewTipsLabelStateType)type {
    NSString *text = @"";
    switch (type) {
        case ACCSelfieMemeCameraViewTipsLabelStateTypeNormal:
            text = @"请点击拍照";
            break;
        case ACCSelfieMemeCameraViewTipsLabelStateTypeHasNoFace:
            text = @"未识别到人脸";
            break;
        case ACCSelfieMemeCameraViewTipsLabelStateTypeOutsideCorrectFaceArea:
            text = @"请把脸移入框内";
            break;
        case ACCSelfieMemeCameraViewTipsLabelStateTypeFaceLowScore:
            text = @"请正对镜头";
            break;
        case ACCSelfieMemeCameraViewTipsLabelStateTypeShotDistanceTooFar:
            text = @"请将镜头拿近一点";
            break;
    }
    if (text.length > 0) {
        self.currentPageStage = ACCSelfieEmojiPageStageRecordDisable;
        self.tipsLabel.text = text;
        [self.tipsLabelTextSet btd_addObject:text];
    }
}

- (void)removeCurrentTipLable:(ACCSelfieMemeCameraViewTipsLabelStateType)type {
    NSString *text = @"";
    switch (type) {
        case ACCSelfieMemeCameraViewTipsLabelStateTypeNormal:
            text = @"请点击拍照";
            break;
        case ACCSelfieMemeCameraViewTipsLabelStateTypeHasNoFace:
            text = @"未识别到人脸";
            break;
        case ACCSelfieMemeCameraViewTipsLabelStateTypeOutsideCorrectFaceArea:
            text = @"请把脸移入框内";
            break;
        case ACCSelfieMemeCameraViewTipsLabelStateTypeFaceLowScore:
            text = @"请正对镜头";
            break;
        case ACCSelfieMemeCameraViewTipsLabelStateTypeShotDistanceTooFar:
            text = @"请将镜头拿近一点";
            break;
    }
    if (text.length > 0) {
        [self.tipsLabelTextSet btd_removeObject:text];
    }
    if (self.tipsLabelTextSet.count == 0) {
        self.currentPageStage = ACCSelfieEmojiPageRecordEnable;
        self.tipsLabel.text = @"请点击拍照";
    } else {
        NSString *tip = [self.tipsLabelTextSet anyObject];
        self.currentPageStage = ACCSelfieEmojiPageStageRecordDisable;
        self.tipsLabel.text = tip.length > 0 ? tip : @"";
    }
}

#pragma mark - Actions

- (void)recordBtnDidClick:(UIButton *)sender {
    self.cameraService.recorder.cameraMode = HTSCameraModePhoto;
    [ACCTracker() trackEvent:@"xmoji_shoot" params:@{@"action_type" : @"shoot"}];
    [self takePicture];
}

//预览完成，使用此照片，进入生成流程
- (void)useThisImageAction:(UIButton *)sender {
    [ACCTracker() trackEvent:@"xmoji_shoot" params:@{@"action_type" : @"generate"}];
    if (![TTReachability isNetworkConnected]) {
        [ACCToast() show:@"无法生成，请检查网络情况"];
        return;
    }
    [self p_startWaitingTimer];
    self.isGenerating = YES;
    self.currentPageStage = ACCSelfieEmojiPageStageGenerating;
    @weakify(self);
    [self.imageProcesser uploadImage:self.photo andVerfyWithCompletion:^(NSError * _Nonnull error, ACCUploadFaceResultType type) {
        @strongify(self);
        if (error || type == ACCUploadFaceResultTypeReviewFailed || type == ACCUploadFaceResultTypeUploadFailed) {
            if (type == ACCUploadFaceResultTypeReviewFailed) {
                self.generateState = ACCSelfieEmojiProcessReviewFailed;
                ACCLog(@"【Xmoji-Generate】上传图片，审核失败");
            } else {
                self.generateState = ACCSelfieEmojiProcessUploadFailed;
                ACCLog(@"【Xmoji-Generate】上传图片，上传失败");
            }
            self.currentPageStage = ACCSelfieEmojiPageStageRetry;
            self.isGenerating = NO;
            [ACCCache() setBool:NO forKey:KACCXmojiIsGeneratingKey];
            [ACCTracker() trackEvent:@"xmoji_generate" params:@{@"is_success" : @(0)}];
            [self p_stopWaitingTimer];
        } else {
            self.generateState = ACCSelfieEmojiProcessUploadSucceed;
            ///拉取列表，同时也是 AILab 生成表情的过程
            [self fetchEmojiList];
        }
    }];
    [self doFakeProgressAnimationComplete:nil];
}

- (void)doFakeProgressAnimationComplete:(void(^)(void))completion {
    self.progressLine.progress = 0.8f;
    NSTimeInterval duration = [ACCAPPSettings() xmojiGenerateProgressLineMinTime];
    [UIView animateWithDuration:duration > 1 ? duration - 1 : 4 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        [self.progressLine layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.fakeProgressCompleted = YES;
        ACCBLOCK_INVOKE(completion);
    }];
}

- (void)fetchEmojiList {
    @weakify(self);
    [IESAutoInline(ACCBaseServiceProvider(), ACCIMModuleServiceProtocol) updateXmojiInfoIfNeededOnCompletion:^(BOOL updated, ACCIMXmojiPullStatus status) {
        @strongify(self);
        self.isGenerating = NO;
        [ACCCache() setBool:NO forKey:KACCXmojiIsGeneratingKey];
        [self p_stopWaitingTimer];
        if (status == ACCIMXmojiPullStatusFailed || status == ACCIMXmojiPullStatusTimeout) {
            self.generateState = ACCSelfieEmojiProcessGenerateFailed;
            self.currentPageStage = ACCSelfieEmojiPageStageRetry;
            ACCLog(@"【Xmoji-Generate】拉取列表，拉取失败");
            [ACCTracker() trackEvent:@"xmoji_generate" params:@{@"is_success" : @(0)}];
            ///如果正在生成的话，需要重试，2s 之后重试
        } else if (status == ACCIMXmojiPullStatusInProgress) {
            ACCLog(@"【Xmoji-Generate】拉取列表，生成中，继续重试");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self fetchEmojiList];
            });
        } else {
            [[BDImageCache sharedImageCache] removeImageForKey:kACCSelfieLastImageCacheKeyPrefix];
            self.generateState = ACCSelfieEmojiProcessGeneratesucceed;
            self.progressLine.progress = 1.f;
            [ACCTracker() trackEvent:@"xmoji_generate" params:@{@"is_success" : @(1)}];
            ACCLog(@"【Xmoji-Generate】拉取列表，拉取成功");
            if (!self.isDidEnterBackground) {
                [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    [self.progressLine layoutIfNeeded];
                } completion:^(BOOL finished) {
                    [ACCToast() show:@"已更新全部自拍表情"];
                    [self.controller close];
                }];
            } else {
                [self.progressLine layoutIfNeeded];
            }
        }

    }];
}

- (void)retryAction:(UIButton *)sender {
    if (self.currentPageStage == ACCSelfieEmojiPageStageRetry) {
        [ACCTracker() trackEvent:@"xmoji_shoot" params:@{@"action_type" : @"fail_retake"}];
    } else {
        [ACCTracker() trackEvent:@"xmoji_shoot" params:@{@"action_type" : @"retake"}];
    }
    self.didClickShoot = NO;
    self.currentPageStage = ACCSelfieEmojiPageStageRecordDisable;
    self.previewImageView.image = nil;
    [self.cameraService.cameraControl startVideoCapture];
}

- (void)takePicture {
    if (self.cameraService.recorder.isRecording) {
        ACCLog(@"【Xmoji-Generate】点击拍摄，recorder is recording 直接 return");
        return;
    }
    if (self.cameraService.recorder.cameraMode != HTSCameraModePhoto) {
        ACCLog(@"【Xmoji-Generate】点击拍摄，cameraMode 不是 photo 直接 return");
        return;
    }
    @weakify(self);
    [self.cameraService.recorder captureStillImageWithCompletion:^(UIImage * _Nonnull processedImage, NSError * _Nonnull error) {
        @strongify(self);
        if (error == nil) {
            acc_dispatch_main_async_safe(^{
                self.photo = processedImage;
                self.previewImageView.image = processedImage;
                [self.cameraService.cameraControl stopVideoCapture];
                self.currentPageStage = ACCSelfieEmojiPageStageDidTapShoot;
                self.didClickShoot = YES;
            });
        } else {
            ACCLog(@"%@", [NSString stringWithFormat:@"【Xmoji-Generate】点击拍摄，拍摄失败 %@", error.localizedDescription]);
        }
    }];
}

- (void)setCurrentPageStage:(ACCSelfieEmojiPageStage)currentPageStage {
    _currentPageStage = currentPageStage;
    switch (currentPageStage) {
        case ACCSelfieEmojiPageStageRecordDisable:
            self.tipsLabel.hidden = NO;
            self.recordBtn.hidden = NO;
            self.usePhotoBtn.hidden = YES;
            self.backControl.hidden = YES;
            self.retryBtn.hidden = YES;
            self.errorLabel.hidden = YES;
            self.progressLine.hidden = YES;
            self.recordBtn.enabled = NO;
            self.generatingLabel.hidden = YES;
            self.faceImageView.image = ACCResourceImage(@"ic_selfie_emoji_record_disabled");
            break;
        case ACCSelfieEmojiPageRecordEnable:
            self.tipsLabel.hidden = NO;
            self.recordBtn.hidden = NO;
            self.usePhotoBtn.hidden = YES;
            self.backControl.hidden = YES;
            self.retryBtn.hidden = YES;
            self.errorLabel.hidden = YES;
            self.progressLine.hidden = YES;
            self.recordBtn.enabled = YES;
            self.generatingLabel.hidden = YES;
            self.faceImageView.image = ACCResourceImage(@"ic_selfie_emoji_record_enabled");
            break;
        case ACCSelfieEmojiPageStageDidTapShoot:
            self.tipsLabel.hidden = YES;
            self.recordBtn.hidden = YES;
            self.usePhotoBtn.hidden = NO;
            self.backControl.hidden = NO;
            self.retryBtn.hidden = YES;
            self.errorLabel.hidden = YES;
            self.progressLine.hidden = YES;
            self.generatingLabel.hidden = YES;
            self.faceImageView.image = ACCResourceImage(@"ic_selfie_emoji_record_enabled");
            break;
        case ACCSelfieEmojiPageStageRetry:
            self.tipsLabel.hidden = YES;
            self.recordBtn.hidden = YES;
            self.usePhotoBtn.hidden = YES;
            self.backControl.hidden = YES;
            self.retryBtn.hidden = NO;
            self.errorLabel.hidden = NO;
            if (self.generateState == ACCSelfieEmojiProcessGenerateFailed) {
                self.errorLabel.text = @"生成失败，请重新拍摄";
            } else if (self.generateState == ACCSelfieEmojiProcessReviewFailed) {
                self.errorLabel.text = @"未通过校验，请重新拍摄";
            }
            self.progressLine.progress = 0.f;
            [self.progressLine layoutIfNeeded];
            self.progressLine.hidden = YES;
            self.generatingLabel.hidden = YES;
            self.faceImageView.image = ACCResourceImage(@"ic_selfie_emoji_record_disabled");
            break;
        case ACCSelfieEmojiPageStageGenerating:
            self.tipsLabel.hidden = YES;
            self.recordBtn.hidden = YES;
            self.usePhotoBtn.hidden = YES;
            self.backControl.hidden = YES;
            self.retryBtn.hidden = YES;
            self.errorLabel.hidden = YES;
            self.progressLine.hidden = NO;
            self.generatingLabel.hidden = NO;
            self.faceImageView.image = ACCResourceImage(@"ic_selfie_emoji_record_enabled");
            break;
    }
}

@end
