//
//  ACCRepoParamTransferModel.h
//  Indexer
//
//  Created by bytedance on 2021/12/8.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

@interface ACCRepoPointerTransferFieldsModel : NSObject

@property (nonatomic, assign, readwrite) BOOL isUserSwappedCamera;
/// add other fileds here
@end

/// 用于剪裁场景，创建了新拍摄页VC，与编辑页VC分别持有一个PublishViewModel
/// 为了确保字段从剪裁VC返回时，保持不变，将这个fields的指针直接传递给新拍摄页VC的PublishViewModel, 不做拷贝。
@interface ACCRepoPointerTransferModel : NSObject<NSCopying, ACCRepositoryRequestParamsProtocol, ACCRepositoryContextProtocol>

@property (nonatomic, strong, readwrite, nullable) ACCRepoPointerTransferFieldsModel *fields;

@end

@interface AWEVideoPublishViewModel (RepoPointerTransfer)

@property (nonatomic, strong, readonly, nonnull) ACCRepoPointerTransferModel *repoPointerTrans;

@end
