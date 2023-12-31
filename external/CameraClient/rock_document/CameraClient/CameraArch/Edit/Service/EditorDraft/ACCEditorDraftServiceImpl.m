//
//  ACCEditorDraftServiceImpl.m
//  CameraClient
//
//  Created by chengfei xiao on 2020/5/18.
//

#import "ACCEditorDraftServiceImpl.h"
#import <CreationKitArch/ACCEditAndPublishConstants.h>
#import <CreationKitArch/ACCRepoPropModel.h>
#import <CameraClient/AWERepoDraftModel.h>
#import <CreationKitArch/ACCRepoFlowControlModel.h>
#import <CameraClient/ACCDraftProtocol.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import "AWERepoVideoInfoModel.h"
#import <CreationKitArch/ACCStudioDefines.h>
#import <CreativeKit/ACCMacros.h>

@interface ACCEditorDraftServiceImpl()
@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;
@end


@implementation ACCEditorDraftServiceImpl

- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    self = [super init];
    if (self) {
        _publishModel = publishModel;
    }
    return self;
}

- (void)saveDraftIfNecessary
{
    if (self.publishModel.repoDraft.originalModel) { // 从草稿/备份恢复后设置草稿缓存路径
        [ACCDraft() setCacheDirPathWithID:self.publishModel.repoDraft.taskID];
    }
    
    if (self.publishModel.repoFlowControl.step < AWEPublishFlowStepEdit) {
        self.publishModel.repoFlowControl.step = AWEPublishFlowStepEdit;
        [ACCDraft() saveDraftWithPublishViewModel:self.publishModel
                                            video:self.publishModel.repoVideoInfo.video
                                           backup:!self.publishModel.repoDraft.originalDraft
                                       completion:^(BOOL success, NSError *error) {}];
    }
}

- (void)removePublishFailedDraft
{
    if (!self.publishModel.repoDraft.isDraft) {
        return;
    }
    
    // 上传失败草稿被编辑过之后，取消上传重试
    NSString *failedDraftId = [ACCCache() objectForKey:kAWEStudioPublishRetryDraftIDKey];
    if ([failedDraftId isEqualToString:self.publishModel.repoDraft.taskID]) {
        [ACCCache() removeObjectForKey:kAWEStudioPublishRetryDraftIDKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:kACCPublishFailedDraftDeleteNotification object:nil];
    }
}

- (void)hadBeenModified
{
    if (self.publishModel.repoFlowControl.step > AWEPublishFlowStepEdit && !(self.publishModel.repoDraft.isDraft ||self.publishModel.repoDraft.isBackUp)) {//从发布页回来重新编辑
        self.publishModel.repoFlowControl.step = AWEPublishFlowStepEdit;//这样进入发布页就会保存草稿
    }
}

- (void)saveDraftEnterNextVC
{
    @weakify(self);
    [ACCDraft() saveDraftWithPublishViewModel:self.publishModel  video:self.publishModel.repoVideoInfo.video backup:!self.publishModel.repoDraft.originalDraft completion:^(BOOL success, NSError *error) {
        @strongify(self);
        if (success) {
            /** 那种吊起编辑页的草稿，改动后保存，再点返回取消编辑，
             草稿箱不会reload，导致数据不同步，这里同步一次 */
            [[NSNotificationCenter defaultCenter] postNotificationName:kACCAwemeDraftUpdateNotification
                                                                object:nil userInfo:@{[ACCDraft() draftIDKey]: self.publishModel.repoDraft.taskID?:@""}];
        }
    }];
}

@end
