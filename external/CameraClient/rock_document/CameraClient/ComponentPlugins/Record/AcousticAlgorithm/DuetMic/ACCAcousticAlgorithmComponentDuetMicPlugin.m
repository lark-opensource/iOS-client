//
//  ACCAcousticAlgorithmComponentDuetMicPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by xiafeiyu on 2021/06/05.
//

#import "ACCAcousticAlgorithmComponentDuetMicPlugin.h"

#import <CameraClient/ACCConfigKeyDefines.h>

#import "ACCAcousticAlgorithmComponent.h"
#import "ACCAudioPortService.h"
#import "ACCMicrophoneService.h"
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import "AWERepoDuetModel.h"
#import "ACCDuetLayoutService.h"
#import "ACCConfigKeyDefines.h"

@interface ACCAcousticAlgorithmComponentDuetMicPlugin ()

@property (nonatomic, strong, readonly) ACCAcousticAlgorithmComponent *hostComponent;
@property (nonatomic, strong) id<IESServiceProvider> serviceProvider;

@property (nonatomic, weak) id<ACCMicrophoneService> microphoneService;
@property (nonatomic, weak) id<ACCAudioPortService> audioPortService;
@property (nonatomic, weak) AWERepoDuetModel *repoDuet;

@property (nonatomic, strong, nullable) BOOL(^openAECPredicate)(id  _Nullable input, __autoreleasing id * _Nullable output);
@property (nonatomic, strong, nullable) BOOL(^openDAPredicate)(id  _Nullable input, __autoreleasing id * _Nullable output);
@property (nonatomic, strong, nullable) BOOL(^openLEPredicate)(id  _Nullable input, __autoreleasing id * _Nullable output);
@property (nonatomic, strong, nullable) BOOL(^openEBPredicate)(id  _Nullable input, __autoreleasing id * _Nullable output);
@property (nonatomic, strong, nullable) BOOL(^showEBBarItemPredicate)(id  _Nullable input, __autoreleasing id * _Nullable output);
@property (nonatomic, strong, nullable) ACCLoudnessLUFSProvider lufsBlock;
@property (nonatomic, strong, nullable) BOOL(^forceRecordAudioPredicate)(id  _Nullable input, __autoreleasing id * _Nullable output);

@end

@implementation ACCAcousticAlgorithmComponentDuetMicPlugin

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
    self.repoDuet = self.hostComponent.repository.repoDuet;
    // 初始化的时候发现是合拍，立即注册 predicate
    if (self.repoDuet.isDuet) {
        [self becomeActive];
    }
}

- (void)becomeActive
{
    NSAssert(self.openAECPredicate == nil, @"already active");
    @weakify(self);
    // AEC
    self.openAECPredicate = ^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(self);
        return ACCConfigBool(kConfigBool_duet_record_audio_aec) && [self meetCommonRequirements] && self.audioPortService.outputPort == ACCAudioIOPortBuiltin;
    };
    [self.hostComponent.openAECPredicate addPredicate:self.openAECPredicate with:self];
    
    // DA
    self.openDAPredicate = ^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(self);
        BOOL hitABTest = (self.repoDuet.isDuetSing && ACCConfigBool(kConfigBool_duet_sing_record_audio_da)) || (self.repoDuet.isDuet && !self.repoDuet.isDuetSing && ACCConfigBool(kConfigBool_duet_record_audio_da));
        return hitABTest && [self meetCommonRequirements] && self.audioPortService.outputPort == ACCAudioIOPortBuiltin;
    };
    [self.hostComponent.openDAPredicate addPredicate:self.openDAPredicate with:self];
    
    // LE
    self.openLEPredicate = ^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(self);
        return ACCConfigBool(kConfigBool_duet_record_audio_le) && [self meetCommonRequirements];
    };
    [self.hostComponent.openLEPredicate addPredicate:self.openLEPredicate with:self];
    self.lufsBlock = ^NSInteger{
        @strongify(self);
        return [self meetCommonRequirements] ? ACCConfigInt(kConfigInt_record_target_lufs) : ACCLoudnessUFLInvalid;
    };
    [self.hostComponent registerLUFSProvider:self.lufsBlock];
    
    // EB
    self.openEBPredicate = ^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(self);
        return ACCConfigBool(kConfigBool_karaoke_ios_duet_ear_back) && self.repoDuet.isDuetSing && self.audioPortService.inputPort == ACCAudioIOPortWiredHeadset && self.hostComponent.userOpenedEarback;
    };
    [self.hostComponent.openEBPredicate addPredicate:self.openEBPredicate with:self];
    self.showEBBarItemPredicate = ^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(self);
        return ACCConfigBool(kConfigBool_karaoke_ios_duet_ear_back) && self.repoDuet.isDuetSing && self.audioPortService.inputPort == ACCAudioIOPortWiredHeadset;
    };
    [self.hostComponent.showEBBarItemPredicate addPredicate:self.showEBBarItemPredicate with:self];
    
    // Force Audio Record
    self.forceRecordAudioPredicate = ^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(self);
        return [self meetCommonRequirements];
    };
    [self.hostComponent.forceRecordAudioPredicate addPredicate:self.forceRecordAudioPredicate with:self];
}

- (void)resignActive
{
    [self.hostComponent.openAECPredicate removePredicate:self.openAECPredicate];
    [self.hostComponent.openDAPredicate removePredicate:self.openDAPredicate];
    [self.hostComponent.openLEPredicate removePredicate:self.openLEPredicate];
    [self.hostComponent.forceRecordAudioPredicate removePredicate:self.forceRecordAudioPredicate];
    [self.hostComponent.openEBPredicate removePredicate:self.openEBPredicate];
    [self.hostComponent.showEBBarItemPredicate removePredicate:self.showEBBarItemPredicate];
    [self.hostComponent unregisterLUFProvider:self.lufsBlock];
    self.openAECPredicate = nil;
    self.openDAPredicate = nil;
    self.openLEPredicate = nil;
    self.forceRecordAudioPredicate = nil;
    self.openEBPredicate = nil;
    self.showEBBarItemPredicate = nil;
    self.lufsBlock = nil;
    
    [self.hostComponent openAlgorithmsIfNeeded];
    [self.hostComponent enableForceRecordAudioIfNeeded];
    [self.hostComponent updateBarItemsVisibility];
}

- (BOOL)meetCommonRequirements
{
    return (self.repoDuet.isDuet && self.microphoneService.currentMicBarState == ACCMicrophoneBarStateSetOn) || self.repoDuet.isDuetSing;
}

#pragma mark - Properties

- (ACCAcousticAlgorithmComponent *)hostComponent
{
    return self.component;
}

@end
