//
//  ACCVideoFilterComponentLiveStickerPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by xiangpeng on 2021/03/08.
//

#import "ACCVideoFilterComponentLiveStickerPlugin.h"
#import "ACCEditVideoFilterComponent.h"

#import "ACCLiveStickerServiceProtocol.h"

@interface ACCVideoFilterComponentLiveStickerPlugin ()

@property (nonatomic, strong, readonly) ACCEditVideoFilterComponent *hostComponent;

@end

@implementation ACCVideoFilterComponentLiveStickerPlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCEditVideoFilterComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    id<ACCLiveStickerServiceProtocol> liveStickerService = IESOptionalInline(serviceProvider, ACCLiveStickerServiceProtocol);
    
    
    @weakify(self);
    [liveStickerService.toggleEditingViewSignal.deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self)
        [self.hostComponent.filterService.filterSwitchManager updatePanGestureEnabled:!x.boolValue];
    }];
    
}

#pragma mark - Properties

- (ACCEditVideoFilterComponent *)hostComponent
{
    return self.component;
}

@end
