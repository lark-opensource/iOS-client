//
//  ACCRecorderTextModeComponentAudioModePlugin.m
//  CameraClient-Pods-AwemeCore
//
//  Created by liujinze on 2021/11/3.
//

#import "ACCRecorderTextModeComponentAudioModePlugin.h"
#import "ACCRecorderTextModeComponent.h"
#import "ACCAudioModeService.h"

@interface ACCRecorderTextModeComponentAudioModePlugin()

@property (nonatomic, strong, readonly) ACCRecorderTextModeComponent *hostComponent;
@property (nonatomic, strong) id<ACCAudioModeService> audioModeService;

@end

@implementation ACCRecorderTextModeComponentAudioModePlugin

@synthesize component = _component;

+ (id)hostIdentifier
{
    return ACCRecorderTextModeComponent.class;
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider{
    self.audioModeService = IESAutoInline(serviceProvider, ACCAudioModeService);
}

- (void)bindToComponent:(ACCRecorderTextModeComponent *)component
{
    @weakify(component);
    [self.audioModeService.audioModeVCDidAppearSignal subscribeNext:^(NSNumber *  _Nullable x) {
        @strongify(component);
        [component silentReleaseTextModeVC];
    }];
}

#pragma mark - Properties

- (ACCRecorderTextModeComponent *)hostComponent
{
    return self.component;
}

@end
