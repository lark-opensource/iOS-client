//
//  ACCStickerComponentPannelSearchPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by <#Bytedance#> on 2021/03/08.
//

#import "ACCStickerComponentPannelSearchPlugin.h"
#import "ACCStickerPannelComponent.h"
#import "ACCLyricsStickerServiceProtocol.h"
#import "ACCStickerSelectionContext.h"

@interface ACCStickerComponentPannelSearchPlugin ()

@property (nonatomic, strong, readonly) ACCStickerPannelComponent *hostComponent;

@end

@implementation ACCStickerComponentPannelSearchPlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCStickerPannelComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    id<ACCLyricsStickerServiceProtocol> lyricStickerService = IESOptionalInline(serviceProvider, ACCLyricsStickerServiceProtocol);
    @weakify(self);
    [[lyricStickerService willShowLyricMusicSelectPanelSignal].deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        ACCStickerSelectionContext *context = [[ACCStickerSelectionContext alloc] init];
        context.stickerType = ACCStickerTypeLyricSticker;
        [[self hostComponent] removeStickerPannelWithAlphaAnimated:YES selectedSticker:context];
    }];
    
    [[lyricStickerService didCancelLyricMusicSelectSignal].deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [[self hostComponent] showStickerPannelWithAlphaAnimated:YES];
    }];
}

#pragma mark - Properties

- (ACCStickerPannelComponent *)hostComponent
{
    return self.component;
}

@end
