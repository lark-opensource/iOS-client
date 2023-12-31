//
//  ACCEditStickerComponentImageAlbumEditPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by <#Bytedance#> on 2021/03/04.
//

#import "ACCEditStickerComponentImageAlbumEditPlugin.h"
#import "ACCVideoEditStickerComponent.h"
#import "ACCStickerServiceImpl.h"
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import <CameraClient/ACCRepoImageAlbumInfoModel.h>
#import "ACCVideoEditFlowControlService.h"

@interface ACCEditStickerComponentImageAlbumEditPlugin () <ACCVideoEditFlowControlSubscriber>

@property (nonatomic, strong, readonly) ACCVideoEditStickerComponent *hostComponent;

@end

@implementation ACCEditStickerComponentImageAlbumEditPlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCVideoEditStickerComponent class];
}

- (void)bindToComponent:(ACCVideoEditStickerComponent *)component
{
    AWEVideoPublishViewModel * resposity = component.repository;
    /// 图集发布模式下 视频转图片 订阅一下切换的逻辑，模拟下一步 保存贴纸信息
    /// 图片转视频 不需要处理，因为图片模式下有自己的恢复逻辑，避免重复
    /// @todo @qiuhang @zhizhao 目前只是简单兼容，后续可能还是需要优化下这块逻辑 避免留坑
    if (resposity.repoImageAlbumInfo.transformContext.isImageAlbumTransformContext && !resposity.repoImageAlbumInfo.isImageAlbumEdit) {
         // 图片模式下有自己的恢复逻辑 不需要走这套
        id<ACCVideoEditFlowControlService> service = IESAutoInline(component.serviceProvider, ACCVideoEditFlowControlService);
        [service addSubscriber:self];
        
        [component.stickerService.needRecoverStickers addPredicate:^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
            return YES;
        } with:self];
    }
}

- (void)willSwitchImageAlbumEditModeWithEditFlowService:(id<ACCVideoEditFlowControlService>)service
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
