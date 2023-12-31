//
//  ACCInfoComponentStickerMusicPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by <#Bytedance#> on 2021/03/08.
//

#import "ACCInfoComponentStickerMusicPlugin.h"
#import "ACCInfoStickerComponent.h"
#import "ACCEditMusicServiceProtocol.h"

@interface ACCInfoComponentStickerMusicPlugin ()

@property (nonatomic, strong, readonly) ACCInfoStickerComponent *hostComponent;

@end

@implementation ACCInfoComponentStickerMusicPlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCInfoStickerComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    id<ACCEditMusicServiceProtocol> musicService = IESAutoInline(serviceProvider, ACCEditMusicServiceProtocol);
    @weakify(self);
    [musicService.didAddMusicSignal.deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        [self.hostComponent refreshCover];
    }];
}

#pragma mark - Properties

- (ACCInfoStickerComponent *)hostComponent
{
    return self.component;
}

@end
