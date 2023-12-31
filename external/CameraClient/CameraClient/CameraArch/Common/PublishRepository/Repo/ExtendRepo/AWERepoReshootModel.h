//
//  AWERepoReshootModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/22.
//

#import <CreationKitArch/ACCRepoReshootModel.h>


NS_ASSUME_NONNULL_BEGIN

@class AWEVideoFragmentInfo;

@interface AWERepoReshootModel : ACCRepoReshootModel

// only for draft
@property (nonatomic, strong, nullable) NSData *recordVideoClipRangeJson;
// 剪辑
@property (nonatomic, strong, nullable) NSData *fullRangeFragmentInfoJson;


@end

@interface AWEVideoPublishViewModel (AWERepoReshoot)
 
@property (nonatomic, strong, readonly) AWERepoReshootModel *repoReshoot;
 
@end

NS_ASSUME_NONNULL_END
