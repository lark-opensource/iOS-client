//  视频回复评论二期
//  ACCRecorderVideoReplyCommentComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by lixuan on 2021/10/8.
//

#import "ACCRecorderVideoReplyCommentComponent.h"
#import "AWERepoStickerModel.h"
#import "ACCRecordViewControllerInputData.h"
#import "ACCRecorderStickerServiceProtocol.h"
#import "ACCVideoReplyCommentStickerHandler.h"
#import "AWERepoDraftModel.h"
#import "ACCRecorderStickerDefines.h"

#import <CameraClientModel/ACCVideoReplyCommentModel.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreativeKit/ACCTrackProtocol.h>

@interface ACCRecorderVideoReplyCommentComponent ()
<
ACCVideoReplyStickerHandlerDelegation
>

@property (nonatomic, weak) id <ACCRecorderStickerServiceProtocol> stickerService;
@property (nonatomic, strong) ACCVideoReplyCommentStickerHandler *videoReplyCommentStickerHandler;

@end

@implementation ACCRecorderVideoReplyCommentComponent

IESAutoInject(self.serviceProvider, stickerService, ACCRecorderStickerServiceProtocol)

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.stickerService registerStickerHandler:self.videoReplyCommentStickerHandler];
}

- (void)componentWillAppear
{
    ACCVideoReplyCommentModel *videoReplyCommentModel = self.repository.repoSticker.videoReplyCommentModel;
    if (videoReplyCommentModel && !videoReplyCommentModel.isDeleted) {
        UIView<ACCStickerProtocol> *stickerView = [self.videoReplyCommentStickerHandler addStickerViewWithModel:videoReplyCommentModel locationModel:nil];
        stickerView.contentView.alpha = kRecorderShootSameStickerViewAlpha;
    }
    else {
        [self.videoReplyCommentStickerHandler removeVideoReplyCommentStickerView];
    }
    
}

#pragma mark - ACCVideoReplyStickerHandlerDelegation Methods

- (void)willDeleteVideoReplyStickerView
{
    self.repository.repoSticker.videoReplyCommentModel.deleted = YES;
}

#pragma mark - Getters and Setters
- (ACCVideoReplyCommentStickerHandler *)videoReplyCommentStickerHandler
{
    if (!_videoReplyCommentStickerHandler) {
        _videoReplyCommentStickerHandler = [[ACCVideoReplyCommentStickerHandler alloc] init];
        _videoReplyCommentStickerHandler.delegation = self;
    }
    
    return _videoReplyCommentStickerHandler;
}

@end
