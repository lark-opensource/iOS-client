//
//  ACCRecorderPendantViewModel.m
//  Indexer
//
//  Created by HuangHongsen on 2021/11/2.
//

#import "ACCRecorderPendantViewModel.h"
#import <CreativeKit/ACCRouterProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCNetServiceProtocol.h>
#import <CreationKitInfra/ACCBaseApiModel.h>
#import <CreationKitArch/ACCURLModelProtocol.h>
#import <CreationKitArch/ACCURLTransModelProtocol.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>

static NSString *const kACCUserDidDismissPendantKey = @"ACCUserDidDismissPendantKey";

@interface ACCRecorderPendantResponseModel : ACCBaseApiModel
@property (nonatomic, assign) BOOL shouldShow;
@property (nonatomic, copy) NSString *activityID;
@property (nonatomic, copy) NSString *schema;
@property (nonatomic, strong) id<ACCURLModelProtocol> iconURL;
@property (nonatomic, copy) NSString *iconURLType;  //@"lottie" or @"png"
@property (nonatomic, strong) id<ACCURLModelProtocol> foldedIconURL;
@property (nonatomic, copy) NSString *foldedIconURLType;

@end

@implementation ACCRecorderPendantResponseModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return [@{
        @"shouldShow" : @"is_show",
        @"activityID" : @"activity_id",
        @"schema" : @"schema",
        @"iconURL" : @"icon_url",
        @"iconURLType" : @"icon_url_type",
        @"foldedIconURL" : @"fold_icon_url",
        @"foldedIconURLType" : @"fold_icon_url_type",
    } acc_apiPropertyKey];
}

- (ACCRecorderPendantResourceType)resourceType
{
    if ([self.iconURLType isEqualToString:@"lottie"]) {
        return ACCRecorderPendantResourceTypeLottie;
    } else if ([self.iconURLType isEqualToString:@"png"]) {
        return ACCRecorderPendantResourceTypePNG;
    }
    return ACCRecorderPendantResourceTypeNone;
}

+ (NSValueTransformer *)iconURLJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[IESAutoInline(ACCBaseServiceProvider(), ACCURLTransModelProtocol) URLModelImplClass]];
}

+ (NSValueTransformer *)foldedIconURLJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[IESAutoInline(ACCBaseServiceProvider(), ACCURLTransModelProtocol) URLModelImplClass]];
}

@end

@interface ACCRecorderPendantViewModel()
@property (nonatomic, copy) NSString *schema;
@property (nonatomic, copy) NSString *activityID;
@property (nonatomic, assign) BOOL isRequestOnAir;
@end

@implementation ACCRecorderPendantViewModel

- (void)checkPendantShouldShowWithCompletion:(void (^)(ACCRecorderPendantResourceType, NSArray *, NSDictionary *))completion
{
    if ([self userDidClosePendant]) {
        ACCBLOCK_INVOKE(completion, ACCRecorderPendantResourceTypeNone, nil, nil);
    } else {
        if (self.isRequestOnAir) {
            return ;
        }
        self.isRequestOnAir = YES;
        NSString *url = [NSString stringWithFormat:@"%@/aweme/v3/shoot/page/pendant/", [ACCNetService() defaultDomain]];
        @weakify(self);
        [ACCNetService() GET:url params:@{} modelClass:[ACCRecorderPendantResponseModel class] completion:^(ACCRecorderPendantResponseModel *model, NSError * _Nullable error) {
            if (!model || error || !model.shouldShow || ![ACCRouter() canOpenURLString:model.schema]) {
                @strongify(self);
                ACCBLOCK_INVOKE(completion, ACCRecorderPendantResourceTypeNone, nil, nil);
                self.isRequestOnAir = NO;
            } else {
                @strongify(self);
                self.schema = model.schema;
                self.activityID = model.activityID;
                if ([model resourceType] == ACCRecorderPendantResourceTypeLottie) {
                    [self downloadLottieWithJSONUrl:[model.iconURL.URLList firstObject] completion:^(NSDictionary * _Nullable animationJSON) {
                        if (animationJSON) {
                            ACCBLOCK_INVOKE(completion, ACCRecorderPendantResourceTypeLottie, nil, animationJSON);
                        } else {
                            ACCBLOCK_INVOKE(completion, ACCRecorderPendantResourceTypeNone, nil, nil);
                        }
                    }];
                } else if ([model resourceType] == ACCRecorderPendantResourceTypePNG) {
                    if (ACC_isEmptyString([model.iconURL.URLList firstObject])) {
                        ACCBLOCK_INVOKE(completion, ACCRecorderPendantResourceTypeNone, nil, nil);
                    } else {
                        ACCBLOCK_INVOKE(completion, ACCRecorderPendantResourceTypePNG, model.iconURL.URLList, nil);
                    }
                } else {
                    ACCBLOCK_INVOKE(completion,ACCRecorderPendantResourceTypeNone, nil, nil);
                }
                self.isRequestOnAir = NO;
            }
        }];
    }
}

- (BOOL)userDidClosePendant
{
    return [ACCCache() boolForKey:[self pendantDismissKey]];
}

- (void)handleUserClosePandent
{
    [ACCCache() setBool:YES forKey:[self pendantDismissKey]];
}

- (void)handleUserTapOnPendant
{
    if (!ACC_isEmptyString(self.schema) && [ACCRouter() canOpenURLString:self.schema]) {
        [ACCRouter() transferToURLStringWithFormat:@"%@", self.schema];
    }
}

- (NSString *)pendantDismissKey
{
    return [NSString stringWithFormat:@"%@-%@", kACCUserDidDismissPendantKey, [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) currentLoginUserModel].userID];
}

#pragma mark - Private Helper

- (void)downloadLottieWithJSONUrl:(NSString *)urlString completion:(void(^)(NSDictionary * _Nullable animationJSON))completion
{
    if (urlString) {
        [ACCNetService() requestWithModel:^(ACCRequestModel * _Nullable requestModel) {
            requestModel.requestType = ACCRequestTypeGET;
            requestModel.urlString = urlString;
        } completion:^(NSDictionary * _Nullable dic, NSError * _Nullable error) {
            if (dic && !error) {
                ACCBLOCK_INVOKE(completion, dic);
            } else {
                ACCBLOCK_INVOKE(completion, nil);
            }
        }];
    } else {
        ACCBLOCK_INVOKE(completion, nil);
    }
}
@end
