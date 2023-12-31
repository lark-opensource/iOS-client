//
//  ACCSearchStickerComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/2/13.
//

#import "ACCSearchStickerComponent.h"
#import "ACCStickerServiceProtocol.h"
#import "ACCVideoEditFlowControlViewModel.h"
#import "ACCSearchStickerViewController.h"
#import "ACCStickerSearchViewModel.h"
#import "ACCConfigKeyDefines.h"
#import "ACCStickerPanelServiceProtocol.h"
#import <CreationKitInfra/ACCLogHelper.h>
#import "ACCStickerPannelDataHelper.h"
#import "ACCVideoEditFlowControlService.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import <EffectPlatformSDK/EffectPlatform+InfoSticker.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CameraClient/ACCStickerPannelFilterImpl.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CameraClient/ACCStickerPannelFilterImpl.h>
#import "ACCStudioGlobalConfig.h"
#import "AWERepoTrackModel.h"

@interface ACCSearchStickerComponent()<ACCStickerPannelObserver, ACCStickerPannelAnimationVCDelegate, ACCSearchStickerVCDelegate, ACCStickerPannelFilterDataSource>

@property (nonatomic, weak) id<ACCStickerPanelServiceProtocol> stickerPanelService;
@property (nonatomic, weak) id<ACCStickerServiceProtocol> stickerService;
@property (nonatomic, weak) id<ACCVideoEditFlowControlService> flowControlService;
@property (nonatomic, strong) ACCStickerSearchViewModel *viewModel;

@property (nonatomic, weak) ACCSearchStickerViewController *searchVC;
@property (nonatomic, weak) UIView *searchStickerBgView;

@property (nonatomic, assign) BOOL showingSearchVC;
@property (nonatomic, copy, nullable) void (^dismissPanelHandle)(ACCStickerType, BOOL);

@end

@implementation ACCSearchStickerComponent

IESAutoInject(self.serviceProvider, stickerPanelService, ACCStickerPanelServiceProtocol)
IESAutoInject(self.serviceProvider, stickerService, ACCStickerServiceProtocol)
IESAutoInject(self.serviceProvider, flowControlService, ACCVideoEditFlowControlService)

- (void)componentDidMount
{
    [self.stickerPanelService registObserver:self];
    @weakify(self);
    // 自定义，POI等有二级页面的贴纸添加完毕后的回调
    [self.stickerPanelService.willDismissStickerPanelSignal subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        if (self.showingSearchVC) {
            [self.searchStickerBgView removeFromSuperview];
            [self.searchVC removeWithoutAnimation];
            self.showingSearchVC = NO;
        }
    }];
}

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCSearchStickerServiceProtocol), self.viewModel);
}

#pragma mark - ACCStickerPannelObserver
- (BOOL)handleSelectSticker:(IESEffectModel *)sticker
                    fromTab:(NSString *)tabName
           willSelectHandle:(dispatch_block_t)willSelectHandle
         dismissPanelHandle:(void (^)(ACCStickerType type, BOOL animated))dismissPanelHandle
{
    NSString *result = [sticker.tags acc_match:^BOOL(NSString * _Nonnull item) {
        return [item.lowercaseString isEqualToString:@"searchsticker"];
    }];
    
    ACCBLOCK_INVOKE(willSelectHandle);
    if (!result) {
        return NO;
    }
    if (self.searchVC) {
        return YES;
    }
    self.dismissPanelHandle = dismissPanelHandle;
    
    ACCSearchStickerViewController *searchVC = [[ACCSearchStickerViewController alloc] init];
    searchVC.uploadFramesURI = self.repository.repoMusic.zipURI;
    searchVC.creationId = self.repository.repoContext.createId;
    searchVC.enterStatus = self.repository.repoTrack.enterStatus;
    searchVC.useAutoSearch = (ACCConfigEnum(kConfigInt_search_sticker_type, ACCEditSearchStickerType) == ACCEditSearchStickerTypeAuto);
    searchVC.containerVC = self.rootVC;
    searchVC.transitionDelegate = self;
    searchVC.delegate = self;
    ACCStickerPannelFilterImpl *impl = [[ACCStickerPannelFilterImpl alloc] init];
    impl.repository = self.repository;
    impl.dataSource = self;
    searchVC.filterTags = [impl filterTags];
    self.searchVC = searchVC;
    [self searchStickerCollectionViewControllerWillShow];
    [self searchTrackEvent:@"enter_infosticker_search" extraParams:nil];
    
    return YES;
}

- (ACCStickerPannelObserverPriority)stikerPriority
{
    return ACCStickerPannelObserverPrioritySearch;
}

#pragma mark SearchStickerDelegate
- (void)searchStickerCollectionViewController:(ACCSearchStickerViewController *)stickerCollectionVC didSelectSticker:(IESInfoStickerModel *)sticker indexPath:(NSIndexPath *)indexPath downloadProgressBlock:(void (^)(CGFloat))downloadProgressBlock downloadedBlock:(void (^)(BOOL))downloadedBlock
{
    @weakify(self);
    [ACCStickerPannelDataHelper downloadInfoSticker:sticker trackParams:self.repository.repoTrack.commonTrackInfoDic progressBlock:^(CGFloat progress) {
        ACCBLOCK_INVOKE(downloadProgressBlock, progress);
    } completion:^(NSError *error, NSString *filePath) {
        @strongify(self);
        if (error || !filePath) {
            ACCBLOCK_INVOKE(downloadedBlock, NO);
            AWELogToolError(AWELogToolTagEdit, @"search info sticker download error: %@", error);
        } else {
            ACCBLOCK_INVOKE(downloadedBlock, YES);
            [self.viewModel addSearchSticker:sticker path:filePath completion:nil];
        }
    }];
}

- (void)searchStickerCollectionViewControllerWillShow
{
    self.showingSearchVC = YES;
    if (!self.searchStickerBgView) {
        UIView *searchStickerBgView = [[UIView alloc] initWithFrame:self.rootVC.view.bounds];
        [self.rootVC.view addSubview:searchStickerBgView];
        [searchStickerBgView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(searchStickerCollectionViewControllerDismiss)]];
        self.searchStickerBgView = searchStickerBgView;
    }
    [self.searchVC showWithoutAnimation];
    [self.viewModel configPannlStatus:NO];
}

// 返回贴纸面板
- (void)searchStickerCollectionViewControllerWillExit
{
    self.showingSearchVC = NO;
    [self.searchStickerBgView removeFromSuperview];
    [self.viewModel configPannlStatus:YES];
    [self.searchVC removeWithoutAnimation];
}

// 点击背景板收起搜索+贴纸面板
- (void)searchStickerCollectionViewControllerDismiss
{
    [self.searchVC removeWithCompletion:nil];
    [self stickerPannelVCDidDismiss];
}

// 下拉搜索收起搜索+贴纸面板
- (void)stickerPannelVCDidDismiss
{
    self.showingSearchVC = NO;
    [self.searchStickerBgView removeFromSuperview];
    ACCBLOCK_INVOKE(self.dismissPanelHandle, ACCStickerTypeSearchSticker, NO);
    self.dismissPanelHandle = nil;
}

- (void)searchTrackEvent:(NSString *)event extraParams:(nullable NSDictionary *)params
{
    NSMutableDictionary *dict = [self.repository.repoTrack.referExtra mutableCopy];
    if (params) {
        [dict addEntriesFromDictionary:params];
    }
    [ACCTracker() trackEvent:event params:[dict copy]];
}

#pragma mark - ACCStickerPannelFilterDataSource
- (BOOL)canOpenLiveSticker
{
    return self.flowControlService.uploadParamsCache.settingsParameters.hasLive.boolValue && [ACCStudioGlobalConfig() shouldKeepLiveMode];
}

#pragma mark - Getter
- (UIViewController *)rootVC
{
    return self.controller.root;
}

- (ACCStickerSearchViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [[ACCStickerSearchViewModel alloc] init];
    }
    return _viewModel;
}

@end
