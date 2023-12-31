//
//  ACCRepoVideoInfoModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/20.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>
#import <TTVideoEditor/HTSVideoData.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "ACCVideoFragmentInfoProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class ACCVideoCanvasSource;

typedef NS_ENUM(NSInteger, ACCVideoCanvasType);

@interface ACCRepoVideoInfoModel : NSObject <NSCopying, ACCRepositoryContextProtocol>

@property (nonatomic) BOOL videoMuted;

@property (nonatomic, strong, nullable) NSValue *sizeOfVideo;

@property (nonatomic, assign) BOOL isExposureOptmize;

@property (nonatomic, assign, readonly) float fps;

@property (nonatomic, assign) BOOL enableHDRNet;

@property (nonatomic, assign) BOOL needExpandVideoSize;

@property (nonatomic, strong) NSMutableArray<__kindof id<ACCVideoFragmentInfoProtocol>> *fragmentInfo;

- (BOOL)isVideoNeedReverse;

@end

@interface AWEVideoPublishViewModel (RepoVideoInfo)
 
@property (nonatomic, strong, readonly) ACCRepoVideoInfoModel *repoVideoInfo;
 
@end

@interface ACCVideoCanvasSource : NSObject <NSCoding>

@property (nonatomic) CGPoint center;
@property (nonatomic) double scale;
@property (nonatomic) double rotation;

- (BOOL)isEqualToObject:(ACCVideoCanvasSource *)object;

@end

NS_ASSUME_NONNULL_END
