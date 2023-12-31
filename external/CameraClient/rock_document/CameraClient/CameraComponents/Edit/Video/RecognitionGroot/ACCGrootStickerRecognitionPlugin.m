//
//  ACCGrootStickerRecognitionPlugin.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/8/23.
//

#import "ACCGrootStickerRecognitionPlugin.h"
#import <CameraClient/ACCGrootStickerComponent.h>
#import <CameraClient/ACCRecognitionGrootConfig.h>
#import <CameraClient/ACCGrootStickerView.h>
#import <CreationKitArch/AWEInteractionStickerModel.h>
#import <CreationKitArch/ACCRecorderViewModel.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CameraClient/ACCRecognitionTrackModel.h>
#import <CreationKitArch/AWEInteractionStickerModel.h>
#import <CameraClient/ACCGrootStickerHandler.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <CameraClient/ACCRecognitionGrootStickerViewFactory.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CameraClient/AWERepoStickerModel.h>
#import <CameraClient/ACCStickerPlayerApplying.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <SmartScan/SSRecommendResult.h>

@interface ACCGrootStickerRecognitionPlugin ()<ACCGrootStickerInputDelegate>

@property (nonatomic, strong, readonly) ACCGrootStickerComponent *hostComponent;
@property (nonatomic, strong) ACCRecognitionGrootStickerView *stickerContentView;
@property (nonatomic, strong) ACCGrootStickerView *stickerView;
@property (nonatomic, strong) ACCGrootStickerView *originStickerView; // for recover

@end

@implementation ACCGrootStickerRecognitionPlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCGrootStickerComponent class];
}

#pragma mark - Properties

- (ACCGrootStickerComponent *)hostComponent
{
    return self.component;
}

- (AWEVideoPublishViewModel *)publishModel
{
    return [[[self.component getViewModel:ACCRecorderViewModel.class] inputData] publishModel];
}

- (void)bindServices:(nonnull id<IESServiceProvider>)serviceProvider {
    self.hostComponent.inputDelegate = self;
}

#pragma mark - ACCGrootStickerInputDelegate

- (void)didMountGrootComponent:(ACCGrootStickerHandler *)stickerHandler viewModel:(nonnull ACCGrootStickerViewModel *)viewModel
{
    [self.hostComponent.repository.repoSticker.recorderInteractionStickers enumerateObjectsUsingBlock:^(AWEInteractionStickerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.type == AWEInteractionStickerTypeGroot){
            [self addGrootStickerWithHandler:stickerHandler stickerModel:obj viewModel:viewModel];
        }
    }];
}

- (void)didUpdateStickerView:(ACCGrootDetailsStickerModel *)stickerModel
{
    if (!stickerModel || stickerModel.isDummy) {
        [self showStickerContentView:NO];
    } else {
        [self.stickerContentView configWithModel:stickerModel];
        [self showStickerContentView:YES];
        self.stickerView.bounds = CGRectMake(0, 0, self.stickerContentView.acc_width, self.stickerContentView.acc_height);
    }
}

- (void)restoreStickerViewIfNeed:(ACCGrootStickerHandler *)stickerHandler stickerModel:(ACCGrootStickerModel *)stickerModel
{
    if (!self.originStickerView) {
        return ;
    }
    [stickerHandler.stickerContainerView removeStickerView:self.stickerView];
    self.stickerView = self.originStickerView;
    self.originStickerView = nil;
    self.stickerContentView = [self.stickerView.subviews btd_filter:^BOOL(__kindof UIView * _Nonnull obj) {
        return [obj isKindOfClass:ACCRecognitionGrootStickerView.class];
    }].firstObject;
    [self.stickerContentView configWithModel:self.stickerView.stickerModel.selectedGrootStickerModel];
    [self showStickerContentView:YES];
}

- (ACCGrootStickerView *)createRecognitionGrootStickerView:(ACCGrootStickerModel *)model
                                                   handler:(nullable ACCGrootStickerHandler *)handler
{
    self.originStickerView = self.stickerView;
    self.stickerView = [[ACCGrootStickerView alloc] initWithStickerModel:model grootStickerUniqueId:nil];
    [self addContentViewToStickerView:model.selectedGrootStickerModel ?: model.grootDetailStickerModels.firstObject];

    return self.stickerView;
}

- (void)confirm:(ACCGrootStickerHandler *)handler
{
    if (!self.originStickerView) {
        return ;
    }
    [handler.stickerContainerView removeStickerView:self.originStickerView];
    self.originStickerView = nil;
}

# pragma mark - private
- (void)addGrootStickerWithHandler:(ACCGrootStickerHandler *)stickerHandler stickerModel:(AWEInteractionStickerModel *)interactionStickerModel viewModel:(nonnull ACCGrootStickerViewModel *)viewModel{

    AWEVideoPublishViewModel *model = self.publishModel;
    ACCRecognitionTrackModel *recognitionModel = [model extensionModelOfClass:ACCRecognitionTrackModel.class];
    recognitionModel.grootModel.didRecover = NO;

    AWEInteractionStickerLocationModel *location = [interactionStickerModel fetchLocationModelFromTrackInfo];

    let grootModel = recognitionModel.grootModel;
    if (!grootModel) {
        return;
    }
    let sticker = grootModel.stickerModel;

    [self setGrootTrackInfo:grootModel];

    [self.hostComponent addGrootStickerWithStickerID:[ACCRecognitionGrootConfig grootStickerId] location:location stickerModel:sticker autoEdit:NO];

    [self.stickerContentView contentDidUpdateToScale:recognitionModel.grootModel.scale];

    [viewModel saveGrooSelectedResult:sticker];
}

- (void)addContentViewToStickerView:(ACCGrootDetailsStickerModel *)detailStickerModel
{
    ACCRecognitionStickerViewType type = (ACCRecognitionStickerViewType)([ACCRecognitionGrootConfig stickerStyle]);

    self.stickerContentView = [ACCRecognitionGrootStickerViewFactory viewWithType:type];

    self.stickerContentView.tag = RECOGNITION_GROOT_TAG;
    self.stickerContentView.alpha = 1;
    [self.stickerContentView configWithModel:detailStickerModel];

    @weakify(self)
    [[[RACObserve(self.stickerView, currentScale).deliverOnMainThread takeUntil:self.rac_willDeallocSignal] skip:1] subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self)
        [self.stickerContentView contentDidUpdateToScale:x.floatValue];
    }];

    self.stickerContentView.userInteractionEnabled = NO;

    [self showStickerContentView:YES];
    [self layoutStickerView:self.stickerView];
    [self.stickerView addSubview:self.stickerContentView];
}

- (void)setGrootTrackInfo:(ACCRecognitionGrootModel *)grootModel
{
    self.hostComponent.repository.repoUploadInfo.extraDict[@"is_authorized"] = @(grootModel.stickerModel.allowGrootResearch);
    self.hostComponent.repository.repoUploadInfo.extraDict[@"baike_id"] = grootModel.stickerModel.selectedGrootStickerModel.baikeId;
    self.hostComponent.repository.repoUploadInfo.extraDict[@"species_name"] = grootModel.stickerModel.selectedGrootStickerModel.speciesName;
}

- (void)showStickerContentView:(BOOL)show
{
    [[self.stickerView subviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.hidden = show;
    }];
    self.stickerContentView.hidden = !show;
}

- (void)layoutStickerView:(ACCGrootStickerView *)stickerView
{
    stickerView.frame = self.stickerContentView.frame;
    self.stickerContentView.frame = stickerView.bounds;
    CGRect f = stickerView.superview.frame;
    f.size = stickerView.frame.size;
    stickerView.superview.frame = f;
}

+ (BOOL)serviceEnabled
{
    return [ACCRecognitionGrootConfig enabled];
}

@end
