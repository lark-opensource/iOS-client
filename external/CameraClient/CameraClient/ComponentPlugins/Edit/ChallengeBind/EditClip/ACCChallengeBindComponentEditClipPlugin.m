//
//  ACCChallengeBindComponentEditClipPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by xiangpeng on 2021/03/05.
//

#import "ACCChallengeBindComponentEditClipPlugin.h"
#import "ACCVideoEditChallengeBindComponent.h"
#import "ACCVideoEditChallengeBindViewModel.h"
#import "ACCEditClipServiceProtocol.h"

@interface ACCChallengeBindComponentEditClipPlugin ()

@property (nonatomic, strong, readonly) ACCVideoEditChallengeBindComponent *hostComponent;
@property (nonatomic, strong, readonly) ACCVideoEditChallengeBindViewModel *challengeBindViewModel;

@end

@implementation ACCChallengeBindComponentEditClipPlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCVideoEditChallengeBindComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    id<ACCEditClipServiceProtocol> clipService = IESOptionalInline(serviceProvider, ACCEditClipServiceProtocol);
    
    @weakify(self);
    [[clipService.didRemoveAllEditsSignal deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self.challengeBindViewModel onRemovedAllEdits];
    }];
    
}

#pragma mark - Properties

- (ACCVideoEditChallengeBindComponent *)hostComponent
{
    return self.component;
}

-(ACCVideoEditChallengeBindViewModel *)challengeBindViewModel
{
    return [self.hostComponent getViewModel:[ACCVideoEditChallengeBindViewModel class]];
}

@end
