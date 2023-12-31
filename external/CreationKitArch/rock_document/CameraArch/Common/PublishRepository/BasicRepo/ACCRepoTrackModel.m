//
//  ACCRepoTrackModel.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/14.
//

#import "ACCRepoFlowControlModel.h"
#import <CreationKitArch/ACCRepoContextModel.h>
#import "ACCRepoTrackModel.h"
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import "ACCRepoPropModel.h"
#import "ACCRepoReshootModel.h"
#import "ACCRepoVideoInfoModel.h"
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import "ACCRepoFlowControlModel.h"

@interface AWEVideoPublishViewModel (RepoTrack) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoTrack)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo
{
    return [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoTrackModel.class];
}

- (ACCRepoTrackModel *)repoTrack
{
    ACCRepoTrackModel *trackModel = [self extensionModelOfClass:ACCRepoTrackModel.class];
    NSAssert(trackModel, @"extension model should not be nil");
    return trackModel;
}

@end

@implementation ACCRepoTrackModel
@synthesize repository;


#pragma mark - public

- (NSDictionary *)commonTrackInfoDic
{
    NSMutableDictionary *dic = @{}.mutableCopy;
    dic[@"shoot_way"] = self.referString;
    ACCRepoContextModel *context = [self.repository extensionModelOfClass:ACCRepoContextModel.class];
    dic[@"creation_id"] = context.createId;
    return [dic copy];
}

- (NSDictionary *)videoFragmentInfoDictionary
{
    NSAssert(NO, @"should implementation in sub class");
    return @{};
}

- (void)trackPostEvent:(NSString *)event enterMethod:(NSString *)enterMethod
{
    [self trackPostEvent:event enterMethod:enterMethod extraInfo:nil];
}

- (void)trackPostEvent:(NSString *)event enterMethod:(NSString *)enterMethod extraInfo:(NSDictionary *)extraInfo
{
    [self trackPostEvent:event enterMethod:enterMethod extraInfo:extraInfo isForceSend:NO];
}

- (void)trackPostEvent:(NSString *)event
           enterMethod:(NSString *)enterMethod
             extraInfo:(NSDictionary *)extraInfo
           isForceSend:(BOOL)isForceSend
{
    NSAssert(NO, @"should implementation in sub class");
}

- (NSDictionary *)referExtra
{
    NSMutableDictionary *extra = @{}.mutableCopy;
    
    [self.repository.extensionModels enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (![obj respondsToSelector:@selector(acc_referExtraParams)]) {
            return;
        }
        NSDictionary *extensionParams = [obj acc_referExtraParams];
        [extensionParams enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull paramsKey, id  _Nonnull paramValue, BOOL * _Nonnull stop) {
            if (![paramValue isKindOfClass:[NSNull class]]) {
                extra[paramsKey] = paramValue;
            }
        }];
    }];
    return extra;
}

- (NSDictionary *)mediaCountInfo
{
    ACCRepoContextModel *contextModel = [self.repository extensionModelOfClass:ACCRepoContextModel.class];
    ACCRepoUploadInfomationModel *uploadModel = [self.repository extensionModelOfClass:ACCRepoUploadInfomationModel.class];
    ACCRepoVideoInfoModel *recordInfoModel = [self.repository extensionModelOfClass:ACCRepoVideoInfoModel.class];

    NSMutableDictionary *params = @{}.mutableCopy;
    if (contextModel.videoSource == AWEVideoSourceCapture) {
        if (contextModel.videoType == AWEVideoTypeNormal || contextModel.videoType == AWEVideoTypeKaraoke) {
            params[@"video_cnt"] = @(recordInfoModel.fragmentInfo.count);
            params[@"pic_cnt"] = @(0);
        } else if (contextModel.videoType == AWEVideoTypeQuickStoryPicture) {
            params[@"pic_cnt"] = (uploadModel.originUploadPhotoCount) ? : @(1);
            params[@"video_cnt"] = @(0);
        } else {
            params[@"pic_cnt"] = @(recordInfoModel.fragmentInfo.count);
            params[@"video_cnt"] = @(0);
        }
    } else {
        params[@"video_cnt"] = (uploadModel.originUploadVideoClipCount) ? : @(0);
        params[@"pic_cnt"] = (uploadModel.originUploadPhotoCount) ? : @(0);
    }
    NSUInteger videoCnt = [params acc_unsignedIntegerValueForKey:@"video_cnt"];
    NSUInteger photoCnt = [params acc_unsignedIntegerValueForKey:@"pic_cnt"];
    if (videoCnt + photoCnt > 1) {
        params[@"is_multi_content"] = @"1";
    } else {
        params[@"is_multi_content"] = @"0";
    }
    if (videoCnt > 0 && photoCnt > 0) {
        params[@"mix_type"] = @"mix";
    } else if (videoCnt > 1) {
        params[@"mix_type"] = @"video";
    } else if (photoCnt > 1) {
        params[@"mix_type"] = @"photo";
    } else {
        params[@"mix_type"] = @"none";
    }
    return params.copy;
}

- (NSDictionary *)contentTypeMap
{
    NSAssert(NO, @"should implementation in sub class");
    return @{};
}

- (NSString *)contentSource
{
    NSAssert(NO, @"should implementation in sub class");
    return @"";
}

- (NSDictionary *)getLogInfo
{
    NSMutableDictionary *extras =  @{}.mutableCopy;
    [self.repository.extensionModels enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (![obj respondsToSelector:@selector(acc_errorLogParams)]) {
            return;
        }
        NSDictionary *extensionParams = [obj acc_errorLogParams];
        [extensionParams enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull paramsKey, id  _Nonnull paramValue, BOOL * _Nonnull stop) {
            if (![paramValue isKindOfClass:[NSNull class]]) {
                extras[paramsKey] = paramValue;
            }
        }];
    }];
    
    return extras;
}

- (NSDictionary<NSNumber *, NSString *> *)recordButtonTypeTrackInfoMap
{
    NSAssert(NO, @"should implementation in sub class");
    return @{};
}

#pragma mark - NSCopying - Required
- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoTrackModel *model = [[[self class] alloc] init];
    model.recordRouteNumber = self.recordRouteNumber;
    model.referString = [self.referString copy];
    model.shootEnterFrom = [self.shootEnterFrom copy];
    model.enterFrom = [self.enterFrom copy];
    model.enterMethod = [self.enterMethod copy];
    model.enterEditPageMethod = [self.enterEditPageMethod copy];
    model.enterShootPageExtra = [self.enterShootPageExtra copy];

    model.storyShootEntrance = self.storyShootEntrance;
    return model;
}

    
#pragma mark - ACCRepositoryTrackContextProtocol

- (NSDictionary *)acc_referExtraParams {
    NSMutableDictionary *extra = @{}.mutableCopy;
    
    if (self.recordRouteNumber != nil) {
        extra[@"route"] = self.recordRouteNumber;
    }
    
    if (self.enterFrom) {
        extra[@"enter_from"] = self.enterFrom;
    }
    
    if (self.enterMethod) {
        extra[@"enter_method"] = self.enterMethod;
    }
    
    ACCRepoContextModel *contextModel = [self.repository extensionModelOfClass:ACCRepoContextModel.class];
    ACCRepoUploadInfomationModel *uploadModel = [self.repository extensionModelOfClass:ACCRepoUploadInfomationModel.class];
    ACCRepoMusicModel *musicModel = [self.repository extensionModelOfClass:ACCRepoMusicModel.class];
    ACCRepoPropModel *propModel = [self.repository extensionModelOfClass:ACCRepoPropModel.class];
    ACCRepoReshootModel *reshootModel = [self.repository extensionModelOfClass:ACCRepoReshootModel.class];
    NSDictionary *contentTypeMap = [self contentTypeMap];
    NSString *contentType = contentTypeMap[@(contextModel.videoType)] ? : @"video";
    
    if (AWEVideoTypePicture == contextModel.videoType) {
        contentType = @"slideshow";
    }
    if (uploadModel.isAIVideoClipMode) {
        contentType = @"sound_sync";
    }
    
    extra[@"content_type"] = contentType;
    extra[@"content_source"] = [self contentSource];
    BOOL isReuseFeedMusic = [musicModel.musicSelectedFrom containsString:@"same_prop_music"];
    BOOL isReuseFeedProp = [propModel.propSelectedFrom containsString:@"direct_shoot"];
    if (isReuseFeedMusic) {
        extra[@"reuse_prop_music"] = isReuseFeedProp ? @"prop_music" : @"music";
    } else if (isReuseFeedProp) {
        extra[@"reuse_prop_music"] = @"prop";
    }
    if (contextModel.videoSource != AWEVideoSourceCapture) {
        extra[@"upload_type"] = uploadModel.originUploadVideoClipCount.integerValue == 1 ? @"single_content" : @"multiple_content";
    }
    
    extra[@"creation_id"] = (reshootModel.isReshoot && reshootModel.fromCreateId.length > 0) ? reshootModel.fromCreateId : contextModel.createId;
    extra[@"mix_type"] = [self mediaCountInfo][@"mix_type"];

    return extra.copy;
}

- (NSDictionary *)acc_errorLogParams {
    return @{
        @"referString" : self.referString ?: @"",
    };
}

#pragma mark - ACCRepositoryRequestParamsProtocol - Optional

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel {
    NSMutableDictionary *mutableParameter = @{}.mutableCopy;
    mutableParameter[@"shoot_way"] = self.referString;
    return mutableParameter.copy;
}

- (NSDictionary *)acc_publishTrackEventParams:(AWEVideoPublishViewModel *)publishViewModel
{
    return @{};
}

@end
