//
//  ACCVideoEditComponentStickerClipPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by Howie He on 2021/3/1.
//

#import "ACCVideoEditComponentStickerClipPlugin.h"
#import <IESInject/IESInject.h>
#import "ACCEditClipServiceProtocol.h"
#import "ACCEditClipV1ServiceProtocol.h"
#import "ACCVideoEditStickerComponent.h"
#import "ACCStickerServiceImpl.h"

@implementation ACCVideoEditComponentStickerClipPlugin

@synthesize component = _component;

+ (id)hostIdentifier
{
    return [ACCVideoEditStickerComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    @weakify(self);
    [(IESOptionalInline(serviceProvider, ACCEditClipServiceProtocol)).removeAllEditsSignal subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [[self hostComponent].stickerService removeAllInfoStickers];
    }];
    
    [(IESOptionalInline(serviceProvider, ACCEditClipV1ServiceProtocol)).removeAllEditsSignal subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [[self hostComponent].stickerService removeAllInfoStickers];
    }];
    
    [(IESOptionalInline(serviceProvider, ACCEditClipV1ServiceProtocol)).videoClipClickedSignal subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [[self hostComponent].stickerService cancelAllPinSticker];
    }];
}

- (ACCVideoEditStickerComponent *)hostComponent
{
    return self.component;
}

@end
