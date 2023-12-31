//
//  ACCRecognitionGrootStickerViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/8/27.
//

#import "ACCRecognitionGrootStickerViewModel.h"
#import <CreativeKit/ACCTrackProtocol.h>
#import "ACCRecognitionService.h"
#import <CameraClient/ACCRecognitionTrackModel.h>
#import "ACCRecognitionGrootConfig.h"

@interface ACCRecognitionGrootStickerViewModel()

@property (nonatomic, strong) RACSubject *clickViewSubject;
@property (nonatomic, strong) id<ACCRecognitionService> recognitionService;

@end

@implementation ACCRecognitionGrootStickerViewModel

IESAutoInject(self.serviceProvider, recognitionService, ACCRecognitionService)

- (instancetype)init
{
    self = [super init];
    if (self) {
        _clickViewSubject = [RACSubject subject];
    }
    return self;
}

#pragma mark - getter & setter
- (RACSignal *)clickViewSignal
{
    return self.clickViewSubject;
}

#pragma mark - ACCRecognitionGrootStickerViewDelegate
- (void)hitView:(ACCRecognitionGrootStickerView *)grootStickerView
{
    [self.clickViewSubject sendNext:grootStickerView];
}

#pragma mark - tarck
/**
 prop_show
 */
- (void)trackGrootStickerPropShow:(NSString *)enterFrom
{
    ACCGrootDetailsStickerModel *detailModel = self.recognitionService.trackModel.grootModel.stickerModel.selectedGrootStickerModel;
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"enter_from"] = enterFrom ?: @"";
    params[@"prop_id"] = [ACCRecognitionGrootConfig grootStickerId];
    params[@"is_sticker"] = @1;
    params[@"baike_id"] = detailModel.baikeId ?: @"";
    params[@"species_name"] = detailModel.speciesName ?: @"";
    [ACCTracker() trackEvent:@"prop_show" params:params needStagingFlag:NO];
}

/**
 prop_delete
 */
- (void)trackGrootStickerPropDelete:(NSString *)enterFrom
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"enter_from"] = enterFrom ?: @"";
    params[@"prop_id"] = [ACCRecognitionGrootConfig grootStickerId];
    params[@"is_sticker"] = @1;
    params[@"prop_selected_from"] = self.recognitionService.trackModel.realityType ?: @"";
    params[@"reality_id"] = self.recognitionService.trackModel.realityId ?: @"";
    [ACCTracker() trackEvent:@"prop_delete" params:params needStagingFlag:NO];
}

/**
 click_change_species
 */
- (void)trackGrootStickerClickChangeSpecies:(NSString *)enterFrom
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"enter_from"] = enterFrom ?: @"";
    params[@"prop_id"] = [ACCRecognitionGrootConfig grootStickerId];
    params[@"is_sticker"] = @1;
    [ACCTracker() trackEvent:@"click_change_species" params:params needStagingFlag:NO];
}

/**
 slide_species_card
 */
- (void)trackGrootStickerSlideSpeciesCard:(NSString *)enterFrom
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"enter_from"] = enterFrom ?: @"";
    params[@"prop_id"] = [ACCRecognitionGrootConfig grootStickerId];
    params[@"is_sticker"] = @1;
    [ACCTracker() trackEvent:@"slide_species_card" params:params needStagingFlag:NO];
}

/**
confirm_species_card
 */
- (void)trackGrootStickerConfirmSpeciesCard:(NSString *)enterFrom
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"prop_id"] = [ACCRecognitionGrootConfig grootStickerId];
    params[@"enter_from"] = enterFrom ?: @"";
    params[@"is_sticker"] = @1;
    params[@"is_authorized"] = @(@(self.recognitionService.trackModel.grootModel.stickerModel.allowGrootResearch).integerValue);
    [ACCTracker() trackEvent:@"confirm_species_card" params:params needStagingFlag:NO];
}

#pragma mark - ACCViewModel
- (void)onCleared
{
    [_clickViewSubject sendCompleted];
}

@end
