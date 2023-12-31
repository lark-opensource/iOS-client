//
//  ACCGrootStickerViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/5/18.
//

#import "ACCGrootStickerViewModel.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <IESInject/IESInject.h>
#import <CameraClient/ACCEditMusicServiceProtocol.h>
#import <CameraClient/ACCGrootStickerNetServiceProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/ACCRepoStickerModel.h>
#import <CreationKitArch/ACCRepoVideoInfoModel.h>
#import <CameraClient/ACCTrackerUtility.h>
#import <CreativeKit/ACCMacros.h>
#import "AWERepoStickerModel.h"
#import "ACCEditVideoFilterService.h"
#import "ACCStickerServiceProtocol.h"
#import "ACCConfigKeyDefines.h"
#import "AWERepoUploadInfomationModel.h"
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import "AWERepoContextModel.h"
#import "ACCRepoTextModeModel.h"
#import "AWERepoVideoInfoModel.h"
#import <CreationKitArch/ACCRepoGameModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import "AWEVideoFragmentInfo.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "ACCRecognitionTrackModel.h"
#import <CameraClientModel/ACCVideoCanvasType.h>

typedef NS_ENUM(NSUInteger, ACCGrootStickerRecognitionStatus) {
    ACCGrootStickerRecognitionNone,
    ACCGrootStickerRecognitionAuto,
    ACCGrootStickerRecognitionManual
};

@interface ACCGrootStickerViewModel ()

@property (nonatomic, strong) RACSubject *showGrootStickerTipsSubject;
@property (nonatomic, strong) RACSubject<NSString *> *sendAutoAddGrootHashtagSubject;

@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCEditMusicServiceProtocol> musicService;
@property (nonatomic, weak) id<ACCStickerServiceProtocol> stickerService;
@property (nonatomic, weak) id<ACCEditVideoFilterService> filterService;

@property (nonatomic, assign) ACCGrootStickerRecognitionStatus handleStatus;
@property (nonatomic, strong) NSString *cameraDirectionString;

@property (nonatomic, copy) void (^checkFinishedBlock)(ACCGrootCheckModel * _Nullable, NSError * _Nullable error);
@property (nonatomic, copy) void (^onFetchFinishedBlock)(ACCGrootListModel * _Nullable, NSError * _Nullable error);

@property (nonatomic, copy) ACCGrootStickerModel *grootModel;
@property (nonatomic, assign) BOOL isAutoRecognition;

@end

@implementation ACCGrootStickerViewModel

IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, musicService, ACCEditMusicServiceProtocol)
IESAutoInject(self.serviceProvider, stickerService, ACCStickerServiceProtocol)
IESAutoInject(self.serviceProvider, filterService, ACCEditVideoFilterService)

#pragma mark - life cycle

- (instancetype)init {
    if (self = [super init]) {
        self.handleStatus = ACCGrootStickerRecognitionNone;
        self.isAutoRecognition = YES;
    }
    return self;
}

- (void)dealloc {
    [_showGrootStickerTipsSubject sendCompleted];
    [_sendAutoAddGrootHashtagSubject sendCompleted];
}

#pragma makr- private

- (RACSignal *)showGrootStickerTipsSignal {
    return self.showGrootStickerTipsSubject;
}

- (RACSubject *)showGrootStickerTipsSubject {
    if (!_showGrootStickerTipsSubject) {
        _showGrootStickerTipsSubject = [RACSubject subject];
    }
    return _showGrootStickerTipsSubject;
}

- (RACSignal<NSString *> *)sendAutoAddGrootHashtagSignal
{
    return self.sendAutoAddGrootHashtagSubject;
}

- (RACSubject<NSString *> *)sendAutoAddGrootHashtagSubject {
    if (!_sendAutoAddGrootHashtagSubject) {
        _sendAutoAddGrootHashtagSubject = [RACSubject subject];
    }
    return _sendAutoAddGrootHashtagSubject;
}

- (void)startCheckCousoryRecognitionWithFrameZip:(NSString *)zipTos creationId:(NSString *_Nonnull)creationId {
    @weakify(self);
    [IESAutoInline(ACCBaseServiceProvider(), ACCGrootStickerNetServiceProtocol) requestCheckGrootRecognitionWith:zipTos creationId:creationId cameraDirection:self.cameraDirectionString completion:^(ACCGrootCheckModel * _Nullable model, NSError * _Nullable error) {
        @strongify(self);
        ACCBLOCK_INVOKE(self.checkFinishedBlock, model, error);
    }];
}

- (void)startFetchReconitionGrootModelsWithZip:(NSString *)zipTos creationId:(NSString *_Nonnull)creationId {
    @weakify(self);
    [IESAutoInline(ACCBaseServiceProvider(), ACCGrootStickerNetServiceProtocol) requestFetchGrootRecognitionListWith:zipTos creationId:creationId cameraDirection:self.cameraDirectionString completion:^(ACCGrootListModel * _Nullable model, NSError * _Nullable error) {
        @strongify(self);
        ACCBLOCK_INVOKE(self.onFetchFinishedBlock, model, error);
    }];
}

#pragma mark - public

- (void)sendShowGrootStickerTips {
    if ([self shouldUploadFramesForRecommendation]) {
        [self.showGrootStickerTipsSubject sendNext:nil];
    }
}

- (void)sendAutoAddHashtagWith:(NSString * _Nonnull)hashtagName {
    if (!ACC_isEmptyString(hashtagName)) {
        [self.sendAutoAddGrootHashtagSubject sendNext:hashtagName];
    }
}

- (void)bindViewModel {
    @weakify(self);
    [[[self musicService].featchFramesUploadStatusSignal deliverOnMainThread] subscribeNext:^(RACTwoTuple<NSString *,NSError *> * _Nullable x) {
        @strongify(self);
        NSString *zipTosString = x.first;
        NSError *error = x.second;
        if (!zipTosString || error) {
            AWELogToolError2(@"Groot", AWELogToolTagEdit, @"featch frames and upload failed, error:%@", error);
            switch (self.handleStatus) {
                case ACCGrootStickerRecognitionAuto:
                    ACCBLOCK_INVOKE(self.checkFinishedBlock, nil, error);
                    break;
                case ACCGrootStickerRecognitionManual:
                    // 需要加抽帧重试，视频裁减后支持重新识别
                    ACCBLOCK_INVOKE(self.onFetchFinishedBlock, nil, error);
                case ACCGrootStickerRecognitionNone:
                default:
                    break;
            }
            return;
        }
        NSString *creationId = self.repository.repoContext.createId;
        switch (self.handleStatus) {
            case ACCGrootStickerRecognitionAuto:
                [self startCheckCousoryRecognitionWithFrameZip:zipTosString creationId:creationId];
                break;
            case ACCGrootStickerRecognitionManual:
                [self startFetchReconitionGrootModelsWithZip:zipTosString creationId:creationId];
                break;
            case ACCGrootStickerRecognitionNone:
            default:
                // do nothing
                break;
        }
        self.handleStatus = ACCGrootStickerRecognitionNone;
    } ];
    
    [[[self stickerService].stickerDeselectedSignal deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        self.isAutoRecognition = NO;
    }];
    
    [[[self filterService].applyFilterSignal deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        self.isAutoRecognition = NO;
    }];
    
    [[[[self stickerService] willStartEditingStickerSignal] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        self.isAutoRecognition = NO;
    }];
}

-  (void)startCheckGrootRecognitionResult:(void (^)(ACCGrootCheckModel * _Nullable, NSError * _Nullable))checkFinishedBlock {
    if (!self.shouldUploadFramesForRecommendation) {
        AWELogToolError2(@"groot", AWELogToolTagEdit, @"silent check groot recognition not allowed.");
        ACCBLOCK_INVOKE(checkFinishedBlock, nil, nil);
        return;
    }
    
    __block NSMutableArray *cameraDirection = nil;
    __block BOOL rearCaptue = NO;
    if (self.repository.repoVideoInfo.fragmentInfo.count > 0) {
        cameraDirection = [[NSMutableArray alloc] init];
        [self.repository.repoVideoInfo.fragmentInfo enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *position = ACCDevicePositionStringify(obj.cameraPosition);
            if (!ACC_isEmptyString(position)) {
                [cameraDirection acc_addObject:position];
            }
            if ([position isEqualToString:@"back"]) {
                rearCaptue = YES;
            }
        }];
    } else {
        rearCaptue = YES;
    }
    self.cameraDirectionString = [cameraDirection componentsJoinedByString:@","] ?: @"";
    if (rearCaptue) {
        self.handleStatus = ACCGrootStickerRecognitionAuto;
        self.checkFinishedBlock = checkFinishedBlock;
        [self.musicService generalFetchFramesAndUpload];
    }
}

-  (void)startFetchGrootRecognitionResult:(void (^)(ACCGrootListModel * _Nullable, NSError * _Nullable))finishedBlock {
    if (!self.shouldUploadFramesForRecommendation) {
        AWELogToolError2(@"groot", AWELogToolTagEdit, @"fetch groot recognition list not allowed.");
        ACCBLOCK_INVOKE(finishedBlock, nil, nil);
        return;
    }
    self.handleStatus = ACCGrootStickerRecognitionManual;
    self.onFetchFinishedBlock = finishedBlock;
    [self.musicService generalFetchFramesAndUpload];
}

- (BOOL)shouldUploadFramesForRecommendation {
    return [self.musicService shouldUploadFramesForRecommendation];
}

- (BOOL)canUseGrootSticker {
    if (!ACCConfigBool(kConfigBool_sticker_support_groot) ||
        self.repository.repoContext.isIMRecord ||
        self.repository.repoContext.videoType == AWEVideoTypeKaraoke ||
        self.repository.repoTextMode.isTextMode ||
        self.repository.repoGame.gameType != ACCGameTypeNone ||
        self.repository.repoDuet.isDuet ||
        self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeMusicStory) {
        AWELogToolInfo2(@"groot", AWELogToolTagEdit, @"groot sticker not supported.");
        return NO;
    }
    return YES;
}

-  (BOOL)isAutoRecognition {
    if (![self canUseGrootSticker]) {
        return NO;
    }
    // 来自groot主页则自动进行二级模型识别和展示 shoot_enter_From = groot_page
    if ([self.repository.repoUploadInfo isShootEnterFromGroot]) {
        if (self.repository.repoDraft.isDraft || self.repository.repoDraft.isBackUp || [self hasStickerFromRecord]) {
            return NO;
        }
        return _isAutoRecognition;
    }
    return NO;
}

#pragma mark - draft

// 根据一级模型的信息更新
- (void)saveCheckGrootRecognitionResult:(BOOL)hasGroot extra:(NSDictionary *)extra
{
    self.grootModel.hasGroot = @(hasGroot);
    self.grootModel.extra = [extra copy];
    [self saveGrootStickerModel:self.grootModel];
}

// 根据二级模型的信息更新
- (void)saveGrooSelectedResult:(ACCGrootStickerModel *)grootStickerModel
{
    self.grootModel.allowGrootResearch = grootStickerModel.allowGrootResearch;
    self.grootModel.selectedGrootStickerModel = grootStickerModel.selectedGrootStickerModel;
    self.grootModel.grootDetailStickerModels = grootStickerModel.grootDetailStickerModels;
    if (!ACC_isEmptyDictionary(grootStickerModel.extra)) {
        self.grootModel.extra = grootStickerModel.extra;
    }
    self.grootModel.userGrootInfo = grootStickerModel.userGrootInfo;
    self.grootModel.fromRecord = grootStickerModel.fromRecord;
    [self saveGrootStickerModel:self.grootModel];
}

- (void)removeSelectedGrootResult {
    self.grootModel.selectedGrootStickerModel = nil;
    [self saveGrootStickerModel:self.grootModel];
}

- (void)saveGrootStickerModel:(ACCGrootStickerModel *)grootStickerModel {
    self.grootModel = grootStickerModel;
    NSString *dataString = [grootStickerModel draftDataJsonString];

    /// use recorderGrootResult if grootSticker choose
    if (self.repository.repoSticker.recorderGrootModelResult.length > 0 &&
        grootStickerModel.selectedGrootStickerModel == nil) {
        self.repository.repoSticker.grootModelResult = self.repository.repoSticker.recorderGrootModelResult;
    } else {
        self.repository.repoSticker.grootModelResult = dataString;
    }
}

- (ACCGrootStickerModel *)recoverGrootStickerModel {
    NSString *grootModelString = self.repository.repoSticker.grootModelResult;
    ACCGrootStickerModel *model = [[ACCGrootStickerModel alloc] initWithEffectIdentifier:@"1148586"];
    [model recoverDataFromDraftJsonString:grootModelString];
    return model;
}

- (ACCGrootStickerModel *)grootModel {
    if (!_grootModel) {
        _grootModel = [self recoverGrootStickerModel];
    }
    return _grootModel;
}

- (BOOL)hasStickerFromRecord
{
    ACCRecognitionTrackModel *trackModel = [self.repository extensionModelOfClass:ACCRecognitionTrackModel.class];
    if (trackModel && trackModel.grootModel && trackModel.grootModel.stickerModel) {
        return YES;
    }
    return NO;
}

@end
