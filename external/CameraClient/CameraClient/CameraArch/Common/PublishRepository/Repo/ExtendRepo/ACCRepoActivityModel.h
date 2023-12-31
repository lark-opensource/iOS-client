//
//  ACCRepoActivityModel.h
//  Aweme
//  专给各种活动使用的repomodel
//  Created by 卜旭阳 on 2021/11/1.
//

#import <Foundation/Foundation.h>
#import "ACCEditVideoData.h"
#import "ACCNewYearWishEditModel.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

@class ACCNewYearWishEditModel, ACCEditMVModel;

@interface ACCRepoActivityModel : NSObject <NSCopying, ACCRepositoryRequestParamsProtocol, ACCRepositoryContextProtocol>

@property (nonatomic, strong, nullable) ACCNewYearWishEditModel *wishModel;
@property (nonatomic, strong, nullable) ACCEditMVModel *mvModel;

@property (nonatomic, copy, nullable) NSDictionary *wishJsonInfo;

- (BOOL)dataValid;

- (NSArray<NSString *> *)uploadFramePathes;

- (void)generateMVFromDraftVideoData:(nullable ACCEditVideoData *)videoData
                              taskId:(nullable NSString *)taskId
                          completion:(nullable void(^)(ACCEditVideoData *, NSError *))completion;

@end

@interface AWEVideoPublishViewModel (Activity) <ACCRepositoryElementRegisterCategoryProtocol>

@property (nonatomic, strong, readonly, nullable) ACCRepoActivityModel *repoActivity;

@end
