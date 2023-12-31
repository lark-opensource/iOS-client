//
//  AWEAutoCaptionsViewController.m
//  Pods
//
//  Created by li xingdong on 2019/8/23.
//

#import "AWERepoCaptionModel.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEAutoCaptionsViewController.h"
#import "AWEAudioExport.h"
#import "AWEStudioCaptionsManager.h"
#import "AWECaptionBottomView.h"
#import "AWEAutoCaptionsEditViewController.h"
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import "ACCStickerContainerView+CameraClient.h"
#import "ACCStickerBizDefines.h"
#import "ACCAutoCaptionsTextStickerView.h"
#import "AWEEditorStickerGestureViewController.h"
#import "ACCConfigKeyDefines.h"
#import <CreationKitArch/ACCRepoContextModel.h>

#import <CreationKitInfra/ACCAlertProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitArch/ACCCustomFontProtocol.h>
#import <CameraClient/ACCViewControllerProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CameraClient/ACCDraftProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>
#import <CreativeKitSticker/ACCStickerContainerView.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <CreationKitInfra/UIView+ACCRTL.h>

#import <CameraClient/ACCConfigKeyDefines.h>
#import "AWECaptionBottomOptimizedView.h"
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CameraClient/AWERepoDraftModel.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

static CGFloat const kAWEAutoCaptionsTopButtonHeight = 44;
static CGFloat const kCorrectedValue = 0.5;
static NSInteger const kInvalidIndex = -1;
static NSInteger const kRequestTimeout = -1001;

@interface AWEAutoCaptionsViewController ()<UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, AWECaptionScrollFlowLayoutDelegate, ACCEditPreviewMessageProtocol>

@property (nonatomic, strong) AWEVideoPublishViewModel *repository;

@property (nonatomic, strong) AWEStoryTextContainerView *textContainerView;
@property (nonatomic, strong) ACCStickerContainerView *stickerContainerView;

@property (nonatomic, assign) BOOL isPlaying;

@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIButton *saveBtn;
@property (nonatomic, strong) UIView *playerContainer;
@property (nonatomic, strong) UIButton *stopAndPlayBtn;
@property (nonatomic, strong) UIImageView *stopAndPlayImageView;
@property (nonatomic, strong) AWECaptionBottomView *bottomView;

@property (nonatomic, assign) CGRect originalPlayerRect;
@property (nonatomic, assign) CGFloat containerScale;
@property (nonatomic, assign) CGPoint containerCenter;

@property (nonatomic, strong) AWEAudioExport *audioExport;
@property (nonatomic, strong) AWEStudioCaptionsManager *captionManager;

@property (nonatomic, strong) AWEEditorStickerGestureViewController *stickerGestureController;

@property (nonatomic, assign) BOOL backupIsPlaying;
@property (nonatomic, assign) BOOL needRestorePlayer;
@property (nonatomic, assign) BOOL enterEditMode;
@property (nonatomic, assign) BOOL seekTimeFinished;

@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) NSString *captionMD5;

@property (nonatomic, assign) CGFloat requestStartTime;
@property (nonatomic, assign) BOOL isRetry;
@property (nonatomic, assign) BOOL playerHasReset;

@end

@implementation AWEAutoCaptionsViewController

- (void)dealloc {
    AWELogToolDebug(AWELogToolTagEdit, @"%@ dealloc",[self class]);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    NSAssert(NO, @"请使用initWithModel:player:");
    return nil;
}

- (instancetype)initWithRepository:(AWEVideoPublishViewModel *)repository
                     containerView:(ACCStickerContainerView *)containerView
                originalPlayerRect:(CGRect)playerRect
                    captionManager:(AWEStudioCaptionsManager *)captionManager
{
    self = [super init];
    if (self) {
        _repository = repository;
        _originalPlayerRect = playerRect;
        _stickerContainerView = containerView;
        _captionManager = captionManager;
        _backupIsPlaying = YES;
        _seekTimeFinished = YES;
        [_captionManager backupCaptionData];
        _captionMD5 = [self.captionManager.captionInfo md5];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [ACCViewControllerService() viewController:self setDisableFullscreenPopTransition:YES];
    [ACCViewControllerService() viewController:self setPrefersNavigationBarHidden:YES];
    self.view.backgroundColor = ACCResourceColor(ACCColorBGCreation);
    
    [self buildViews];
    [self buildPlayer];
    
    // 更新贴纸以及容器事件
    [self changeStickerContainerAction];
    
    // upload audio and query captions
    [self commitAndQueryCaption];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.stopAndPlayBtn.hidden = YES;
    
    if (!self.playerHasReset) {
        if (self.previewService) {
            [self.previewService resetPlayerWithViews:@[self.playerContainer]];
            [self.previewService seekToTime:kCMTimeZero];
            [self.previewService setStickerEditMode:!self.isPlaying];
        }
        self.playerHasReset = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.stopAndPlayBtn.hidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.isRetry = NO;
    
    if (self.enterEditMode) {
        if (self.isPlaying) {
            if (self.previewService) {
                [self.previewService setStickerEditMode:YES];
            }
            self.backupIsPlaying = YES;
            self.isPlaying = NO;
        }
    } else {
        if (self.previewService) {
            [self.previewService setStickerEditMode:NO];
            [self.previewService seekToTime:kCMTimeZero];
        }
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

#pragma mark - Init UI

- (void)buildViews
{
    {
        [self.view addSubview:self.playerContainer];
        self.playerContainer.frame = [self mediaSmallMediaContainerFrame];
        
        [self configStickerContainer];
    }
    
    {
        [self.view addSubview:self.bottomView];
        @weakify(self);
        self.bottomView.refreshUICompletion = ^(AWECaptionBottomViewType type) {
            @strongify(self);
            CGFloat alpha = type == AWECaptionBottomViewTypeCaption ? 1 : 0;
            [UIView animateWithDuration:0.2 animations:^{
                self.cancelBtn.alpha = alpha;
                self.saveBtn.alpha = alpha;
            }];
            if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypePlayBtn
                || ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypeReplaceIconWithText) {
                self.stopAndPlayBtn.alpha = (type == AWECaptionBottomViewTypeCaption || type == AWECaptionBottomViewTypeStyle) ? 1 : 0;
            }
        };
        
        [self buildBottomView];
    }
    
    {
        // Sticker Gesture Recognizer
        [self.view addSubview:self.stickerGestureController.view];
        [self.stickerGestureController configTextStickerContainer:self.textContainerView];
    }
    
    {
        [self p_setupUIOptimization];
    }
}

- (void)buildBottomView
{
    [self.bottomView.cancelButton addTarget:self action:@selector(cancelAutoCaptionButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView.retryButton addTarget:self action:@selector(retryAutoCaptionButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView.quitButton addTarget:self action:@selector(quitAutoCaptionButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView.emptyCancelButton addTarget:self action:@selector(quitAutoCaptionButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView.styleButton addTarget:self action:@selector(autoCaptionStyleButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView.deleteButton addTarget:self action:@selector(autoCaptionDeleteButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView.editButton addTarget:self action:@selector(autoCaptionEditButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView.styleCancelButton addTarget:self action:@selector(autoCaptionStyleCancelButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView.styleSaveButton addTarget:self action:@selector(autoCaptionStyleSaveButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView.styleToolBar.leftButton addTarget:self action:@selector(autoCaptionStyleToolBarLeftButtonClicked:) forControlEvents:UIControlEventTouchUpInside];

    self.bottomView.captionCollectionView.delegate = self;
    self.bottomView.captionCollectionView.dataSource = self;
    self.bottomView.layoutDelegate = self;
    
    @weakify(self);
    self.bottomView.styleToolBar.colorChooseView.didSelectedColorBlock = ^(AWEStoryColor * selectColor, NSIndexPath *indexPath) {
        @strongify(self);
        [self updateCaptionColor:selectColor fontIndexPath:indexPath];
    };
    
    self.bottomView.styleToolBar.fontChooseView.didSelectedFontBlock = ^(AWEStoryFontModel *selectFont, NSIndexPath *indexPath) {
        @strongify(self);
        [self updateCaptionFont:selectFont fontIndexPath:indexPath];
    };
}

- (void)buildPlayer
{
    if (self.previewService) {
        [self.previewService addSubscriber:self];
    }
    [self.captionManager resetDeleteState];
}

- (void)configStickerContainer
{
    if (self.stickerContainerView) {
        [self configScale];
        [self.playerContainer addSubview:self.stickerContainerView];
        self.stickerContainerView.transform = CGAffineTransformMakeScale(self.containerScale, self.containerScale);
        self.stickerContainerView.center = self.containerCenter;
        self.stickerGestureController.stickerContainerView = self.stickerContainerView;
        
        [self makeMaskLayerForContainerView:self.stickerContainerView];
    }
}

- (void)changeStickerContainerAction
{
    @weakify(self);
    self.stickerGestureController.gestureStartBlock = ^BOOL(UIView *editView) {
        if ([editView isKindOfClass:[ACCBaseStickerView class]] &&
            [((ACCBaseStickerView *)editView).config.typeId isEqualToString:ACCStickerTypeIdCaptions]) {
            return YES;
        }
        
        @strongify(self);
        [self didClickStopAndPlay:nil];
        
        return NO;
    };
    
    [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdCaptions] btd_forEach:^(ACCStickerViewType  _Nonnull obj) {
        obj.config.onceTapCallback =
        ^(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> *contentView, UITapGestureRecognizer *gesture) {
            @strongify(self);
            AWEStudioCaptionModel *model = ACCDynamicCast([self.captionManager.captionStickerIdMaps objectForKey:@(self.captionManager.stickerEditId)], AWEStudioCaptionModel);
            [self jumpToCaptionEditViewControllerWithCurrentModel:model isFromPreview:YES];
        };
    }];
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
    
    self.containerCenter = CGPointMake(self.playerContainer.center.x - self.playerContainer.frame.origin.x,
                                       self.playerContainer.center.y - self.playerContainer.frame.origin.y);
}

- (void)makeMaskLayerForContainerView:(UIView *)view
{
    CGRect frame = [self.view convertRect:self.playerContainer.frame toView:view];
    CAShapeLayer *layer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:frame];

    layer.path = path.CGPath;
    view.layer.mask = layer;
}

#pragma mark - Request Caption

- (void)commitAndQueryCaption
{
    CGFloat startTime = CFAbsoluteTimeGetCurrent();
    self.requestStartTime = startTime;
    [self.bottomView refreshUIWithType:AWECaptionBottomViewTypeLoading];
    void(^startUploadAudioBlock)(NSURL *url, NSError *error) = ^(NSURL *url, NSError *error) {
        if (error) {
            AWELogToolError2(@"editAutoCaption", AWELogToolTagEdit, @"query captions: %@", error);
        }
        if (!url || error || ![[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.bottomView refreshUIWithType:AWECaptionBottomViewTypeRetry];
            });
            return;
        }
        
        self.repository.repoCaption.mixAudioUrl = url;
        @weakify(self);
        [self.repository.repoCaption queryCaptionsWithUrl:url completion:^(NSArray<AWEStudioCaptionModel *> *captionsArray, NSError *error) {
            @strongify(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                self.captionManager.captions = [[NSMutableArray alloc] initWithArray:captionsArray];
                [self setCaptionMarginToContainerCenterY];
                
                //track
                NSInteger requestDuration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000;
                NSMutableDictionary *params = [@{} mutableCopy];
                [params addEntriesFromDictionary:self.repository.repoTrack.referExtra];
                [params setValue:@([self.repository.repoVideoInfo.video totalVideoDuration] * 1000.0) forKey:@"video_duration"];
                [params setValue:@(requestDuration) forKey:@"load_time"];
                
                if (self.isRetry) {
                    [params setValue:@"retry" forKey:@"action_type"];
                } else {
                    [params setValue:@"origin" forKey:@"action_type"];
                }
                
                if (error) {
                    [self.bottomView refreshUIWithType:AWECaptionBottomViewTypeRetry];
                    
                    if (error.code == kRequestTimeout) {
                        [params setValue:@"exceed" forKey:@"load_status"];
                    } else {
                        [params setValue:@"error" forKey:@"load_status"];
                        [params setValue:(error.description ?: @(error.code)) forKey:@"error_type"];
                    }
            
                    [ACCTracker() trackEvent:@"auto_subtitle_end" params:params needStagingFlag:NO];
                    return;
                }
                
                if (captionsArray.count == 0) {
                    [self.bottomView refreshUIWithType:AWECaptionBottomViewTypeEmpty];
                    [params setValue:@"empty" forKey:@"load_status"];
                    [ACCTracker() trackEvent:@"auto_subtitle_end" params:params needStagingFlag:NO];
                    return;
                }
                
                [self captionQuerySucceed];
                [params setValue:@"succeed" forKey:@"load_status"];
                [ACCTracker() trackEvent:@"auto_subtitle_end" params:params needStagingFlag:NO];
            });
        }];
    };
    
    NSString *existPath = self.repository.repoCaption.mixAudioUrl.path;
    if (self.repository.repoCaption.mixAudioUrl) {
        NSString *draftFolder = [AWEDraftUtils generateDraftFolderFromTaskId:self.repository.repoDraft.taskID];
        existPath = [draftFolder stringByAppendingPathComponent:[existPath lastPathComponent]];
    }
    
    /// If audio changes, trigger re-identification
    if ([self.repository.repoCaption audioDidChanged]) {
        [self.repository.repoCaption resetAudioChangeFlag];
        [self.captionManager setNeedUploadAudio];
        [self.audioExport exportAudioWithCompletion:^(NSURL * _Nonnull url, NSError * _Nonnull error, AVAssetExportSessionStatus status) {
            ACCBLOCK_INVOKE(startUploadAudioBlock, url, error);
        }];
    } else {
        if (self.captionManager.captions.count > 0) {
            [self captionQuerySucceed];
        } else if (existPath.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:existPath]) {
            ACCBLOCK_INVOKE(startUploadAudioBlock, [NSURL URLWithString:existPath], nil);
        } else {
            [self.audioExport exportAudioWithCompletion:^(NSURL * _Nonnull url, NSError * _Nonnull error, AVAssetExportSessionStatus status) {
                ACCBLOCK_INVOKE(startUploadAudioBlock, url, error);
            }];
        }
    }
}

#pragma mark 设置字幕底边距
- (void)setCaptionMarginToContainerCenterY
{
    // 分享到日常场景需要调整字幕y值
    if (ACCConfigBool(kConfigBool_enable_share_to_story_add_auto_caption_capacity_in_edit_page) &&
        self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeShareAsStory) {
        NSDecimalNumber *locationY = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", self.marginToContainerCenterY]];
        AWEInteractionStickerLocationModel *location = [AWEInteractionStickerLocationModel new];
        location.scale = [NSDecimalNumber decimalNumberWithString:@"1.0"];
        location.y = locationY;
        self.captionManager.location = location;
    }
}

- (void)captionQuerySucceed
{
    if (self.captionManager.captions.count == 0) {
        return;
    }
    
    if (self.editService) {
        [self.captionManager addCaptionsForEditService:self.editService
                                         containerView:self.stickerContainerView];
        
        [self changeStickerContainerAction];
    }
    
    [self.bottomView refreshUIWithType:AWECaptionBottomViewTypeCaption];
    [self.bottomView.captionCollectionView reloadData];
    
    if (self.previewService) {
        [self.previewService setStickerEditMode:YES];
        @weakify(self);
        self.seekTimeFinished = NO;
        [self.previewService seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
            @strongify(self);
            self.seekTimeFinished = YES;
            if (!self.isPlaying) {
                [self didClickStopAndPlay:nil];
            } else {
                [self.previewService setStickerEditMode:NO];
            }
        }];
    }
}

#pragma mark - AWECaptionBottomView Action

- (void)cancelAutoCaptionButtonClicked
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:ACCLocalizedString(@"auto_caption_recognizing_cancel", @"字幕即将识别完成，确认退出吗？") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedString(@"auto_caption_exit", @"退出") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self removeCaptions];
        [self.captionManager deleteCaption];
        if (self.transitionService) {
            [self.transitionService dismissViewController:self completion:^{
                ACCBLOCK_INVOKE(self.didDismissBlock);
            }];
        } else {
            [self dismissViewControllerAnimated:YES completion:^{
                ACCBLOCK_INVOKE(self.didDismissBlock);
            }];
        }
        
        NSInteger requestDuration = (CFAbsoluteTimeGetCurrent() - self.requestStartTime) * 1000;
        NSMutableDictionary *params = [@{} mutableCopy];
        [params addEntriesFromDictionary:self.repository.repoTrack.referExtra];
        [params setValue:@([self.repository.repoVideoInfo.video totalVideoDuration] * 1000.0) forKey:@"video_duration"];
        [params setValue:@(requestDuration) forKey:@"load_time"];
        [params setValue:@"cancel" forKey:@"load_status"];
        if (self.isRetry) {
            [params setValue:@"retry" forKey:@"action_type"];
        } else {
            [params setValue:@"origin" forKey:@"action_type"];
        }
        [ACCTracker() trackEvent:@"auto_subtitle_end" params:params needStagingFlag:NO];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedString(@"auto_caption_recognizing_continue", @"继续识别") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }]];
    [ACCAlert() showAlertController:alertController animated:YES];
}

- (void)retryAutoCaptionButtonClicked
{
    self.isRetry = YES;
    [self commitAndQueryCaption];

    NSMutableDictionary *params = [@{} mutableCopy];
    [params addEntriesFromDictionary:self.repository.repoTrack.referExtra];
    [ACCTracker() trackEvent:@"retry_auto_subtitle" params:params needStagingFlag:NO];
}

- (void)quitAutoCaptionButtonClicked
{
    if (self.transitionService) {
        [self.transitionService dismissViewController:self completion:^{
            ACCBLOCK_INVOKE(self.didDismissBlock);
        }];
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            ACCBLOCK_INVOKE(self.didDismissBlock);
        }];
    }
}

- (void)autoCaptionStyleButtonClicked
{
    [self.captionManager backupTextStyle];
    [self.bottomView refreshUIWithType:AWECaptionBottomViewTypeStyle];
    NSString *imageName = [NSString stringWithFormat:@"icTextStyle_%@", @(self.captionManager.captionInfo.textInfoModel.textStyle)];
    UIImage *image = ACCResourceImage(imageName);
    [self.bottomView.styleToolBar.leftButton setImage:image forState:UIControlStateNormal];
    NSString *title = @"文本样式";
    if (self.captionManager.captionInfo.textInfoModel.textStyle == AWEStoryTextStyleStroke) {
        title = [title stringByAppendingString:@",描边"];
    } else if (self.captionManager.captionInfo.textInfoModel.textStyle == AWEStoryTextStyleBackground) {
        title = [title stringByAppendingString:@",背景"];
    } else if (self.captionManager.captionInfo.textInfoModel.textStyle == AWEStoryTextStyleAlphaBackground) {
        title = [title stringByAppendingString:@",半透明背景"];
    } else {
        title = [title stringByAppendingString:@",无"];
    }
    self.bottomView.styleToolBar.leftButton.accessibilityLabel = title;
    [self.bottomView.styleToolBar.colorChooseView.collectionView selectItemAtIndexPath:self.captionManager.captionInfo.textInfoModel.colorIndex
                                                                              animated:NO
                                                                        scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    if (self.captionManager.captionInfo.textInfoModel.fontIndex.row < ACCCustomFont().stickerFonts.count) {
        __block NSInteger index = -1;
        [ACCCustomFont().stickerFonts enumerateObjectsUsingBlock:^(AWEStoryFontModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.title isEqualToString:self.captionManager.captionInfo.textInfoModel.fontModel.title]) {
                index = idx;
                *stop = YES;
            }
        }];
        if (index >= 0) {
            self.captionManager.captionInfo.textInfoModel.fontIndex = [NSIndexPath indexPathForRow:index inSection:0];
        } else {
            if (self.captionManager.captionInfo.textInfoModel.fontIndex.row >= ACCCustomFont().stickerFonts.count) {
                self.captionManager.captionInfo.textInfoModel.fontIndex = [NSIndexPath indexPathForRow:0 inSection:0];
            }
        }
        
        [self.bottomView.styleToolBar.fontChooseView selectWithIndexPath:self.captionManager.captionInfo.textInfoModel.fontIndex];
    }
    
    NSMutableDictionary *params = [@{} mutableCopy];
    [params addEntriesFromDictionary:self.repository.repoTrack.referExtra];
    [params setObject:@(1) forKey:@"is_subtitle"];
    [ACCTracker() trackEvent:@"edit_text" params:params needStagingFlag:NO];
}

- (void)autoCaptionDeleteButtonClicked
{
    @weakify(self);
    void (^block)(void) = ^ {
        [self removeCaptions];
        
        UIImage *snap = [self.playerContainer acc_snapshotImageAfterScreenUpdates:NO withSize:self.view.bounds.size];
        ACCBLOCK_INVOKE(self.willDismissBlock, snap, YES, YES);
        
        
        let completionBlock = ^{
            @strongify(self);
            if (self.previewService) {
                [self.previewService setStickerEditMode:NO];
            }
            ACCBLOCK_INVOKE(self.didDismissBlock);
        };
        
        if (self.transitionService) {
            [self.transitionService dismissViewController:self completion:completionBlock];
        } else {
            [self dismissViewControllerAnimated:YES completion:completionBlock];
        }
        
        [self.repository.repoTrack trackPostEvent:@"text_delete"
                                  enterMethod:nil
                                    extraInfo:@{
                                        @"enter_from" : self.repository.repoTrack.enterFrom? : @"",
                                        @"is_subtitle": @1,
                                        @"enter_method": @"click_icon"
                                    }];
    };
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:ACCLocalizedString(@"auto_caption_delete", @"确认删除所有字幕吗？") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedString(@"auto_caption_cancel", @"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedString(@"auto_caption_confirm", @"confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        block();
    }]];
    [ACCAlert() showAlertController:alertController animated:YES];
}

/// 编辑按钮点击
- (void)autoCaptionEditButtonClicked
{
    NSInteger stickerId = self.captionManager.stickerEditId;
    AWEStudioCaptionModel *model = [self.captionManager.captionStickerIdMaps objectForKey:@(stickerId)];
    [self jumpToCaptionEditViewControllerWithCurrentModel:model isFromPreview:YES];
}

- (void)autoCaptionStyleCancelButtonClicked
{
    [self.captionManager restoreTextStyle];
    if (self.editService) {
        [self.editService.sticker updateSticker:self.captionManager.stickerEditId];
    }
    [self.bottomView refreshUIWithType:AWECaptionBottomViewTypeCaption];
}

- (void)autoCaptionStyleSaveButtonClicked
{
    [self.bottomView refreshUIWithType:AWECaptionBottomViewTypeCaption];
}

- (void)autoCaptionStyleToolBarLeftButtonClicked:(UIButton *)button
{
    AWEStoryTextStyle style = (self.captionManager.textStyle + 1) % AWEStoryTextStyleCount;
    NSString *imageName = [NSString stringWithFormat:@"icTextStyle_%@", @(style)];
    [button setImage:ACCResourceImage(imageName) forState:UIControlStateNormal];
    button.isAccessibilityElement = YES;
    button.accessibilityTraits = UIAccessibilityTraitButton;
    NSString *title = @"文本样式";
    if (style == AWEStoryTextStyleStroke) {
        title = [title stringByAppendingString:@",描边"];
    } else if (style == AWEStoryTextStyleBackground) {
        title = [title stringByAppendingString:@",背景"];
    } else if (style == AWEStoryTextStyleAlphaBackground) {
        title = [title stringByAppendingString:@",半透明背景"];
    } else {
        title = [title stringByAppendingString:@",无"];
    }
    button.accessibilityLabel = title;
    [self updateCaptionTextStyle:style];
}

#pragma mark - 字幕样式

- (void)updateCaptionFont:(AWEStoryFontModel *)font fontIndexPath:(NSIndexPath *)indexPath
{
    self.captionManager.fontModel = font;
    self.captionManager.fontIndex = indexPath;
    [self updateToolBarEnable:font];
    if (self.editService) {
        [self.editService.sticker updateSticker:self.captionManager.stickerEditId];
    }
    [self.captionManager updateCaptionLineRectForAll];
    
    NSMutableDictionary *params = [@{} mutableCopy];
    [params addEntriesFromDictionary:self.repository.repoTrack.referExtra];
    [params setObject:font.title ?: @"" forKey:@"font"];
    [params setObject:@(1) forKey:@"is_subtitle"];
    [ACCTracker() trackEvent:@"select_text_font" params:params needStagingFlag:NO];
}

- (void)updateCaptionColor:(AWEStoryColor *)color fontIndexPath:(NSIndexPath *)indexPath
{
    self.captionManager.fontColor = color;
    self.captionManager.colorIndex = indexPath;
    if (self.editService) {
        [self.editService.sticker updateSticker:self.captionManager.stickerEditId];
    }
    
    NSMutableDictionary *params = [@{} mutableCopy];
    [params addEntriesFromDictionary:self.repository.repoTrack.referExtra];
    [params setObject:color.colorString ?: @"" forKey:@"color"];
    [params setObject:@(1) forKey:@"is_subtitle"];
    [ACCTracker() trackEvent:@"select_text_color" params:params needStagingFlag:NO];
}

- (void)updateCaptionTextStyle:(AWEStoryTextStyle)style
{
    self.captionManager.textStyle = style;
    if (self.editService) {
        [self.editService.sticker updateSticker:self.captionManager.stickerEditId];
    }
    
    NSMutableDictionary *params = [@{} mutableCopy];
    [params addEntriesFromDictionary:self.repository.repoTrack.referExtra];
    [params setObject:@(style) forKey:@"text_style"];
    [params setObject:@(1) forKey:@"is_subtitle"];
    [ACCTracker() trackEvent:@"select_text_style" params:params needStagingFlag:NO];
}

- (void)updateToolBarEnable:(AWEStoryFontModel *)font
{
    if (!font) {
        return;
    }
    
    if (font.hasBgColor) {
        self.bottomView.styleToolBar.leftButton.enabled = YES;
    } else {
        self.bottomView.styleToolBar.leftButton.enabled = NO;
    }
}

#pragma mark - UICollectionViewDataSource, UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.captionManager.captions.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AWECaptionCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[AWECaptionCollectionViewCell identifier] forIndexPath:indexPath];
    if (indexPath.row < [self.captionManager.captions count]) {
        AWEStudioCaptionModel *model = [self.captionManager.captions objectAtIndex:indexPath.row];
        [cell configCellWithCaptionModel:model];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(AWECaptionCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    [cell configCaptionHighlight:NO];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    AWEStudioCaptionModel *model = [self.captionManager.captions objectAtIndex:indexPath.row];
    [self jumpToCaptionEditViewControllerWithCurrentModel:model isFromPreview:NO];
}

#pragma mark - AWECaptionScrollFlowLayoutDelegate

- (void)collectionViewScrollStopAtIndex:(NSInteger)index
{
    self.currentIndex = index;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.isPlaying) {
        if (self.previewService) {
            [self.previewService setStickerEditMode:YES];
        }
        self.isPlaying = NO;
        self.backupIsPlaying = YES;
    }
    
    self.needRestorePlayer = YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!self.isPlaying) {
        self.currentIndex = [self highlightIndexWithContentOffset:scrollView.contentOffset.y];
        [self.bottomView refreshCellHighlightWithRow:self.currentIndex];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self restorePlayerStatus];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self restorePlayerStatus];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self restorePlayerStatus];
}

- (void)restorePlayerStatus
{
    if (!self.needRestorePlayer) {
        return;
    }

    @weakify(self);
    void(^playIfBackupIsPlayingBlock)(void) = ^{
        self.needRestorePlayer = NO;
        if (self.backupIsPlaying) {
            if (self.previewService) {
                [self.previewService setStickerEditMode:NO];
            }
            self.isPlaying = YES;
            self.backupIsPlaying = NO;
        }
    };
    
    NSInteger index = self.currentIndex;
    if (index < self.captionManager.captions.count) {
        AWEStudioCaptionModel *model = [self.captionManager.captions objectAtIndex:index];
        
        // current time
        CGFloat currentTime = model.startTime / 1000.0;
        if (index >= 0) {
            [self.bottomView refreshCellHighlightWithRow:index];
        } else {
            [self.bottomView refreshCellHighlightWithRow:kInvalidIndex];
        }
        
        if (index == 0) {
            currentTime = 0;
        }
        
        self.seekTimeFinished = NO;
        if (self.previewService) {
            [self.previewService seekToTime:CMTimeMakeWithSeconds(currentTime, 1000000) completionHandler:^(BOOL finished) {
                @strongify(self);
                // 延长一个时间，防止iOS 9等系统偶现 currentPlayerTime 与seek的 currentTime 不一致的问题
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    self.seekTimeFinished = YES;
                });
                playIfBackupIsPlayingBlock();
            }];
        }
    } else {
        playIfBackupIsPlayingBlock();
    }
}

#pragma mark - KVOController Action

- (void)scrollCaptionWithCurrentPlayerTime:(CGFloat)currentTime
{
    if (!self.isPlaying) {
        return;
    }
    
    NSInteger index = [self captionIndexWithCurrentPlayerTime:currentTime];
    self.currentIndex = index;
    if (index == kInvalidIndex || self.bottomView.currentRow == index) {
        [self.bottomView refreshCellHighlightWithRow:index];
        
        // 处理首句字幕起始时间较晚的情况
        if (self.bottomView.currentRow == self.captionManager.captions.count - 1 && ACC_FLOAT_EQUAL_ZERO(currentTime)) {
            AWEStudioCaptionModel *model = self.captionManager.captions.firstObject;
            if (model.startTime > 0.25) {
                [self.bottomView.captionCollectionView setContentOffset:CGPointMake(0, -kAWECaptionBottomTableViewHighlightOffset) animated:YES];
            }
        }
        
        return;
    }

    CGFloat contentOffset = index * kAWECaptionBottomTableViewCellHeight - kAWECaptionBottomTableViewHighlightOffset;
    [self.bottomView refreshCellHighlightWithRow:index];
    [self.bottomView.captionCollectionView setContentOffset:CGPointMake(0, contentOffset) animated:YES];
}

- (NSInteger)captionIndexWithCurrentPlayerTime:(CGFloat)currentTime
{
    NSInteger index = kInvalidIndex;
    CGFloat currentTimeMs = currentTime * 1000.0 + kCorrectedValue;
    for (int i = 0; i < self.captionManager.captions.count; i++) {
        AWEStudioCaptionModel *model = [self.captionManager.captions objectAtIndex:i];
        if (model.startTime < currentTimeMs && currentTimeMs < model.endTime ) {
            index = i;
            break;
        }
    }
    
    return index;
}

- (NSInteger)highlightIndexWithContentOffset:(CGFloat)offset
{
    if (offset < -kAWECaptionBottomTableViewHighlightOffset) {
        return kInvalidIndex;
    }
    
    NSInteger index = self.bottomView.currentRow;
    
    float floatIndex = (offset + kAWECaptionBottomTableViewHighlightOffset) / kAWECaptionBottomTableViewCellHeight;
    int floorIndex = floor(floatIndex);
    int ceilIndex = ceil(floatIndex);
    
    if ((floatIndex - floorIndex) < 0.1) {
        index = floorIndex;
    }
    
    if ((ceilIndex - floatIndex) < 0.1) {
        index = ceilIndex;
    }
    
    if (index >= self.captionManager.captions.count) {
        index = kInvalidIndex;
    }
    
    return index;
}


#pragma mark - Action

- (void)didClickCancelBtn:(UIButton *)btn
{
    @weakify(self);
    void (^block)(void) = ^ {
        [self removeCaptions];
        
        UIImage *snap = [self.playerContainer acc_snapshotImageAfterScreenUpdates:NO withSize:self.view.bounds.size];
        ACCBLOCK_INVOKE(self.willDismissBlock, snap, YES, NO);
        
        let completionBlock = ^{
            @strongify(self);
            if (self.previewService) {
                [self.previewService setStickerEditMode:NO];
            }
            ACCBLOCK_INVOKE(self.didDismissBlock);
        };
        
        if (self.transitionService) {
            [self.transitionService dismissViewController:self completion:completionBlock];
        } else {
            [self dismissViewControllerAnimated:YES completion:completionBlock];
        }
    };
    
    if ([self captionHasChanged]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:ACCLocalizedString(@"auto_caption_unsave", @"确认不保存字幕吗？") preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedString(@"auto_caption_cancel", @"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedString(@"auto_caption_confirm", @"confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            ACCBLOCK_INVOKE(block);
        }]];
        [ACCAlert() showAlertController:alertController animated:YES];
    } else {
        ACCBLOCK_INVOKE(block);
    }
}

- (void)didClickSaveBtn:(UIButton *)btn
{
    //点击保存
    self.repository.repoCaption.captionInfo = self.captionManager.captionInfo;
    [ACCDraft() saveDraftWithPublishViewModel:self.repository
                                        video:self.repository.repoVideoInfo.video
                                       backup:!self.repository.repoDraft.originalDraft
                                   completion:^(BOOL success, NSError *error) {
        if (error) {
            AWELogToolError2(@"editAutoCaption", AWELogToolTagEdit, @"save draft error: %@", error);
        }
    }];
    
    NSMutableDictionary *params = [@{} mutableCopy];
    [params addEntriesFromDictionary:self.repository.repoTrack.referExtra];
    [ACCTracker() trackEvent:@"save_subtitle" params:params needStagingFlag:NO];
    
    [self removeCaptions];
    
    UIImage *snap = [self.playerContainer acc_snapshotImageAfterScreenUpdates:NO withSize:self.view.bounds.size];
    ACCBLOCK_INVOKE(self.willDismissBlock, snap, NO, NO);
    
    @weakify(self);
    let completionBlock = ^{
        @strongify(self);
        if (self.previewService) {
            [self.previewService setStickerEditMode:NO];
        }
        ACCBLOCK_INVOKE(self.didDismissBlock);
    };
    
    if (self.transitionService) {
        [self.transitionService dismissViewController:self completion:completionBlock];
    } else {
        [self dismissViewControllerAnimated:YES completion:completionBlock];
    }
}

- (void)didClickStopAndPlay:(UIButton *)btn
{
    NSString *clickTypeStr = nil;
    if (self.isPlaying) {
        //进入暂停状态
        if (self.previewService) {
            [self.previewService setStickerEditMode:YES];
        }
        self.isPlaying = NO;
        clickTypeStr = @"stop";
    } else {
        //进入播放状态
        if (self.previewService) {
            [self.previewService setStickerEditMode:NO];
        }
        self.isPlaying = YES;
        clickTypeStr = @"play";
    }
    
    [ACCTracker() trackEvent:@"preview_item"
                      params:@{
                          @"click_type" : clickTypeStr ?: @"",
                          @"function_type" : @"subtitle",
                          @"shoot_way" : self.repository.repoTrack.referString ?: @"",
                          @"content_source" : [self.repository.repoTrack referExtra][@"content_source"] ?: @"",
                          @"content_type" : [self.repository.repoTrack referExtra][@"content_type"] ?: @"",
                          @"is_multi_content" : self.repository.repoTrack.mediaCountInfo[@"is_multi_content"] ?: @"",
                          @"mix_type" : [self.repository.repoTrack referExtra][@"mix_type"] ?: @"",
                          @"creation_id" : self.repository.repoContext.createId ?: @"",
                      }];
}

- (void)removeCaptions
{
    if (self.editService) {
        [self.captionManager removeCaptionForEditService:self.editService
                                           containerView:self.stickerContainerView];
    }
}

- (BOOL)captionHasChanged
{
    NSString *finalMD5 = [self.captionManager.captionInfo md5];
    
    if ([finalMD5 isEqualToString:self.captionMD5]) {
        return NO;
    }
    
    return YES;
}

#pragma mark - UI Optimized

- (CGFloat)autoCaptionsFooterViewHeigth
{
    if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypeDisabled) {
        return AWEAutoCaptionsBottomViewHeigth;
    } else {
        return AWEAutoCaptionsFooterViewHeight;
    }
}

#pragma mark - 跳转字幕编辑页面

- (void)jumpToCaptionEditViewControllerWithCurrentModel:(AWEStudioCaptionModel *)model isFromPreview:(BOOL)isFromPreview
{
    self.enterEditMode = YES;
    NSInteger row = [self.captionManager.captions indexOfObject:model];
    AWEAutoCaptionsEditViewController *captionEdit =
    [[AWEAutoCaptionsEditViewController alloc] initWithReferExtra:self.repository.repoTrack.referExtra
                                                         captions:self.captionManager.captions
                                                    selectedIndex:row];
    captionEdit.previewService = self.previewService;
    captionEdit.enterFrom = isFromPreview ? @"click_preview" : @"click_subtitle";
    
    @weakify(self);
    captionEdit.savedBlock = ^(NSMutableArray<AWEStudioCaptionModel *> *captions, NSInteger currentIndex) {
        if (captions) {
            @strongify(self);
            self.captionManager.captions = captions;
            if (self.editService) {
                [self.captionManager addCaptionsForEditService:self.editService
                                                 containerView:self.stickerContainerView];
                
                [self changeStickerContainerAction];
            }
    
            // 滚动到播放cell
            self.currentIndex = currentIndex;
            CGFloat contentOffset = currentIndex * kAWECaptionBottomTableViewCellHeight - kAWECaptionBottomTableViewHighlightOffset;
            [self.bottomView.captionCollectionView reloadData];
            [self.bottomView.captionCollectionView setContentOffset:CGPointMake(0, contentOffset) animated:YES];
        }
    };
    
    captionEdit.didDismissBlock = ^(CGFloat startTime, NSInteger currentIndex) {
        self.enterEditMode = NO;
        
        // 重置播放时间
        self.seekTimeFinished = NO;
        if (self.previewService) {
            if (self.backupIsPlaying && !self.isPlaying && self.captionManager.captions.count > 0) {
                [self.previewService seekToTime:CMTimeMakeWithSeconds(startTime, 1000000) completionHandler:^(BOOL finished) {
                    self.seekTimeFinished = YES;
                    [self.previewService setStickerEditMode:NO];
                    self.backupIsPlaying = NO;
                    self.isPlaying = YES;
                }];
            } else {
                [self.previewService seekToTime:CMTimeMakeWithSeconds(startTime, 1000000) completionHandler:^(BOOL finished) {
                    self.seekTimeFinished = YES;
                    self.backupIsPlaying = NO;
                }];
            }
        }
        
        [self.bottomView refreshCellHighlightWithRow:currentIndex];
    };
    
    //track
    NSMutableDictionary *params = [@{} mutableCopy];
    [params addEntriesFromDictionary:self.repository.repoTrack.referExtra];
    [params setValue:isFromPreview ? @"click_preview" : @"click_subtitle" forKey:@"enter_method"];
    [ACCTracker() trackEvent:@"enter_edit_subtitle" params:params needStagingFlag:NO];
    
    captionEdit.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:captionEdit animated:YES completion:nil];
}

#pragma mark - AWEMediaSmallAnimationProtocol

- (UIView *)mediaSmallMediaContainer
{
    return self.playerContainer;
}

- (CGRect)mediaSmallMediaContainerFrame
{
    CGFloat playerY = ACC_STATUS_BAR_NORMAL_HEIGHT;
    if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypeDisabled) {
        playerY += 52;
    }
    
    CGFloat playerHeight = ACC_SCREEN_HEIGHT - (playerY + [self autoCaptionsFooterViewHeigth] + 12) - ACC_IPHONE_X_BOTTOM_OFFSET;
    CGFloat playerWidth = self.view.acc_width;
    CGFloat playerX = (self.view.bounds.size.width - playerWidth) / 2;
    CGSize videoSize = CGSizeMake(540, 960);
    if (self.previewService) {
        if (!CGRectEqualToRect(self.repository.repoVideoInfo.playerFrame, CGRectZero)) {
            videoSize = self.repository.repoVideoInfo.playerFrame.size;
        }
    }
    return AVMakeRectWithAspectRatioInsideRect(videoSize, CGRectMake(playerX, playerY, playerWidth, playerHeight));
}

- (UIView *)mediaSmallBottomView
{
    return self.bottomView;
}

- (CGFloat)mediaSmallBottomViewHeight
{
    return [self autoCaptionsFooterViewHeigth] + ACC_IPHONE_X_BOTTOM_OFFSET;
}

- (NSArray<UIView *>*)displayTopViews
{
    if (self.captionManager.captions.count == 0) {
        return nil;
    }
    NSMutableArray<UIView *> *topViews = [NSMutableArray array];
    [topViews acc_addObject:self.cancelBtn];
    [topViews acc_addObject:self.saveBtn];
    return topViews.copy;
}

#pragma mark -

// 自动字幕-根据播放进度更新贴纸显示
- (void)updateStickerContainerWithCurrentPlayerTime:(CGFloat)currentPlayerTime
{
    for (UIView <ACCSelectTimeRangeStickerProtocol> *stickerView in self.stickerContainerView.stickerViewList) {
        [stickerView updateWithCurrentPlayerTime:currentPlayerTime];
    }
}

#pragma mark - Getter & Setter

- (UIButton *)cancelBtn
{
    if (!_cancelBtn) {
        _cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelBtn.alpha = 0;
        [_cancelBtn setTitle:ACCLocalizedString(@"auto_caption_cancel", @"cancel") forState:UIControlStateNormal];
        [_cancelBtn.titleLabel setFont:[ACCFont() systemFontOfSize:17 weight:ACCFontWeightRegular]];
        UIColor *titleColor = ACCResourceColor(ACCUIColorConstTextInverse);
        [_cancelBtn setTitleColor:titleColor forState:UIControlStateNormal];
        [_cancelBtn addTarget:self action:@selector(didClickCancelBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtn;
}

- (UIButton *)saveBtn
{
    if (!_saveBtn) {
        _saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _saveBtn.alpha = 0;
        [_saveBtn setTitle:ACCLocalizedString(@"auto_caption_save", @"save") forState:UIControlStateNormal];
        [_saveBtn.titleLabel setFont:[ACCFont() systemFontOfSize:17 weight:ACCFontWeightMedium]];
        UIColor *titleColor = ACCResourceColor(ACCUIColorConstTextInverse);
        [_saveBtn setTitleColor:titleColor forState:UIControlStateNormal];
        [_saveBtn addTarget:self action:@selector(didClickSaveBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _saveBtn;
}

- (UIView *)playerContainer
{
    if (!_playerContainer) {
        _playerContainer = [UIView new];
        _playerContainer.layer.cornerRadius = 2;
        _playerContainer.layer.masksToBounds = YES;
        _playerContainer.accrtl_viewType = ACCRTLViewTypeNormal;
    }
    return _playerContainer;
}

- (AWECaptionBottomView *)bottomView
{
    if (_bottomView == nil) {
        if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypeDisabled) {
            _bottomView = [[AWECaptionBottomView alloc] initWithFrame:CGRectMake(0, ACC_SCREEN_HEIGHT, ACC_SCREEN_WIDTH, [self mediaSmallBottomViewHeight])];
        } else {
            _bottomView = [[AWECaptionBottomOptimizedView alloc] initWithFrame:CGRectMake(0, ACC_SCREEN_HEIGHT, ACC_SCREEN_WIDTH, [self mediaSmallBottomViewHeight])];
            _bottomView.separateLine.alpha = 0;
        }
        _bottomView.backgroundColor = ACCResourceColor(ACCColorBGCreation2);
    }
    return _bottomView;
}

- (UIButton *)stopAndPlayBtn
{
    if (!_stopAndPlayBtn) {
        _stopAndPlayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_stopAndPlayBtn addTarget:self action:@selector(didClickStopAndPlay:) forControlEvents:UIControlEventTouchUpInside];
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

- (void)setIsPlaying:(BOOL)isPlaying
{
    _isPlaying = isPlaying;
    [self.stopAndPlayImageView.layer removeAllAnimations];
    
    if (_isPlaying) {
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

- (AWEAudioExport *)audioExport
{
    if (!_audioExport) {
        _audioExport = [[AWEAudioExport alloc] initWithPublishModel:self.repository];
    }
    
    return _audioExport;
}

- (AWEEditorStickerGestureViewController *)stickerGestureController
{
    if (!_stickerGestureController) {
        _stickerGestureController = [[AWEEditorStickerGestureViewController alloc] init];
        _stickerGestureController.view.frame = [self mediaSmallMediaContainerFrame];
    }
    
    return _stickerGestureController;
}

#pragma mark - ACCEditPreviewMessageProtocol

- (void)playerCurrentPlayTimeChanged:(NSTimeInterval)currentPlayerTime
{
    if (!self.seekTimeFinished) {
        return;
    }
    [self scrollCaptionWithCurrentPlayerTime:currentPlayerTime];
    [self updateStickerContainerWithCurrentPlayerTime:currentPlayerTime];
}

#pragma mark - UI Optimization

/// Adjust UI according to AB
- (void)p_setupUIOptimization
{
    if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypeDisabled) {
        [self p_setupUIOptimizationPlayBtn:NO];
        [self p_setupUIOptimizationSaveCancelBtn:NO];
    } else if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypeSaveCancelBtn) {
        [self p_setupUIOptimizationPlayBtn:NO];
        [self p_setupUIOptimizationSaveCancelBtn:YES];
        [self p_setupUIOptimizationReplaceIconWithText:YES];
    } else if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypePlayBtn) {
        [self p_setupUIOptimizationPlayBtn:YES];
        [self p_setupUIOptimizationSaveCancelBtn:YES];
        [self p_setupUIOptimizationReplaceIconWithText:YES];
    } else if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypeReplaceIconWithText) {
        [self p_setupUIOptimizationPlayBtn:YES];
        [self p_setupUIOptimizationSaveCancelBtn:YES];
        [self p_setupUIOptimizationReplaceIconWithText:NO];
    }
}

- (void)p_setupUIOptimizationSaveCancelBtn:(BOOL)shouldOptimized
{
    if (shouldOptimized && [self.bottomView isKindOfClass:[AWECaptionBottomOptimizedView class]]) {
        [((AWECaptionBottomOptimizedView *)self.bottomView).backButton addTarget:self action:@selector(didClickCancelBtn:) forControlEvents:UIControlEventTouchUpInside];
        [((AWECaptionBottomOptimizedView *)self.bottomView).saveButton addTarget:self action:@selector(didClickSaveBtn:) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomView.captionTitle setHidden:YES];
    } else {
        [self.view addSubview:self.cancelBtn];
        [self.view addSubview:self.saveBtn];
        
        ACCMasMaker(self.cancelBtn, {
            make.left.equalTo(@16);
            make.centerY.equalTo(self.view.mas_top).offset(52/2 + ([UIDevice acc_isIPhoneX] ? 44 : 0));
            make.height.equalTo(@(kAWEAutoCaptionsTopButtonHeight));
        });
        
        ACCMasMaker(self.saveBtn, {
            make.right.equalTo(@-16);
            make.centerY.equalTo(self.view.mas_top).offset(52/2 + ([UIDevice acc_isIPhoneX] ? 44 : 0));
            make.height.equalTo(@(kAWEAutoCaptionsTopButtonHeight));
        });
    }
}

- (void)p_setupUIOptimizationPlayBtn:(BOOL)shouldOptimized
{
    if (shouldOptimized) {
        [self.stopAndPlayBtn setImage:ACCResourceImage(@"cameraStickerPlay") forState:UIControlStateNormal];
        [self.stopAndPlayBtn setImage:ACCResourceImage(@"cameraStickerPause") forState:UIControlStateSelected];
        [self.bottomView addSubview:self.stopAndPlayBtn];
        self.stopAndPlayBtn.frame = CGRectMake(ACC_SCREEN_WIDTH - 40, 12, 28, 28);
        self.stopAndPlayBtn.center = CGPointMake(self.bottomView.frame.size.width / 2.f, self.stopAndPlayBtn.center.y);
        ((AWECaptionBottomOptimizedView *)self.bottomView).styleTitle.alpha = 0;
    } else {
        [self.view insertSubview:self.stopAndPlayBtn belowSubview:self.stickerGestureController.view];
        [self.stopAndPlayBtn addSubview:self.stopAndPlayImageView];
        
        ACCMasMaker(self.stopAndPlayBtn, {
            make.center.equalTo(self.playerContainer);
            make.width.height.equalTo(self.playerContainer);
        });
        ACCMasMaker(self.stopAndPlayImageView, {
            make.left.top.right.bottom.equalTo(self.stopAndPlayBtn);
        });
    }
}

- (void)p_setupUIOptimizationReplaceIconWithText:(BOOL)shouldUseText
{
    if (shouldUseText) {
        AWECaptionBottomOptimizedView *bottomView = (AWECaptionBottomOptimizedView *)self.bottomView;
        [bottomView.backButton setImage:nil forState:UIControlStateNormal];
        [bottomView.backButton setImage:nil forState:UIControlStateHighlighted];
        [bottomView.backButton setTitle:@"取消" forState:UIControlStateNormal];
        bottomView.backButton.titleLabel.font = [ACCFont() systemFontOfSize:17];
        CGSize newSize = [bottomView.backButton.titleLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, 24.f)];
        bottomView.backButton.frame = CGRectMake(16, 14, newSize.width, newSize.height);
        
        [bottomView.saveButton setImage:nil forState:UIControlStateNormal];
        [bottomView.saveButton setImage:nil forState:UIControlStateHighlighted];
        [bottomView.saveButton setTitle:@"保存" forState:UIControlStateNormal];
        bottomView.saveButton.titleLabel.font = [ACCFont() systemFontOfSize:17];
        newSize = [bottomView.saveButton.titleLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, 24.f)];
        bottomView.saveButton.frame = CGRectMake(ACC_SCREEN_WIDTH - 16 - newSize.width, 14, newSize.width, newSize.height);
    }
}

@end
