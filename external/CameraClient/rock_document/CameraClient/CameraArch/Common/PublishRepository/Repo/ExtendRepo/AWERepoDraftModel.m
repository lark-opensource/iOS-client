//
//  AWERepoDraftModel.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/20.
//

#import "AWERepoDraftModel.h"
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CameraClient/ACCDraftModelProtocol.h>

/*
 ！！！model注入看这里！！！
 在大部分情况下，需要在AWEVideoPublishViewModel初始化的时候注入业务model，以便后续的取值/赋值
 当然也可以不使用这个能力，而使用ACCPublishRepository的setExtensionModelByClass:在合适的时机注入，这个就由各业务方根据具体情况去判断。
 */
@interface AWEVideoPublishViewModel (AWERepoDraft) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (AWERepoDraft)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
	ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:AWERepoDraftModel.class];
	return info;
}

- (AWERepoDraftModel *)repoDraft
{
    AWERepoDraftModel *draftModel = [self extensionModelOfClass:AWERepoDraftModel.class];
    NSAssert(draftModel, @"extension model should not be nil");
    return draftModel;
}

@end

@implementation AWERepoDraftModel

/*
!!! 必须实现 ！！！
 NSCopying 协议的实现是必须的
 1.在repository被拷贝的时候element也需要被深拷贝
 2.在一些需要传递repository容器的场景下element也需要被深拷贝。
 */
#pragma mark - NSCopying - Required
- (id)copyWithZone:(NSZone *)zone
{
    AWERepoDraftModel *model = [super copyWithZone:zone];
    model.originalDraft = self.originalDraft;
    model.originalModel = self.originalModel;
    model.userID = self.userID;
    model.saveDate = self.saveDate;
    model.adminDraftId = self.adminDraftId;
    model.draftSavePolicy = self.draftSavePolicy;
    model.postPageFrequency = self.postPageFrequency;
    return model;
}

- (NSDictionary *)acc_referExtraParams
{
    NSMutableDictionary *extrasDict = @{}.mutableCopy;
    if (self.editFrequency > 0) {
        extrasDict[@"draft_id"] = @(self.editFrequency).stringValue;
    }
    extrasDict[@"is_draft"] = self.isDraft ? @(1) : @(0);
    return extrasDict;
}

#pragma mark - ACCRepositoryTrackContextProtocol

- (NSDictionary *)acc_errorLogParams {
    NSMutableDictionary *dict = [super acc_errorLogParams].mutableCopy;
    [dict addEntriesFromDictionary:@{
        @"is_draft" : self.originalDraft?@"1":@"0",
    }];
    return dict;
}

#pragma mark - public

- (BOOL)isDraft
{
    return self.originalDraft != nil;
}

- (NSString *)tagForDraftFromBackEdit
{
    if (!self.isDraft) {
        return nil;
    } else {
        return @([self.originalDraft.saveDate timeIntervalSince1970]).stringValue;
    }
}

@end
