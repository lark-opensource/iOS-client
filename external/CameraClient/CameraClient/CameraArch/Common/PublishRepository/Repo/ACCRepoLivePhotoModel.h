//
//  ACCRepoLivePhotoModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/7/15.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

// multi photo render business type; e.g boomrange, live photo
typedef NS_ENUM(NSInteger, ACCLivePhotoType) {
    ACCLivePhotoTypeNone        = 0, // invalid
    ACCLivePhotoTypeBoomerang   = 1, // {1,2,3,3,2,1} * N, N is the `repeatCount`
    ACCLivePhotoTypePlainRepeat = 2, // {1,2,3} * N, N is the `repeatCount`
};

@interface ACCRepoLivePhotoModel : NSObject <NSCopying, ACCRepositoryContextProtocol>

// Local draft; not support cross-platform

@property (nonatomic, assign) ACCLivePhotoType businessType;
@property (nonatomic, copy) NSArray<NSString *> *imagePathList; // relativePath
@property (nonatomic, assign) CGFloat durationPerFrame; // default is 0.1
@property (nonatomic, assign) CGFloat repeatCount; // default is 5

- (void)reset;
- (NSTimeInterval)videoPlayDuration;
- (void)updateRepeatCountWithVideoPlayDuration:(NSTimeInterval)videoDuration;

@end

@interface AWEVideoPublishViewModel (RepoLivePhoto)
 
@property (nonatomic, strong, readonly) ACCRepoLivePhotoModel *repoLivePhoto;
 
@end

NS_ASSUME_NONNULL_END
