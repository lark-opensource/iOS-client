//
//  ACCMomentIntelligentMovieTIMManager.m
//  CameraClient-Pods-Aweme
//
//  Created by Lemonior on 2020/11/23.
//

#import "ACCMomentIntelligentMovieTIMManager.h"
#import "ACCTemplateDetailModel.h"
#import <CreativeKit/ACCNetServiceProtocol.h>
#import <EffectSDK_iOS/bef_effect_api.h>
#import "ACCCutSameLVConstDefinitionProtocol.h"
#import "ACCLocationProtocol.h"
#import "ACCCutSameRequestExtralInfo.h"
#import <CameraClient/ACCMomentBIMResult.h>
#import "ACCMomentBIMResult+VEAIMomentMaterialInfo.h"
#import "ACCMomentMediaDataProvider.h"
#import "ACCMomentAIMomentModel.h"
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/ACCLogProtocol.h>

// 错误信息
static NSString *const ACCTOCMVDomain = @"com.toc.template.recommend.moment";

@implementation ACCMomentIntelligentMovieTIMManager

/* fetch template
 * server - doc: https://bytedance.feishu.cn/docs/doccnutD5Bez0UI4kOyBD8730ld
 */
+ (void)fetchTemplateWithMoment:(ACCMomentAIMomentModel *)moment
                      musicInfo:(ACCMusicInfo *)musicInfo
                     completion:(void (^)(ACCTemplateRecommendModel * _Nullable templatesModel,
                                          NSError * _Nullable error))completion {
    NSString *materialInfo = [self materialInfoWithMoment:moment];
    if (materialInfo.length == 0) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:ACCTOCMVDomain code:99 userInfo:nil]);
        }
        return;
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@/aweme/v1/ulike/recommend/template/detail/",
                           [ACCNetService() defaultDomain]];
    char version[10] = {0};
#if !TARGET_IPHONE_SIMULATOR
    bef_effect_get_sdk_version(version,sizeof(version));
#endif
    NSString *effectSDKVersion = [[NSString alloc] initWithUTF8String:version];
    
    NSMutableDictionary *params = @{
        @"cut_same_sdk_version" : [[IESAutoInline(ACCBaseServiceProvider(), ACCCutSameLVConstDefinitionProtocol) class] lvTemplateVersion],
        @"city_code" : [ACCLocation() currentSelectedCityCode] ?: @"",
        @"effect_sdk_version" : effectSDKVersion ?: @"",
        @"material_info_list": materialInfo ?: @"",
        @"music_info": [self musicInfoWithMusic:musicInfo] ?: @"",
        @"template_source": @(2), // 抖音
        @"origin": @"moment"
    }.mutableCopy;
   
    if ([ACCCutSameRequestExtralInfo requestExtralInfo]) {
        [params addEntriesFromDictionary:[ACCCutSameRequestExtralInfo requestExtralInfo]];
    }
    
    NSInteger fetchStart = CFAbsoluteTimeGetCurrent(); // config task endTime
    [ACCNetService() requestWithModel:^(ACCRequestModel * _Nullable requestModel) {
        requestModel.requestType = ACCRequestTypePOST;
        requestModel.urlString = urlString;
        requestModel.params = params;
        requestModel.objectClass = ACCTemplateRecommendModel.class;
    } completion:^(ACCTemplateRecommendModel * _Nullable model, NSError * _Nullable error) {
        AWELogToolInfo(AWELogToolTagMoment, @"fetch templates finish with error: %@, impr_id: %@", error, model.logPb.imprID ?: @"");
        NSInteger fetchEnd = CFAbsoluteTimeGetCurrent(); // config task endTime
        [ACCMonitor() trackService:@"toc_tim_access"
                            status: error ? 1 : 0
                             extra: @{
                                 @"impr_id": model.logPb.imprID ?: @"",
                                 @"error": error ?: @"",
                                 @"template_count": @(model.recommendTemplates.count),
                                 @"duration": @((fetchEnd - fetchStart) * 1000),
                                 @"origin": @"moment"
                             }];
        if (completion) {
            completion(model, error);
        }
    }];
}

+ (NSString * _Nullable)musicInfoWithMusic:(ACCMusicInfo *)music {
    if (music == nil) return nil;
    
    NSDictionary *musicDict = [music acc_musicInfoDict];
    if ([NSJSONSerialization isValidJSONObject:musicDict]) {
        NSError *err = nil;
        NSData *musicInfoData = [NSJSONSerialization dataWithJSONObject:musicDict options:0 error:&err];
        if (musicInfoData && !err) {
            NSString *musicInfo = [[NSString alloc] initWithData:musicInfoData encoding:NSUTF8StringEncoding];
            return musicInfo;
        }
        if (err) {
            AWELogToolError(AWELogToolTagMoment, @"change musicInfo from json to NSData error: %@", err);
        }
    }
    return nil;
}

+ (NSString * _Nullable)materialInfoWithMoment:(ACCMomentAIMomentModel *)moment {
    
    __block NSArray<ACCMomentBIMResult *> *bimResults = nil;
    if (moment == nil || moment.materialIds.count == 0) {
        return nil;
    }
    
    // get moment bimResults
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [self momentBIMResultWithMomentInfo:moment
                                 result:^(NSArray<ACCMomentBIMResult *> * _Nullable results) {
        bimResults = results;
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    // get moment materialInfo with bimResult
    NSMutableArray *tempMaterialInfo = [NSMutableArray array];
    for (ACCMomentBIMResult *bimResult in bimResults) {
        NSDictionary *materialInfo = [bimResult acc_materialInfoDict];
        [tempMaterialInfo acc_addObject:materialInfo];
    }
    NSArray *JSONArray = [tempMaterialInfo copy];
    
    if (tempMaterialInfo.count != moment.materialIds.count) {
        AWELogToolInfo(AWELogToolTagMoment, @"Attention - materials bim result lost， materials: %@", moment.materialIds);
        return nil;
    }
    
    if ([NSJSONSerialization isValidJSONObject:JSONArray]) {
        NSError *err = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:JSONArray options:0 error:&err];
        if (data && !err) {
            NSString *JSONString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            return JSONString;
        }
        if (err) {
            AWELogToolError(AWELogToolTagMoment, @"change bimResult from json to NSData error: %@", err);
        }
    }
    return nil;
}

#pragma mark - data

+ (void)momentBIMResultWithMomentInfo:(ACCMomentAIMomentModel *)momentInfo
                               result:(void(^)(NSArray<ACCMomentBIMResult *> * _Nullable results))generateCompletion {
    ACCMomentMediaDataProvider *dataProvider = [ACCMomentMediaDataProvider normalProvider];
    [dataProvider loadBIMWithLocalIdentifiers:momentInfo.materialIds
                                  resultBlock:^(NSArray<ACCMomentBIMResult *> * _Nullable results,
                                                NSError * _Nullable error) {
        if (error) {
            AWELogToolError(AWELogToolTagMoment,
                            @"load bim error: %@ for generating moment with materialIDs: %@",
                            error,
                            momentInfo.materialIds);
        }
        if (generateCompletion) {
            generateCompletion(results);
        }
    }];
}

@end
