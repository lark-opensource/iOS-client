//
//  ACCRepoPointerTransferModel.m
//  Indexer
//
//  Created by bytedance on 2021/12/8.
//

#import "ACCRepoPointerTransferModel.h"

#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>

#pragma mark - AWEVideoPublishViewModel -

@interface AWEVideoPublishViewModel (RepoPointerTransfer) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoPointerTransfer)

- (id)extensionModelForRepositoryWhenSetup
{
    ACCRepoPointerTransferModel *model = [[ACCRepoPointerTransferModel alloc] init];
    return model;
}

- (ACCRepoPointerTransferModel *)repoPointerTrans
{
    ACCRepoPointerTransferModel *repoPointerTransfer = [self extensionModelOfClass:ACCRepoPointerTransferModel.class];
    NSAssert(repoPointerTransfer, @"extension model should not be nil");
    return repoPointerTransfer;
}

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoPointerTransferModel.class];
    return info;
}

@end

#pragma mark - ACCRepoPointerTransferModel -

@interface ACCRepoPointerTransferModel()

@end

@implementation ACCRepoPointerTransferModel

@synthesize repository;

- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoPointerTransferModel *model = [[ACCRepoPointerTransferModel alloc] init];
    model.fields = self.fields; /// pass pointer
    return model;
}

- (ACCRepoPointerTransferFieldsModel *)fields
{
    if (!_fields) {
        _fields = [[ACCRepoPointerTransferFieldsModel alloc] init];
    }
    return _fields;
}

#pragma mark  ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    return @{};
}

@end

#pragma mark - ACCRepoPointerTransferFieldsModel -

@interface ACCRepoPointerTransferFieldsModel ()

@end

@implementation ACCRepoPointerTransferFieldsModel

@end
