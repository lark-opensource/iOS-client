//
//  ACCRepoSmartMovieInfoModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/8/13.
//

#import "ACCRepoSmartMovieInfoModel.h"
#import "ACCSmartMovieUtils.h"
#import <CreativeKit/ACCMacros.h>
#import <CameraClient/ACCNLEEditVideoData.h>
#import <CameraClient/ACCSmartMovieABConfig.h>

@implementation ACCRepoSmartMovieInfoModel

- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoSmartMovieInfoModel *model = [[ACCRepoSmartMovieInfoModel allocWithZone:zone] init];
    model.assetPaths = self.assetPaths;
    model.videoMode = self.videoMode;
    model.videoForMV = self.videoForMV;
    model.videoForSmartMovie = self.videoForSmartMovie;
    
    model.musicForMV = self.musicForMV;
    model.musicForSmartMovie = self.musicForSmartMovie;
    
    return model;
}

- (BOOL)isMVMode
{
    return (self.videoMode == ACCSmartMovieSceneModeMVVideo);
}

- (BOOL)isSmartMovieMode
{
    return (self.videoMode == ACCSmartMovieSceneModeSmartMovie);
}

- (BOOL)transformedForSmartMovie
{
    return [ACCSmartMovieABConfig isOn] && ((self.videoMode == ACCSmartMovieSceneModeMVVideo) || (self.videoMode == ACCSmartMovieSceneModeSmartMovie));
}

- (void)setAssetPaths:(NSArray<NSString *> *)assetPaths
{
    _assetPaths = [assetPaths copy];
    _thumbPaths = [ACCSmartMovieUtils thumbImagesForPaths:assetPaths];
}

@end

@interface AWEVideoPublishViewModel (RepoSmartMovieInfo) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoSmartMovieInfo)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoSmartMovieInfoModel.class];
    return info;
}

- (ACCRepoSmartMovieInfoModel *)repoSmartMovie
{
    ACCRepoSmartMovieInfoModel *model = [self extensionModelOfClass:[ACCRepoSmartMovieInfoModel class]];
    NSParameterAssert(model != nil);
    return model;
}

@end
