//
//  ACCAcousticAlgorithmComponentAudioModePlugin.m
//  CameraClient-Pods-AwemeCore
//
//  Created by liujinze on 2021/11/17.
//

#import "ACCAcousticAlgorithmComponentAudioModePlugin.h"
#import "ACCAcousticAlgorithmComponent.h"
#import "ACCRepoAudioModeModel.h"
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import <ReactiveObjC/ReactiveObjC.h>

@interface ACCAcousticAlgorithmComponentAudioModePlugin()

@property (nonatomic, strong, readonly) ACCAcousticAlgorithmComponent *hostComponent;

@end

@implementation ACCAcousticAlgorithmComponentAudioModePlugin

@synthesize component = _component;

- (void)bindServices:(nonnull id<IESServiceProvider>)serviceProvider {
    @weakify(self);
    [self.hostComponent.forceRecordAudioPredicate addPredicate:^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(self);
        return [self meetCommonRequirements];
    } with:self];
}

- (BOOL)meetCommonRequirements
{
    if (self.hostComponent.repository.repoAudioMode.isAudioMode) {
        return YES;
    }
    return NO;
}

+ (id)hostIdentifier
{
    return [ACCAcousticAlgorithmComponent class];
}

#pragma mark - Properties

- (ACCAcousticAlgorithmComponent *)hostComponent
{
    return self.component;
}


@end
