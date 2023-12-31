//
//  ACCRecorderAudioModeComponentTextModePlugin.m
//  CameraClient-Pods-AwemeCore
//
//  Created by liujinze on 2021/11/3.
//

#import "ACCRecorderAudioModeComponentTextModePlugin.h"
#import "ACCRecorderAudioModeComponent.h"
#import "ACCTextModeService.h"

@interface ACCRecorderAudioModeComponentTextModePlugin()

@property (nonatomic, strong, readonly) ACCRecorderAudioModeComponent *hostComponent;
@property (nonatomic, strong) id<ACCTextModeService> textModeService;

@end

@implementation ACCRecorderAudioModeComponentTextModePlugin

@synthesize component = _component;

+ (id)hostIdentifier
{
    return ACCRecorderAudioModeComponent.class;
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider{
    self.textModeService = IESAutoInline(serviceProvider, ACCTextModeService);
}

- (void)bindToComponent:(ACCRecorderAudioModeComponent *)component
{
    @weakify(component);
    [self.textModeService.textModeVCDidAppearSignal subscribeNext:^(NSNumber *  _Nullable x) {
        @strongify(component);
        [component silentReleaseAudioModeVC];
    }];
}

#pragma mark - Properties

- (ACCRecorderAudioModeComponent *)hostComponent
{
    return self.component;
}

@end
