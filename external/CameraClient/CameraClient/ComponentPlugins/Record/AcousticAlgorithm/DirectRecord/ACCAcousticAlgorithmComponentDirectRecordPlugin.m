//
//  ACCAcousticAlgorithmComponentDirectRecordPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by xiafeiyu on 2021/06/05.
//

#import "ACCAcousticAlgorithmComponentDirectRecordPlugin.h"

#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <ReactiveObjC/ReactiveObjC.h>
#import <CameraClient/ACCConfigKeyDefines.h>

#import "ACCAcousticAlgorithmComponent.h"
#import "ACCMicrophoneService.h"
#import "ACCKaraokeService.h"
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>

@interface ACCAcousticAlgorithmComponentDirectRecordPlugin () <ACCRecordSwitchModeServiceSubscriber>

@property (nonatomic, strong, readonly) ACCAcousticAlgorithmComponent *hostComponent;

@property (nonatomic, strong) id<ACCMicrophoneService> microphoneService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCKaraokeService> karaokeService;

@end

@implementation ACCAcousticAlgorithmComponentDirectRecordPlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCAcousticAlgorithmComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.switchModeService = IESAutoInline(serviceProvider, ACCRecordSwitchModeService);
    self.karaokeService = IESAutoInline(serviceProvider, ACCKaraokeService);
    self.microphoneService = IESAutoInline(serviceProvider, ACCMicrophoneService);
    
    [self.switchModeService addSubscriber:self];
    @weakify(self);
    // LE
    [self.hostComponent.openLEPredicate addPredicate:^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(self);
        // if record with music, will be handled in ACCAcousticComponentMusicMicPlugin
        // if is duet, will be handled in ACCAcousticComponentDuetMicPlugin
        // if is karaoke,  will be handled in ACCAcousticComponentKaraokePlugin
        return ACCConfigBool(kConfigBool_shoot_record_audio_le) && [self meetCommonRequirements];
    } with:self];
    [self.hostComponent registerLUFSProvider:^NSInteger{
        @strongify(self);
        return [self meetCommonRequirements] ? ACCConfigInt(kConfigInt_record_target_lufs) : ACCLoudnessUFLInvalid;
    }];
}

- (BOOL)meetCommonRequirements
{
    return self.hostComponent.repository.repoMusic.music == nil && !self.hostComponent.repository.repoDuet.isDuet && !self.karaokeService.inKaraokeRecordPage;
}

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    [self.hostComponent openAlgorithmsIfNeeded];
}

#pragma mark - Properties

- (ACCAcousticAlgorithmComponent *)hostComponent
{
    return self.component;
}

@end
