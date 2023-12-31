//
//  ACCStickerComponentPannelLyricsPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by <#Bytedance#> on 2021/03/08.
//

#import "ACCStickerComponentPannelLyricsPlugin.h"
#import "ACCStickerPannelComponent.h"
#import "ACCSearchStickerServiceProtocol.h"
#import "ACCAddInfoStickerContext.h"
#import <CreativeKit/ACCMacros.h>

@interface ACCStickerComponentPannelLyricsPlugin ()

@property (nonatomic, strong, readonly) ACCStickerPannelComponent *hostComponent;

@end

@implementation ACCStickerComponentPannelLyricsPlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCStickerPannelComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    id<ACCSearchStickerServiceProtocol> searchStickerService = IESOptionalInline(serviceProvider, ACCSearchStickerServiceProtocol);
    @weakify(self);
    [searchStickerService.configPannelStatusSignal.deliverOnMainThread subscribeNext:^(NSNumber *  _Nullable x) {
        @strongify(self);
        [[self hostComponent] configPannelVC:x.boolValue];
    }];
    [searchStickerService.addSearchedStickerSignal.deliverOnMainThread subscribeNext:^(ACCAddInfoStickerContext *_Nullable x) {
        @strongify(self);
        [[self hostComponent] addSearchInfoSticker:x];
        ACCBLOCK_INVOKE(x.completion);
    }];
}

#pragma mark - Properties

- (ACCStickerPannelComponent *)hostComponent
{
    return self.component;
}

@end
