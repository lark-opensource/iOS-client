//
//  ACCRecorderVideoReplyComponent.m
//  Indexer
//
//  Created by Daniel on 2021/8/20.
//

#import "ACCRecorderVideoReplyComponent.h"
#import "AWERepoStickerModel.h"
#import "ACCRecordViewControllerInputData.h"
#import "ACCRecorderStickerServiceProtocol.h"
#import "ACCVideoReplyStickerHandler.h"
#import "AWERepoDraftModel.h"
#import "ACCRecorderStickerDefines.h"

#import <CameraClientModel/ACCVideoReplyModel.h>
#import <CreationKitArch/ACCRecorderViewModel.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreativeKit/ACCTrackProtocol.h>

@interface ACCRecorderVideoReplyComponent ()
<
ACCVideoReplyStickerHandlerDelegation
>

@property (nonatomic, weak) id<ACCRecorderStickerServiceProtocol> stickerService;
@property (nonatomic, strong) ACCVideoReplyStickerHandler *videoReplyStickerHandler;
@property (nonatomic, weak) ACCRecorderViewModel *recorderViewModel;

@end

@implementation ACCRecorderVideoReplyComponent

IESAutoInject(self.serviceProvider, stickerService, ACCRecorderStickerServiceProtocol)

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.stickerService registerStickerHandler:self.videoReplyStickerHandler];
}

- (void)componentWillAppear
{
    ACCVideoReplyModel *videoReplyModel = self.repository.repoSticker.videoReplyModel;
    if (videoReplyModel != nil && !videoReplyModel.isDeleted) {
        UIView<ACCStickerProtocol> *stickerView = [self.videoReplyStickerHandler createStickerView:videoReplyModel locationModel:nil];
        stickerView.contentView.alpha = kRecorderShootSameStickerViewAlpha;
    } else {
        [self.videoReplyStickerHandler removeVideoReplyStickerView];
    }
}

#pragma mark - Getters and Setters

- (ACCVideoReplyStickerHandler *)videoReplyStickerHandler
{
    if (!_videoReplyStickerHandler) {
        _videoReplyStickerHandler = [[ACCVideoReplyStickerHandler alloc] init];
        _videoReplyStickerHandler.delegation = self;
    }
    return _videoReplyStickerHandler;
}

#pragma mark - ACCVideoReplyStickerHandlerDelegation Methods

- (NSString *)generateVideoReplyDraftPath:(NSUInteger)index
{
    NSString *taskID = self.repository.repoDraft.taskID;
    NSString *fileName = @"video_reply_video";
    {
        fileName = [NSString stringWithFormat:@"%@_%@", fileName, @(index)];
        NSString *dateTag = [self.repository.repoDraft tagForDraftFromBackEdit];
        fileName = [AWEDraftUtils generateName:fileName
                                  withDraftTag:dateTag];
        fileName = [NSString stringWithFormat:@"%@.png", fileName];
    }
    NSString *pathString = [AWEDraftUtils generatePathFromTaskId:taskID name:fileName];
    return pathString;
}

- (void)willDeleteVideoReplyStickerView
{
    self.repository.repoSticker.videoReplyModel.deleted = YES;
    
    [ACCTracker() trackEvent:@"delete_video_sticker" params:@{
        @"enter_from" : @"video_shoot_page",
    }];
}

- (nullable NSString *)getTrackEnterMethod
{
    return @"video_shoot_page";
}

@end
