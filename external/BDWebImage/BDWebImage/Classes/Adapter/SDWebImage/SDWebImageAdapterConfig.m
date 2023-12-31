//
//  SDWebImageAdapterConfig.m
//  BDWebImage
//
//  Created by lizhuoli on 2017/12/11.
//

#import "SDWebImageAdapterConfig.h"

@implementation SDWebImageAdapterConfig

- (id)copyWithZone:(NSZone *)zone
{
    SDWebImageAdapterConfig *config = [[self class] allocWithZone:zone];
    config.cacheKeyFilter = self.cacheKeyFilter;
    config.executionOrder = self.executionOrder;
    config.cacheNameSpace = self.cacheNameSpace;
    return config;
}

@end
