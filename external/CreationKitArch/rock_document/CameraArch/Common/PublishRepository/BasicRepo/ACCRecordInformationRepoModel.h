//
//  ACCRecordInformationRepoModel.h
//  CameraClient
//
//  Created by haoyipeng on 2020/10/14.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "ACCVideoFragmentInfoProtocol.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>

@class AWEVideoFragmentInfo;

NS_ASSUME_NONNULL_BEGIN

@interface ACCRecordInformationRepoModel : NSObject <NSCopying, ACCRepositoryContextProtocol>
@property (nonatomic, strong, readonly) NSMutableArray<__kindof id<ACCVideoFragmentInfoProtocol>> *fragmentInfo;

- (NSArray *)originalFrameNamesArray;

- (NSDictionary *)beautifyTrackInfoDic;

@end

@interface AWEVideoPublishViewModel (RepoRecordInformation)

@property (nonatomic, strong, readonly) ACCRecordInformationRepoModel *repoRecordInfo;

@end

NS_ASSUME_NONNULL_END
