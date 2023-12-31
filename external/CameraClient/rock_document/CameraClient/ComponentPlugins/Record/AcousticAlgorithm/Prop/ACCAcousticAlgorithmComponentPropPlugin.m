//
//  ACCAcousticAlgorithmComponentPropPlugin.m
//  CameraClient-Pods-Aweme
//
//  Created by xiafeiyu on 2021/8/2.
//

#import <ReactiveObjC/ReactiveObjC.h>

#import "ACCAcousticAlgorithmComponentPropPlugin.h"
#import "ACCAcousticAlgorithmComponent.h"
#import "ACCRecordPropService.h"
#import "ACCAudioPortService.h"
#import "ACCMicrophoneService.h"

#import <CreationKitInfra/ACCGroupedPredicate.h>
#import <CreationKitArch/IESEffectModel+ACCSticker.h>
#import <CreationKitRTProtocol/ACCCameraService.h>


@interface ACCAcousticAlgorithmComponentPropPlugin () <ACCRecordPropServiceSubscriber>

@property (nonatomic, strong) id<ACCCameraService> cameraService;

@end

@implementation ACCAcousticAlgorithmComponentPropPlugin

@synthesize component = _component;

+ (id)hostIdentifier
{
    return [ACCAcousticAlgorithmComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.cameraService = IESAutoInline(serviceProvider, ACCCameraService);
    id<ACCRecordPropService> propService = IESAutoInline(serviceProvider, ACCRecordPropService);
    [propService addSubscriber:self];
    id<ACCAudioPortService> audioPortService = IESAutoInline(serviceProvider, ACCAudioPortService);
    id<ACCMicrophoneService> microphoneService = IESAutoInline(serviceProvider, ACCMicrophoneService);
    [[microphoneService.micStateSignal takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id  _Nullable x) {
        [self.hostComponent enableForceRecordAudioIfNeeded];
    }];
    
    @weakify(propService);
    @weakify(audioPortService);
    [self.hostComponent.openAECPredicate addPredicate:^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(propService);
        @strongify(audioPortService);
        IESEffectModel *prop = propService.prop;
        return prop.audioGraphMicSource && prop.audioGraphUseOutput && audioPortService.outputPort == ACCAudioIOPortBuiltin;
    } with:self];
    
    [[self hostComponent].forceRecordAudioPredicate addPredicate:^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(propService);
        IESEffectModel *prop = propService.prop;
        if (prop.audioGraphUseOutput) {
            return YES;
        }
        BOOL isVoiceRecognition = [prop isTypeVoiceRecognization];
        if (isVoiceRecognition && self.hostComponent.repository.repoVideoInfo.microphoneBarState == ACCMicrophoneBarStateSetOn) {
            return YES;
        }
        return NO;
    } with:self];
}

- (void)propServiceWillApplyProp:(IESEffectModel *)prop propSource:(ACCPropSource)propSource
{
    if (prop) {
        // must in order: enable algorithms -> set backend
        [self.hostComponent openAlgorithmsIfNeeded];
        [self.hostComponent enableForceRecordAudioIfNeeded];
    } else {
        [self.hostComponent openAlgorithmsIfNeeded];
        [self.hostComponent enableForceRecordAudioIfNeeded];
    }
}

- (ACCAcousticAlgorithmComponent *)hostComponent
{
    return self.component;
}

@end
