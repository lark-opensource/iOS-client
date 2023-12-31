//
//  ACCAutoCaptionViewModel.m
//  CameraClient
//
//  Created by chengfei xiao on 2020/7/8.
//

#import "ACCAutoCaptionViewModel.h"
#import "AWERepoVideoInfoModel.h"
#import <CreativeKit/ACCMacros.h>

@implementation ACCAutoCaptionViewModel

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

- (AWEStudioCaptionsManager *)captionManager
{
    if (!_captionManager) {
        _captionManager = [[AWEStudioCaptionsManager alloc] initWithRepoCaptionModel:self.repository.repoCaption repoVideo:self.repository.repoVideoInfo];
    }
    return _captionManager;
}

@end
