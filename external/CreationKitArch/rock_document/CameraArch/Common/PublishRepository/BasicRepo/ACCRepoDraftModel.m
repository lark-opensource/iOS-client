//
//  ACCRepoDraftModel.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/20.
//

#import "ACCRepoDraftModel.h"
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreationKitArch/AWEVideoPublishDraftTempProductModel.h>

@interface AWEVideoPublishViewModel (RepoDraft) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoDraft)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    return [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoDraftModel.class];
}

- (ACCRepoDraftModel *)repoDraft
{
    ACCRepoDraftModel *draftModel = [self extensionModelOfClass:ACCRepoDraftModel.class];
    NSAssert(draftModel, @"extension model should not be nil");
    return draftModel;
}

@end

@implementation ACCRepoDraftModel

@synthesize repository = _repository;

#pragma mark - NSCopying - Required
- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoDraftModel *model = [[[self class] alloc] init];
    model.taskID = self.taskID;
    model.originalModel = self.originalModel;
    model.draftPath = self.draftPath;
    model.isBackUp = self.isBackUp;
    model.editFrequency = self.editFrequency;
    return model;
}

#pragma mark - public

- (BOOL)isDraft
{
    NSAssert(nil, @"should be overwrite in subclass");
    return NO;
}

- (NSString *)taskID
{
    if (!_taskID) {
        _taskID = [AWEDraftUtils generateTaskID];
    }
    return _taskID;
}

- (NSString *)draftPath
{
    if (!_draftPath) {
        _draftPath = [AWEDraftUtils generateDraftPathFromTaskId:self.taskID];
    }
    return _draftPath;
}

- (AWEVideoPublishDraftTempProductModel *)draftTempProduct {
    if (!_draftTempProduct) {
        _draftTempProduct = [AWEVideoPublishDraftTempProductModel new];
        _draftTempProduct.publishTaskId = self.taskID;
    }
    return _draftTempProduct;
}

- (NSString *)draftFolder
{
    return [AWEDraftUtils generateDraftFolderFromTaskId:self.taskID];
}

#pragma mark - ACCRepositoryRequestParamsProtocol - Optional

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    return @{@"is_draft" : self.isDraft ? @1 : @0};
}

#pragma mark - ACCRepositoryTrackContextProtocol

- (NSDictionary *)acc_errorLogParams {
    return @{
        @"task": self.taskID ?: @"",
    };
}

- (NSDictionary *)acc_referExtraParams
{
    NSMutableDictionary *extrasDict = @{}.mutableCopy;
    if (self.editFrequency > 0) {
        extrasDict[@"draft_id"] = @(self.editFrequency).stringValue;
    }
    return extrasDict;
}

@end
