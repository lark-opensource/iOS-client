//
//  ACCModernPinStickerViewController.m
//  CameraClient
//
//  Created by Pinka.
//

#import <ReactiveObjC/RACSignal+Operations.h>
#import <ReactiveObjC/NSObject+RACDeallocating.h>
#import <ReactiveObjC/RACDisposable.h>
#import <ReactiveObjC/UIControl+RACSignalSupport.h>
#import <ReactiveObjC/RACEXTScope.h>
#import "ACCModernPinStickerViewController.h"
#import <CreationKitInfra/AWEMediaSmallAnimationProtocol.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <EffectSDK_iOS/RequirementDefine.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import "ACCModernPinStickerPlayer.h"
#import "ACCPinStickerBottom.h"
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreationKitArch/VEEditorSession+ACCPreview.h>
#import "ACCEditTransitionServiceProtocol.h"
#import <CreativeKitSticker/ACCStickerContainerView.h>
#import "ACCInfoStickerContentView.h"
#import <CreativeKitSticker/ACCBaseStickerView.h>
#import "ACCStickerBizDefines.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitInfra/UIView+ACCRTL.h>

@interface ACCModernPinStickerViewController () <AWEMediaSmallAnimationProtocol, ACCPinStickerBottomSliderDelegate>

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, assign) CGFloat containerScale;
@property (nonatomic, assign) CGPoint containerCenter;
@property (nonatomic, assign) CGRect originalPlayerRect;
@property (nonatomic, strong) UIView *playerContainer;

@property (nonatomic, strong) ACCModernPinStickerPlayer *playerComponent;
@property (nonatomic, strong) ACCPinStickerBottom *bottomView;

@property (nonatomic, strong) ACCModernPinStickerViewControllerInputData *inputData;

@end

@implementation ACCModernPinStickerViewController

- (void)dealloc
{
    ACCLog(@"ACCModernPinStickerViewController --dealloc");
}

- (instancetype)initWithInputData:(ACCModernPinStickerViewControllerInputData *)inputData
{
    self = [super init];
    
    if (self) {
        _inputData = inputData;
        
        @weakify(self);
        [inputData.stickerContainerView.allStickerViews enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.config.gestureCanStartCallback = ^BOOL(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull wrapper, UIGestureRecognizer * _Nonnull gesture) {
                @strongify(self);
                [self highlightSticker:[wrapper contentView]];
                return YES;
            };
            if ([obj.contentView isKindOfClass:ACCInfoStickerContentView.class]) {
                ACCInfoStickerContentView *contentView = (id)obj.contentView;
                if (contentView.stickerId == inputData.stickerId) {
                    [self highlightSticker:contentView];
                }
            }
        }];
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
    
    [self.inputData.editService.preview resetPlayerWithViews:@[self.playerContainer]];
    [self.inputData.editService.preview seekToTime:CMTimeMake(self.inputData.currTime * 1000, 1000)];
    [self updateBottomView];
    
    [self.inputData.editService.preview setHighFrameRateRender:YES];
    [self.inputData.editService.preview setStickerEditMode:YES];
    [self.playerComponent configWhenContainerDidAppear];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.inputData.editService.preview setHighFrameRateRender:NO];
    [self.inputData.editService.preview setStickerEditMode:NO];
    [self.playerComponent configWhenContainerWillDisappear];
}

#pragma mark - Setter & Getter
- (UIView *)containerView
{
    if (!_containerView) {
        _containerView = [[UIView alloc] init];
        _containerView.backgroundColor = [UIColor clearColor];
        _containerView.accrtl_viewType = ACCRTLViewTypeNormal;
    }
    
    return _containerView;
}

- (ACCModernPinStickerPlayer *)playerComponent
{
    if (!_playerComponent) {
        _playerComponent = [[ACCModernPinStickerPlayer alloc] init];
        
        @weakify(self);
        _playerComponent.activeStickerBlock = ^(CGFloat startTime, CGFloat duration, CGFloat currTime) {
            @strongify(self);
            [self.bottomView updateSlideWithStartTime:self.inputData.startTime
                                             duration:self.inputData.duration
                                             currTime:[self.inputData.editService.preview currentPlayerTime]];
        };
    }
    
    return _playerComponent;
}

- (ACCPinStickerBottom *)bottomView
{
    if (!_bottomView) {
        _bottomView = [[ACCPinStickerBottom alloc] init];
        _bottomView.sliderDelegate = self;
        
        @weakify(self);
        [[[_bottomView.cancel
         rac_signalForControlEvents:UIControlEventTouchUpInside]
         takeUntil:[self rac_willDeallocSignal]]
         subscribeNext:^(__kindof UIControl *_Nullable x) {
             @strongify(self);
             [self cancelClicked];
         }];
        [[[_bottomView.confirm
         rac_signalForControlEvents:UIControlEventTouchUpInside]
         takeUntil:[self rac_willDeallocSignal]]
         subscribeNext:^(__kindof UIControl *_Nullable x) {
             @strongify(self);
             [self startPin];
         }];
    }
    
    return _bottomView;
}

- (UIView *)playerContainer
{
    if (!_playerContainer) {
        _playerContainer = [[UIView alloc] initWithFrame:[self mediaSmallMediaContainerFrame]];
        _playerContainer.accrtl_viewType = ACCRTLViewTypeNormal;
    }
    
    return _playerContainer;
}

#pragma mark - private methods
- (void)setupUI
{
    self.view.backgroundColor = ACCResourceColor(ACCColorBGCreation);
    self.containerView.frame = self.view.bounds;
    
    //setup
    [self setupWithInputData];

    //container
    self.containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.containerView];
    
    if (self.inputData.stickerContainerView) {
        [self configScale];
        [self.containerView addSubview:self.inputData.stickerContainerView];
        self.inputData.stickerContainerView.transform = CGAffineTransformMakeScale(self.containerScale, self.containerScale);
        CGPoint realPoint = [self.containerView convertPoint:self.playerContainer.center fromView:self.playerContainer.superview];
        self.inputData.stickerContainerView.center = realPoint;
    }

    //bottom
    [self.bottomView buildBottomViewWithContainer:self.containerView];
    [self updateBottomView];
}

- (void)setupWithInputData
{
    ACCModernPinStickerViewControllerInputData *inputData = self.inputData;
    
    [self.view insertSubview:self.playerContainer atIndex:0];

    self.originalPlayerRect = inputData.playerRect;
    [self.playerComponent setInputData:inputData];
    [self.playerComponent setPlayerContainerFrame:[self mediaSmallMediaContainerFrame] content:self.containerView];
    [self.playerComponent setInteractionImageView:inputData.interactionImageView];

    if (inputData.stickerContainerView) {
        [self configScale];
        [self.playerContainer addSubview:inputData.stickerContainerView];
        inputData.stickerContainerView.transform = CGAffineTransformMakeScale(self.containerScale, self.containerScale);
        inputData.stickerContainerView.center = self.containerCenter;
    }
}

- (void)updateBottomView
{
    [self.bottomView updateSlideWithStartTime:self.inputData.startTime
                                     duration:self.inputData.duration
                                     currTime:self.inputData.currTime];
}

- (void)cancelClicked
{
    @weakify(self);
    if (self.presentingViewController) {
        if (self.inputData.transitionService) {
            [self.inputData.transitionService dismissViewController:self completion:^{
                @strongify(self);
                [self processAfterCancel];
            }];
        } else {
            [self dismissViewControllerAnimated:YES completion:^{
                @strongify(self);
                [self processAfterCancel];
            }];
        }
    } else if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
        [self processAfterCancel];
    }
}

- (void)processAfterCancel
{
    if (self.inputData.willDismissBlock) {
        self.inputData.willDismissBlock(NO);
    }
    //should wait editorSession setSticker: finish then update sticker operation ui,this code is ugly.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.inputData.didDismissBlock) {
            self.inputData.didDismissBlock(NO);
        }
    });
}

- (void)configScale
{
    self.containerScale = 1.0;

    CGFloat standScale = 9.0 / 16.0;
    CGRect currentFrame = [self mediaSmallMediaContainerFrame];
    CGFloat currentWidth = CGRectGetWidth(currentFrame);
    CGFloat currentHeight = CGRectGetHeight(currentFrame);
    CGRect oldFrame = self.originalPlayerRect;
    CGFloat oldWidth = CGRectGetWidth(oldFrame);
    CGFloat oldHeight = CGRectGetHeight(oldFrame);

    if (currentHeight > 0.0 && oldWidth > 0.0 && oldHeight > 0.0) {
        self.containerScale = currentWidth / oldWidth;
        if (currentWidth/currentHeight < standScale-0.01) {
            self.containerScale = currentHeight / oldHeight;
        }
    }
    self.containerCenter = CGPointMake(self.playerContainer.center.x - self.playerContainer.frame.origin.x,
                                       self.playerContainer.center.y - self.playerContainer.frame.origin.y);
}

- (void)startPin
{
    ACCModernPinStickerViewControllerInputData *inputData = self.inputData;
    // 准备Pin
    [inputData.editService.sticker preparePin];
    
    __weak UIView<ACCStickerContainerProtocol> * weakContainerView = inputData.stickerContainerView;
    __block UIView<ACCLoadingViewProtocol> *loadingView = nil;
    __auto_type startPinBlock = ^{ // Start Pin
        void (^didFailedCallback)(void) = [inputData.didFailedBlock copy];
        NSInteger __block selectStickerId = NSNotFound;
        [[weakContainerView stickerViewsWithTypeId:ACCStickerTypeIdInfo] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.contentView isKindOfClass:ACCInfoStickerContentView.class]) {
                ACCInfoStickerContentView *contentView = (id)obj.contentView;
                if (contentView.isTransparent == NO) {
                    selectStickerId = contentView.stickerId;
                    *stop = YES;
                }
            }
        }];
        [inputData.editService.sticker startPin:selectStickerId
                      pinStartTime:inputData.startTime
                       pinDuration:inputData.duration completion:^(BOOL result, NSError *_Nonnull error) {
            [loadingView dismissWithAnimated:YES];
            if (result && !error) {

            } else {
                // VE SDK Bug, In the case of pin failure, the sticker will stay at the last internal calculation position; at the same time another bug is that trying to set the sticker position cannot take effect, the callback for pin failure will be triggered more than once;
                // So the temporary solution is to update the position of the sticker box
                if (didFailedCallback) {
                    didFailedCallback();
                }
            }
        }];
    };

    __auto_type didDismissBlock = ^{
        loadingView = [ACCLoading() showWindowLoadingWithTitle:ACCLocalizedString(@"creation_edit_sticker_pin_ongoing", @"Pinning...") animated:YES];
        
        if (inputData.willDismissBlock) {
            inputData.willDismissBlock(YES);
        }
        
        // 模型文件检查或下载
        NSArray<NSString *> *requirements = @[@REQUIREMENT_OBJECT_TRACKING_TAG];
        if ([EffectPlatform isRequirementsDownloaded:requirements]) {
            startPinBlock();
        } else {
            [EffectPlatform downloadRequirements:requirements completion:^(BOOL success, NSError *_Nonnull error) {
                if (success && !error) {
                    startPinBlock();
                } else {
                    // 模型下载失败
                    [loadingView dismissWithAnimated:YES];
                    [ACCToast() showError:ACCLocalizedString(@"error_and_retry", @"操作失败，请重试")];
                }
            }];
        }
        
        if (inputData.didDismissBlock) {
            inputData.didDismissBlock(YES);
        }
    };

    // dismiss到编辑页
    if (inputData.transitionService) {
        [inputData.transitionService dismissViewController:self completion:^{
            ACCBLOCK_INVOKE(didDismissBlock);
        }];
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            ACCBLOCK_INVOKE(didDismissBlock);
        }];
    }

    [self trackPropPinConfirm];
}

- (void)highlightSticker:(UIView *)sticker
{
    [self.inputData.stickerContainerView.allStickerViews enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.contentView conformsToProtocol:@protocol(ACCStickerEditContentProtocol)]) {
            UIView<ACCStickerEditContentProtocol> *cmpContent = (id)(obj.contentView);
            cmpContent.transparent = (sticker != cmpContent);
        }
    }];
    
    [self.inputData.repository.repoVideoInfo.video.infoStickers enumerateObjectsUsingBlock:^(IESInfoSticker * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isSrtInfoSticker) {
            [self.inputData.editService.sticker setSticker:obj.stickerId alpha:0.34];
        }
    }];
}

#pragma mark - AWEMediaSmallAnimationProtocol
- (UIView *)mediaSmallMediaContainer
{
    return self.playerContainer;
}

- (UIView *)mediaSmallBottomView
{
    return [self.bottomView contentView];
}

- (CGRect)mediaSmallMediaContainerFrame
{
    CGFloat playerY = [UIDevice acc_isIPhoneX] ? 44.f : 0;
    CGFloat playerHeight = [UIScreen mainScreen].bounds.size.height - self.bottomView.contentViewHeight - playerY;
    CGFloat playerWidth = self.view.frame.size.width;
    CGFloat playerX = (self.view.frame.size.width - playerWidth) * 0.5;
    CGSize videoSize = CGSizeMake(540, 960);

    CGRect playerFrame = self.inputData.repository.repoVideoInfo.playerFrame;
    if (!CGRectEqualToRect(playerFrame, CGRectZero)) {
        videoSize = playerFrame.size;
    }
    return AVMakeRectWithAspectRatioInsideRect(videoSize, CGRectMake(playerX, playerY, playerWidth, playerHeight));
}

- (CGFloat)mediaSmallBottomViewHeight
{
    return self.bottomView.contentViewHeight;
}

#pragma mark - ACCPinStickerBottomSliderDelegate
- (void)sliderDidSlideToValue:(CGFloat)value
{
    CGFloat progress = value;
    CGFloat aimedTime = self.inputData.startTime + self.inputData.duration * progress;
    
    [self.inputData.editService.preview seekToTime:CMTimeMake(aimedTime * 1000, 1000)];
    [self.inputData.stickerContainerView.allStickerViews enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj updateWithCurrentPlayerTime:aimedTime];
    }];
}

#pragma mark - Track
- (void)trackPropPinConfirm
{
    NSMutableDictionary *params = @{}.mutableCopy;
    params[@"shoot_way"] = self.inputData.repository.repoTrack.referString ? : @"";
    params[@"enter_from"] = @"video_edit_page";
    params[@"creation_id"] = self.inputData.repository.repoContext.createId ? : @"";
    params[@"content_source"] = self.inputData.repository.repoTrack.referExtra[@"content_source"] ? : @"";
    params[@"content_type"] = self.inputData.repository.repoTrack.referExtra[@"content_type"] ? : @"";
    params[@"prop_id"] = self.inputData.stickerInfos.userInfo[@"stickerID"] ? : @"";
    params[@"is_diy_prop"] = @(self.inputData.isCustomUploadSticker);
    [ACCTracker() trackEvent:@"prop_pin_confirm" params:params.copy needStagingFlag:NO];
}

@end
