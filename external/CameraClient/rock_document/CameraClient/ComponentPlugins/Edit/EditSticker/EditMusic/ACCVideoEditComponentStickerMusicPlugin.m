//
//  ACCVideoEditComponentStickerMusicPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by Howie He on 2021/3/1.
//

#import "ACCVideoEditComponentStickerMusicPlugin.h"
#import "ACCVideoEditStickerComponent.h"
#import "ACCEditMusicServiceProtocol.h"

@implementation ACCVideoEditComponentStickerMusicPlugin

@synthesize component = _component;

+ (id)hostIdentifier
{
    return [ACCVideoEditStickerComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    id<ACCEditMusicServiceProtocol> musicService = IESAutoInline(serviceProvider, ACCEditMusicServiceProtocol);
    @weakify(self);
    [musicService.mvDidChangeMusicSignal subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        if (x.boolValue) {
            [[self hostComponent] clearAllEffectsAndStickers];
        }
    }];
}

- (ACCVideoEditStickerComponent *)hostComponent
{
    return self.component;
}

@end
