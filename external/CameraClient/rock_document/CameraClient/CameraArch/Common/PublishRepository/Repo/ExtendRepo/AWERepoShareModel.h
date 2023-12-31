//
//  AWERepoShareModel.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/25.
//

#import <CreationKitArch/ACCRepoShareModel.h>


NS_ASSUME_NONNULL_BEGIN

@class ACCPublishShareModel;

@interface AWERepoShareModel : ACCRepoShareModel <NSCopying, ACCRepositoryRequestParamsProtocol>

// 分享/同步
@property (nonatomic, assign) BOOL syncToToutiao;

@property (nonatomic, copy) NSString *thirdAppName;
@property (nonatomic, assign) BOOL shareToPublish;

- (nullable NSString *)shareShootWay;

@end

@interface AWEVideoPublishViewModel (AWERepoShare)
 
@property (nonatomic, strong, readonly) AWERepoShareModel *repoShare;
 
@end

NS_ASSUME_NONNULL_END
