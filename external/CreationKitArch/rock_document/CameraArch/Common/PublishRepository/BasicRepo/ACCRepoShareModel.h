//
//  ACCRepoShareModel.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/25.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCPublishShareModel.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCPublishShareModel;

@interface ACCRepoShareModel : NSObject <NSCopying, ACCRepositoryRequestParamsProtocol>

@property (nonatomic, strong) NSURL *shareVideoURL;

@property (nonatomic, copy) NSString *thirdAppKey;

//share model
@property (nonatomic, strong) ACCPublishShareModel *shareModel;

@end

@interface AWEVideoPublishViewModel (RepoShare)
 
@property (nonatomic, strong, readonly) ACCRepoShareModel *repoShare;
 
@end

NS_ASSUME_NONNULL_END
