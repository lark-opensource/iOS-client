//
//  ACCRepoBirthdayModel.m
//  CameraClient-Pods-Aweme
//
//  Created by shaohua yang on 11/30/20.
//

#import <Mantle/Mantle.h>

#import "ACCRepoBirthdayModel.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitArch/ACCRepoMVModel.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import "AWERepoPublishConfigModel.h"

@interface AWEVideoPublishViewModel (RepoBirthday) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoBirthday)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoBirthdayModel.class];
    return info;
}

- (ACCRepoBirthdayModel *)repoBirthday
{
    return [self extensionModelOfClass:[ACCRepoBirthdayModel class]];
}

@end


@interface ACCRepoBirthdayModel () <ACCRepositoryRequestParamsProtocol, ACCRepositoryContextProtocol>

@end

@implementation ACCRepoBirthdayModel

@synthesize birthdayTemplates = _birthdayTemplates;

- (BOOL)isBirthdayPost
{
    return self.birthdayTemplatesJson.length > 0;
}

- (NSArray<ACCBirthdayTemplateModel *> *)birthdayTemplates
{
    NSError *jsonError = nil;
    NSError *convertError = nil;
    if (!_birthdayTemplates && self.birthdayTemplatesJson.length > 0) {
        NSArray *json = [NSJSONSerialization JSONObjectWithData:self.birthdayTemplatesJson options:0 error:&jsonError];
        if (jsonError) {
            AWELogToolError(AWELogToolTagNone, @"%s %@", __PRETTY_FUNCTION__, jsonError);
        }
        
        _birthdayTemplates = [MTLJSONAdapter modelsOfClass:[ACCBirthdayTemplateModel class] fromJSONArray:json error:&convertError];
        if (convertError) {
            AWELogToolError(AWELogToolTagNone, @"%s %@", __PRETTY_FUNCTION__, convertError);
        }
    }
    return _birthdayTemplates;
}

- (void)setBirthdayTemplates:(NSArray<ACCBirthdayTemplateModel *> *)birthdayTemplates
{
    _birthdayTemplates = birthdayTemplates;
    if (birthdayTemplates.count > 0) {
        NSArray *json = [MTLJSONAdapter JSONArrayFromModels:birthdayTemplates error:NULL];
        self.birthdayTemplatesJson = [NSJSONSerialization dataWithJSONObject:json options:0 error:NULL];
    }
}

- (ACCBirthdayTemplateModel *)current
{
    ACCRepoMVModel *mvModel = [self.repository extensionModelOfClass:[ACCRepoMVModel class]];
    NSArray<ACCBirthdayTemplateModel *> *templates = self.birthdayTemplates;
    NSInteger currentId = [mvModel.templateModelId integerValue];
    ACCBirthdayTemplateModel *effect = templates.firstObject;
    for (int i = 0; i < templates.count; i++) {
        if (templates[i].effectId == currentId) {
            return templates[i];
        }
    }
    return effect;
}

- (ACCBirthdayTemplateModel *)next
{
    ACCRepoMVModel *mvModel = [self.repository extensionModelOfClass:[ACCRepoMVModel class]];
    NSArray<ACCBirthdayTemplateModel *> *templates = self.birthdayTemplates;
    NSInteger currentId = [mvModel.templateModelId integerValue];
    ACCBirthdayTemplateModel *nextEffect = templates.firstObject;
    for (int i = 0; i < templates.count; i++) {
        if (templates[i].effectId == currentId) {
            if (i + 1 < templates.count) {
                nextEffect = templates[i + 1];
                break;
            }
        }
    }
    return nextEffect;
}

- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoBirthdayModel *model = [[ACCRepoBirthdayModel alloc] init];
    model.birthdayTemplatesJson = [self.birthdayTemplatesJson copy];
    model.birthdayTemplates = [self.birthdayTemplates copy];
    model.isIMBirthdayPost = self.isIMBirthdayPost;
    model.isDraftEnable = self.isDraftEnable;
    model.atUser = self.atUser;
    return model;
}

#pragma mark - ACCRepositoryContextProtocol

@synthesize repository;

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    NSMutableDictionary *params = @{}.mutableCopy;
    if (publishViewModel.repoBirthday.isBirthdayPost) {
        params[@"story_source_type"] = @(5);
        publishViewModel.repoPublishConfig.categoryDA = ACCFeedTypeExtraCategoryDaBirthday;
    }
    return params;
}

@end
