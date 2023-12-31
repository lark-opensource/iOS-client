//
//  ACCRecorderAudioModeViewModel.m
//  CameraClient-Pods-AwemeCore
//
//  Created by liujinze on 2021/10/21.
//

#import "ACCRecorderAudioModeViewModel.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CameraClient/ACCEditMVModel.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CameraClient/AWEEffectPlatformManager.h>
#import <CameraClient/AWEMVTemplateModel.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <CreativeKit/ACCMacros.h>
#import "ACCRepoAudioModeModel.h"
#import "AWEAudioModeDataHelper.h"
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <BDWebImage/UIImageView+BDWebImage.h>

@interface ACCRecorderAudioModeViewModel()

@property (nonatomic, strong, readwrite) ACCEditVideoData *resultVideoData;
@property (nonatomic, strong, readwrite) ACCEditMVModel *resultMVModel;
@property (nonatomic, strong, readwrite) UIImage *userAvatarImage;
@property (nonatomic, strong, readwrite) NSMutableArray<AWEStudioCaptionModel *> *resultCaptions;
@property (nonatomic, strong) IESEffectModel *audioToVideoModel;
@property (nonatomic, assign) BOOL isTemplateDownloading;

@property (nonatomic, strong) RACSubject *audioModeVCDidAppearSubject;

@end

@implementation ACCRecorderAudioModeViewModel

#pragma mark - audio Service

- (void)onCleared{
    [_audioModeVCDidAppearSubject sendCompleted];
}

- (void)send_audioModeVCDidAppearSignal{
    [self.audioModeVCDidAppearSubject sendNext:nil];
}

- (RACSignal *)audioModeVCDidAppearSignal{
    return self.audioModeVCDidAppearSubject;
}

- (RACSubject *)audioModeVCDidAppearSubject{
    if (!_audioModeVCDidAppearSubject) {
        _audioModeVCDidAppearSubject = [[RACSubject alloc] init];
    }
    return _audioModeVCDidAppearSubject;
}


#pragma mark - export video

- (void)prefetchAudioMVTemplate
{
    if (self.isTemplateDownloading) {
        return;
    }
    self.isTemplateDownloading = YES;
    [AWEEffectPlatformManager configEffectPlatform];
    @weakify(self);
    [AWEAudioModeDataHelper prefetchAudioMVTemplate:^(BOOL success, IESEffectModel *templateModel) {
        @strongify(self);
        if (success) {
            self.audioToVideoModel = templateModel;
        } else {
            self.audioToVideoModel = nil;
        }
        self.isTemplateDownloading = NO;
    }];
}

- (void)preFetchAvatarImage:(void(^)(void))completion
{
    acc_dispatch_main_async_safe(^{
        UIImage *avatarPlaceholder = ACCResourceImage(@"ic_audioavatar_placeholder");
        id<ACCUserModelProtocol> userModel = [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) currentLoginUserModel];
        if (![IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin]){
            self.userAvatarImage = avatarPlaceholder;
        } else {
            @weakify(self);
            UIImageView *webImageView = [[UIImageView alloc] init];
            [webImageView bd_setImageWithURLs:userModel.avatar300.URLList ?: @[] placeholder:nil options:BDImageRequestNotCacheToDisk transformer:nil progress:NULL completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                @strongify(self);
                if (error && self != nil && webImageView.image == nil) {
                    acc_dispatch_main_async_safe(^{
                        self.userAvatarImage = avatarPlaceholder;
                    });
                } else {
                    acc_dispatch_main_async_safe(^{
                        self.userAvatarImage = webImageView.image;
                    });
                }
                acc_dispatch_main_async_safe(^{
                    ACCBLOCK_INVOKE(completion);
                });
            }];
        }
    });
}

- (ACCEditMVModel *)generateAudioMVDataWithImages:(NSArray *)images
                                       repository:(AWEVideoPublishViewModel *)repository
                                      draftFolder:(NSString *)draftFolder
                                        videoData:(ACCEditVideoData *)videoData
                                       completion:(void(^)(ACCEditVideoData *, NSError *))completion
{
    IESEffectModel *model = self.audioToVideoModel;
    if (!model.downloaded) {
        [self prefetchAudioMVTemplate];//如果没下载好 再来一次
        NSError *templateNotReadyError = [NSError errorWithDomain:@"aweme.creative.audioMode" code:-1 userInfo:@{@"msg": @"audio mv template is not downloaded"}];
        ACCBLOCK_INVOKE(completion, nil, templateNotReadyError);
        return nil;
    }
    NSString *mvPath = model.filePath;

    ACCEditMVModel *mvModel = [[ACCEditMVModel alloc] initWithDraftFolder:draftFolder];
    CGSize resolutionSize = ACCConfigBool(kConfigBool_enable_1080p_mv_video) ? CGSizeMake(1080, 1920) : CGSizeMake(720, 1280);
    [mvModel setResolution:resolutionSize];
    [mvModel setVariableDuration:videoData.totalBGAudioDuration];
    //传入头像和图片
    NSMutableArray *resources = [[NSMutableArray alloc] init];
    [images enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        IESMMMVResource *resource = [[IESMMMVResource alloc] init];
        resource.resourceContent = obj;
        resource.resourceType = IESMMMVResourcesType_img;
        [resources btd_addObject:resource];
    }];
    @weakify(self);
    [mvModel generateMVWithPath:mvPath repository:repository userResourses:[resources copy] videoData:[videoData copy] completion:^(BOOL result, NSError *error, ACCEditVideoData *info) {
        @strongify(self);
        self.resultVideoData = info;
        self.resultMVModel = mvModel;
        repository.repoAudioMode.audioMvId = self.audioToVideoModel.effectIdentifier;
        repository.repoAudioMode.materialPaths = images;
//        暂不支持草稿迁移videoData恢复存在异常 VE字段对齐后可开启
//        if (!ACC_isEmptyArray(info.bgAudioAssets)) {
//            repository.repoAudioMode.bgaudioAssetPath = [AWEAudioModeDataHelper outputBgAudioAsset:info.bgAudioAssets.firstObject withDraftID:repository.repoDraft.taskID];
//        }
        acc_dispatch_main_async_safe(^{
            if (result && !error && info) {
                ACCBLOCK_INVOKE(completion, info, nil);
            } else {
                ACCBLOCK_INVOKE(completion, nil, error);
            }
        });
    }];
    return mvModel;
}

- (void)updateAudioCaptions:(NSMutableArray<AWEStudioCaptionModel *> *)captions
{
    self.resultCaptions = captions;
}

@end
