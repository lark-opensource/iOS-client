//
//  ACCAcousticAlgorithmComponentKaraokePlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by xiafeiyu on 2021/06/06.
//

#import "ACCAcousticAlgorithmComponentKaraokePlugin.h"

#import <ReactiveObjC/ReactiveObjC.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CameraClient/ACCConfigKeyDefines.h>

#import "ACCAudioPortService.h"
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import "ACCAcousticAlgorithmComponent.h"
#import "ACCKaraokeService.h"

@interface ACCAcousticAlgorithmComponentKaraokePlugin () <ACCRecordSwitchModeServiceSubscriber, ACCKaraokeServiceSubscriber>

@property (nonatomic, strong, readonly) ACCAcousticAlgorithmComponent *hostComponent;
@property (nonatomic, assign) BOOL isActive;

@property (nonatomic, strong) id<ACCAudioPortService> audioPortService;
@property (nonatomic, weak) id<ACCKaraokeService> karaokeService;
@property (nonatomic, strong, nullable) BOOL(^openAECPredicate)(id  _Nullable input, __autoreleasing id * _Nullable output);
@property (nonatomic, strong, nullable) BOOL(^openLEPredicate)(id  _Nullable input, __autoreleasing id * _Nullable output);
@property (nonatomic, strong, nullable) ACCLoudnessLUFSProvider lufsBlock;
@property (nonatomic, strong, nullable) BOOL(^openDAPredicate)(id  _Nullable input, __autoreleasing id * _Nullable output);
@property (nonatomic, strong, nullable) BOOL(^openEBPredicate)(id  _Nullable input, __autoreleasing id * _Nullable output);
@property (nonatomic, strong, nullable) BOOL(^showEBBarItemPredicate)(id  _Nullable input, __autoreleasing id * _Nullable output);
@property (nonatomic, strong) RACDisposable *subscription;

@end

@implementation ACCAcousticAlgorithmComponentKaraokePlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCAcousticAlgorithmComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.karaokeService = IESAutoInline(serviceProvider, ACCKaraokeService);
    self.audioPortService = IESAutoInline(serviceProvider, ACCAudioPortService);
    [self.karaokeService addSubscriber:self];
}

- (void)karaokeService:(id<ACCKaraokeService>)service inKaraokeRecordPageDidChangeFrom:(BOOL)prevState to:(BOOL)state
{
    if (state) {
        [self becomeActive];
    } else {
        [self resignActive];
    }
}

- (void)becomeActive
{
    if (self.isActive) {
        return;
    }
    @weakify(self);
    self.openAECPredicate = ^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(self);
        return ACCConfigBool(kConfigBool_karaoke_record_audio_aec) && self.audioPortService.outputPort == ACCAudioIOPortBuiltin && self.karaokeService.inKaraokeRecordPage;
    };
    [self.hostComponent.openAECPredicate addPredicate:self.openAECPredicate with:self];
    
    self.openDAPredicate = ^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(self);
        return ACCConfigBool(kConfigBool_karaoke_record_audio_da) && self.audioPortService.outputPort == ACCAudioIOPortBuiltin && self.karaokeService.inKaraokeRecordPage;
    };
    [self.hostComponent.openDAPredicate addPredicate:self.openDAPredicate with:self];
    
    self.openLEPredicate = ^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(self);
        return ACCConfigBool(kConfigBool_karaoke_record_audio_le) && self.karaokeService.inKaraokeRecordPage;
    };
    [self.hostComponent.openLEPredicate addPredicate:self.openLEPredicate with:self];
    self.lufsBlock = ^NSInteger{
        return -12;
    };
    [self.hostComponent registerLUFSProvider:self.lufsBlock];
    
    self.openEBPredicate = ^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(self);
        return self.audioPortService.inputPort == ACCAudioIOPortWiredHeadset && self.karaokeService.inKaraokeRecordPage && self.hostComponent.userOpenedEarback;
    };
    [self.hostComponent.openEBPredicate addPredicate:self.openEBPredicate with:self];
    self.showEBBarItemPredicate = ^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(self);
        return self.karaokeService.inKaraokeRecordPage && self.audioPortService.inputPort == ACCAudioIOPortWiredHeadset;
    };
    [self.hostComponent.showEBBarItemPredicate addPredicate:self.showEBBarItemPredicate with:self];
    
    self.subscription = [[self.karaokeService.updateAcousticAlgoSignal takeUntil:self.rac_willDeallocSignal].deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self.hostComponent openAlgorithmsIfNeeded];
    }];
    [self.hostComponent openAlgorithmsIfNeeded];
    [self.hostComponent updateBarItemsVisibility];
    self.isActive = YES;
}

- (void)resignActive
{
    [self.hostComponent.openAECPredicate removePredicate:self.openAECPredicate];
    [self.hostComponent.openDAPredicate removePredicate:self.openDAPredicate];
    [self.hostComponent.openLEPredicate removePredicate:self.openLEPredicate];
    [self.hostComponent.openEBPredicate removePredicate:self.openEBPredicate];
    [self.hostComponent.showEBBarItemPredicate removePredicate:self.showEBBarItemPredicate];
    [self.hostComponent unregisterLUFProvider:self.lufsBlock];
    self.openAECPredicate = nil;
    self.openDAPredicate = nil;
    self.openLEPredicate = nil;
    self.openEBPredicate = nil;
    self.showEBBarItemPredicate = nil;
    [self.subscription dispose];
    self.subscription = nil;
    self.lufsBlock = nil;
    [self.hostComponent openAlgorithmsIfNeeded];
    [self.hostComponent updateBarItemsVisibility];
    self.isActive = NO;
}

#pragma mark - Properties

- (ACCAcousticAlgorithmComponent *)hostComponent
{
    return self.component;
}

@end
