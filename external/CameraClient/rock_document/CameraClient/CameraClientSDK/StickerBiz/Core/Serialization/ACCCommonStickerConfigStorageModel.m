//
//  ACCCommonStickerConfigStorageModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/12/21.
//

#import "ACCCommonStickerConfigStorageModel.h"
#import <CreativeKitSticker/ACCBaseStickerView.h>

@implementation ACCCommonStickerConfigStorageModel

- (ACCStickerTimeRangeModelStorageModel *)timeRangeModel
{
    if (!_timeRangeModel) {
        _timeRangeModel = [[ACCStickerTimeRangeModelStorageModel alloc] init];
    }
    
    return _timeRangeModel;
}

@end
