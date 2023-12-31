//
//  ACCEditHRDComponent.m
//  Pods
//
//  Created by 郝一鹏 on 2019/9/25.
//
#import "ACCEditHDRComponent.h"
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCEditViewContainer.h>
#import "ACCEditorDraftService.h"
#import "ACCVideoEditToolBarDefinition.h"
#import "ACCEditHDRViewModel.h"
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import "NSObject+ACCEventContext.h"
#import "AWEHDRModelManager.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreativeKit/ACCAPMProtocol.h>
#import "ACCEditClipServiceProtocol.h"
#import "ACCEditClipV1ServiceProtocol.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import "ACCRepoImageAlbumInfoModel.h"
#import <CreationKitArch/ACCRepoDraftModel.h>
#import "AWERepoVideoInfoModel.h"
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import "ACCEditBarItemExtraData.h"
#import "ACCRepoKaraokeModelProtocol.h"
#import "ACCEditHDRProtocolD.h"
#import <CreativeKit/ACCProtocolContainer.h>
#import "AWERepoTrackModel.h"
#import "ACCBarItem+Adapter.h"
#import <CameraClient/ACCRepoSmartMovieInfoModel.h>

static const NSInteger kACCEditHDRDefaultScene = 20000;
static NSString *const kAWENormalVideoEditAndPublishVCShowHDRKey = @"kAWENormalVideoEditAndPublishVCShowHDRKey";

@interface ACCEditHDRComponent ()
@property (nonatomic, weak) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, strong) ACCEditHDRViewModel *viewModel;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCEditClipServiceProtocol> clipService;
@property (nonatomic, weak) id<ACCEditClipV1ServiceProtocol> clipV1Service;

@property (nonatomic, assign) BOOL useOneKeyHDR;
@property (nonatomic, assign) BOOL detectionSucceed;

@end


@implementation ACCEditHDRComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, clipService, ACCEditClipServiceProtocol)
IESAutoInject(self.serviceProvider, clipV1Service, ACCEditClipV1ServiceProtocol)

#pragma mark - life cycle

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

- (void)loadComponentView {
    if ([self.viewModel enableVideoHDR]) {
        [self.viewContainer addToolBarBarItem:[self p_barItem]];
        self.useOneKeyHDR = [self p_shouldUseOneKeyHDR];
        if (self.useOneKeyHDR && !ACCConfigBool(kConfigBool_use_optimized_hdr_detection)) {
            @weakify(self)
            [ACCGetProtocol(self.editService.hdr, ACCEditHDRProtocolD) startMatchingAlgorithmWithVideoData:self.repository.repoVideoInfo.video completion:^(int scene) {
                @strongify(self)
                self.detectionSucceed = YES;
                [self p_restoreHDRNetState];
            }];
        } else {
            [self p_restoreHDRNetState];
        }
    }
}

- (void)componentDidMount {
    // 直接进编辑页，下载算法
    [AWEHDRModelManager downloadAlgorithmModelIfNeeded];
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    
    BOOL needRecoverMode = (self.viewModel.inputData.publishModel.repoDraft.isDraft ||
                            self.viewModel.inputData.publishModel.repoDraft.isBackUp ||
                            self.viewModel.inputData.publishModel.repoImageAlbumInfo.isTransformedFromImageAlbumMVVideoEditMode ||
                            [self.repository.repoSmartMovie transformedForSmartMovie]);
    
    if (self.viewModel.inputData.publishModel.repoVideoInfo.enableHDRNet && needRecoverMode) {
        [self p_setHDRNetEnabled:self.viewModel.inputData.publishModel.repoVideoInfo.enableHDRNet];
    }
    [self p_bindViewModel];
}

- (void)componentWillAppear
{
    if (![self.controller enableFirstRenderOptimize]) {
        [self p_restoreHDRNetState];
    }
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

#pragma mark - private methods

- (void)p_bindViewModel
{
    @weakify(self);
    [self.viewModel.clearHDRSignal.deliverOnMainThread subscribeNext:^(NSNumber *x) {
        @strongify(self);
        if (x.boolValue) {
            [self p_setHDRNetEnabled:NO];
            [self p_videoEnhanceButton].selected = NO;
        }
    }];
    NSMutableArray *signalList = @[].mutableCopy;
    [signalList acc_addObject:self.clipService.removeAllEditsSignal];
    [signalList acc_addObject:self.clipV1Service.removeAllEditsSignal];
    RACSignal *mergeSignal = [RACSignal merge:signalList.copy];
    [mergeSignal subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self.viewModel clearHDR];
    }];
    
    [self.clipV1Service.didFinishClipEditSignal subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        [self p_restoreHDRNetState];
    }];
}

- (ACCBarItem<ACCEditBarItemExtraData*>*)p_barItem {
    let config = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarVideoEnhanceContext];
    if (!config) return nil;

    ACCBarItem<ACCEditBarItemExtraData*>* bar = [[ACCBarItem alloc] init];
    bar.title = config.title;
    bar.imageName = config.imageName;
    bar.location = config.location;
    bar.selectedImageName = config.selectedImageName;
    bar.itemId = ACCEditToolBarVideoEnhanceContext;
    bar.type = ACCBarItemFunctionTypeDefault;
    NSString *title = [config.title copy];

    bar.barItemViewConfigBlock = ^(UIView * _Nonnull itemView) {
        UIButton *barItemButton;
        if ([itemView isKindOfClass:[AWEEditActionItemView class]]) {
            AWEEditActionItemView *editItemView = (AWEEditActionItemView*)itemView;
            barItemButton = editItemView.button;
        } else if ([itemView isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)itemView;
            barItemButton = button;
        }
        if (barItemButton) {
            barItemButton.isAccessibilityElement = YES;
            barItemButton.accessibilityTraits = UIAccessibilityTraitButton;
            barItemButton.accessibilityLabel = [NSString stringWithFormat:@"%@%@", title, barItemButton.selected ? @"已开启" : @"已关闭"];
        }
    };

    @weakify(self);
    bar.barItemActionBlock = ^(UIView * _Nonnull itemView) {
        @strongify(self);
        if (!self.isMounted) {
            return;
        }
        UIButton *barItemButton;
        if ([itemView isKindOfClass:[AWEEditActionItemView class]]) {
            AWEEditActionItemView *editItemView = (AWEEditActionItemView*)itemView;
            editItemView.button.selected = !editItemView.button.selected;
            barItemButton = editItemView.button;
            [self p_editAndPublishViewVideoHDRButtonClicked:editItemView.button];
        } else if ([itemView isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)itemView;
            button.selected = !button.selected;
            barItemButton = button;
            [self p_editAndPublishViewVideoHDRButtonClicked:button];
        }
        if (barItemButton) {
            barItemButton.accessibilityLabel = [NSString stringWithFormat:@"%@%@", title, barItemButton.selected ? @"已开启" : @"已关闭"];
        }
    };
    bar.extraData = [[ACCEditBarItemExtraData alloc] initWithButtonClass:nil type:AWEEditAndPublishViewDataTypeVideoEnhance];
    return bar;
}

- (void)p_editAndPublishViewVideoHDRButtonClicked:(UIButton *)button
{
    BOOL enable = button.selected;

    if (!enable || !ACCConfigBool(kConfigBool_use_optimized_hdr_detection) || self.detectionSucceed || !self.useOneKeyHDR) {
        [self p_setHDRNetEnabled:enable];
    } else {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [ACCGetProtocol(self.editService.hdr, ACCEditHDRProtocolD) detectHDRScene];
            self.detectionSucceed = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self p_setHDRNetEnabled:enable];
            });
        });
    }
    [self p_trackHDRNet:enable];
    
    let draftService = IESAutoInline(self.serviceProvider, ACCEditorDraftService);
    NSAssert(draftService, @"should not be nil");
    [draftService hadBeenModified];
}

- (void)p_setHDRNetEnabled:(BOOL)enabled
{
    NSInteger hdrScene = 0;
    if (enabled) {
        if (self.useOneKeyHDR) {
            hdrScene = [self.editService.hdr currentScene];
            NSString *modelPath = [AWEHDRModelManager modelPathForScene:[self.editService.hdr currentScene]];
            [self.editService.hdr enableOneKeyHDRWithModel:modelPath
                                            disableDenoise:[self p_shouldDisableDenoise]
                                                   asfMode:ACCConfigInt(kConfigInt_asf_mode)
                                                   hdrMode:ACCConfigInt(kConfigInt_hdr_mode)];
        } else {
            hdrScene = kACCEditHDRDefaultScene;
            NSString *path = [AWEHDRModelManager lensModelPath];
            if (ACC_isEmptyString(path) || ![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                AWELogToolError(AWELogToolTagEffectPlatform, @"Could not find hdr model path");
                enabled = NO;
            }
            [self.editService.hdr enableLensHDRWithModelPath:path];
        }
    } else {
        if (self.useOneKeyHDR) {
            [self.editService.hdr disableOneKeyHDR];
        } else {
            [self.editService.hdr disableLensHDR];
        }
    }
    self.repository.repoTrack.hdrScene = hdrScene;
    [ACCAPM() attachFilter:@(enabled) forKey:@"hdr_enabled"];
    self.viewModel.inputData.publishModel.repoVideoInfo.enableHDRNet = enabled;
}

- (UIButton *)p_videoEnhanceButton
{
    return [self.viewContainer viewWithBarItemID:ACCEditToolBarVideoEnhanceContext].button;
}

- (void)p_restoreHDRNetState
{
    if (![self.viewModel enableVideoHDR]) {
        return;
    }
    if (self.viewModel.inputData.publishModel.repoVideoInfo.enableHDRNet) {
        [self p_setHDRNetEnabled:YES];
        // 如果草稿箱返回有画质增强，则设置对应的按钮状态
        [self p_videoEnhanceButton].selected = YES;
    }
}

- (void)p_trackHDRNet:(BOOL)enable
{
    NSDictionary *referExtra = self.viewModel.inputData.publishModel.repoTrack.referExtra;

    [self.containerViewController acc_trackEvent:@"click_quality_improve" attributes:^(ACCAttributeBuilder *build) {
        build.enterFrom.equalTo(@"video_edit_page");
        build.attribute(@"to_status").equalTo(enable ? @"on" : @"off");
        build.attribute(@"creation_id").equalTo(self.viewModel.inputData.publishModel.repoContext.createId);
        build.attribute(@"content_type").equalTo(referExtra[@"content_type"]);
        build.attribute(@"shoot_way").equalTo(referExtra[@"shoot_way"]);
        build.attribute(@"content_source").equalTo(referExtra[@"content_source"]);
        build.attribute(@"improve_method").equalTo(@"hdr");
        build.attribute(@"is_multi_content").equalTo(self.viewModel.inputData.publishModel.repoTrack.mediaCountInfo[@"is_multi_content"]);
        if (self.viewModel.inputData.publishModel.repoContext.videoType == AWEVideoTypeKaraoke) {
            id<ACCRepoKaraokeModelProtocol> repoModel = [self.viewModel.inputData.publishModel extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
            build.attribute(@"music_id").equalTo(repoModel.trackParams[@"music_id"]);
            build.attribute(@"pop_music_id").equalTo(repoModel.trackParams[@"pop_music_id"]);
            build.attribute(@"pop_music_type").equalTo(repoModel.trackParams[@"pop_music_type"]);
        }
    }];

}

#pragma mark - getter

- (ACCEditHDRViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self.modelFactory createViewModel:ACCEditHDRViewModel.class];
    }
    return _viewModel;
}

- (UIViewController *)containerViewController
{
    if ([self.controller isKindOfClass:[UIViewController class]]) {
        return (UIViewController *)self.controller;
    }
    NSAssert(nil, @"exception");
    return nil;
}

#pragma mark - Private Helper

- (BOOL)p_shouldUseOneKeyHDR
{
    if (!ACCConfigBool(kConfigBool_use_one_key_lens_hdr_denoise) && !ACCConfigBool(kConfigBool_use_one_key_lens_hdr_no_denoise)) {
        return NO;
    }
    if (!self.repository.repoVideoInfo.video.crossplatInput) {
        return NO;
    }
    if ([self.repository.repoVideoInfo.video.videoAssets count] == 1 && self.repository.repoContext.videoType != AWEVideoTypePhotoToVideo) {
        return YES;
    }
    return NO;
}

- (BOOL)p_shouldDisableDenoise
{
    if (ACCConfigBool(kConfigBool_use_one_key_lens_hdr_denoise) && [self.editService.hdr shouldUseDenoise] && self.repository.repoVideoInfo.video.crossplatInput) {
        return NO;
    }
    return YES;
}

- (void)handleAlgorithmCheckFinishedWithScene:(int)scene maxCacheSize:(NSInteger)maxCacheSize
{
    
}

- (void)handleHDRStatus:(BOOL)hdrOn useOneKey:(BOOL)useOneKey useOpt:(BOOL)useOpt  scene:(int)scene modelName:(NSString *)modelName useDenoise:(BOOL)useDenoise asfMode:(NSInteger)asfMode hdrMode:(NSInteger)hdrMod
{
    
}

#pragma mark - Draft recover

+ (NSArray <NSString *> *)requirementsToDownloadForPublishViewModel:(AWEVideoPublishViewModel *)publishModel
{
    return @[];
}

+ (NSArray <NSString *> *)modelsToDownloadForPublishViewModel:(AWEVideoPublishViewModel *)publishModel
{
    if ([AWEHDRModelManager enableVideoHDR]) { // 下载完成后 enableVideoHDR 才为 YES
        return nil;
    }
    NSArray <NSString *>* models = [AWEHDRModelManager lensHDRModelNames];
    return models;
}

+ (NSArray <NSString *> *)draftResourceIDsToDownloadForPublishViewModel:(AWEVideoPublishViewModel *)publishModel
{
    return @[];
}

@end
