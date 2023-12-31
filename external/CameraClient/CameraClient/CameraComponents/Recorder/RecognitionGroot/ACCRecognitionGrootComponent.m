//
//  ACCRecognitionGrootComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/8/23.
//

#import "ACCRecognitionGrootComponent.h"
#import <SmartScan/SSRecommendResult.h>
#import "ACCRecognitionService.h"
#import "ACCRecognitionTrackModel.h"
#import <CreationKitInfra/ACCRACWrapper.h>
#import <IESInject/IESInjectDefines.h>
#import <CameraClient/ACCRecorderStickerServiceProtocol.h>
#import <CameraClient/ACCRecognitionGrootStickerHandler.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CameraClient/ACCRecognitionTrackModel.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <CreationKitInfra/ACCRACWrapper.h>
#import <CreationKitArch/ACCRecorderViewModel.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import "ACCRecognitionSpeciesPanelViewModel.h"
#import <CameraClient/ACCRecognitionConfig.h>
#import "ACCRecognitionGrootStickerViewModel.h"
#import "ACCRecognitionGrootStickerViewFactory.h"
#import <CreationKitRTProtocol/ACCCameraService.h>
#import "ACCRecognitionGrootConfig.h"
#import "ACCFlowerService.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import "ACCRecognitionPropPanelViewModel.h"

@interface ACCRecognitionGrootComponent()<ACCRecordSwitchModeServiceSubscriber>

@property (nonatomic, weak  ) id<ACCRecognitionService> recognitionService;
@property (nonatomic, weak  ) id<ACCRecorderStickerServiceProtocol> stickerService;
@property (nonatomic, weak  ) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, weak) id<ACCFlowerService> flowerService;

@property (nonatomic, strong) ACCRecognitionGrootStickerHandler *stickerHandler;
@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) ACCRecognitionSpeciesPanelViewModel *speciesViewModel;
@property (nonatomic, strong) ACCRecognitionGrootStickerViewModel *grootStickerViewModel;
@property (nonatomic, strong) ACCGrootDetailsStickerModel *originDetailStickerModel;

@property (nonatomic, strong) ACCRecognitionGrootModel *stashedGrootModel;

@end

@implementation ACCRecognitionGrootComponent

IESAutoInject(self.serviceProvider, recognitionService, ACCRecognitionService)
IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, stickerService, ACCRecorderStickerServiceProtocol)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, flowerService, ACCFlowerService)

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self initGrootStickerHandler];
    [self.stickerService registerStickerHandler:self.stickerHandler];
    [self.switchModeService addSubscriber:self];
}

- (void)componentDidMount
{
    @weakify(self)
    [[self.recognitionService.recognitionResultSignal.deliverOnMainThread takeUntil:[self rac_willDeallocSignal]] subscribeNext:^(RACTwoTuple<SSRecommendResult *,NSString *> * _Nullable x) {
        @strongify(self)
        if (self.recognitionService.detectResult != ACCRecognitionDetectResultSmartScan) {
            return;
        }
        ACCGrootStickerModel *stickerModel = [self transformData:x.first selectedIndex:0];
        [self.stickerHandler removeGrootSticker];
        if (!stickerModel) {
            self.recognitionService.trackModel.grootModel = nil;
            self.propPanelViewModel.homeItem = nil;
            return ;
        }
        self.propPanelViewModel.homeItem = [[ACCPropPickerItem alloc] initWithType:ACCPropPickerItemTypeHome];
        self.recognitionService.trackModel.grootModel = [ACCRecognitionGrootModel new];
        self.recognitionService.trackModel.grootModel.stickerModel = stickerModel;
        [self.stickerHandler addGrootStickerWithModel:stickerModel];
        self.stashedGrootModel = self.recognitionService.trackModel.grootModel;
    }];
    [self bindViewModel];
}

- (void)componentDidUnmount
{
    [self.grootStickerViewModel onCleared];
}

- (void)bindViewModel
{
    @weakify(self);
    [[[self.grootStickerViewModel.clickViewSignal takeUntil:[self rac_willDeallocSignal]] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self.stickerHandler editStickerView];
        if (self.flowerService.inFlowerPropMode) {
            [self.speciesViewModel flowerTrackForClickChangeSpecies];
        } else {
            [self.grootStickerViewModel trackGrootStickerClickChangeSpecies:@"video_shoot_page"];
        }
        self.recognitionService.trackModel.isClickByGroot = YES;
    }];

    [[[[RACObserve(self.recognitionService, recognitionState) skip:1] takeUntil:[self rac_willDeallocSignal]] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        if ([x integerValue] == ACCRecognitionStateNormal){
            [self.stickerHandler removeGrootSticker];
            self.recognitionService.trackModel.grootModel = nil;
            self.stashedGrootModel = nil;
            [self.recognitionService updateTrackModel];
        }
    }];

    [[[self.speciesViewModel.closePanelSignal takeUntil:[self rac_willDeallocSignal]] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self.stickerHandler stopEditStickerView];
        [self restoreOriginStatus];
    }];

    [[[self.speciesViewModel.checkGrootSignal takeUntil:[self rac_willDeallocSignal]] deliverOnMainThread] subscribeNext:^(NSNumber *  _Nullable x) {
        @strongify(self);
        self.recognitionService.trackModel.grootModel.stickerModel.allowGrootResearch = [x boolValue];
    }];

    [[[self.speciesViewModel.stickerSelectItemSignal takeUntil:[self rac_willDeallocSignal]] deliverOnMainThread] subscribeNext:^(RACTwoTuple<SSRecognizeResult *,NSNumber *> * _Nullable x) {
        @strongify(self)
        self.originDetailStickerModel = nil;
        // update groot data
        ACCGrootDetailsStickerModel *detailModel = [self tranfromResultToDetailModel:x.first];
        self.recognitionService.trackModel.grootModel.index = [x.second integerValue];
        self.recognitionService.trackModel.grootModel.stickerModel.selectedGrootStickerModel = [self tranfromResultToDetailModel:x.first];
        [self.recognitionService updateTrackModel];

        [self.stickerHandler updateStickerViewByDetailStickerModel:detailModel];
        [self.stickerHandler stopEditStickerView];

    }];

    [[self.speciesViewModel.slideCardSignal takeUntil:[self rac_willDeallocSignal]] subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self)
        ACCGrootDetailsStickerModel *detailModel = self.recognitionService.trackModel.grootModel.stickerModel.grootDetailStickerModels[x.integerValue];
        [self.stickerHandler updateStickerViewByDetailStickerModel:detailModel];
        [self sendSelectSpeciesMessage:[self tranfromDetailModelToResult:detailModel]];
    }];

    [[[RACObserve(self.speciesViewModel, isShowingPanel) takeUntil:[self rac_willDeallocSignal]] deliverOnMainThread] subscribeNext:^(NSNumber*  _Nullable x) {
        @strongify(self);
        if (!x.boolValue) {
            [self restoreOriginStatus];
        } else {
            // 保存原贴纸
            self.originDetailStickerModel = self.recognitionService.trackModel.grootModel.stickerModel.selectedGrootStickerModel;
        }
    }];

}

#pragma mark - public
- (void)updateCheckGrootResearch:(BOOL)allowResearch
{
    
}

- (void)updateStickerState:(BOOL)show
{
    
}

- (void)saveRecoverSticker
{

}

# pragma mark - private
- (void)initGrootStickerHandler
{
    ACCRecognitionStickerViewType type = (ACCRecognitionStickerViewType)([ACCRecognitionGrootConfig stickerStyle]);
    self.stickerHandler = [[ACCRecognitionGrootStickerHandler alloc]
                               initWithGrootStickerViewModel:self.grootStickerViewModel
                               viewWithType:type];
    self.stickerHandler.recognitionService = self.recognitionService;
}

- (void)restoreOriginStatus
{
    if (!self.originDetailStickerModel ||
        [self.originDetailStickerModel.speciesName isEqual:self.stickerHandler.stickerView.stickerModel.speciesName]) {
        return;
    }
    // 恢复贴纸
    [self.stickerHandler updateStickerViewByDetailStickerModel:self.originDetailStickerModel];
    // 恢复道具
    [self sendSelectSpeciesMessage:[self tranfromDetailModelToResult:self.originDetailStickerModel]];
}

- (ACCGrootStickerModel *)transformData:(SSRecommendResult *)recognitionResult selectedIndex:(NSInteger)index
{
    NSArray<SSRecognizeResult *> *imageTags = recognitionResult.data.imgTags.imageTags;
    if (imageTags.count == 0) {
        return nil;
    }
    ACCGrootStickerModel *model = [[ACCGrootStickerModel alloc] initWithEffectIdentifier:[ACCRecognitionGrootConfig grootStickerId]];
    model.allowGrootResearch = YES;
    model.hasGroot = @(YES);
    model.fromRecord = YES;
    model.grootDetailStickerModels = [imageTags btd_map:^id _Nullable(SSRecognizeResult * _Nonnull obj) {
        return [self tranfromResultToDetailModel:obj];
    }];
    model.selectedGrootStickerModel = model.grootDetailStickerModels[index];

    return model;
}

- (ACCGrootDetailsStickerModel *)tranfromResultToDetailModel:(SSRecognizeResult *)result
{
    ACCGrootDetailsStickerModel *model = [ACCGrootDetailsStickerModel new];
    model.baikeId = @(result.wikiID.integerValue);
    model.baikeHeadImage = result.imageLinks.firstObject;
    model.speciesName = result.chnName;
    model.baikeIcon = result.icon ?: @"";
    model.commonName = result.aliasName;
    model.categoryName = result.clsSys;
    model.prob = @(result.score);
    model.engName = result.engName;
    return model;
}

- (SSRecognizeResult *)tranfromDetailModelToResult:(ACCGrootDetailsStickerModel *)model
{
    SSRecognizeResult *result = [SSRecognizeResult new];
    result.clsSys = model.categoryName;
    result.chnName = model.speciesName;
    result.aliasName = model.commonName;
    return result;
}

- (void)sendSelectSpeciesMessage:(SSRecognizeResult *)species
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:species.clsSys ? : @"" forKey:@"des1"];
    [dict setValue:species.chnName ? : @"" forKey:@"name"];
    [dict setValue:species.aliasName ? : @"" forKey:@"des2"];

    IESMMEffectMsg msg = (IESMMEffectMsg)(ACCRecognitionMsgRecognizedSpecies);
    IESMMEffectMessage *message = [IESMMEffectMessage messageWithType:msg];
    message.arg1 = ACCRecognitionMsgTypeSendPropInformation;
    message.arg3 = [dict acc_dictionaryToJson];

    [self.cameraService.message sendMessageToEffect:message];
}


#pragma mark - Getter & Setter
- (ACCRecognitionSpeciesPanelViewModel *)speciesViewModel
{
    if (!_speciesViewModel) {
        _speciesViewModel = [self getViewModel:[ACCRecognitionSpeciesPanelViewModel class]];
    }
    return _speciesViewModel;
}

- (ACCRecognitionGrootStickerViewModel *)grootStickerViewModel
{
    if (!_grootStickerViewModel) {
        _grootStickerViewModel = [self getViewModel:[ACCRecognitionGrootStickerViewModel class]];
    }
    return _grootStickerViewModel;
}

- (ACCRecognitionPropPanelViewModel *)propPanelViewModel
{
    return [self getViewModel:ACCRecognitionPropPanelViewModel.class];
}

- (AWEVideoPublishViewModel *)publishModel
{
    return [[[self getViewModel:ACCRecorderViewModel.class] inputData] publishModel];
}

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    if ([self supportGrootStcker:mode]){
        self.recognitionService.trackModel.grootModel = self.stashedGrootModel;
    }else{
        self.recognitionService.trackModel.grootModel = nil;
    }
}

- (BOOL)supportGrootStcker:(ACCRecordMode *)mode
{
    return
    mode.serverMode == ACCServerRecordModeQuick ||
    mode.serverMode == ACCServerRecordModePhoto ||
    mode.serverMode == ACCServerRecordModeCombine ||
    mode.serverMode == ACCServerRecordModeCombine60 ||
    mode.serverMode == ACCServerRecordModeCombine15 ||
    mode.serverMode == ACCServerRecordModeCombine180;

}

@end
