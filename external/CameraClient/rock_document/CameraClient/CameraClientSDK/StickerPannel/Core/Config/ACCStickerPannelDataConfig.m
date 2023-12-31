//
//  ACCStickerPannelDataConfig.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/2/24.
//

#import "ACCStickerPannelDataConfig.h"

@implementation ACCStickerPannelDataConfig

- (instancetype)copyWithZone:(NSZone *)zone
{
    ACCStickerPannelDataConfig *config = [[ACCStickerPannelDataConfig alloc] init];
    
    config.zipURI = self.zipURI;
    config.creationId = self.creationId;
    config.trackParams = self.trackParams;

    return config;
}

@end
