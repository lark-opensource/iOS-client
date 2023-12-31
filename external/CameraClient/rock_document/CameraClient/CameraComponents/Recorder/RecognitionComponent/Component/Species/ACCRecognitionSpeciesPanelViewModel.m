//
//  ACCRecognitionSpeciesPanelViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/20.
//

#import "ACCRecognitionSpeciesPanelViewModel.h"
#import <CreativeKit/ACCNetServiceProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCViewModel.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>
#import <CameraClient/ACCRecognitionTrackModel.h>
#import <CameraClient/AWERepoContextModel.h>
#import <SmartScan/SSRecommendResult.h>
#import <CreationKitArch/ACCRepoTrackModel.h>

#import "ACCSpeciesInfoCardsView.h"
#import "ACCRecognitionService.h"
#import "ACCFlowerService.h"
#import "ACCRecognitionGrootConfig.h"

@interface ACCRecognitionSpeciesPanelViewModel ()

@property (nonatomic, strong) SSImageTags *recognizeResultData;
@property (nonatomic, strong) RACSubject *closePanelSubject;
@property (nonatomic, strong) RACSubject *checkGrootSubject;
@property (nonatomic, strong) RACSubject *slideCardSubject;
@property (nonatomic, strong) RACSubject <RACThreeTuple<SSRecognizeResult *, NSNumber *, NSNumber *> *> *selectItemSubject;
@property (nonatomic, strong) RACSubject<RACTwoTuple<SSRecognizeResult *, NSNumber *> *> *stickerSelectItemSubject;

@property (nonatomic, strong) id<ACCRecognitionService> recognitionService;
@property (nonatomic, strong) id<ACCFlowerService> flowerService;

@property (nonatomic, assign) BOOL allowResearch;

@end

@implementation ACCRecognitionSpeciesPanelViewModel

IESAutoInject(self.serviceProvider, recognitionService, ACCRecognitionService)
IESAutoInject(self.serviceProvider, flowerService, ACCFlowerService)

- (instancetype)init
{
    if (self = [super init]) {
        _closePanelSubject = [RACSubject subject];
        _checkGrootSubject = [RACSubject subject];
        _selectItemSubject = [RACSubject subject];
        _slideCardSubject  = [RACSubject subject];
        _stickerSelectItemSubject  = [RACSubject subject];
    }
    return self;
}

#pragma mark - Public Methods
- (void)updateRecommendResult:(SSRecommendResult *)recommendResult
{
    if (recommendResult.data.imgTags.imageTags.count > 0) {
        self.recognizeResultData = recommendResult.data.imgTags;
        self.recognitionService.trackModel.speciesIndex = 0;
        [self sendSelectItemSignalWithIndex:0 isInitial:YES];
    }
}

- (BOOL)canShowSpeciesPanel
{
    return self.recognizeResultData.imageTags.count > 0;
}

- (RACSignal *)closePanelSignal
{
    return self.closePanelSubject;
}

- (RACSignal *)checkGrootSignal
{
    return self.checkGrootSubject;
}

- (RACSignal *)slideCardSignal
{
    return self.slideCardSubject;
}

- (RACSignal<RACThreeTuple<SSRecognizeResult *, NSNumber *, NSNumber *> *> *)selectItemSignal
{
    return self.selectItemSubject;
}

- (RACSignal<RACTwoTuple<SSRecognizeResult *,NSNumber *> *> *)stickerSelectItemSignal
{
    return self.stickerSelectItemSubject;
}

- (nullable SSRecognizeResult *)itemAtIndex:(NSUInteger)index
{
    if (index < self.recognizeResultData.imageTags.count) {
        return self.recognizeResultData.imageTags[index];
    }
    return nil;
}
    
#pragma mark - Private Methods
- (void)sendSelectItemSignalWithIndex:(NSUInteger)index isInitial:(BOOL)isInitial
{
    if (index < self.recognizeResultData.imageTags.count) {
        SSRecognizeResult *result = self.recognizeResultData.imageTags[index];
        [self.stickerSelectItemSubject sendNext:RACTuplePack(result, @(index))];
        [self.selectItemSubject sendNext:RACTuplePack(result, @(index), @(isInitial))];
        if (self.flowerService.inFlowerPropMode) {
            [self flowerTrackForConfirmSpeciesCard:index];
        } else {
            [self trackSelectedSpeciesAtIndex:index];
        }
    }
}

#pragma mark - ACCSpeciesInfoCardsViewDelegate
- (void)cardsView:(ACCSpeciesInfoCardsView *)cardsView didSelectItemAtIndex:(NSInteger)index withAllowResearch:(BOOL)allowResearch
{
    self.allowResearch = allowResearch;
    [self sendSelectItemSignalWithIndex:index isInitial:NO];
}

- (void)cardsView:(ACCSpeciesInfoCardsView *)cardsView didCheckAllowResearch:(BOOL)allowResearch
{
    self.allowResearch = allowResearch;
    [self.checkGrootSubject sendNext:@(allowResearch)];
}

- (void)cardsView:(ACCSpeciesInfoCardsView *)cardsView didSlideCardFrom:(NSInteger)from to:(NSInteger)to withAllowResearch:(BOOL)allowResearch
{
    if (self.recognitionService.trackModel.isClickByGroot) {
        [self trackSpeciesCardSlideTo:to isSticker:YES];
    } else {
        [self trackSpeciesCardSlideTo:to isSticker:NO];
    }
    [self.slideCardSubject sendNext:@(to)];
}

- (void)cardsView:(ACCSpeciesInfoCardsView *)cardsView didCloseAtIndex:(NSInteger)index withAllowResearch:(BOOL)allowResearch
{
    [self.closePanelSubject sendNext:nil];
}

#pragma mark - Track
- (void)trackClickChangeSpecies:(BOOL)isSticker
{
    AWEVideoPublishViewModel *publishModel = self.inputData.publishModel;
    NSMutableDictionary *referExtra = [NSMutableDictionary dictionary];
    referExtra[@"shoot_way"] = publishModel.repoTrack.referString ? : @"";
    referExtra[@"reality_id"] = self.recognitionService.trackModel.realityId ? : @"";
    referExtra[@"prop_id"] = isSticker?[ACCRecognitionGrootConfig grootStickerId]: self.recognizeResultData.stickerID ?:@"";
    referExtra[@"is_sticker"] = @(isSticker);
    referExtra[@"enter_from"] = @"video_shoot_page";
    referExtra[@"creation_id"] = publishModel.repoContext.createId ? : @"";
    referExtra[@"content_type"] = @"reality";
    [ACCTracker() trackEvent:@"click_change_species" params:referExtra];
}

- (void)flowerTrackForClickChangeSpecies
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"enter_from"] = @"video_shoot_page";
    params[@"content_type"] = @"reality";
    params[@"prop_id"] = self.recognizeResultData.stickerID ?: @"1165572";
    params[@"shoot_way"] = self.inputData.publishModel.repoTrack.referString ?: @"";
    params[@"creation_id"] = self.inputData.publishModel.repoContext.createId ? : @"";
    params[@"record_mode"] = @"sf_2022_activity_camera";
    params[@"reality_id"] = self.recognitionService.trackModel.realityId ? : @"";
    params[@"is_sticker"] = @0;
    // flower通用参数
    params[@"params_for_special"] = @"flower";
    [ACCTracker() trackEvent:@"click_change_species" params:params];
}

- (void)trackSpeciesCardSlideTo:(NSInteger)toIndex isSticker:(BOOL)isSticker
{
    AWEVideoPublishViewModel *publishModel = self.inputData.publishModel;
    NSMutableDictionary *referExtra = [NSMutableDictionary dictionary];
    referExtra[@"shoot_way"] = publishModel.repoTrack.referString ? : @"";
    referExtra[@"reality_id"] = self.recognitionService.trackModel.realityId ? : @"";
    referExtra[@"card_location"] = @(toIndex).stringValue;
    referExtra[@"creation_id"] = publishModel.repoContext.createId ? : @"";
    referExtra[@"content_type"] = @"reality";
    referExtra[@"enter_from"] = @"video_shoot_page";
    referExtra[@"prop_id"] = isSticker?[ACCRecognitionGrootConfig grootStickerId]: self.recognizeResultData.stickerID ?:@"";
    referExtra[@"is_sticker"] = @(isSticker);
    [ACCTracker() trackEvent:@"slide_species_card" params:referExtra];
}

- (void)trackSelectedSpeciesAtIndex:(NSInteger)index
{
    AWEVideoPublishViewModel *publishModel = self.inputData.publishModel;
    NSMutableDictionary *referExtra = [NSMutableDictionary dictionary];
    referExtra[@"shoot_way"] = publishModel.repoTrack.referString ? : @"";
    referExtra[@"reality_id"] = self.recognitionService.trackModel.realityId ? : @"";
    referExtra[@"card_location"] = @(index).stringValue;
    referExtra[@"creation_id"] = publishModel.repoContext.createId ? : @"";
    referExtra[@"content_type"] = @"reality";
    referExtra[@"is_sticker"] = @0;
    referExtra[@"is_authorized"] = @(self.allowResearch);
    if (self.recognitionService.trackModel.isClickByGroot) {
        // groot
        referExtra[@"is_sticker"] = @1;
        referExtra[@"enter_from"] = @"video_shoot_page";
        referExtra[@"prop_id"] = [ACCRecognitionGrootConfig grootStickerId];
    }
    [ACCTracker() trackEvent:@"confirm_species_card" params:referExtra];
}

- (void)flowerTrackForConfirmSpeciesCard:(NSInteger)index
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"enter_from"] = @"video_shoot_page";
    params[@"content_type"] = @"reality";
    params[@"shoot_way"] = self.inputData.publishModel.repoTrack.referString ?: @"";
    params[@"creation_id"] = self.inputData.publishModel.repoContext.createId ? : @"";
    params[@"record_mode"] = @"sf_2022_activity_camera";
    params[@"reality_id"] = self.recognitionService.trackModel.realityId ? : @"";
    params[@"card_location"] = @(index).stringValue;
    params[@"is_sticker"] = @0;
    params[@"is_authorized"] = @(self.allowResearch);
    // flower通用参数
    params[@"params_for_special"] = @"flower";
    [ACCTracker() trackEvent:@"confirm_species_card" params:params];
}

#pragma mark - ACCViewModel
- (void)dealloc
{
    [_selectItemSubject sendCompleted];
    [_closePanelSubject sendCompleted];
    [_checkGrootSubject sendCompleted];
    [_slideCardSubject sendCompleted];
    [_stickerSelectItemSubject sendCompleted];
}

@end
