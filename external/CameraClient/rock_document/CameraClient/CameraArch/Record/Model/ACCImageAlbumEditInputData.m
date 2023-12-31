//
//  ACCImageAlbumEditInputData.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2020/12/18.
//

#import "ACCImageAlbumEditInputData.h"
#import "ACCVEVideoData.h"
#import "AWERepoVideoInfoModel.h"
#import "AWERepoDraftModel.h"
#import "ACCRepoSmartMovieInfoModel.h"

@implementation ACCImageAlbumEditInputData

- (id)copyWithZone:(NSZone *)zone
{
    ACCImageAlbumEditInputData *ret = [[ACCImageAlbumEditInputData alloc] init];
    // publish model 并不需要copy 因为对于视频/图片编辑来说 两份数据已经分开
    ret.imageModePublishModel = self.imageModePublishModel;
    ret.videoModePublishModel = self.videoModePublishModel;
    return ret;
}

- (void)setImageModePublishModel:(AWEVideoPublishViewModel *)imageModePublishModel
{
    _imageModePublishModel = imageModePublishModel;
    
    // 图集只需要一个空的 VideoData
    [imageModePublishModel.repoVideoInfo updateVideoData:[ACCVEVideoData videoDataWithDraftFolder:imageModePublishModel.repoDraft.draftFolder]];
    // 图集不需要缓存智照场景的数据
    _imageModePublishModel.repoSmartMovie.videoForMV = nil;
    _imageModePublishModel.repoSmartMovie.videoForSmartMovie = nil;
}

@end
