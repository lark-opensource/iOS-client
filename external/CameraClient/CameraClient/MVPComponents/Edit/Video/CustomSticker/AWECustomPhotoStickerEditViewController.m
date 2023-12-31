//
//  AWECustomPhotoStickerEditViewController.m
//  CameraClient
//
//  Created by 卜旭阳 on 2020/6/12.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWECustomPhotoStickerEditViewController.h"
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CoreGraphics/CGGeometry.h>
#import "AWECustomStickerEditContainer.h"
#import "AWECustomStickerImageProcessor.h"
#import "AWECustomPhotoStickerEditConfig.h"
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <YYImage/YYImage.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <CreativeKit/ACCNetServiceProtocol.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <Masonry/View+MASAdditions.h>
#import <CreationKitInfra/ACCRTLProtocol.h>
#import <ACCConfigKeyDefines.h>

CGFloat const AWECustomStickerEditVCBottomMargin = 117.f;
NSString *const AWECustomStickerAlbumClipTimingKey = @"custom_sticker_imageclip_cost_timing";

typedef NS_ENUM(NSInteger, AWECustomPhotoStickerEditStatus) {
    AWECustomPhotoStickerEditStatusNone = 0,
    AWECustomPhotoStickerEditStatusProcess,
    AWECustomPhotoStickerEditStatusComplete,
};

@interface AWECustomPhotoStickerEditViewController ()<AWECustomStickerEditContainerDelegate>
///Common
@property (nonatomic, strong) AWECustomPhotoStickerEditConfig *config;
///GIF
@property (nonatomic, strong) YYAnimatedImageView *animatedImageView;

@property (nonatomic, strong) AWECustomStickerEditContainer *editContainer;

@property (nonatomic, strong) UIImageView *iconView;

@property (nonatomic, strong) UILabel *statusLabel;

@property (nonatomic, strong) UILabel *confirmLabel;

@property (nonatomic, assign) AWECustomPhotoStickerEditStatus currentStatus;

@property (nonatomic, strong) id clipRequest;

@property (nonatomic, weak) UIView<ACCLoadingViewProtocol> *loadingView;

@end

@implementation AWECustomPhotoStickerEditViewController

- (void)dealloc
{
    [ACCNetService() cancel:self.clipRequest];
    self.clipRequest = nil;
    self.editContainer.delegate = nil;
}

- (instancetype)initWithConfig:(AWECustomPhotoStickerEditConfig *)config
{
    self = [super init];
    if(self) {
        _config = config;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = ACCResourceColor(ACCColorBGCreation);
    self.navigationController.navigationBar.hidden = YES;
    
    if(self.config.isGIF) {
        CGSize size = self.config.animatedImage.size;
        CGSize aniContainerSize = [AWECustomStickerEditContainer containerSizeWithImageSize:size maxSize:self.view.frame.size];
        
        self.animatedImageView = [[YYAnimatedImageView alloc] init];
        self.animatedImageView.image = self.config.animatedImage;
        [self.view addSubview:self.animatedImageView];
        ACCMasMaker(self.animatedImageView, {
            make.center.equalTo(self.view);
            make.width.equalTo(@(aniContainerSize.width));
            make.height.equalTo(@(aniContainerSize.height));
        });
        if (!ACCConfigBool(kConfigBool_studio_adjust_black_mask)) {
            UIView *upCoverView = [[UIView alloc] init];
            CAGradientLayer *upCoverLayer = [CAGradientLayer layer];
            upCoverLayer.frame = CGRectMake(0.f, 0.f, CGRectGetWidth(self.view.frame), ACC_STATUS_BAR_HEIGHT+AWECustomStickerEditVCBottomMargin);
            upCoverLayer.colors = @[(__bridge id)[[UIColor blackColor] colorWithAlphaComponent:0.5].CGColor,
                                     (__bridge id)[[UIColor blackColor] colorWithAlphaComponent:0.0].CGColor];
            upCoverLayer.startPoint = CGPointMake(0, 0);
            upCoverLayer.endPoint = CGPointMake(0, 1);
            [upCoverView.layer addSublayer:upCoverLayer];
            [self.view addSubview:upCoverView];
            ACCMasMaker(upCoverView, {
                make.left.equalTo(self.view);
                make.right.equalTo(self.view);
                make.top.equalTo(self.view);
                make.height.equalTo(@(ACC_STATUS_BAR_HEIGHT+AWECustomStickerEditVCBottomMargin));
            });
            
            UIView *downCoverView = [[UIView alloc] init];
            CAGradientLayer *downCoverLayer = [CAGradientLayer layer];
            downCoverLayer.frame = CGRectMake(0.f, 0.f, CGRectGetWidth(self.view.frame), ACC_STATUS_BAR_HEIGHT+AWECustomStickerEditVCBottomMargin);
            downCoverLayer.colors = @[(__bridge id)[[UIColor blackColor] colorWithAlphaComponent:0.5].CGColor,
                                     (__bridge id)[[UIColor blackColor] colorWithAlphaComponent:0.0].CGColor];
            downCoverLayer.startPoint = CGPointMake(0, 1);
            downCoverLayer.endPoint = CGPointMake(0, 0);
            [downCoverView.layer addSublayer:downCoverLayer];
            [self.view addSubview:downCoverView];
            ACCMasMaker(downCoverView, {
                make.left.equalTo(self.view);
                make.right.equalTo(self.view);
                make.bottom.equalTo(self.view);
                make.height.equalTo(@(ACC_IPHONE_X_BOTTOM_OFFSET+AWECustomStickerEditVCBottomMargin));
            });
        }
    } else {
        UIImage *inputImage = self.config.inputImage;
        
        CGSize aniContainerSize = [AWECustomStickerEditContainer containerSizeWithImageSize:inputImage.size maxSize:self.view.frame.size];
        
        self.editContainer = [[AWECustomStickerEditContainer alloc] initWithImage:inputImage aspectRatio:[AWECustomStickerEditContainer aspectRatioWithImageSize:inputImage.size containerSize:aniContainerSize]];
        [self.view addSubview:self.editContainer];
        ACCMasMaker(self.editContainer, {
            make.center.equalTo(self.view);
            make.width.equalTo(@(aniContainerSize.width));
            make.height.equalTo(@(aniContainerSize.height));
        });
        self.editContainer.delegate = self;
        if (!ACCConfigBool(kConfigBool_studio_adjust_black_mask)) {
            UIView *upCoverView = [[UIView alloc] init];
            CAGradientLayer *upCoverLayer = [CAGradientLayer layer];
            upCoverLayer.frame = CGRectMake(0.f, 0.f, CGRectGetWidth(self.view.frame), ACC_STATUS_BAR_HEIGHT+AWECustomStickerEditVCBottomMargin);
            upCoverLayer.colors = @[(__bridge id)[[UIColor blackColor] colorWithAlphaComponent:0.5].CGColor,
                                     (__bridge id)[[UIColor blackColor] colorWithAlphaComponent:0.0].CGColor];
            upCoverLayer.startPoint = CGPointMake(0, 0);
            upCoverLayer.endPoint = CGPointMake(0, 1);
            [upCoverView.layer addSublayer:upCoverLayer];
            [self.view addSubview:upCoverView];
            ACCMasMaker(upCoverView, {
                make.left.equalTo(self.view);
                make.right.equalTo(self.view);
                make.top.equalTo(self.view);
                make.height.equalTo(@(ACC_STATUS_BAR_HEIGHT+AWECustomStickerEditVCBottomMargin));
            });
            
            UIView *downCoverView = [[UIView alloc] init];
            CAGradientLayer *downCoverLayer = [CAGradientLayer layer];
            downCoverLayer.frame = CGRectMake(0.f, 0.f, CGRectGetWidth(self.view.frame), ACC_STATUS_BAR_HEIGHT+AWECustomStickerEditVCBottomMargin);
            downCoverLayer.colors = @[(__bridge id)[[UIColor blackColor] colorWithAlphaComponent:0.5].CGColor,
                                     (__bridge id)[[UIColor blackColor] colorWithAlphaComponent:0.0].CGColor];
            downCoverLayer.startPoint = CGPointMake(0, 1);
            downCoverLayer.endPoint = CGPointMake(0, 0);
            [downCoverView.layer addSublayer:downCoverLayer];
            [self.view addSubview:downCoverView];
            ACCMasMaker(downCoverView, {
                make.left.equalTo(self.view);
                make.right.equalTo(self.view);
                make.bottom.equalTo(self.view);
                make.height.equalTo(@(ACC_IPHONE_X_BOTTOM_OFFSET+AWECustomStickerEditVCBottomMargin));
            });
        }
        
        if([IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin]) {
            self.iconView = [[UIImageView alloc] initWithImage:ACCResourceImage(@"icStickerEditNone")];
            self.iconView.userInteractionEnabled = YES;
            UITapGestureRecognizer *iconGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickOnProcessArea)];
            [self.iconView addGestureRecognizer:iconGesture];
            [self.view addSubview:self.iconView];
            ACCMasMaker(self.iconView, {
                make.left.equalTo(@16);
                make.bottom.equalTo(@(-23-ACC_IPHONE_X_BOTTOM_OFFSET));
                make.width.equalTo(@32);
                make.height.equalTo(@32);
            });
            
            self.statusLabel = [[UILabel alloc] init];
            self.statusLabel.text = ACCLocalizedString(@"creation_edit_sticker_upload_cutout_switch",@"Remove background");
            self.statusLabel.font = [UIFont systemFontOfSize:15.f];
            self.statusLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
            [self.statusLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
            self.statusLabel.userInteractionEnabled = YES;
            UITapGestureRecognizer *labelGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickOnProcessArea)];
            [self.statusLabel addGestureRecognizer:labelGesture];
            [self.view addSubview:self.statusLabel];
            ACCMasMaker(self.statusLabel, {
                make.left.equalTo(@52);
                make.centerY.equalTo(self.iconView);
                make.height.equalTo(@22);
            });
        }
    }
    
    self.confirmLabel = [[UILabel alloc] init];
    self.confirmLabel.backgroundColor = ACCResourceColor(ACCColorPrimary);
    self.confirmLabel.text = ACCLocalizedString(@"creation_edit_sticker_upload_btn",@"OK");
    self.confirmLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
    self.confirmLabel.font = [UIFont systemFontOfSize:15.f];
    self.confirmLabel.textAlignment = NSTextAlignmentCenter;
    self.confirmLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.confirmLabel.layer.cornerRadius = 2.f;
    self.confirmLabel.layer.masksToBounds = YES;
    [self.confirmLabel sizeToFit];
    CGFloat width = CGRectGetWidth(self.confirmLabel.frame);
    if(width < 70) {
        width = 70;
    } else if(width > 100) {
        width = 100;
    }
    self.confirmLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *confirmGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickOnConfirmBtn)];
    [self.confirmLabel addGestureRecognizer:confirmGesture];
    [self.view addSubview:self.confirmLabel];
    ACCMasMaker(self.confirmLabel, {
        make.right.equalTo(@-16);
        make.width.equalTo(@(width));
        make.bottom.equalTo(@(-21-ACC_IPHONE_X_BOTTOM_OFFSET));
        make.height.equalTo(@36);
    });
    
    UIButton *backBtn = [[UIButton alloc] init];
    UIImage *image = ACCResourceImage(@"ic_titlebar_back_white");
    if ([ACCRTL() isRTL]) {
        image = [UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:UIImageOrientationDown];
    }
    [backBtn setImage:image forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(clickOnCancelBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backBtn];
    ACCMasMaker(backBtn, {
        make.left.equalTo(@16);
        make.top.equalTo(@(ACC_STATUS_BAR_NORMAL_HEIGHT+10.f));
        make.width.equalTo(@24);
        make.height.equalTo(@24);
    });
}

- (void)clickOnConfirmBtn
{
    self.loadingView = [ACCLoading() showLoadingOnView:self.view];
    ACCBLOCK_INVOKE(self.completionBlock);
}

- (void)clickOnCancelBtn:(UIButton *)btn
{
    if(self.currentStatus == AWECustomPhotoStickerEditStatusProcess) {
        [ACCNetService() cancel:self.clipRequest];
        self.clipRequest = nil;
        [self updateInfoWithStatus:AWECustomPhotoStickerEditStatusNone];
        [self.editContainer applyUseProcessed:NO];
    } else {
        ACCBLOCK_INVOKE(self.cancelBlock);
    }
}

- (void)saveImageCompleted
{
    [self.loadingView dismiss];
}

- (void)processAnimationCompleted
{
    if(self.config.processedImage) {
        [self updateInfoWithStatus:AWECustomPhotoStickerEditStatusComplete];
    }
}

#pragma mark - Handle Static Process
- (void)clickOnProcessArea
{
    switch (self.currentStatus) {
        case AWECustomPhotoStickerEditStatusNone:
        {
            if(self.config.processedImage) {
                [self updateInfoWithStatus:AWECustomPhotoStickerEditStatusComplete];
                [self.editContainer applyUseProcessed:YES];
            } else {
                [self updateInfoWithStatus:AWECustomPhotoStickerEditStatusProcess];
                [self.editContainer prepareForProcess];
                @weakify(self);
                [ACCMonitor() startTimingForKey:AWECustomStickerAlbumClipTimingKey];
                self.clipRequest = [AWECustomStickerImageProcessor requestProcessedStickerImage:self.config.inputImage completion:^(BOOL success,AWECustomPhotoStickerClipedInfo *info,UIImage *processedImage,NSError *error) {
                    @strongify(self);
                    BOOL clipSuccess = (success && !error && processedImage.size.width && processedImage.size.height);
                    if(clipSuccess) {
                        self.config.processedImage = processedImage;
                        [self.editContainer processWithResult:self.config.processedImage points:info.points maxRect:info.boxRect];
                    } else {
                        if(error.code != -999) {
                            [ACCToast() showError:error.localizedDescription];
                        }
                        [self updateInfoWithStatus:AWECustomPhotoStickerEditStatusNone];
                        [self.editContainer applyUseProcessed:NO];
                    }
                    [ACCMonitor() trackService:@"custom_sticker_imageclip_cost" status:0 extra:@{@"duration":@([ACCMonitor() timeIntervalForKey:AWECustomStickerAlbumClipTimingKey])}];
                    [ACCMonitor() cancelTimingForKey:AWECustomStickerAlbumClipTimingKey];
                    [ACCMonitor() trackService:@"custom_sticker_imageclip_rate" status:clipSuccess ? 0 : 1 extra:@{@"code":@(error.code)}];
                }];
            }
        }
            break;
        case AWECustomPhotoStickerEditStatusComplete:
        {
            [self updateInfoWithStatus:AWECustomPhotoStickerEditStatusNone];
            [self.editContainer applyUseProcessed:NO];
        }
            break;
        default:
            break;
    }
    ACCBLOCK_INVOKE(self.clickOnRemoveBgBlock);
}

- (void)updateInfoWithStatus:(AWECustomPhotoStickerEditStatus)status
{
    switch (status) {
        case AWECustomPhotoStickerEditStatusNone: {
            self.currentStatus = AWECustomPhotoStickerEditStatusNone;
            self.iconView.image = ACCResourceImage(@"icStickerEditNone");
            self.statusLabel.text = ACCLocalizedString(@"creation_edit_sticker_upload_cutout_switch",@"Remove background");
            self.iconView.userInteractionEnabled = YES;
            self.statusLabel.userInteractionEnabled = YES;
            self.confirmLabel.userInteractionEnabled = YES;
            self.iconView.alpha = 1;
            self.statusLabel.alpha = 1;
            self.confirmLabel.alpha = 1;
            self.config.useProcessedData = NO;
        }
            break;
        case AWECustomPhotoStickerEditStatusProcess: {
            self.currentStatus = AWECustomPhotoStickerEditStatusProcess;
            self.iconView.image = ACCResourceImage(@"icStickerEditNone");
            self.statusLabel.text = ACCLocalizedString(@"creation_edit_sticker_upload_cutout_loading",@"Loading...");
            self.iconView.userInteractionEnabled = NO;
            self.statusLabel.userInteractionEnabled = NO;
            self.confirmLabel.userInteractionEnabled = NO;
            self.iconView.alpha = 0.4;
            self.statusLabel.alpha = 0.4;
            self.confirmLabel.alpha = 0.4;
            self.config.useProcessedData = NO;
        }
            break;
        case AWECustomPhotoStickerEditStatusComplete: {
            self.currentStatus = AWECustomPhotoStickerEditStatusComplete;
            self.iconView.image = ACCResourceImage(@"icStickerEditComplete");
            self.statusLabel.text = ACCLocalizedString(@"creation_edit_sticker_upload_cutout_switch",@"Remove background");
            self.iconView.userInteractionEnabled = YES;
            self.statusLabel.userInteractionEnabled = YES;
            self.confirmLabel.userInteractionEnabled = YES;
            self.iconView.alpha = 1;
            self.statusLabel.alpha = 1;
            self.confirmLabel.alpha = 1;
            self.config.useProcessedData = YES;
        }
            break;
        default:
            break;
    }
}

@end
