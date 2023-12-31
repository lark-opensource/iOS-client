//
//  ACCStickerPluginConfig.m
//  CameraClient
//
//  Created by Yangguocheng on 2020/6/5.
//

#import "ACCStickerPluginConfig.h"
#import "ACCStickerHighlightMomentPlugin.h"

@implementation ACCStickerPluginConfig

+ (NSNumber *)priorityWithClass:(Class)class
{
    if ([class isEqual:[ACCStickerHighlightMomentPlugin class]]) {
        return @1;
    }
    return @0;
}

+ (NSArray<__kindof id<ACCStickerContainerPluginProtocol>> *)resortPluginPriority:(NSArray<__kindof id<ACCStickerContainerPluginProtocol>> *)pluginList
{
    return [pluginList sortedArrayUsingComparator:^NSComparisonResult(id <ACCStickerContainerPluginProtocol>  _Nonnull obj1, id <ACCStickerContainerPluginProtocol> _Nonnull obj2) {
        NSNumber *priority1 = [self priorityWithClass:[obj1 class]];
        NSNumber *priority2 = [self priorityWithClass:[obj2 class]];
        return [priority1 compare:priority2];
    }];
}

@end
