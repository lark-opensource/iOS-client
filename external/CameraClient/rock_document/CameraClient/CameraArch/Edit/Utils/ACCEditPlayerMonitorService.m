//
//  ACCEditPlayerMonitorService.m
//  CameraClient
//
//  Created by haoyipeng on 2020/9/11.
//

#import "ACCEditPlayerMonitorService.h"
#import <AVFoundation/AVFoundation.h>
#import <CreativeKit/ACCMacros.h>
#import <KVOController/KVOController.h>
#import <libextobjc/EXTKeyPathCoding.h>

#import <CameraClient/ACCVideoInspectorProtocol.h>

@interface ACCEditPlayerMonitorService () <ACCEditBuildListener>

@property (nonatomic, weak) VEEditorSession *player;

@end

@implementation ACCEditPlayerMonitorService

- (void)setEditSessionProvider:(id<ACCEditSessionProvider>)editSessionProvider
{
    [editSessionProvider addEditSessionListener:self];
}

- (void)onEditSessionInit:(ACCEditSessionWrapper *)editSession
{
    self.player = editSession.videoEditSession;
}

- (void)inspectAssetIfNeeded
{
    if (!self.player.mixPlayer) {
        return;
    }
    @weakify(self);
    AVPlayerItem *item = self.player.mixPlayer.currentItem;
    void(^inspectPlayerItem)(AVPlayerItem *) = ^(AVPlayerItem *playerItem) {
        IESVideoDetectInputModel *input = [[IESVideoDetectInputModel alloc] init];
        input.asset = playerItem.asset;
        input.videoComposition = playerItem.videoComposition;
        input.extraLog = @{@"scene": @"edit"};
        [ACCVideoInspector() inspectVideo:input];
    };
    ACCBLOCK_INVOKE(inspectPlayerItem, item);
    [self.player.mixPlayer.KVOController observe:self.player.mixPlayer.currentItem
                                         keyPath:@ keypath(self.player.mixPlayer.currentItem, status)
                                         options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew block:^(id  _Nullable observer, AVPlayerItem  *object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        if ([change[NSKeyValueChangeOldKey] integerValue] == AVPlayerItemStatusUnknown && object.status == AVPlayerItemStatusReadyToPlay) {
            ACCBLOCK_INVOKE(inspectPlayerItem, object);
        }
        [self.player.mixPlayer.KVOController unobserve:object keyPath:@"status"];
    }];
}

@end
