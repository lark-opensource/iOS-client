//
//  ACCEditStickerComponentSmartMoviePlugin.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/8/13.
//

#import "ACCEditStickerComponentSmartMoviePlugin.h"
#import <CameraClient/ACCStickerServiceImpl.h>
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import <CameraClient/ACCSmartMovieABConfig.h>
#import <CameraClient/ACCRepoImageAlbumInfoModel.h>
#import <CameraClient/ACCVideoEditStickerComponent.h>
#import <CameraClient/ACCVideoEditFlowControlService.h>

@interface ACCEditStickerComponentSmartMoviePlugin () <ACCVideoEditFlowControlSubscriber>

@property (nonatomic, strong, readonly) ACCVideoEditStickerComponent *hostComponent;

@end

@implementation ACCEditStickerComponentSmartMoviePlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCVideoEditStickerComponent class];
}

- (void)bindToComponent:(ACCVideoEditStickerComponent *)component
{
    if ([ACCSmartMovieABConfig isOn]) {
         // 图片模式下有自己的恢复逻辑 不需要走这套
        id<ACCVideoEditFlowControlService> service = IESAutoInline(component.serviceProvider, ACCVideoEditFlowControlService);
        [service addSubscriber:self];
        
        [component.stickerService.needRecoverStickers addPredicate:^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
            return YES;
        } with:self];
    }
}

- (void)willSwitchSmartMovieEditModeWithEditFlowService:(id<ACCVideoEditFlowControlService> _Nullable)service
{
    typeof(self.hostComponent) component = self.hostComponent;
    // 切换的时候实际需要按照save的操作流程走一遍
    [component.stickerBizModule readyForPublish];
    [component.stickerService finish];
}

#pragma mark - Properties

- (ACCVideoEditStickerComponent *)hostComponent
{
    return self.component;
}

@end
