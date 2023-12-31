//
//  ACCEditorStickerComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/6/29.
//

#import "ACCEditorStickerComponent.h"
#import "ACCVideoEditStickerContainerConfig.h"
#import "AWEXScreenAdaptManager.h"
#import "ACCConfigKeyDefines.h"
#import <CreativeKitSticker/ACCStickerContainerView.h>
#import "ACCStickerServiceImpl.h"

#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "ACCRepoTextModeModel.h"
#import "AWERepoStickerModel.h"
#import "AWERepoDraftModel.h"

#import "ACCSocialStickerHandler.h"
#import "ACCModernPOIStickerHandler.h"
#import "ACCInfoStickerHandler.h"
#import "ACCCustomStickerHandler.h"
#import "ACCTextStickerHandler.h"

#import "ACCTextStickerDataProvider.h"
#import "ACCSocialStickerDataProvider.h"
#import "ACCPOIStickerDataProvider.h"

#import <CreationKitArch/AWEDraftUtils.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import "ACCEditViewControllerInputData.h"
#import <CreativeKit/ACCServiceBinding.h>
#import "ACCCanvasStickerHandler.h"
#import "ACCEditStickerBizModule.h"
#import "ACCStickerPlayerApplyingImpl.h"
#import "ACCStickerLoggerImpl.h"
#import "ACCStickerHandler+Private.h"

@interface ACCEditorStickerComponent ()

@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;

@property (nonatomic, strong) ACCTextStickerDataProvider *textStickerDataProvider;
@property (nonatomic, strong) ACCSocialStickerDataProvider *socialStickerDataProvider;
@property (nonatomic, strong) ACCPOIStickerDataProvider *POIStickerDataProvider;

@property (nonatomic, strong) ACCStickerServiceImpl *stickerService;
@property (nonatomic, strong) ACCCanvasStickerHandler *canvasStickerHandler;
@property (nonatomic, strong) ACCEditStickerBizModule *stickerBizModule;
@property (nonatomic, strong) ACCStickerContainerView *stickerContainerView;

@end

@implementation ACCEditorStickerComponent
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)

- (void)registerServiceBinding:(ACCServiceBinding *)serviceBinding intoServiceContainer:(id<IESServiceRegister>)serviceProvider
{
    if (serviceBinding.serciceProtocol) {
        [serviceProvider registerInstance:serviceBinding.serviceImpl forProtocol:serviceBinding.serciceProtocol];
    } else if (serviceBinding.serciceProtocols) {
        [serviceProvider registerInstance:serviceBinding.serviceImpl forProtocols:serviceBinding.serciceProtocols];
    }
}

- (void)buildStickerHandler
{
    ACCStickerPlayerApplyingImpl *playerImpl = [[ACCStickerPlayerApplyingImpl alloc] init];
    playerImpl.editService = self.editService;
    playerImpl.stickerService = self.stickerService;
    playerImpl.repository = self.repository;
    playerImpl.isIMRecord = NO;
    self.stickerService.compoundHandler.player = playerImpl;
    ACCStickerLoggerImpl *logger = [ACCStickerLoggerImpl new];
    logger.publishModel = self.repository;
    self.stickerService.compoundHandler.stickerContainerView = self.stickerContainerView;
    @weakify(self);
    self.stickerService.compoundHandler.stickerContainerLoader = ^ACCStickerContainerView * _Nonnull{
        @strongify(self);
        return self.stickerContainerView;
    };
}

- (void)setupStickerServiceForSilentPublishWithPlayerFrame:(CGRect)playerFrame
{
    ACCStickerServiceImpl *stickerService = [[ACCStickerServiceImpl alloc] init];
    stickerService.repository = self.repository;
    stickerService.editService = self.editService;
    self.stickerService = stickerService;
    [self registerServiceBinding:ACCCreateMutipleServiceBinding(@[@protocol(ACCStickerServiceProtocol), @protocol(ACCEditStickerServiceImplProtocol)], self.stickerService) intoServiceContainer:self.serviceProvider];

    self.stickerContainerView = [self stickerContainerForSilentPublishWithPlayerFrame:playerFrame];
    stickerService.stickerContainer = self.stickerContainerView;
    [self buildStickerHandler];

    ACCInfoStickerHandler *infoStickerHandler = [[ACCInfoStickerHandler alloc] init];
    infoStickerHandler.editService = self.editService;
    infoStickerHandler.repository = self.repository;

    [stickerService registStickerHandler:infoStickerHandler];
    [stickerService registStickerHandler:({
        ACCCustomStickerHandler *handler = [[ACCCustomStickerHandler alloc] init];
        handler.editService = [self editService];
        handler.infoStickerHandler = infoStickerHandler;
        handler.repository = self.repository;
        handler;
    })];
    
    self.textStickerDataProvider = [[ACCTextStickerDataProvider alloc] init];
    self.textStickerDataProvider.serviceProvider = self.serviceProvider;
    self.textStickerDataProvider.repository = self.repository;
    self.socialStickerDataProvider = [[ACCSocialStickerDataProvider alloc] init];
    self.socialStickerDataProvider.repository = self.repository;
    self.POIStickerDataProvider = [[ACCPOIStickerDataProvider alloc] init];
    self.POIStickerDataProvider.repository = self.repository;
    self.POIStickerDataProvider.serviceProvider = self.serviceProvider;

    ACCTextStickerHandler *textStickerHandler = [[ACCTextStickerHandler alloc] init];
    textStickerHandler.publishViewModel = self.repository;
    textStickerHandler.dataProvider = self.textStickerDataProvider;
    @weakify(self);
    textStickerHandler.onStickerApplySuccess = ^{
        @strongify(self);
        self.repository.repoSticker.hasTextAdded = YES;
    };
    textStickerHandler.stylePreferenceModel = [self textStickerStylePreferenceWithRepository:self.repository];
    [stickerService registStickerHandler:textStickerHandler];

    ACCSocialStickerHandler *socialStickerHandler = [[ACCSocialStickerHandler alloc] initWithDataProvider:self.socialStickerDataProvider publishModel:self.repository];
    [stickerService registStickerHandler:socialStickerHandler];

    ACCModernPOIStickerHandler *POIStickerhandler = [[ACCModernPOIStickerHandler alloc] init];
    POIStickerhandler.dataProvider = self.POIStickerDataProvider;
    POIStickerhandler.onStickerApplySuccess = ^{
        @strongify(self);
        [self onPOIStickerApplySuccess];
    };
    self.canvasStickerHandler = [[ACCCanvasStickerHandler alloc] initWithRepository:self.repository];
    self.canvasStickerHandler.editService = [self editService];
    [self.stickerService registStickerHandler:self.canvasStickerHandler];
}

- (void)setupWithCompletion:(void (^)(NSError *))completion
{
    self.stickerBizModule = [[ACCEditStickerBizModule alloc] initWithServiceProvider:self.serviceProvider];

    CGRect playerFrame = [self editService].mediaContainerView.frame;
    [self setupStickerServiceForSilentPublishWithPlayerFrame:playerFrame];
    AWERepoStickerModel *repoStickerModel = self.repository.repoSticker;
    // see annotation in code `[self.stickerService registStickerHandler:self.canvasStickerHandler];`
    [self.canvasStickerHandler setupCanvasSticker];

    if (repoStickerModel.stickerConfigAssembler != nil) {
        [self.stickerService expressStickersOnCompletion:^{
            if (completion) {
                completion(nil);
            }
        }];
      repoStickerModel.stickerConfigAssembler = nil;
    } else {
        if (completion) {
            completion(nil);
        }
    }
}

- (void)onPOIStickerApplySuccess
{
    if (self.repository.repoSticker.textImage) {
        self.repository.repoSticker.textImage = nil;
        NSString *stickerImagePath = [AWEDraftUtils generatePathFromTaskId:self.repository.repoDraft.taskID name:@"interactionSticker"];
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:stickerImagePath error:&error];
        if (error) {
            AWELogToolError(AWELogToolTagEdit, @"[onStickerApplySuccess] -- error:%@", error);
        }
    }
}

- (AWETextStickerStylePreferenceModel *)textStickerStylePreferenceWithRepository:(AWEVideoPublishViewModel *)repository
{
    AWETextStickerStylePreferenceModel *preferenceModel = [[AWETextStickerStylePreferenceModel alloc] init];
    preferenceModel.enableUsingUserPreference = YES;
    // 产品要求把文字tab的样式带进来
    if (repository.repoTextMode.isTextMode) {
        preferenceModel.preferenceTextFont = repository.repoTextMode.textModel.fontModel;
        preferenceModel.preferenceTextColor = repository.repoTextMode.textModel.fontColor;
    }
    return preferenceModel;
}

- (ACCStickerContainerView *)stickerContainerForSilentPublishWithPlayerFrame:(CGRect)playerFrame
{
    ACCVideoEditStickerContainerConfig *stickerContainerConfig = [self editorStickerConfig];
    return [self setupStickerContainerWithFrame:[UIScreen mainScreen].bounds playerFrame:playerFrame config:stickerContainerConfig];
}

- (ACCVideoEditStickerContainerConfig *)editorStickerConfig
{
    ACCVideoEditStickerContainerConfig *config = [[ACCVideoEditStickerContainerConfig alloc] init];
    config.stickerHierarchyComparator = ^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        if ([obj1 integerValue]< [obj2 integerValue]) {
            return NSOrderedAscending;
        } else if ([obj1 integerValue] > [obj2 integerValue]){
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    };
    config.ignoreMaskRadiusForXScreen = [AWEXScreenAdaptManager needAdaptScreen] && ACCViewFrameOptimizeContains(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize), ACCViewFrameOptimizeFullDisplay);
    return config;
}

- (ACCStickerContainerView *)setupStickerContainerWithFrame:(CGRect)containerFrame playerFrame:(CGRect)playerFrame config:(NSObject<ACCStickerContainerConfigProtocol> *)config
{
    ACCStickerContainerView *containerView = [[ACCStickerContainerView alloc] initWithFrame:containerFrame config:config];
    [containerView configWithPlayerFrame:playerFrame allowMask:NO];
    return containerView;
}

@end
