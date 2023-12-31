//
//  ACCRepoActivityModel.m
//  Aweme
//  
//  Created by 卜旭阳 on 2021/11/1.
//

#import "ACCRepoActivityModel.h"
#import "AWERepoDraftModel.h"
#import "ACCEditActivityDataHelperProtocol.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <EffectPlatformSDK/EffectPlatform+Additions.h>

@interface ACCRepoActivityModel()

@end

@implementation ACCRepoActivityModel

@synthesize repository;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _wishModel = [[ACCNewYearWishEditModel alloc] init];
    }
    return self;
}

#pragma mark - NSCopying

- (nonnull id)copyWithZone:(nullable NSZone *)zone
{
    ACCRepoActivityModel *copiedModel = [[ACCRepoActivityModel allocWithZone:zone] init];
    copiedModel.repository = self.repository;
    copiedModel.mvModel = self.mvModel;
    copiedModel.wishModel = [self.wishModel copy];
    copiedModel.wishJsonInfo = self.wishJsonInfo;
    return copiedModel;
}

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    return @{};
}

- (NSArray<NSString *> *)uploadFramePathes
{
    AWERepoDraftModel *repoDraft = [self.repository extensionModelOfClass:AWERepoDraftModel.class];
    NSString *avatarPath = [AWEDraftUtils generatePathFromTaskId:repoDraft.taskID name:self.wishModel.originAvatarPath];

    NSMutableArray<NSString *> *frames = [[NSMutableArray alloc] init];
    if (avatarPath) {
        [frames acc_addObject:avatarPath];
    }
    return [frames copy];
}

- (BOOL)dataValid
{
    return self.wishModel.text.length > 0;
}

- (void)generateMVFromDraftVideoData:(ACCEditVideoData *)videoData
                              taskId:(NSString *)taskId
                          completion:(void(^)(ACCEditVideoData *, NSError *))completion
{
    let dataHelper = [IESAutoInline(ACCBaseServiceProvider(), ACCNewYearWishDataHelperProtocol) class];
    IESEffectModel *model = [[EffectPlatform sharedInstance] cachedEffectOfEffectId:self.wishModel.effectId];
    NSString *resourcePath = [dataHelper fetchVideoFileInFolder:model.filePath];
    BOOL isImage = !resourcePath.length || self.wishModel.images.count > 0;
    if (isImage) {
        resourcePath = [AWEDraftUtils generatePathFromTaskId:taskId name:self.wishModel.images.firstObject];
    }
    
    self.mvModel = [dataHelper generateWishMVDataWithResource:resourcePath repository:(AWEVideoPublishViewModel *)self.repository videoData:videoData isImage:isImage completion:^(BOOL success, NSError *error, ACCEditVideoData *result) {
        if (!error && result && success) {
            ACCBLOCK_INVOKE(completion, result, nil);
        } else {
            ACCBLOCK_INVOKE(completion, nil, error);
        }
    }];
    
}

@end

@implementation AWEVideoPublishViewModel(Activity)

- (ACCRepoActivityModel *)repoActivity
{
    ACCRepoActivityModel *repoActivity = [self extensionModelOfClass:ACCRepoActivityModel.class];
    return repoActivity;
}

- (ACCRepositoryRegisterInfo *)repoRegisterInfo
{
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoActivityModel.class];
    return info;
}

@end
