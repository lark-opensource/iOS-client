//
//  ACCRepoReshootModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/22.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "ACCVideoFragmentInfoProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCRepoReshootModel : NSObject<NSCopying>

@property (nonatomic, assign) BOOL isReshoot;
@property (nonatomic, strong) NSString *fromCreateId;
// original publishModel taskID & used in reshoot
@property (nonatomic, strong) NSString *fromTaskId;
@property (nonatomic, strong, nullable) NSValue *recordVideoClipRange;
@property (nonatomic, assign) NSTimeInterval durationBeforeReshoot;
@property (nonatomic, assign) NSTimeInterval durationAfterReshoot;

@property (nonatomic, strong, nullable) NSMutableArray<__kindof id<ACCVideoFragmentInfoProtocol>> *fullRangeFragmentInfo;

- (BOOL)hasVideoClipEdits;

- (NSUInteger)getStickerSavePhotoCount;

- (void)removeVideoClipEdits;

@end

@interface AWEVideoPublishViewModel (RepoReshoot)
 
@property (nonatomic, strong, readonly) ACCRepoReshootModel *repoReshoot;
 
@end

NS_ASSUME_NONNULL_END
