//
//  ACCAcousticAlgorithmComponentMusicMicPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by xiafeiyu on 2021/06/05.
//

#import "ACCAcousticAlgorithmComponentMusicMicPlugin.h"
#import "ACCAcousticAlgorithmComponent.h"

#import <ReactiveObjC/ReactiveObjC.h>
#import <CameraClient/ACCConfigKeyDefines.h>

#import "ACCAudioPortService.h"
#import "ACCMicrophoneService.h"
#import "AWERepoDuetModel.h"
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import "ACCConfigKeyDefines.h"

@interface ACCAcousticAlgorithmComponentMusicMicPlugin ()

@property (nonatomic, strong, readonly) ACCAcousticAlgorithmComponent *hostComponent;
@property (nonatomic, strong) id<IESServiceProvider> serviceProvider;

@property (nonatomic, strong) id<ACCMicrophoneService> microphoneService;
@property (nonatomic, strong) id<ACCAudioPortService> audioPortService;

@end

@implementation ACCAcousticAlgorithmComponentMusicMicPlugin

@synthesize component = _component;

IESAutoInject(self.serviceProvider, microphoneService, ACCMicrophoneService);
IESAutoInject(self.serviceProvider, audioPortService, ACCAudioPortService)

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCAcousticAlgorithmComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.serviceProvider = serviceProvider;
    @weakify(self);
    [self.hostComponent.openAECPredicate addPredicate:^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(self);
        return ACCConfigBool(kConfigBool_music_record_audio_aec) && [self meetCommonRequirements] && self.audioPortService.outputPort == ACCAudioIOPortBuiltin;
    } with:self];
    [self.hostComponent.openDAPredicate addPredicate:^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(self);
        return ACCConfigBool(kConfigBool_music_record_audio_da) && [self meetCommonRequirements] && self.audioPortService.outputPort == ACCAudioIOPortBuiltin;
    } with:self];
    [self.hostComponent.openLEPredicate addPredicate:^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(self);
        return ACCConfigBool(kConfigBool_music_record_audio_le) && [self meetCommonRequirements];
    } with:self];
    [self.hostComponent registerLUFSProvider:^NSInteger{
        @strongify(self);
        return [self meetCommonRequirements] ? ACCConfigInt(kConfigInt_record_target_lufs) : ACCLoudnessUFLInvalid;
    }];
    
    [self.hostComponent.forceRecordAudioPredicate addPredicate:^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(self);
        return [self meetCommonRequirements];
    } with:self];
    [[self.microphoneService.micStateSignal takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self.hostComponent openAlgorithmsIfNeeded];
        [self.hostComponent enableForceRecordAudioIfNeeded];
    }];
}

- (BOOL)meetCommonRequirements
{
    if (self.hostComponent.repository.repoDuet.isDuet) {
        // Duet will be handled by ACCAcousticAlgorithmComponentDuetMicPlugin
        return NO;
    }
    return self.hostComponent.repository.repoMusic.music != nil && self.microphoneService.currentMicBarState == ACCMicrophoneBarStateSetOn;
}

#pragma mark - Properties

- (ACCAcousticAlgorithmComponent *)hostComponent
{
    return self.component;
}

@end
