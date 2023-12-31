//
//  ACCRepoTextModeModel.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/26.
//

#import "ACCRepoTextModeModel.h"
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitArch/AWEStoryTextImageModel.h>
#import <CreationKitArch/ACCAwemeModelProtocol.h>
#import "AWERepoPublishConfigModel.h"

@interface AWEVideoPublishViewModel (RepoTextMode) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoTextMode)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoTextModeModel.class];
    return info;
}

- (ACCRepoTextModeModel *)repoTextMode
{
    ACCRepoTextModeModel *textModeModel = [self extensionModelOfClass:ACCRepoTextModeModel.class];
    NSAssert(textModeModel, @"extension model should not be nil");
    return textModeModel;
}

@end

@implementation ACCRepoTextModeModel
@synthesize repository;

#pragma mark - copying

- (id)copyWithZone:(NSZone *)zone {
    ACCRepoTextModeModel *model = [[[self class] alloc] init];
    if (self.textModel != nil) {
        NSError *error = nil;
        NSDictionary *parameter = [MTLJSONAdapter JSONDictionaryFromModel:self.textModel error:&error];
        if (error) {
            AWELogToolError(AWELogToolTagDraft, @"%s %@", __PRETTY_FUNCTION__, error);
        } else if (parameter) {
            NSError *convertError = nil;
            model.textModel = [MTLJSONAdapter modelOfClass:[AWEStoryTextImageModel class] fromJSONDictionary:parameter error:&convertError];
            if (convertError) {
                AWELogToolError(AWELogToolTagDraft, @"%s %@", __PRETTY_FUNCTION__, convertError);
            }
        }
    }
    model.isTextMode = self.isTextMode;
    return model;
}

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    NSMutableDictionary *mutableParameter = @{}.mutableCopy;
    if (self.isTextMode) {
        mutableParameter[@"is_text_mode"] = @1;
        mutableParameter[@"category_da"] = @(ACCFeedTypeExtraCategoryDaTextMode);
    }
    return mutableParameter.copy;
}


@end
