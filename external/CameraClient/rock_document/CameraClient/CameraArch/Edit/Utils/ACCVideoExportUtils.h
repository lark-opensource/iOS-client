//
//  ACCVideoExportUtils.h
//  CameraClient-Pods-Aweme
//
//  Created by lixingdong on 2020/11/2.
//

#import <Foundation/Foundation.h>
#import "ACCEditVideoData.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;
@class ACCRepoContextModel;
@class ACCRepoCutSameModel;
@class ACCRepoVideoInfoModel;

@interface ACCVideoExportUtils : NSObject

+ (CGSize)videoSizeForVideoData:(ACCEditVideoData *)videoData
                  suggestedSize:(CGSize)suggestedSize
                   publishModel:(AWEVideoPublishViewModel *)publishModel;

+ (CGSize)videoSizeForVideoData:(ACCEditVideoData *)videoData
                  suggestedSize:(CGSize)suggestedSize
                    repoContext:(ACCRepoContextModel *)contextModel
                    repoCutSame:(ACCRepoCutSameModel *)repoCutSame
                  repoVideoInfo:(ACCRepoVideoInfoModel *)repoVideoInfo;

+ (CGSize)videoSizeForVideoData:(ACCEditVideoData *)videoData
                  suggestedSize:(CGSize)suggestedSize;

@end

NS_ASSUME_NONNULL_END
