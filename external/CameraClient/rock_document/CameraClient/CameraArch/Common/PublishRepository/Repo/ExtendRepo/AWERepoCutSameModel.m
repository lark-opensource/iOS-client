//
//  AWERepoCutSameModel.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/23.
//

#import "AWERepoCutSameModel.h"
#import <CameraClient/AWEAssetModel.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CameraClient/AWEVideoRecordOutputParameter.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoMVModel.h>
#import "AWERepoContextModel.h"

@implementation ACCMediaResource

- (id)copyWithZone:(NSZone *)zone
{
    ACCMediaResource *model = [[ACCMediaResource alloc] init];

    model.assetInfo = [self.assetInfo copy];
    model.relativePath = [self.relativePath copy];
    
    return model;
}

@end

@interface AWEVideoPublishViewModel (AWERepoCutSame) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (AWERepoCutSame)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
	ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:AWERepoCutSameModel.class];
	return info;
}

- (AWERepoCutSameModel *)repoCutSame
{
    AWERepoCutSameModel *cutSameModel = [self extensionModelOfClass:AWERepoCutSameModel.class];
    NSAssert(cutSameModel, @"extension model should not be nil");
    return cutSameModel;
}

@end

@implementation AWERepoCutSameModel

- (BOOL)isCutSame {
    AWERepoContextModel *baseInfo = [self.repository extensionModelOfClass:AWERepoContextModel.class];
    BOOL isCutSame = baseInfo.videoType == AWEVideoTypeMV && self.accTemplateType == ACCMVTemplateTypeCutSame;
    return isCutSame;
}

- (BOOL)canTransferToCutSame {
    AWERepoContextModel *baseInfo = [self.repository extensionModelOfClass:AWERepoContextModel.class];
    return baseInfo.videoType == AWEVideoTypePhotoToVideo ||
           (baseInfo.videoType == AWEVideoTypeNormal && baseInfo.videoSource != AWEVideoSourceCapture);
}

- (BOOL)isSmartFilming
{
    AWERepoContextModel *contextModel = [self.repository extensionModelOfClass:AWERepoContextModel.class];
    BOOL isSmartFilming = contextModel.videoType == AWEVideoTypeOneClickFilming ||
                          contextModel.videoType == AWEVideoTypeMoments ||
                          contextModel.videoType == AWEVideoTypeSmartMV;
    return isSmartFilming;
}

- (BOOL)isNewCutSameOrSmartFilming
{
    return self.isNLECutSame || [self isSmartFilming];
}

- (CGFloat)originRatio
{
    return [LVCutSameConsumer getRatio:self.dataManager.draft];
}

- (NSValue *)preferVideoSize
{
    CGFloat originRatio = self.originRatio;
    if (originRatio > 9.f / 16.f) {
        CGSize maxSize = [AWEVideoRecordOutputParameter currentMaxExportSize];
        CGFloat width = maxSize.width;
        CGFloat height = width / originRatio;
        return [NSValue valueWithCGSize:CGSizeMake(width, height)];
    }

    return nil;
}

- (NSDictionary *)smartVideoAdditonParamsForTrack
{
    AWERepoContextModel *contextModel = [self.repository extensionModelOfClass:AWERepoContextModel.class];
    ACCRepoMusicModel *musicModel = [self.repository extensionModelOfClass:ACCRepoMusicModel.class];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (contextModel.videoType == AWEVideoTypeSmartMV) {
        params[@"single_song_music_id"] = self.originSmartMVMusicID ?: @"";
        params[@"music_id"] = musicModel.music.musicID ?: @"";
    }
    
    if (contextModel.videoType == AWEVideoTypeOneClickFilming) {
        params[@"mv_request_id"] = self.oneClickFilmingImprID ?: @"";
    }
    return [params copy];
}

- (NSDictionary *)smartVideoAdditionParamsForPublishTrack
{
    AWERepoContextModel *contextModel = [self.repository extensionModelOfClass:AWERepoContextModel.class];
    ACCRepoMVModel *mvModel = [self.repository extensionModelOfClass:ACCRepoMVModel.class];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"mv_id"] = mvModel.templateModelId ?: @"";
    params[@"content_type"] = [self p_contentTypeForSmartVideoWithType:contextModel.videoType];
    [params addEntriesFromDictionary:[self smartVideoAdditonParamsForTrack]];
    return [params copy];
}

- (NSString *)p_contentTypeForSmartVideoWithType:(AWEVideoType)videoType
{
    if (self.isNLECutSame) {
        return @"jianying_mv";
    }
    
    switch (videoType) {
        case AWEVideoTypeMoments:
            return @"moment";
            break;
        case AWEVideoTypeSmartMV:
            return @"smart_mv";
            break;
        case AWEVideoTypeOneClickFilming:
            return @"ai_upload";
            break;
            
        default:
            break;
    }
    
    return @"";
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AWERepoCutSameModel *model = [super copyWithZone:zone];

    model.cutSameChallengeIDs = self.cutSameChallengeIDs;
    model.cutSameChallengeNames = self.cutSameChallengeNames;
    model.templateSource = self.templateSource;
    // cut same link optimization
    model.cutSameNLEModel = [self.cutSameNLEModel deepClone];
    model.isNLECutSame = self.isNLECutSame;
    
    model.dataManager = self.dataManager;
    model.templatesArray = self.templatesArray;
    model.currentTemplateAssets = self.currentTemplateAssets;
    model.sourceMedia = self.sourceMedia;
    model.currentSelectIndex = self.currentSelectIndex;
    model.cutsameOriginVoiceVolume = self.cutsameOriginVoiceVolume;
    model.originSmartMVMusicID = self.originSmartMVMusicID;
    model.oneClickFilmingImprID = self.oneClickFilmingImprID;
    return model;
}

@end
