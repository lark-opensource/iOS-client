//
//  ACCRepoCutSameModel.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/23.
//

#import "ACCRepoCutSameModel.h"
#import "ACCRepoContextModel.h"
#import "AWEVideoPublishViewModel+Repository.h"

@interface AWEVideoPublishViewModel (RepoCutSame) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoCutSame)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo
{
    return [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoCutSameModel.class];
}

- (ACCRepoCutSameModel *)repoCutSame
{
    ACCRepoCutSameModel *cutSameModel = [self extensionModelOfClass:ACCRepoCutSameModel.class];
    NSAssert(cutSameModel, @"extension model should not be nil");
    return cutSameModel;
}

@end

@implementation ACCRepoCutSameModel

@synthesize repository;

#pragma mark - public

- (BOOL)isClassicalMV
{
    ACCRepoContextModel *baseInfo = [self.repository extensionModelOfClass:ACCRepoContextModel.class];
    return baseInfo.isMVVideo && ACCMVTemplateTypeClassic == self.accTemplateType;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    ACCRepoCutSameModel *model = [[[self class] alloc] init];
    model.repository = self.repository;

    model.cutSameEditedTexts = self.cutSameEditedTexts;
    model.accTemplateType = self.accTemplateType;
    model.templateModel = self.templateModel;
    // Cut same
    model.cutSameMusicID = self.cutSameMusicID;
    
    return model;
}

@end
