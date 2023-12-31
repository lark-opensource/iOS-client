//
//  AWERecordInformationRepoModel.m
//  CameraClient-Pods-Aweme
//
//  Created by 马超 on 2021/4/23.
//

#import "AWERecordInformationRepoModel.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreationKitInfra/NSData+ACCAdditions.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitArch/AWEColorFilterDataManager.h>
#import <CreationKitArch/ACCRepoStickerModel.h>
#import "AWEMVTemplateModel.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import "AWERepoCutSameModel.h"
#import "AWEVideoFragmentInfo.h"
#import <CreationKitArch/ACCRepoMVModel.h>
#import <CreationKitArch/ACCRepoChallengeModel.h>
#import "ACCRepoMissionModelProtocol.h"
#import <CreationKitArch/ACCRepoMusicModel.h>
#import "AWERepoContextModel.h"
#import <CreationKitArch/ACCRepoDraftModel.h>
#import "AWERepoVideoInfoModel.h"
#import <CreationKitArch/AWEDraftUtils.h>

@interface AWERecordInformationRepoModel ()

@property (nonatomic, copy) NSArray<AWEVideoFragmentInfo *> *recordFragmentInfo;

@end


@interface AWEVideoPublishViewModel (AWERepoRecordInformation) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (AWERepoRecordInformation)

#pragma mark - ACCRepositoryElementRegisterCategoryProtocol

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:AWERecordInformationRepoModel.class];
    return info;
}

- (AWERecordInformationRepoModel *)repoRecordInfo
{
    AWERecordInformationRepoModel *recordInfoModel = [self extensionModelOfClass:AWERecordInformationRepoModel.class];
    NSAssert(recordInfoModel, @"extension model should not be nil");
    return recordInfoModel;
}

- (nullable NSString *)effectTrackStringWithFilter:(BOOL(^ _Nullable)(ACCEffectTrackParams *param))filter
{
    return [AWEVideoFragmentInfo effectTrackStringWithFragmentInfos:self.repoVideoInfo.fragmentInfo filter:filter];
}

@end

@implementation AWERecordInformationRepoModel

- (BOOL)shouldForbidCommerce
{
    return [self shouldForbidCommerce:nil];
}

- (BOOL)shouldForbidCommerce:(NSMutableArray *)log
{
    __block BOOL isCommerceProp = NO;
    [self.fragmentInfo enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isCommerce) {
            for (AWEVideoPublishChallengeInfo *challenge in obj.challengeInfos) {
                if (challenge.challengeId.length > 0) {
                    isCommerceProp = YES;
                    *stop = YES;
                }
            }
        }
    }];
    
    ACCRepoMVModel *mvModel = [self.repository extensionModelOfClass:ACCRepoMVModel.class];
    NSString *effectIdentifier = mvModel.templateModelId;
    NSArray<IESEffectModel *> *mvModels = [NSArray arrayWithArray:[AWEMVTemplateModel sharedManager].templateModels];
    BOOL hasCommerceMV = NO;
    for (IESEffectModel *mvModel in mvModels) {
        if ([effectIdentifier isEqualToString:mvModel.effectIdentifier] && mvModel.isCommerce) {
            hasCommerceMV = YES;
            break;
        }
    }
    
    BOOL hasMvCommerceChallenge = NO;
    NSArray *challengeArray =[[AWEMVTemplateModel sharedManager].mvChallengeArrayDict acc_arrayValueForKey:mvModel.templateModelId];
    if ([challengeArray acc_filter:^BOOL(id<ACCChallengeModelProtocol>  _Nonnull item) {return item.isCommerce;}].count > 0) {
        hasMvCommerceChallenge = YES;
    }
    
    id<ACCRepoMissionModelProtocol> missionModel = [self.repository extensionModelOfProtocol:@protocol(ACCRepoMissionModelProtocol)];
    ACCRepoChallengeModel *challengeModel = [self.repository extensionModelOfClass:ACCRepoChallengeModel.class];
    ACCRepoMusicModel *musicModel = [self.repository extensionModelOfClass:ACCRepoMusicModel.class];
    AWERepoCutSameModel *cutSameModel = [self.repository extensionModelOfClass:AWERepoCutSameModel.class];

    if (log) {
        [log addObject:[NSString stringWithFormat:@"hasCommerceProp %d", isCommerceProp]];
        [log addObject:[NSString stringWithFormat:@"hasCommerceMV %d", hasCommerceMV && mvModel.mvChallengeName.length > 0]];
        [log addObject:[NSString stringWithFormat:@"challenge (isCommerce %d || hasTask %d)", challengeModel.challenge.isCommerce, challengeModel.challenge.task != nil]];
        [log addObject:[NSString stringWithFormat:@"hasMission %d", [missionModel acc_mission] != nil || [missionModel acc_missionID].length > 0]];
        [log addObject:[NSString stringWithFormat:@"music.isCommerce %d", musicModel.music.challenge.isCommerce]];
        [log addObject:[NSString stringWithFormat:@"cutSameChallengeIDs %d", [cutSameModel cutSameChallengeIDs].count > 0]];
    }

    if (challengeModel.challenge.isCommerce
        || !ACC_isEmptyString(challengeModel.challenge.task.ID)
        || [missionModel acc_mission] != nil
        || musicModel.music.challenge.isCommerce
        || isCommerceProp
        || (mvModel.mvChallengeName.length > 0 && hasCommerceMV)
        || hasMvCommerceChallenge
        || [missionModel acc_missionID].length > 0
        || [cutSameModel cutSameChallengeIDs].count > 0
        || self.isCommerceDataInToolsLine) {
        return YES;
    }
    return NO;
}

//商业化道具、影集和剪同款在编辑页不出话题贴纸判断条件
- (BOOL)isCommerceStickerOrMV
{
    //道具
    __block BOOL isCommerceProp = NO;
    [self.fragmentInfo enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isCommerce) {
            for (AWEVideoPublishChallengeInfo *challenge in obj.challengeInfos) {
                if (challenge.challengeId.length > 0) {
                    isCommerceProp = YES;
                    *stop = YES;
                }
            }
        }
    }];
    //影集
    ACCRepoMVModel *mvModel = [self.repository extensionModelOfClass:ACCRepoMVModel.class];
    NSString *effectIdentifier = mvModel.templateModelId;
    //剪同款
    AWERepoCutSameModel *cutSameModel = [self.repository extensionModelOfClass:AWERepoCutSameModel.class];
    id<ACCRepoMissionModelProtocol> missionModel = [self.repository extensionModelOfProtocol:@protocol(ACCRepoMissionModelProtocol)];
    ACCRepoChallengeModel *challengeModel = [self.repository extensionModelOfClass:ACCRepoChallengeModel.class];
    //是否为商业化任务
    BOOL isCommerceTask = !ACC_isEmptyString(challengeModel.challenge.task.ID) || [missionModel acc_mission] != nil;
    //是否为影集或剪同款
    BOOL isMVOrCutSame = !ACC_isEmptyString(effectIdentifier) || [cutSameModel cutSameChallengeIDs].count > 0;
    return isCommerceProp || (isCommerceTask && isMVOrCutSame);
}

- (NSArray *)originalFrameNamesArray
{
    __block NSMutableArray *frames = [NSMutableArray array];
    [self.fragmentInfo enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.originalFramesArray) {
            [frames addObjectsFromArray:obj.originalFramesArray];
        }
    }];
    
    return [frames copy];
}

- (BOOL)hasStickers
{
    AWERepoContextModel *contextModel = [self.repository extensionModelOfClass:AWERepoContextModel.class];
    if (!contextModel.isRecord) {
        return NO;
    }
    
    __block BOOL flag = NO;
    [self.fragmentInfo enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.uploadStickerUsed ||
            !ACC_isEmptyString(obj.stickerId) ||
            !ACC_isEmptyArray(obj.stickerImageAssetPaths) ||
            !ACC_isEmptyString(obj.stickerVideoAssetURL.path)) {
            flag = YES;
            *stop = YES;
        }
    }];
    
    return flag;
}

#pragma mark - Compatible

- (void)updateFragmentInfo:(NSArray<AWEVideoFragmentInfo *> *)fragmentInfo
{
    // 兼容草稿迁移 & 老草稿 fragmentInfo在 ACCRecordInformationRepoModel 下的情况
    self.recordFragmentInfo = fragmentInfo;
}

- (void)updateVideoFragmentInfo
{
    // 兼容草稿迁移 & 老草稿 fragmentInfo在 ACCRecordInformationRepoModel 下的情况
    ACCRepoVideoInfoModel *repoVideo = [self.repository extensionModelOfClass:ACCRepoVideoInfoModel.class];
    if (ACC_isEmptyArray(repoVideo.fragmentInfo) && !ACC_isEmptyArray(self.recordFragmentInfo)) {
        [repoVideo.fragmentInfo addObjectsFromArray:self.recordFragmentInfo];
    }
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    AWERecordInformationRepoModel *copy = [super copyWithZone:zone];
    copy.pictureToVideoInfo = [self.pictureToVideoInfo copy];
    copy.isCommerceDataInToolsLine = self.isCommerceDataInToolsLine;
    return copy;
}

#pragma mark - Private

- (NSString *)generateThumbnailsFloader
{
    ACCRepoDraftModel *draftModel = [self.repository extensionModelOfClass:[ACCRepoDraftModel class]];
    NSString *draftRootPath = [AWEDraftUtils generateDraftFolderFromTaskId:draftModel.taskID];
    NSString *draftFolder = [draftRootPath stringByAppendingPathComponent:@"extract_shot/migrate"];
    BOOL isDirectory;
    if ([[NSFileManager defaultManager] fileExistsAtPath:draftFolder isDirectory:&isDirectory]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:draftFolder error:&error];
        if (error != nil) {
            AWELogToolError2(@"migrate", AWELogToolTagDraft, @"Remove Thumbnail Folder Error:%@", error);
        }
    }
    NSError *createDirectoryError;
    [[NSFileManager defaultManager] createDirectoryAtPath:draftFolder
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&createDirectoryError];
    if (createDirectoryError != nil) {
        AWELogToolError2(@"migrate", AWELogToolTagDraft, @"Create Thumbnail Folder Error:%@", createDirectoryError);
        return draftRootPath;
    } else {
        return draftFolder;
    }
}

- (NSString *)saveImage:(UIImage *)image index:(NSInteger)index draftFolder:(NSString *)draftFolder
{
    NSString *name = [NSString stringWithFormat:@"draft_generate_thumb_%ld.jpeg", (long)index];
    
    NSString *imagePath = [draftFolder stringByAppendingPathComponent:name];
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);;
    if (imagePath && imageData && [imageData acc_writeToFile:imagePath atomically:YES]) {
        if ([draftFolder hasSuffix:@"extract_shot/migrate"]) {
            return [NSString stringWithFormat:@"extract_shot/migrate/%@", name];
        } else {
            return name;
        }
    }
    return nil;
}

#pragma mark - Getter
- (NSDictionary *)beautifyTrackInfoDic
{
    __block NSMutableArray *composerBeautifyInfoStringArray = [NSMutableArray array];
    __block NSMutableArray *beautifyUsedArray = [NSMutableArray array];
    __block NSUInteger isComposer = 0;
    [self.fragmentInfo enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.composerBeautifyInfo) {
            isComposer = 1;
            [composerBeautifyInfoStringArray addObject:obj.composerBeautifyInfo];
            [beautifyUsedArray addObject:obj.composerBeautifyUsed ? @(1) : @(0)];
        } else {
            [beautifyUsedArray addObject:obj.beautifyUsed ? @(1) : @(0)];
        }
    }];
    
     //超短视频补充上报美颜信息
     if(ACC_isEmptyArray(self.fragmentInfo) && self.pictureToVideoInfo) {
         if (self.pictureToVideoInfo.composerBeautifyInfo) {
             isComposer = 1;
             [composerBeautifyInfoStringArray addObject:self.pictureToVideoInfo.composerBeautifyInfo];
             [beautifyUsedArray addObject:self.pictureToVideoInfo.composerBeautifyUsed ? @(1) : @(0)];
         } else {
             [beautifyUsedArray addObject:self.pictureToVideoInfo.beautifyUsed ? @(1) : @(0)];
         }
     }
    
    return @{@"is_composer"   : @(isComposer),
             @"beautify_used" : beautifyUsedArray,
             @"beautify_info" : composerBeautifyInfoStringArray,
            };
}

- (NSMutableArray<__kindof id<ACCVideoFragmentInfoProtocol>> *)fragmentInfo
{
    ACCRepoVideoInfoModel *repoVideo = [self.repository extensionModelOfClass:ACCRepoVideoInfoModel.class];
    AWERepoContextModel *repoContext = [self.repository extensionModelOfClass:AWERepoContextModel.class];
    
    [self updateVideoFragmentInfo];
    
    if (repoContext.isRecord) {
        return repoVideo.fragmentInfo;
    }
    
    return [NSMutableArray array];
}

@end
