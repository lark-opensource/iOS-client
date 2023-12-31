//
//  ACCCutSameVideoCompressor.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/4/20.
//

#import "ACCCutSameVideoCompressor.h"
#import "ACCCutSameVideoCompressConfig.h"

@interface ACCCutSameVideoCompressor ()

@end

@implementation ACCCutSameVideoCompressor

- (void)cancelAllTasks
{
    [[LVVideoCompressor shared] cancelAllTasks];
}

- (void)compressAsset:(AVURLAsset *)asset
           withConfig:(id<ACCCutSameVideoCompressConfigProtocol>)config
      progressHandler:(ACCCutSameVideoCompressProgress _Nullable)progressHandler
           completion:(ACCCutSameVideoCompressCompletion _Nullable)completion
{
    if ([config isKindOfClass:ACCCutSameVideoCompressConfig.class]) {
        ACCCutSameVideoCompressConfig *theConfig = (ACCCutSameVideoCompressConfig *)config;
        [[LVVideoCompressor shared] compressWtihAsset:asset
                                               config:theConfig.originConfig
                                      progressHandler:^(CGFloat progress) {
            if (progressHandler) {
                progressHandler(progress);
            }
        } completion:^(AVURLAsset * _Nullable theAsset, NSError * _Nullable error) {
            if (completion) {
                completion(theAsset, error);
            }
        }];
    }
}

@end
