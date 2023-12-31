//
//  AWERepoMVModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/22.
//

#import "AWERepoMVModel.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/ACCRepoVideoInfoModel.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "ACCRepoBirthdayModel.h"

// dependency
#import <CreationKitArch/ACCRepoContextModel.h>
#import "AWERepoCutSameModel.h"

#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

// 业务的剪同款模板空间：https://bytedance.feishu.cn/docs/doccnHbnIz2Kxnt9Xw3Kt9dxgBd
typedef NS_ENUM(NSUInteger, ACCCutSameTemplateSource) {
    ACCCutSameTemplateSourceDouyin = 0,      // 同步到抖音空间的模板
    ACCCutSameTemplateSourceJianying = 1,    // 未同步到抖音的模板，剪映侧全量模板
    ACCCutSameTemplateSourceIronMan = 4,     // 小程序
    ACCCutSameTemplateSourceSpiderMan = 5,   // 小游戏
};

// 投稿时业务标识：https://bytedance.feishu.cn/docs/doccnHbnIz2Kxnt9Xw3Kt9dxgBd
typedef NS_ENUM(NSUInteger, ACCMVType) {
    ACCMVTypeForClassicalMV = 0,        // 经典影集
    ACCMVTypeForDouyinCutsame = 1,      // 同步到抖音空间的模板
    ACCMVTypeForOneClickFilming = 2,    // 一键成片
    ACCMVTypeForSmartMV = 3,            // 音乐一键MV
    ACCMVTypeForIronMan = 4,            // 小程序
    ACCMVTypeForSpiderMan = 5,          // 小游戏
};

@implementation ACCMVServerMaterialInfo

+ (NSArray *)mergeServerMaterialInfo:(NSArray<ACCMVServerMaterialInfo *> *)sourceArray
{
    if (sourceArray.count != 2) {
        return sourceArray;
    }

    NSMutableArray *resultArray = @[].mutableCopy;

    if (sourceArray[0].algorithmResultType == VEMVAlgorithmResultInType_Json &&
        sourceArray[1].algorithmResultType != VEMVAlgorithmResultInType_Json &&
        ACC_isEmptyString(sourceArray[1].algorithmJson)) {
        sourceArray[1].algorithmJson = sourceArray[0].algorithmJson;
        [resultArray addObject:sourceArray[1]];
    }

    if (sourceArray[1].algorithmResultType == VEMVAlgorithmResultInType_Json &&
        sourceArray[0].algorithmResultType != VEMVAlgorithmResultInType_Json &&
        ACC_isEmptyString(sourceArray[0].algorithmJson)) {
        sourceArray[0].algorithmJson = sourceArray[1].algorithmJson;
        [resultArray addObject:sourceArray[0]];
    }

    return resultArray.count > 0 ? resultArray : sourceArray;
}

+ (NSArray<NSString *> *)generateLocalAlgorithmMaterial:(NSArray<ACCMVServerMaterialInfo *> *)sourceArray
{
    NSMutableArray<NSString *> *result = [NSMutableArray array];
    for (ACCMVServerMaterialInfo *item in sourceArray) {
        [result acc_addObject:item.resultMaterialPath];
    }
    return result;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.algorithmName forKey:@"algorithmName"];
    [coder encodeObject:self.nativeMaterialPath forKey:@"nativeMaterialPath"];
    [coder encodeObject:self.algorithmJson forKey:@"algorithmJson"];
    [coder encodeObject:self.resultMaterialPath forKey:@"resultMaterialPath"];
    [coder encodeInteger:self.algorithmResultType forKey:@"algorithmResultType"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        _algorithmName = [coder decodeObjectForKey:@"algorithmName"];
        _nativeMaterialPath = [coder decodeObjectForKey:@"nativeMaterialPath"];
        _algorithmJson = [coder decodeObjectForKey:@"algorithmJson"];
        _resultMaterialPath = [coder decodeObjectForKey:@"resultMaterialPath"];
        _algorithmResultType = [coder decodeIntegerForKey:@"algorithmResultType"];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    ACCMVServerMaterialInfo *model = [[ACCMVServerMaterialInfo alloc] init];
    model.algorithmName = self.algorithmName;
    model.nativeMaterialPath = self.nativeMaterialPath.copy;
    model.algorithmJson = self.algorithmJson.copy;
    model.resultMaterialPath = self.resultMaterialPath;
    model.algorithmResultType = self.algorithmResultType;
    return model;
}

@end


@interface AWEVideoPublishViewModel (AWERepoMV) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (AWERepoMV)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
	ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:AWERepoMVModel.class];
	return info;
}

- (AWERepoMVModel *)repoMV
{
    AWERepoMVModel *mvModel = [self extensionModelOfClass:AWERepoMVModel.class];
    NSAssert(mvModel, @"extension model should not be nil");
    return mvModel;
}

@end

@interface AWERepoMVModel()<ACCRepositoryRequestParamsProtocol>

@end

@implementation AWERepoMVModel
@synthesize mvChallengeName = _mvChallengeName;

- (id)copyWithZone:(NSZone *)zone
{
    AWERepoMVModel *model = [super copyWithZone:zone];
    model.mvModel = self.mvModel;   // mv 和 status共用
    model.serverMaterials = self.serverMaterials.copy;
    model.mvChallengeNameArray = self.mvChallengeNameArray;
    model.mvID = self.mvID;
    model.templateMaterialsString = self.templateMaterialsString;
    model.mvTemplateCategoryID = self.mvTemplateCategoryID;
    model.oneKeyMVEnterfrom = self.oneKeyMVEnterfrom;
    model.previousPage = self.previousPage;
    return model;
}

- (void)setMvChallengeName:(NSString *)mvChallengeName
{
    _mvChallengeName = [mvChallengeName copy];
    if (_mvChallengeName.length > 0 && [_mvChallengeNameArray containsObject:self.mvChallengeName] == NO) {
        // 影集多话题，兼容老草稿
        NSMutableArray *mergeArray = [_mvChallengeNameArray mutableCopy] ?: [NSMutableArray array];
        [mergeArray addObject:self.mvChallengeName];
        _mvChallengeNameArray = [mergeArray copy];
    }
}

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel {
    
    NSMutableDictionary *params = @{
        @"slideshow_mv_id" : self.slideshowMVID ?: [NSNull null],
    }.mutableCopy;
    
    NSMutableDictionary *miscInfoDict = [NSMutableDictionary dictionary];
    ACCRepoContextModel *contextModel = [self.repository extensionModelOfClass:ACCRepoContextModel.class];
    AWERepoCutSameModel *cutSameModel = [self.repository extensionModelOfClass:AWERepoCutSameModel.class];
    ACCRepoBirthdayModel *birthdayModel = [self.repository extensionModelOfClass:ACCRepoBirthdayModel.class];
    // 主题mv模板id参数
    if (contextModel.videoType != AWEVideoTypeMoments && (self.templateModelId)) {
        if (contextModel.videoType == AWEVideoTypeOneClickFilming) {
            NSDictionary *mvIdDict = [NSDictionary dictionaryWithObject:self.templateModelId ?: @"" forKey:@"mv_id"];
            [miscInfoDict btd_setObject:@(ACCMVTypeForOneClickFilming) forKey:@"mv_type"];
            [miscInfoDict addEntriesFromDictionary:mvIdDict];
        } else if (contextModel.videoType == AWEVideoTypeSmartMV)  {
            NSDictionary *mvIdDict = [NSDictionary dictionaryWithObject:self.templateModelId ?: @"" forKey:@"mv_id"];
            [miscInfoDict btd_setObject:@(ACCMVTypeForSmartMV) forKey:@"mv_type"];
            [miscInfoDict addEntriesFromDictionary:mvIdDict];
        } else if (!birthdayModel.isBirthdayPost && !birthdayModel.isIMBirthdayPost) { // 生日祝福不能显示模版锚点
            NSDictionary *mvIdDict = [NSDictionary dictionaryWithObject:self.templateModelId ?: @"" forKey:@"mv_id"];
            if (cutSameModel.accTemplateType == ACCMVTemplateTypeCutSame) {
                NSInteger mvType = [publishViewModel.repoTrack.enterShootPageExtra acc_intValueForKey:@"mv_type"] ?: 1;
                // mvType为影集或抖音剪同款需要再细化类型
                if (mvType == ACCMVTypeForClassicalMV ||
                    mvType == ACCMVTypeForDouyinCutsame) {
                    mvType = [self getMVTypeFromTemplateSource:cutSameModel.templateSource];
                }
                [miscInfoDict btd_setObject:@(mvType) forKey:@"mv_type"];
            }
            [miscInfoDict addEntriesFromDictionary:mvIdDict];
        }
    }

    if (miscInfoDict.count > 0) {
        NSError *error = nil;
        NSData *miscInfoData = [NSJSONSerialization dataWithJSONObject:miscInfoDict options:0 error:&error];
        if (error) {
            AWELogToolError(AWELogToolTagPublish, @"%s %@", __PRETTY_FUNCTION__, error);
        }
        if (miscInfoData && !error) {
            NSString *miscInfoStr = [[NSString alloc] initWithData:miscInfoData encoding:NSUTF8StringEncoding];
            if (miscInfoStr) {
                params[@"misc_info"] = miscInfoStr;
            }
        }
    }
    return params;
}

- (ACCMVType)getMVTypeFromTemplateSource:(ACCCutSameTemplateSource)templateSource {
    ACCMVType mvType = ACCMVTypeForDouyinCutsame;
    switch (templateSource) {
        case ACCCutSameTemplateSourceDouyin:
            mvType = ACCMVTypeForDouyinCutsame;
            break;
        case ACCCutSameTemplateSourceIronMan:
            mvType = ACCMVTypeForIronMan;
            break;
        case ACCCutSameTemplateSourceSpiderMan:
            mvType = ACCMVTypeForSpiderMan;
            break;
        default:
            break;
    }
    return mvType;
}

- (NSDictionary *)acc_referExtraParams
{
    // 一键成片
    NSMutableDictionary *params = @{}.mutableCopy;
    ACCRepoContextModel *contextModel = [self.repository extensionModelOfClass:ACCRepoContextModel.class];
    
    if (contextModel.videoType == AWEVideoTypeOneClickFilming) {
        params[@"ai_upload_entrance"] = self.oneKeyMVEnterfrom;
    }
    
    return params;
}

@end
