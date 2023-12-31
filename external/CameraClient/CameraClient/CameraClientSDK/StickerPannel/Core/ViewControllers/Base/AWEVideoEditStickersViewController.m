//
//  AWEVideoEditStickersViewController.m
//  AWEStudio
//
//  Created by guochenxiang on 2018/9/14.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEVideoEditStickersViewController.h"
#import <EffectPlatformSDK/EffectPlatform.h>
#import <CreationKitInfra/ACCSlidingViewController.h>
#import <CreationKitInfra/ACCSlidingTabbarView.h>
#import "AWEVideoEditEmojiStickerCollectionViewController.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "AWESingleStickerDownloader.h"
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import "ACCVideoEditInfoStickerViewController.h"
#import "ACCStickerPannelDataHelper.h"
#import <EffectPlatformSDK/IESInfoStickerModel.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreativeKit/ACCAccessibilityProtocol.h>

static const CGFloat kAWEVideoEditStickerSwitchTabViewHeight = 52;

@interface AWEVideoEditStickersViewController () <ACCSlidingViewControllerDelegate, AWEVideoEditStickerCollectionVCDelegate, ACCVideoEditInfoStickerVCDelegate>

@property (nonatomic, strong) ACCSlidingViewController *slidingViewController;
@property (nonatomic, strong) ACCSlidingTabbarView *slidingTabbarView;

@property (nonatomic, copy) NSArray<NSString *> *panels;
@property (nonatomic, copy) NSArray<NSString *> *titles;

@property (nonatomic, copy) NSArray<IESCategoryModel *> *categories;

@property (nonatomic, strong) AWEVideoEditEmojiStickerCollectionViewController *emojiViewController;
@property (nonatomic, strong) ACCVideoEditInfoStickerViewController *modernInfoStickerViewController;

@property (nonatomic, strong) AWESingleStickerDownloader *stickerDownloader;

@property (nonatomic, strong) UIView *topView;

@end

@implementation AWEVideoEditStickersViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.topOffset = self.uiConfig.pannelTopOffset > 0 ? self.uiConfig.pannelTopOffset : self.topOffset;
    
    [self.view addSubview:self.slidingTabbarView];
    ACCMasMaker(self.slidingTabbarView, {
        make.top.equalTo(self.view.mas_top);
        make.left.right.equalTo(self.view);
        make.height.equalTo(@(kAWEVideoEditStickerSwitchTabViewHeight));
    });
    
    [self.slidingViewController setTabbarView:self.slidingTabbarView];
    [self addChildViewController:self.slidingViewController];
    [self.slidingViewController didMoveToParentViewController:self];
    [self.view addSubview:self.slidingViewController.view];
    ACCMasMaker(self.slidingViewController.view, {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.slidingTabbarView.mas_bottom);
    });
    
    // 设置 tab 和 view controllers
    if (self.enableEmojiSticker) {
        self.titles = @[ACCLocalizedCurrentString(@"com_mig_stickers_eym4co"), ACCLocalizedString(@"im_emoji", @"表情")];
        self.panels = @[@"sticker", @"emoji"];
    } else {
        self.titles = @[ACCLocalizedCurrentString(@"com_mig_stickers_eym4co")];
        self.panels = @[@"sticker"];
    }
    UIFont *normalFont = [self.uiConfig slidingTabbarViewButtonTextNormalFont];
    UIFont *selectedFont = [self.uiConfig slidingTabbarViewButtonTextSelectFont];
    [self.slidingTabbarView configureButtonTextFont:normalFont selectedFont:selectedFont];
    [self.slidingTabbarView resetDataArray:self.titles selectedDataArray:self.titles];
    [self.slidingViewController reloadViewControllers];
    self.slidingViewController.selectedIndex = 0;
    [self.slidingTabbarView configureButtonTextColor:ACCResourceColor(ACCUIColorConstTextInverse3) selectedTextColor:ACCResourceColor(ACCUIColorConstTextInverse)];
    self.slidingTabbarView.selectionLineColor = ACCResourceColor(ACCUIColorConstTextInverse);
    self.slidingTabbarView.shouldShowBottomLine = NO;
    self.slidingTabbarView.topBottomLineColor = ACCUIColorFromRGBA(0xFFFFFF, .12);
    CGFloat seperatorViewHeight = 0.5;
    if ([UIScreen mainScreen].scale > 0) {
        seperatorViewHeight = 1.0f/[UIScreen mainScreen].scale;
    }
    UIView *seperatorView = [[UIView alloc] init];
    seperatorView.backgroundColor = ACCUIColorFromRGBA(0xFFFFFF, .12);
    [self.slidingTabbarView addSubview:seperatorView];
    ACCMasMaker(seperatorView, {
        make.leading.trailing.equalTo(@(0));
        make.bottom.equalTo(self.slidingTabbarView.mas_bottom);
        make.height.equalTo(@(seperatorViewHeight));
    });
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([ACCAccessibility() isVoiceOverOn]) {
        if ([self.topView superview]) {
            [self.topView removeFromSuperview];
        }
        [self.containerVC.view addSubview:self.topView];
        ACCMasMaker(self.topView, {
            make.top.equalTo(self.containerVC.view);
            make.left.right.equalTo(self.containerVC.view);
            make.height.equalTo(@(self.topOffset));
        });
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if ([ACCAccessibility() isVoiceOverOn]) {
        [self.topView removeFromSuperview];
    }
}

- (ACCSlidingTabbarView *)slidingTabbarView
{
    if (!_slidingTabbarView) {
        _slidingTabbarView = [[ACCSlidingTabbarView alloc] initWithFrame:CGRectMake(0, 0, self.view.acc_width, kAWEVideoEditStickerSwitchTabViewHeight) buttonStyle:ACCSlidingTabButtonStyleText dataArray:nil selectedDataArray:nil];
        _slidingTabbarView.selectedIndex = 0;
        _slidingTabbarView.shouldShowBottomLine = YES;
        _slidingTabbarView.shouldShowTopLine = NO;
        [_slidingTabbarView configureButtonTextColor:ACCResourceColor(ACCUIColorConstTextInverse3) selectedTextColor:ACCResourceColor(ACCUIColorConstTextInverse)];
        UIFont *normalFont = [self.uiConfig slidingTabbarViewButtonTextNormalFont];
        UIFont *selectedFont = [self.uiConfig slidingTabbarViewButtonTextSelectFont];
        [_slidingTabbarView configureButtonTextFont:normalFont hasShadow:YES];
        [_slidingTabbarView configureButtonTextFont:normalFont selectedFont:selectedFont];
        _slidingTabbarView.selectionLineColor = [UIColor clearColor];
        _slidingTabbarView.topBottomLineColor = ACCUIColorFromRGBA(0xFFFFFF, .12);
    }
    return _slidingTabbarView;
}

- (ACCSlidingViewController *)slidingViewController
{
    if (!_slidingViewController) {
        _slidingViewController = [[ACCSlidingViewController alloc] init];
        _slidingViewController.slideEnabled = YES;
        _slidingViewController.delegate = self;
    }
    return _slidingViewController;
}

- (void)setCategories:(NSArray<IESCategoryModel *> *)categories
{
    _categories = categories;
    NSMutableArray *titleArray = [NSMutableArray array];
    for (IESCategoryModel *model in categories) {
        [titleArray addObject:model.categoryName ? : @""];
    }
    _titles = [titleArray copy];
}

#pragma mark - ACCSlidingViewControllerDelegate

- (NSInteger)numberOfControllers:(ACCSlidingViewController *)slidingController
{
    return self.panels.count;
}

- (UIViewController *)slidingViewController:(ACCSlidingViewController *)slidingViewController viewControllerAtIndex:(NSInteger)index
{
    if (index >= self.panels.count) {
        return [[UIViewController alloc] init];
    }
    NSString *panel = self.panels[index];
    
    if ([panel isEqualToString:@"emoji"]) {
        return self.emojiViewController;
    } else {
        return self.modernInfoStickerViewController;
    }
}

- (void)slidingViewController:(ACCSlidingViewController *)slidingViewController didSelectIndex:(NSInteger)index
{
    [self.logger logSlidingDidSelectIndex:index title:[self.titles objectAtIndex:index]];
}

#pragma mark - AWEVideoEditStickerCollectionVCDelegate

- (void)stickerCollectionViewController:(AWEVideoEditStickerCollectionViewController *)stickerCollectionVC
                       didSelectSticker:(IESEffectModel *)sticker
                                atIndex:(NSInteger)index
                                categoryName:(NSString *)categoryName
                                     tabName:(NSString *)tabName
                  downloadProgressBlock:(void(^)(CGFloat))downloadProgressBlock
                        downloadedBlock:(void(^)(void))downloadedBlock
{    
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoEditStickersViewController: didSelectSticker:fromTab:downloadProgressBlock:downloadedBlock:)]) {
        [self.delegate videoEditStickersViewController:self didSelectSticker:sticker fromTab:tabName downloadProgressBlock:downloadProgressBlock downloadedBlock:downloadedBlock];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerViewController:didSelectSticker:fromTab:downloadTrigger:)]) {
        @weakify(self);
        [self.delegate stickerViewController:self didSelectSticker:sticker fromTab:tabName downloadTrigger:^{
            @strongify(self);
            void(^compeletion)(AWESingleStickerDownloadInfo * _Nonnull downloadInfo) = ^(AWESingleStickerDownloadInfo * _Nonnull downloadInfo) {
                @strongify(self);
                ACCBLOCK_INVOKE(downloadedBlock);
                [self.logger logStickerDownloadFinished:downloadInfo];
                if (downloadInfo.result.failed) {
                    [ACCToast() showError:ACCLocalizedCurrentString(@"com_mig_stickers_are_not_available")];
                } else {
                    [self.delegate stickerViewController:self didSelectSticker:sticker fromTab:tabName downloadTrigger:nil];
                }
            };
            AWESingleStickerDownloadParameter *download = [AWESingleStickerDownloadParameter new];
            download.sticker = sticker;
            download.downloadProgressBlock = downloadProgressBlock;
            download.compeletion = compeletion;
            [self.stickerDownloader downloadSticker:download];
        }];
    }
}

- (void)modernStickerCollectionVC:(ACCVideoEditInfoStickerViewController *)stickerCollectionVC
                 didSelectSticker:(IESInfoStickerModel *)sticker
                          atIndex:(NSInteger)index
                     categoryName:(NSString *)categoryName
                          tabName:(NSString *)tabName
            downloadProgressBlock:(void(^)(CGFloat))downloadProgressBlock
                  downloadedBlock:(void(^)(void))downloadedBlock
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoEditStickersViewController: didSelectSticker:fromTab:downloadProgressBlock:downloadedBlock:)]) {
        [self.delegate videoEditStickersViewController:self didSelectSticker:sticker.effectModel fromTab:tabName downloadProgressBlock:downloadProgressBlock downloadedBlock:downloadedBlock];
    }
    if (sticker.dataSource == IESInfoStickerModelSourceLoki && [self.delegate respondsToSelector:@selector(stickerViewController:didSelectSticker:fromTab:downloadTrigger:)]) {
        [self.delegate stickerViewController:self didSelectSticker:sticker.effectModel fromTab:tabName downloadTrigger:^{
            [ACCStickerPannelDataHelper downloadInfoSticker:sticker trackParams:self.dataConfig.trackParams progressBlock:downloadProgressBlock completion:^(NSError *error, NSString *filePath) {
                ACCBLOCK_INVOKE(downloadedBlock);
                if (error || !filePath) {
                    [ACCToast() showError:ACCLocalizedCurrentString(@"com_mig_stickers_are_not_available")];
                } else {
                    [self.delegate stickerViewController:self didSelectSticker:sticker.effectModel fromTab:tabName downloadTrigger:nil];
                }
                AWELogToolError(AWELogToolTagEdit, @"modern sticker pannel loki download error: %@", error);
            }];
        }];
    }
    if (sticker.dataSource == IESInfoStickerModelSourceThirdParty && [self.delegate respondsToSelector:@selector(stickerViewController:didSelectThirdPartySticker:fromTab:downloadTrigger:)]) {
        [self.delegate stickerViewController:self didSelectThirdPartySticker:sticker.thirdPartyStickerModel fromTab:tabName downloadTrigger:^{
            [ACCStickerPannelDataHelper downloadInfoSticker:sticker trackParams:self.dataConfig.trackParams progressBlock:downloadProgressBlock completion:^(NSError *error, NSString *filePath) {
                ACCBLOCK_INVOKE(downloadedBlock);
                if (error || !filePath) {
                    [ACCToast() showError:ACCLocalizedCurrentString(@"com_mig_stickers_are_not_available")];
                } else {
                    [self.delegate stickerViewController:self didSelectThirdPartySticker:sticker.thirdPartyStickerModel fromTab:tabName downloadTrigger:nil];
                }
                AWELogToolError(AWELogToolTagEdit, @"modern sticker pannel thirdparty download error: %@", error);
            }];
        }];
    }
}

- (AWESingleStickerDownloader *)stickerDownloader {
    if (!_stickerDownloader) {
        _stickerDownloader = [AWESingleStickerDownloader new];
    }
    return _stickerDownloader;
}

#pragma mark - Getters

- (AWEVideoEditEmojiStickerCollectionViewController *)emojiViewController
{
    if (!_emojiViewController) {
        _emojiViewController = [[AWEVideoEditEmojiStickerCollectionViewController alloc] init];
        _emojiViewController.uiConfig = self.uiConfig;
        _emojiViewController.delegate = self;
        _emojiViewController.logger = self.logger;
    }
    return _emojiViewController;
}

- (ACCVideoEditInfoStickerViewController *)modernInfoStickerViewController
{
    if (!_modernInfoStickerViewController) {
        _modernInfoStickerViewController = [[ACCVideoEditInfoStickerViewController alloc] init];
        _modernInfoStickerViewController.uiConfig = self.uiConfig;
        _modernInfoStickerViewController.delegate = self;
        _modernInfoStickerViewController.pannelFilter = self.pannelFilter;
        _modernInfoStickerViewController.logger = self.logger;
    }
    return _modernInfoStickerViewController;
}

#pragma mark - UIAccessibility

- (BOOL)accessibilityPerformEscape
{
    [self.transitionDelegate stickerPannelVCDidDismiss];
    [self removeWithCompletion:nil];
    return YES;
}

- (UIView *)topView
{
    if (!_topView) {
        _topView = [[UIView alloc] init];
        _topView.backgroundColor = [UIColor clearColor];
        _topView.isAccessibilityElement = YES;
        _topView.accessibilityLabel = @"关闭";
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self  action:@selector(dismissPanel)];
        [_topView addGestureRecognizer:tap];
    }
    return _topView;
}

- (void)dismissPanel
{
    [self removeWithCompletion:nil];
}

@end
