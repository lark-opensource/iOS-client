//
//  ACCEditorConfig.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/3/15.
//

#import "AWERepoStickerModel.h"
#import "AWERepoMusicModel.h"
#import "ACCEditorConfig.h"
#import "ACCMediaContainerView.h"
#import <CameraClient/AWERepoPublishConfigModel.h>
#import <CreativeKit/ACCMacros.h>

@interface ACCEditorConfig ()

@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, strong) ACCEditorStickerConfigAssembler *stickerConfigAssembler;

@end

@implementation ACCEditorConfig

- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    self = [super init];
    if (self) {
        _publishModel = publishModel;
        _publishModel.repoPublishConfig.isParameterizedCreation = YES;
        _stickerConfigAssembler = [[ACCEditorStickerConfigAssembler alloc] init];
        publishModel.repoSticker.stickerConfigAssembler = _stickerConfigAssembler;
        _musicConfigAssembler = [[ACCEditorMusicConfigAssembler alloc] init];
        publishModel.repoMusic.musicConfigAssembler = _musicConfigAssembler;
    }
    return self;
}

+ (instancetype)editorConfigWithPublishModelAndEnsurePublishModelIsConfiged:(AWEVideoPublishViewModel *)publishModel
{
    return [[ACCEditorConfig alloc] initWithPublishModel:publishModel];
}

- (CGRect)playerFrame
{
    ACCMediaContainerView *mediaContainerView = [[ACCMediaContainerView alloc] initWithPublishModel:self.publishModel];
    [mediaContainerView builder];
    return mediaContainerView.frame;
}

- (void)prepareOnCompletion:(void (^)(NSError * _Nullable))completionHandler
{
    __block NSError *lastError;
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_enter(group);
    [self.stickerConfigAssembler prepareOnCompletion:^(NSError * _Nullable error) {
        if (error) {
            lastError = error;
        }
        dispatch_group_leave(group);
    }];
    
    dispatch_group_enter(group);
    [self.musicConfigAssembler prepareOnCompletion:^(NSError * _Nullable error) {
        if (error) {
            lastError = error;
        }
        dispatch_group_leave(group);
    }];
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        ACCBLOCK_INVOKE(completionHandler,lastError);
    });
}

@end
