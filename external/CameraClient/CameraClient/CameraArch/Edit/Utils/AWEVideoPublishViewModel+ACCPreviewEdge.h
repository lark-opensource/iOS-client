//
//  AWEVideoPublishViewModel+ACCPreviewEdge.h
//  CameraClient
//
//  Created by haoyipeng on 2020/8/18.
//

#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEVideoPublishViewModel (ACCPreviewEdge)

@property (nonatomic, assign) BOOL preMergeInProcess;
@property (nonatomic, assign) BOOL backFromEditPage;
@property (nonatomic, assign) CGRect originalPlayerFrame;

@end

NS_ASSUME_NONNULL_END
