//
//  ACCVideoEditStickerComponentLyricsStickerPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by Howie He on 2021/3/1.
//

#import "ACCVideoEditStickerComponentLyricsStickerPlugin.h"
#import "ACCVideoEditStickerComponent.h"
#import "ACCLyricsStickerServiceProtocol.h"
#import "ACCStickerServiceImpl.h"
#import <CreationKitInfra/ACCGroupedPredicate.h>

@implementation ACCVideoEditStickerComponentLyricsStickerPlugin

@synthesize component = _component;

+ (id)hostIdentifier
{
    return [ACCVideoEditStickerComponent class];
}

- (void)bindToComponent:(ACCVideoEditStickerComponent *)component
{
    ACCStickerServiceImpl *stickerService = component.stickerService;
    id<ACCLyricsStickerServiceProtocol> lyricsStickerService = IESAutoInline(component.serviceProvider, ACCLyricsStickerServiceProtocol);
    @weakify(lyricsStickerService);
    [stickerService.needResetPreviewEdge addPredicate:^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(lyricsStickerService);
        if (lyricsStickerService == nil) {
            return YES;
        }
        
        return !lyricsStickerService.hasAlreadyAddLyricSticker;
    } with:self];
}

@end
