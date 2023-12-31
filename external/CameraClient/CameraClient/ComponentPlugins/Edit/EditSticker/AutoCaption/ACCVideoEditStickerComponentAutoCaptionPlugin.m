//
//  ACCVideoEditStickerComponentAutoCaptionPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by Howie He on 2021/3/1.
//

#import "ACCVideoEditStickerComponentAutoCaptionPlugin.h"
#import "ACCVideoEditStickerComponent.h"
#import "ACCAutoCaptionServiceProtocol.h"
#import "ACCStickerServiceImpl.h"
#import <CreationKitInfra/ACCGroupedPredicate.h>

@implementation ACCVideoEditStickerComponentAutoCaptionPlugin

@synthesize component = _component;

+ (id)hostIdentifier
{
    return [ACCVideoEditStickerComponent class];
}

- (void)bindToComponent:(ACCVideoEditStickerComponent *)component
{
    ACCStickerServiceImpl *stickerService = component.stickerService;
    id<ACCAutoCaptionServiceProtocol> autoCaptionService = IESAutoInline(component.serviceProvider, ACCAutoCaptionServiceProtocol);
    @weakify(autoCaptionService);
    [stickerService.needResetPreviewEdge addPredicate:^BOOL(id  _Nullable input,  __autoreleasing id * _Nullable output) {
        @strongify(autoCaptionService);
        if (autoCaptionService == nil) {
            return YES;
        }
        
        return !autoCaptionService.isCaptionAction;
    } with:self];
}

@end
