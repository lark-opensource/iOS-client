//
//  ACCVideoFilterComponentCutMusicPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by xiangpeng on 2021/03/08.
//

#import "ACCVideoFilterComponentCutMusicPlugin.h"
#import "ACCEditVideoFilterComponent.h"
#import "ACCEditCutMusicServiceProtocol.h"

#import <CreationKitInfra/ACCRACWrapper.h>

@interface ACCVideoFilterComponentCutMusicPlugin ()

@property (nonatomic, strong, readonly) ACCEditVideoFilterComponent *hostComponent;

@end

@implementation ACCVideoFilterComponentCutMusicPlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCEditVideoFilterComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    id<ACCEditCutMusicServiceProtocol> cutMusicService = IESAutoInline(serviceProvider, ACCEditCutMusicServiceProtocol);
    
    @weakify(self);
    [[[cutMusicService didClickCutMusicButtonSignal] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        [self.hostComponent.filterService.filterSwitchManager updatePanGestureEnabled:NO];
    }];
    
    [[[cutMusicService didFinishCutMusicSignal] deliverOnMainThread] subscribeNext:^(ACCCutMusicRangeChangeContext * _Nullable x) {
        @strongify(self)
        [self.hostComponent.filterService.filterSwitchManager updatePanGestureEnabled:YES];
    }];
    
}

#pragma mark - Properties

- (ACCEditVideoFilterComponent *)hostComponent
{
    return self.component;
}

@end
