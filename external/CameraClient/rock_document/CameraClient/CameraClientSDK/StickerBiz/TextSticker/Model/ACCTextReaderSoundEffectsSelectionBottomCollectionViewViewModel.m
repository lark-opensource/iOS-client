//
//  ACCTextReaderSoundEffectsSelectionBottomCollectionViewViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/2/25.
//

#import "ACCTextReaderSoundEffectsSelectionBottomCollectionViewViewModel.h"

#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <CreativeKit/ACCMacros.h>
#import <EffectPlatformSDK/EffectPlatform.h>

static NSString * const kACCTextReaderEffectPannel = @"speaking-voice";

@interface ACCTextReaderSoundEffectsSelectionBottomCollectionViewViewModel ()

@end

@implementation ACCTextReaderSoundEffectsSelectionBottomCollectionViewViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.cellModels = @[[[ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel alloc] init]];
        self.selectedIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    }
    return self;
}

- (void)useDefaultSpeaker
{
    NSMutableArray *tempArr = [@[] mutableCopy];
    [tempArr btd_addObject:[[ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel alloc] init]];
    ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel *cellModel = [[ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel alloc] init];
    [cellModel useDefaultSoundEffectWithAudioText:self.audioText];
    [tempArr btd_addObject:cellModel];
    self.cellModels = [tempArr copy];
}

- (void)fetchTextReaderTimbreListWithCompletion:(void (^)(NSError *))completion
{
    @weakify(self);
    [EffectPlatform downloadEffectListWithPanel:kACCTextReaderEffectPannel
                                     completion:^(NSError *error, IESEffectPlatformResponseModel *response) {
        @strongify(self);
        NSMutableArray *mutableArray = [NSMutableArray array];
        [mutableArray btd_addObject:self.cellModels[0]]; // the first one is none_speaker
        if (error || response.effects == nil || response.effects.count == 0) {
            ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel *cellModel = [[ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel alloc] init];
            [cellModel useDefaultSoundEffectWithAudioText:self.audioText];
            [mutableArray btd_addObject:cellModel];
        } else {
            [response.effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj,
                                                           NSUInteger idx,
                                                           BOOL * _Nonnull stop) {
                ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel *cellModel = [[ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel alloc] init];
                [cellModel configWithEffectModel:response.effects[idx] audioText:self.audioText];
                if ([cellModel.soundEffect isEqualToString:self.originalSpeakerID]) {
                    [mutableArray btd_insertObject:cellModel atIndex:1];
                } else {
                    [mutableArray btd_addObject:cellModel];
                }
            }];
        }
        self.cellModels = [mutableArray copy];
        acc_dispatch_main_async_safe(^{
            ACCBLOCK_INVOKE(completion, error);
        });
    }];
}

@end
