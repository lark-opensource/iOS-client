//
//  ACCRepoSmartMovieInfoModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/8/13.
//

#import <Foundation/Foundation.h>
#import "ACCSmartMovieDefines.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>

@protocol ACCEditVideoDataProtocol;
@protocol ACCMusicModelProtocol;

@interface ACCRepoSmartMovieInfoModel : NSObject <NSCopying>

@property (nonatomic, assign) ACCSmartMovieSceneMode videoMode;
@property (nonatomic, copy, nullable) NSArray<NSString *> *assetPaths;   // 素材路径
@property (nonatomic, copy, readonly, nullable) NSArray<NSString *> *thumbPaths;   // 缩略图路径
@property (nonatomic, strong, nullable) id<ACCEditVideoDataProtocol> videoForMV; // 用来切换
@property (nonatomic, strong, nullable) id<ACCEditVideoDataProtocol> videoForSmartMovie; // 用来切换

@property (nonatomic, strong, nullable) id<ACCMusicModelProtocol> musicForMV;   // mv场景下的音乐
@property (nonatomic, strong, nullable) id<ACCMusicModelProtocol> musicForSmartMovie;   // 智照场景下的音乐

- (BOOL)isMVMode;           // 当前是MV场景
- (BOOL)isSmartMovieMode;   // 当前是智照场景
- (BOOL)transformedForSmartMovie;   // 当前是智照的场景切换

@end


@interface AWEVideoPublishViewModel (RepoSmartMovieInfo)

@property (nonatomic, strong, readonly, nonnull) ACCRepoSmartMovieInfoModel *repoSmartMovie;

@end
