//
//  ACCRecordCloseComponentKaraokePlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by xiafeiyu on 2021/04/10.
//

#import "ACCRecordCloseComponentKaraokePlugin.h"

#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreativeKit/ACCProtocolContainer.h>

#import "ACCKaraokeService.h"
#import "ACCLayoutContainerProtocolD.h"
#import "ACCRecordCloseComponent.h"

@interface ACCRecordCloseComponentKaraokePlugin () <ACCKaraokeServiceSubscriber>

@property (nonatomic, weak, readonly) ACCRecordCloseComponent *hostComponent;

@property (nonatomic, strong) id<IESServiceProvider> serviceProvider;
@property (nonatomic, weak) id<ACCKaraokeService> karaokeService;
@property (nonatomic, weak) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, assign) BOOL buttonRemovedByMe;


@end

@implementation ACCRecordCloseComponentKaraokePlugin

@synthesize component = _component;

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCRecordCloseComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.serviceProvider = serviceProvider;
    self.karaokeService = IESAutoInline(serviceProvider, ACCKaraokeService);
    [self.karaokeService addSubscriber:self];
}

- (void)addCloseButtonToHierarchy
{
    [self.viewContainer.interactionView insertSubview:self.hostComponent.closeButton aboveSubview:self.viewContainer.preview];
    [self.viewContainer.layoutManager addSubview:self.hostComponent.closeButton viewType:ACCViewTypeClose];
    self.hostComponent.reshootTitle = nil;
    self.hostComponent.exitTitle = nil;
    self.buttonRemovedByMe = NO;
}

#pragma mark - Protocol Implementations

#pragma mark ACCKaraokeServiceSubscriber

- (void)karaokeService:(id<ACCKaraokeService>)service inKaraokeRecordPageDidChangeFrom:(BOOL)prevState to:(BOOL)state
{
    if (state) {
        // 进入了K歌拍摄页
        if (self.karaokeService.musicSource == ACCKaraokeMusicSourceKaraokeSelectMusic || self.karaokeService.musicSource == ACCKaraokeMusicSourceRecordSelectMusic) {
            // 从 K歌选择页/主拍摄页 选择歌曲后进入K歌拍摄页，将关闭按钮X移除，由 AWEKaraokeBackComponent 添加返回按钮<
            [ACCGetProtocol(self.viewContainer.layoutManager, ACCLayoutContainerProtocolD) removeSubviewType:ACCViewTypeClose];
            [self.hostComponent.closeButton removeFromSuperview];
            self.buttonRemovedByMe = YES;
        } else {
            // 从其他路径（draft/backup恢复、外部带歌曲直接K歌）进入K歌拍摄页，由于不存在上一级页面，所以保留关闭按钮，但需要更改文案。
            self.hostComponent.reshootTitle = @"重新演唱";
            self.hostComponent.exitTitle = @"退出";
        }
    } else if (!state && self.buttonRemovedByMe) {
        [self addCloseButtonToHierarchy];
    }
}

#pragma mark - Properties

- (ACCRecordCloseComponent *)hostComponent
{
    return self.component;
}

@end
