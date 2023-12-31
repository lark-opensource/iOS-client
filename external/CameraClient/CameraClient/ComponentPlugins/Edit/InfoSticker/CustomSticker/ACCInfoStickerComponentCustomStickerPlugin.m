//
//  ACCInfoStickerComponentCustomStickerPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by <#Bytedance#> on 2021/03/08.
//

#import "ACCInfoStickerComponentCustomStickerPlugin.h"
#import "ACCInfoStickerComponent.h"
#import "ACCCustomStickerServiceProtocol.h"

@interface ACCInfoStickerComponentCustomStickerPlugin ()

@property (nonatomic, strong, readonly) ACCInfoStickerComponent *hostComponent;

@end

@implementation ACCInfoStickerComponentCustomStickerPlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCInfoStickerComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    id<ACCCustomStickerServiceProtocol> customStickerService = IESAutoInline(serviceProvider, ACCCustomStickerServiceProtocol);
    @weakify(self);
    [customStickerService.addCustomStickerSignal.deliverOnMainThread subscribeNext:^(ACCAddInfoStickerContext *x) {
        @strongify(self);
        [self.hostComponent addCustomSticker:x];
    }];
}

#pragma mark - Properties

- (ACCInfoStickerComponent *)hostComponent
{
    return self.component;
}

@end
