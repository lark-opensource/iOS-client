//
//  ACCPOIStickerModel.m
//  CameraClient
//
//  Created by liuqing on 2020/6/17.
//

#import "ACCPOIStickerModel.h"

@implementation ACCPOIStickerModel

- (AWEInteractionPOIStickerModel *)interactionStickerInfo
{
    if (!_interactionStickerInfo) {
        _interactionStickerInfo = [[AWEInteractionPOIStickerModel alloc] init];
    }
    return _interactionStickerInfo;
}

@end
