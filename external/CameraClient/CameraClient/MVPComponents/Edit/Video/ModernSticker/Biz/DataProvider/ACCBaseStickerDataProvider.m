//
//  ACCStickerDataProvider.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/7/12.
//

#import "ACCBaseStickerDataProvider.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "AWERepoStickerModel.h"

@implementation ACCBaseStickerDataProvider

- (NSValue *)gestureInvalidFrameValue
{
    return self.repository.repoSticker.gestureInvalidFrameValue;
}

@end
