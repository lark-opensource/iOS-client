//
//  ACCShootSameStickerHandlerFactory.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/18.
//

#import "ACCShootSameStickerHandlerFactory.h"

#import "ACCShootSameStickerHandlerFactoryVideoComment.h"

@implementation ACCShootSameStickerHandlerFactory

+ (nullable id<ACCShootSameStickerHandlerFactoryProtocol>)factoryWithType:(AWEInteractionStickerType)stickerType
{
    if (stickerType == AWEInteractionStickerTypeComment) {
        return [[ACCShootSameStickerHandlerFactoryVideoComment alloc] init];
    }
    return nil;
}

@end
